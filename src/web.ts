/// <reference types="jwplayer" />
import { WebPlugin } from '@capacitor/core';

import type { JwPlayerPlugin } from './definitions';

declare global {
  interface Window {
    jwplayer: JWPlayerStatic;
  }
}

export class JwPlayerWeb extends WebPlugin implements JwPlayerPlugin {
  // Track if our overlay is currently displayed
  private overlayDiv: HTMLDivElement | null = null;
  // Store JW Player instance
  private jwPlayerInstance: jwplayer.JWPlayer | null = null;

  // Generate a UUID that works in all browsers
  private generateUUID(): string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
      const r = (Math.random() * 16) | 0;
      const v = c === 'x' ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  }

  async initialize(options: { licenseKey: string; playerUrl?: string }): Promise<void> {
    console.log('INITIALIZE', options);

    if (!options.playerUrl) {
      throw new Error('playerUrl is required for web implementation');
    }

    const playerUrl = options.playerUrl;

    await new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = playerUrl;
      script.onload = () => resolve(null);
      script.onerror = () => reject(new Error('Failed to load JW Player script'));
      document.head.appendChild(script);
    });

    // Check if jwplayer() is available globally
    if (typeof window.jwplayer !== 'function') {
      throw new Error('JW Player script failed to load properly - jwplayer() function not found');
    }
  }

  async play(options: { mediaUrl: string; mediaType: 'video' | 'playlist'; autostart?: boolean }): Promise<void> {
    if (!window.jwplayer) {
      throw new Error('JW Player script failed to load properly - jwplayer() function not found');
    }

    // Create fullscreen overlay div
    if (this.overlayDiv) {
      // Remove existing overlay if it exists
      document.body.removeChild(this.overlayDiv);
      this.overlayDiv = null;
    }

    // Create new overlay div (this will be our red background container)
    this.overlayDiv = document.createElement('div');

    // Style the outer overlay to take up 100% of screen
    Object.assign(this.overlayDiv.style, {
      position: 'fixed',
      top: '0',
      left: '0',
      width: '100%',
      height: '100%',
      zIndex: '9999',
      display: 'flex',
    });

    // Create the inner div for the player
    const playerDiv = document.createElement('div');
    const uniqueId = this.generateUUID();
    const id = `jw-player-${uniqueId}`;
    playerDiv.id = id;

    // Style the inner player div
    Object.assign(playerDiv.style, {
      width: '100%',
      height: '100%',
      margin: '0 auto',
    });

    // Create close (X) button
    const closeButton = document.createElement('button');
    closeButton.textContent = 'X';
    Object.assign(closeButton.style, {
      position: 'absolute',
      top: '10px',
      left: '10px',
      background: 'rgba(0, 0, 0, 0.5)',
      color: 'white',
      border: 'none',
      borderRadius: '50%',
      width: '30px',
      height: '30px',
      fontSize: '16px',
      fontWeight: 'bold',
      cursor: 'pointer',
      zIndex: '10000',
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      padding: '0',
    });

    // Add click handler to close button
    closeButton.addEventListener('click', () => {
      if (this.jwPlayerInstance) {
        this.jwPlayerInstance.remove();
        this.jwPlayerInstance = null;
      }
      if (this.overlayDiv?.parentNode) {
        document.body.removeChild(this.overlayDiv);
        this.overlayDiv = null;
        this.notifyListeners('playerDismissed', {});
      }
    });

    // Append inner div to the red overlay
    this.overlayDiv.appendChild(playerDiv);

    // Append close button to overlay
    this.overlayDiv.appendChild(closeButton);

    // Append outer div to body
    document.body.appendChild(this.overlayDiv);

    // Setup player on the inner div
    this.jwPlayerInstance = jwplayer(id).setup({
      playlist: options.mediaType === 'playlist' ? options.mediaUrl : [{ file: options.mediaUrl, title: 'Video' }],
      width: '100%',
      height: '100%',
      autostart: options.autostart || false,
      controls: true,
      displaytitle: false,
    });

    // Add unified event handlers to match iOS and Android
    this.setupEventHandlers();

    return;
  }

  // Setup unified event handlers to match iOS and Android
  private setupEventHandlers() {
    if (!this.jwPlayerInstance) return;

    // Ready event
    this.jwPlayerInstance.on('ready', () => {
      this.notifyListeners('ready', {});
    });

    // Error event
    this.jwPlayerInstance.on('error', (error: any) => {
      this.notifyListeners('error', {
        message: error?.message || 'Unknown error',
        code: error?.code || -1,
      });
    });

    // Play event
    this.jwPlayerInstance.on('play', () => {
      this.notifyListeners('play', { reason: 'external' });
    });

    // Pause event
    this.jwPlayerInstance.on('pause', () => {
      this.notifyListeners('pause', { reason: 'external' });
    });

    // Complete event
    this.jwPlayerInstance.on('complete', () => {
      this.notifyListeners('complete', {});
    });

    // Seek event
    this.jwPlayerInstance.on('seek', (event: { position: number; offset: number }) => {
      this.notifyListeners('seek', {
        position: event.position,
        offset: event.offset,
      });
    });

    // Time event (throttled to not fire too often)
    let lastTimeUpdate = 0;
    this.jwPlayerInstance.on('time', (event: { position: number; duration: number }) => {
      const now = Date.now();
      // Throttle to once per second max
      if (now - lastTimeUpdate > 1000) {
        this.notifyListeners('time', {
          position: event.position,
          duration: event.duration,
        });
        lastTimeUpdate = now;
      }
    });

    // Playlist item event
    this.jwPlayerInstance.on('playlistItem', (event: { index: number; item: any }) => {
      this.notifyListeners('playlistItem', {
        index: event.index,
        title: event.item?.title || '',
      });
    });

    // Playlist complete event
    this.jwPlayerInstance.on('playlistComplete', () => {
      this.notifyListeners('playlistComplete', {});
    });

    // Controls visibility event
    this.jwPlayerInstance.on('controls', (event: { controls: boolean }) => {
      this.notifyListeners('controlsChanged', {
        visible: event.controls,
      });
    });
  }

  async pause(): Promise<void> {
    if (this.jwPlayerInstance) {
      this.jwPlayerInstance.pause();
      // Event is fired by the event handler
      return;
    }
    throw new Error('Player not active');
  }

  async stop(): Promise<void> {
    if (this.jwPlayerInstance) {
      this.jwPlayerInstance.remove();
      this.jwPlayerInstance = null;

      if (this.overlayDiv?.parentNode) {
        document.body.removeChild(this.overlayDiv);
        this.overlayDiv = null;
      }

      // The complete event will be triggered by the JW Player event handler,
      // but since we're removing the player instance, we need to send it manually here
      this.notifyListeners('playerDismissed', {});
      return;
    }
    throw new Error('Player not active');
  }

  async seekTo(options: { time: number }): Promise<void> {
    if (this.jwPlayerInstance) {
      this.jwPlayerInstance.seek(options.time);
      return;
    }
    throw new Error('Player not active');
  }

  async setVolume(options: { volume: number }): Promise<void> {
    if (this.jwPlayerInstance) {
      this.jwPlayerInstance.setVolume(options.volume);
      return;
    }
    throw new Error('Player not active');
  }

  async getPosition(): Promise<{ position: number }> {
    if (this.jwPlayerInstance) {
      return { position: this.jwPlayerInstance.getPosition() };
    }
    throw new Error('Player not active');
  }

  async getState(): Promise<{ state: number }> {
    if (!this.jwPlayerInstance) {
      // IDLE (no player)
      return { state: 0 };
    }

    // Convert JW Player state to our state format
    // jwplayer: BUFFERING(3), IDLE(0), COMPLETE(4), PAUSED(2), PLAYING(1)
    // our API: IDLE(0), BUFFERING(1), PLAYING(2), PAUSED(3), COMPLETE(4)
    const jwState = this.jwPlayerInstance.getState();
    let state = 0;

    switch (jwState) {
      case 'buffering':
        state = 1;
        break;
      case 'playing':
        state = 2;
        break;
      case 'paused':
        state = 3;
        break;
      default:
        state = 0; // idle
    }

    return { state };
  }

  async setSpeed(options: { speed: number }): Promise<void> {
    if (this.jwPlayerInstance) {
      this.jwPlayerInstance.setPlaybackRate(options.speed);
      return;
    }
    throw new Error('Player not active');
  }

  async setPlaylistIndex(options: { index: number }): Promise<void> {
    if (this.jwPlayerInstance) {
      this.jwPlayerInstance.playlistItem(options.index);
      return;
    }
    throw new Error('Player not active');
  }

  async loadPlaylist(options: { playlistUrl: string }): Promise<void> {
    if (this.jwPlayerInstance) {
      this.jwPlayerInstance.load(options.playlistUrl);
      return;
    }
    throw new Error('Player not active');
  }

  async loadPlaylistWithItems(options: { playlist: any[] }): Promise<void> {
    if (this.jwPlayerInstance) {
      this.jwPlayerInstance.load(options.playlist);
      return;
    }
    throw new Error('Player not active');
  }

  async getAudioTracks(): Promise<{ tracks: any[] }> {
    if (this.jwPlayerInstance) {
      const tracks = this.jwPlayerInstance.getAudioTracks();
      return { tracks };
    }
    throw new Error('Player not active');
  }

  async getCurrentAudioTrack(): Promise<{ index: number }> {
    if (this.jwPlayerInstance) {
      const index = this.jwPlayerInstance.getCurrentAudioTrack();
      return { index };
    }
    throw new Error('Player not active');
  }

  async setCurrentAudioTrack(options: { index: number }): Promise<void> {
    if (this.jwPlayerInstance) {
      this.jwPlayerInstance.setCurrentAudioTrack(options.index);
      return;
    }
    throw new Error('Player not active');
  }

  async getCaptions(): Promise<{ captions: any[] }> {
    if (this.jwPlayerInstance) {
      const captions = this.jwPlayerInstance.getCaptionsList();
      return { captions };
    }
    throw new Error('Player not active');
  }

  async getCurrentCaptions(): Promise<{ index: number }> {
    if (this.jwPlayerInstance) {
      const index = this.jwPlayerInstance.getCurrentCaptions();
      return { index };
    }
    throw new Error('Player not active');
  }

  async setCurrentCaptions(options: { index: number }): Promise<void> {
    if (this.jwPlayerInstance) {
      this.jwPlayerInstance.setCurrentCaptions(options.index);
      return;
    }
    throw new Error('Player not active');
  }

  async currentPlaylist(): Promise<any> {
    if (this.jwPlayerInstance) {
      return this.jwPlayerInstance.getPlaylist();
    }
    throw new Error('Player not active');
  }

  async resume(): Promise<void> {
    if (this.jwPlayerInstance) {
      this.jwPlayerInstance.play();
      // Event is fired by the event handler
      return;
    }
    throw new Error('Player not active');
  }

  async getPluginVersion(): Promise<{ version: string }> {
    return { version: 'web' };
  }
}
