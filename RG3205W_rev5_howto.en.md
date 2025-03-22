# Make some use of Rev5
**No opening the box; no soldering; no root; no Linux**

*Just a bit of tapping, and a (simulated) Bluetooth keyboard*

This is a quick howto documenting my experiments with an ASKEY (RG3205W) rev5 (Fab date: 2101).
This wouldn't be possible without all the existing effort documented by the community, and their active support on the Telgram channel!

In fact, the below steps should also work with the Mitrastar, or the ASKEY rev4 versions; I just havent' tested with those units.
While this setup has several limitations, one positive bit is that audio and camera work, something you lose if you install Linux on the Mitrastar.

## Escaping the Movistar Home kiosk
These initial steps are documented elsewhere, I'm reporing them here to make this howto self-contained.

Start with a vanilla Movistar Home (maybe do a factory reset to ensure you're starting from a known state).
As documented elsewhere in the docs, at this stage (and only at this stage), you'll need a Wi-Fi connection via the Movistar ISP,
so that the Movistar Home device can complete its initial setup process. Connect through the Movistar-provided Wi-Fi, and go through the initial setup.
Make sure the setup completes and you are in the Movistar Home homepage.

From there, go to the config and try to add a bluetooth speaker. When the Movistar Home is accepting Bluetooth connections, use a bluetooth keyboard to connect.
You should be able to use a physical keyboard. If you have a computer with MacOS, you can use the *keyPad* app;
it's handy as it also allows you to paste long strings (e.g. Bearer tokens).

Once the Bluetooth keyboard is connected, press `<meta>`-E (*`<meta>`* is the Win key on Windows keyboards, or the Command key on MacOS),
to open the email app on the Movistar Home device.

Configure the email app to connect to a remote mailbox. In my experience, *gmx.com* mailboxes will work fine (you can create one dedicated to
your device); make sure to use the *IMAP* protocol, as the *POP* one doesn't correctly download attachments for me.
In my experience, Outlook and Yahoo mail won't work (I always get a username/password error, even when using app passwords);
Gmail doesn't allow to attach .apk files, which are fundamental in our next step.

Go to the web-based gmx.com interface, and create an email (either save as draft, or send to yourself), where you attach the .apk of an app store.
Many people that worked with the Movistar Home device have recommended Aptoide, which worked fine with me. Other options are F-droid which, however,
may have a smaller selection of free-software-only apps.

Now, go back to the Movistar Home device email app. Refresh (either the inbox, or the draft folder), and open the email with the *aptoide.apk*
app store file. Open the attachment. This will install the app store.

Once installed, click on *open*, which will launch the app store. From within the app store, select a launcher. The recommended one here is
*Nova Launcher*. Again my experience was fine with it. Install *Nova Launcher* from the app store; once installed, click *open* to run it.

You should get a popup asking wether Nova Launcher should be the default launcher (or some "Always open with" dialog), to which you want to say *yes*.

Congrats! By the moment Nova Launcher is the defauly launcher, you're out of the Movistar Home kiosk.

At this point you can reboot the unit, and make sure Nova Launcher starts on boot (it will appear like a standard Android tablet).
You may want to fiddle a bit with the Nova Launcher config. For exmaple, I addded the drawer button instead of opening the drawer by sliding (see below why).

## Configuring the device to make some use of it
