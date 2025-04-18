# @capgo/capacitor-jw-player

Playes videos from jwplayer.com

## Install

```bash
npm install @capgo/capacitor-jw-player
npx cap sync
```

## API

<docgen-index>

* [`initialize(...)`](#initialize)
* [`play(...)`](#play)
* [`load(...)`](#load)
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


### load(...)

```typescript
load(options: { mediaUrl: string; mediaType: 'video' | 'playlist'; }) => Promise<void>
```

Load a video

| Param         | Type                                                                 | Description                     |
| ------------- | -------------------------------------------------------------------- | ------------------------------- |
| **`options`** | <code>{ mediaUrl: string; mediaType: 'video' \| 'playlist'; }</code> | - The options for the JW Player |

--------------------


### currentPlaylist()

```typescript
currentPlaylist() => Promise<any>
```

Get the current playlist

**Returns:** <code>Promise&lt;any&gt;</code>

--------------------

</docgen-api>
