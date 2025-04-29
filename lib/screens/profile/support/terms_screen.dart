import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 이용약관 데이터
    final List<Map<String, String>> termsData = [
      {
        'title': '제1조 (목적)',
        'content': '이 약관은 에이아이에스 주식회사(이하 "회사")가 제공하는 Voice Contract 서비스(이하 "서비스")의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.'
      },
      {
        'title': '제2조 (정의)',
        'content': '1. "서비스"란 회사가 제공하는 근로계약서 작성 및 번역 서비스를 의미합니다.\n2. "이용자"란 이 약관에 따라 서비스를 이용하는 회원 및 비회원을 말합니다.'
      },
      {
        'title': '제3조 (약관의 효력 및 변경)',
        'content': '1. 회사는 이 약관의 내용을 이용자가 쉽게 알 수 있도록 서비스 초기 화면에 게시합니다.\n2. 회사는 필요한 경우 약관을 변경할 수 있으며, 변경된 약관은 서비스 내에 공지함으로써 효력이 발생합니다.'
      },
      {
        'title': '제4조 (개인정보 보호)',
        'content': '회사는 이용자의 개인정보 보호를 위해 개인정보 처리방침을 수립하고 준수합니다. 자세한 내용은 서비스 내 개인정보 처리방침을 참고하시기 바랍니다.'
      },
      {
        'title': '제5조 (서비스 이용)',
        'content': '1. 서비스 이용은 회사의 업무상 또는 기술상 특별한 지장이 없는 한 연중무휴, 1일 24시간을 원칙으로 합니다.\n2. 회사는 서비스의 제공에 필요한 경우 정기점검을 실시할 수 있으며, 이러한 경우 사전에 공지합니다.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('이용약관'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        itemCount: termsData.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final term = termsData[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                backgroundColor: Colors.white,
                collapsedBackgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  term['title']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.description_outlined,
                      color: Colors.indigo,
                      size: 20,
                    ),
                  ),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade50,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      term['content']!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}