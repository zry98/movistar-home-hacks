# Reutilización de Movistar Home - IGW5000

como un panel de dashboard para Home Assistant.

**Este documento solo está destinado al modelo `IGW-5000A2BKMP-I v2` con una CPU x86 de Intel. Para el modelo `RG3205W` con un SoC arm64 de Qualcomm, por favor consulta [RG3205W/README.md](../RG3205W/README.md). [_¿Cómo identificarlo?_](../README.md#nota-importante)**

[🇺🇸 English version](../IGW5000/README.en.md)

[Notas de investigación (en inglés)](../researches/IGW5000.md)

## SE NECESITA AYUDA

Extraje el firmware original de Android-x86 en la memoria flash, pero no logró arrancar después de volver a escribirlo.

Cualquier contribución al [repositorio](https://github.com/zry98/movistar-home-hacks) será muy bienvenida.

Si tienes alguna pregunta o quieres ayudar en este proyecto, por favor únete a nuestro [grupo de Telegram](https://t.me/movistar_home_hacking).

### Lista de tareas

- [ ] Arreglar el driver de la tarjeta de sonido
  - [x] Arreglar los altavoces
  - [ ] Arreglar los micrófonos (quizás las configuraciones de [ALSA](https://en.wikipedia.org/wiki/Advanced_Linux_Sound_Architecture))
- [ ] Arreglar el driver de la cámara
- [ ] Arreglar el driver de bluetooth
- [ ] Arreglar el botón de reinicio
- [ ] Encontrar una manera de instalar Linux sin desmontar ni soldar (quizás a través del [easycwmp en el puerto 7547](../researches/IGW5000.md#easycwmp))

## Especificaciones

| | |
| --- | --- |
| CPU | Intel Atom x5-Z8350 (4C4T) @ 1,44 GHz |
| RAM | Hynix 2 GB DDR3 ECC @ 1600 MHz |
| Almacenamiento | Kingston TB2816 16 GB eMMC |
| Pantalla | 8 pulgadas 1280x800 con pantalla táctil de I2C de Goodix |
| Wi-Fi & Bluetooth | Realtek RTL8822BE |
| Tarjeta de sonido | Realtek RT5672 |
| Altavoces | 2 x 5 W (SPL 87 dB @ 1 W \| 1 m) |
| Micrófonos | 4 micrófonos omnidireccionales con DSP dedicado |
| Cámara | OMNIVISION OV2680 con 2 megapíxeles |
| Medidas | 21,2 x 23,5 x 12,2 cm (alto x ancho x fondo) |
| Peso | 1,1 kg |

## Estado de los drivers

Como en el último Arch Linux con kernel 6.14.10-arch1-1, el 10 de junio de 2025:

| Dispositivo | Driver | Estado |
| --- | --- | --- |
| Pantalla táctil | goodix_ts | OK |
| Wi-Fi | rtw88_8822be | OK |
| Bluetooth | rtw88_8822be | No funciona |
| Tarjeta de sonido | snd_soc_sst_cht_bsw_rt5672 | Altavoces OK, micrófonos no funcionan |
| Cámara | atomisp | No funciona en kernel 5.15, no disponible en 6.2+ |

## Instalación de Linux

### Desmontaje

Desmonta el dispositivo, tiene **10 presillas** debajo de los bordes del panel posterior, ten cuidado de no dañarlos; luego hay **8 tornillos** debajo del panel, y **4 tornillos** ocultos debajo de la tira de goma en la parte de abajo del dispositivo.

Localiza el puerto micro USB desocupado en el borde izquierdo de la placa base:

![inside-with-usb-port-location](../img/inside-with-usb-port-location.jpg)

Suelda un conector hembra de micro USB y conecta un cable adaptador OTG; o simplemente suelda un cable con un conector hembra de USB-A estándar, luego cortocircuita el cuarto pin (o el pad `ID` cercano) a el quinto pin GND (o cualquier pad de tierra en la placa), haciendo que el puerto funcione como un _OTG host_.

Aquí es un ejemplo para soldar un conector USB-A hembra:

![igw5000-usb-port-connection-1](../img/igw5000-usb-port-connection-1.jpg)

Flashea un pendrive USB con tu distribución de Linux favorita.

Teniendo en cuenta que el Movistar Home solo tiene 2 GB de RAM, se recomienda encarecidamente usar solo [gestor de ventanas](https://wiki.archlinux.org/title/Window_manager_(Espa%C3%B1ol)). Si deseas usar un entorno de escritorio completo, considera uno muy ligero como _Xfce_.

Conecta un teclado y el pendrive a un hub de USB y conéctalo al Movistar Home. Enciéndelo mientras presiona la tecla <kbd>F2</kbd>, se iniciará a la configuración del BIOS (UEFI), navega a la última pestaña (`Save & Exit`), selecciona tu pendrive (debería ser algo así como `UEFI: USB, Partition 1`) en el menú `Boot Override`, presiona la tecla <kbd>Intro</kbd> (<kbd>Enter</kbd>) para iniciarlo.

![bios](../img/bios.jpg)

Instala tu distribución de Linux como de costumbre, puede ser necesario incluir los drivers y firmwares _non-free_.

> [!IMPORTANT]
> Se recomienda configurar el servidor OpenSSH antes de desoldar el conector USB y volver a montar el dispositivo, para los posibles mantenimientos en el futuro.

## Configuraciones

Las siguientes configuraciones se realizaron para [Arch Linux](https://archlinux.org/) con el gestor de ventanas [_Sway_](https://wiki.archlinux.org/title/Sway) (basado en el compositor de Wayland _wlroots_), y es posible que necesiten algunas modificaciones para las otras distribuciones, gestores de ventanas o entornos de escritorio.

Si deseas usar un entorno de escritorio completo, consulta la [guía antigua](../IGW5000/xfce.md) para Xfce.

### Mejorar la estabilidad del Wi-Fi

Crea el fichero `/etc/modprobe.d/99-movistar-home-panel.conf` con el siguiente contenido:

```plaintext
# disable RTL8822BE power-saving
options rtw88_core disable_lps_deep=y
options rtw88_pci disable_msi=y disable_aspm=y
options rtw_core disable_lps_deep=y
options rtw_pci disable_msi=y disable_aspm=y
```

Y ejecuta `sudo mkinitcpio -P` para regenerar el _initramfs_.

### Arreglar la pantalla táctil y el control de la retroiluminación

Crea el fichero `/etc/mkinitcpio.conf.d/99-movistar-home-panel.conf` con el siguiente contenido:

```plaintext
MODULES=(i915 pwm-lpss-platform)
```

Crea el fichero `/etc/udev/rules.d/10-movistar-home-panel-backlight.rules` con el siguiente contenido:

```plaintext
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video $sys$devpath/brightness", RUN+="/bin/chmod g+w $sys$devpath/brightness"
```

Y ejecuta `sudo mkinitcpio -P` para regenerar el _initramfs_.

Asegúrate de añadir tu usuario al grupo `video` con `sudo usermod -aG video $USER`.

Edita el fichero de configuración de Sway (por defecto es `~/.config/sway/config`) y añade el siguiente contenido:

```nginx
# ...
# pantalla
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

Si prefieres la resolución completa de 1280x800, puedes cambiar el `scale` a `1.0`.

### Arreglar la pantalla táctil

Añade el siguiente contenido al fichero de configuración de Sway:

```nginx
# ...
# mapea la pantalla táctil
input "1046:911:Goodix_Capacitive_TouchScreen" {
  map_to_output DSI-1
}
# ...
```

### Reducción automática de brillo

Crea el fichero `~/.config/systemd/user/sway-session.target` con el siguiente contenido:

```systemd
[Unit]
Description=Sesión SwayWM
BindsTo=graphical-session.target
Wants=graphical-session-pre.target
After=graphical-session-pre.target
```

Instala [_swayidle_](https://man.archlinux.org/man/swayidle.1) con `sudo pacman -S swayidle`, y crea el fichero `~/.config/systemd/user/swayidle.service` con el siguiente contenido:

```systemd
[Unit]
Description=Swayidle
BindsTo=sway-session.target
After=sway-session.target

[Service]
Type=simple
# brillo al 100% al iniciar
ExecStartPre=brightnessctl --quiet --device=intel_backlight set 100
# reducer al 15% tras 60 segundos de inactividad
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

Luego ejecuta `systemctl --user daemon-reload && systemctl --user enable --now sway-session.target swayidle.service` para que se ejecute al iniciar.

La primera regla (`timeout 3 ':' ...`) sirve para reactivar la pantalla tras tocarla si estaba apagada.

Ajusta los valores de la segunda regla a tu gusto. El ejemplo reduce al 15% tras 60 segundos de inactividad.

Además, es recomendable desactivar el servicio systemd-backlight con `sudo systemctl mask systemd-backlight@backlight\:intel_backlight.service` para evitar interferencias.

### Teclado virtual

Aún no he encontrado un buen teclado virtual para Sway (Wayland). Si tienes alguna sugerencia, ¡no dudes en compartirla!

Puedes usar la utilidad [_ydotool_](https://man.archlinux.org/man/ydotool.1.en) para simular teclas y escribir textos, a través de SSH.

Instálalo con `sudo pacman -S ydotool`, y ejecuta `systemctl --user daemon-reload && systemctl --user enable --now ydotool.service` para que se ejecute al iniciar.

Consulta su documentación en GitHub para ver [cómo se usa](https://github.com/ReimuNotMoe/ydotool?tab=readme-ov-file#usage) y [ejemplos](https://github.com/ReimuNotMoe/ydotool?tab=readme-ov-file#examples).

### Ocultar cursor del ratón

Edita el fichero de configuración de Sway y añade lo siguiente:

```nginx
# ...
# oculta el cursor del ratón
seat seat0 {
  hide_cursor 100
}
# ...
```

### Arreglar el sonido

> [!NOTE]
> **TRABAJO EN CURSO**
> El contenido de esta sección (especialmente los ficheros) podría cambiar frecuentemente, ya que seguimos trabajando en ello.

> [!NOTE]
> Actualmente solo se han arreglado los altavoces; los micrófonos aún no funcionan.

El amplificador integrado para los altavoces no se activa correctamente mediante el driver de la tarjeta de sonido RT5672. Tenemos que configurar los GPIO 5 y 7 de gpiochip1 al nivel lógico ALTO.

<details>

<summary>Detalles técnicos</summary>

El amplificador integrado Realtek ALC1304 es compatible con el TI [TPA313xD2](https://www.ti.com/lit/ds/slos841b/slos841b.pdf).

El GPIO 5 de gpiochip1 controla el nivel lógico en el pin 29 (`SDZ`) del amplificador; al configurarlo en ALTO, el pin se pone en estado ALTO, activando el amplificador.

> Pin 29 `SDZ`: Entrada lógica de apagado para el amplificador de audio (BAJO = salidas en Hi-Z, ALTO = salidas activadas).

El GPIO 7 de gpiochip1 controla el pin 7 (`MUTE`) del amplificador; al configurarlo en ALTO, el pin se pone en estado BAJO, habilitando la salida.

> Pin 7 `MUTE`: Señal de silencio para desactivar/activar rápidamente las salidas: ALTO = salidas apagadas (high-Z), BAJO = salidas encendidas.

</details>

Ejecuta `sudo pacman -S alsa-utils alsa-ucm-conf libgpiod` para instalar los paquetes necesarios, luego crea el fichero `/etc/systemd/system/fix-sound.service` con el siguiente contenido:

```systemd
[Unit]
Description=Arreglar sonido

[Service]
Type=simple
ExecStart=gpioset -c 1 5=1 7=1

[Install]
WantedBy=multi-user.target
```

Ejecuta `sudo systemctl daemon-reload && sudo systemctl enable fix-sound.service` para que se ejecute al iniciar.

Edita el fichero de configuración de Sway y añade lo siguiente:

```nginx
# ...
# arregla el sonido
exec alsaucm --card cht-bsw-rt5672 set _verb HiFi set _enadev Headphones
# ...
```

### Home Assistant dashboard

Crea el fichero `~/.config/systemd/user/hass-dashboard.service` con el siguiente contenido:

```systemd
[Unit]
Description=HASS dashboard
BindsTo=sway-session.target
After=sway-session.target

[Service]
Environment=HASS_DASHBOARD_URL=https://tu.hass.url
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

Y ejecuta `systemctl --user daemon-reload && systemctl --user enable --now hass-dashboard.service` para que se ejecute al iniciar.

Si prefieres Firefox, reemplaza la línea `ExecStart` por:

```systemd
ExecStart=firefox -kiosk -url "${HASS_DASHBOARD_URL}"
```

Según mis pruebas, Chromium consume menos memoria, es más fluido y soporta aceleración por hardware (útil para ver cámaras). También puedes probar [ungoogled-chromium](https://aur.archlinux.org/packages/ungoogled-chromium).

### Controlar la retroiluminación desde Home Assistant

Ejecuta `python3 -m venv ~/panel-controller` para crear un entorno virtual de Python, y ejecuta `sudo pacman -S gtk4-layer-shell && ~/panel-controller/bin/pip install Flask==3.1.1 i3ipc==2.2.1 PyGObject==3.52.3 apscheduler==3.11.0` para instalar las dependencias necesarias.

Luego crea el fichero `~/panel-controller/app.py` con el siguiente contenido:

<details>

<summary>Python script app.py</summary>

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

</details><br>

Crea el fichero `~/.config/systemd/user/panel-controller.service` con el siguiente contenido:

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

Y ejecuta `systemctl --user daemon-reload && systemctl --user enable --now panel-controller.service` para que se ejecute al iniciar.

Crea un [Interruptor de RESTful](https://www.home-assistant.io/integrations/switch.rest/) en la configuración YAML de tu Home Assistant como:

```yaml
switch:
  - platform: rest
    name: Pantalla del Panel
    unique_id: pantalla_panel
    resource: http://panel:8080/display/state  # reemplaza `panel` con el nombre de host o la dirección IP de tu panel
    body_on: 'ON'
    body_off: 'OFF'
    is_on_template: '{{ value == "ON" }}'
    headers:
      Authorization: Bearer aa83720a-0bc1-4d5b-82fc-bf27a6682aa4  # reemplázalo con tu clave secreta (después del `Bearer `)
    verify_ssl: false
    icon: mdi:tablet-dashboard
```

Recarga tu instancia de Home Assistant, usa las _Herramientas de desarrollador_ para probar el interruptor y el sensor.

Luego puedes usarlo en las Automatizaciones, por ejemplo, apagarlo cuando te vas a dormir por la noche y volver a encenderlo cuando te levantas por la mañana.

Dado que se usará principalmente para mostrar un dashboard de Home Assistant todos los días, es muy probable que con el tiempo sufra de [quemado de pantalla](https://en.wikipedia.org/wiki/Screen_burn-in), aunque tiene una pantalla LCD.

Para evitarlo, este script en Python también muestra periódicamente (cada hora) varios colores en pantalla completa para refrescar todos los píxeles. Puedes desactivar esta función añadiendo una variable de entorno `SCREENSAVER_ENABLED=0` en el fichero del servicio como siguiente:

```systemd
# ...
[Service]
Environment=TOKEN=aa83720a-0bc1-4d5b-82fc-bf27a6682aa4
Environment=SCREENSAVER_ENABLED=0
Type=simple
# ...
```

## Recursos

- [Volcado de la memoria flash](https://t.me/movistar_home_hacking/93) usando `dd`
