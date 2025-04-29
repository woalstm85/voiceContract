import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:google_speech/google_speech.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum RecordingStatus {
  idle,
  listening,
  processing,
  success,
  error,
}

class VoiceRecognitionService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  SpeechToText? _speechToText;
  RecordingStatus _recordingStatus = RecordingStatus.idle;
  bool _isRecording = false;
  bool _stoppedDueToSilence = false;
  bool _hasSpeechStarted = false;
  int _totalSilenceAfterSpeech = 0;
  Timer? _silenceTimer;

  // 콜백 함수 정의
  final List<Function(RecordingStatus)> _statusListeners = [];
  final List<Function(String)> _textListeners = [];

  bool get isRecording => _isRecording;
  RecordingStatus get status => _recordingStatus;

  // 리스너 등록 메서드
  void addStatusListener(Function(RecordingStatus) listener) {
    _statusListeners.add(listener);
  }

  void addRecognizedTextListener(Function(String) listener) {
    _textListeners.add(listener);
  }

  // 상태 변경 메서드 (모든 리스너에게 알림)
  void _notifyStatusChange(RecordingStatus status) {
    _recordingStatus = status;
    for (var listener in _statusListeners) {
      listener(status);
    }
  }

  // 인식된 텍스트 변경 메서드
  void _notifyTextChange(String text) {
    for (var listener in _textListeners) {
      listener(text);
    }
  }

  // 초기화
  Future<void> init() async {
    await _initSpeechToText();
  }

  Future<void> _initSpeechToText() async {
    final String jsonString = await rootBundle.loadString('assets/voice_service_account.json');
    final serviceAccount = ServiceAccount.fromString(jsonString);
    _speechToText = SpeechToText.viaServiceAccount(serviceAccount);
  }

  // 녹음 시작
  Future<void> startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final audioPath = await _getAudioFilePath();

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            bitRate: 16000,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: audioPath,
        );

        _isRecording = true;
        _hasSpeechStarted = false;
        _totalSilenceAfterSpeech = 0;
        _stoppedDueToSilence = false;
        _notifyStatusChange(RecordingStatus.listening);
        _notifyTextChange('음성인식중...');

        // 무음 모니터링 시작
        _monitorRecording();
      }
    } catch (e) {
      _notifyStatusChange(RecordingStatus.error);
      _notifyTextChange('녹음 시작 오류: $e');
    }
  }

  // 녹음 중지
  Future<void> stopRecording() async {
    try {
      _isRecording = false;

      final path = await _audioRecorder.stop();

      if (path == null) {
        print("오류: 녹음 파일이 생성되지 않음");
        return;
      }

      if (_stoppedDueToSilence) {
        // 무음 감지로 인해 녹음 중지된 경우
        _notifyStatusChange(RecordingStatus.idle);
        _notifyTextChange(''); // 텍스트 필드 초기화

        // 플래그 초기화
        _stoppedDueToSilence = false;
        return; // 이후 처리 중단
      }

      // 정상적인 녹음 중지인 경우 파일 처리
      await _processAudio(File(path));
    } catch (e) {
      print("녹음 중지 오류: $e");
      _isRecording = false;
      _notifyStatusChange(RecordingStatus.error);
      _notifyTextChange('녹음 중지 오류 발생');
    }
  }

  // 무음 모니터링
  void _monitorRecording() {
    int silentCount = 0;
    const double silenceThreshold = -25.0;
    const int maxSilenceBeforeSpeech = 3;
    const int maxSilenceAfterSpeech = 3;

    _silenceTimer?.cancel(); // 기존 타이머가 있다면 취소
    _silenceTimer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      try {
        Amplitude? amplitudeData = await _audioRecorder.getAmplitude();
        double amplitude = amplitudeData?.current ?? 0.0;

        print('현재 소리 크기: $amplitude');

        if (amplitude > silenceThreshold) {
          silentCount = 0; // 무음 카운터 초기화
          if (!_hasSpeechStarted) {
            _hasSpeechStarted = true;
            print('말하기 시작 감지');
          }
        } else {
          silentCount++;
          print('무음 감지: ${silentCount * 0.5}초');

          if (_hasSpeechStarted) {
            _totalSilenceAfterSpeech = silentCount;
            if (_totalSilenceAfterSpeech >= maxSilenceAfterSpeech * 2) {
              print('말한 후 ${maxSilenceAfterSpeech}초 무음 감지. 음성 처리를 시작합니다.');
              timer.cancel();
              _silenceTimer = null; // 타이머 해제
              _stoppedDueToSilence = false;
              await stopRecording();
            }
          } else {
            if (silentCount >= maxSilenceBeforeSpeech * 2) {
              print('${maxSilenceBeforeSpeech}초 동안 소리가 감지되지 않아 자동 중지합니다.');
              timer.cancel();
              _silenceTimer = null;
              _stoppedDueToSilence = true;
              await stopRecording();
            }
          }
        }
      } catch (e) {
        print('볼륨 모니터링 오류: $e');
      }
    });
  }

  // 오디오 파일 경로 생성
  Future<String> _getAudioFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/audio_$timestamp.wav';
  }

  // 오디오 처리 및 음성 인식
  Future<void> _processAudio(File audioFile) async {
    _notifyStatusChange(RecordingStatus.processing);

    try {
      final audio = await audioFile.readAsBytes();

      final config = RecognitionConfig(
        encoding: AudioEncoding.LINEAR16,
        model: RecognitionModel.basic,
        enableAutomaticPunctuation: false,
        sampleRateHertz: 16000,
        languageCode: 'ko-KR',
      );

      final speechToText = _speechToText;
      if (speechToText == null) {
        _notifyStatusChange(RecordingStatus.error);
        _notifyTextChange('Speech-to-Text 초기화되지 않음');
        return;
      }

      final response = await speechToText.recognize(config, audio);

      // 음성 인식 결과 검증
      if (response.results.isEmpty) {
        _notifyStatusChange(RecordingStatus.error);
        _notifyTextChange('음성을 인식할 수 없습니다');
        return;
      }

      final recognizedText = response.results
          .map((e) => e.alternatives.first.transcript)
          .join(' ')
          .trim(); // 공백 제거

      // 인식된 텍스트가 비어있는지 확인
      if (recognizedText.isEmpty) {
        _notifyStatusChange(RecordingStatus.error);
        _notifyTextChange('음성을 인식할 수 없습니다');
        return;
      }

      final englishText = await _translateText(recognizedText, 'en');
      final vietnameseText = await _translateText(recognizedText, 'vi');

      // SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      final workerInfo = {
        'workerName': {
          'korean': recognizedText,
          'english': englishText,
          'vietnamese': vietnameseText,
        },
        'content': {
          'korean': "",
          'english': "",
          'vietnamese': "",
        },
        'date': DateTime.now().toIso8601String(),
      };

      await prefs.setString('current_worker', json.encode(workerInfo));

      _notifyStatusChange(RecordingStatus.success);
      _notifyTextChange(recognizedText);
    } catch (e) {
      _notifyStatusChange(RecordingStatus.error);
      _notifyTextChange('음성 처리 오류: $e');
    }
  }

  // 번역 API 호출
  Future<String> _translateText(String text, String targetLanguage) async {
    try {
      final apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

      final uri = Uri.parse('https://translation.googleapis.com/language/translate/v2?key=$apiKey');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'q': text,
          'source': 'ko',
          'target': targetLanguage,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['data']['translations'][0]['translatedText'];
      } else {
        print('번역 API 오류: ${response.statusCode} ${response.body}');
        return '';
      }
    } catch (e) {
      print('번역 오류: $e');
      return '';
    }
  }

  // 상태에 따른 색상 가져오기
  Color getStatusColor() {
    switch (_recordingStatus) {
      case RecordingStatus.idle:
        return Colors.indigoAccent;
      case RecordingStatus.listening:
        return Colors.blue;
      case RecordingStatus.processing:
        return Colors.purple;
      case RecordingStatus.success:
        return Colors.green;
      case RecordingStatus.error:
        return Colors.red;
    }
  }

  // 상태에 따른 아이콘 가져오기
  IconData getStatusIcon() {
    switch (_recordingStatus) {
      case RecordingStatus.idle:
        return Icons.mic_none;
      case RecordingStatus.listening:
        return Icons.hearing;
      case RecordingStatus.processing:
        return Icons.hourglass_top;
      case RecordingStatus.success:
        return Icons.check_circle;
      case RecordingStatus.error:
        return Icons.error;
    }
  }

  // 리소스 정리
  void dispose() {
    _silenceTimer?.cancel();
    _audioRecorder.dispose();
    _statusListeners.clear();
    _textListeners.clear();
  }
}