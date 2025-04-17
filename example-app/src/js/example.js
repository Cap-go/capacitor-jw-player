import { JwPlayer } from '@capgo/capacitor-jw-player';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    JwPlayer.echo({ value: inputValue })
}
