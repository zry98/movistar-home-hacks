#!/usr/bin/env bash

DISK_DEVICE="/dev/mmcblk1"
KERNEL_OPTIONS="loglevel=3 quiet consoleblank=0 cpufreq.default_governor=performance fbcon=rotate:1 fbconsole=rotate:1 audit=0 mitigations=off zswap.enabled=0"

# script utils
GREEN=$'\e[32m'
RESET=$'\e[0m'

####################
### connect WLAN ###
####################
function connect_wlan {
  set -e

  # disable MAC address randomization
  mkdir -p /etc/iwd
  cat > /etc/iwd/main.conf <<\EOF
[Scan]
DisablePeriodicScan=false
[General]
EnableNetworkConfiguration=true
AddressRandomization=disabled
Country=ES
EOF
  systemctl restart iwd

  rfkill unblock wlan
  iwctl device wlan0 show  # check if WLAN driver is working
  iwctl device wlan0 set-property Powered on
  iwctl adapter phy0 set-property Powered on
  iwctl station wlan0 scan
  echo "${GREEN}Scanning for Wi-Fi, please wait for 10 seconds...${RESET}"
  sleep 10
  iwctl station wlan0 get-networks

  local SSID PASSWORD IS_HIDDEN
  read -rp $'\n\n'"${GREEN}Enter Wi-Fi name: ${RESET}"$'\n' SSID
  read -rp $'\n\n'"${GREEN}Is this Wi-Fi hidden? (y/N): ${RESET}"$'\n' IS_HIDDEN
  read -rp $'\n\n'"${GREEN}Enter Wi-Fi password: ${RESET}"$'\n' PASSWORD

  echo "${GREEN}Connecting, please wait for 10 seconds...${RESET}"
  if [[ "$IS_HIDDEN" == [yY] ]]; then
    iwctl --passphrase "${PASSWORD}" station wlan0 connect "${SSID}"
  else
    iwctl --passphrase "${PASSWORD}" station wlan0 connect-hidden "${SSID}"
  fi
  sleep 10  # FIXME: wait for connection
  iwctl known-networks "${SSID}" set-property AutoConnect yes
}

####################
### Arch install ###
####################
function arch_install {
  set -e

  loadkeys es

  ln -sf /usr/share/zoneinfo/${TZ:-Europe/Madrid} /etc/localtime
  mkdir -p /etc/systemd/timesyncd.conf.d/
  cat /etc/systemd/timesyncd.conf.d/99-movistar-home-panel.conf <<\EOF
[Time]
FallbackNTP=0.es.pool.ntp.org 1.europe.pool.ntp.org time.cloudflare.com time.google.com
PollIntervalMinSec=100
PollIntervalMaxSec=10800
EOF
  timedatectl set-ntp true
  sleep 5  # wait for clock sync
  hwclock --systohc

  mkdir -p /mnt/emmc
  ! mountpoint --quiet /mnt/emmc || umount --recursive --force --quiet /mnt/emmc
  local PTUUID="$(blkid -s PTUUID -o value "${DISK_DEVICE}")"
  sfdisk "${DISK_DEVICE}" <<EOF
label: gpt
label-id: ${PTUUID^^}
device: ${DISK_DEVICE}
unit: sectors
first-lba: 2048
last-lba: 30670814
sector-size: 512

${DISK_DEVICE}p1 : start=4096, size=614400, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, uuid=43E90F4B-A203-411C-A0C3-960E11ED73A5
${DISK_DEVICE}p2 : start=618496, size=30049589, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=9C801BE8-6085-4BF1-A291-610B51403F26, name="root"
EOF
  sleep 2  # wait for disk sync
  mkfs.fat -F 32 "${DISK_DEVICE}p1"
  mkfs.f2fs -f -i -O extra_attr,inode_checksum,sb_checksum "${DISK_DEVICE}p2"
  mount "${DISK_DEVICE}p2" /mnt/emmc
  mount --mkdir "${DISK_DEVICE}p1" /mnt/emmc/boot

  # bootloader
  bootctl install --esp-path=/mnt/emmc/boot
  cat > /mnt/emmc/boot/loader/loader.conf <<\EOF
timeout 0
console-mode max
default arch.conf
EOF
  local ROOT_UUID="$(blkid -s UUID -o value "${DISK_DEVICE}p2")"
  cat > /mnt/emmc/boot/loader/entries/arch.conf <<EOF
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=${ROOT_UUID} rw ${KERNEL_OPTIONS}
EOF
  cat > /mnt/emmc/boot/loader/entries/arch-fallback.conf <<EOF
title Arch Linux fallback
linux /vmlinuz-linux
initrd /initramfs-linux-fallback.img
options root=UUID=${ROOT_UUID} rw ${KERNEL_OPTIONS}
EOF

  reflector --sort rate --country es --number 20 --age 6 --latest 10 --fastest 10
  pacstrap -K /mnt/emmc \
    base linux \
    linux-firmware-intel linux-firmware-realtek linux-firmware-other \
    intel-ucode \
    iw iwd \
    openssh \
    f2fs-tools \
    nano \
    vim vim-runtime \
    mkinitcpio \
    sudo \
    curl rsync reflector \
    ca-certificates ca-certificates-mozilla \
    libgpiod \
    alsa-utils alsa-ucm-conf alsa-firmware \
    pipewire pipewire-audio pipewire-pulse pipewire-session-manager pipewire-alsa \
    brightnessctl \
    noto-fonts \
    seatd sway swayidle \
    chromium \
    ydotool

  genfstab -U /mnt/emmc >> /mnt/emmc/etc/fstab

  # copy WLAN connection configs
  mkdir -p /mnt/emmc/var/lib/iwd
  cp -af /var/lib/iwd/ /mnt/emmc/var/lib/
}

####################
### post-install ###
####################
function setup_chrooted {
  set -e

  # locale
  cat > /etc/vconsole.conf <<\EOF
KEYMAP=es
EOF
  cat > /etc/locale.gen <<\EOF
en_US.UTF-8 UTF-8
es_ES.UTF-8 UTF-8
EOF
  locale-gen
  cat > /etc/locale.conf <<\EOF
LANG=en_US.UTF-8
EOF

  # basics
  local ROOT_PASSWD USER_PASSWD
  read -rp $'\n\n'"${GREEN}Enter root user's password (leave empty to use 'root'): ${RESET}"$'\n' ROOT_PASSWD
  if [[ -z "${ROOT_PASSWD}" ]]; then
    ROOT_PASSWD="root"
  fi
  echo "${ROOT_PASSWD}" | passwd --stdin root
  read -rp $'\n\n'"${GREEN}Enter 'panel' user's password (leave empty to use 'panel'): ${RESET}"$'\n' USER_PASSWD

  local KIOSK_URL PANEL_CONTROLLER_TOKEN
  read -rp $'\n\n'"${GREEN}Enter Chromium kiosk URL (leave empty to skip the service, but there won't be anything usable on screen): ${RESET}"$'\n' KIOSK_URL
  read -rp $'\n\n'"${GREEN}Enter panel controller token (leave empty to skip the service): ${RESET}"$'\n' PANEL_CONTROLLER_TOKEN

  cat > /etc/ssh/sshd_config.d/99-movistar-home-panel.conf <<\EOF
PasswordAuthentication yes
PubkeyAuthentication yes
EOF
  rm -f /root/.ssh/id_ed25519 && ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N ''

  # modules
  cat > /etc/modprobe.d/99-movistar-home-panel.conf <<\EOF
# blacklist useless modules
blacklist axp20x_i2c
blacklist extcon_axp288
blacklist intel_xhci_usb_role_switch
blacklist extcon_intel_int3496
blacklist hid_sensor_hub
blacklist bluetooth
blacklist intel_atomisp2_pm
blacklist ov2680
# disable RTL8822BE power-saving
options rtw88_core disable_lps_deep=y
options rtw88_pci disable_msi=y disable_aspm=y
options rtw_core disable_lps_deep=y
options rtw_pci disable_msi=y disable_aspm=y
# disable bluetooth
blacklist bluetooth
blacklist hci_uart
EOF
  cat > /etc/modules-load.d/99-movistar-home-panel.conf <<\EOF
zram
tls
EOF

  cat > /etc/sysctl.d/99-movistar-home-panel.conf <<\EOF
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
vm.dirty_writeback_centisecs = 6000
EOF

  # display
  cat > /etc/mkinitcpio.conf.d/99-movistar-home-panel.conf <<\EOF
MODULES=(i915 pwm-lpss-platform)
EOF

  cat > /etc/udev/rules.d/99-movistar-home-panel.rules <<\EOF
# backlight
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video $sys$devpath/brightness", RUN+="/bin/chmod g+w $sys$devpath/brightness"
# zram
ACTION=="add", KERNEL=="zram0", ATTR{initstate}=="0", ATTR{comp_algorithm}="zstd", ATTR{disksize}="2G", TAG+="systemd"
EOF

  cat >> /etc/fstab <<\EOF

/dev/zram0  none  swap  defaults,discard,pri=100,x-systemd.makefs 0 0
EOF

  mkinitcpio -P

  # networking
  mkdir -p /etc/iwd
  cat > /etc/iwd/main.conf <<\EOF
[Scan]
DisablePeriodicScan=false
[General]
EnableNetworkConfiguration=true
AddressRandomization=disabled
Country=ES
[Network]
NameResolvingService=systemd
[DriverQuirks]
PowerSaveDisable=rtw*
EOF
  echo "panel" > /etc/hostname
  cat > /etc/hosts <<\EOF
127.0.0.1 localhost
127.0.1.1 panel.localdomain panel
::1 localhost
EOF
  mkdir -p /etc/systemd/resolved.conf.d/
  cat /etc/systemd/resolved.conf.d/99-movistar-home-panel.conf <<\EOF
[Resolve]
FallbackDNS=1.0.0.1#cloudflare-dns.com 149.112.112.112#dns.quad9.net 8.8.4.4#dns.google 2606:4700:4700::1001#cloudflare-dns.com 2620:fe::9#dns.quad9.net 2001:4860:4860::8844#dns.google
EOF

  # time
  ln -sf /usr/share/zoneinfo/${TZ:-Europe/Madrid} /etc/localtime
  systemctl enable systemd-timesyncd

  # journald
  mkdir -p /etc/systemd/journald.conf.d/
  cat /etc/systemd/journald.conf.d/99-movistar-home-panel.conf <<\EOF
[Journal]
Storage=volatile
Compress=yes
SystemMaxUse=10M
ForwardToSyslog=no
ForwardToKMsg=no
ForwardToConsole=no
MaxLevelStore=notice
MaxLevelSyslog=notice
MaxLevelKMsg=notice
MaxLevelConsole=info
EOF

  # power button event
  mkdir -p /etc/systemd/logind.conf.d/
  cat > /etc/systemd/logind.conf.d/99-movistar-home-panel.conf <<\EOF
[Login]
HandlePowerKey=ignore
HandlePowerKeyLongPress=poweroff
EOF

  # panel user
  useradd --create-home --groups wheel,audio,video,input,seat panel
  cat > /etc/sudoers.d/99-movistar-home-panel <<\EOF
%wheel ALL=(ALL:ALL) ALL
EOF
  if [[ -z "${USER_PASSWD}" ]]; then
    USER_PASSWD="panel"
  fi
  echo "${USER_PASSWD}" | passwd --stdin panel
  # regenerate SSH key if not exists
  if [[ ! -f "/home/panel/.ssh/id_ed25519" ]]; then
    sudo --user=panel ssh-keygen -t ed25519 -f /home/panel/.ssh/id_ed25519 -N ''
  fi

  # sound
  cat > /etc/systemd/system/fix-sound.service <<\EOF
[Unit]
Description=Fix sound

[Service]
Type=simple
ExecStart=gpioset --chip 1 5=1 7=1

[Install]
WantedBy=multi-user.target
EOF

  # swaywm
  mkdir -p /etc/systemd/system/getty@tty1.service.d
  cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<\EOF
[Service]
Environment=XDG_SESSION_TYPE=wayland
ExecStart=
ExecStart=-/sbin/agetty --skip-login --nonewline --noissue --autologin panel --noclear %I $TERM
Restart=on-failure
RestartSec=5
TimeoutStopSec=10
EOF
  if ! grep -q '^\[\[ -f ~/sway\.sh ]] && \. ~/sway\.sh' /home/panel/.bash_profile; then
    cat >> /home/panel/.bash_profile <<\EOF
[[ -f ~/sway.sh ]] && . ~/sway.sh
EOF
  fi
  cat >> /home/panel/sway.sh <<\EOF
#!/bin/bash
# sway
if [ -z "$WAYLAND_DISPLAY" ] && [ -n "$XDG_VTNR" ] && [ "$XDG_VTNR" -eq 1 ]; then
  WLR_DRM_NO_ATOMIC=1 exec sway --config .config/sway/config #--debug |& tee ./sway.log
else
  export SWAYSOCK=/run/user/$(id -u)/sway-ipc.$(id -u).$(pgrep -x sway).sock
fi
EOF
  chmod 0755 /home/panel/sway.sh

  mkdir -p /home/panel/.config/sway
  cat > /home/panel/.config/sway/config <<\EOF
include /etc/sway/config.d/*

# output
output DSI-1 {
  power on
  mode 800x1280
  position 0 0
  transform 90
  scale 1.25
  adaptive_sync on
  background #000000 solid_color
}

# map touchscreen
input "1046:911:Goodix_Capacitive_TouchScreen" {
  map_to_output DSI-1
}

# volume buttons
bindsym --locked XF86AudioLowerVolume exec pactl set-sink-volume \@DEFAULT_SINK@ -10%
bindsym --locked XF86AudioRaiseVolume exec pactl set-sink-volume \@DEFAULT_SINK@ +10%

# hide cursor
seat seat0 {
  hide_cursor 100
}

# no window borders
default_border none
default_floating_border none
hide_edge_borders both
smart_borders off
smart_gaps off

# fix sound
exec alsaucm --card cht-bsw-rt5672 set _verb HiFi set _enadev Headphones

exec_always systemctl --user start sway-session.target
# anything else to run goes below:
# ...
EOF

  # create user services
  mkdir -p /home/panel/.config/systemd/user/
  cat > /home/panel/.config/systemd/user/sway-session.target <<\EOF
[Unit]
Description=SwayWM session
BindsTo=graphical-session.target
Wants=graphical-session-pre.target
After=graphical-session-pre.target
EOF
  cat > /home/panel/.config/systemd/user/swayidle.service <<\EOF
[Unit]
Description=Swayidle
BindsTo=sway-session.target
After=sway-session.target

[Service]
Type=simple
# default backlight to 100% on start-up
ExecStartPre=brightnessctl --quiet --device=intel_backlight set 100
# auto dim backlight to 15% after idling for 60 secs
ExecStart=swayidle -w \
            timeout 3 ':' \
              resume 'brightnessctl --quiet --device=intel_backlight set 100 && swaymsg "output DSI-1 power on"' \
            timeout 60 'brightnessctl --quiet --device=intel_backlight set 15' \
              resume 'brightnessctl --quiet --device=intel_backlight set 100'
Restart=on-failure
RestartSec=5
TimeoutStopSec=10

[Install]
WantedBy=sway-session.target
EOF
  if [[ ! -z "${PANEL_CONTROLLER_TOKEN}" ]]; then
    pacman --sync --noconfirm base-devel gtk4 gtk4-layer-shell
    python3 -m venv /home/panel/panel-controller
    curl -L -o /home/panel/panel-controller/app.py "https://raw.githubusercontent.com/zry98/movistar-home-hacks/main/IGW5000/panel-controller/app.py"
    curl -L -o /home/panel/panel-controller/requirements.txt "https://raw.githubusercontent.com/zry98/movistar-home-hacks/main/IGW5000/panel-controller/requirements.txt"
    /home/panel/panel-controller/bin/pip install -r /home/panel/panel-controller/requirements.txt

    cat > /home/panel/.config/systemd/user/panel-controller.service <<EOF
[Unit]
Description=Panel controller
BindsTo=sway-session.target
After=sway.service

[Service]
Environment=TOKEN=${PANEL_CONTROLLER_TOKEN}
Type=simple
ExecStart=%h/panel-controller/bin/python %h/panel-controller/app.py
Restart=on-failure
RestartSec=5
TimeoutStopSec=10

[Install]
WantedBy=sway-session.target
EOF
  fi

  if [[ ! -z "${KIOSK_URL}" ]]; then
    cat > /home/panel/.config/systemd/user/chromium-kiosk.service <<EOF
[Unit]
Description=Chromium Kiosk
BindsTo=sway-session.target
After=sway-session.target

[Service]
Environment=KIOSK_URL=${KIOSK_URL}
Type=simple
ExecStart=chromium \
            --ozone-platform=wayland \
            --no-default-browser-check \
            --no-first-run \
            --disable-crash-reporter \
            --disable-breakpad \
            --disable-search-engine-choice-screen \
            --webview-disable-safebrowsing-support \
            --process-per-site \
            --disk-cache-dir="/tmp/chromium-cache" \
            --kiosk \
            --hide-scrollbars \
            --autoplay-policy=no-user-gesture-required \
            "\${KIOSK_URL}"
Restart=on-failure
RestartSec=5
TimeoutStopSec=10
CPUAccounting=yes
BlockIOAccounting=yes
MemoryAccounting=yes
MemoryHigh=1G
MemoryMax=1G
MemorySwapMax=1.5G

[Install]
WantedBy=sway-session.target
EOF
  fi

  # enable services
  systemctl enable \
    iwd.service \
    systemd-resolved.service \
    sshd.service \
    seatd.service \
    fix-sound.service
  # enable user services
  mkdir -p /home/panel/.config/systemd/user/{default.target.wants,sway-session.target.wants}/
  chown -R panel:panel /home/panel
  sudo --user=panel systemctl --user enable \
    swayidle.service \
    ydotool.service
  if [[ ! -z "${KIOSK_URL}" ]]; then
    sudo --user=panel systemctl --user enable chromium-kiosk.service
  fi
  if [[ ! -z "${PANEL_CONTROLLER_TOKEN}" ]]; then
    sudo --user=panel systemctl --user enable panel-controller.service
  fi

  chown -R panel:panel /home/panel # ensure file permissions
  # pacman mirrors
  reflector --sort rate --country es --number 20 --age 6 --latest 10 --fastest 10

  read -rp $'\n\n'"${GREEN}Successful! Please remove the USB drive and press Enter key to reboot now; or Ctrl+C if you want to do anything else...${RESET}"
  [[ $? -eq 0 ]] && reboot now
}

############
### main ###
############
set -x

if ! systemd-detect-virt --chroot; then
  # not running in chroot
  while ! ping -q -c 1 -W 5 1.0.0.1; do  # check if connected to the internet
    connect_wlan
  done
  # install Arch Linux
  arch_install
  # copy the script to chroot
  cp -f "$(realpath "$0")" /mnt/emmc/root/setup.sh
  chmod +x /mnt/emmc/root/setup.sh
  arch-chroot -S /mnt/emmc /root/setup.sh --post-install
else
  if [[ "$#" -eq 0 ]]; then
    # running in chroot but no arguments given, meaning it's being re-ran inside chroot after post-install setups failed or something
    echo "${GREEN}Please exit from chroot by 'Ctrl+D' or executing 'exit', then re-run the script${RESET}"
  else
    # run post-install setups
    setup_chrooted
  fi
fi
