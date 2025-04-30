import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';

/// PDF 생성 및 저장을 담당하는 클래스
class ContractPDFGenerator {
  // 콜백 함수들
  final Function(String) showSuccessSnackBar;
  final Function(String) showWarningSnackBar;
  final Function(String) showErrorSnackBar;
  final String Function({required String en, required String vi, required String ko, String? langCode}) getLocalizedText;
  final String Function(String, String) getSectionTitle;

  ContractPDFGenerator({
    required this.showSuccessSnackBar,
    required this.showWarningSnackBar,
    required this.showErrorSnackBar,
    required this.getLocalizedText,
    required this.getSectionTitle,
  });

  /// PDF 생성 메인 메소드
  Future<void> generatePDF({
    required BuildContext context,
    required Map<String, dynamic> contract,
    required String currentLangCode,
  }) async {
    try {
      // 폰트 로드
      final fontKorean = await rootBundle.load('assets/fonts/NanumGothic-Regular.ttf');
      final koreanTtf = pw.Font.ttf(fontKorean);

      final fontRegular = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final regularTtf = pw.Font.ttf(fontRegular);

      final pdf = pw.Document();
      final koreanName = contract['workerName']['korean'];

      // PDF 페이지 추가
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildPdfContent(
              contract: contract,
              currentLangCode: currentLangCode,
              getFont: () => currentLangCode == 'ko' ? koreanTtf : regularTtf,
            );
          },
        ),
      );

      // 플랫폼별 PDF 저장 로직 분리
      if (Platform.isAndroid) {
        await _savePDFForAndroid(pdf, koreanName);
      } else if (Platform.isIOS) {
        await _savePDFForIOS(pdf, koreanName);
      }
    } catch (e) {
      showErrorSnackBar('PDF 생성 중 오류가 발생했습니다');
      print('PDF 생성 오류: $e');
    }
  }

  /// PDF 내용 생성
  pw.Widget _buildPdfContent({
    required Map<String, dynamic> contract,
    required String currentLangCode,
    required pw.Font Function() getFont,
  }) {
    // 제목 텍스트 가져오기
    String title = getLocalizedText(
      en: 'Standard Labor Contract',
      vi: 'Hợp đồng lao động chuẩn',
      ko: '근로계약서',
      langCode: currentLangCode,
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
            _buildPdfSection(
              contract: contract,
              getFont: getFont,
              number: '1',
              titleKo: '근로자명',
              titleEn: "Name of Employee",
              titleVi: 'Họ và tên người lao động',
              currentLangCode: currentLangCode,
              content: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    contract['workerName'][currentLangCode == 'en' ? 'english' :
                    currentLangCode == 'vi' ? 'vietnamese' : 'korean'],
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
            if (contract.containsKey('sections'))
              for (int i = 0; i < contract['sections'].length; i++)
                _buildPdfSection(
                  contract: contract,
                  getFont: getFont,
                  number: '${i + 2}',
                  titleKo: contract['sections'][i]['title'],
                  titleEn: getSectionTitle(contract['sections'][i]['title'], 'en'),
                  titleVi: getSectionTitle(contract['sections'][i]['title'], 'vi'),
                  currentLangCode: currentLangCode,
                  content: pw.Text(
                    contract['sections'][i]['content'][currentLangCode == 'en' ? 'english' :
                    currentLangCode == 'vi' ? 'vietnamese' : 'korean'],
                    style: pw.TextStyle(
                      font: getFont(),
                      fontSize: 14,
                    ),
                  ),
                ),
          ],
        ),

        // 서명 영역 - 페이지 오른쪽 하단에 고정
        if (contract['signature'] != null)
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
                pw.MemoryImage(base64Decode(contract['signature'])),
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
      ],
    );
  }

  /// PDF 섹션 위젯 생성
  pw.Widget _buildPdfSection({
    required Map<String, dynamic> contract,
    required pw.Font Function() getFont,
    required String number,
    required String titleKo,
    required String titleEn,
    required String titleVi,
    required String currentLangCode,
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
              getLocalizedText(
                en: titleEn,
                vi: titleVi,
                ko: titleKo,
                langCode: currentLangCode,
              ),
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

  /// Android용 PDF 저장 메소드
  Future<void> _savePDFForAndroid(pw.Document pdf, String koreanName) async {
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      final contractDir = Directory('${downloadDir.path}/Labor Contract/$koreanName');

      // 디렉토리 생성
      await contractDir.create(recursive: true);

      // 파일 저장
      final file = File('${contractDir.path}/근로계약서.pdf');
      await file.writeAsBytes(await pdf.save());

      showSuccessSnackBar('PDF가 $koreanName 폴더에 저장되었습니다');

      try {
        await OpenFile.open(file.path);
      } catch (openError) {
        showWarningSnackBar('PDF 파일을 열 수 없습니다. 다운로드 폴더를 확인해주세요.');
        print('파일 열기 오류: $openError');
      }
    } catch (e) {
      showErrorSnackBar('안드로이드 PDF 저장 오류: $e');
      print('안드로이드 PDF 저장 오류: $e');
    }
  }

  /// iOS용 PDF 저장 메소드
  Future<void> _savePDFForIOS(pw.Document pdf, String koreanName) async {
    try {
      final output = await getApplicationDocumentsDirectory();
      final contractDir = Directory('${output.path}/Labor Contract');
      await contractDir.create(recursive: true);

      final fileName = '${koreanName}_근로계약서.pdf';
      final file = File('${contractDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      showSuccessSnackBar('PDF가 생성되었습니다');

      try {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '근로계약서 PDF',
        );
      } catch (shareError) {
        showWarningSnackBar('PDF 파일 공유 중 오류가 발생했습니다');
        print('파일 공유 오류: $shareError');
      }
    } catch (e) {
      showErrorSnackBar('iOS PDF 저장 오류: $e');
      print('iOS PDF 저장 오류: $e');
    }
  }
}