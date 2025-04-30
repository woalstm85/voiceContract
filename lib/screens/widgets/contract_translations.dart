/// 다국어 번역을 관리하는 클래스
/// 계약서 관련 모든 번역 로직을 담당합니다.
class ContractTranslations {
  // 제목 번역 맵
  final Map<String, Map<String, String>> _titleTranslations = {
    '근로자명': {'en': 'Name of Employee', 'vi': 'Họ và tên người lao động'},
    '근로개시일': {'en': 'Employment Start Date', 'vi': 'Ngày bắt đầu làm việc'},
    '근무장소': {'en': 'Place of Employment', 'vi': 'Địa điểm làm việc'},
    '업무내용': {'en': 'Job Description', 'vi': 'Nội dung công việc'},
    '근로시간': {'en': 'Working Hours', 'vi': 'Thời gian làm việc'},
    '임금': {'en': 'Payment', 'vi': 'Tiền lương'},
    '휴일': {'en': 'Holidays', 'vi': 'Ngày nghỉ'}
  };

  // PDF에 사용할 일반 텍스트 번역 맵
  final Map<String, Map<String, String>> _commonTranslations = {
    'title': {
      'en': 'Standard Labor Contract',
      'vi': 'Hợp đồng lao động chuẩn',
      'ko': '근로계약서'
    },
    'original': {
      'en': 'Original',
      'vi': 'Bản gốc',
      'ko': '원본'
    },
    'translation': {
      'en': 'Translation',
      'vi': 'Bản dịch',
      'ko': '번역본'
    },
  };

  /// 읽기용 타이틀 텍스트 가져오기
  /// 예: "1. 근로자명" -> "1. Name of Employee" (영어 선택 시)
  String getTitleForReading(String koreanTitle, String langCode) {
    // 숫자와 제목 분리 (예: "1. 근로자명" -> 숫자="1", 제목="근로자명")
    final parts = koreanTitle.split('. ');
    if (parts.length != 2) return koreanTitle;

    final number = parts[0];
    final title = parts[1];

    // 현재 언어에 맞는 번역된 제목 가져오기 (영어나 베트남어일 경우만)
    if (langCode != 'ko' && _titleTranslations.containsKey(title)) {
      final translatedTitle = _titleTranslations[title]?[langCode];
      if (translatedTitle != null) {
        return '$number. $translatedTitle';
      }
    }

    return koreanTitle; // 한국어일 경우 그대로 반환
  }

  /// PDF 섹션 제목 가져오기
  String getSectionTitle(String koreanTitle, String langCode) {
    if (_titleTranslations.containsKey(koreanTitle) &&
        _titleTranslations[koreanTitle]!.containsKey(langCode)) {
      return _titleTranslations[koreanTitle]![langCode]!;
    }

    return koreanTitle; // 번역이 없는 경우 원래 제목 반환
  }

  /// 현재 언어에 맞는 공통 텍스트 가져오기
  String getLocalizedText({
    required String en,
    required String vi,
    required String ko,
    String? langCode,
  }) {
    final code = langCode ?? 'ko';
    return code == 'en' ? en : code == 'vi' ? vi : ko;
  }

  /// 키를 사용해 미리 정의된 번역 텍스트 가져오기
  String getCommonText(String key, String langCode) {
    if (_commonTranslations.containsKey(key) &&
        _commonTranslations[key]!.containsKey(langCode)) {
      return _commonTranslations[key]![langCode]!;
    }

    // 번역이 없는 경우 한국어 버전 반환 또는 키 그대로 반환
    return _commonTranslations[key]?['ko'] ?? key;
  }

  /// 언어 이름 가져오기
  String getLanguageName(String code) {
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
}