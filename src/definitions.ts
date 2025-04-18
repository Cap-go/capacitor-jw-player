export interface JwPlayerPlugin {
  /**
   * Initialize the JW Player
   * @param options - The options for the JW Player
   * @param options.licenseKey - The license key for the JW Player. Keep in mind that this is different for iOS and Android.
   * @returns A promise that resolves to the JW Player instance
   */
  initialize(options: { licenseKey: string }): Promise<void>;
  /**
   * Play a video
   * @param options - The options for the JW Player
   * @param options.mediaUrl - The URL of the media to play
   * @param options.mediaType - The type of media to play
   * @returns A promise that resolves to the JW Player instance
   */
  play(options: { 
    mediaUrl: string 
    mediaType: 'video' | 'playlist'
  }): Promise<void>;

  /**
   * Load a video
   * @param options - The options for the JW Player
   * @param options.mediaUrl - The URL of the media to play
   * @param options.mediaType - The type of media to play
   * @returns A promise that resolves to the JW Player instance
   */
  load(options: {
    mediaUrl: string 
    mediaType: 'video' | 'playlist'
  }): Promise<void>;

  /**
   * Get the current playlist
   * @returns A promise that resolves to the current playlist
   */
  currentPlaylist(): Promise<any>;
}
