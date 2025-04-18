import { JwPlayer } from '@capgo/capacitor-jw-player';
import { Capacitor } from '@capacitor/core';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    JwPlayer.echo({ value: inputValue })
}

document.addEventListener('DOMContentLoaded', async () => {
    try {
        console.log('Initializing JW Player');
        const platform = Capacitor.getPlatform();
        if (platform === 'ios') {
            await JwPlayer.initialize({
                licenseKey: ''
            });
        } else {
            await JwPlayer.initialize({
                licenseKey: 'YOUR_LICENSE_KEY_HERE'
            });
        }
        
        // Add event listeners for the buttons
        const playVideoButton = document.getElementById('playVideoButton');
        const playPlaylistButton = document.getElementById('playPlaylistButton');
        
        if (playVideoButton) {
            playVideoButton.addEventListener('click', playJwVideo);
        }
        
        if (playPlaylistButton) {
            playPlaylistButton.addEventListener('click', playJwPlaylist);
        }
    } catch (error) {
        console.error('Failed to initialize JW Player:', error);
    }
});

// Function to play a JW Player playlist
async function playJwPlaylist() {
    try {
        console.log('Playing playlist from JW Player');
        await JwPlayer.play({
            mediaUrl: 'https://cdn.jwplayer.com/v2/playlists/YI6hVldO',
            mediaType: 'playlist'
        });
    } catch (error) {
        console.error('Failed to play playlist:', error);
        alert('Error playing playlist: ' + error.message);
    }
}

// Function to play the JW Player video
async function playJwVideo() {
    try {
        console.log('Playing video from JW Player');
        await JwPlayer.play({
            mediaUrl: 'https://cdn.jwplayer.com/manifests/pbQRWilr.m3u8',
            mediaType: 'video'
        });
    } catch (error) {
        console.error('Failed to play video:', error);
        alert('Error playing video: ' + error.message);
    }
}

