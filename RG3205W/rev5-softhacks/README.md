# Hacks por software para RG3205W Rev5

_Autor:_ [@alfredopironti](https://github.com/alfredopironti)

**Este documento solo está destinado al modelo `RG3205W` con un SoC arm64 de Qualcomm. Para el modelo `IGW-5000A2BKMP-I v2` con una CPU x86 de Intel, por favor consulta [IGW5000/README.md](../../IGW5000/README.md). [_¿Cómo identificarlo?_](../../README.md#nota-importante)**

[🇺🇸 English version](./README.en.md)

**No es necesario abrir la caja; nada de soldar; no root; no Linux**

_Solo se necesita interactuar con la pantalla táctil, un teclado Bluetooth (o virtual), mucha paciencia y tiempo libre_

Este es un breve tutorial que documenta mis experimentos con un ASKEY (RG3205W) rev5 (Fecha de fabricación: 2101).

Esto no habría sido posible sin todo el esfuerzo existente documentado por la comunidad y su apoyo activo en el grupo de Telegram.

Los siguientes hacks también deberían funcionar con el modelo _MitraStar_ IGW-5000 con una CPU Intel o con la versión _ASKEY_ RG3205W Rev4; simplemente no los he probado en esas unidades.

Aunque esta configuración tiene varias limitaciones, no se han modificado componentes de bajo nivel, por lo que los micrófonos y la cámara funcionan perfectamente, algo que actualmente se pierde si se instala Linux en el IGW-5000.

## Escapar del kiosk de Movistar Home

Estos pasos iniciales están documentados en otros lugares, los reproduzco aquí para que este tutorial sea autocontenido.

### Conectar un teclado Bluetooth (virtual) para iniciar el cliente de correo incorporado

Comienza con un Movistar Home en estado de fábrica (puedes hacer un restablecimiento de fábrica para asegurarte de empezar desde un estado conocido).

Como se documenta en otros lugares, en esta etapa (y solo en esta etapa), necesitarás una conexión Wi-Fi a través del ISP de Movistar, para que el dispositivo Movistar Home complete su proceso de configuración inicial. Conéctate a la Wi-Fi proporcionada por Movistar y completa la configuración inicial.

Asegúrate de que la configuración se complete y que estés en la pantalla de inicio de Movistar Home. Desde allí, ve a la configuración e intenta agregar un altavoz Bluetooth. Cuando el Movistar Home acepte conexiones Bluetooth, usa un teclado Bluetooth para conectarte.

Deberías poder usar un teclado físico. Si tienes una computadora con MacOS, puedes usar la aplicación [KeyPad](https://apps.apple.com/us/app/keypad-bluetooth-keyboard/id1491684442),
que es útil ya que también permite pegar cadenas largas (por ejemplo, tokens Bearer).

Una vez conectado el teclado Bluetooth, presiona las teclas <kbd>Super</kbd> + <kbd>E</kbd> (<kbd>Super</kbd> es la tecla <kbd>⊞ Win</kbd> en un teclado típico de Windows,
o la tecla <kbd>⌘ Command</kbd> en un de Macs).

### Configurar correo electrónico para recibir e instalar un .apk de la tienda de aplicaciones

Configura la aplicación de correo para conectarse a un buzón remoto. En mi experiencia, los buzones de _gmx.com_ funcionan bien (puedes crear uno dedicado a tu dispositivo); asegúrate de usar el protocolo _IMAP_, ya que el protocolo _POP_ no descarga correctamente los archivos adjuntos en mi caso. Según mi experiencia, Outlook y Yahoo Mail no funcionan (siempre obtengo un error de usuario/contraseña, incluso al usar contraseñas de aplicaciones);
Gmail no permite adjuntar archivos .apk, lo cual es fundamental para nuestro siguiente paso.

Ve a la interfaz web de gmx.com en tu PC y crea un correo (puedes guardarlo como borrador o enviártelo a ti mismo), donde adjuntas el .apk de una tienda de aplicaciones.

Muchas personas que han trabajado con el dispositivo Movistar Home han recomendado [Aptoide](https://aptoide.en.aptoide.com/app), que funcionó bien conmigo.

Otras opciones son [Aurora](https://auroraoss.com/) para una experiencia estilo Google Play,
o [F-Droid](https://f-droid.org/en/) para usar sólo aplicaciones de código abierto (lo que limita un poco la elección).

Ahora, vuelve a la aplicación de correo en tu dispositivo Movistar Home. Actualiza (ya sea la bandeja de entrada o la carpeta de borradores) y abre el correo con el archivo APK de la tienda de aplicaciones. Abre el archivo adjunto. Esto instalará la tienda de aplicaciones.

### Instalar un launcher y salir del kiosk de Movistar Home

Una vez instalado, haz clic en _Abrir_, lo que iniciará la tienda de aplicaciones. Desde la tienda de aplicaciones, selecciona un launcher. El recomendado aquí es _Nova Launcher_ (`com.teslacoilsw.launcher`). Mi experiencia fue buena con él. Instala _Nova Launcher_ desde la tienda de aplicaciones; una vez instalado, haz clic en _Abrir_ para ejecutarlo.

Debería aparecer un mensaje preguntando si Nova Launcher debe ser el launcher predeterminado (o un cuadro de diálogo de "Siempre abrir con"), a lo que debes responder _Sí_.

¡Felicidades! En el momento en que Nova Launcher sea el launcher predeterminado, habrás salido del kiosk de Movistar Home.

## Configurar el dispositivo para que sea útil

### Conceptos básicos: navegación con botones y suspensión/bloqueo de pantalla

Una de las primeras cosas que notarás es que el dispositivo no tiene botones de retroceso, inicio o recientes.

De hecho, los gestos parecen no estar disponibles en la configuración. Afortunadamente, instalando la aplicación _Navigation Bar_ (`nu.nav.bar`) puedes obtener la misma funcionalidad. Ten en cuenta que la tablet Movistar Home opera como si la pantalla estuviera girada, por lo que deberás configurar Navigation Bar para colocar los botones en el "lado", para que aparezcan en la parte inferior.

Yo los configuré para que desaparecieran después de 3 segundos y los hago aparecer deslizando desde la parte inferior, para ahorrar espacio en pantalla cuando no los necesito.

Otra característica que ahora uso con poca frecuencia, pero que creo que es buena tener, es la capacidad de bloquear la pantalla. El botón trasero no bloqueará la pantalla cuando se presione, pero otra aplicación viene al rescate: Lock Screen (`com.olalab.lockscreen`). Una vez que la pantalla está bloqueada, puedes presionar el botón en la parte trasera para activar el dispositivo.

Si en lugar de bloquear la pantalla prefieres simplemente atenuar el brillo, la aplicación _Screen Timeout_ (`de.lhoer0.screentimeout`) es lo que estás buscando.

Podrías lograr lo mismo a través de la sección configuración de las aplicaciones originales de Movistar pero, curiosamente, el mismo menú está deshabilitado en el menu de configuración de Android.

Lamentablemente, cuando la pantalla entra en reposo por inactividad, el sistema operativo Android no envía el _broadcast intent_ para comunicar que la pantalla se ha apagado, como si esa parte del sistema operativo hubiera sido eliminada. Esto significa que, desafortunadamente, no puedes hacer que la pantalla se bloquee o el salvapantallas se active justo cuando la pantalla se atenúa: la función del sistema operativo ha sido eliminada. Esto nos lleva al siguiente dolor de cabeza en la automatización.

### Poner la pantalla en reposo

Terminé instalando _Automate_ (`com.llamalab.automate`), que ahora gestiona el salvapantallas/bloqueo de pantalla, y [algunas otras funciones](./automate-examples) que puedes importar a tu instancia (ver más detalles abajo sobre cada script).

Dado que no podemos detectar cuándo la pantalla se atenúa o, en general, cuándo el dispositivo está inactivo, he automatizado una solución alternativa que funciona, aunque no me enorgullece.

La [automatización de salvapantallas automático](./automate-examples/Run-screensaver-every-3min.flo) inicia, espera 3 minutos (puedes modificar el flujo para elegir el tiempo promedio que crees que interactuarás con la pantalla), y luego simplemente activa el salvapantallas (la actividad `Somnambulator`) —- alternativamente puedes modificar el flujo para bloquear la pantalla en su lugar.

Luego, la automatización espera el _broadcast intent_ `DREAMING_STOPPED` (si decidiste bloquear la pantalla en su lugar, elige el evento de difusión correcto para activar el dispositivo), que se activa cuando alguien toca la pantalla, despertando el dispositivo. En ese momento, la automatización vuelve a esperar 3 minutos en un bucle. No es tan limpio como me gustaría, pero funciona lo suficientemente bien.

Debes configurar Automate para que reanude tus automatizaciones en el arranque, para que sigan ejecutándose si se corta la energía.

Pero, sí, leíste bien: Automate _reanuda_ las automatizaciones, no las _reinicia_ al arrancar. ¿Qué significa esto? Supongamos que tu dispositivo estaba inactivo, con el salvapantallas activo, y la energía se corta. Cuando la energía vuelve, tu dispositivo se reinicia... y el salvapantallas nunca se activa. Esto se debe a que, con el salvapantallas activo, la automatización estaba esperando el _intent_ `DREAMING_STOPPED`. Después del reinicio, el dispositivo no tiene el salvapantallas activo, por lo que, a menos que lo inicies y lo cierres manualmente, el _intent_ `DREAMING_STOPPED` nunca se enviará, bloqueando la automatización reanudada.

Solución temporal actual: crear [otra automatización](./automate-examples/Start-Firefox-and-screensaver-at-boot.flo) que espere el _intent_ `BOOT_COMPLETED`, luego inicia el salvapantallas y vuelve a esperar la intención de arranque en un bucle.

(Otra solución podría ser: crear una automatización que, al arrancar, elimine y reinicie todas las demás automatizaciones, aunque requiere más nodos que afectan al límite de la versión gratuita de Automate).

Sí, ya ves por qué no puedo estar orgulloso. Pero, nuevamente, funciona dentro de las limitaciones del sistema operativo en Movistar Home.

Si encuentras alguna forma de detectar programáticamente cuándo el dispositivo está inactivo, ¡avisa a la comunidad!

### Extra: Cambiar el brillo de la pantalla según la hora del día

El dispositivo Movistar Home no tiene un sensor de luz, por lo que no puede ajustar el brillo de la pantalla según la luz exterior.

Podrías sentir la tentación de usar Automate para aumentar/disminuir el brillo según la hora del día, que es lo que yo hice... más o menos.

Tal vez por ser un entusiasta de la automatización, no puedo tolerar que la pantalla se atenúe, digamos, a las 20:00. ¡Demasiado temprano en verano y demasiado tarde en invierno!

Afortunadamente, encontré una [buena automatización de Sándor Illés](https://llamalab.com/automate/community/flows/2103) que calcula localmente (sin necesidad de acceso a Internet, algo crucial para mi configuración) las horas de salida y puesta del sol para un día determinado, en función de las cuales ahora ajusto el brillo de la pantalla. Automate es gratuito para automatizaciones de hasta 30 nodos, así que tuve que trabajar bastante para minimizarlo y ejecutarlo dentro del límite de la versión gratuita.

Puedes descargar [mi automatización personalizada de ajuste de brillo según la hora del día](./automate-examples/Dim-brightness-at-calculated-sunrise-sunset-times.flo), importa el archivo y configura las variables `lat` y `lng` con tu ubicación. Puedes derivar tu ubicación desde cualquier aplicación de mapas.

Por ejemplo, establece `lat` como `40.4163889` y `lng` como `-3.7036111111111114` (sin comillas, ya que deben ser números) para establecer la ubicación en el Km0 en Madrid, en la Puerta del Sol.

## Caso de uso: Panel de escritorio/pared para Home Assistant

Ahora que tienes una configuración básica casi aceptable, puede que quieras hacer algo útil con el dispositivo. Conozco personas que lo usan como reproductor de YouTube mientras cocinan.

En mi caso, opté por usarlo como un panel de escritorio para Home Assistant (aunque quedaría mejor en una pared -- tal vez en el futuro le quite la carcasa y lo monte).

### La aplicación de Home Assistant no rula bien

Podrías sentirte tentado a instalar la aplicación de Home Assistant desde la tienda de aplicaciones. Sin embargo, pronto notarás que usa el WebView embebido en el sistema operativo, que está bastante desactualizado.

Vi que _Aptoide_ permite descargar una versión más reciente de WebView, pero no probé esa opción:

- por un lado, los foros dicen que es complicado hacer que una aplicación use un WebView personalizado (a menos que se compile de manera estática);
- por otro lado, me preocupa que esto pueda interferir con el sistema base, y un restablecimiento de fábrica me llevaría mucho tiempo para restaurar la configuración actual. Así que tomé otro camino (ver más abajo).

La aplicación nativa de Home Assistant también sería necesaria si quisieras usar las funciones de voz de Home Assistant a través del micrófono y los altavoces del Movistar Home. Android 8 admite la instalación de asistentes de voz, así que técnicamente podría hacerse. Sin embargo, aún no he experimentado con el sistema operativo reducido, ni con las capacidades de su CPU (y el uso del WebView desactualizado mencionado antes). Si logras algún avance con esto, ¡comparte tus hallazgos con la comunidad!

### Instalar un navegador y usar la Aplicación Web Progresiva (PWA) de Home Assistant

Inicialmente, instalé Chrome (`com.android.chrome`), navegué hasta mi instancia de Home Assistant y, desde ahí, instalé la PWA en el escritorio.

Me habría quedado con esta configuración, si no fuera porque estaba ejecutando mi instancia de Home Assistant en la red local, a través de HTTP.

En este caso, incluso en modo PWA, Chrome siempre muestra la barra de estado, recordando que la conexión no está cifrada, lo que consume espacio de pantalla innecesariamente.

Ni siquiera la opción `chrome://flags/#unsafely-treat-insecure-origin-as-secure` eliminaría la barra (ahora no mostraría una advertencia, pero la barra seguiría apareciendo).

Plan B: Instalar Firefox (`org.mozilla.firefox`). Sin embargo, Firefox no maneja bien las PWA: si intentas agregar una al escritorio, cada vez que la inicies abrirá una nueva pestaña con la misma aplicación. No es lo ideal.

Pero, si usas Firefox sin más y configuras tu instancia de Home Assistant como la página de inicio de Firefox, esto funciona bien.

Luego, ¿recuerdas la [automatización que ejecuta el salvapantallas al arrancar](./automate-examples/Start-Firefox-and-screensaver-at-boot.flo)? Ahora, primero inicia Firefox y luego el salvapantallas inmediatamente después.

Así que, después de un reinicio, solo debes tocar la pantalla y la pantalla de inicio de Home Assistant estará lista para ti.

### Extra: Botones de volumen como automatizaciones de Home Assistant

Planeo usar el Movistar Home como un telefonillo. Así que, si alguien toca el timbre, ¿no sería genial poder caminar hasta el dispositivo Movistar Home, presionar uno de los dos botones de "volumen" y abrir la puerta? ¡Con la configuración a continuación, podrás hacerlo!

Lo que queremos lograr aquí es que, cuando presiones el botón de volumen+, se envíe una solicitud HTTP POST a la API REST de Home Assistant para activar el servicio de tu elección.

En mi caso, abrir la puerta se hace activando un interruptor, por lo que sería una solicitud POST a `http://<URL-de-home-assistant>:8123/api/services/switch/toggle`, usando el token de acceso de largo plazo como encabezado `Authentication`, y el `entity_id` deseado como datos de la solicitud POST.

Primero, instala la aplicación _Button Mapper_ (`flar2.homebutton`). Podrías sentirte tentado a pagar la versión pro para usar su mapeo _HTTP POST_ integrado. No te molestes: no solo no es necesario, sino que realmente no funciona.

Así que, como siguiente paso, también instala la aplicación _HTTP Request Shortcuts_ (`ch.rmy.android.http_shortcuts`). En esta app, configura la solicitud HTTP POST que te gustaría enviar a tu instancia de Home Assistant cuando se presione el botón.

Luego, regresa a la app Button Mapper y, para la pulsación del botón de volumen+, configura la acción para que active un acceso directo: selecciona "HTTP Shortcuts" y finalmente el acceso directo que configuraste en el paso anterior. Si aparece un popup, elige el modo "legacy" (si eliges el modo "actual", obtendrás un error).

¡Deberías estar listo! Quizás solo quieras ajustar algunos detalles en la configuración de HTTP Shortcuts. Por ejemplo, después de probar la configuración algunas veces, configuré HTTP Shortcuts para que se ejecute en modo silencioso en caso de éxito, lo que solo hace que la pantalla parpadee por un instante cuando presionas el botón, dando una retroalimentación visual muy agradable.

Por supuesto, puedes repetir el proceso para el otro botón de volumen-. Ten en cuenta que no puedes configurar el botón de encendido (Android no lo permite, a menos que el dispositivo esté rooteado), ni el botón de silencio del micrófono (que parece estar físicamente vinculado al hardware, ya que no genera un _intent_ en Android cuando se presiona).

Finalmente, configuré las pulsaciones prolongadas de los botones para seguir activando el volumen, así que esa función no se pierde; y todavía tienes el doble clic disponible para activar otras automatizaciones.

## Otros detalles del proceso

Mientras configuraba esta instalación, a menudo necesitaba ingresar cadenas de texto largas (por ejemplo, tokens de autenticación Bearer) o, en general, copiar/pegar bastante texto (por ejemplo, modificar automatizaciones de terceros).

Lamentablemente, el sistema operativo de Movistar Home está muy reducido en cuanto a la capacidad de copiar/pegar desde los campos de texto de entrada (a veces puedes, pero en la mayoría de los casos presionas prolongadamente el campo de texto y no pasa nada). Además, el teclado estándar de Android 8 no ofrece (como los teclados modernos) la capacidad de ingresar contenido del portapapeles.

La solución más sencilla es usar el teclado Bluetooth virtual de MacOS. Si puedes copiar/pegar el texto desde el sistema operativo del escritorio (por ejemplo, generar el token Bearer en el escritorio), entonces puedes usar el teclado virtual para enviar el contenido pegado.

Muchas veces olvidé esto a lo largo del proceso, por lo que tuve que ingeniármelas con soluciones creativas para copiar/pegar dentro del Movistar Home. No recomiendo este enfoque, pero lo documentaré aquí por si resulta útil.

Primero, intenté instalar teclados más modernos (como Microsoft SwiftKey), pero no se ejecutaban en el sistema operativo limitado del Movistar Home.

Entonces, desesperado, terminé instalando la aplicación _Paste Keyboard_ (`com.appmazing.autopastekey`). Esta es una... curiosa aplicación que te permite configurar algunas cadenas de texto estáticas, y luego, cuando seleccionas la app como teclado del sistema operativo,
te permite pegarlas en un campo de texto. Cumple su función.

Pero, supongamos que copiaste un Bearer Token en el portapapeles. ¿Cómo lo pegas en la configuración de Paste Keyboard, si al presionar prolongadamente el campo de texto no aparece la opción de pegar?

Aquí entra en acción _AnyCopy_ (`any.copy.io.basic`). Esta es una aplicación que captura todo lo que se copia al portapapeles y lo almacena. Luego, si instalas una aplicación complementaria vinculada desde dentro de la app, puedes dar doble toque en (casi) cualquier campo de texto para abrir un popup y pegar el contenido guardado. Digo que funciona en casi cualquier campo de texto, porque sí funcionó en Paste Keyboard, pero no en HTTP Shortcuts, lo que me obligó a recurrir al truco del teclado adicional.

Repito, lo mejor es no complicarse la vida y simplemente usar el teclado Bluetooth virtual cuando configures tu dispositivo Movistar Home.

## Conclusión

Este resumen abarca mi configuración y la experiencia que he tenido con este dispositivo... hasta ahora.

La tablet no es muy potente -- tengo un panel de Home Assistant mostrando 8 cámaras de seguridad, y ahí peta bastante (cualquier teléfono móvil moderno con Android lo maneja sin problema).

Además, todas las limitaciones del sistema operativo reducido hacen que sea un compromiso (cuando no un dolor de cabeza) utilizarlo. Por ejemplo, el salvapantallas improvisado, los problemas con copiar/pegar, la falta de un WebView moderno... podría seguir.

Sin embargo, estas unidades pueden encontrarse muy baratas de segunda mano, y si se ajustan a tu caso de uso, siguen siendo una gran opción por su precio.

Si experimentaste con ellas y tienes información para mejorar, corregir o ampliar este documento, ¡avisa en el [grupo de Telegram](https://t.me/movistar_home_hacking)! ¡La comunidad allí es excelente!
