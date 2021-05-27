import gdk.Clipboard;
import gdk.Display;
import gdk.Texture;
import gio.AsyncResultIF;
import gio.AsyncResultT;
import gtk.Application;
import gtk.ApplicationWindow;
import gtk.Box;
import gtk.Button;
import gtk.Entry;
import gtk.EntryBuffer;
import gtk.Image;
import gtk.Label;

class AsyncResult : AsyncResultIF
{
    import gobject.ObjectG;

    mixin AsyncResultT!GAsyncResult;

    GAsyncResult* raw;
    bool ownedRef;

    public this(GAsyncResult* raw)
    {
        this.raw = raw;
    }

    override void* getStruct()
    {
        return cast(void*) this.raw;
    }
}

int main(string[] args)
{
    auto application = new Application("org.gtkd.example.clipboard", GApplicationFlags.FLAGS_NONE);
    application.addOnActivate((Application) {
            auto window = new ApplicationWindow(application);
            window.setTitle("Clipboard");

            auto display = Display.getDefault;
            auto clipboard = display.getClipboard;

            auto container = new Box(Orientation.HORIZONTAL, 24);
            container.setMarginTop(24);
            container.setMarginBottom(24);
            container.setMarginStart(24);
            container.setMarginEnd(24);
            container.setHalign(GtkAlign.CENTER);
            container.setValign(GtkAlign.CENTER);

            auto title = new Label("Text");
            title.setHalign(GtkAlign.START);
            container.append(title);

            auto fromEntry = new Entry;
            fromEntry.setPlaceholderText("Type text to copy");
            container.append(fromEntry);

            auto copyBtn = new Button("Copy");
            copyBtn.addOnClicked((Button) {
                    clipboard.setText(fromEntry.getBuffer.getText);
                });
            container.append(copyBtn);

            auto intoEntry = new Entry;
            container.append(intoEntry);

            auto pasteBtn = new Button("Paste");
            pasteBtn.addOnClicked((Button) {
                    extern (C) void callback(GObject* gobject, GAsyncResult* result, void* intoEntry) @system
                    {
                        auto asyncResult = new AsyncResult(result);
                        GdkClipboard* gdkClipboard = cast(GdkClipboard*) gobject;
                        Clipboard clipboard = new Clipboard(gdkClipboard);
                        auto text = clipboard.readTextFinish(asyncResult);
                        EntryBuffer buffer = new EntryBuffer(text, cast(int) text.length);
                        (cast(Entry) intoEntry).setBuffer(buffer);
                    }
                    clipboard.readTextAsync(null, cast(GAsyncReadyCallback) &callback, cast(void*) intoEntry);
                });
            container.append(pasteBtn);

            window.setChild(container);
            window.show();
        });
    return application.run(args);
}
