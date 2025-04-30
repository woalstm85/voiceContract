import 'package:flutter/material.dart';
import '../models/contract_section.dart';

class SectionContent extends StatelessWidget {
  final ContractSection section;
  final bool isRecording;
  final bool isPlaying;
  final Function() onStartRecording;
  final Function() onStopRecording;
  final Function() onTogglePlayback;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 한국어 텍스트
        _buildLanguageSection(
          '한국어',
          section.koreanText,
          Colors.indigo,
          null,
        ),

        // 영어 텍스트
        _buildLanguageSection(
          '영어 (English)',
          section.englishText,
          Colors.teal,
          section.isCompleted && section.englishText.isNotEmpty
              ? _buildAudioButton(() => onSpeakText(section.englishText, 'en'), Colors.teal)
              : null,
        ),

        // 베트남어 텍스트
        _buildLanguageSection(
          '베트남어 (Tiếng Việt)',
          section.vietnameseText,
          Colors.deepPurple,
          section.isCompleted && section.vietnameseText.isNotEmpty
              ? _buildAudioButton(() => onSpeakText(section.vietnameseText, 'vi'), Colors.deepPurple)
              : null,
        ),

        // 녹음 및 재생 버튼
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildLanguageSection(
      String title,
      String content,
      Color color,
      Widget? trailingWidget,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 언어 타이틀
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6), // 여백 증가
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // 패딩 증가
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // 폰트 크기 증가
                  ),
                ),
              ),
              const Spacer(),
              if (trailingWidget != null) trailingWidget,
            ],
          ),
        ),
        // 내용 컨테이너 (높이 증가)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12), // 패딩 증가
          constraints: const BoxConstraints(
            minHeight: 60, // 최소 높이 증가
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 1.5, // 테두리 두께 증가
            ),
            borderRadius: BorderRadius.circular(8), // 라운드 코너 증가
          ),
          child: Text(
            content.isEmpty ? '아직 내용이 없습니다' : content,
            style: TextStyle(
              fontSize: 15, // 폰트 크기 증가
              color: content.isEmpty ? Colors.grey : Colors.black87,
              fontStyle: content.isEmpty ? FontStyle.italic : FontStyle.normal,
              height: 1.5, // 줄 간격 증가
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioButton(Function() onPressed, Color color) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
      ),
      child: IconButton(
        icon: Icon(
          Icons.volume_up_rounded,
          color: color,
          size: 20, // 아이콘 크기 증가
        ),
        onPressed: onPressed,
        tooltip: "내용 읽기",
        padding: const EdgeInsets.all(8), // 패딩 증가
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16), // 여백 증가
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 녹음 버튼
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(isRecording ? Icons.stop : Icons.mic, size: 20), // 아이콘 크기 증가
              label: Text(
                isRecording ? '녹음 중지' : '녹음 시작',
                style: const TextStyle(fontSize: 15), // 폰트 크기 증가
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: isRecording ? Colors.red : Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 12), // 패딩 증가
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // 라운드 코너 증가
                ),
                elevation: 2, // 그림자 증가
              ),
              onPressed: isRecording ? onStopRecording : onStartRecording,
            ),
          ),
          const SizedBox(width: 12), // 간격 증가
          // 재생 버튼
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow, size: 20), // 아이콘 크기 증가
              label: Text(
                isPlaying ? '중지' : '재생',
                style: const TextStyle(fontSize: 15), // 폰트 크기 증가
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: !section.isCompleted || section.audioFilePath.isEmpty
                    ? Colors.grey.withOpacity(0.5)
                    : (isPlaying ? Colors.orange : Colors.indigo),
                padding: const EdgeInsets.symmetric(vertical: 12), // 패딩 증가
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // 라운드 코너 증가
                ),
                elevation: 2, // 그림자 증가
              ),
              onPressed: (!section.isCompleted || section.audioFilePath.isEmpty)
                  ? null
                  : onTogglePlayback,
            ),
          ),
        ],
      ),
    );
  }
}