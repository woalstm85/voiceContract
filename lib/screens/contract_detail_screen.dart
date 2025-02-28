import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';

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
  final FlutterTts flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();
  late TabController _languageTabController;
  String _currentLangCode = '';
  bool _showComparisonView = false;

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _currentLangCode = widget.langCode;
    _initTts();
    _initLanguageTabs();
  }

  void _initLanguageTabs() {
    _languageTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _currentLangCode == 'ko' ? 0 : _currentLangCode == 'en' ? 1 : 2,
    );

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
        _initTts();
      }
    });
  }

  // 스크롤 진행 상태 업데이트 메소드 제거됨

  Future<void> _initTts() async {
    await flutterTts.setLanguage(_currentLangCode == 'vi' ? 'vi-VN' :
    _currentLangCode == 'en' ? 'en-US' : 'ko-KR');
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  // 언어 이름 가져오기
  String _getLanguageName(String code) {
    switch (code) {
      case 'ko':
        return '한국어';
      case 'en':
        return '영어';
      case 'vi':
        return '베트남어';
      default:
        return '한국어';
    }
  }

  // 언어 색상 가져오기
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

  // 비교 보기 토글
  void _toggleComparisonView() {
    setState(() {
      _showComparisonView = !_showComparisonView;
    });
  }

// 버튼형 탭 (TabBar 대신 버튼으로 교체)
  Widget _buildLanguageTabButton(int index, String label) {
    bool isSelected = _languageTabController.index == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _languageTabController.animateTo(index);
          });
        },
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? _getLanguageColor(_currentLangCode) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

// 2. _buildInfoSection 메서드 수정 (화면에는 한국어로 표시, 읽기만 번역)
  Widget _buildInfoSection(String title, String content, bool showSpeakButton, {String? originalContent}) {
    // 읽기용 번역된 타이틀
    final String titleForReading = _getTitleForReading(title);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getLanguageColor(_currentLangCode).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getLanguageColor(_currentLangCode).withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title, // 항상 한국어 타이틀 표시
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getLanguageColor(_currentLangCode),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.volume_up_rounded, color: _getLanguageColor(_currentLangCode).withOpacity(0.7)),
                  onPressed: () => _speak(titleForReading), // 번역된 제목으로 읽기
                  tooltip: "제목 읽기",
                  iconSize: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 비교 보기가 활성화된 경우 원본(한국어) 내용 먼저 표시
            if (_showComparisonView && _currentLangCode != 'ko' && originalContent != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.indigo,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '원본',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      originalContent,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getLanguageColor(_currentLangCode).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getLanguageColor(_currentLangCode).withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getLanguageColor(_currentLangCode),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '번역본',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            content,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (showSpeakButton)
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getLanguageColor(_currentLangCode).withOpacity(0.1),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.volume_up_rounded, color: _getLanguageColor(_currentLangCode)),
                              onPressed: () => _speak(content),
                              tooltip: "내용 읽기",
                              iconSize: 20,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 일반 보기 모드
              Row(
                children: [
                  Expanded(
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (showSpeakButton)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getLanguageColor(_currentLangCode).withOpacity(0.1),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.volume_up_rounded, color: _getLanguageColor(_currentLangCode)),
                        onPressed: () => _speak(content),
                        tooltip: "내용 읽기",
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contractDate = widget.contract.containsKey('date')
        ? _formatDate(widget.contract['date'])
        : '날짜 정보 없음';

    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: _getLanguageColor(_currentLangCode),
        title: const Text(
          '근로계약서 작성내용',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 앱바 하단에 언어 선택과 진행 상태 표시 (고정)
          Container(
            color: _getLanguageColor(_currentLangCode),
            child: Column(
              children: [
                // 언어 선택 탭 (개선된 UI, 밑줄 제거)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      _buildLanguageTabButton(0, '한국어'),
                      const SizedBox(width: 4),
                      _buildLanguageTabButton(1, '영어'),
                      const SizedBox(width: 4),
                      _buildLanguageTabButton(2, '베트남어'),
                    ],
                  ),
                ),

                // 비교 보기 버튼과 날짜 정보
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentLangCode != 'ko')
                        OutlinedButton.icon(
                          onPressed: _toggleComparisonView,
                          icon: Icon(
                            _showComparisonView ? Icons.compare_arrows : Icons.compare,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: Text(
                            _showComparisonView ? '일반 보기' : '비교 보기',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                        )
                      else
                        const SizedBox(), // 한국어일 때는 비교 버튼 없음
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            contractDate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 계약서 내용 (Expanded로 남은 공간 차지)
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 근로자명 정보 표시
                  _buildInfoSection(
                    '1. 근로자명',
                    widget.contract['workerName'][
                    _currentLangCode == 'en' ? 'english' :
                    _currentLangCode == 'vi' ? 'vietnamese' : 'korean'
                    ],
                    _currentLangCode != 'ko',
                    originalContent: _currentLangCode != 'ko' ? widget.contract['workerName']['korean'] : null,
                  ),

                  // 모든 섹션 정보 동적으로 표시
                  for (int i = 0; i < widget.contract['sections'].length; i++)
                    _buildInfoSection(
                      '${i + 2}. ${widget.contract['sections'][i]['title']}',
                      widget.contract['sections'][i]['content'][
                      _currentLangCode == 'en' ? 'english' :
                      _currentLangCode == 'vi' ? 'vietnamese' : 'korean'
                      ],
                      _currentLangCode != 'ko',
                      originalContent: _currentLangCode != 'ko' ? widget.contract['sections'][i]['content']['korean'] : null,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _getLanguageColor(_currentLangCode),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _generatePDF,
            child: const Text(
              'PDF 생성',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 개선된 언어 탭 위젯
  Widget _buildLanguageTab(int index, String label) {
    bool isSelected = _languageTabController.index == index;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(3), // 각 탭 사이의 간격
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? _getLanguageColor(_currentLangCode) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generatePDF() async {
    // 폰트 로드
    final fontKorean = await rootBundle.load('assets/fonts/NanumGothic-Regular.ttf');
    final koreanTtf = pw.Font.ttf(fontKorean);

    final fontRegular = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final regularTtf = pw.Font.ttf(fontRegular);

    final pdf = pw.Document();
    final koreanName = widget.contract['workerName']['korean'];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildPdfContent(getFont: () => _currentLangCode == 'ko' ? koreanTtf : regularTtf);
        },
      ),
    );
    try {
      // 플랫폼별 PDF 저장 로직 분리
      if (Platform.isAndroid) {
        await _savePDFForAndroid(pdf, koreanName);
      } else if (Platform.isIOS) {
        await _savePDFForIOS(pdf, koreanName);
      }
    } catch (e) {
      _showErrorSnackBar('PDF 저장 중 오류가 발생했습니다');
      print('PDF 저장 오류: $e');
    }
  }

  pw.Widget _buildPdfContent({required pw.Font Function() getFont}) {
    String title = _getLocalizedText(
        en: 'Standard Labor Contract',
        vi: 'Hợp đồng lao động chuẩn',
        ko: '근로계약서'
    );

    return pw.Stack(
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 타이틀 영역
            pw.Center(
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  font: getFont(),
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 30),

            // 근로자 정보 섹션
            _buildSectionWithNumberedTitle(
              getFont: getFont,
              number: '1',
              titleKo: '근로자명',
              titleEn: "Name of Employee",
              titleVi: 'Họ và tên người lao động',
              content: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    widget.contract['workerName'][_currentLangCode == 'en' ? 'english' :
                    _currentLangCode == 'vi' ? 'vietnamese' : 'korean'],
                    style: pw.TextStyle(
                      font: getFont(),
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 계약 섹션들
            if (widget.contract.containsKey('sections'))
              for (int i = 0; i < widget.contract['sections'].length; i++)
                _buildSectionWithNumberedTitle(
                  getFont: getFont,
                  number: '${i + 2}',
                  titleKo: widget.contract['sections'][i]['title'],
                  titleEn: getSectionTitle(widget.contract['sections'][i]['title'], 'en'),
                  titleVi: getSectionTitle(widget.contract['sections'][i]['title'], 'vi'),
                  content: pw.Text(
                    widget.contract['sections'][i]['content'][_currentLangCode == 'en' ? 'english' :
                    _currentLangCode == 'vi' ? 'vietnamese' : 'korean'],
                    style: pw.TextStyle(
                      font: getFont(),
                      fontSize: 14,
                    ),
                  ),
                ),
          ],
        ),

        // 서명 영역 - 페이지 오른쪽 하단에 고정
        if (widget.contract['signature'] != null)
          pw.Positioned(
            bottom: 20,
            right: 20,
            child: pw.Container(
              width: 200,
              height: 100,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Image(
                pw.MemoryImage(base64Decode(widget.contract['signature'])),
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
      ],
    );
  }

// 섹션 타이틀 메서드 수정
  pw.Widget _buildSectionWithNumberedTitle({
    required pw.Font Function() getFont,
    required String number,
    required String titleKo,
    required String titleEn,
    required String titleVi,
    required pw.Widget content,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              '$number. ',
              style: pw.TextStyle(
                font: getFont(),
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              _getLocalizedText(en: titleEn, vi: titleVi, ko: titleKo),
              style: pw.TextStyle(
                font: getFont(),
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          child: content,
        ),
      ],
    );
  }

  String _getTitleForReading(String koreanTitle) {
    // 숫자와 제목 분리 (예: "1. 근로자명" -> 숫자="1", 제목="근로자명")
    final parts = koreanTitle.split('. ');
    if (parts.length != 2) return koreanTitle;

    final number = parts[0];
    final title = parts[1];

    // 제목 번역 맵
    final Map<String, Map<String, String>> translations = {
      '근로자명': {'en': 'Name of Employee', 'vi': 'Họ và tên người lao động'},
      '근로개시일': {'en': 'Employment Start Date', 'vi': 'Ngày bắt đầu làm việc'},
      '근무장소': {'en': 'Place of Employment', 'vi': 'Địa điểm làm việc'},
      '업무내용': {'en': 'Job Description', 'vi': 'Nội dung công việc'},
      '근로시간': {'en': 'Working Hours', 'vi': 'Thời gian làm việc'},
      '임금': {'en': 'Payment', 'vi': 'Tiền lương'},
      '휴일': {'en': 'Holidays', 'vi': 'Ngày nghỉ'}
    };

    // 현재 언어에 맞는 번역된 제목 가져오기 (영어나 베트남어일 경우만)
    if (_currentLangCode != 'ko' && translations.containsKey(title)) {
      final translatedTitle = translations[title]?[_currentLangCode];
      if (translatedTitle != null) {
        return '$number. $translatedTitle';
      }
    }

    return koreanTitle; // 한국어일 경우 그대로 반환
  }

  String getSectionTitle(String koreanTitle, String langCode) {
    final Map<String, Map<String, String>> translations = {
      '근로개시일': { 'en': 'Employment Start Date', 'vi': 'Ngày bắt đầu làm việc' },
      '근무장소': { 'en': 'Place of Employment', 'vi': 'Địa điểm làm việc' },
      '업무내용': { 'en': 'Job Description', 'vi': 'Nội dung công việc' },
      '근로시간': { 'en': 'Working Hours', 'vi': 'Thời gian làm việc' },
      '임금': { 'en': 'Payment', 'vi': 'Tiền lương' },
      '휴일': { 'en': 'Holidays', 'vi': 'Ngày nghỉ' }
    };

    if (translations.containsKey(koreanTitle) && translations[koreanTitle]!.containsKey(langCode)) {
      return translations[koreanTitle]![langCode]!;
    }

    return koreanTitle; // 번역이 없는 경우 원래 제목 반환
  }

  String _getLocalizedText({required String en, required String vi, required String ko}) {
    return _currentLangCode == 'en' ? en :
    _currentLangCode == 'vi' ? vi : ko;
  }
  Future<void> _savePDFForAndroid(pw.Document pdf, String koreanName) async {
    final downloadDir = Directory('/storage/emulated/0/Download');
    final contractDir = Directory('${downloadDir.path}/Labor Contract/$koreanName');

    await contractDir.create(recursive: true);

    final file = File('${contractDir.path}/근로계약서.pdf');
    await file.writeAsBytes(await pdf.save());

    _showSuccessSnackBar('PDF가 $koreanName 폴더에 저장되었습니다');

    try {
      await OpenFile.open(file.path);
    } catch (openError) {
      _showWarningSnackBar('PDF 파일을 열 수 없습니다. 다운로드 폴더를 확인해주세요.');
      print('파일 열기 오류: $openError');
    }
  }

  Future<void> _savePDFForIOS(pw.Document pdf, String koreanName) async {
    final output = await getApplicationDocumentsDirectory();
    final contractDir = Directory('${output.path}/Labor Contract');
    await contractDir.create(recursive: true);

    final fileName = '${koreanName}_근로계약서.pdf';
    final file = File('${contractDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    _showSuccessSnackBar('PDF가 생성되었습니다');

    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '근로계약서 PDF',
      );
    } catch (shareError) {
      _showWarningSnackBar('PDF 파일 공유 중 오류가 발생했습니다');
      print('파일 공유 오류: $shareError');
    }
  }

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
    // 기존 스낵바가 있다면 먼저 제거
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
    // 기존 스낵바가 있다면 먼저 제거
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

  @override
  void dispose() {
    flutterTts.stop();
    _scrollController.dispose();
    _languageTabController.dispose();
    super.dispose();
  }
}