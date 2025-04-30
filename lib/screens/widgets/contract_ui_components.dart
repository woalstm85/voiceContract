import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

/// 계약서 상세 화면에서 사용하는 UI 컴포넌트들을 모아놓은 클래스
/// worker_list_screen과 동일한 디자인 시스템을 적용
class ContractUIComponents {
  // 콜백 함수들 (함수 참조를 저장)
  final Future<void> Function(String) speak;
  final void Function() toggleComparisonView;
  final Color Function(String) getLanguageColor;

  // UI 상수 - 일관된 디자인 시스템을 위한 값들
  final double _borderRadius = 12.0;
  final double _elevation = 8.0;
  final double _animationDuration = 300.0;
  final double _headerHeight = 44.0;

  ContractUIComponents({
    required this.speak,
    required this.toggleComparisonView,
    required this.getLanguageColor,
  });

  // ===== AppBar 관련 위젯 =====

  /// 상단 앱바 생성
  PreferredSizeWidget buildAppBar({
    required BuildContext context,
    required Color languageColor,
    required String currentLangCode,
  }) {
    return AppBar(
      centerTitle: true,
      backgroundColor: languageColor,
      scrolledUnderElevation: 0,
      elevation: 0,  // 그림자 제거
      title: FadeIn(  // 애니메이션 효과
        duration: Duration(milliseconds: _animationDuration.toInt()),
        child: const Text(
          '근로계약서 작성내용',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,  // worker_list_screen과 동일한 굵기
            fontSize: 20,
            letterSpacing: 1.2,  // worker_list_screen과 동일한 레터 스페이싱
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
        tooltip: '이전 화면으로 돌아가기',  // 접근성 향상
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          tooltip: '홈 화면으로 이동',  // 접근성 향상
        ),
      ],
    );
  }

  // ===== 언어 선택 헤더 관련 위젯 =====

  /// 언어 선택 헤더 위젯
  Widget buildLanguageHeader({
    required TabController languageTabController,
    required String contractDate,
    required String currentLangCode,
    required bool showComparisonView,
  }) {
    final languageColor = getLanguageColor(currentLangCode);

    return Container(
      decoration: BoxDecoration(
        color: languageColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(  // 노치 영역 안전하게 처리
        bottom: false,
        child: Column(
          children: [
            // 언어 선택 탭 버튼 영역
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: FadeIn(  // 애니메이션 효과
                duration: Duration(milliseconds: _animationDuration.toInt()),
                child: Row(
                  children: [
                    _buildLanguageTabButton(0, '한국어', languageTabController, currentLangCode),
                    const SizedBox(width: 4),
                    _buildLanguageTabButton(1, '영어', languageTabController, currentLangCode),
                    const SizedBox(width: 4),
                    _buildLanguageTabButton(2, '베트남어', languageTabController, currentLangCode),
                  ],
                ),
              ),
            ),

            // 비교 보기 버튼과 날짜 정보
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: FadeIn(  // 애니메이션 효과
                duration: Duration(milliseconds: _animationDuration.toInt()),
                delay: const Duration(milliseconds: 100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 한국어가 아닐 때만 비교 보기 버튼 표시
                    if (currentLangCode != 'ko')
                      OutlinedButton.icon(
                        onPressed: toggleComparisonView,
                        icon: Icon(
                          showComparisonView ? Icons.compare_arrows : Icons.compare,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: Text(
                          showComparisonView ? '일반 보기' : '비교 보기',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,  // 더 굵게 해서 가독성 향상
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_borderRadius / 2),  // 버튼 모서리 둥글게
                          ),
                        ),
                      )
                    else
                      const SizedBox(), // 한국어일 때는 비교 버튼 없음

                    // 날짜 표시
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(_borderRadius / 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            contractDate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 언어 탭 버튼 생성
  Widget _buildLanguageTabButton(
      int index,
      String label,
      TabController tabController,
      String currentLangCode
      ) {
    bool isSelected = tabController.index == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          tabController.animateTo(index);
        },
        child: Container(
          height: _headerHeight,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(_borderRadius),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? getLanguageColor(currentLangCode) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== 콘텐츠 섹션 관련 위젯 =====

  /// 정보 섹션 위젯 생성
  Widget buildInfoSection({
    required String title,
    required String content,
    required bool showSpeakButton,
    required String currentLangCode,
    required bool showComparisonView,
    required String titleForReading,
    String? originalContent,
    int? index,  // 애니메이션 지연을 위한 인덱스 추가
  }) {
    final Color languageColor = getLanguageColor(currentLangCode);
    // 인덱스에 기반한 애니메이션 지연 계산
    final delay = index != null ? Duration(milliseconds: 100 * index) : const Duration(milliseconds: 0);

    return FadeInUp(  // 애니메이션 효과
      duration: Duration(milliseconds: _animationDuration.toInt()),
      delay: delay,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_borderRadius),
          border: Border.all(
            color: languageColor.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: languageColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: _elevation,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(  // 내용이 컨테이너를 넘어가지 않도록
          borderRadius: BorderRadius.circular(_borderRadius),
          child: Material(  // 리플 효과를 위한 Material 위젯 추가
            color: Colors.transparent,
            child: InkWell(  // 터치 피드백 추가
              onTap: () => speak(titleForReading),  // 제목을 누르면 읽어주기
              splashColor: languageColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 영역
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title, // 항상 한국어 타이틀 표시
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: languageColor,
                              letterSpacing: 0.5,  // 가독성 향상
                            ),
                          ),
                        ),
                        // 음성 버튼을 포함하는 컨테이너
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: languageColor.withOpacity(0.1),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.volume_up_rounded, color: languageColor.withOpacity(0.7)),
                            onPressed: () => speak(titleForReading), // 번역된 제목으로 읽기
                            tooltip: "제목 읽기",
                            iconSize: 24,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),  // 제목과 내용 사이 구분선

                    // 비교 보기 모드일 때 (한국어 원본과 번역본 함께 표시)
                    if (showComparisonView && currentLangCode != 'ko' && originalContent != null) ...[
                      // 원본 내용 (한국어)
                      _buildComparisonBlock(
                        content: originalContent,
                        isOriginal: true,
                        languageColor: Colors.indigo,
                      ),
                      const SizedBox(height: 12),
                      // 번역된 내용
                      _buildComparisonBlock(
                        content: content,
                        isOriginal: false,
                        languageColor: languageColor,
                        showSpeakButton: showSpeakButton,
                        onSpeakPressed: () => speak(content),
                      ),
                    ] else ...[
                      // 일반 모드 (번역된 내용만 표시)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,  // 내용이 길 때 맨 위에서 시작
                        children: [
                          Expanded(
                            child: Text(
                              content,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.5,  // 줄 간격 증가로 가독성 향상
                              ),
                            ),
                          ),
                          if (showSpeakButton)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: languageColor.withOpacity(0.1),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.volume_up_rounded, color: languageColor),
                                  onPressed: () => speak(content),
                                  tooltip: "내용 읽기",
                                  iconSize: 20,
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 비교 보기 블록 위젯
  Widget _buildComparisonBlock({
    required String content,
    required bool isOriginal,
    required Color languageColor,
    bool showSpeakButton = false,
    VoidCallback? onSpeakPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: languageColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(_borderRadius / 2),
        border: Border.all(color: languageColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (원본 또는 번역본)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: languageColor,
                  borderRadius: BorderRadius.circular(_borderRadius / 3),
                ),
                child: Text(
                  isOriginal ? '원본' : '번역본',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 내용 영역
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,  // 내용이 길 때 맨 위에서 시작
            children: [
              Expanded(
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,  // 줄 간격 증가로 가독성 향상
                    fontWeight: isOriginal ? FontWeight.normal : FontWeight.w500,  // 번역본 텍스트 살짝 강조
                  ),
                ),
              ),
              // 음성 버튼 (옵션)
              if (showSpeakButton && onSpeakPressed != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: languageColor.withOpacity(0.1),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.volume_up_rounded, color: languageColor),
                      onPressed: onSpeakPressed,
                      tooltip: "내용 읽기",
                      iconSize: 20,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== 하단 버튼 관련 위젯 =====

  /// 하단 버튼 위젯
  Widget buildBottomButton({
    required Color languageColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
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
      child: FadeInUp(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: languageColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_borderRadius),
            ),
            elevation: _elevation / 2,  // 약간의 그림자 추가
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, size: 20),
              const SizedBox(width: 8),
              const Text(
                'PDF 생성',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 학습 정보 (empty state) 위젯 생성 - worker_list_screen과 유사한 스타일
  Widget buildEmptyState(Color languageColor, String message) {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 600),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: languageColor.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 20,
                color: languageColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Text(
                '근로계약서를 불러오는 중 오류가 발생했습니다.\n잠시 후 다시 시도해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}