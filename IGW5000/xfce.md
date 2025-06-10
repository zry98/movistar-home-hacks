# Entorno de Escritorio Xfce - IGW5000

**Este documento solo está destinado al modelo `IGW-5000A2BKMP-I v2` con una CPU x86 de Intel. Para el modelo `RG3205W` con un SoC arm64 de Qualcomm, por favor consulta [RG3205W/README.md](../RG3205W/README.md). [_¿Cómo identificarlo?_](../README.md#nota-importante)**

[🇺🇸 English version](../IGW5000/xfce.en.md)

Las siguientes configuraciones se realizaron para Manjaro con Xfce y es posible que necesiten algunas modificaciones para las otras distribuciones o entornos de escritorio.

Teniendo en cuenta los recursos de hardware limitados (2 GB de RAM) del IGW5000, se recomienda encarecidamente usar solo un [gestor de ventanas](https://wiki.archlinux.org/title/Window_manager_(Espa%C3%B1ol)). Consulta la [guía más reciente](../IGW5000/README.md) para más detalles.

### Corregir la rotación de la pantalla

Instala el driver `xf86-video-intel` con el comando `sudo pacman -S xf86-video-intel`.

Crea el fichero `/etc/X11/xorg.conf.d/20-monitor.conf` con el siguiente contenido:

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

En la Configuración de Pantalla de Xfce, ajusta la escala a tu gusto, descubrí que 0.8x (equivalente a 1024x640) es el más adecuado para esta pantalla.

### Arreglar la pantalla táctil

Por alguna razón, la pantalla táctil no funciona en absoluto a menos que se haya reiniciado una vez, en _dmesg_ el driver dice "Goodix-TS i2c-GDIX1001:00: Invalid config (0, 0, 0), using defaults".

Para arreglarlo, crea el fichero `/etc/systemd/system/fix-touchscreen.service` con el siguiente contenido:

```systemd
[Unit]
Description=Arreglar la pantalla táctil

[Service]
Type=oneshot
ExecStart=sh -c 'dmesg | grep -q " Goodix-TS .*: Invalid config " && reboot now || exit 0'

[Install]
WantedBy=multi-user.target
```

Ejecuta `sudo systemctl daemon-reload && sudo systemctl enable fix-touchscreen.service` para que se ejecute al iniciar.

Para corregir la rotación, crea el fichero `/etc/X11/xorg.conf.d/30-touchscreen.conf` con el siguiente contenido:

```plaintext
Section "InputClass"
    Identifier      "calibration"
    MatchProduct    "Goodix Capacitive TouchScreen"
    Option          "TransformationMatrix" "0 1 0 -1 0 1 0 0 1"
EndSection
```

#### Arreglar el control táctil en Firefox

_Fuente: [Firefox/Tweaks - ArchWiki](https://wiki.archlinux.org/title/Firefox/Tweaks#Enable_touchscreen_gestures)_

Abre la Firefox y acceda a `about:config`, busca por `dom.w3c_touch_events.enabled` y asegúrase de que está configurado a 1 (_habilitado_) o 2 (_predeterminado, detección automática_).

También añade `MOZ_USE_XINPUT2 DEFAULT=1` al `/etc/security/pam_env.conf`.

### Reducción automática de brillo

Modifica el fichero `/etc/mkinitcpio.conf` para incluir `i915` y `pwm-lpss-platform` en la matriz `MODULES` como sigue:

```plaintext
...
MODULES=(i915 pwm-lpss-platform)
...
```

Y ejecuta `sudo mkinitcpio -P` para regenerar el initramfs.

Crea el fichero `/etc/X11/xorg.conf.d/10-intel.conf` con el siguiente contenido:

```plaintext
Section "Device"
    Identifier    "Intel Graphics"
    Driver        "intel"
    Option        "AccelMethod" "sna"
    Option        "TearFree"    "true"
    Option        "Backlight"   "intel_backlight"
EndSection
```

Abre el `Administrador de energía` de Xfce, cambia a la pestaña `Pantalla` y ajusta la configuración de `Reducción de brillo`. Personalmente lo configuré para que se reduzca al 20% después de 90 segundos de inactividad.

También recuerda a deshabilitar la suspensión/apagar automática desde allí.

Crea el fichero `/etc/udev/rules.d/backlight.rules` con el siguiente contenido:

```plaintext
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/bin/chgrp video $sys$devpath/brightness", RUN+="/bin/chmod g+w $sys$devpath/brightness", ATTR{brightness}="100"
```

Y mejor deshabilitar el servicio systemd-backlight con `sudo systemctl mask systemd-backlight@backlight\:intel_backlight.service`, para evitar que interfiera.

### Teclado virtual

Instala [_Onboard_](https://launchpad.net/onboard) con `sudo pacman -S onboard`, abre la configuración `Sesión e inicio` de Xfce, cambia a la pestaña `Autoarranque de aplicaciones`, busca y habilita `Onboard (Teclado en pantalla flexible)`.

Después de reiniciar, abre la configuración de _Onboard_ y ajústala a tu gusto.

### Ocultar cursor del ratón

Instala [_unclutter_](https://github.com/Airblader/unclutter-xfixes) con `sudo pacman -S unclutter`.

Crea el fichero `~/.config/autostart/hide-cursor.desktop` con el siguiente contenido:

```systemd
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=Ocultar cursor
Comment=Ocultar cursor del ratón
Exec=unclutter --hide-on-touch
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
```

### Arreglar el sonido

> [!NOTE]
> **TRABAJO EN CURSO**
> El contenido de esta sección (especialmente los ficheros) podría cambiar frecuentemente, ya que seguimos trabajando en ello.

> [!NOTE]
> Actualmente solo se han arreglado los altavoces; los micrófonos aún no funcionan.

El amplificador integrado para los altavoces no se activa correctamente mediante el driver de la tarjeta de sonido RT5672. Tenemos que configurar los GPIO 5 y 7 de gpiochip1 al nivel lógico ALTO.

<details markdown="1">

<summary markdown="span">Detalles técnicos</summary>

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

Crea el fichero `~/.config/autostart/switch-alsa-ucm.desktop` con el siguiente contenido:

```systemd
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=Cambiar ALSA UCM
Comment=Para arreglar los altavoces
Exec=alsaucm -c cht-bsw-rt5672 set _verb HiFi set _enadev Headphones
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
```

### Home Assistant dashboard

Crea el fichero `~/.config/autostart/HASS.desktop` con el siguiente contenido:

```systemd
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=HASS Dashboard
Comment=Ejecute el dashboard de HASS en el mode quiosco de Firefox
Exec=firefox -kiosk -url 'https://tu.hass.url'
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
```

Ejecutará Firefox en modo quiosco al iniciar, del que solo puedes salir presionando `Alt+F4` o usando el comando `kill` a través de SSH.

#### Controlar la retroiluminación desde Home Assistant

> [!TIP]
> Como se menciona en [ArchLinux Wiki](https://wiki.archlinux.org/title/Xfce#Display_blanking), para que el `xset` pueda controlar la DPMS, necesitas desactivar:
>  1. La reducción de brillo de pantalla en `Administrador de energía` de Xfce.
>  2. El `XScreenSaver` de Xfce.

Ejecuta `sudo pacman -S python-flask` para instalar _Flask_, luego crea el fichero `~/.local/bin/panel_server.py` con el siguiente contenido:

<details markdown="1">

<summary markdown="span">script de Python panel_server.py</summary>

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

Ejecuta `systemctl --user edit --force --full panelserver.service`, lo cual creará un fichero de servicio de systemd y lo abrirá en tu editor predeterminado (puede ser cambiado con la variable de entorno `EDITOR`, por ejemplo, `EDITOR=nano systemctl edit ...`), luego poner el siguiente contenido:

```systemd
[Unit]
Description=Panel Server
After=network.target graphical.target

[Service]
Environment=TOKEN=aa83720a-0bc1-4d5b-82fc-bf27a6682aa4  # reemplázalo con tu clave secreta
Environment=DISPLAY=:0
NoNewPrivileges=true
ExecStart=/usr/bin/python3 /home/panel/.local/bin/panel_server.py  # reemplázalo con tu ruta real
Restart=always

[Install]
WantedBy=default.target
```

Guárdalo y ejecuta `systemctl --user daemon-reload && systemctl --user enable --now panelserver.service` para que se ejecute al iniciar.

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

### Evitar que la pantalla se queme

Dado que se usará principalmente para mostrar un dashboard de Home Assistant todos los días, es muy probable que con el tiempo sufra de [quemado de pantalla](https://en.wikipedia.org/wiki/Screen_burn-in), aunque tiene una pantalla LCD.

Para evitarlo, se puede utilizar un script en Python para que muestre periódicamente varios colores en pantalla completa para refrescar todos los píxeles. Si lo prefieres, también puede actualizar la pestaña del navegador al mismo tiempo para solucionar posibles problemas como el bloqueo.

> [!CAUTION]
> **¡NO USES este script si tú o algún miembro de tu familia tiene [epilepsia fotosensible](https://es.wikipedia.org/wiki/Epilepsia_fotosensible)!**

Instala los paquetes necesarios con `sudo pacman -S tk xdotool` y crea el fichero `~/.local/bin/screensaver.py` con el siguiente contenido:

<details markdown="1">

<summary markdown="span">script de Python screensaver.py</summary>

```python
#!/usr/bin/env python3
import os
import threading
import tkinter as tk
from subprocess import run
from time import time

color_interval = int(os.environ.get('COLOR_INTERVAL', 300))  # milisegundos
total_time = int(os.environ.get('TOTAL_TIME', 10))  # segundos, saldrá después de ese tiempo
colors = ['red', 'green', 'blue', 'black', 'white']

root = tk.Tk()
w, h = root.winfo_screenwidth(), root.winfo_screenheight()
root.overrideredirect(True)
root.attributes('-fullscreen', True)
canvas = tk.Canvas(root, width=w, height=h, background='black', highlightthickness=0)
canvas.pack()
canvas.focus_set()
canvas.bind('<Button-1>', lambda _: root.destroy())  # saldrá al tocar

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


# actualiza la pestaña del navegador
browser_window_class = os.environ.get('BROWSER_WINDOW_CLASS', '')
if browser_window_class:
    refresh_thread = threading.Thread(target=refresh_browser, args=(browser_window_class,))
    refresh_thread.start()
# protector de pantalla
time_start = time()
show_color()
root.mainloop()
```

</details>

Ejecuta `chmod +x ~/.local/bin/screensaver.py` para hacerlo ejecutable, luego ejecuta `crontab -e` y agrega un trabajo de _cron_ como sigue, que ejecutará el script cada hora:

```crontab
0 * * * *	DISPLAY=:0 COLOR_INTERVAL=300 TOTAL_TIME=10 BROWSER_WINDOW_CLASS="firefox" /home/panel/.local/bin/screensaver.py  # reemplázalo con tu ruta real
```

Ajusta las dos variables de entorno `COLOR_INTERVAL` y `TOTAL_TIME` a tu gusto, con un `TOTAL_TIME` de 10 estará ejecutándose durante 10 segundos. Si necesitas detenerlo inmediatamente, simplemente toca la pantalla.

Si utilizas otro navegador (por ejemplo, `chromium`), cambia el valor de `BROWSER_WINDOW_CLASS` en consecuencia; si no deseas actualizar la pestaña del navegador, hazlo vacío (`BROWSER_WINDOW_CLASS=""`).

Si utilizas otro navegador (por ejemplo, `chromium`) para el dashboard, cambia el valor de `BROWSER_WINDOW_CLASS` en consecuencia; quitalo si no deseas actualizar la pestaña del navegador.

## Recursos

- [Volcado de la memoria flash](https://t.me/movistar_home_hacking/93) usando `dd`
