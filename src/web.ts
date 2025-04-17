import { WebPlugin } from '@capacitor/core';

import type { JwPlayerPlugin } from './definitions';

export class JwPlayerWeb extends WebPlugin implements JwPlayerPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
