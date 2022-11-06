# Repurposing Movistar Home

as a Home Assistant dashboard panel.

[Versión en castellano](README.md)

[Research notes](researches.md)

![hass](img/hass.jpg)

## HELP NEEDED

I dumped the original Android-x86 firmware from flash, but it failed to boot after I wrote it back in, and the /data partition was encrypted and I couldn't find a way to decrypt it.

Contributions to the [repository](https://github.com/zry98/movistar-home-hacks) are very welcomed if you've got any discoveries; or if you have a Movistar Home not in use and willing to help this project, please contact me through my email in [GitHub profile](https://github.com/zry98), much appreciated!

### TODO list

- [ ] Fix sound card driver ([ALSA](https://en.wikipedia.org/wiki/Advanced_Linux_Sound_Architecture) configs)
- [ ] Fix camera driver
- [ ] Fix bluetooth driver
- [ ] Fix reset button
- [ ] Find a way to install Linux without disassembling nor soldering (maybe through [easycwmp on port 7547](researches.md#easycwmp))

## Tech specs

| | |
| --- | --- |
| CPU | Intel Atom x5-Z8350 (4C4T) @ 1.44 GHz |
| RAM | Hynix 2 GB DDR3 ECC @ 1600 MHz |
| Storage | Kingston TB2816 16 GB eMMC |
| Screen | 8-inch 1280x800 with Goodix I2C touch screen |
| Wi-Fi & Bluetooth | Realtek RTL8822BE |
| Sound card | Realtek RT5672 |
| Speakers | 2 x 5 W (SPL 87 dB @ 1 W \| 1 m) |
| Microphones | 4 omnidirectional microphones with dedicated DSP |
| Camera | OMNIVISION OV2680 with 2 megapixels |
| Dimensions | 21.2 x 23.5 x 12.2 cm (height x width x depth) |
| Weight | 1.1 kg |

## Driver status

As in the latest Manjaro XFCE with 5.15.71-1 kernel, on November 5, 2022:

| Device | Driver | Status |
| --- | --- | --- |
| Touch screen | goodix | OK |
| Wi-Fi | rtw88_8822be | OK |
| Bluetooth | rtw88_8822be | Not working |
| Sound card | snd_soc_sst_cht_bsw_rt5672 | Not working |
| Camera | atomisp | Not working |

## Linux installation

Disassemble the device, there are 10 snap-fits under the back panel edges, be careful not to damage them; then 8 screws under it.

Locate the unpopulated micro USB port on the left edge of the motherboard, for model `IGW-5000A2BKMP-I v2`:

![inside-with-usb-port-location](img/inside-with-usb-port-location.jpg)

For rev5 board in newer model `RG3205W` (I haven't tested one yet):

![board-rev5](img/board-rev5.jpg)

Solder a micro USB female connector and connect an OTG adapter cable; or just solder a cable with a standard USB-A female connector to it, then short the fourth pin (or the `ID` pad) to the ground (GND, the fifth pin), making the device function as an OTG host.

Flash a USB drive with your favorite Linux distro, I recommend using Xfce desktop environment considering the Movistar Home only has 2 GB RAM.

Connect a keyboard and the drive to a USB hub and connect it to Movistar Home. Power it up while pressing the `F2` key, it will boot into BIOS setup, navigate to the last tab (`Save & Exit`), select your USB drive (should be something like `UEFI: USB, Partition 1`) in the `Boot Override` menu, press Enter key to boot it.

![bios](img/bios.jpg)

Install your linux as usual, it may be necessary to include non-free drivers.

It's recommended to set up the OpenSSH server before unsoldering the USB connector and reassembling the device, for possible future maintenance.

## Configurations

The following configurations were made for Manjaro XFCE and may need some modifications for other distros.

### Fix screen rotation

Create file `/etc/X11/xorg.conf.d/20-monitor.conf` with the following content:

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

Create file `/etc/systemd/system/fix-touchscreen.service` with the following content:

```systemd
[Unit]
Description=Fix touchscreen

[Service]
Type=oneshot
ExecStart=sh -c 'dmesg | grep -q " Goodix-TS .*: Invalid config " && reboot now || exit 0'

[Install]
WantedBy=multi-user.target
```

Then execute `sudo systemctl daemon-reload && systemctl enable fix-touchscreen.service` to make it run at startup.

For fixing rotation, create file `/etc/X11/xorg.conf.d/30-touchscreen.conf` with the following content:

```
Section "InputClass"
        Identifier      "calibration"
        MatchProduct    "Goodix Capacitive TouchScreen"
        Option          "TransformationMatrix"  "0 1 0 -1 0 1 0 0 1"
EndSection
```

#### Fix touch control in Firefox

*Source: [Firefox/Tweaks - ArchWiki](https://wiki.archlinux.org/title/Firefox/Tweaks#Enable_touchscreen_gestures)*

Open Firefox and access `about:config`, search for `dom.w3c_touch_events.enabled` and make sure it's either set to 1 (*enabled*) or 2 (*default, auto-detect*).

Add `MOZ_USE_XINPUT2 DEFAULT=1` to `/etc/security/pam_env.conf`.

### Auto backlight dimming

Create file `/etc/X11/xorg.conf.d/10-intel.conf` with the following content:

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

Create file `~/.config/autostart/set-backlight.desktop` with the following content:

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

Install [*Onboard*](https://archlinux.org/packages/community/x86_64/onboard/) with `sudo pacman -S onboard`, open Xfce's `Session and Startup` settings, switch to `Application Autostart` tab, find and enable `Onboard (Flexible onscreen keyboard)`.

After rebooting, open Onboard's settings and adjust them to your liking.

### Hide mouse cursor

Install [*unclutter*](https://archlinux.org/packages/community/x86_64/unclutter/) with `sudo pacman -S unclutter`.

Create file `~/.config/autostart/hide-cursor.desktop` with the following content:

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

Create file `~/.config/autostart/HASS.desktop` with the following content:

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

This will run Firefox in kiosk mode at startup, which you can only exit by pressing alt+F4 or using kill command in SSH.

### Prevent screen burn-in

Since it will mostly be used to display a HASS dashboard 24/7, it's very likely to get [screen burn-in](https://en.wikipedia.org/wiki/Screen_burn-in) after some time, although it has an LCD screen.

To prevent that, I wrote a Python script to have it periodically flash several colors in full screen to refresh all the pixels.

**DO NOT USE this script if you or a family member has [photosensitive epilepsy](https://en.wikipedia.org/wiki/Photosensitive_epilepsy)!**

Create file `/usr/bin/screensaver.py` with the following content:

```python
#!/usr/bin/env python3
from time import time
import tkinter as tk

color_interval = 300  # milliseconds
total_time = 10  # seconds, exit after that

colors = ['red', 'green', 'blue', 'black', 'white']
color_index = 0

root = tk.Tk()
w, h = root.winfo_screenwidth(), root.winfo_screenheight()
root.overrideredirect(True)
root.attributes('-fullscreen', True)
canvas = tk.Canvas(root, width=w, height=h, background='black', highlightthickness=0)
canvas.pack()
canvas.focus_set()
canvas.bind('<Button-1>', lambda _: root.destroy())  # exit on touch


def flash_color():
    global color_index
    if time() - time_start > total_time: root.destroy()
    canvas.configure(background=colors[color_index])
    color_index = (color_index + 1) % len(colors)
    root.after(color_interval, flash_color)


time_start = time()
flash_color()
root.mainloop()
```

Adjust the two variables `color_interval` and `total_time` to your liking, with `total_time = 10` it will be running for 10 seconds, just touch the screen if you need to stop it immediately.

Run command `chmod +x /usr/bin/screensaver.py` to make it executable, then run command `crontab -e` and add a cron job as following, which will run the script every hour:

```crontab
0 * * * *       export DISPLAY=:0; /usr/bin/screensaver.py
```
