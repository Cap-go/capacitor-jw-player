export interface JwPlayerPlugin {
  /**
   * Initialize the JW Player
   * @param options - The options for the JW Player
   * @param options.licenseKey - The license key for the JW Player. Keep in mind that this is different for iOS and Android.
   * @param options.playerUrl - The player URL for the JW Player. This is used on the web in order to load the player.
   * @returns A promise that resolves when initialized
   */
  initialize(options: { licenseKey: string; playerUrl?: string }): Promise<void>;

  /**
   * Play a video
   * @param options - The options for the JW Player
   * @param options.mediaUrl - The URL of the media to play
   * @param options.mediaType - The type of media to play
   * @param options.autostart - Whether to start the media automatically. Default is false.
   * @returns A promise that resolves when the command is executed
   */
  play(options: { mediaUrl: string; mediaType: 'video' | 'playlist'; autostart?: boolean }): Promise<void>;

  /**
   * Pause the currently playing media
   * @returns A promise that resolves when the command is executed
   */
  pause(): Promise<void>;

  /**
   * Resume the currently paused media
   * @returns A promise that resolves when the command is executed
   */
  resume(): Promise<void>;

  /**
   * Stop the currently playing media
   * @returns A promise that resolves when the command is executed
   */
  stop(): Promise<void>;

  /**
   * Seek to a specific position in the currently playing media
   * @param options - Options for seeking
   * @param options.time - The position to seek to in seconds
   * @returns A promise that resolves when the command is executed
   */
  seekTo(options: { time: number }): Promise<void>;

  /**
   * Set the volume level
   * @param options - Options for setting volume
   * @param options.volume - The volume level (0.0 to 1.0)
   * @returns A promise that resolves when the command is executed
   */
  setVolume(options: { volume: number }): Promise<void>;

  /**
   * Get the current position in the media
   * @returns A promise that resolves with the current position in seconds
   */
  getPosition(): Promise<{ position: number }>;

  /**
   * Get the current player state
   * @returns A promise that resolves with the player state
   */
  getState(): Promise<{ state: number }>;

  /**
   * Set the playback speed
   * @param options - Options for setting speed
   * @param options.speed - The playback speed (0.5 to 2.0)
   * @returns A promise that resolves when the command is executed
   */
  setSpeed(options: { speed: number }): Promise<void>;

  /**
   * Set the current item in the playlist by index
   * @param options - Options for setting playlist item
   * @param options.index - The index of the item to play
   * @returns A promise that resolves when the command is executed
   */
  setPlaylistIndex(options: { index: number }): Promise<void>;

  /**
   * Load a playlist
   * @param options - Options for loading a playlist
   * @param options.playlistUrl - The URL of the playlist
   * @returns A promise that resolves when the command is executed
   */
  loadPlaylist(options: { playlistUrl: string }): Promise<void>;

  /**
   * Load a playlist with items
   * @param options - Options for loading a playlist
   * @param options.playlist - Array of playlist items
   * @returns A promise that resolves when the command is executed
   */
  loadPlaylistWithItems(options: { playlist: any[] }): Promise<void>;

  /**
   * Get available audio tracks
   * @returns A promise that resolves with available audio tracks
   */
  getAudioTracks(): Promise<{ tracks: any[] }>;

  /**
   * Get the current audio track
   * @returns A promise that resolves with current audio track index
   */
  getCurrentAudioTrack(): Promise<{ index: number }>;

  /**
   * Set the current audio track
   * @param options - Options for setting audio track
   * @param options.index - The index of the audio track
   * @returns A promise that resolves when the command is executed
   */
  setCurrentAudioTrack(options: { index: number }): Promise<void>;

  /**
   * Get the available captions/subtitles
   * @returns A promise that resolves with available captions
   */
  getCaptions(): Promise<{ captions: any[] }>;

  /**
   * Get the current captions/subtitles track
   * @returns A promise that resolves with current captions track index
   */
  getCurrentCaptions(): Promise<{ index: number }>;

  /**
   * Set the current captions/subtitles track
   * @param options - Options for setting captions track
   * @param options.index - The index of the captions track
   * @returns A promise that resolves when the command is executed
   */
  setCurrentCaptions(options: { index: number }): Promise<void>;

  /**
   * Get the current playlist
   * @returns A promise that resolves to the current playlist
   */
  currentPlaylist(): Promise<any>;
}

/**
 * Events emitted by the JW Player plugin across all platforms.
 *
 * The plugin uses Capacitor's event system. You can listen to these events using:
 * ```
 * import { Plugins } from '@capacitor/core';
 * const { JwPlayer } = Plugins;
 *
 * JwPlayer.addListener('ready', () => {
 *   console.log('Player is ready');
 * });
 * ```
 */
export interface JwPlayerEvents {
  /**
   * Fired when the player is ready
   */
  ready: void;

  /**
   * Fired when the player encounters an error
   */
  error: {
    message: string;
    code?: number;
  };

  /**
   * Fired when playback starts or resumes
   */
  play: {
    reason: string;
  };

  /**
   * Fired when playback is paused
   */
  pause: {
    reason: string;
  };

  /**
   * Fired when playback completes (reaches the end)
   */
  complete: void;

  /**
   * Fired when the player is seeking to a new position
   */
  seek: {
    position: number;
    offset: number;
  };

  /**
   * Fired when the player has completed seeking
   */
  seeked: void;

  /**
   * Fired periodically during playback with time updates (throttled)
   */
  time: {
    position: number;
    duration: number;
  };

  /**
   * Fired when a new playlist item starts playing
   */
  playlistItem: {
    index: number;
    title?: string;
  };

  /**
   * Fired when playback of the entire playlist is complete
   */
  playlistComplete: void;

  /**
   * Fired when the player enters or exits fullscreen mode
   */
  fullscreen: {
    fullscreen: boolean;
  };

  /**
   * Fired when the player UI controls visibility changes (show/hide)
   */
  controlsChanged: {
    visible: boolean;
  };

  /**
   * Fired when the player is dismissed (closed)
   */
  playerDismissed: void;

  /**
   * Fired when the player enters Picture-in-Picture mode (iOS/Android only)
   */
  pipStarted: {
    isInPictureInPictureMode?: boolean;
  };

  /**
   * Fired when the player exits Picture-in-Picture mode (iOS/Android only)
   */
  pipStopped: {
    isInPictureInPictureMode?: boolean;
  };

  /**
   * Get the native Capacitor plugin version
   *
   * @returns {Promise<{ id: string }>} an Promise with version for this device
   * @throws An error if the something went wrong
   */
  getPluginVersion(): Promise<{ version: string }>;
}
