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

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  final FlutterTts flutterTts = FlutterTts();

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage(widget.langCode == 'vi' ? 'vi-VN' :
    widget.langCode == 'en' ? 'en-US' : 'ko-KR');
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  Widget _buildInfoSection(String title, String content, bool showSpeakButton) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,  // 타이틀 (항상 한글)
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: Colors.orangeAccent),
              onPressed: () => _speak(title),  // 타이틀 읽기
              tooltip: "제목 읽기",
              iconSize: 20,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.indigoAccent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  content,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              if (showSpeakButton)
                Padding(
                  padding: const EdgeInsets.only(left: 8), // 아이콘과 텍스트 간격 조정
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.indigoAccent, width: 1),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: Colors.green),
                      onPressed: () => _speak(content),
                      tooltip: "내용 읽기",
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Text('근로계약서 작성내용',
          style: const TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.black),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 근로자명 정보 표시
            _buildInfoSection(
                '1. 근로자명',
                widget.contract['workerName'][
                widget.langCode == 'en' ? 'english' :
                widget.langCode == 'vi' ? 'vietnamese' : 'korean'
                ],
                widget.langCode != 'ko'
            ),

            // 모든 섹션 정보 동적으로 표시
            for (int i = 0; i < widget.contract['sections'].length; i++)
              _buildInfoSection(
                  '${i + 2}. ${widget.contract['sections'][i]['title']}',
                  widget.contract['sections'][i]['content'][
                  widget.langCode == 'en' ? 'english' :
                  widget.langCode == 'vi' ? 'vietnamese' : 'korean'
                  ],
                  widget.langCode != 'ko'
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
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
          return _buildPdfContent(getFont: () => widget.langCode == 'ko' ? koreanTtf : regularTtf);
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
        en: 'Labor Contract',
        vi: 'Hợp đồng lao động',
        ko: '근로계약서'
    );

    return pw.Stack(
      children: [
        // 📌 기존 계약 내용 (왼쪽 정렬)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  font: getFont(),
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 15),

            // 근로자명 정보
            pw.Text(
              _getLocalizedText(en: 'Worker Name', vi: 'Tên người lao động', ko: '근로자명'),
              style: pw.TextStyle(
                font: getFont(),
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
              ),
              child: pw.Text(
                widget.contract['workerName'][widget.langCode == 'en' ? 'english' :
                widget.langCode == 'vi' ? 'vietnamese' : 'korean'],
                style: pw.TextStyle(font: getFont()),
              ),
            ),
            pw.SizedBox(height: 15),

            // 📌 모든 계약 내용 추가
            if (widget.contract.containsKey('sections')) ...[
              for (int i = 0; i < widget.contract['sections'].length; i++) ...[
                pw.Text(
                  _getLocalizedText(
                      en: getSectionTitle(widget.contract['sections'][i]['title'], 'en'),
                      vi: getSectionTitle(widget.contract['sections'][i]['title'], 'vi'),
                      ko: widget.contract['sections'][i]['title']
                  ),
                  style: pw.TextStyle(
                    font: getFont(),
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                  ),
                  child: pw.Text(
                    widget.contract['sections'][i]['content'][widget.langCode == 'en' ? 'english' :
                    widget.langCode == 'vi' ? 'vietnamese' : 'korean'],
                    style: pw.TextStyle(font: getFont()),
                  ),
                ),
                pw.SizedBox(height: 15),
              ],
            ],
          ],
        ),

        // ✅ 오른쪽 아래에 서명 배치
        if (widget.contract['signature'] != null)
          pw.Positioned(
            bottom: 20, // 하단에서 20pt 위로
            right: 20,  // 오른쪽에서 20pt 왼쪽으로
            child: pw.Container(
              width: 200,  // 서명 크기
              height: 100,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),  // 테두리 추가 (디버깅용)
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

  String getSectionTitle(String koreanTitle, String langCode) {
    final Map<String, Map<String, String>> translations = {
      '근로개시일': {'en': 'Start Date of Work', 'vi': 'Ngày bắt đầu làm việc'},
      '근무장소': {'en': 'Workplace', 'vi': 'Nơi làm việc'},
      '업무내용': {'en': 'Job Description', 'vi': 'Nội dung công việc'},
      '근로시간': {'en': 'Working Hours', 'vi': 'Thời gian làm việc'},
      '임금': {'en': 'Wages', 'vi': 'Tiền lương'},
      '휴일': {'en': 'Holidays', 'vi': 'Ngày nghỉ'},

    };

    if (translations.containsKey(koreanTitle) && translations[koreanTitle]!.containsKey(langCode)) {
      return translations[koreanTitle]![langCode]!;
    }

    return koreanTitle; // 번역이 없는 경우 원래 제목 반환
  }

  String _getLocalizedText({required String en, required String vi, required String ko}) {
    return widget.langCode == 'en' ? en :
    widget.langCode == 'vi' ? vi : ko;
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
    super.dispose();
  }
}