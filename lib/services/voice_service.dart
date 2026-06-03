import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum VoiceState { idle, listening, error, notAvailable }

class VoiceService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  VoiceState _state = VoiceState.idle;
  String _recognizedText = '';
  bool _isAvailable = false;

  VoiceState get state => _state;
  String get recognizedText => _recognizedText;
  bool get isListening => _state == VoiceState.listening;
  bool get isAvailable => _isAvailable;

  Future<bool> initialize() async {
    _isAvailable = await _speech.initialize(
      onError: (error) {
        _state = VoiceState.error;
        notifyListeners();
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _stopListening();
        }
      },
    );
    _state = _isAvailable ? VoiceState.idle : VoiceState.notAvailable;
    notifyListeners();
    return _isAvailable;
  }

  void startListening() {
    if (!_isAvailable) return;
    _recognizedText = '';
    _state = VoiceState.listening;
    notifyListeners();

    _speech.listen(
      onResult: (result) {
        _recognizedText = result.recognizedWords;
        notifyListeners();
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: 'es_PE',
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  void _stopListening() {
    _state = VoiceState.idle;
    notifyListeners();
  }

  void stop() {
    _speech.stop();
    _stopListening();
  }

  void cancel() {
    _speech.cancel();
    _recognizedText = '';
    _stopListening();
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
