package ee.forgr.capacitor_jw_player;

import android.content.Intent;
import android.util.Log;
import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.google.android.gms.cast.framework.CastContext;
import com.jwplayer.pub.api.JWPlayer;
import com.jwplayer.pub.api.configuration.PlayerConfig;
import com.jwplayer.pub.api.license.LicenseUtil;
import com.jwplayer.pub.api.media.audio.AudioTrack;
import com.jwplayer.pub.api.media.captions.Caption;
import com.jwplayer.pub.api.media.playlists.PlaylistItem;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;

@CapacitorPlugin(name = "JwPlayer")
public class JwPlayerPlugin extends Plugin {

    private final String pluginVersion = "8.0.2";

    private static final String TAG = "JwPlayerPlugin";
    // Static reference to the plugin instance for activity communication
    private static WeakReference<JwPlayerPlugin> staticPluginRef;
    private static JWPlayer staticPlayerInstance; // To control playback from plugin methods

    @Override
    public void load() {
        super.load();
        staticPluginRef = new WeakReference<>(this);
        Log.i(TAG, "Plugin loaded and static reference set.");
        // License key initialization might be better placed here or in initialize()
    }

    @PluginMethod
    public void initialize(PluginCall call) {
        String licenseKey = call.getString("licenseKey");
        if (licenseKey == null || licenseKey.isEmpty()) {
            call.reject("licenseKey is required for initialize");
            return;
        }
        Log.i(TAG, "Initializing JW Player SDK with license key.");
        // Initialize license
        new LicenseUtil().setLicenseKey(getContext(), licenseKey);
        // You might want to add success/failure listeners to the license call if available
        call.resolve();
    }

    @PluginMethod
    public void play(PluginCall call) {
        String mediaUrl = call.getString("mediaUrl");
        String mediaType = call.getString("mediaType");
        boolean autostart = Boolean.TRUE.equals(call.getBoolean("autostart", false));

        if (mediaUrl == null || mediaUrl.isEmpty()) {
            call.reject("mediaUrl is required for play");
            return;
        }
        if (mediaType == null || mediaType.isEmpty()) {
            call.reject("mediaType is required for play");
            return;
        }

        Log.d(TAG, "Launching PlayerActivity with URL: " + mediaUrl + ", Type: " + mediaType);

        Intent intent = new Intent(getContext(), PlayerActivity.class);
        intent.putExtra(PlayerActivity.EXTRA_MEDIA_URL, mediaUrl);
        intent.putExtra(PlayerActivity.EXTRA_MEDIA_TYPE, mediaType);
        intent.putExtra(PlayerActivity.AUTOSTART, autostart);
        getActivity().startActivity(intent);

        // We resolve immediately, actual playback state comes via events
        call.resolve();
    }

    @PluginMethod
    public void pause(PluginCall call) {
        Log.d(TAG, "Pause called");
        if (staticPlayerInstance != null) {
            staticPlayerInstance.pause();
            call.resolve();
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void resume(PluginCall call) {
        Log.d(TAG, "Resume called");
        if (staticPlayerInstance != null) {
            staticPlayerInstance.play();
            call.resolve();
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void stop(PluginCall call) {
        Log.d(TAG, "Stop called");
        if (staticPlayerInstance != null) {
            staticPlayerInstance.stop();
            // Consider finishing PlayerActivity here? Maybe PlayerActivity should finish itself on stop.
            call.resolve();
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void seekTo(PluginCall call) {
        Double time = call.getDouble("time");
        if (time == null) {
            call.reject("time parameter is required");
            return;
        }
        if (staticPlayerInstance != null) {
            staticPlayerInstance.seek(time);
            call.resolve();
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void setVolume(PluginCall call) {
        Double volume = call.getDouble("volume"); // JW Player Android uses 0-100
        if (volume == null) {
            call.reject("volume parameter is required");
            return;
        }
        if (staticPlayerInstance != null) {
            // Cast the result to int
            staticPlayerInstance.setVolume((int) (volume.floatValue() * 100));
            call.resolve();
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void setSpeed(PluginCall call) {
        Double speed = call.getDouble("speed");
        if (speed == null) {
            call.reject("speed parameter is required");
            return;
        }
        if (staticPlayerInstance != null) {
            staticPlayerInstance.setPlaybackRate(speed.floatValue());
            call.resolve();
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void getPosition(PluginCall call) {
        if (staticPlayerInstance != null) {
            JSObject ret = new JSObject();
            ret.put("position", staticPlayerInstance.getPosition());
            call.resolve(ret);
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void getState(PluginCall call) {
        if (staticPlayerInstance != null) {
            JSObject ret = new JSObject();
            // Convert JWPlayerState enum to int like iOS
            int stateInt = mapPlayerStateToInt(staticPlayerInstance.getState());
            ret.put("state", stateInt);
            call.resolve(ret);
        } else {
            call.reject("Player not active", "-1"); // Return -1 or similar on error
        }
    }

    @PluginMethod
    public void loadPlaylist(PluginCall call) {
        String playlistUrl = call.getString("playlistUrl");
        if (playlistUrl == null || playlistUrl.isEmpty()) {
            call.reject("playlistUrl parameter is required");
            return;
        }
        if (staticPlayerInstance != null) {
            Log.d(TAG, "Loading playlist from URL: " + playlistUrl);
            // Use PlayerConfig with a single playlist item URL
            PlaylistItem playlistItem = new PlaylistItem.Builder().file(playlistUrl).build();
            List<PlaylistItem> playlist = new ArrayList<>();
            playlist.add(playlistItem);
            PlayerConfig config = new PlayerConfig.Builder()
                .playlist(playlist)
                // Autostart false when just loading?
                .autostart(false)
                .build();
            staticPlayerInstance.setup(config); // Use setup for subsequent loads
            call.resolve();
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void loadPlaylistWithItems(PluginCall call) {
        JSArray itemsJS = call.getArray("playlist");
        if (itemsJS == null) {
            call.reject("playlist parameter is required and must be an array");
            return;
        }
        if (staticPlayerInstance != null) {
            try {
                List<PlaylistItem> playlist = new ArrayList<>();
                for (int i = 0; i < itemsJS.length(); i++) {
                    JSObject itemJS = JSObject.fromJSONObject(itemsJS.getJSONObject(i));
                    String file = itemJS.getString("file");
                    if (file != null) {
                        PlaylistItem.Builder itemBuilder = new PlaylistItem.Builder().file(file);
                        if (itemJS.has("title")) {
                            itemBuilder.title(itemJS.getString("title"));
                        }
                        playlist.add(itemBuilder.build());
                    }
                }
                if (!playlist.isEmpty()) {
                    Log.d(TAG, "Loading playlist with " + playlist.size() + " items");
                    // Use PlayerConfig for loading multiple items too
                    PlayerConfig config = new PlayerConfig.Builder()
                        .playlist(playlist)
                        .autostart(false) // Or true depending on desired behavior
                        .build();
                    staticPlayerInstance.setup(config); // Use setup
                    call.resolve();
                } else {
                    call.reject("No valid playlist items found");
                }
            } catch (Exception e) {
                Log.e(TAG, "Error parsing playlist items", e);
                call.reject("Error parsing playlist items: " + e.getMessage());
            }
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void setPlaylistIndex(PluginCall call) {
        Integer index = call.getInt("index");
        if (index == null) {
            call.reject("index parameter is required");
            return;
        }
        if (staticPlayerInstance != null) {
            Log.d(TAG, "Setting playlist index to: " + index);
            staticPlayerInstance.playlistItem(index);
            call.resolve();
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void getAudioTracks(PluginCall call) {
        if (staticPlayerInstance != null) {
            List<AudioTrack> audioTracks = staticPlayerInstance.getAudioTracks();
            JSArray tracksArray = new JSArray();
            if (audioTracks != null) {
                for (AudioTrack track : audioTracks) {
                    JSObject trackObj = new JSObject();
                    trackObj.put("name", track.getName());
                    trackObj.put("language", track.getLanguage());
                    // trackObj.put("defaultTrack", track.isDefaultTrack()); // Check API for default
                    tracksArray.put(trackObj);
                }
            }
            JSObject result = new JSObject();
            result.put("tracks", tracksArray);
            call.resolve(result);
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void getCurrentAudioTrack(PluginCall call) {
        if (staticPlayerInstance != null) {
            int index = staticPlayerInstance.getCurrentAudioTrack();
            JSObject result = new JSObject();
            result.put("index", index);
            call.resolve(result);
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void setCurrentAudioTrack(PluginCall call) {
        Integer index = call.getInt("index");
        if (index == null) {
            call.reject("index parameter is required");
            return;
        }
        if (staticPlayerInstance != null) {
            Log.d(TAG, "Setting audio track index to: " + index);
            staticPlayerInstance.setCurrentAudioTrack(index);
            call.resolve();
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void getCaptions(PluginCall call) {
        if (staticPlayerInstance != null) {
            List<Caption> captions = staticPlayerInstance.getCaptionsList();
            JSArray captionsArray = new JSArray();
            if (captions != null) {
                for (int i = 0; i < captions.size(); i++) {
                    Caption caption = captions.get(i);
                    JSObject captionObj = new JSObject();
                    captionObj.put("index", i); // Use list index
                    captionObj.put("label", caption.getLabel());
                    // captionObj.put("language", caption.getLanguage()); // Check API
                    captionsArray.put(captionObj);
                }
            }
            JSObject result = new JSObject();
            result.put("captions", captionsArray);
            call.resolve(result);
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void getCurrentCaptions(PluginCall call) {
        if (staticPlayerInstance != null) {
            int index = staticPlayerInstance.getCurrentCaptions();
            JSObject result = new JSObject();
            result.put("index", index); // 0 typically means off
            call.resolve(result);
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void setCurrentCaptions(PluginCall call) {
        Integer index = call.getInt("index");
        if (index == null) {
            call.reject("index parameter is required");
            return;
        }
        if (staticPlayerInstance != null) {
            Log.d(TAG, "Setting captions index to: " + index);
            staticPlayerInstance.setCurrentCaptions(index);
            call.resolve();
        } else {
            call.reject("Player not active");
        }
    }

    @PluginMethod
    public void currentPlaylist(PluginCall call) {
        if (staticPlayerInstance != null) {
            List<PlaylistItem> playlist = staticPlayerInstance.getPlaylist();
            JSArray playlistJS = new JSArray();
            if (playlist != null) {
                for (PlaylistItem item : playlist) {
                    JSObject itemJS = new JSObject();
                    itemJS.put("file", item.getFile());
                    itemJS.put("title", item.getTitle());
                    itemJS.put("description", item.getDescription());
                    // Add other relevant properties
                    playlistJS.put(itemJS);
                }
            }
            JSObject result = new JSObject();
            result.put("playlist", playlistJS);
            call.resolve(result);
        } else {
            call.reject("Player not active");
        }
    }

    // --- Static methods for PlayerActivity Communication ---

    public static void setStaticPlayerInstance(JWPlayer player) {
        Log.d(TAG, "Setting static player instance: " + (player != null));
        staticPlayerInstance = player;
    }

    public static void onPlayerDismissed() {
        Log.d(TAG, "PlayerActivity dismissed, clearing static player instance.");
        staticPlayerInstance = null;
        JwPlayerPlugin plugin = staticPluginRef != null ? staticPluginRef.get() : null;
        if (plugin != null) {
            plugin.notifyListeners("playerDismissed", null);
        }
    }

    public static void notifyPipChanged(boolean isInPip) {
        JwPlayerPlugin plugin = staticPluginRef != null ? staticPluginRef.get() : null;
        if (plugin != null) {
            JSObject data = new JSObject();
            data.put("isInPictureInPictureMode", isInPip);
            plugin.notifyListeners(isInPip ? "pipStarted" : "pipStopped", data);
        }
    }

    // Static notification helpers called by PlayerActivity listeners
    public static void notifyReady() {
        JwPlayerPlugin plugin = staticPluginRef != null ? staticPluginRef.get() : null;
        if (plugin != null) {
            plugin.notifyListeners("ready", null);
        }
    }

    public static void notifyError(String type, String message) {
        JwPlayerPlugin plugin = staticPluginRef != null ? staticPluginRef.get() : null;
        if (plugin != null) {
            JSObject data = new JSObject();
            data.put("message", message);
            // data.put("code", code); // Android SDK might not provide code easily
            plugin.notifyListeners(type, data);
        }
    }

    public static void notifyWarning(String type, String message) {
        JwPlayerPlugin plugin = staticPluginRef != null ? staticPluginRef.get() : null;
        if (plugin != null) {
            JSObject data = new JSObject();
            data.put("message", message);
            plugin.notifyListeners(type, data);
        }
    }

    public static void notifyPlaylistItem(int index, PlaylistItem item) {
        JwPlayerPlugin plugin = staticPluginRef != null ? staticPluginRef.get() : null;
        if (plugin != null) {
            JSObject data = new JSObject();
            data.put("index", index);
            if (item != null) {
                data.put("title", item.getTitle());
                // data.put("file", item.getFile()); // Be careful with accessing file directly
            }
            plugin.notifyListeners("playlistItem", data);
        }
    }

    public static void notifyPlaylistComplete() {
        JwPlayerPlugin plugin = staticPluginRef != null ? staticPluginRef.get() : null;
        if (plugin != null) {
            plugin.notifyListeners("complete", null); // Maybe playlistComplete event?
        }
    }

    public static void notifyPause(String reason) {
        JwPlayerPlugin plugin = staticPluginRef != null ? staticPluginRef.get() : null;
        if (plugin != null) {
            JSObject data = new JSObject();
            data.put("reason", reason); // Android uses enum names
            plugin.notifyListeners("pause", data);
        }
    }

    public static void notifyPlay(String reason) {
        JwPlayerPlugin plugin = staticPluginRef != null ? staticPluginRef.get() : null;
        if (plugin != null) {
            JSObject data = new JSObject();
            data.put("reason", reason); // Android uses enum names
            plugin.notifyListeners("play", data);
        }
    }

    public static void notifyComplete() {
        JwPlayerPlugin plugin = staticPluginRef != null ? staticPluginRef.get() : null;
        if (plugin != null) {
            plugin.notifyListeners("complete", null);
        }
    }

    public static void notifySeek(double position, double offset) {
        JwPlayerPlugin plugin = staticPluginRef != null ? staticPluginRef.get() : null;
        if (plugin != null) {
            JSObject data = new JSObject();
            data.put("position", position);
            data.put("offset", offset);
            plugin.notifyListeners("seek", data);
        }
    }

    public static void notifyTime(double position, double duration) {
        JwPlayerPlugin plugin = staticPluginRef != null ? staticPluginRef.get() : null;
        if (plugin != null) {
            JSObject data = new JSObject();
            data.put("position", position);
            data.put("duration", duration);
            plugin.notifyListeners("time", data);
        }
    }

    // Helper to map Android state enum to iOS-like integers
    private int mapPlayerStateToInt(com.jwplayer.pub.api.PlayerState state) {
        switch (state) {
            case IDLE:
                return 0;
            case BUFFERING:
                return 1;
            case PLAYING:
                return 2;
            case PAUSED:
                return 3;
            case COMPLETE:
                return 4;
            default:
                return -1; // Unknown
        }
    }

    // TODO: Implement other methods like loadPlaylist, getAudioTracks, setAudioTrack, getCaptions, setCaptions etc.
    // These will require more complex communication with the PlayerActivity or direct player interaction.

    @PluginMethod
    public void getPluginVersion(final PluginCall call) {
        try {
            final JSObject ret = new JSObject();
            ret.put("version", this.pluginVersion);
            call.resolve(ret);
        } catch (final Exception e) {
            call.reject("Could not get plugin version", e);
        }
    }
}
