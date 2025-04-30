import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:contact/screens/models/contract_section.dart';
import 'package:contact/screens/services/speech_recognition_service.dart';
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

  String _workerName = '';

  // 현재 확장된 섹션
  String _expandedSectionId = 'startDate';

  // 섹션 목록
  late List<ContractSection> _sections;

  // 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  // 컴포넌트가 마운트 상태인지 확인하기 위한 변수
  bool _isMounted = false;

  // 각 섹션의 GlobalKey 리스트 (자동 스크롤 위해)
  final List<GlobalKey> _sectionKeys = [];

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _initSections();
    // 섹션별 GlobalKey 초기화
    for (int i = 0; i < _sections.length; i++) {
      _sectionKeys.add(GlobalKey());
    }
    _initServices();
    _loadWorkerInfo();
  }

  // 서비스 초기화
  Future<void> _initServices() async {
    await _voiceService.init();
    _audioPlayerService.init(
        onPlayStateChanged: (isPlaying) {
          if (_isMounted) setState(() {});
        }
    );
    await _initTts();
    _scrollController.addListener(_scrollListener);

    // 음성 인식 결과 리스너 등록
    _voiceService.addRecognitionResultListener(_handleRecognitionResult);
  }

  // 음성 인식 결과 처리
  void _handleRecognitionResult(String sectionId, String koreanText, String englishText, String vietnameseText) {
    if (_isMounted) {
      setState(() {
        final index = _sections.indexWhere((s) => s.id == sectionId);
        if (index != -1) {
          _sections[index].koreanText = koreanText;
          if (englishText.isNotEmpty) {
            _sections[index].englishText = englishText;
          }
          if (vietnameseText.isNotEmpty) {
            _sections[index].vietnameseText = vietnameseText;
          }
          if (koreanText.isNotEmpty && englishText.isNotEmpty && vietnameseText.isNotEmpty) {
            _sections[index].isCompleted = true;
          }
        }
      });
    }
  }

  // 스크롤 위치에 따라 앱바 색상 변경
  void _scrollListener() {
    if (!_isMounted) return;

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
    await flutterTts.setLanguage('vi-VN');
  }

  // TTS 음성 재생
  Future<void> _speak(String text, String langCode) async {
    if (!_isMounted) return;

    await flutterTts.setLanguage(langCode == 'vi' ? 'vi-VN' : 'en-US');
    await flutterTts.speak(text);
  }

  // 근로자 정보 로드
  Future<void> _loadWorkerInfo() async {
    if (!_isMounted) return;

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
    if (!_isMounted) return;

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
      if (_isMounted) {
        showSnackBar(context, '녹음을 시작할 수 없습니다');
      }
    }
  }

  // 녹음 중지
  Future<void> _stopRecording() async {
    if (!_isMounted) return;

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
      if (_isMounted) {
        showSnackBar(context, '음성이 인식되지 않았습니다', seconds: 2);
      }
      return;
    }

    // 정상 중지된 경우 오디오 경로만 업데이트
    if (_isMounted) {
      setState(() {
        final index = _sections.indexWhere((s) => s.id == _expandedSectionId);
        if (index != -1) {
          _sections[index].audioFilePath = _voiceService.lastRecordingPath;
        }
      });
    }
  }

  // 오디오 재생/중지
  Future<void> _togglePlayback() async {
    if (!_isMounted) return;

    final section = _sections.firstWhere((s) => s.id == _expandedSectionId);

    try {
      if (_audioPlayerService.isPlaying) {
        await _audioPlayerService.stopPlayback();
      } else {
        await _audioPlayerService.startPlayback(section.audioFilePath);
      }
    } catch (e) {
      if (_isMounted) {
        showSnackBar(context, '재생 오류: $e');
      }
    }
  }

  // 계약 저장
  Future<void> _saveContract() async {
    if (!_isMounted) return;

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

      if (_isMounted) {
        showSnackBar(context, '저장되었습니다');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('Error saving contract: $e');
      if (_isMounted) {
        showSnackBar(context, '저장 중 오류가 발생했습니다: $e');
      }
    }
  }

  // 섹션 확장/축소 토글하고 자동 스크롤
  void _toggleSection(String sectionId, int index) {
    if (!_isMounted) return;

    setState(() {
      // 같은 섹션을 다시 누른 경우 닫기
      if (_expandedSectionId == sectionId) {
        _expandedSectionId = '';
      } else {
        _expandedSectionId = sectionId;
        // 확장된 다음에 스크롤 위치 조정 (약간의 딜레이 필요)
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_isMounted) {
            Scrollable.ensureVisible(
              _sectionKeys[index].currentContext!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 디바이스 화면 크기 가져오기
    final screenHeight = MediaQuery.of(context).size.height;
    // 실제 사용 가능한 콘텐츠 영역 계산 (앱바, 진행바, 하단 버튼 제외)
    final contentHeight = screenHeight - 56 - 40 - 64 - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom;
    // 한 화면에 보여줄 섹션 수 (최소 1개는 보장)
    final targetSectionsPerScreen = (contentHeight / 400 > 1) ? 2 : 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCompactProgressBar(), // 간결한 진행 바
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), // 패딩 감소
              itemCount: _sections.length,
              itemBuilder: (context, i) {
                return Column(
                  key: _sectionKeys[i],
                  children: [
                    const SizedBox(height: 8), // 간격 줄임
                    _buildCompactSectionHeader(i),
                    if (_expandedSectionId == _sections[i].id)
                      FadeIn(
                        duration: const Duration(milliseconds: 200),
                        child: SectionContent(
                          section: _sections[i],
                          isRecording: _voiceService.isRecording,
                          isPlaying: _audioPlayerService.isPlaying,
                          onStartRecording: _startRecording,
                          onStopRecording: _stopRecording,
                          onTogglePlayback: _togglePlayback,
                          onSpeakText: _speak,
                        ),
                      ),
                    const SizedBox(height: 8), // 하단 여백 줄임
                  ],
                );
              },
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  // AppBar 위젯
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: _isScrolled ? 4.0 : 0.0,
      centerTitle: true,
      backgroundColor: _isScrolled ? Colors.indigo : Colors.white,
      title: Text(
        '근로계약서 작성',
        style: TextStyle(
          color: _isScrolled ? Colors.white : Colors.indigo,
          fontWeight: FontWeight.w900,
          fontSize: 20,
          letterSpacing: 1.2,
        ),
      ),
      leading: IconButton(
        icon: Icon(
            Icons.arrow_back_ios,
            color: _isScrolled ? Colors.white : Colors.indigo
        ),
        onPressed: () {
          _audioPlayerService.stopPlayback();
          _voiceService.stopRecording();
          Navigator.pop(context);
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
              Icons.home,
              color: _isScrolled ? Colors.white : Colors.indigo
          ),
          onPressed: () {
            _audioPlayerService.stopPlayback();
            _voiceService.stopRecording();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ],
    );
  }

  // 간결한 섹션 헤더 위젯
  Widget _buildCompactSectionHeader(int index) {
    final section = _sections[index];
    final isExpanded = _expandedSectionId == section.id;

    return InkWell(
      onTap: () => _toggleSection(section.id, index),
      borderRadius: BorderRadius.circular(8),
      splashColor: Colors.indigo.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18), // 패딩 증가
        decoration: BoxDecoration(
          color: isExpanded ? Colors.indigo.withOpacity(0.08) : Colors.grey.withOpacity(0.05),
          border: Border.all(
            color: isExpanded ? Colors.indigo : Colors.grey.shade300,
            width: isExpanded ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 번호 배지 (크기 증가)
            Container(
              width: 36, // 크기 증가
              height: 36, // 크기 증가
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isExpanded ? Colors.indigo : Colors.indigo.withOpacity(0.7),
                borderRadius: BorderRadius.circular(18),
                boxShadow: isExpanded ? [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18, // 폰트 크기 증가
                ),
              ),
            ),
            const SizedBox(width: 18), // 간격 증가
            Expanded(
              child: Text(
                section.title,
                style: TextStyle(
                  fontSize: 18, // 폰트 크기 증가
                  fontWeight: isExpanded ? FontWeight.bold : FontWeight.w500,
                  color: isExpanded ? Colors.indigo : Colors.black87,
                ),
              ),
            ),
            // 완료 표시 아이콘
            if (section.isCompleted)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 26, // 아이콘 크기 증가
              ),
            const SizedBox(width: 10), // 간격 증가
            // 확장/축소 아이콘
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: isExpanded ? Colors.indigo : Colors.grey[700],
              size: 26, // 아이콘 크기 증가
            ),
          ],
        ),
      ),
    );
  }

  // 간결한 진행 상태 바
  Widget _buildCompactProgressBar() {
    final completedCount = _sections.where((s) => s.isCompleted).length;
    final totalCount = _sections.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '진행 상황:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: completedCount / totalCount,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  completedCount == totalCount ? Colors.greenAccent : Colors.white,
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$completedCount/$totalCount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 하단 버튼 위젯
  Widget _buildBottomButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () {
                _audioPlayerService.stopPlayback();
                _voiceService.stopRecording();
                Navigator.pop(context);
              },
              child: const Text(
                '이 전',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: _saveContract,
              child: const Text(
                '저 장',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isMounted = false;
    _voiceService.dispose();
    _audioPlayerService.dispose();
    flutterTts.stop();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
}