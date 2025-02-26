import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:io';
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
      // API 키를 실제 키로 교체했는지 확인
      final apiKey = "AIzaSyDNiiHzhqOX79XJjQ6gHyFd9dGIfyekJJw";

      // URL에 API 키를 쿼리 파라미터로 추가
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
          _nameController.text = '듣고 있습니다...';
        });
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
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null) {
        await _processAudio(File(path));
      }
    } catch (e) {
      setState(() => _nameController.text = '녹음 중지 오류: $e');
    }
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
                  backgroundColor: Colors.teal,
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