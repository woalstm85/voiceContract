import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_speech/google_speech.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as path;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../widgets/wave_pulse_loading.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ContractSection {
  final String id;
  final String title;
  String koreanText;
  String englishText;
  String vietnameseText;
  String audioFilePath;
  bool isCompleted;

  ContractSection({
    required this.id,
    required this.title,
    this.koreanText = '',
    this.englishText = '',
    this.vietnameseText = '',
    this.audioFilePath = '',
    this.isCompleted = false,
  });
}

class SpeechRecognitionScreen extends StatefulWidget {
  const SpeechRecognitionScreen({Key? key}) : super(key: key);

  @override
  _SpeechRecognitionScreenState createState() => _SpeechRecognitionScreenState();
}

class _SpeechRecognitionScreenState extends State<SpeechRecognitionScreen> {

  final FlutterTts flutterTts = FlutterTts();
  bool _isRecording = false;
  bool _isPlaying = false;
  String _workerName = '';
  final _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  SpeechToText? _speechToText;

  // 현재 확장된 섹션
  String _expandedSectionId = 'startDate';

  // 섹션 목록
  late List<ContractSection> _sections;

  // 스크롤 컨트롤러 추가
  final ScrollController _scrollController = ScrollController();
  // 앱바 색상 상태 변수
  bool _isScrolled = false;
  bool _stoppedDueToSilence = false;
  bool _hasSpeechStarted = false;
  int _totalSilenceAfterSpeech = 0;
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    _initSections();
    _initSpeechToText();
    _initAudioPlayer();
    _loadWorkerInfo();
    _initTts();
    _scrollController.addListener(_scrollListener);
    _hasSpeechStarted = false;
    _totalSilenceAfterSpeech = 0;
  }

  // 스크롤 위치에 따라 앱바 색상 변경
  void _scrollListener() {
    if (_scrollController.offset > 10 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 10 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  void _initSections() {
    _sections = [
      ContractSection(id: 'startDate', title: '근로개시일'),
      ContractSection(id: 'workplace', title: '근무장소'),
      ContractSection(id: 'jobDescription', title: '업무내용'),
      ContractSection(id: 'workHours', title: '근로시간'),
      ContractSection(id: 'wages', title: '임금'),
      ContractSection(id: 'holidays', title: '휴일'),
    ];
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage('vi-VN');  // 초기 언어 설정
  }

  Future<void> _speak(String text, String langCode) async {
    await flutterTts.setLanguage(langCode == 'vi' ? 'vi-VN' : 'en-US');
    await flutterTts.speak(text);
  }

  Future<void> _loadWorkerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final workerInfoString = prefs.getString('current_worker');
    if (workerInfoString != null) {
      final workerInfo = json.decode(workerInfoString);
      setState(() {
        _workerName = workerInfo['workerName']['korean'];
      });
    }
  }

  Future<String> _translateText(String text, String targetLanguage) async {
    try {
      final apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

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

  // 현재 섹션에 대한 오디오 파일 경로 생성
  Future<String> _getAudioFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final section = _sections.firstWhere((s) => s.id == _expandedSectionId);
    return path.join(dir.path, '${_workerName}_${section.title}_$timestamp.wav');
  }

  // 현재 선택된 섹션에 대한 녹음 시작
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

        // 현재 섹션 업데이트
        setState(() {
          _isRecording = true;
          final index = _sections.indexWhere((s) => s.id == _expandedSectionId);
          if (index != -1) {
            _sections[index].koreanText = '듣고 있습니다...';
            _sections[index].englishText = '';
            _sections[index].vietnameseText = '';
          }
        });
        _monitorRecording();
      }
    } catch (e) {
      setState(() {
        final index = _sections.indexWhere((s) => s.id == _expandedSectionId);
        if (index != -1) {
          _sections[index].koreanText = '녹음 시작 오류: $e';
        }
      });
    }
  }

// 무음 감지 함수 수정
  Future<void> _monitorRecording() async {
    int silentCount = 0;
    const double silenceThreshold = -15.0; // 데시벨 스케일에 맞는 임계값
    const int maxSilenceBeforeSpeech = 3; // 말하기 전 최대 무음 시간
    const int maxSilenceAfterSpeech = 3; // 말한 후 무음 시간 (번역 전)

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
          // 소리가 감지됨
          silentCount = 0; // 무음 카운터 초기화

          if (!_hasSpeechStarted) {
            // 처음으로 말하기 시작함
            setState(() {
              _hasSpeechStarted = true;
            });
            print('말하기 시작 감지');
          }
        } else {
          // 무음 감지
          silentCount++;
          print('무음 감지: ${silentCount * 0.5}초');

          if (_hasSpeechStarted) {
            // 이미 말하기가 시작된 상태에서의 무음
            _totalSilenceAfterSpeech = silentCount;

            // 말한 후 일정 시간(maxSilenceAfterSpeech) 이상 무음이면 녹음 중지 후 처리
            if (_totalSilenceAfterSpeech >= maxSilenceAfterSpeech * 2) { // *2는 0.5초 간격이므로
              print('말한 후 ${maxSilenceAfterSpeech}초 무음 감지. 음성 처리를 시작합니다.');
              timer.cancel();
              _silenceTimer = null; // 타이머 해제
              _stoppedDueToSilence = false; // 정상적인 종료로 처리
              await _stopRecording();
            }
          } else {
            // 아직 말하기가 시작되지 않은 상태에서의 무음
            // 처음부터 일정 시간(maxSilenceBeforeSpeech) 이상 무음이면 녹음 중지
            if (silentCount >= maxSilenceBeforeSpeech * 2) { // *2는 0.5초 간격이므로
              print('${maxSilenceBeforeSpeech}초 동안 소리가 감지되지 않아 자동 중지합니다.');
              timer.cancel();
              _silenceTimer = null; // 타이머 해제
              _stoppedDueToSilence = true; // 무음으로 인한 중지
              await _stopRecording();
            }
          }
        }
      } catch (e) {
        print('볼륨 모니터링 오류: $e');
      }
    });
  }

// 녹음 중지 및 오디오 처리
  Future<void> _stopRecording() async {
    try {
      // 먼저 녹음 상태 업데이트 (stop() 전에 설정)
      setState(() => _isRecording = false);

      final path = await _audioRecorder.stop();

      if (path == null) {
        print("오류: 녹음 파일이 생성되지 않음");
        return;
      }

      if (_stoppedDueToSilence) {
        // 무음으로 인한 중지인 경우
        setState(() {
          final index = _sections.indexWhere((s) => s.id == _expandedSectionId);
          if (index != -1) {
            // 초기 상태로 되돌림
            _sections[index].koreanText = '';
            _sections[index].englishText = '';
            _sections[index].vietnameseText = '';
          }
        });

        // 스낵바 표시
        showCustomSnackBar(context, '음성이 인식되지 않았습니다', seconds: 2);

        // 플래그 초기화
        _stoppedDueToSilence = false;

        return; // 더 이상 처리하지 않음
      }

      // 정상적인 녹음 중지인 경우 (사용자가 직접 중지하거나 음성이 있는 경우)
      final index = _sections.indexWhere((s) => s.id == _expandedSectionId);
      if (index != -1) {
        setState(() {
          _sections[index].audioFilePath = path;
          _sections[index].koreanText = '처리 중...';
        });
      }
      await _processAudio(File(path));
    } catch (e) {
      print("녹음 중지 오류: $e");

      setState(() {
        _isRecording = false; // 오류 발생 시에도 녹음 상태 false로
      });

      showCustomSnackBar(context, '녹음 중지 오류: $e');
    }
  }

  // 오디오 파일 처리 및 번역
  Future<void> _processAudio(File audioFile) async {
    if (!mounted) return;

    context.showWavePulseLoading(message: '음성 번역 중');
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

        setState(() {
          final index = _sections.indexWhere((s) => s.id == _expandedSectionId);
          if (index != -1) {
            _sections[index].koreanText = 'Speech-to-Text 초기화되지 않음';
          }
        });

        context.hideWavePulseLoading();
        return;
      }

      final response = await speechToText.recognize(config, audio);

      // 음성 인식 결과 검증
      if (response.results.isEmpty) {
        setState(() {
          final index = _sections.indexWhere((s) => s.id == _expandedSectionId);
          if (index != -1) {
            showCustomSnackBar(context, '음성을 인식할 수 없습니다', seconds: 2);
          }
        });
        context.hideWavePulseLoading();
        return;
      }

      final recognizedText = response.results
          .map((e) => e.alternatives.first.transcript)
          .join(' ')
          .trim(); // 공백으로 연결하고 앞뒤 공백 제거

      // 인식된 텍스트가 비어있는지 확인
      if (recognizedText.isEmpty) {
        setState(() {
          final index = _sections.indexWhere((s) => s.id == _expandedSectionId);
          if (index != -1) {
            showCustomSnackBar(context, '음성을 인식할 수 없습니다', seconds: 2);
          }
        });
        context.hideWavePulseLoading();
        return;
      }

      final englishText = await _translateText(recognizedText, 'en');
      final vietnameseText = await _translateText(recognizedText, 'vi');

      setState(() {
        final index = _sections.indexWhere((s) => s.id == _expandedSectionId);
        if (index != -1) {
          _sections[index].koreanText = recognizedText;
          _sections[index].englishText = englishText;
          _sections[index].vietnameseText = vietnameseText;
          _sections[index].isCompleted = true;
        }
      });

      context.hideWavePulseLoading();
    } catch (e) {
      if (!mounted) return;
      context.hideWavePulseLoading();

      setState(() {
        final index = _sections.indexWhere((s) => s.id == _expandedSectionId);
        if (index != -1) {
          showCustomSnackBar(context, '음성 처리 오류: $e');
        }
      });
    }
  }

  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
      });
    });
  }

  Future<void> _togglePlayback() async {
    try {
      final section = _sections.firstWhere((s) => s.id == _expandedSectionId);

      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(DeviceFileSource(section.audioFilePath));
      }
    } catch (e) {
      print('재생 오류: $e');
      showCustomSnackBar(context, '재생오류: $e');
      setState(() {
        _isPlaying = false;
      });
    }
  }

  // 모든 계약 정보 저장
  Future<void> _saveContract() async {
    try {
      // 모든 섹션이 완료되었는지 확인
      final uncompletedSections = _sections.where((s) => !s.isCompleted).toList();
      if (uncompletedSections.isNotEmpty) {
        showCustomSnackBar(context,
            '모든 항목을 작성해야 합니다. 미완료: ${uncompletedSections.map((s) => s.title).join(', ')}'
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      // 근로자 정보 가져오기
      final workerInfoString = prefs.getString('current_worker');
      if (workerInfoString == null) {
        throw Exception('근로자 정보를 찾을 수 없습니다');
      }
      final workerInfo = json.decode(workerInfoString);

      // 기존 계약 목록 가져오기
      final contracts = prefs.getStringList('contracts') ?? [];

      // 새 계약 정보 생성
      final contractInfo = {
        'workerName': workerInfo['workerName'],
        'signature': workerInfo['signature'],
        'date': DateTime.now().toIso8601String(),
        'sections': _sections.map((section) => {
          'id': section.id,
          'title': section.title,
          'content': {
            'korean': section.koreanText,
            'english': section.englishText,
            'vietnamese': section.vietnameseText,
          },
          'audioFile': section.audioFilePath,
        }).toList(),
      };

      // 계약 목록에 추가
      contracts.add(jsonEncode(contractInfo));
      await prefs.setStringList('contracts', contracts);

      if (mounted) {
        showCustomSnackBar(context, '저장되었습니다');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('Error saving contract: $e');
      if (mounted) {
        showCustomSnackBar(context, '저장 중 오류가 발생했습니다: $e');
      }
    }
  }

  // 섹션 확장/축소 토글
  void _toggleSection(String sectionId) {
    setState(() {
      _expandedSectionId = (_expandedSectionId == sectionId) ? '' : sectionId;
    });
  }

  // 아코디언 섹션 헤더 위젯 빌드
  Widget _buildSectionHeader(ContractSection section) {
    final isExpanded = _expandedSectionId == section.id;

    return InkWell(
      onTap: () => _toggleSection(section.id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isExpanded ? Colors.indigo.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isExpanded ? Colors.indigo : Colors.grey.shade300,
            width: isExpanded ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 번호와 제목
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '${_sections.indexWhere((s) => s.id == section.id) + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              section.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isExpanded ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            // 완료 표시 아이콘
            if (section.isCompleted)
              const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            // 확장/축소 아이콘
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // 언어별 텍스트 섹션 빌드
  Widget _buildLanguageSection(String title, String content, String langCode) {
    final isStatusMessage = content == '듣고 있습니다...' ||
        content.contains('오류:') ||
        content.contains('초기화되지 않음');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (langCode != 'ko' && content.isNotEmpty && !isStatusMessage) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.indigo),
                onPressed: () => _speak(content, langCode),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isStatusMessage ? Colors.orange : Colors.grey.shade300,
              width: isStatusMessage ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content.isEmpty ? (langCode == 'ko' ? '음성으로 정보를 입력해주세요' : '') : content,
            style: TextStyle(
              fontSize: 14,
              color: isStatusMessage ? Colors.orange : Colors.black,
              fontStyle: isStatusMessage ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // 섹션 콘텐츠 빌드
  Widget _buildSectionContent(ContractSection section) {
    final hasAudio = section.audioFilePath.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLanguageSection('한국어', section.koreanText, 'ko'),
          _buildLanguageSection('영어 (English)', section.englishText, 'en'),
          _buildLanguageSection('베트남어 (Tiếng Việt)', section.vietnameseText, 'vi'),

          // 녹음 및 재생 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white), // 아이콘 색상을 흰색으로 설정
                label: Text(
                  _isRecording ? '녹음 중지' : '녹음 시작',
                  style: const TextStyle(color: Colors.white), // 텍스트 색상을 흰색으로 설정
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
              if (hasAudio) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _togglePlayback,
                  icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow, color: Colors.white), // 아이콘 색상을 흰색으로 설정
                  label: Text(
                    _isPlaying ? '중지' : '재생',
                    style: const TextStyle(color: Colors.white), // 텍스트 색상을 흰색으로 설정
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlaying ? Colors.red : Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void showCustomSnackBar(BuildContext context, String message, {int seconds = 1}) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar(); // 기존 스낵바 제거

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: seconds), // 매개변수로 받은 초 사용
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _isScrolled ? Colors.indigo : Colors.white,
        centerTitle: true,
        title: Text(
          '근로계약서 작성',
          style: TextStyle(
              color: _isScrolled ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600
          ),
        ),
        elevation: _isScrolled ? 4.0 : 0.0, // 스크롤 시 그림자 효과 추가
        leading: IconButton(
          icon: Icon(
              Icons.arrow_back_ios,
              color: _isScrolled ? Colors.white : Colors.black
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController, // 스크롤 컨트롤러 연결
              padding: const EdgeInsets.all(16),
              children: [
                // 완료 상태 표시
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Text(
                        '작성 완료: ${_sections.where((s) => s.isCompleted).length}/${_sections.length}',
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // 각 섹션 렌더링
                for (int i = 0; i < _sections.length; i++) ...[
                  _buildSectionHeader(_sections[i]),
                  if (_expandedSectionId == _sections[i].id)
                    _buildSectionContent(_sections[i]),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),

          // 하단 버튼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
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
                      style: TextStyle(color: Colors.black87),
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
                    onPressed: _saveContract,
                    child: const Text(
                      '저 장',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    flutterTts.stop();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _silenceTimer?.cancel();
    super.dispose();
  }
}