package ee.forgr.capacitor_jw_player;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import android.graphics.Rect;
import android.os.Build;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.Rational;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.ImageButton;
import android.widget.ImageView;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.gms.cast.CastMediaControlIntent;
import com.google.android.gms.cast.LaunchOptions;
import com.google.android.gms.cast.framework.CastOptions;
import com.google.android.gms.cast.framework.OptionsProvider;
import com.google.android.gms.cast.framework.SessionProvider;
import com.jwplayer.pub.api.JWPlayer;
import com.jwplayer.pub.api.PlayerState;
import com.jwplayer.pub.api.UiGroup;
import com.jwplayer.pub.api.configuration.PlayerConfig;
// import com.jwplayer.pub.api.configuration.PlaylistConfig; // Already commented/removed - ensure it's gone
import com.jwplayer.pub.api.configuration.UiConfig;
import com.jwplayer.pub.api.events.*;
import com.jwplayer.pub.api.events.listeners.AdvertisingEvents;
import com.jwplayer.pub.api.events.listeners.VideoPlayerEvents;
import com.jwplayer.pub.api.license.LicenseUtil;
import com.jwplayer.pub.api.media.captions.Caption;
import com.jwplayer.pub.api.media.captions.CaptionType;
import com.jwplayer.pub.api.media.meta.Metadata;
import com.jwplayer.pub.api.media.playlists.PlaylistItem;
import com.jwplayer.pub.ui.viewmodels.ControlbarViewModel;
import com.jwplayer.pub.view.JWPlayerView;
import com.jwplayer.ui.views.ControlbarView;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class PlayerActivity
    extends AppCompatActivity
    implements
        VideoPlayerEvents.OnFullscreenListener,
        VideoPlayerEvents.OnReadyListener,
        VideoPlayerEvents.OnErrorListener,
        VideoPlayerEvents.OnSetupErrorListener,
        VideoPlayerEvents.OnPlaylistCompleteListener,
        VideoPlayerEvents.OnPlaylistItemListener,
        VideoPlayerEvents.OnPauseListener,
        VideoPlayerEvents.OnPlayListener,
        VideoPlayerEvents.OnCompleteListener,
        VideoPlayerEvents.OnSeekListener,
        VideoPlayerEvents.OnTimeListener,
        AdvertisingEvents.OnAdErrorListener,
        AdvertisingEvents.OnAdWarningListener,
        VideoPlayerEvents.OnMetaListener {

    private static final String TAG = "PlayerActivity";
    public static final String EXTRA_MEDIA_URL = "mediaUrl";
    public static final String EXTRA_MEDIA_TYPE = "mediaType";
    public static final String AUTOSTART = "autostartMedia";

    private JWPlayerView mPlayerView;
    private JWPlayer mPlayer;
    private ImageButton mCloseButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(TAG, "onCreate");

        setContentView(R.layout.activity_player);

        // Make activity fullscreen - moved after setContentView
        if (getWindow() != null) {
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
            // Keep the screen on during playback
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        } else {
            Log.e(TAG, "Window is null in onCreate!");
        }

        // Hide navigation bar and enable immersive mode
        hideSystemUI();

        mPlayerView = findViewById(R.id.jwplayer);
        mPlayer = mPlayerView.getPlayer();
        mPlayer.registerActivityForPip(this, getSupportActionBar());

        // Delete fullscreen button
        ControlbarView customControlBar = mPlayerView.getControlsContainer().getControlbarView();
        ImageView enterFullScreenButton = customControlBar.findViewById(com.longtailvideo.jwplayer.R.id.controlbar_enter_fullscreen_btn);
        ImageView exitFullScreenButton = customControlBar.findViewById(com.longtailvideo.jwplayer.R.id.controlbar_exit_fullscreen_btn);
        if (enterFullScreenButton != null && enterFullScreenButton.getParent() != null) {
            ((ViewGroup) enterFullScreenButton.getParent()).removeView(enterFullScreenButton);
        }
        if (exitFullScreenButton != null && exitFullScreenButton.getParent() != null) {
            ((ViewGroup) exitFullScreenButton.getParent()).removeView(exitFullScreenButton);
        }

        // Setup Close Button
        mCloseButton = findViewById(R.id.close_button);
        mCloseButton.setOnClickListener((v) -> finish());

        ControlbarViewModel controlbarViewModel = (ControlbarViewModel) mPlayer.getViewModelForUiGroup(UiGroup.CONTROLBAR);

        controlbarViewModel
            .isUiLayerVisible()
            .observe(this, (isVisible) -> {
                if (isInPictureInPictureMode()) {
                    mCloseButton.setVisibility(View.GONE);
                    return;
                }
                mCloseButton.setVisibility(isVisible ? View.VISIBLE : View.INVISIBLE);
            });

        // Set the static instance reference in the plugin
        JwPlayerPlugin.setStaticPlayerInstance(mPlayer);

        mPlayerView.setOnClickListener((v) -> toggleSystemUI());

        // Initialize JW Player license (ensure this is also done in Plugin if needed)
        // new LicenseUtil().setLicenseKey(this, "YOUR_LICENSE_KEY"); // Ideally get from Intent or Plugin

        // Setup JW Player listeners
        setupPlayerListeners();

        // Get playback info from Intent
        Intent intent = getIntent();
        String mediaUrl = intent.getStringExtra(EXTRA_MEDIA_URL);
        String mediaType = intent.getStringExtra(EXTRA_MEDIA_TYPE);
        boolean autostart = intent.getBooleanExtra(AUTOSTART, false);

        if (mediaUrl != null && mediaType != null) {
            Log.d(TAG, "Received Media URL: " + mediaUrl + ", Type: " + mediaType);
            loadMedia(mediaUrl, mediaType, autostart);
        } else {
            Log.e(TAG, "Error: Media URL or Type not provided in Intent.");
            // Notify plugin of error?
            finish(); // Close if no media info
        }
    }

    private void loadMedia(String mediaUrl, String mediaType, boolean autostart) {
        if (mediaType.equals("video")) {
            PlaylistItem playlistItem = new PlaylistItem.Builder()
                .file(mediaUrl)
                // .title("Video Title") // Optional
                // .description("Video Description") // Optional
                .build();

            List<PlaylistItem> playlist = new ArrayList<>();
            playlist.add(playlistItem);

            PlayerConfig config = new PlayerConfig.Builder().playlist(playlist).autostart(autostart).build();

            mPlayer.setup(config);
            Log.d(TAG, "Player setup initiated.");
        } else if (mediaType.equals("playlist")) {
            PlayerConfig config = new PlayerConfig.Builder().playlistUrl(mediaUrl).autostart(autostart).build();

            mPlayer.setup(config);
        }
    }

    private void setupPlayerListeners() {
        mPlayer.addListener(EventType.READY, this);
        mPlayer.addListener(EventType.ERROR, this);
        mPlayer.addListener(EventType.SETUP_ERROR, this);
        mPlayer.addListener(EventType.FULLSCREEN, this);
        mPlayer.addListener(EventType.PLAYLIST_COMPLETE, this);
        mPlayer.addListener(EventType.PLAYLIST_ITEM, this);
        mPlayer.addListener(EventType.PAUSE, this);
        mPlayer.addListener(EventType.PLAY, this);
        mPlayer.addListener(EventType.COMPLETE, this);
        mPlayer.addListener(EventType.SEEK, this);
        mPlayer.addListener(EventType.TIME, this);
        mPlayer.addListener(EventType.AD_ERROR, this);
        mPlayer.addListener(EventType.AD_WARNING, this);
        mPlayer.addListener(EventType.META, this);
    }

    @Override
    protected void onResume() {
        super.onResume();
        Log.d(TAG, "onResume");
        if (mPlayer != null) {
            // mPlayer.play(); // Resume playback
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        Log.d(TAG, "onPause");
        if (mPlayer != null && !isInPictureInPictureMode()) {
            // Don't pause if entering PiP
            // mPlayer.pause();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "onDestroy");
        // Clean up resources
        if (mPlayerView != null) {
            // mPlayerView.onDestroy(); // Check JW Player docs if needed
        }
        if (getWindow() != null) {
            getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        }
        // Notify plugin that player was dismissed AND clear static instance
        JwPlayerPlugin.onPlayerDismissed(); // This already clears the static instance
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        // Exit fullscreen when the back button is pressed
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            finish();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus && getWindow() != null) {
            hideSystemUI();
        }
    }

    // --- Fullscreen Handling --- Not needed as Activity is fullscreen by default
    public void onFullscreen(FullscreenEvent fullscreenEvent) {
        Log.d(TAG, "onFullscreen event: " + fullscreenEvent.getFullscreen());
        // Activity is already fullscreen, this listener might be for internal JW Player state
        // We don't need to change Android's fullscreen state here.
    }

    // --- Picture-in-Picture --- (Basic handling)
    @Override
    public void onUserLeaveHint() {
        // Enter PiP if supported when user navigates away (e.g., home button)
        super.onUserLeaveHint();
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            getPackageManager().hasSystemFeature(getPackageManager().FEATURE_PICTURE_IN_PICTURE)
        ) {
            if (mPlayer != null && mPlayer.getState() == PlayerState.PLAYING) {
                Log.d(TAG, "User leaving hint, entering PiP mode.");
                // enterPictureInPictureMode();
            }
        }
    }

    @Override
    public void onStop() {
        Log.d(TAG, "On stop triggered?");
        super.onStop();
    }

    @Override
    public void onPictureInPictureModeChanged(boolean isInPictureInPictureMode, Configuration newConfig) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig);
        mPlayer.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig);
        Log.d(TAG, "onPictureInPictureModeChanged: " + isInPictureInPictureMode);
        if (isInPictureInPictureMode) {
            // PiP is active, hide controls like the close button
            mCloseButton.setVisibility(View.GONE);
        } else {
            // PiP is inactive, restore UI
            mCloseButton.setVisibility(View.VISIBLE);
            if (getWindow() != null) {
                hideSystemUI(); // Re-hide system bars when exiting PiP
            }
        }
        // Notify plugin about PiP status change?
        JwPlayerPlugin.notifyPipChanged(isInPictureInPictureMode);
    }

    // --- Player Event Listeners --- (Notify plugin)

    public void onReady(ReadyEvent readyEvent) {
        Log.d(TAG, "onReady");
        JwPlayerPlugin.notifyReady();
    }

    public void onSetupError(SetupErrorEvent setupErrorEvent) {
        Log.e(TAG, "onSetupError: " + setupErrorEvent.getMessage());
        JwPlayerPlugin.notifyError("setupError", setupErrorEvent.getMessage());
        finish();
    }

    public void onError(ErrorEvent errorEvent) {
        Log.e(TAG, "onError: " + errorEvent.getMessage());
        JwPlayerPlugin.notifyError("error", errorEvent.getMessage());
        // Decide if we should finish based on error type?
    }

    public void onAdError(AdErrorEvent adErrorEvent) {
        Log.e(TAG, "onAdError: " + adErrorEvent.getMessage());
        JwPlayerPlugin.notifyError("adError", adErrorEvent.getMessage());
    }

    public void onAdWarning(AdWarningEvent adWarningEvent) {
        Log.w(TAG, "onAdWarning: " + adWarningEvent.getMessage());
        JwPlayerPlugin.notifyWarning("adWarning", adWarningEvent.getMessage());
    }

    public void onPlaylistItem(PlaylistItemEvent playlistItemEvent) {
        Log.d(TAG, "onPlaylistItem: index=" + playlistItemEvent.getIndex());
        // Need to serialize item data if required by JS
        JwPlayerPlugin.notifyPlaylistItem(playlistItemEvent.getIndex(), playlistItemEvent.getPlaylistItem());
    }

    public void onPlaylistComplete(PlaylistCompleteEvent playlistCompleteEvent) {
        Log.d(TAG, "onPlaylistComplete");
        JwPlayerPlugin.notifyPlaylistComplete();
        finish(); // Close activity when playlist finishes
    }

    public void onPause(PauseEvent pauseEvent) {
        Log.d(TAG, "onPause event: state=" + pauseEvent.getOldState());
        JwPlayerPlugin.notifyPause(pauseEvent.getPauseReason().name());
    }

    public void onPlay(PlayEvent playEvent) {
        Log.d(TAG, "onPlay event: state=" + playEvent.getOldState());
        JwPlayerPlugin.notifyPlay(playEvent.getPlayReason().name());
    }

    public void onMeta(MetaEvent metaEvent) {
        Metadata metadata = metaEvent.getMetadata();
        // Calculate aspect ratio and ensure it's within PiP bounds (2.38:1 to 1:2.38)
        // The aspect ratio allows up to .39 but, i want to be safe and set it to 2.38
        float aspectRatio = (float) metadata.getWidth() / metadata.getHeight();
        int width = metadata.getWidth();
        int height = metadata.getHeight();

        if (aspectRatio > 2.38f) {
            // Too wide, adjust width, let's not handle it
            return;
        } else if (aspectRatio < 1 / 2.38f) {
            // Too tall, adjust height, let's not handle it for now
            return;
        }

        Rational rational = new Rational(width, height);
        // Get the display metrics for the current screen
        DisplayMetrics displayMetrics = new DisplayMetrics();
        getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);
        int screenWidth = displayMetrics.widthPixels;

        // Calculate one-third of screen width and round to nearest even number
        int thirdWidth = (int) Math.round((double) screenWidth / 3.0);
        if (thirdWidth % 2 != 0) {
            // If odd, round up to next even number
            thirdWidth += 1;
        }

        int thirdHeight = (int) Math.round(((double) screenWidth / 3.0) * aspectRatio);
        if (thirdHeight % 2 != 0) {
            // If odd, round up to next even number
            thirdHeight += 1;
        }

        if (mPlayer != null) {
            mPlayer.setPipAspectRatio(rational);
            mPlayer.setPipSourceRectHint(new Rect(0, 0, thirdWidth, thirdHeight));
        }
    }

    public void onComplete(CompleteEvent completeEvent) {
        Log.d(TAG, "onComplete event");
        JwPlayerPlugin.notifyComplete();
    }

    public void onSeek(SeekEvent seekEvent) {
        Log.d(TAG, "onSeek event: position=" + seekEvent.getPosition() + ", offset=" + seekEvent.getOffset());
        JwPlayerPlugin.notifySeek(seekEvent.getPosition(), seekEvent.getOffset());
    }

    public void onTime(TimeEvent timeEvent) {
        // Log.v(TAG, "onTime event: position=" + timeEvent.getPosition() + ", duration=" + timeEvent.getDuration());
        JwPlayerPlugin.notifyTime(timeEvent.getPosition(), timeEvent.getDuration());
    }

    // --- System UI Helpers ---
    private void hideSystemUI() {
        // Check if window is null
        if (getWindow() == null) {
            Log.e(TAG, "Window is null in hideSystemUI!");
            return;
        }

        // For AppCompatActivity, use the support library methods
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            getWindow().setDecorFitsSystemWindows(false);
            android.view.WindowInsetsController insetsController = getWindow().getInsetsController();
            if (insetsController != null) {
                insetsController.hide(android.view.WindowInsets.Type.statusBars() | android.view.WindowInsets.Type.navigationBars());
                insetsController.setSystemBarsBehavior(android.view.WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
            }
        } else {
            // Legacy method for older Android versions
            View decorView = getWindow().getDecorView();
            decorView.setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY |
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE |
                    View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION |
                    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN |
                    View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
                    View.SYSTEM_UI_FLAG_FULLSCREEN
            );
        }
    }

    private void showSystemUI() {
        // Check if window is null
        if (getWindow() == null) {
            Log.e(TAG, "Window is null in showSystemUI!");
            return;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            getWindow().setDecorFitsSystemWindows(true);
            getWindow()
                .getInsetsController()
                .show(android.view.WindowInsets.Type.statusBars() | android.view.WindowInsets.Type.navigationBars());
        } else {
            // Legacy method for older Android versions
            View decorView = getWindow().getDecorView();
            decorView.setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            );
        }
    }

    private void toggleSystemUI() {
        // Check if window is null
        if (getWindow() == null) {
            Log.e(TAG, "Window is null in toggleSystemUI!");
            return;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // For Android 11+, use InsetsController to check visibility
            // Just toggle - there's no direct visibility check for R+
            hideSystemUI();
        } else {
            View decorView = getWindow().getDecorView();
            boolean isVisible = (decorView.getSystemUiVisibility() & View.SYSTEM_UI_FLAG_HIDE_NAVIGATION) == 0;
            if (isVisible) {
                hideSystemUI();
            } else {
                showSystemUI();
            }
        }
    }
}
