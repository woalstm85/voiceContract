import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:io';
import 'dart:convert';

// 분리된 파일 임포트
import 'package:contact/screens/widgets/contract_translations.dart';
import 'package:contact/screens/widgets/contract_pdf_generator.dart';
import 'package:contact/screens/widgets/contract_ui_components.dart';

class ContractDetailScreen extends StatefulWidget {
  final String langCode;
  final Map<String, dynamic> contract;

  const ContractDetailScreen({
    Key? key,
    required this.langCode,
    required this.contract,
  }) : super(key: key);

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> with SingleTickerProviderStateMixin {
  // ===== 상태 변수 =====
  final FlutterTts flutterTts = FlutterTts();  // TTS 기능을 위한 변수
  final ScrollController _scrollController = ScrollController();  // 스크롤 컨트롤러
  late TabController _languageTabController;  // 언어 탭 컨트롤러
  String _currentLangCode = '';  // 현재 선택된 언어 코드
  bool _showComparisonView = false;  // 비교 보기 모드 활성화 여부
  late final ContractTranslations _translations;  // 번역 관리 클래스
  late final ContractUIComponents _uiComponents;  // UI 컴포넌트 클래스
  late final ContractPDFGenerator _pdfGenerator;  // PDF 생성 클래스

  // ===== 생명주기 메소드 =====
  @override
  void initState() {
    super.initState();
    _currentLangCode = widget.langCode;  // 초기 언어 코드 설정

    // 헬퍼 클래스 초기화
    _translations = ContractTranslations();
    _uiComponents = ContractUIComponents(
      speak: _speak,
      toggleComparisonView: _toggleComparisonView,
      getLanguageColor: _getLanguageColor,
    );
    _pdfGenerator = ContractPDFGenerator(
      showSuccessSnackBar: _showSuccessSnackBar,
      showWarningSnackBar: _showWarningSnackBar,
      showErrorSnackBar: _showErrorSnackBar,
      getLocalizedText: _translations.getLocalizedText,
      getSectionTitle: _translations.getSectionTitle,
    );

    _initTts();  // TTS 초기화
    _initLanguageTabs();  // 언어 탭 초기화
  }

  @override
  void dispose() {
    flutterTts.stop();  // TTS 중지
    _scrollController.dispose();  // 스크롤 컨트롤러 해제
    _languageTabController.dispose();  // 탭 컨트롤러 해제
    super.dispose();
  }

  // ===== 초기화 메소드 =====

  // 언어 탭 초기화 메소드
  void _initLanguageTabs() {
    // 언어 코드에 따른 초기 탭 인덱스 설정
    _languageTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _currentLangCode == 'ko' ? 0 : _currentLangCode == 'en' ? 1 : 2,
    );

    // 탭 변경 시 언어 코드 업데이트
    _languageTabController.addListener(() {
      if (_languageTabController.indexIsChanging) {
        setState(() {
          switch (_languageTabController.index) {
            case 0:
              _currentLangCode = 'ko';
              break;
            case 1:
              _currentLangCode = 'en';
              break;
            case 2:
              _currentLangCode = 'vi';
              break;
          }
        });
        _initTts();  // 언어가 변경되면 TTS 재초기화
      }
    });
  }

  // TTS 초기화 메소드
  Future<void> _initTts() async {
    await flutterTts.setLanguage(_currentLangCode == 'vi' ? 'vi-VN' :
    _currentLangCode == 'en' ? 'en-US' : 'ko-KR');
  }

  // TTS 음성 재생 메소드
  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  // ===== 유틸리티 메소드 =====

  // 언어별 색상 가져오기
  Color _getLanguageColor(String code) {
    switch (code) {
      case 'ko':
        return Colors.indigo;
      case 'en':
        return Colors.teal;
      case 'vi':
        return Colors.deepPurple;
      default:
        return Colors.indigo;
    }
  }

  // 비교 보기 토글 메소드
  void _toggleComparisonView() {
    setState(() {
      _showComparisonView = !_showComparisonView;
    });
  }

  // 날짜 형식 변환 메소드
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // ===== 스낵바 메소드 =====
  void _showSuccessSnackBar(String message) {
    // 기존 스낵바가 있다면 먼저 제거
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  // ===== PDF 생성 메소드 =====
  Future<void> _generatePDF() async {
    await _pdfGenerator.generatePDF(
      context: context,
      contract: widget.contract,
      currentLangCode: _currentLangCode,
    );
  }

  // ===== UI 빌드 메소드 =====
  @override
  Widget build(BuildContext context) {
    final contractDate = widget.contract.containsKey('date')
        ? _formatDate(widget.contract['date'])
        : '날짜 정보 없음';
    final languageColor = _getLanguageColor(_currentLangCode);

    return Scaffold(
      backgroundColor: Colors.indigo[50],  // worker_list_screen과 동일한 배경색
      appBar: _uiComponents.buildAppBar(
          context: context,
          languageColor: languageColor,
          currentLangCode: _currentLangCode
      ),
      body: Column(
        children: [
          // 언어 선택 및 비교 보기 헤더
          _uiComponents.buildLanguageHeader(
            languageTabController: _languageTabController,
            contractDate: contractDate,
            currentLangCode: _currentLangCode,
            showComparisonView: _showComparisonView,
          ),

          // 계약서 내용 (스크롤 가능)
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: _buildContractContent(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _uiComponents.buildBottomButton(
        languageColor: languageColor,
        onPressed: _generatePDF,
      ),
    );
  }

  // 계약서 내용 위젯
  Widget _buildContractContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 근로자명 정보 표시
        _uiComponents.buildInfoSection(
          title: '1. 근로자명',
          content: widget.contract['workerName'][
          _currentLangCode == 'en' ? 'english' :
          _currentLangCode == 'vi' ? 'vietnamese' : 'korean'
          ],
          showSpeakButton: _currentLangCode != 'ko',
          originalContent: _currentLangCode != 'ko' ? widget.contract['workerName']['korean'] : null,
          currentLangCode: _currentLangCode,
          showComparisonView: _showComparisonView,
          titleForReading: _translations.getTitleForReading('1. 근로자명', _currentLangCode),
        ),

        // 모든 섹션 정보 동적으로 표시
        for (int i = 0; i < widget.contract['sections'].length; i++)
          _uiComponents.buildInfoSection(
            title: '${i + 2}. ${widget.contract['sections'][i]['title']}',
            content: widget.contract['sections'][i]['content'][
            _currentLangCode == 'en' ? 'english' :
            _currentLangCode == 'vi' ? 'vietnamese' : 'korean'
            ],
            showSpeakButton: _currentLangCode != 'ko',
            originalContent: _currentLangCode != 'ko' ? widget.contract['sections'][i]['content']['korean'] : null,
            currentLangCode: _currentLangCode,
            showComparisonView: _showComparisonView,
            titleForReading: _translations.getTitleForReading(
                '${i + 2}. ${widget.contract['sections'][i]['title']}',
                _currentLangCode
            ),
          ),
      ],
    );
  }
}