import { JwPlayer } from '@capgo/capacitor-jw-player';
import { Capacitor } from '@capacitor/core';

// For displaying results
const showResult = (title, data) => {
    const resultDisplay = document.getElementById('resultDisplay');
    if (resultDisplay) {
        resultDisplay.innerHTML = `<strong>${title}</strong><br>${typeof data === 'object' ? JSON.stringify(data, null, 2) : data}`;
    }
    console.log(title, data);
};

document.addEventListener('DOMContentLoaded', async () => {
    try {
        console.log('Initializing JW Player');
        const platform = Capacitor.getPlatform();
        if (platform === 'ios') {
            await JwPlayer.initialize({
                licenseKey: 'w2xXw2vXW4z4Os0+QDom4xTYUL/KH3pQ2q9EvhacSbYLq8FV'
            });
        } else {
            await JwPlayer.initialize({
                licenseKey: 'YOUR_LICENSE_KEY_HERE'
            });
        }
        
        // Set up event listeners
        setupEventListeners();
        
        // Listen for player events
        setupPlayerEventListeners();
        
        showResult('JW Player initialized successfully', '');
    } catch (error) {
        console.error('Failed to initialize JW Player:', error);
        showResult('Error initializing JW Player', error.message);
    }
});

// Setup event listeners for all UI controls
function setupEventListeners() {
    // Video playback buttons
    document.getElementById('playVideo1')?.addEventListener('click', () => playVideo('7mjctscM'));
    document.getElementById('playVideo2')?.addEventListener('click', () => playVideo('eRJJMuHN'));
    document.getElementById('playVideo3')?.addEventListener('click', () => playVideo('GSOQLcQ0'));
    
    // Playlist buttons
    document.getElementById('playPlaylist1')?.addEventListener('click', () => playPlaylist('NHYc9BBh'));
    document.getElementById('playPlaylist2')?.addEventListener('click', () => playPlaylist('YJ684zZI'));
    document.getElementById('playPlaylist3')?.addEventListener('click', () => playPlaylist('XUqlflYa'));
    
    // Player ID buttons
    document.getElementById('playPlayer1')?.addEventListener('click', () => playPlayer('hxwoJbII'));
    document.getElementById('playPlayer2')?.addEventListener('click', () => playPlayer('YVExfHuG'));
    
    // Playback controls
    document.getElementById('pauseButton')?.addEventListener('click', pausePlayback);
    document.getElementById('resumeButton')?.addEventListener('click', resumePlayback);
    document.getElementById('stopButton')?.addEventListener('click', stopPlayback);
    document.getElementById('seekButton')?.addEventListener('click', seekToPosition);
    document.getElementById('setVolumeButton')?.addEventListener('click', setVolume);
    document.getElementById('setSpeedButton')?.addEventListener('click', setPlaybackSpeed);
    
    // Playlist controls
    document.getElementById('setPlaylistIndexButton')?.addEventListener('click', setPlaylistIndex);
    document.getElementById('getPlaylistButton')?.addEventListener('click', getCurrentPlaylist);
    
    // Audio track controls
    document.getElementById('getAudioTracksButton')?.addEventListener('click', getAudioTracks);
    document.getElementById('getCurrentAudioTrackButton')?.addEventListener('click', getCurrentAudioTrack);
    document.getElementById('setAudioTrackButton')?.addEventListener('click', setCurrentAudioTrack);
    
    // Caption controls
    document.getElementById('getCaptionsButton')?.addEventListener('click', getCaptions);
    document.getElementById('getCurrentCaptionsButton')?.addEventListener('click', getCurrentCaptions);
    document.getElementById('setCaptionButton')?.addEventListener('click', setCurrentCaptions);
    
    // Player information
    document.getElementById('getPositionButton')?.addEventListener('click', getPosition);
    document.getElementById('getStateButton')?.addEventListener('click', getState);
}

// Set up JW Player event listeners
function setupPlayerEventListeners() {
    JwPlayer.addListener('ready', () => {
        showResult('Player Event', 'Player is ready');
    });
    
    JwPlayer.addListener('play', () => {
        showResult('Player Event', 'Playback started');
    });
    
    JwPlayer.addListener('pause', (data) => {
        showResult('Player Event', `Playback paused. Reason: ${data.reason}`);
    });
    
    JwPlayer.addListener('complete', () => {
        showResult('Player Event', 'Playback completed');
    });
    
    JwPlayer.addListener('time', (data) => {
        // We don't want to flood the UI with time updates
        console.log(`Position: ${data.position}, Duration: ${data.duration}`);
    });
    
    JwPlayer.addListener('error', (data) => {
        showResult('Player Error', data.message || 'Unknown error');
    });
    
    JwPlayer.addListener('playerDismissed', () => {
        showResult('Player Event', 'Player dismissed');
    });
}

// Play a video by Media ID
async function playVideo(mediaId) {
    try {
        showResult('Playing Video', `Media ID: ${mediaId}`);
        await JwPlayer.play({
            mediaUrl: `https://cdn.jwplayer.com/manifests/${mediaId}.m3u8`,
            mediaType: 'video'
        });
    } catch (error) {
        showResult('Error Playing Video', error.message);
    }
}

// Play a playlist by ID
async function playPlaylist(playlistId) {
    try {
        showResult('Playing Playlist', `Playlist ID: ${playlistId}`);
        await JwPlayer.play({
            mediaUrl: `https://cdn.jwplayer.com/v2/playlists/${playlistId}`,
            mediaType: 'playlist'
        });
    } catch (error) {
        showResult('Error Playing Playlist', error.message);
    }
}

// Play by Player ID
async function playPlayer(playerId) {
    try {
        showResult('Playing Player', `Player ID: ${playerId}`);
        await JwPlayer.play({
            mediaUrl: `https://cdn.jwplayer.com/v2/media/${playerId}`,
            mediaType: 'playlist'
        });
    } catch (error) {
        showResult('Error Playing Player', error.message);
    }
}

// Pause playback
async function pausePlayback() {
    try {
        await JwPlayer.pause();
        showResult('Playback Control', 'Playback paused');
    } catch (error) {
        showResult('Error Pausing', error.message);
    }
}

// Resume playback
async function resumePlayback() {
    try {
        // For resuming, we don't need to provide a URL
        await JwPlayer.play();
        showResult('Playback Control', 'Playback resumed');
    } catch (error) {
        showResult('Error Resuming', error.message);
    }
}

// Stop playback
async function stopPlayback() {
    try {
        await JwPlayer.stop();
        showResult('Playback Control', 'Playback stopped');
    } catch (error) {
        showResult('Error Stopping', error.message);
    }
}

// Seek to position
async function seekToPosition() {
    try {
        const seekTime = parseFloat(document.getElementById('seekInput').value) || 0;
        await JwPlayer.seekTo({ time: seekTime });
        showResult('Playback Control', `Seeked to ${seekTime} seconds`);
    } catch (error) {
        showResult('Error Seeking', error.message);
    }
}

// Set volume
async function setVolume() {
    try {
        const volumeLevel = parseInt(document.getElementById('volumeInput').value) / 100;
        await JwPlayer.setVolume({ volume: volumeLevel });
        showResult('Playback Control', `Volume set to ${volumeLevel * 100}%`);
    } catch (error) {
        showResult('Error Setting Volume', error.message);
    }
}

// Set playback speed
async function setPlaybackSpeed() {
    try {
        const speed = parseFloat(document.getElementById('speedSelect').value);
        await JwPlayer.setSpeed({ speed });
        showResult('Playback Control', `Playback speed set to ${speed}x`);
    } catch (error) {
        showResult('Error Setting Speed', error.message);
    }
}

// Set playlist index
async function setPlaylistIndex() {
    try {
        const index = parseInt(document.getElementById('playlistIndexInput').value) || 0;
        await JwPlayer.setPlaylistIndex({ index });
        showResult('Playlist Control', `Switched to item at index ${index}`);
    } catch (error) {
        showResult('Error Setting Playlist Index', error.message);
    }
}

// Get current playlist
async function getCurrentPlaylist() {
    try {
        const playlist = await JwPlayer.currentPlaylist();
        showResult('Playlist Information', playlist);
    } catch (error) {
        showResult('Error Getting Playlist', error.message);
    }
}

// Get audio tracks
async function getAudioTracks() {
    try {
        const result = await JwPlayer.getAudioTracks();
        showResult('Audio Tracks', result);
    } catch (error) {
        showResult('Error Getting Audio Tracks', error.message);
    }
}

// Get current audio track
async function getCurrentAudioTrack() {
    try {
        const result = await JwPlayer.getCurrentAudioTrack();
        showResult('Current Audio Track', result);
    } catch (error) {
        showResult('Error Getting Current Audio Track', error.message);
    }
}

// Set current audio track
async function setCurrentAudioTrack() {
    try {
        const index = parseInt(document.getElementById('audioTrackIndexInput').value) || 0;
        await JwPlayer.setCurrentAudioTrack({ index });
        showResult('Audio Track Control', `Set audio track to index ${index}`);
    } catch (error) {
        showResult('Error Setting Audio Track', error.message);
    }
}

// Get captions
async function getCaptions() {
    try {
        const result = await JwPlayer.getCaptions();
        showResult('Captions', result);
    } catch (error) {
        showResult('Error Getting Captions', error.message);
    }
}

// Get current captions
async function getCurrentCaptions() {
    try {
        const result = await JwPlayer.getCurrentCaptions();
        showResult('Current Caption', result);
    } catch (error) {
        showResult('Error Getting Current Captions', error.message);
    }
}

// Set current captions
async function setCurrentCaptions() {
    try {
        const index = parseInt(document.getElementById('captionIndexInput').value) || 0;
        await JwPlayer.setCurrentCaptions({ index });
        showResult('Caption Control', `Set caption track to index ${index}`);
    } catch (error) {
        showResult('Error Setting Caption Track', error.message);
    }
}

// Get current position
async function getPosition() {
    try {
        const result = await JwPlayer.getPosition();
        showResult('Player Position', `Current position: ${result.position} seconds`);
    } catch (error) {
        showResult('Error Getting Position', error.message);
    }
}

// Get player state
async function getState() {
    try {
        const result = await JwPlayer.getState();
        // Convert the state number to a more readable format
        const stateMap = {
            0: 'IDLE',
            1: 'BUFFERING',
            2: 'PLAYING',
            3: 'PAUSED',
            4: 'COMPLETE'
        };
        const stateName = stateMap[result.state] || `Unknown (${result.state})`;
        showResult('Player State', `Current state: ${stateName}`);
    } catch (error) {
        showResult('Error Getting State', error.message);
    }
}

