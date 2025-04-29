import 'package:flutter/material.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<String> categories = [
    '이용 방법', '계정 관리', '사업자 정보', '기타 문의'
  ];

  final List<List<Map<String, String>>> faqData = [
    // 이용 방법
    [
      {
        "question": "어떤 언어로 번역이 가능한가요?",
        "answer": "현재 한국어, 영어, 베트남어 번역을 지원하고 있습니다. 추후 더 많은 언어를 추가할 예정입니다."
      },
      {
        "question": "계약서 작성 후 수정이 가능한가요?",
        "answer": "네, 작성내역 메뉴에서 이전에 작성한 계약서를 확인하고 수정할 수 있습니다."
      },
      {
        "question": "음성 인식이 잘 되지 않을 때는 어떻게 해야 하나요?",
        "answer": "조용한 환경에서 천천히 또박또박 말씀해주시면 인식률이 향상됩니다. 그래도 인식이 안 될 경우 직접 텍스트를 입력하실 수도 있습니다."
      },
    ],
    // 계정 관리
    [
      {
        "question": "비밀번호를 잊어버렸어요.",
        "answer": "로그인 화면에서 '비밀번호 찾기'를 통해 이메일로 인증 후 비밀번호를 재설정할 수 있습니다."
      },
      {
        "question": "계정 정보를 변경하고 싶어요.",
        "answer": "프로필 화면의 '계정 관리' 탭에서 이름, 이메일 등의 기본 정보를 변경할 수 있습니다."
      },
      {
        "question": "로그아웃은 어떻게 하나요?",
        "answer": "프로필 화면의 '계정 관리' 탭에서 로그아웃 버튼을 선택하시면 로그아웃이 가능합니다."
      },
    ],
    // 사업자 정보
    [
      {
        "question": "사업자 등록 증명은 어떻게 하나요?",
        "answer": "사업자 정보 관리 화면에서 사업자등록증을 촬영하거나 업로드하여 등록할 수 있습니다. 검증 후 승인이 완료됩니다."
      },
      {
        "question": "등록한 사업자 정보를 변경하고 싶어요.",
        "answer": "사업자 정보 관리 화면에서 '정보 수정' 버튼을 통해 변경할 수 있으며, 변경된 정보는 재검증이 필요할 수 있습니다."
      },
    ],
    // 기타 문의
    [
      {
        "question": "작성한 계약서를 인쇄할 수 있나요?",
        "answer": "네, 작성이 완료된 계약서는 PDF로 저장하여 인쇄하거나 이메일로 공유할 수 있습니다."
      },
      {
        "question": "서비스에 오류가 있는 것 같아요.",
        "answer": "문의하기 화면에서 오류 사항을 자세히 기재해 주시면 빠르게 확인 후 해결해 드리겠습니다. 스크린샷이나 오류 발생 과정을 함께 보내주시면 더욱 빠른 해결이 가능합니다."
      },
    ],
  ];

  int _selectedCategoryIndex = 0;
  Set<int> _expandedItems = {};

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: categories.length,
      initialIndex: _selectedCategoryIndex,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            '자주 묻는 질문',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.indigo,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: TabBar(
              tabs: categories.map((category) => Tab(text: category)).toList(),
              labelColor: Colors.indigo,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo,
              indicatorWeight: 3,
              onTap: (index) {
                setState(() {
                  _selectedCategoryIndex = index;
                  _expandedItems.clear(); // 탭 변경 시 펼친 항목 초기화
                });
              },
            ),
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: List.generate(
              categories.length,
                  (categoryIndex) => buildFAQList(categoryIndex),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFAQList(int categoryIndex) {
    final List<Map<String, String>> currentCategoryFAQs = faqData[categoryIndex];

    return currentCategoryFAQs.isEmpty
        ? Center(
      child: Text(
        '등록된 FAQ가 없습니다.',
        style: TextStyle(color: Colors.grey[600]),
      ),
    )
        : ListView.separated(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        top: 12,
      ),
      itemCount: currentCategoryFAQs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => buildFAQItem(currentCategoryFAQs[index], index, categoryIndex),
    );
  }

  Widget buildFAQItem(Map<String, String> faq, int index, int categoryIndex) {
    final itemKey = categoryIndex * 100 + index; // 카테고리별로 고유한 키 생성
    final bool isExpanded = _expandedItems.contains(itemKey);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: isExpanded ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpanded ? Colors.indigo : Colors.grey.shade200,
          width: isExpanded ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // 질문 부분
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedItems.remove(itemKey);
                  } else {
                    _expandedItems.add(itemKey);
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isExpanded ? Colors.indigo.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: isExpanded ? Radius.zero : const Radius.circular(12),
                    bottomRight: isExpanded ? Radius.zero : const Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? Colors.indigo
                            : Colors.indigo.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'Q',
                          style: TextStyle(
                            color: isExpanded ? Colors.white : Colors.indigo,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            faq["question"]!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isExpanded ? FontWeight.bold : FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          if (!isExpanded)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '답변 보기',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? Colors.indigo.withOpacity(0.1)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isExpanded ? Icons.remove : Icons.add,
                          size: 16,
                          color: isExpanded ? Colors.indigo : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 답변 부분 (펼쳐졌을 때만 표시)
            if (isExpanded)
              Container(
                width: double.infinity,
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          faq["answer"]!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.6,
                          ),
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
}