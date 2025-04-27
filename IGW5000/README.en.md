# Repurposing Movistar Home

as a Home Assistant dashboard panel.

**This document is only intended for the model `IGW-5000A2BKMP-I v2` with an Intel x86 CPU. For the model `RG3205W` with a Qualcomm arm64 SoC, please refer to [RG3205W/README.en.md](../RG3205W/README.en.md). [_How to identify?_](../README.en.md#important-note)**

[🇪🇸 Versión en castellano](../IGW5000/README.md)

[Research notes](../researches/IGW5000.md)

## HELP NEEDED

I dumped the original Android-x86 firmware from flash, but it failed to boot after I wrote it back in.

Any contributions to the [repository](https://github.com/zry98/movistar-home-hacks) are very welcomed.

If you have any questions or want to help this project, please join our [Telegram group chat](https://t.me/movistar_home_hacking).

### TODO list

- [ ] Fix sound card driver
  - [x] Fix speakers
  - [ ] Fix microphones (maybe [ALSA](https://en.wikipedia.org/wiki/Advanced_Linux_Sound_Architecture) configs)
- [ ] Fix camera driver
- [ ] Fix bluetooth driver
- [ ] Fix reset button
- [ ] Find a way to install Linux without disassembling or soldering (maybe through [easycwmp on port 7547](../researches/IGW5000.md#easycwmp))

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

As in the latest Manjaro Xfce 25.0.0 with 6.12.21-4 kernel, on April 27, 2025:

| Device | Driver | Status |
| --- | --- | --- |
| Touch screen | goodix_ts | OK |
| Wi-Fi | rtw88_8822be | OK |
| Bluetooth | rtw88_8822be | Not working |
| Sound card | snd_soc_sst_cht_bsw_rt5672 | Speakers OK, microphones not working |
| Camera | atomisp | Not working in kernel 5.15, unavailable in kernel 6.2+ |

## Linux installation

### Disassembling

Disassemble the device, it has **10 snap-fits** under the back panel edges, be careful not to damage them; then **8 screws** under the panel, and **4 screws** hidden under the rubber strip at the bottom of the device.

Locate the unpopulated micro USB port on the left edge of the motherboard:

![inside-with-usb-port-location](../img/inside-with-usb-port-location.jpg)

Solder a micro USB female connector and connect an OTG adapter cable; or just solder a cable with a standard USB-A female connector to it, then short the fourth pin (or the `ID` pad nearby) to the fifth pin GND (or any ground pad on the motherboard), making the port function as OTG host.

Here is an example for soldering a USB-A female connector:

![igw5000-usb-port-connection-1](../img/igw5000-usb-port-connection-1.jpg)

Flash a USB drive with your favorite Linux distro, it is recommended to use a lightweight desktop environment like Xfce, considering the Movistar Home has only 2 GB of RAM.

Connect a keyboard and the drive to a USB hub and connect it to Movistar Home. Power it up while pressing the <kbd>F2</kbd> key, it will boot into the BIOS (UEFI) setup, navigate to the last tab (`Save & Exit`), select your USB drive (should be something like `UEFI: USB, Partition 1`) in the `Boot Override` menu, press <kbd>Enter</kbd> key to boot it.

![bios](../img/bios.jpg)

Install your Linux distro as usual, it might be necessary to include _non-free_ drivers and firmwares.

> [!IMPORTANT]
> It is recommended to set up the OpenSSH server before unsoldering the USB connector and reassembling the device, for possible future maintenance.

## Configurations

The following configurations were made for Manjaro with Xfce and may need some modifications for other distros or desktop environments.

### Fix screen rotation

Install the driver `xf86-video-intel` with the command `sudo pacman -S xf86-video-intel`.

Create the file `/etc/X11/xorg.conf.d/20-monitor.conf` with the following content:

```plaintext
Section "Monitor"
    Identifier    "DSI1"
    Option        "Rotate" "right"
    Option        "DPMS" "true"
EndSection

Section "ServerFlags"
    Option        "StandbyTime" "0"
    Option        "SuspendTime" "0"
    Option        "OffTime"     "0"
EndSection
```

In Xfce's Display Settings, adjust the scaling to your liking, I found 0.8x (1024x640 effectively) being the most suitable for this screen.

### Fix touch screen

For some reason the touch screen won't work at all unless it has been soft rebooted once, in dmesg the driver says "Goodix-TS i2c-GDIX1001:00: Invalid config (0, 0, 0), using defaults".

To fix this, create the file `/etc/systemd/system/fix-touchscreen.service` with the following content:

```systemd
[Unit]
Description=Fix touchscreen

[Service]
Type=oneshot
ExecStart=sh -c 'dmesg | grep -q " Goodix-TS .*: Invalid config " && reboot now || exit 0'

[Install]
WantedBy=multi-user.target
```

Then execute `sudo systemctl daemon-reload && sudo systemctl enable fix-touchscreen.service` to make it run at startup.

To fix rotation, create the file `/etc/X11/xorg.conf.d/30-touchscreen.conf` with the following content:

```plaintext
Section "InputClass"
    Identifier      "calibration"
    MatchProduct    "Goodix Capacitive TouchScreen"
    Option          "TransformationMatrix" "0 1 0 -1 0 1 0 0 1"
EndSection
```

#### Fix touch control in Firefox

_Source: [Firefox/Tweaks - ArchWiki](https://wiki.archlinux.org/title/Firefox/Tweaks#Enable_touchscreen_gestures)_

Open Firefox and access `about:config`, search for `dom.w3c_touch_events.enabled` and make sure it's either set to 1 (_enabled_) or 2 (_default, auto-detect_).

Also add `MOZ_USE_XINPUT2 DEFAULT=1` to `/etc/security/pam_env.conf`.

### Auto backlight dimming

Modify the file `/etc/mkinitcpio.conf` to include `i915` and `pwm-lpss-platform` in the `MODULES` array like below:

```plaintext
...
MODULES=(i915 pwm-lpss-platform)
...
```

Then execute `sudo mkinitcpio -P` to regenerate the initramfs.

Create the file `/etc/X11/xorg.conf.d/10-intel.conf` with the following content:

```plaintext
Section "Device"
    Identifier    "Intel Graphics"
    Driver        "intel"
    Option        "AccelMethod" "sna"
    Option        "TearFree"    "true"
    Option        "Backlight"   "intel_backlight"
EndSection
```

Open Xfce's `Power Manager`, switch to `Display` tab, and adjust the `Brightness reduction` settings. I personally set it to reduce to 20% after 90 seconds of inactivity.

Remember also to disable the auto suspension/shutdown from there.

Create the file `/etc/udev/rules.d/backlight.rules` with the following content:

```plaintext
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/bin/chgrp video $sys$devpath/brightness", RUN+="/bin/chmod g+w $sys$devpath/brightness", ATTR{brightness}="100"
```

And better to disable the systemd-backlight service with `sudo systemctl mask systemd-backlight@backlight\:intel_backlight.service`, to prevent it from interfering.

### Virtual keyboard

Install [_Onboard_](https://launchpad.net/onboard) with `sudo pacman -S onboard`, open Xfce's `Session and Startup` settings, switch to `Application Autostart` tab, find and enable `Onboard (Flexible onscreen keyboard)`.

After rebooting, open Onboard's settings and adjust them to your liking.

### Hide mouse cursor

Install [_unclutter_](https://github.com/Airblader/unclutter-xfixes) with `sudo pacman -S unclutter`.

Create the file `~/.config/autostart/hide-cursor.desktop` with the following content:

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

### Fix sound

> [!NOTE]
> **WORK IN PROGRESS**
> The contents of this section (especially the files) might be changing frequently, as we are still working on it.

> [!NOTE]
> Currently only the speakers are fixed, the microphones are still not working yet.

The built-in speaker amplifier is not enabled correctly by the driver for sound card RT5672, we need to set the GPIO 5 and 7 on gpiochip1 to logical HIGH.

<details>

<summary>Technical details</summary>

The amplifier IC Realtek ALC1304 is compatible with the TI [TPA313xD2](https://www.ti.com/lit/ds/slos841b/slos841b.pdf).

The GPIO 5 on gpiochip1 controls the logic level on the amp's pin 29 (`SDZ`), by setting it to HIGH, the pin will be pulled to HIGH, enabling the amplifier.

> Pin 29 `SDZ`: Shutdown logic input for audio amp (LOW = outputs Hi-Z, HIGH = outputs enabled).

The GPIO 7 on gpiochip1 controls the amp's pin 7 (`MUTE`), by setting it to HIGH, the pin will be pulled to LOW, enabling the output.

> Pin 7 `MUTE`: Mute signal for fast disable/enable of outputs: HIGH = outputs OFF (high-Z), LOW = outputs ON.

</details>

Execute `sudo pacman -S alsa-utils alsa-ucm-conf libgpiod` to install the necessary stuff, then create the file `/etc/systemd/system/fix-sound.service` with the following content:

```systemd
[Unit]
Description=Fix sound

[Service]
Type=simple
ExecStart=gpioset -c 1 5=1 7=1

[Install]
WantedBy=multi-user.target
```

Execute `sudo systemctl daemon-reload && sudo systemctl enable fix-sound.service` to make it run at startup.

Create the file `~/.config/autostart/switch-alsa-ucm.desktop` with the following content:

```systemd
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=Switch ALSA UCM
Comment=For fixing the speakers
Exec=alsaucm -c cht-bsw-rt5672 set _verb HiFi set _enadev Headphones
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
```

### Home Assistant dashboard

Create the file `~/.config/autostart/HASS.desktop` with the following content:

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

This will run Firefox in kiosk mode at startup, which you can only exit by pressing `Alt+F4` or using the `kill` command over SSH.

#### Control backlight from Home Assistant

> [!TIP]
> As mentioned in [ArchLinux Wiki](https://wiki.archlinux.org/title/Xfce#Display_blanking), for `xset` to be able to control DPMS, you need to disable:
>  1. Screen dimming in Xfce's `Power Manager`.
>  2. Xfce's `XScreenSaver`.

Run `sudo pacman -S python-flask` to install _Flask_, then create the file `~/.local/bin/panel_server.py` with the following content:

<details>

<summary>Python script panel_server.py</summary>

```python
#!/usr/bin/env python3
import logging
import os
from subprocess import run
from time import sleep

from flask import Flask, request
from werkzeug.wrappers import Request, Response

TOKEN = os.environ.get('TOKEN', '')


class middleware():
    def __init__(self, app):
        self.app = app

    def __call__(self, env, start_resp):
        request = Request(env)
        if TOKEN != '' and request.headers.get('Authorization') != f'Bearer {TOKEN}':
            res = Response('Unauthorized', mimetype='text/plain', status=401)
            return res(env, start_resp)
        return self.app(env, start_resp)


app = Flask(__name__)
app.wsgi_app = middleware(app.wsgi_app)
log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)


@app.route('/display/state', methods=['GET'])
def get_display_state():
    cmd = f"xset -display :0.0 q | grep '^  Monitor is' | awk '{{print $NF}}'"
    state = run(cmd, shell=True, capture_output=True).stdout.decode().strip()
    if state == 'On':
        return 'ON', 200
    elif state == 'Off':
        return 'OFF', 200
    else:
        return f'Unknown state "{state}"', 500


@app.route('/display/state', methods=['POST'])
def set_display_state():
    req_body = request.get_data().decode()
    if req_body == 'OFF':
        cmd = f'xset -display :0.0 dpms force off'
    elif req_body == 'ON':
        cmd = f'xset -display :0.0 dpms force on'
    else:
        return 'Bad Request', 400

    ret = run(cmd, shell=True).returncode
    if ret == 0:
        return req_body, 200
    else:
        return f'Command returned {ret}', 500


def init_display():
    while True:
        out = run(f"xset -display :0.0 q | grep '^  DPMS is '", shell=True, capture_output=True).stdout.decode()
        if 'Disabled' in out or 'Enabled' in out:
            break
        sleep(3)
    ret = run(f'xset -display :0.0 dpms force on', shell=True).returncode
    if ret != 0:
        print(f'Failed to turn on display: command returned {ret}')
        exit(ret)


if __name__ == '__main__':
    init_display()

    app.run(host=os.environ.get('HOST', '0.0.0.0'), port=os.environ.get('PORT', 8080))
```

</details>

Execute `systemctl edit --user --force --full panelserver.service`, which will create a systemd service file and edit it in your default editor (can be overridden by setting the environment variable `EDITOR`, e.g., `EDITOR=nano systemctl edit ...`), then put in the following content:

```systemd
[Unit]
Description=Panel Server
After=network.target graphical.target

[Service]
Environment=TOKEN=aa83720a-0bc1-4d5b-82fc-bf27a6682aa4  # replace it with your secret token
Environment=DISPLAY=:0
NoNewPrivileges=true
ExecStart=/usr/bin/python3 /home/panel/.local/bin/panel_server.py  # replace it with your actual path
Restart=always

[Install]
WantedBy=default.target
```

Save it and execute `systemctl daemon-reload --user && systemctl enable --user --now panelserver.service` to make it run at startup.

Create a [RESTful Switch](https://www.home-assistant.io/integrations/switch.rest/) in your Home Assistant's YAML config like:

```yaml
switch:
  - platform: rest
    name: Panel Display
    unique_id: panel_display
    resource: http://panel:8080/display/state  # replace `panel` with your panel's hostname or IP address
    body_on: 'ON'
    body_off: 'OFF'
    is_on_template: '{{ value == "ON" }}'
    headers:
      Authorization: Bearer aa83720a-0bc1-4d5b-82fc-bf27a6682aa4  # replace it with your secret token (after `Bearer `)
    verify_ssl: false
    icon: mdi:tablet-dashboard
```

Reload your Home Assistant instance, use _Developer Tools_ to test the switch and sensor.

Then you can use it in Automations, e.g., turn it off when you go to sleep at night and turn it back on when you get up in the morning.

### Prevent screen burn-in

Since it will mostly be used to display a Home Assistant dashboard 24/7, it's very likely to get [screen burn-in](https://en.wikipedia.org/wiki/Screen_burn-in) after some time, albeit having an LCD screen.

To prevent that, a Python script can be used to have it periodically flash several colors in full screen to refresh all the pixels. If you prefer, it can also refresh the browser tab at the same time to fix any potential problem like tab crashing.

> [!CAUTION]
> **DO NOT USE this script if you or a family member has [photosensitive epilepsy](https://en.wikipedia.org/wiki/Photosensitive_epilepsy)!**

Install the required packages with `sudo pacman -S tk xdotool` and create the file `~/.local/bin/screensaver.py` with the following content:

<details>

<summary>Python script screensaver.py</summary>

```python
#!/usr/bin/env python3
import os
import threading
import tkinter as tk
from subprocess import run
from time import time

color_interval = int(os.environ.get('COLOR_INTERVAL', 300))  # milliseconds
total_time = int(os.environ.get('TOTAL_TIME', 10))  # seconds, exit after that
colors = ['red', 'green', 'blue', 'black', 'white']

root = tk.Tk()
w, h = root.winfo_screenwidth(), root.winfo_screenheight()
root.overrideredirect(True)
root.attributes('-fullscreen', True)
canvas = tk.Canvas(root, width=w, height=h, background='black', highlightthickness=0)
canvas.pack()
canvas.focus_set()
canvas.bind('<Button-1>', lambda _: root.destroy())  # exit on touch

color_index = 0


def show_color():
    global color_index
    if time() - time_start > total_time:
        root.destroy()
        return
    canvas.configure(background=colors[color_index])
    color_index = (color_index + 1) % len(colors)
    root.after(color_interval, show_color)


def refresh_browser(window_class: str):
    window_id = run(f'xdotool search --onlyvisible --class "{window_class}" | head -1',
                    shell=True, capture_output=True).stdout.decode().strip()
    ret = run(f'xdotool windowactivate {window_id}', shell=True).returncode
    if ret != 0:
        print(f'Failed to activate window {window_id}')
    ret = run(f'xdotool key F5', shell=True).returncode
    if ret != 0:
        print(f'Failed to send F5 key to window {window_id}')


# refresh browser window
browser_window_class = os.environ.get('BROWSER_WINDOW_CLASS', '')
if browser_window_class:
    refresh_thread = threading.Thread(target=refresh_browser, args=(browser_window_class,))
    refresh_thread.start()
# screensaver
time_start = time()
show_color()
root.mainloop()
```

</details>

Execute `chmod +x ~/.local/bin/screensaver.py` to make it executable, then execute `crontab -e` and add a cron job like below, which will run the script every hour:

```crontab
0 * * * *	DISPLAY=:0 COLOR_INTERVAL=300 TOTAL_TIME=10 BROWSER_WINDOW_CLASS="firefox" /home/panel/.local/bin/screensaver.py  # replace it with your actual path
```

Adjust the two environment variables `COLOR_INTERVAL` and `TOTAL_TIME` to your liking, with a `TOTAL_TIME` of 10 it will be running for 10 seconds. If you need to stop it immediately, just touch the screen.

If you are using another browser (e.g., `chromium`) for the dashboard, change the value of `BROWSER_WINDOW_CLASS` accordingly; if you don't want to refresh the browser tab, just remove it.

## Resources

- [Flash memory dump](https://t.me/movistar_home_hacking/93) using `dd`
