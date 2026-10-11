// DroidEye ships without voice control for now. The voice code stays in place
// (other features reuse its command runner); this only hides its controls.

const VOICE_TIP = /GEV MIC|talk to the map/i;

export function disableVoiceUi() {
  document.body.classList.add('droideye-no-voice');
  for (const note of document.querySelectorAll('.first-run-note')) {
    if (VOICE_TIP.test(note.textContent)) note.textContent = '';
  }
}
