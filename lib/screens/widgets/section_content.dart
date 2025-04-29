import 'package:flutter/material.dart';
import '../models/contract_section.dart';

/// 계약서 섹션의 내용 위젯 (언어별 텍스트와 컨트롤)
class SectionContent extends StatelessWidget {
  final ContractSection section;
  final bool isRecording;
  final bool isPlaying;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onTogglePlayback;
  final Function(String, String) onSpeakText;

  const SectionContent({
    Key? key,
    required this.section,
    required this.isRecording,
    required this.isPlaying,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onTogglePlayback,
    required this.onSpeakText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                onPressed: isRecording ? onStopRecording : onStartRecording,
                icon: Icon(isRecording ? Icons.stop : Icons.mic, color: Colors.white),
                label: Text(
                  isRecording ? '녹음 중지' : '녹음 시작',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRecording ? Colors.red : Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
              if (hasAudio) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onTogglePlayback,
                  icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow, color: Colors.white),
                  label: Text(
                    isPlaying ? '중지' : '재생',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPlaying ? Colors.red : Colors.indigo,
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

  // 언어별 텍스트 섹션 빌드
  Widget _buildLanguageSection(String title, String content, String langCode) {
    final isStatusMessage = content == '듣고 있습니다...' ||
        content.contains('오류:') ||
        content.contains('초기화되지 않음') ||
        content == '처리 중...';

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
                onPressed: () => onSpeakText(content, langCode),
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
}