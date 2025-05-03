# @capgo/capacitor-jw-player
 <a href="https://capgo.app/"><img src='https://raw.githubusercontent.com/Cap-go/capgo/main/assets/capgo_banner.png' alt='Capgo - Instant updates for capacitor'/></a>

<div align="center">
  <h2><a href="https://capgo.app/?ref=plugin"> ➡️ Get Instant updates for your App with Capgo 🚀</a></h2>
  <h2><a href="https://capgo.app/consulting/?ref=plugin"> Fix your annoying bug now, Hire a Capacitor expert 💪</a></h2>
</div>

WIP: do not use it yet it's in dev

Play videos from jwplayer.com with a fullscreen player interface. The plugin provides a comprehensive API for controlling JW Player playback, playlists, and tracks.

## Key Features

- Always fullscreen player
- Supports both single videos and playlists
- Complete control over playback (play, pause, seek, etc.)
- Audio track selection
- Caption/subtitle support
- Event listeners for player state changes
Playes videos from jwplayer.com

## Install

```bash
npm install @capgo/capacitor-jw-player
npx cap sync
```

## Android

Edit `build.gradle` in order for the plugin to work:
```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url 'https://mvn.jwplayer.com/content/repositories/releases/'
        }
    }
}
```

## Usage Examples

### Basic Setup and Playback

```typescript
import { JwPlayer } from '@capgo/capacitor-jw-player';

// Initialize the player with your license key
await JwPlayer.initialize({ 
  licenseKey: 'YOUR_JW_PLAYER_LICENSE_KEY' 
});

// Play a video
await JwPlayer.play({
  mediaUrl: 'https://example.com/video.mp4',
  mediaType: 'video' 
});

// Play a playlist
await JwPlayer.play({
  mediaUrl: 'https://cdn.jwplayer.com/v2/playlists/PLAYLIST_ID',
  mediaType: 'playlist'
});
```

### Playback Controls

```typescript
// Pause playback
await JwPlayer.pause();

// Resume playback
// Note: No need to call play() again with the URL, it resumes current content
await JwPlayer.play();

// Seek to a specific position (in seconds)
await JwPlayer.seekTo({ time: 30 });

// Set volume (0.0 to 1.0)
await JwPlayer.setVolume({ volume: 0.5 });

// Change playback speed
await JwPlayer.setSpeed({ speed: 1.5 });

// Stop and release the player
await JwPlayer.stop();
```

### Working with Playlists

```typescript
// Load a playlist by URL
await JwPlayer.loadPlaylist({ 
  playlistUrl: 'https://cdn.jwplayer.com/v2/playlists/PLAYLIST_ID' 
});

// Load a playlist with custom items
await JwPlayer.loadPlaylistWithItems({
  playlist: [
    { file: 'https://example.com/video1.mp4', title: 'Video 1' },
    { file: 'https://example.com/video2.mp4', title: 'Video 2' }
  ]
});

// Jump to a specific item in the playlist
await JwPlayer.setPlaylistIndex({ index: 2 });

// Get information about the current playlist
const playlistInfo = await JwPlayer.currentPlaylist();
console.log(playlistInfo.playlist);
```

### Audio and Caption Tracks

```typescript
// Get available audio tracks
const { tracks } = await JwPlayer.getAudioTracks();
console.log('Available audio tracks:', tracks);

// Get current audio track
const { index } = await JwPlayer.getCurrentAudioTrack();
console.log('Current audio track index:', index);

// Set audio track
await JwPlayer.setCurrentAudioTrack({ index: 1 });

// Get available captions
const { captions } = await JwPlayer.getCaptions();
console.log('Available captions:', captions);

// Set captions track (0 is usually "Off")
await JwPlayer.setCurrentCaptions({ index: 1 });
```

### Event Listeners

```typescript
import { JwPlayer } from '@capgo/capacitor-jw-player';

// Listen for player ready event
JwPlayer.addListener('ready', () => {
  console.log('Player is ready');
});

// Listen for playback state changes
JwPlayer.addListener('play', () => {
  console.log('Playback started');
});

JwPlayer.addListener('pause', (data) => {
  console.log('Playback paused, reason:', data.reason);
});

JwPlayer.addListener('complete', () => {
  console.log('Playback completed');
});

// Listen for time updates
JwPlayer.addListener('time', (data) => {
  console.log(`Position: ${data.position}, Duration: ${data.duration}`);
});

// Listen for playlist changes
JwPlayer.addListener('playlist', (data) => {
  console.log(`Playlist loaded with ${data.playlistSize} items`);
});

JwPlayer.addListener('playlistItem', (data) => {
  console.log(`Now playing item at index ${data.index}`);
});

// Listen for errors
JwPlayer.addListener('error', (data) => {
  console.error('Player error:', data.message);
});

// Clean up listeners when done
function cleanup() {
  JwPlayer.removeAllListeners();
}
```

## API

<docgen-index>

* [`initialize(...)`](#initialize)
* [`play(...)`](#play)
* [`pause()`](#pause)
* [`resume()`](#resume)
* [`stop()`](#stop)
* [`seekTo(...)`](#seekto)
* [`setVolume(...)`](#setvolume)
* [`getPosition()`](#getposition)
* [`getState()`](#getstate)
* [`setSpeed(...)`](#setspeed)
* [`setPlaylistIndex(...)`](#setplaylistindex)
* [`loadPlaylist(...)`](#loadplaylist)
* [`loadPlaylistWithItems(...)`](#loadplaylistwithitems)
* [`getAudioTracks()`](#getaudiotracks)
* [`getCurrentAudioTrack()`](#getcurrentaudiotrack)
* [`setCurrentAudioTrack(...)`](#setcurrentaudiotrack)
* [`getCaptions()`](#getcaptions)
* [`getCurrentCaptions()`](#getcurrentcaptions)
* [`setCurrentCaptions(...)`](#setcurrentcaptions)
* [`currentPlaylist()`](#currentplaylist)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### initialize(...)

```typescript
initialize(options: { licenseKey: string; }) => Promise<void>
```

Initialize the JW Player

| Param         | Type                                 | Description                     |
| ------------- | ------------------------------------ | ------------------------------- |
| **`options`** | <code>{ licenseKey: string; }</code> | - The options for the JW Player |

--------------------


### play(...)

```typescript
play(options: { mediaUrl: string; mediaType: 'video' | 'playlist'; }) => Promise<void>
```

Play a video

| Param         | Type                                                                 | Description                     |
| ------------- | -------------------------------------------------------------------- | ------------------------------- |
| **`options`** | <code>{ mediaUrl: string; mediaType: 'video' \| 'playlist'; }</code> | - The options for the JW Player |

--------------------


### pause()

```typescript
pause() => Promise<void>
```

Pause the currently playing media

--------------------


### resume()

```typescript
resume() => Promise<void>
```

Resume the currently paused media

--------------------


### stop()

```typescript
stop() => Promise<void>
```

Stop the currently playing media

--------------------


### seekTo(...)

```typescript
seekTo(options: { time: number; }) => Promise<void>
```

Seek to a specific position in the currently playing media

| Param         | Type                           | Description           |
| ------------- | ------------------------------ | --------------------- |
| **`options`** | <code>{ time: number; }</code> | - Options for seeking |

--------------------


### setVolume(...)

```typescript
setVolume(options: { volume: number; }) => Promise<void>
```

Set the volume level

| Param         | Type                             | Description                  |
| ------------- | -------------------------------- | ---------------------------- |
| **`options`** | <code>{ volume: number; }</code> | - Options for setting volume |

--------------------


### getPosition()

```typescript
getPosition() => Promise<{ position: number; }>
```

Get the current position in the media

**Returns:** <code>Promise&lt;{ position: number; }&gt;</code>

--------------------


### getState()

```typescript
getState() => Promise<{ state: number; }>
```

Get the current player state

**Returns:** <code>Promise&lt;{ state: number; }&gt;</code>

--------------------


### setSpeed(...)

```typescript
setSpeed(options: { speed: number; }) => Promise<void>
```

Set the playback speed

| Param         | Type                            | Description                 |
| ------------- | ------------------------------- | --------------------------- |
| **`options`** | <code>{ speed: number; }</code> | - Options for setting speed |

--------------------


### setPlaylistIndex(...)

```typescript
setPlaylistIndex(options: { index: number; }) => Promise<void>
```

Set the current item in the playlist by index

| Param         | Type                            | Description                         |
| ------------- | ------------------------------- | ----------------------------------- |
| **`options`** | <code>{ index: number; }</code> | - Options for setting playlist item |

--------------------


### loadPlaylist(...)

```typescript
loadPlaylist(options: { playlistUrl: string; }) => Promise<void>
```

Load a playlist

| Param         | Type                                  | Description                      |
| ------------- | ------------------------------------- | -------------------------------- |
| **`options`** | <code>{ playlistUrl: string; }</code> | - Options for loading a playlist |

--------------------


### loadPlaylistWithItems(...)

```typescript
loadPlaylistWithItems(options: { playlist: any[]; }) => Promise<void>
```

Load a playlist with items

| Param         | Type                              | Description                      |
| ------------- | --------------------------------- | -------------------------------- |
| **`options`** | <code>{ playlist: any[]; }</code> | - Options for loading a playlist |

--------------------


### getAudioTracks()

```typescript
getAudioTracks() => Promise<{ tracks: any[]; }>
```

Get available audio tracks

**Returns:** <code>Promise&lt;{ tracks: any[]; }&gt;</code>

--------------------


### getCurrentAudioTrack()

```typescript
getCurrentAudioTrack() => Promise<{ index: number; }>
```

Get the current audio track

**Returns:** <code>Promise&lt;{ index: number; }&gt;</code>

--------------------


### setCurrentAudioTrack(...)

```typescript
setCurrentAudioTrack(options: { index: number; }) => Promise<void>
```

Set the current audio track

| Param         | Type                            | Description                       |
| ------------- | ------------------------------- | --------------------------------- |
| **`options`** | <code>{ index: number; }</code> | - Options for setting audio track |

--------------------


### getCaptions()

```typescript
getCaptions() => Promise<{ captions: any[]; }>
```

Get the available captions/subtitles

**Returns:** <code>Promise&lt;{ captions: any[]; }&gt;</code>

--------------------


### getCurrentCaptions()

```typescript
getCurrentCaptions() => Promise<{ index: number; }>
```

Get the current captions/subtitles track

**Returns:** <code>Promise&lt;{ index: number; }&gt;</code>

--------------------


### setCurrentCaptions(...)

```typescript
setCurrentCaptions(options: { index: number; }) => Promise<void>
```

Set the current captions/subtitles track

| Param         | Type                            | Description                          |
| ------------- | ------------------------------- | ------------------------------------ |
| **`options`** | <code>{ index: number; }</code> | - Options for setting captions track |

--------------------


### currentPlaylist()

```typescript
currentPlaylist() => Promise<any>
```

Get the current playlist

**Returns:** <code>Promise&lt;any&gt;</code>

--------------------

</docgen-api>

## Event Listeners

The plugin emits the following events that you can listen for:

| Event | Description | Data |
| ----- | ----------- | ---- |
| `ready` | Player is ready to use | None |
| `play` | Playback has started | None |
| `pause` | Playback is paused | `{ reason: number }` |
| `complete` | Playback of the current item is complete | None |
| `time` | Playback time has updated | `{ position: number, duration: number }` |
| `setupError` | Error during setup | `{ code: number, message: string }` |
| `error` | General playback error | `{ code: number, message: string }` |
| `warning` | Player warning | `{ code: number, message: string }` |
| `playlist` | Playlist has been loaded | `{ playlistSize: number }` |
| `playlistItem` | Current playlist item has changed | `{ index: number, file: string, title: string }` |
| `playerDismissed` | Player has been closed/dismissed | None |
