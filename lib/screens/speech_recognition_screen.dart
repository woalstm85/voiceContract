import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:contact/screens/models/contract_section.dart';
import 'package:contact/screens/services/speech_recognition_service.dart';
import 'package:contact/screens/services/translation_service.dart';
import 'package:contact/screens/services/audio_player_service.dart';
import 'package:contact/screens/widgets/section_header.dart';
import 'package:contact/screens/widgets/section_content.dart';
import 'package:contact/screens/utils/snackbar_utils.dart';

class SpeechRecognitionScreen extends StatefulWidget {
  const SpeechRecognitionScreen({Key? key}) : super(key: key);

  @override
  _SpeechRecognitionScreenState createState() => _SpeechRecognitionScreenState();
}

class _SpeechRecognitionScreenState extends State<SpeechRecognitionScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  final VoiceRecognitionService _voiceService = VoiceRecognitionService();
  final TranslationService _translationService = TranslationService();

  String _workerName = '';

  // 현재 확장된 섹션
  String _expandedSectionId = 'startDate';

  // 섹션 목록
  late List<ContractSection> _sections;

  // 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _initSections();
    _voiceService.init();
    _audioPlayerService.init(
        onPlayStateChanged: (isPlaying) {
          setState(() {});
        }
    );
    _initTts();
    _loadWorkerInfo();
    _scrollController.addListener(_scrollListener);

    // 음성 인식 결과 리스너 등록
    _voiceService.addRecognitionResultListener(_handleRecognitionResult);
  }

// 음성 인식 결과 처리
  void _handleRecognitionResult(String sectionId, String koreanText, String englishText, String vietnameseText) {
    setState(() {
      final index = _sections.indexWhere((s) => s.id == sectionId);
      if (index != -1) {
        // 한글 텍스트는 항상 업데이트
        _sections[index].koreanText = koreanText;

        // 영어와 베트남어는 "번역 중..." 메시지가 아닐 때만 업데이트
        if (englishText != "번역 중...") {
          _sections[index].englishText = englishText;
        }
        if (vietnameseText != "번역 중...") {
          _sections[index].vietnameseText = vietnameseText;
        }

        // 번역이 완료되었을 때만 완료 상태로 표시
        if (englishText != "번역 중..." && vietnameseText != "번역 중...") {
          _sections[index].isCompleted = true;
        }
      }
    });
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

  // 섹션 초기화
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

  // TTS 초기화
  Future<void> _initTts() async {
    await flutterTts.setLanguage('vi-VN');  // 초기 언어 설정
  }

  // TTS 음성 재생
  Future<void> _speak(String text, String langCode) async {
    await flutterTts.setLanguage(langCode == 'vi' ? 'vi-VN' : 'en-US');
    await flutterTts.speak(text);
  }

  // 근로자 정보 로드
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

  // 녹음 시작
  Future<void> _startRecording() async {
    if (await _voiceService.startRecording(_expandedSectionId, _workerName)) {
      setState(() {
        final index = _sections.indexWhere((s) => s.id == _expandedSectionId);
        if (index != -1) {
          _sections[index].koreanText = '듣고 있습니다...';
          _sections[index].englishText = '';
          _sections[index].vietnameseText = '';
        }
      });
    } else {
      showSnackBar(context, '녹음을 시작할 수 없습니다');
    }
  }

  // 녹음 중지
  Future<void> _stopRecording() async {
    await _voiceService.stopRecording();

    // 음성 인식이 중단된 경우 (무음 감지 등)
    if (_voiceService.stoppedDueToSilence) {
      setState(() {
        final index = _sections.indexWhere((s) => s.id == _expandedSectionId);
        if (index != -1) {
          _sections[index].koreanText = '';
          _sections[index].englishText = '';
          _sections[index].vietnameseText = '';
        }
      });
      showSnackBar(context, '음성이 인식되지 않았습니다', seconds: 2);
      return;
    }

    // 정상 중지된 경우
    final index = _sections.indexWhere((s) => s.id == _expandedSectionId);
    if (index != -1) {
      setState(() {
        _sections[index].audioFilePath = _voiceService.lastRecordingPath;
        _sections[index].koreanText = '처리 중...';
      });
    }
  }

  // 오디오 재생/중지
  Future<void> _togglePlayback() async {
    final section = _sections.firstWhere((s) => s.id == _expandedSectionId);

    try {
      if (_audioPlayerService.isPlaying) {
        await _audioPlayerService.stopPlayback();
      } else {
        await _audioPlayerService.startPlayback(section.audioFilePath);
      }
    } catch (e) {
      showSnackBar(context, '재생 오류: $e');
    }
  }

  // 계약 저장
  Future<void> _saveContract() async {
    try {
      // 모든 섹션이 완료되었는지 확인
      final uncompletedSections = _sections.where((s) => !s.isCompleted).toList();
      if (uncompletedSections.isNotEmpty) {
        showSnackBar(
            context,
            '모든 항목을 작성해야 합니다. 미완료: ${uncompletedSections.map((s) => s.title).join(', ')}',
            seconds: 3
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
        showSnackBar(context, '저장되었습니다');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('Error saving contract: $e');
      if (mounted) {
        showSnackBar(context, '저장 중 오류가 발생했습니다: $e');
      }
    }
  }

  // 섹션 확장/축소 토글
  void _toggleSection(String sectionId) {
    setState(() {
      _expandedSectionId = (_expandedSectionId == sectionId) ? '' : sectionId;
    });
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
        elevation: _isScrolled ? 4.0 : 0.0,
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
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _buildCompletionStatus(),

                // 각 섹션 렌더링
                for (int i = 0; i < _sections.length; i++) ...[
                  SectionHeader(
                    section: _sections[i],
                    index: i + 1,
                    isExpanded: _expandedSectionId == _sections[i].id,
                    onToggle: () => _toggleSection(_sections[i].id),
                  ),
                  if (_expandedSectionId == _sections[i].id)
                    SectionContent(
                      section: _sections[i],
                      isRecording: _voiceService.isRecording,
                      isPlaying: _audioPlayerService.isPlaying,
                      onStartRecording: _startRecording,
                      onStopRecording: _stopRecording,
                      onTogglePlayback: _togglePlayback,
                      onSpeakText: _speak,
                    ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),

          _buildBottomButtons(),
        ],
      ),
    );
  }

  // 완료 상태 표시 위젯
  Widget _buildCompletionStatus() {
    return Container(
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
    );
  }

  // 하단 버튼 위젯
  Widget _buildBottomButtons() {
    return Padding(
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
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _audioPlayerService.dispose();
    flutterTts.stop();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
}