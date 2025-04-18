import { WebPlugin } from '@capacitor/core';

import type { JwPlayerPlugin } from './definitions';

export class JwPlayerWeb extends WebPlugin implements JwPlayerPlugin {
  async play(_options: { mediaUrl: string; mediaType: 'video' | 'playlist'; }): Promise<void> {
    throw new Error('Method not implemented.');
  }
  async load(_options: { mediaUrl: string; mediaType: 'video' | 'playlist'; }): Promise<void> {
    throw new Error('Method not implemented.');
  }
  async currentPlaylist(): Promise<any> {
    throw new Error('Method not implemented.');
  }
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
  async initialize(options: { licenseKey: string }): Promise<void> {
    console.log('INITIALIZE', options);
    return;
  }
}
