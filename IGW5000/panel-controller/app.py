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
