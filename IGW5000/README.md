# Reutilización de Movistar Home - IGW5000

como un panel de dashboard para Home Assistant.

**Este documento solo está destinado al modelo `IGW-5000A2BKMP-I v2` con una CPU x86 de Intel. Para el modelo `RG3205W` con un SoC arm64 de Qualcomm, por favor consulta [RG3205W/README.md](../RG3205W/README.md). [_¿Cómo identificarlo?_](../README.md#nota-importante)**

[🇺🇸 English version](./README.en.md)

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

> [!CAUTION]
> Seguir las instrucciones a continuación **anulará la garantía** de tu dispositivo y **puede violar tu contrato o acuerdo de servicio** con Movistar. Procede completamente bajo tu propio riesgo.

### Desmontaje

Para desmontar el dispositivo, suelta las **10 presillas** _("snap-fits")_ situadas bajo los bordes del panel trasero, teniendo cuidado de no dañarlas.

Luego retira los **8 tornillos** situados bajo el panel y los **4 tornillos** ocultos bajo la tira de goma negra en la parte inferior del dispositivo.

### Conectar al USB OTG

Localiza el puerto micro USB desocupado en el borde izquierdo de la placa base:

![ubicación-puerto-usb](../assets/img/IGW5000-usb-port-location.jpg)

Suelda un conector hembra de micro USB y conecta un cable adaptador OTG; o simplemente suelda un cable con un conector hembra de USB-A estándar, luego cortocircuita el cuarto pin (o el pad `ID` cercano) a el quinto pin GND (o cualquier pad de tierra en la placa), haciendo que el puerto funcione como un _OTG host_.

Aquí es un ejemplo de cableado para soldar un conector USB-A hembra:

![conexión-puerto-usb](../assets/img/IGW5000-usb-port-connection.jpg)

Y dos ejemplos de cables soldados (cortesías de Carlos Chipe y Ángel de nuestro grupo de Telegram):

![cables-soldados-usb](../assets/img/IGW5000-usb-connection-examples.jpg)

Flashea un pendrive USB con tu distribución de Linux favorita.

Teniendo en cuenta que el Movistar Home solo tiene 2 GB de RAM, se recomienda encarecidamente usar solo [gestor de ventanas](https://wiki.archlinux.org/title/Window_manager_(Espa%C3%B1ol)). Si deseas usar un entorno de escritorio completo, considera uno muy ligero como _Xfce_. No se recomienda utilizar el SO _Android-x86_, ni entornos de escritorio pesados ​​como _GNOME_ o _KDE Plasma_.

También es importante aplicar optimizaciones para mejorar el rendimiento y reducir el desgaste de la eMMC, consulta la sección [Mejorar el rendimiento y reducir el desgaste de la eMMC](#mejorar-el-rendimiento-y-reducir-el-desgaste-de-la-emmc).

Conecta un teclado y el pendrive a un hub de USB y conéctalo al Movistar Home. Enciéndelo mientras presiona la tecla <kbd>F2</kbd>, se iniciará a la configuración del BIOS (UEFI), navega a la última pestaña (`Save & Exit`), selecciona tu pendrive (debería ser algo así como `UEFI: USB, Partition 1`) en el menú `Boot Override`, presiona la tecla <kbd>Intro</kbd> (<kbd>Enter</kbd>) para iniciarlo.

![bios](../assets/img/IGW5000-bios.jpg)

Instala tu distribución de Linux como de costumbre, puede ser necesario incluir los drivers y firmwares _non-free_.

> [!IMPORTANT]
> Se recomienda configurar el servidor OpenSSH antes de desoldar el conector USB y volver a montar el dispositivo, para los posibles mantenimientos en el futuro.

## Configuraciones

Las siguientes configuraciones se realizaron para [Arch Linux](https://archlinux.org/) con el gestor de ventanas [_Sway_](https://wiki.archlinux.org/title/Sway) (basado en el compositor de Wayland _wlroots_), y es posible que necesiten algunas modificaciones para las otras distribuciones, gestores de ventanas o entornos de escritorio.

Sway, al ser un gestor de ventanas de mosaico (_tiling_), no es necesario para el caso de uso de kiosk (mostrar solo una pestaña del navegador); lo utilicé por su alto rendimiento y por el soporte de comandos _IPC_ (útiles, por ejemplo, para el control del brillo). También puedes probar [otros](https://wiki.archlinux.org/title/Wayland_(Espa%C3%B1ol)#Compositores) como [_cage_](https://github.com/cage-kiosk/cage), un compositor minimalista diseñado para el modo quiosco.

Si deseas usar un entorno de escritorio completo, consulta la [guía antigua](./xfce.md) para Xfce.

Puedes encontrar un script de configuración experimental en [IGW5000/setup/setup.sh](setup/setup.sh). No se ha probado exhaustivamente; si encuentras algún problema, pide ayuda en nuestro [grupo de Telegram](https://t.me/movistar_home_hacking). Para usarlo, crea un medio de instalación de Arch Linux (como un pendrive booteable), incluye el script en él y ejecútalo con `bash` tras arrancar en la línea de comandos de instalación.

### Mejorar la estabilidad del Wi-Fi

Crea el fichero `/etc/modprobe.d/99-movistar-home-panel.conf` con el siguiente contenido:

```plaintext
# desactivar modulos innecesarios
blacklist axp20x_i2c
blacklist extcon_axp288
blacklist intel_xhci_usb_role_switch
blacklist extcon_intel_int3496
blacklist hid_sensor_hub
blacklist intel_atomisp2_pm
blacklist ov2680
# desactivar Bluetooth (aun no funciona)
blacklist bluetooth
blacklist hci_uart
# desactivar el ahorro de energía del RTL8822BE
options rtw88_core disable_lps_deep=y
options rtw88_pci disable_msi=y disable_aspm=y
options rtw_core disable_lps_deep=y
options rtw_pci disable_msi=y disable_aspm=y
```

Y ejecuta `sudo mkinitcpio -P` para regenerar el _initramfs_.

### Botón de encendido

Edita el fichero `/etc/systemd/logind.conf` para cambiar los valores en la sección `[Login]` como sigue:

```systemd
HandlePowerKey=ignore
HandlePowerKeyLongPress=poweroff
```

Esto hará que el botón de encendido no haga nada al pulsarlo brevemente y que el dispositivo se apague correctamente al pulsarlo prolongadamente.

Si has configurado una [pantalla de bloqueo](https://wiki.archlinux.org/title/Session_lock), también puedes configurar `HandlePowerKey=lock` para habilitarla.

Y ejecuta `sudo systemctl enable --now systemd-logind.service`.

### Rotación de la pantalla y control de la retroiluminación

Crea el fichero `/etc/mkinitcpio.conf.d/99-movistar-home-panel.conf` con el siguiente contenido:

```plaintext
MODULES=(i915 pwm-lpss-platform)
```

Crea el fichero `/etc/udev/rules.d/99-movistar-home-panel.rules` con el siguiente contenido:

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

### Pantalla táctil

Añade el siguiente contenido al fichero de configuración de Sway:

```nginx
# ...
# mapea la pantalla táctil
input "1046:911:Goodix_Capacitive_TouchScreen" {
  map_to_output DSI-1
}
# ...
```

### Reducción automática de retroiluminación

Crea el fichero `~/.config/systemd/user/sway-session.target` con el siguiente contenido:

```systemd
[Unit]
Description=Sesión SwayWM
BindsTo=graphical-session.target
Wants=graphical-session-pre.target
After=graphical-session-pre.target
```

Edita el fichero de configuración de Sway y añade el siguiente contenido al final:

```nginx
exec_always systemctl --user start sway-session.target
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

Luego ejecuta `systemctl --user daemon-reload && systemctl --user enable --now swayidle.service` para que se ejecute al iniciar.

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

### Sonido

> [!NOTE]
> **TRABAJO EN CURSO**
> El contenido de esta sección (especialmente los ficheros) podría cambiar frecuentemente, ya que seguimos trabajando en ello.

> [!NOTE]
> Actualmente solo se han arreglado los altavoces; los micrófonos aún no funcionan.

El amplificador integrado para los altavoces no se activa correctamente mediante el driver de la tarjeta de sonido RT5672. Tenemos que configurar los GPIO 5 y 7 de gpiochip1 al nivel lógico ALTO.

<details markdown="1">

<summary markdown="span">Haz clic para mostrar los detalles técnicos</summary>

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

### Mejorar el rendimiento y reducir el desgaste de la eMMC

#### Frecuencia de la CPU

Añade el parámetro de kernel `cpufreq.default_governor=performance` al fichero de configuración del _bootloader_ (gestor de arranque):

- Para _systemd-boot_, edita `/boot/loader/entries/arch.conf` y añádelo al final de la línea `options`.
- Para _GRUB_, edita `/etc/default/grub` y añádelo al final de la línea `GRUB_CMDLINE_LINUX_DEFAULT` (entre comillas).
- Para otros [gestores de arranque](https://wiki.archlinux.org/title/Arch_boot_process_(Espa%C3%B1ol)#Comparaci%C3%B3n_de_caracter%C3%ADsticas), consulta su documentación.

Ejecuta `sudo mkinitcpio -P` para regenerar el initramfs. También ejecuta `sudo grub-mkconfig -o /boot/grub/grub.cfg` si usas GRUB.

Crea el fichero `/etc/systemd/system/set-energy-perf-bias.service` con el siguiente contenido:

```systemd
[Unit]
Description=Set ENERGY_PERF_BIAS

[Service]
Type=oneshot
ExecStart=sh -c 'for f in /sys/devices/system/cpu/cpu*/power/energy_perf_bias; do echo 0 > "$f"; done'

[Install]
WantedBy=multi-user.target
```

Ejecuta `sudo systemctl daemon-reload && sudo systemctl enable --now set-energy-perf-bias.service` para que se ejecute al iniciar.

#### zram

Crea el fichero `/etc/modules-load.d/99-movistar-home-panel.conf` con el siguiente contenido para cargar el módulo al arrancar:

```plaintext
zram
```

Edita el fichero `/etc/udev/rules.d/99-movistar-home-panel.rules` para añadir el siguiente contenido, para configurar el dispositivo zram al arrancar:

```plaintext
ACTION=="add", KERNEL=="zram0", ATTR{initstate}=="0", ATTR{comp_algorithm}="zstd", ATTR{disksize}="2G", TAG+="systemd"
```

Edita el fichero `/etc/fstab` para añadir el siguiente contenido y así montar zram como _swap_ al arrancar:

```plaintext
/dev/zram0      none    swap    defaults,discard,pri=100,x-systemd.makefs   0 0
```

Crea el fichero `/etc/sysctl.d/99-movistar-home-panel.conf` con el siguiente contenido para optimizar el uso del swap:

```ini
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
```

Se recomienda deshabilitar _zswap_ desde el kernel al usar zram. Añade el parámetro de kernel `zswap.enabled=0` al fichero de configuración del bootloader:

- Para systemd-boot, edita `/boot/loader/entries/arch.conf` y añádelo al final de la línea `options`.
- Para GRUB, edita `/etc/default/grub` y añádelo al final de la línea `GRUB_CMDLINE_LINUX_DEFAULT` (entre comillas).
- Para otros [gestores de arranque](https://wiki.archlinux.org/title/Arch_boot_process_(Espa%C3%B1ol)#Comparaci%C3%B3n_de_caracter%C3%ADsticas), consulta su documentación.

Ejecuta `sudo mkinitcpio -P` para regenerar el initramfs. También ejecuta `sudo grub-mkconfig -o /boot/grub/grub.cfg` si usas GRUB.

#### Logging

Edita el fichero `/etc/systemd/journald.conf` para cambiar los valores en la sección `[Journal]` como sigue:

```systemd
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
```

Para comprobar el desgaste **estimado** de la eMMC, instala el paquete `mmc-utils` y ejecuta el comando `mmc extcsd read /dev/mmcblk1 | grep -E 'LIFE|EOL'`. Puedes encontrar información sobre cómo interpretar los valores [aquí](https://docs.netgate.com/pfsense/en/latest/troubleshooting/disk-lifetime.html#interpreting-mmc-health-data).

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
MemoryHigh=1G
MemoryMax=1G
MemorySwapMax=1.5G

[Install]
WantedBy=sway-session.target
```

> [!TIP]
> Deberías reducir los valores de `MemoryHigh` y `MemoryMax` si tienes otras aplicaciones que consumen mucha memoria ejecutándose junto con el navegador, o si no has [configurado zram](#zram).

Y ejecuta `systemctl --user daemon-reload && systemctl --user enable --now hass-dashboard.service` para que se ejecute al iniciar.

Si prefieres Firefox, reemplaza la línea `ExecStart` por:

```systemd
ExecStart=firefox -kiosk -url "${HASS_DASHBOARD_URL}"
```

Según mis pruebas, Chromium consume menos memoria, es más fluido y soporta aceleración por hardware (útil para ver cámaras). También puedes probar [ungoogled-chromium](https://aur.archlinux.org/packages/ungoogled-chromium) en AUR.

### Controlar la retroiluminación desde Home Assistant

Ejecuta `python3 -m venv ~/panel-controller` para crear un entorno virtual de Python, y ejecuta `sudo pacman -S gtk4 gtk4-layer-shell && ~/panel-controller/bin/pip install Flask==3.1.1 i3ipc==2.2.1 PyGObject==3.52.3 apscheduler==3.11.0` para instalar las dependencias necesarias.

Descarga el script [`panel-controller/app.py`](https://raw.githubusercontent.com/zry98/movistar-home-hacks/main/IGW5000/panel-controller/app.py) y guárdalo en `~/panel-controller/app.py`.

Puedes usar `wget` con `wget https://raw.githubusercontent.com/zry98/movistar-home-hacks/main/IGW5000/panel-controller/app.py -O ~/panel-controller/app.py`.

Luego crea el fichero `~/.config/systemd/user/panel-controller.service` con el siguiente contenido:

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

<!-- {% raw %} -->
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
<!-- {% endraw %} -->

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
