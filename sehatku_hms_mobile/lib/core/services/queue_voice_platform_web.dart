import 'dart:js_interop';

@JS('playHospitalChimeAndSpeak')
external void _playHospitalChimeAndSpeak(JSString text);

void playHospitalChimeAndSpeak(String text) {
  _playHospitalChimeAndSpeak(text.toJS);
}
