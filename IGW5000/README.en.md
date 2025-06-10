# Repurposing Movistar Home - IGW5000

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

As in the latest Arch Linux with 6.14.10-arch1-1 kernel, on June 10, 2025:

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

![inside-with-usb-port-location](../assets/img/inside-with-usb-port-location.jpg)

Solder a micro USB female connector and connect an OTG adapter cable; or just solder a cable with a standard USB-A female connector to it, then short the fourth pin (or the `ID` pad nearby) to the fifth pin GND (or any ground pad on the motherboard), making the port function as OTG host.

Here is an example for soldering a USB-A female connector:

![igw5000-usb-port-connection-1](../assets/img/igw5000-usb-port-connection-1.jpg)

Flash a USB drive with your favorite Linux distro.

Considering the Movistar Home has only 2 GB of RAM, it is highly recommended to only use a [window manager](https://wiki.archlinux.org/title/Window_manager). If you want to use a full desktop environment, consider using a lightweight one like _Xfce_.

Connect a keyboard and the drive to a USB hub and connect it to Movistar Home. Power it up while pressing the <kbd>F2</kbd> key, it will boot into the BIOS (UEFI) setup, navigate to the last tab (`Save & Exit`), select your USB drive (should be something like `UEFI: USB, Partition 1`) in the `Boot Override` menu, press <kbd>Enter</kbd> key to boot it.

![bios](../assets/img/bios.jpg)

Install your Linux distro as usual, it might be necessary to include _non-free_ drivers and firmwares.

> [!IMPORTANT]
> It is recommended to set up the OpenSSH server before unsoldering the USB connector and reassembling the device, for possible future maintenance.

## Configurations

The following configurations were made for [Arch Linux](https://archlinux.org/) with the [_Sway_](https://wiki.archlinux.org/title/Sway) window manager (based on the Wayland compositor _wlroots_), some modifications may be needed for other distros, window managers or desktop environments.

If you prefer to use a full desktop environment, please refer to the [legacy guide](../IGW5000/xfce.en.md) for Xfce.

### Improve Wi-Fi stability

Create the file `/etc/modprobe.d/99-movistar-home-panel.conf` with the following content:

```plaintext
# disable RTL8822BE power-saving
options rtw88_core disable_lps_deep=y
options rtw88_pci disable_msi=y disable_aspm=y
options rtw_core disable_lps_deep=y
options rtw_pci disable_msi=y disable_aspm=y
```

Then execute `sudo mkinitcpio -P` to regenerate the initramfs.

### Fix screen rotation and backlight control

Create the file `/etc/mkinitcpio.conf.d/99-movistar-home-panel.conf` with the following content:

```plaintext
MODULES=(i915 pwm-lpss-platform)
```

Create the file `/etc/udev/rules.d/10-movistar-home-panel-backlight.rules` with the following content:

```plaintext
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video $sys$devpath/brightness", RUN+="/bin/chmod g+w $sys$devpath/brightness"
```

Then execute `sudo mkinitcpio -P` to regenerate the initramfs.

Make sure to add your user to the `video` group with `sudo usermod -aG video $USER`.

Edit the Sway config file (default is `~/.config/sway/config`) to add the following content:

```nginx
# ...
# display
output DSI-1 {
  power on
  mode 800x1280
  position 0 0
  transform 90
  scale 1.25
  adaptive_sync on
  background #000000 solid_color
}
# ...
```

If you prefer the full resolution of 1280x800, you can change the `scale` to `1.0`.

### Fix touch screen

Add the following content to your Sway config file:

```nginx
# ...
# map touchscreen
input "1046:911:Goodix_Capacitive_TouchScreen" {
  map_to_output DSI-1
}
# ...
```

### Auto backlight dimming

Create the file `~/.config/systemd/user/sway-session.target` with the following content:

```systemd
[Unit]
Description=SwayWM session
BindsTo=graphical-session.target
Wants=graphical-session-pre.target
After=graphical-session-pre.target
```

Install [_swayidle_](https://man.archlinux.org/man/swayidle.1) with `sudo pacman -S swayidle`, then create the file `~/.config/systemd/user/swayidle.service` with the following content:

```systemd
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
```

Then execute `systemctl --user daemon-reload && systemctl --user enable --now sway-session.target swayidle.service` to make it run at startup.

The first rule (`timeout 3 ':' ...`) is for reactivating the screen and resuming the backlight after touching the screen when the screen had been turned off.

Adjust the values in of second rule to your liking, the one above is for dimming it to 15% after idling for 60 seconds.

And better to disable the systemd-backlight service with `sudo systemctl mask systemd-backlight@backlight\:intel_backlight.service`, to prevent it from interfering.

### Virtual keyboard

I haven't found a good virtual keyboard for Sway (Wayland) yet. If you have any suggestions, please share!

You can use the [_ydotool_](https://man.archlinux.org/man/ydotool.1.en) utility to simulate key presses and type texts, over SSH.

Install it with `sudo pacman -S ydotool`, then execute `systemctl --user daemon-reload && systemctl --user enable --now ydotool.service` to make it run at startup.

Check its readme on GitHub for [usage](https://github.com/ReimuNotMoe/ydotool?tab=readme-ov-file#usage) and [examples](https://github.com/ReimuNotMoe/ydotool?tab=readme-ov-file#examples).

### Hide mouse cursor

Edit the Sway config file and add the following content:

```nginx
# ...
# hide cursor
seat seat0 {
  hide_cursor 100
}
# ...
```

### Fix sound

> [!NOTE]
> **WORK IN PROGRESS**
> The contents of this section (especially the files) might be changing frequently, as we are still working on it.

> [!NOTE]
> Currently only the speakers are fixed, the microphones are still not working yet.

The built-in speaker amplifier is not enabled correctly by the driver for sound card RT5672, we need to set the GPIO 5 and 7 on gpiochip1 to logical HIGH.

<details markdown="1">

<summary markdown="span">Technical details</summary>

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

Execute `sudo systemctl daemon-reload && sudo systemctl enable --now fix-sound.service` to make it run at startup.

Edit the Sway config file and add the following content:

```nginx
# ...
# fix sound
exec alsaucm --card cht-bsw-rt5672 set _verb HiFi set _enadev Headphones
# ...
```

### Home Assistant dashboard

Create the file `~/.config/systemd/user/hass-dashboard.service` with the following content:

```systemd
[Unit]
Description=HASS dashboard
BindsTo=sway-session.target
After=sway-session.target

[Service]
Environment=HASS_DASHBOARD_URL=https://your.hass.url
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
            "${HASS_DASHBOARD_URL}"
Restart=on-failure
RestartSec=5
TimeoutStopSec=10
CPUAccounting=yes
BlockIOAccounting=yes
MemoryAccounting=yes
MemoryHigh=1.2G
MemoryMax=1.2G
MemorySwapMax=0

[Install]
WantedBy=sway-session.target
```

Then execute `systemctl --user daemon-reload && systemctl --user enable --now hass-dashboard.service` to make it run at startup.

If you prefer Firefox, replace the `ExecStart` line with:

```systemd
ExecStart=firefox -kiosk -url "${HASS_DASHBOARD_URL}"
```

Based on my testing, Chromium consumes less memory, is more responsive and stable than Firefox on this device, and has support for hardware acceleration (useful for viewing camera streams). You can also try [ungoogled-chromium](https://aur.archlinux.org/packages/ungoogled-chromium).

#### Control backlight from Home Assistant

Execute the command `python3 -m venv ~/panel-controller` to create a Python virtual environment, then execute `sudo pacman -S gtk4-layer-shell && ~/panel-controller/bin/pip install Flask==3.1.1 i3ipc==2.2.1 PyGObject==3.52.3 apscheduler==3.11.0` to install the required dependencies.

Then create the file `~/panel-controller/app.py` with the following content:

<details markdown="1">

<summary markdown="span">Python script app.py</summary>

```python
import logging
import os
import threading
from colorsys import hsv_to_rgb
from ctypes import CDLL
CDLL('libgtk4-layer-shell.so')
from functools import wraps

import gpiod
from apscheduler.schedulers.background import BackgroundScheduler
from flask import Flask, request
from i3ipc import Connection as SwayIPC

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Gtk4LayerShell', '1.0')
from gi.repository import Gtk, GLib
from gi.repository import Gtk4LayerShell as LayerShell

APP_ID = 'io.zry.panel-controller'

def auth_required(f):
    """Authentication decorator for endpoints"""
    @wraps(f)
    def decorator(*args, **kwargs):
        token = server.config.get('TOKEN', '')
        if token != '' and request.headers.get('Authorization', '') != f'Bearer {token}':
            return 'Unauthorized', 401
        return f(*args, **kwargs)
    return decorator

# HTTP API server
server = Flask(__name__)
log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)

@server.route('/display/state', methods=['GET'])
@auth_required
def get_display_state():
    """GET endpoint to get display state over Sway IPC"""
    try:
        ipc = SwayIPC()
        outputs = ipc.get_outputs()
        for o in outputs:
            if o.name == 'DSI-1':
                if o.dpms:
                    return 'ON', 200
                else:
                    return 'OFF', 200
        raise ValueError('Output not found')
    except Exception as e:
        return f'Failed to get display state: {e}', 500


@server.route('/display/state', methods=['POST'])
@auth_required
def set_display_state():
    """POST endpoint to set display state"""
    try:
        state = request.get_data(as_text=True).strip().upper()
        if not state:
            raise ValueError('Invalid state: empty')
        if state not in ['ON', 'OFF']:
            raise ValueError('Invalid state: must be "ON" or "OFF"')

        try:
            ipc = SwayIPC()
            if state == 'ON':
                result = ipc.command('output DSI-1 power on')
            else:
                result = ipc.command('output DSI-1 power off')
            if result and result[0].success:
                return state, 200
            else:
                error_msg = result[0].error if result and result[0].error else 'Unknown error'
                raise Exception(f'IPC command error: {error_msg}')
        except Exception as e:
            return f'Failed to set display state: {e}', 500
    except Exception as e:
        return str(e), 400

class ScreensaverWindow(Gtk.Window):
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self.set_default_size(1280, 800)
        LayerShell.init_for_window(self)
        LayerShell.set_layer(self, LayerShell.Layer.OVERLAY)
        LayerShell.set_anchor(self, LayerShell.Edge.LEFT, True)
        LayerShell.set_anchor(self, LayerShell.Edge.TOP, True)
        self.hue = 0
        self.drawing_area = Gtk.DrawingArea()
        self.drawing_area.set_draw_func(self.on_draw)
        self.set_child(self.drawing_area)
        click = Gtk.GestureClick.new()
        click.connect('pressed', lambda *args: self.close())  # close on click
        self.add_controller(click)
        GLib.timeout_add(15, self.update_color)

    def on_draw(self, area, ctx, width, height):
        r, g, b = hsv_to_rgb(self.hue / 360.0, 1.0, 1.0)
        ctx.set_source_rgb(r, g, b)
        ctx.paint()

    def update_color(self):
        self.hue += 1
        if self.hue > 360:
            self.close()
            return False
        self.drawing_area.queue_draw()
        return True

class ScreensaverApp(Gtk.Application):
    def __init__(self, enabled: bool = True):
        super().__init__(application_id=APP_ID)
        self.connect('activate', self.on_activate)
        self.enabled = enabled
        self.scheduler = None
        self.current_window = None

    def show_screensaver_window(self):
        def show_window():
            if self.current_window:
                self.current_window.close()
            self.current_window = ScreensaverWindow(self, application=self)
            self.current_window.present()
        GLib.idle_add(show_window)

    def on_activate(self, app):
        self.scheduler = BackgroundScheduler()
        if self.enabled:
            self.scheduler.add_job(
                func=self.show_screensaver_window,
                trigger='cron',
                hour='*',
            )
        self.scheduler.start()
        self.hold()

def run_api_server(host: str, port: int, token: str):
    """Run the Flask API server"""
    server.config['TOKEN'] = token
    server.run(host=host, port=port, debug=False, use_reloader=False)

if __name__ == '__main__':
    host = os.getenv('HOST', '0.0.0.0')
    port = os.getenv('PORT', 8080)
    token = os.getenv('TOKEN', '')
    # start API server in a separate thread
    server_thread = threading.Thread(target=run_api_server, args=(host, port, token,), daemon=True)
    server_thread.start()
    print(f'HTTP API server started on http://{host}:{port}')
    # start GTK application in the main thread
    screensaver_enabled = os.getenv('SCREENSAVER_ENABLED', '1') == '1'
    gtk_app = ScreensaverApp(screensaver_enabled)
    gtk_app.run(None)
```

</details>

Create the file `~/.config/systemd/user/panel-controller.service` with the following content:

```systemd
[Unit]
Description=Panel controller
BindsTo=sway-session.target
After=sway.service

[Service]
Environment=TOKEN=aa83720a-0bc1-4d5b-82fc-bf27a6682aa4
Type=simple
ExecStart=%h/panel-controller/bin/python %h/panel-controller/app.py
Restart=on-failure
RestartSec=5
TimeoutStopSec=10

[Install]
WantedBy=sway-session.target
```

Then execute `systemctl --user daemon-reload && systemctl --user enable --now panel-controller.service` to make it run at startup.

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

Since it will mostly be used to display a Home Assistant dashboard 24/7, it's very likely to get [screen burn-in](https://en.wikipedia.org/wiki/Screen_burn-in) after some time, albeit having an LCD screen.

To prevent that, this Python script also periodically (every hour) flashes several colors in full screen to refresh all the pixels. You can disable this feature by adding an environment variable `SCREENSAVER_ENABLED=0` in the service file like below:

```systemd
# ...
[Service]
Environment=TOKEN=aa83720a-0bc1-4d5b-82fc-bf27a6682aa4
Environment=SCREENSAVER_ENABLED=0
Type=simple
# ...
```

## Resources

- [Flash memory dump](https://t.me/movistar_home_hacking/93) using `dd`
