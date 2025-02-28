import 'package:flutter/material.dart';
import 'contract_detail_screen.dart';

class WorkerListScreen extends StatelessWidget {
  final String langCode;
  final List<dynamic> contracts;

  const WorkerListScreen({
    Key? key,
    required this.langCode,
    required this.contracts,
  }) : super(key: key);

  Map<String, List<dynamic>> groupContractsByWorker(List<dynamic> contracts) {
    final groups = <String, List<dynamic>>{};

    for (var contract in contracts) {
      final workerName = contract['workerName']['korean'] as String;
      if (!groups.containsKey(workerName)) {
        groups[workerName] = [];
      }
      groups[workerName]!.add(contract);
    }
    return groups;
  }

  // 언어 코드에 따른 언어명 반환
  String getLanguageName() {
    switch (langCode) {
      case 'ko':
        return '한국어';
      case 'en':
        return '영어 (English)';
      case 'vi':
        return '베트남어 (Tiếng Việt)';
      default:
        return '한국어';
    }
  }

  // 언어 코드에 따른 색상 반환
  Color getLanguageColor() {
    switch (langCode) {
      case 'ko':
        return Colors.indigo;
      case 'en':
        return Colors.teal;
      case 'vi':
        return Colors.deepPurple;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workerGroups = groupContractsByWorker(contracts);
    final languageColor = getLanguageColor();

    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Text(
          '근로계약서 목록',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.indigo),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.indigo),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          // 상단 설명 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: BoxDecoration(
              color: Colors.indigo,
              border: Border.all(
                color: Colors.indigo,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '저장된 근로계약서',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '선택한 언어로 번역되어 근로계약서 상세 내용을 확인할 수 있습니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // 선택된 언어 표시 영역 (새로 추가)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: languageColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: languageColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: languageColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.language, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        getLanguageName(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '선택된 언어로 계약서가 표시됩니다',
                    style: TextStyle(
                      color: languageColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 근로자 목록
          Expanded(
            child: workerGroups.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: workerGroups.length,
              itemBuilder: (context, index) {
                final koreanName = workerGroups.keys.elementAt(index);
                final workerContract = workerGroups[koreanName]!.first;

                return _buildWorkerContractItem(context, workerContract, langCode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerContractItem(BuildContext context, dynamic workerContract, String langCode) {
    final languageColor = getLanguageColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: languageColor.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: languageColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => ContractDetailScreen(
                  langCode: langCode,
                  contract: workerContract,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0); // 아래에서 위로 올라오는 효과
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;

                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: languageColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person, size: 28, color: languageColor),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workerContract['workerName']['korean'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: languageColor,
                        ),
                      ),
                      if (langCode != 'ko') ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: languageColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                langCode == 'en' ? 'EN' : langCode == 'vi' ? 'VI' : 'KO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: languageColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                workerContract['workerName'][
                                langCode == 'en' ? 'english' :
                                langCode == 'vi' ? 'vietnamese' : 'korean'
                                ],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: languageColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final languageColor = getLanguageColor();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.document_scanner_outlined,
            size: 80,
            color: languageColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '저장된 근로계약서가 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: languageColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새 근로계약서를 작성해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}