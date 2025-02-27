import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:google_speech/google_speech.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'speech_recognition_screen.dart';
import '../../widgets/wave_pulse_loading.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WorkerInfoScreen extends StatefulWidget {
  const WorkerInfoScreen({Key? key}) : super(key: key);

  @override
  State<WorkerInfoScreen> createState() => _WorkerInfoScreenState();
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.5;  // 격자선을 좀 더 얇게 설정

    // 가로 선
    double gridSize = 20; // 격자 크기
    for (double i = 0; i <= size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    // 세로 선
    for (double i = 0; i <= size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum RecordingStatus {
  idle,
  listening,
  processing,
  success,
  error,
}

class _WorkerInfoScreenState extends State<WorkerInfoScreen> {

  final TextEditingController _nameController = TextEditingController();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _isRecording = false;
  bool _hasSignature = false;
  final _audioRecorder = AudioRecorder();
  SpeechToText? _speechToText;
  RecordingStatus _recordingStatus = RecordingStatus.idle;
  bool _stoppedDueToSilence = false;
  bool _hasSpeechStarted = false;
  int _totalSilenceAfterSpeech = 0;
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    _initSpeechToText();
    _signatureController.addListener(() {
      final hasSignature = _signatureController.isNotEmpty;
      if (hasSignature != _hasSignature) {
        setState(() {
          _hasSignature = hasSignature;
        });
      }
    });
  }

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


  Future<void> _initSpeechToText() async {
    final String jsonString = await rootBundle.loadString('assets/voice_service_account.json');
    final serviceAccount = ServiceAccount.fromString(jsonString);
    _speechToText = SpeechToText.viaServiceAccount(serviceAccount);
  }

  Future<void> _toggleListening() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

// 녹음 시작 시 상태 초기화 (기존 _startRecording 함수에 추가)
  Future<void> _startRecording() async {
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

        setState(() {
          _isRecording = true;
          _recordingStatus = RecordingStatus.listening;
          _nameController.text = '음성인식중...';
          _hasSpeechStarted = false; // 상태 초기화
          _totalSilenceAfterSpeech = 0; // 상태 초기화
        });

        // 무음 모니터링 시작
        _monitorRecording();
      }
    } catch (e) {
      setState(() {
        _recordingStatus = RecordingStatus.error;
        _nameController.text = '녹음 시작 오류: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      // 녹음 상태 업데이트 (stop() 전에 설정)
      setState(() => _isRecording = false);

      final path = await _audioRecorder.stop();

      if (path == null) {
        print("오류: 녹음 파일이 생성되지 않음");
        return;
      }

      if (_stoppedDueToSilence) {
        // 무음 감지로 인해 녹음 중지된 경우
        setState(() {
          _recordingStatus = RecordingStatus.idle;
          _nameController.text = ''; // 텍스트 필드 초기화
        });

        // 사용자에게 안내
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('음성이 인식되지 않았습니다'),
            duration: Duration(seconds: 2),
          ),
        );

        // 플래그 초기화
        _stoppedDueToSilence = false;
        return; // 이후 처리 중단
      }

      // 정상적인 녹음 중지인 경우 파일 처리
      await _processAudio(File(path));
    } catch (e) {
      print("녹음 중지 오류: $e");

      setState(() {
        _isRecording = false; // 오류 발생 시에도 녹음 상태 false로
        _nameController.text = '녹음 중지 오류 발생';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('녹음 중 오류가 발생했습니다: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _monitorRecording() async {
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
            setState(() {
              _hasSpeechStarted = true;
            });
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
              await _stopRecording();
            }
          } else {
            if (silentCount >= maxSilenceBeforeSpeech * 2) {
              print('${maxSilenceBeforeSpeech}초 동안 소리가 감지되지 않아 자동 중지합니다.');
              timer.cancel();
              _silenceTimer = null;
              _stoppedDueToSilence = true;
              await _stopRecording();
            }
          }
        }
      } catch (e) {
        print('볼륨 모니터링 오류: $e');
      }
    });
  }

  Future<String> _getAudioFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/audio_$timestamp.wav';
  }

  Future<void> _processAudio(File audioFile) async {
    if (!mounted) return;

    setState(() {
      _recordingStatus = RecordingStatus.processing;
    });

    context.showWavePulseLoading(message: '음성번역중');
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
        if (!mounted) return;
        setState(() => _nameController.text = 'Speech-to-Text 초기화되지 않음');
        context.hideWavePulseLoading();
        return;
      }

      final response = await speechToText.recognize(config, audio);

      // 음성 인식 결과 검증
      if (response.results.isEmpty) {
        setState(() => _nameController.text = '음성을 인식할 수 없습니다');
        context.hideWavePulseLoading();
        return;
      }

      final recognizedText = response.results
          .map((e) => e.alternatives.first.transcript)
          .join(' ')
          .trim(); // 공백 제거

      // 인식된 텍스트가 비어있는지 확인
      if (recognizedText.isEmpty) {
        setState(() => _nameController.text = '음성을 인식할 수 없습니다');
        context.hideWavePulseLoading();
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

      setState(() {
        _recordingStatus = RecordingStatus.success;
        _nameController.text = recognizedText;
      });
      context.hideWavePulseLoading();
    } catch (e) {
      if (!mounted) return;
      context.hideWavePulseLoading();
      setState(() {
        _recordingStatus = RecordingStatus.error;
        _nameController.text = '음성 처리 오류: $e';
      });
    }
  }

  Future<void> _saveWorkerInfo() async {
    if (_nameController.text.isEmpty || !_hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이름과 서명을 모두 입력해주세요'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    try {
      final signature = await _signatureController.toPngBytes();
      final prefs = await SharedPreferences.getInstance();

      // 기존 정보 불러오기
      final currentWorkerString = prefs.getString('current_worker');
      if (currentWorkerString != null) {
        final currentWorker = json.decode(currentWorkerString);
        currentWorker['signature'] = base64Encode(signature!);

        // 업데이트된 정보 저장
        await prefs.setString('current_worker', json.encode(currentWorker));

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SpeechRecognitionScreen(),
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving worker info: $e');
    }
  }

  // 상태에 따른 색상 가져오기
  Color _getStatusColor() {
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
  IconData _getStatusIcon() {
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        centerTitle: true,
        title: const Text(
          '근로자 정보',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '근로자명',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _getStatusColor(),
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Icon(
                            _getStatusIcon(),
                            color: _getStatusColor(),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            readOnly: true,
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: '음성으로 이름을 말씀해주세요',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                              ),
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  backgroundColor: _isRecording ? Colors.red : Colors.teal,
                  onPressed: _toggleListening,
                  child: Icon(_isRecording ? Icons.mic_off : Icons.mic, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              '서명',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.indigoAccent, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: GridPainter(),
                  ),
                  Signature(
                    controller: _signatureController,
                    height: 200,
                    backgroundColor: Colors.transparent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _signatureController.clear(),
                  child: const Text('서명 지우기', style: TextStyle(color: Colors.orange)),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '이 전',
                      style: TextStyle(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _saveWorkerInfo,
                    child: const Text(
                      '확 인',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _nameController.dispose();
    _signatureController.dispose();
    super.dispose();
  }
}