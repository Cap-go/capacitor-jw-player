import { registerPlugin } from '@capacitor/core';

import type { JwPlayerPlugin } from './definitions';

const JwPlayer = registerPlugin<JwPlayerPlugin>('JwPlayer', {
  web: () => import('./web').then((m) => new m.JwPlayerWeb()),
});

export * from './definitions';
export { JwPlayer };
