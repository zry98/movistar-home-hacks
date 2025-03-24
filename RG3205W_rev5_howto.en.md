# Hacks for RG3205W Rev5

_Author:_ @alfredopironti

**No need to open the box; no soldering; no root; no Linux**

*Just needs a bit of tapping, a Bluetooth (or virtual) keyboard, lots of patience and spare time*

This is a quick how-to documenting my experiments with an ASKEY (RG3205W) rev5 (Fab date: 2101).

This wouldn't be possible without all the existing effort documented by the community, and their active support on the Telegram channel!

The hacks below should also work with the *MitraStar* IGW-5000 model with an Intel CPU, or the *ASKEY* RG3205W Rev4 version; I just havent' tested with those units.
While this setup has several limitations, no low-level components were modified, so the speaker, microphone and camera all work perfectly, something you currently lose if you install Linux on the IGW-5000.

## Escaping the Movistar Home kiosk
These initial steps are documented elsewhere, I'm reporing them here to make this howto self-contained.

### Connect a Bluetooth (virtual) keyboard to launch the embedded email client
Start with a vanilla Movistar Home (maybe do a factory reset to ensure you're starting from a known state).
As documented elsewhere in the docs, at this stage (and only at this stage), you'll need a Wi-Fi connection via the Movistar ISP,
so that the Movistar Home device can complete its initial setup process. Connect through the Movistar-provided Wi-Fi, and go through the initial setup.
Make sure the setup completes and you are in the Movistar Home homepage.

From there, go to the config and try to add a bluetooth speaker. When the Movistar Home is accepting Bluetooth connections, use a bluetooth keyboard to connect.
You should be able to use a physical keyboard. If you have a computer with MacOS,
you can use the [keyPad](https://apps.apple.com/us/app/keypad-bluetooth-keyboard/id1491684442) app;
it's handy as it also allows you to paste long strings (e.g. Bearer tokens).

Once the Bluetooth keyboard is connected, press <kbd>Meta</kbd> and <kbd>E</kbd> (<kbd>Meta</kbd> is the <kbd>Win</kbd> key on a typical keyboard for Windows, or the <kbd>⌘ Command</kbd> key on a keyboard for Macs),

### Setup email to receive and install an App Store .apk
Configure the email app to connect to a remote mailbox. In my experience, *gmx.com* mailboxes will work fine (you can create one dedicated to
your device); make sure to use the *IMAP* protocol, as the *POP* one doesn't correctly download attachments for me.
In my experience, Outlook and Yahoo mail won't work (I always get a username/password error, even when using app passwords);
Gmail doesn't allow to attach .apk files, which are fundamental in our next step.

Go to the web-based gmx.com interface, and create an email (either save as draft, or send to yourself), where you attach the .apk of an app store.
Many people that worked with the Movistar Home device have recommended [Aptoide](https://aptoide.en.aptoide.com/app), which worked fine with me.
Other options are [F-Droid](https://f-droid.org/en/) which, however, only contains open-source applications, somwewhat limiting choice.

Now, back to the email app on your Movistar Home device. Refresh (either the inbox, or the draft folder), and open the email with the app store APK file.
Open the attachment. This will install the app store.

### Install a launcher and get out of Movistar Home kiosk
Once installed, click on *open*, which will launch the app store. From within the app store, select a launcher. The recommended one here is
*Nova Launcher* (`com.teslacoilsw.launcher`). Again my experience was fine with it. Install *Nova Launcher* from the app store; once installed, click *open* to run it.

You should get a popup asking wether Nova Launcher should be the default launcher (or some "Always open with" dialog), to which you want to say *yes*.

Congrats! By the moment Nova Launcher is the defauly launcher, you're out of the Movistar Home kiosk.

At this point you can reboot the unit, and make sure Nova Launcher starts on boot (it will appear like a standard Android tablet).
You may want to fiddle a bit with the Nova Launcher config. For exmaple, I addded the drawer button instead of opening the drawer by sliding (see below why).

From now on, you don't need to be connected to a Movistar Wi-Fi; any Wi-Fi network will do, in fact most of the time I use my unit on a local LAN with no Internet access
(which, given it's Android 8 with the most recent security patches dating back to 2021, is probably a good idea anyway!).
In my unit, no Movistar app is autostarted at boot (I guess the Movistar launcher does that), so I get no interference.
However, I'm aware other users have disabled all Movistar apps from the config menu, which shouldn't hurt.

## Configuring the device to make some use of it
### Basics: button navigation and screen sleep/lock
One thing you'll likely notice, the device has no back/home/recent buttons. In fact, gestures seem to be not available via the config.
Luckily, installing the *Navigation Bar* app (`nu.nav.bar`) you can get the same functionality.
Note the Movistar Home tablet operates like if the screen is rotated, so you'll have to tell the Navigation Bar to set the buttons on the "side", for them to show at the bottom.
I configured them to disappear after 3 seconds, and bring them up by sliding from the bottom, to save screen estate when I don't need them.

Another feature I now seldom use, but I guess it's good to have, is the ability to lock the screen.
The rear button won't lock the screen when pressed; but then again an app comes to the rescue: Lock Screen (`com.olalab.lockscreen`).
Once the screen is locked, indeed you can press the button on the back to wake up the device.

If you instead prefer to simply dim the display down, the *Screen Timeout* app (`de.lhoer0.screentimeout`) is what you're looking for.
You could achieve the same through the settings of the original Movistar apps but, interestingly, the same menu is disabled from the Android configuration.
Crucially, when the display goes idle due to inactivity, the Android OS doesn't send the broadcast intent to communicate the screen has shut down,
much like if that bit of the OS has been stripped out. This means that, sadly, you can't have either the screen lock, or the screensaver start,
right when the display dims: the OS feature has been stripped. This leads to the below automation headache.

### Putting the screen to sleep
I ended up installing *Automate* (`com.llamalab.automate`), that now manages the screensave/screen lock, and
[a few other bits](automate_examples) you can import into your instance (see below for details about each script).

Since we can't tell when the display dims or, in general, when the device is idle, I've automated a workaround that, well, works, albeit it doesn't make me proud.

The [auto-screensaver automation](automate_examples/Run%20screensaver%20every%203min.flo) starts, waits for 3 minutes
(you can tweak the flow to pick the average amount of time you think you'll be continuosuly interacting with the screen),
and then just launches the screensaver (the `Somnambulator` activity) -- alternatively you can modify the flow to lock the screen instead.
Then, the automation waits for the `DREAMING_STOPPED` broadcast intent (if you decided to lock the screen instead, pick the proper broadcast event on wake up),
which triggers once someone touches the screen, waking the device up. At which points, the automation loops on the 3 minutes wait.
Not clean as I'd like, but it works *just good enough*.

You'll want to configure Automate to resume your automations at boot, so they keep running if the power goes out.
But, yes, you read well: Automate will *resume* automations, not *restart* them at boot. What does this means?
Suppose your device was idle, with the screensaver active, and the power goes down. When the power comes back up, your device reboots... and the
screensaver never kicks in. This is because with the screensaver active, the automation was waiting for the `DREAMING_STOPPED` intent. After reboot,
the device has no screensaver active, so unless you run and then exit from it manually, the `DREAMING_STOPPED` intent will never be sent, deadlocking your resumed automation.

Current dirty solution: create [another automation](automate_examples/Start%20Firefox%20and%20screensaver%20at%20boot.flo)
that waits for the `BOOT_COMPLETED` intent, then launches the Screen Saver, and loops waiting again for the boot intent.
(Another solution could be: create an automation that, on boot, kills and re-start all other automations -- requires more nodes that eat against the Automate free tier.)
Yes, you see why I can't be proud. But, again, it works, within the limitations of the OS running on the Movistar Home.

If you find any way of programmatically detecting when the device is idle, please let the community know!

### Bonus: Changing the display brightness based on time of the day
The Movistar Home device doesn't come with a light sensor, so it can't adjust the display brightness based on the outdoor light.
You may be tempted to use Automate to increase/decrease brightness based on time of the day, which is what I've done -- sort of.

Maybe being an automation freak, I can't have a display going dim at, say, 8PM. That's too early in Summer, and too late in Winter!

Luckily, I found a [nice automation by Sándor Illés](https://llamalab.com/automate/community/flows/2103)
that would compute locally (no Internet access required, which is the case for my setup) the sunrise and sunset times for a given day,
based on which I now alter the display brightness. Automate is free for automations with up to 30 nodes -- so I had to spend quite some time tweaking it,
to minimize it so that I could run it within the free tier.
You can download my custom [dim brightness based on time of day automation](automate_examples/Dim%20brightness%20at%20calculated%20sunrise-sunset%20times.flo):
import it, and then set the `lat` and `lng` variables to your location. You can derive your location from any map application.
For example, set `lat` to `40.4163889` and `lng` to `-3.7036111111111114`
(without quotes, as you want numbers), to set it to the Km0 sign in Madird, Puerta del Sol.

## Use case: Home Assistant wall/desk panel
Now that you got to an almost-decent basic setup, you may actually want to do something with the device. I know of people that use it as a Youtube player while cooking.

In my case, I opted for a Home Assistant desk panel (it would stay better on a wall -- eventually in the future I'll remove the case and hang it).

### No Home Assistant app
You may be tempted to install the Home Assistant app from the app store. However, you'll soon notice it uses the stock webview which is, to say the least, outdated.

I see Aptoide lets you download a recent webview, but I haven't tried this route:
on one hand, forums say it's complex to let an app use a custom webview (unless it's statically compiled to embed it);
on the other hand, I'm somewhat afraid of this possibly messing with the base OS, and a factory reset is going to take me so much time to restore the current setup,
I just went another way (see below).

The Home Assistant native app would also be required if you want to use the Home Assistant voice features via the Movistar Home mic and speakers.
Android 8 supports installing voice assistants, so it could be technically doable; however I haven't experiemented with the stipped-down OS,
nor with its CPU capabilities (and the aforecited usage of the outdated webview). If you get any results with this, please let the community know!

### Install browser, and use the Home Assistant Progressive Web App (PWA)
Initially, I installed Chrome (`com.android.chrome`), navigated to my Home Assistant instance and, from there, installed the PWA on the desktop.
I would have stuck with this setup, if only I wasn't running my Home Assistance instance over the local network, via HTTP.
In this case, even when in PWA mode, Chrome always shows the status bar, to remind of an unecrypted connection, which unacceptably eats screen estate.
Not even the `chrome://flags/#unsafely-treat-insecure-origin-as-secure` would remove the bar (the bar would now not show as a warning -- but it would still show up!)

Plan B: Install Firefox (`org.mozilla.firefox`). Now, Firefox really doesn't work well with PWAs: if you tell Firefox to add one on your desktop, every time you launch it,
it actually opens a new tab with the same app. No good.

However, using plain Firefox, and setting my Home Assistance instance as the home page does the trick.

Then, remember the [automation that at boot runs the screensaver](automate_examples/Start%20Firefox%20and%20screensaver%20at%20boot.flo)?
Well, it now starts Firefox first, then the screensaver immediately after.
So that, after a boot, I touch the screen and my Home Assistant home screen is there, waiting for me.

Tip: I created a Home Assistant user dedicated to the Movistar Home device,
and somewhat restricted access as currently possible within the Home Assistant ACLs (e.g. it's a local user).
The Movistar Home comes preinstalled with apps such as QTI Logikit.

### Bonus: Volume buttons as Home Assistant automations
I plan to use the Movistar Home as a door intercom. So, someone rings at the door: wouldn't it be nice if you could walk to the Movistar Home device, press one of the two
"volume" buttons, and have the door open? Well, with the configuration below, you'll be able to!

What we want to achieve here, is that when you press, say, the volume-up button, an HTTP POST requestis sent to your Home Assistant REST API, to trigger the service of your choice.
In my case, opening the door is done by toggling a switch, so it would be doing a POST request to `http://<home-assistant-URL>:8123/api/services/switch/toggle`, using the correct
long-term bearer token as the `Authentication` header, and the desired `entity_id` as the POST data.

First, install the *Button Mapper* app (`flar2.homebutton`). You may be tempted to pay for the pro version, to use its embedded *HTTP POST* mapping. Don't bother:
not only it's not needed; it actually doesn't work.

So, as a next step, also install the *HTTP Request Shortcuts* app (`ch.rmy.android.http_shortcuts`). On this app, do configure the HTTP POST request
you'd like to send to your Home Assistant instance, when the button is pressed.

Then, go back to the Button Mapper app, and for the volume-up button press, configure to trigger a shorcut: then select "HTTP Shortcuts" and finally the shortcut you
defined in the step above. If a popup comes up, pick the "legacy" mode (if you pick the "current" mode, you'll get an error, and you can try again).

You should be all set! You may just want to fine-tune the HTTP Shortcut config.
For instance, after trying the setup a few times, I've configured the HTTP Shortcut to execute silently on success,
which just flashes the screen for a moment when you press it, giving a nice feedback.

Of course, you can repeat for the other, volume-down, button. Note you can't configure the power button (Android doesn't allow that, unless the device is rooted),
nor the mic-mute button (which seems to be physically connected to the hardware, in that no intent is generate in Android when it's pressed).

## Other notes from the journey
While configuring this setup, I often came across the need to input either large strings (e.g. Bearer Tokens), or in general copy/paste quite some text (e.g. refactoring
third-party automations).

Sadly, the Movistar Home OS is mostly stripped down of the ability to copy/paste from input textfields (sometimes you can, but most times you long press the textfield,
and nothing happens). Also, the stock keyboard that comes with Android 8 doesn't offer (like moder keyboards do) the ability to input the clipboard contents.

The easier solution is to use the (MacOS) virtual Bluetooth keyboard. If you can copy/paste the text from the desktop OS (e.g. generate the Bearer Token on the desktop),
then you can use the virtual keyboard to issue the pasted contents.

Often times, I forgot this through my journey, and so came with other creative solutions to handle copy/paste within the Movistar Home.
I don't recommend this approach, but I'm documenting it here, just in case it's useful.

I first tried installing more modern keyboards (e.g. Microsoft SwiftKey), but they won't start in the stripped OS that runs on the Movistar Home.

Then, out of desperation I ended up installing the *Paste Keyboard* app (`com.appmazing.autopastekey`).
This is a... funny application that gets configured with a few static strings,
and then when you select it as the OS keyboard, allows you to paste those strings in the textfield. Does the job.

However, suppose you copied a Bearer Token in the clipoard. How do you paste it into the Paste Keyobard config, given long-pressing its textfield doesn't allow you to paste?

Here comes *AnyCopy* (`any.copy.io.basic`) to the rescue. This is an app that snaps everything that gets copied to the clipboard, and stores it.
Then, if you install a companion app linked from within the app, you can double tap on (almost) any text field, to get a popup and paste the contents it snapped.
I say it works on *almost* any textfield: it does work on the Paste Keyboard app;
it wouldn't work on the HTTP Shortcuts one -- hence why I needed to go through that shady additional keyboard.

Again, just remain sane, and use the virtual Bluetooth keyboard when configuring your Movistar Home unit!

## End notes
This, more or less, summarizes my setup, and journey with the device -- thus far.

The tablet isn't very powerful -- I have a Home Assistant dashboard showing 8 CCTV cameras,
and it chockes there big time (any modern Android mobile phone copes with it just fine).

Also, all the stripped-down OS limitations make it somewhat of a compromise (when not a pain) to use. E.g. the hacked screensaver, the issues with copy/pasting, lack of modern
webview... I could go on.

However, these units can be found very cheap second hand, and if they match your use case, they can still be a good bang for the bucks.

If you managed to experiment with them, and have any info to improve, amend or expand this document, please just shout on the Telegram channel!
The community there is great!
