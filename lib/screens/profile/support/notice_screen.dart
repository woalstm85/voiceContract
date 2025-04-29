import 'package:flutter/material.dart';

class NoticeScreen extends StatelessWidget {
  const NoticeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 공지사항 예시 데이터
    final List<Map<String, dynamic>> notices = [
      {
        'title': '서비스 업데이트 안내',
        'date': '2025.02.20',
        'content': '음성 인식 기능이 개선되었습니다. 이제 더 정확한 인식이 가능합니다.'
      },
      {
        'title': '베트남어 번역 지원 확대',
        'date': '2025.02.15',
        'content': '베트남어 번역 지원 항목이 추가되었습니다.'
      },
      {
        'title': '서비스 오픈 안내',
        'date': '2025.02.01',
        'content': 'Voice Contract 서비스가 정식 오픈하였습니다.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        itemCount: notices.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final notice = notices[index];
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
                  notice['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  notice['date'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
                      Icons.announcement_outlined,
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
                      notice['content'],
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