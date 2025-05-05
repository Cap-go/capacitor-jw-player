import { WebPlugin } from '@capacitor/core';

import type { JwPlayerPlugin } from './definitions';

export class JwPlayerWeb extends WebPlugin implements JwPlayerPlugin {
  async initialize(options: { licenseKey: string }): Promise<void> {
    console.log('INITIALIZE', options);
    return;
  }

  async play(_options: { mediaUrl: string; mediaType: 'video' | 'playlist' }): Promise<void> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async pause(): Promise<void> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async stop(): Promise<void> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async seekTo(_options: { time: number }): Promise<void> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async setVolume(_options: { volume: number }): Promise<void> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async getPosition(): Promise<{ position: number }> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async getState(): Promise<{ state: number }> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async setSpeed(_options: { speed: number }): Promise<void> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async setPlaylistIndex(_options: { index: number }): Promise<void> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async loadPlaylist(_options: { playlistUrl: string }): Promise<void> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async loadPlaylistWithItems(_options: { playlist: any[] }): Promise<void> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async getAudioTracks(): Promise<{ tracks: any[] }> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async getCurrentAudioTrack(): Promise<{ index: number }> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async setCurrentAudioTrack(_options: { index: number }): Promise<void> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async getCaptions(): Promise<{ captions: any[] }> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async getCurrentCaptions(): Promise<{ index: number }> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async setCurrentCaptions(_options: { index: number }): Promise<void> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async currentPlaylist(): Promise<any> {
    throw this.unimplemented('JW Player is not available in web.');
  }

  async resume(): Promise<void> {
    throw this.unimplemented('JW Player is not available in web.');
  }
}
