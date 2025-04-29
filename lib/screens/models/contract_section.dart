/// 계약서의 각 섹션을 나타내는 모델 클래스
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

  // 객체의 깊은 복사본 생성
  ContractSection copy() {
    return ContractSection(
      id: id,
      title: title,
      koreanText: koreanText,
      englishText: englishText,
      vietnameseText: vietnameseText,
      audioFilePath: audioFilePath,
      isCompleted: isCompleted,
    );
  }

  // JSON 변환 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': {
        'korean': koreanText,
        'english': englishText,
        'vietnamese': vietnameseText,
      },
      'audioFile': audioFilePath,
      'isCompleted': isCompleted,
    };
  }

  // JSON에서 객체 생성
  factory ContractSection.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>;

    return ContractSection(
      id: json['id'],
      title: json['title'],
      koreanText: content['korean'] ?? '',
      englishText: content['english'] ?? '',
      vietnameseText: content['vietnamese'] ?? '',
      audioFilePath: json['audioFile'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}