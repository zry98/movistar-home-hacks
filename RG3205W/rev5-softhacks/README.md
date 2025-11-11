# Reutilización de Movistar Home - RG3205W Soft-hacks

como un panel de dashboard para Home Assistant.

**Este documento solo está destinado al modelo `RG3205W` con un SoC arm64 de Qualcomm. Para el modelo `IGW-5000A2BKMP-I v2` con una CPU x86 de Intel, por favor consulta [IGW5000/README.md](../../IGW5000/README.md). [_¿Cómo identificarlo?_](../../README.md#nota-importante)**

[🇺🇸 English version](./README.en.md)

> [!IMPORTANT]
> **TRABAJO EN CURSO**, especialmente para la variante Rev5.

## Escapar del quiosco

> [!CAUTION]
> Seguir las instrucciones a continuación **anulará la garantía** de tu dispositivo y **puede violar tu contrato o acuerdo de servicio** con Movistar. Procede completamente bajo tu propio riesgo.

No necesitas (y sea muy difícil) instalar Linux como con el modelo `IGW-5000A2BKMP-I v2`.

Si tienes un Wi-Fi de Movistar con un contrato _Fusión_ válido, puedes acceder a la pantalla principal después de conectarte. Desliza hacia abajo el panel superior y toca "Ajustes" para abrir los ajustes, luego toca _Conectividad > Altavoz bluetooth_ para entrar al menú originalmente para conectarse a un altavoz Bluetooth. Pero por alguna razón, también se puede usar para conectar un teclado Bluetooth; si no tienes uno, puedes intentar usar una aplicación de teclado Bluetooth virtual en tu móvil (consulta la sección [Recursos](#recursos) para unas apps sugeridas). Ahora puedes saltarte la siguiente sección e ir directamente a [la parte de configuraciones](#configuraciones).

Pero si no tienes un Wi-Fi de Movistar, no podrás saltar la pantalla de conexión de Wi-Fi y acceder a la configuración de Bluetooth. Tendrás que desmontarlo y probablemente hacer algo de soldadura.

### Desmontaje

(Tiene un chasis idéntico al del [IGW5000](../../IGW5000/README.md#desmontaje))

Para desmontar el dispositivo, suelta las **10 presillas** _("snap-fits")_ situadas bajo los bordes del panel trasero, teniendo cuidado de no dañarlas.

Luego retira los **8 tornillos** situados bajo el panel y los **4 tornillos** ocultos bajo la tira de goma negra en la parte inferior del dispositivo.

### Conectar un teclado USB

Actualmente existen al menos 2 variantes (revisiones de hardware) del RG3205W: `Rev4` y `Rev5`.

> [!IMPORTANT]
> Para identificar las 2 variantes, **la única forma fiable** es retirar el panel posterior y comprobar las marcas en la placa o la presencia del conector USB Tipo-C.
> 
> Se han reportado varias excepciones sobre la fecha de fabricación "F.Fab(AAMM)" en la etiqueta adhesiva, por ejemplo, `2001` puede ser Rev4 o Rev5.

#### Rev4

![RG3205W-rev4-internal](../../assets/img/RG3205W-rev4-internal.jpg)

Si el tuyo tiene una PCB `Rev4`, tienes mucha suerte de que venga con un conector hembra USB Tipo-C ya soldado y funcionando!

#### Rev5

![RG3205W-rev5-internal](../../assets/img/RG3205W-rev5-internal.jpg)

Por desgracia, la variante más común en el mercado es la `Rev5` que no solo viene sin el conector USB Tipo-C populado, sino que también falta una resistencia _pull-down_ de 5,1 kΩ entre los pines `CC` (`CC1` o `CC2` dependiendo del lado) y `GND` para ponerlo en modo _host_. Así que tendrás que soldar la resistencia tú mismo como se muestra a continuación:

![rev5-usb-resistencia-pull-down](../../assets/img/RG3205W-rev5-usb-pull-down-resistor.jpg)

![pinout-usb-tipo-c](../../assets/img/usb-type-c-pinout.png)

Sin embargo, el conector JST-PH2.0 blanco hembra de 4 pines que se encuentra cerca también está conectado a los 4 pines de USB 2.0, con el pinout de izquierda a derecha: `D-`, `D+`, `GND`, `+5V`, puedes usarlo para sacar la conexión USB sin necesidad de soldar un conector SMD de USB Tipo-C (lo cual es muy difícil de hacer).

![rev5-usb-jst-port-connection](../../assets/img/RG3205W-rev5-usb-jst-port-connection.jpg)

## Configuraciones

De todos modos, con un teclado USB o Bluetooth conectado, puedes presionar las teclas <kbd>Super</kbd> + <kbd>N</kbd> (<kbd>Super</kbd> es usualmente la tecla <kbd>⊞ Win</kbd>) para abrir el panel de notificaciones, luego toca el icono de engranaje para abrir los ajustes del sistema Android.

Si conseguiste una variante Rev4, tienes tanta suerte de que no tiene restricciones en la ROM, así que puedes simplemente habilitar las Opciones para desarrolladores tocando el número de compilación 7 veces, luego habilitar la Depuración por USB y cualquier tipo de cosas a través de ADB.

Desafortunadamente, para la variante Rev5 todavía no hemos encontrado una manera de habilitar la Depuración por USB (ADB), porque se ha eliminado todo el menú de "Opciones para desarrolladores" por completo en la ROM, junto con muchas muchas más cosas.

Sin embargo, todavía puedes instalar APKs usando la aplicación incorporada de correo electrónico. Puedes abrir esa aplicación presionando las teclas <kbd>Super</kbd> + <kbd>E</kbd>, luego configurar una cuenta de correo electrónico. Después de eso, puedes enviar un correo a esta dirección con el APK adjunto, luego abrir el correo en la app y tocar el adjunto para descargarlo e instalarlo.

> [!TIP]
> No deberías usar proveedores de correo principales como Gmail, ni para enviar ni para recibir, porque normalmante no se permiten los adjuntos de APK. Puedes usar la herramienta "[email-file-server](https://github.com/zry98/movistar-home-hacks/tree/main/email-file-server)" incluida en este repositorio; consulta la [siguiente subsección](#usar-la-herramienta-mail-file-server) para obtener instrucciones detalladas.

> [!TIP]
> **Para más información sobre hacks por software para el Rev5, por favor consulta la guía increíblemente completa [extras.md](extras.md) elaborada por [@alfredopironti](https://github.com/alfredopironti).**

La primera aplicación que definitivamente debes instalar es un [lanzador](https://search.f-droid.org/?q=launcher), y configurarlo como el lanzador predeterminado (_Ajustes > Aplicaciones y notificaciones > Ajustes avanzados > Aplicaciones predeterminadas > Aplicación de página principal_), de lo contrario, seguirás atrapado en la aplicación de incorporación cada vez que se reinice.

Pero ten en cuenta que la aplicación de incorporación seguirá apareciendo y te bloqueará cuando cambie la conexión Wi-Fi. Así que aún necesitamos encontrar una manera de desinstalarla.

#### Usar la herramienta mail-file-server

Debes tener un PC accesible desde tu Movistar Home, por ejemplo, en la misma red LAN.

Descarga la versión de email-file-server adecuada para tu PC desde su [página de releases](https://github.com/zry98/movistar-home-hacks/releases/tag/v0.0.1), por ejemplo, `email-file-server_v0.0.1_windows_amd64.zip` para la mayoría de los PC con Windows. Descomprime el archivo y pon los ficheros APK que quieras instalar en tu Movistar Home dentro de la carpeta `files` en la carpeta descomprimida.

Abre una terminal en esa carpeta, y ejecuta `./email-file-server`. Por defecto, leerá todos los ficheros dentro de la carpeta `files`, y arrancará un servidor POP3 mínimo escuchando en el puerto 8110, y un servidor SMTP mínimo escuchando en el puerto 8025.

Puedes ejecutar `./email-file-server --help` para ver las opciones disponibles si quieres personalizar algo.

En la app de correo de tu Movistar Home, configura una cuenta con cualquier dirección y luego pulsa el botón "AJUSTES MANUALES":

![email-apks-paso-1](../../assets/img/email-apks-step-1.png)

Selecciona el tipo de cuenta "PERSONAL (POP3)".

Introduce cualquier contraseña y pulsa el botón "SIGUIENTE".

Introduce la dirección IP de tu PC (el que está ejecutando el servidor) en el campo "SERVIDOR", selecciona "Ninguna" como "TIPO DE SEGURIDAD", e introduce el puerto de POP3 (`8110` por defecto) en el campo "PUERTO". Luego pulsa "SIGUIENTE":

![email-apks-paso-4](../../assets/img/email-apks-step-4.png)

Introduce la misma dirección IP en el campo "SERVIDOR SMTP", selecciona "Ninguna" como "TIPO DE SEGURIDAD", e introduce el puerto de SMTP (`8025` por defecto) en el campo "PUERTO", y desmarca la casilla "Solicitar inicio de sesión". Luego pulsa "SIGUIENTE":

![email-apks-paso-5](../../assets/img/email-apks-step-5.png)

Selecciona "Nunca" como "Frecuencia de sincronización", luego pulsa "SIGUIENTE".

Puedes darle un nombre a la cuenta, pero no es necesario. Simplemente pulsa "SIGUIENTE" y deberías ver la bandeja de entrada. Por defecto, comenzará a descargar todos los correos (con los APK adjuntos, que pueden ser grandes), así que espera a que termine el indicador de carga. Si no ves nada, desliza hacia abajo para forzar la sincronización.

Cuando veas el correo que contiene el APK que quieres instalar, ábrelo y pulsa el fichero adjunto, luego pulsa cualquiera de los dos botones que aparecen para instalarlo:

![email-apks-instalar](../../assets/img/email-apks-install.png)

## Recursos

- [Bluetooth Keyboard & Mouse](https://play.google.com/store/apps/details?id=io.appground.blek) para Android, sugerido por _josemoraocana_ en nuestro grupo de Telegram
- [KeyPad - Bluetooth Keyboard](https://apps.apple.com/us/app/keypad-bluetooth-keyboard/id1491684442) para iPhone / iPad, sugerida por [@alfredopironti](https://github.com/alfredopironti)
