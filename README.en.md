# Repurposing Movistar Home

![hass](img/hass.jpg)

[Versión en castellano](README.md)

## HELP NEEDED

I dumped the original Android-x86 firmware from flash, but it failed to boot after I wrote it back in, and the /data partition was encrypted and I couldn't find a way to decrypt it.

Contributions to the [repository](https://github.com/zry98/movistar-home) are very welcomed if you've got any discoveries; or if you have a Movistar Home not in use and willing to help this project, please contact me through my email in [GitHub profile](https://github.com/zry98), much appreciated!

### TODO list

- [ ] Fix sound card driver ([ALSA](https://en.wikipedia.org/wiki/Advanced_Linux_Sound_Architecture) configs)
- [ ] Fix camera driver
- [ ] Fix bluetooth driver
- [ ] Fix reset button
- [ ] Find a way to install Linux without disassembling nor soldering (maybe through easycwmp on port 7547)

## Driver status

As in the latest Manjaro XFCE with 5.15.28-1 kernel, on April 9, 2022:

| Device | Model | Driver | Status |
| --- | --- | --- | --- |
| Touch screen | Goodix unknown model | goodix | OK |
| Wi-Fi | Realtek RTL8822BE | rtw88_8822be | OK |
| Bluetooth | Realtek RTL8822BE | rtw88_8822be | Not working |
| Sound card (speaker & microphone) | Realtek RT5672 | snd_soc_sst_cht_bsw_rt5672 | Not working |
| Camera | OMNIVISION OV2680 | atomisp | Not working |

## Linux installation

Disassemble the device, be careful not to damage those snaps under the back panel.

Locate the unpopulated micro USB port on the left edge of the motherboard:

![inside-with-usb-port-location](img/inside-with-usb-port-location.jpg)

Solder a micro USB female connector and connect an OTG adapter, or just a cable with a standard USB female connector to it, then short the fourth pin (or the `ID` pad) to the ground (GND), making the device function as an OTG host.

Flash a USB drive with your favorite Linux distro, I recommend using XFCE desktop environment since it only has 2 GB RAM.

Connect a keyboard and the drive to a USB hub and connect it to Movistar Home. Power it up while pressing the `F2` key, it will boot into BIOS setup, navigate to the last tab (`Save & Exit`), select your USB drive (should be something like `UEFI: USB, Partition 1`) in the `Boot Override` menu, press Enter key to boot it.

![bios](img/bios.jpg)

Install your linux as usual, it may be necessary to include non-free drivers.

## Configurations

The following configurations were made for Manjaro XFCE and may need to be adjusted for other distros.

### Fix screen rotation

Create file `/etc/X11/xorg.conf.d/20-monitor.conf` with following content:

```
Section "Monitor"
        Identifier      "DSI1"
        Option          "Rotate" "right"
        Option          "Scale"  "0.8x0.8"
EndSection
```

Adjust the scaling parameter to your liking, I found 0.8x most suitable for this screen.

### Fix touch screen

For some reason the touch screen won't work at all unless it's soft rebooted once, in dmesg the driver says "*Goodix-TS i2c-GDIX1001:00: Invalid config (0, 0, 0), using defaults*".

Create file `/etc/systemd/system/fix-touchscreen.service` with following content:

```systemd
[Unit]
Description=Fix touchscreen

[Service]
Type=oneshot
ExecStart=sh -c 'dmesg | grep -q " Goodix-TS .*: Invalid config " && reboot now || exit 0'

[Install]
WantedBy=multi-user.target
```

Then execute `sudo systemctl daemon-reload && systemctl enable fix-touchscreen.service` to make it run at boot.

For fixing rotation, create file `/etc/X11/xorg.conf.d/30-touchscreen.conf` with following content:

```
Section "InputClass"
        Identifier      "calibration"
        MatchProduct    "Goodix Capacitive TouchScreen"
        Option          "TransformationMatrix"  "0 1 0 -1 0 1 0 0 1"
EndSection
```

### Auto backlight dimming

Create file `/etc/X11/xorg.conf.d/10-intel.conf` with following content:

```
Section "Device"
        Identifier      "Intel Graphics"
        Driver          "intel"
        Option          "AccelMethod"   "sna"
        Option          "TearFree"      "true"
        Option          "Backlight"     "intel_backlight"
EndSection
```

Open Xfce's `Power Manager`, switch to `Display` tab, and adjust the `Brightness reduction` settings. I personally set it to reduce to 20% after 90 seconds of inactivity.

Remember also to disable the auto suspension/shutdown from there.

Create file `~/.config/autostart/set-backlight.desktop` with following content:

```systemd
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=Set Backlight Brightness
Comment=Set backlight brightness on startup
Exec=bash -c "echo 100 > /sys/class/backlight/intel_backlight/brightness"
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
```

(I found this is somehow not achievable with a systemd service)

### Virtual keyboard

Install *Onboard* with `sudo pacman -S onboard`, open Xfce's `Session and Startup` settings, switch to `Application Autostart` tab, find and enable `Onboard (Flexible onscreen keyboard)`.

After rebooting, open Onboard's settings and adjust them to your liking.

### Hide mouse cursor

Install *unclutter* with `sudo pacman -S unclutter`.

Create file `~/.config/autostart/hide-cursor.desktop` with following content:

```systemd
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=Hide Cursor
Comment=Hide mourse cursor
Exec=unclutter --hide-on-touch
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
```

### Home Assistant dashboard

Create file `~/.config/autostart/HASS.desktop` with following content:

```systemd
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=HASS Dashboard
Comment=Run HASS dashboard in Firefox kiosk
Exec=firefox -kiosk -url 'https://your.hass.url'
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
```

It's recommended to set up the OpenSSH server before unsoldering the USB connector and reassemble the device, for future maintenance.
