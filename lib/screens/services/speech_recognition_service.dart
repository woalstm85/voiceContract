import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:google_speech/google_speech.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:contact/screens/services/translation_service.dart';

/// 음성 인식 및 녹음 처리를 위한 서비스 클래스
class VoiceRecognitionService {
  // 기본 속성
  final AudioRecorder _audioRecorder = AudioRecorder();
  SpeechToText? _speechToText;
  bool _isRecording = false;
  bool _stoppedDueToSilence = false;
  bool _hasSpeechStarted = false;
  int _totalSilenceAfterSpeech = 0;
  Timer? _silenceTimer;
  String _lastRecordingPath = '';

  // 현재 진행중인 섹션 ID
  String _currentSectionId = '';

  // 번역 서비스
  final TranslationService _translationService = TranslationService();

  // 콜백 함수 정의
  final List<Function(String, String, String, String)> _recognitionResultListeners = [];

  // 게터
  bool get isRecording => _isRecording;
  bool get stoppedDueToSilence => _stoppedDueToSilence;
  String get lastRecordingPath => _lastRecordingPath;

  // 초기화
  Future<void> init() async {
    await _initSpeechToText();
  }

  // 리스너 등록
  void addRecognitionResultListener(Function(String, String, String, String) listener) {
    _recognitionResultListeners.add(listener);
  }

  // 인식 결과 알림
  void _notifyRecognitionResult(String sectionId, String koreanText, String englishText, String vietnameseText) {
    for (var listener in _recognitionResultListeners) {
      listener(sectionId, koreanText, englishText, vietnameseText);
    }
  }

  // Speech-to-Text 초기화
  Future<void> _initSpeechToText() async {
    final String jsonString = await rootBundle.loadString('assets/voice_service_account.json');
    final serviceAccount = ServiceAccount.fromString(jsonString);
    _speechToText = SpeechToText.viaServiceAccount(serviceAccount);
  }

  // 녹음 파일 경로 생성
  Future<String> _getAudioFilePath(String sectionId, String workerName) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(dir.path, '${workerName}_${sectionId}_$timestamp.wav');
  }

  // 녹음 시작
  Future<bool> startRecording(String sectionId, String workerName) async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final audioPath = await _getAudioFilePath(sectionId, workerName);

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
        _currentSectionId = sectionId;
        _hasSpeechStarted = false;
        _totalSilenceAfterSpeech = 0;
        _stoppedDueToSilence = false;

        // 무음 모니터링 시작
        _monitorRecording();
        return true;
      }
      return false;
    } catch (e) {
      print('녹음 시작 오류: $e');
      return false;
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

      _lastRecordingPath = path;

      if (_stoppedDueToSilence) {
        // 무음으로 인한 중지는 더 이상 처리하지 않음
        return;
      }

      // 음성 처리 시작
      await _processAudio(File(path), _currentSectionId);
    } catch (e) {
      print("녹음 중지 오류: $e");
    }
  }

  // 무음 모니터링
  void _monitorRecording() {
    int silentCount = 0;
    const double silenceThreshold = -25.0;
    const int maxSilenceBeforeSpeech = 3;
    const int maxSilenceAfterSpeech = 3;

    _silenceTimer?.cancel();
    _silenceTimer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      try {
        Amplitude? amplitudeData = await _audioRecorder.getAmplitude();
        double amplitude = amplitudeData?.current ?? 0.0;

        if (amplitude > silenceThreshold) {
          // 소리가 감지됨
          silentCount = 0;
          if (!_hasSpeechStarted) {
            _hasSpeechStarted = true;
            print('말하기 시작 감지');
          }
        } else {
          // 무음 감지
          silentCount++;

          if (_hasSpeechStarted) {
            // 말하기 후 무음
            _totalSilenceAfterSpeech = silentCount;
            if (_totalSilenceAfterSpeech >= maxSilenceAfterSpeech * 2) {
              timer.cancel();
              _silenceTimer = null;
              _stoppedDueToSilence = false;
              await stopRecording();
            }
          } else {
            // 말하기 전 무음
            if (silentCount >= maxSilenceBeforeSpeech * 2) {
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

  // 오디오 처리 및 번역
// 오디오 처리 및 번역
  Future<void> _processAudio(File audioFile, String sectionId) async {
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
        print('Speech-to-Text 초기화되지 않음');
        return;
      }

      // 음성 인식 요청
      final response = await speechToText.recognize(config, audio);

      // 인식 결과 검증
      if (response.results.isEmpty) {
        print('음성을 인식할 수 없습니다');
        return;
      }

      final recognizedText = response.results
          .map((e) => e.alternatives.first.transcript)
          .join(' ')
          .trim();

      if (recognizedText.isEmpty) {
        print('인식된 텍스트가 없습니다');
        return;
      }

      // 한국어 텍스트 인식 즉시 UI에 표시 (번역 전)
      _notifyRecognitionResult(sectionId, recognizedText, "번역 중...", "번역 중...");

      // 번역 시작
      final englishText = await _translationService.translate(recognizedText, 'en');
      final vietnameseText = await _translationService.translate(recognizedText, 'vi');

      // 번역 완료 후 최종 결과 업데이트
      _notifyRecognitionResult(sectionId, recognizedText, englishText, vietnameseText);
    } catch (e) {
      print('음성 처리 오류: $e');
    }
  }

  // 리소스 정리
  void dispose() {
    _silenceTimer?.cancel();
    _audioRecorder.dispose();
    _recognitionResultListeners.clear();
  }
}