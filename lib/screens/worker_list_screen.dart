import 'package:flutter/material.dart';
import 'contract_detail_screen.dart';
import 'package:animate_do/animate_do.dart';

class WorkerListScreen extends StatefulWidget {
  final String langCode;
  final List<dynamic> contracts;
  final String flagImagePath;

  const WorkerListScreen({
    Key? key,
    required this.langCode,
    required this.contracts,
    required this.flagImagePath,
  }) : super(key: key);

  @override
  _WorkerListScreenState createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
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

  String getLanguageName() {
    switch (widget.langCode) {
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

  Color getLanguageColor() {
    switch (widget.langCode) {
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
    final workerGroups = groupContractsByWorker(widget.contracts);
    final languageColor = getLanguageColor();

    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildHeader(context, languageColor),
          _buildLanguageInfo(languageColor, getLanguageName()),
          Expanded(
            child: workerGroups.isEmpty
                ? _buildEmptyState(languageColor)
                : _buildWorkerList(context, workerGroups, widget.langCode),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      title: FadeIn(
        child: const Text(
          '근로계약서 목록',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
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
    );
  }

  Widget _buildHeader(BuildContext context, Color languageColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo, Colors.indigoAccent],
        ),
      ),
      child: FadeInDown(
        delay: const Duration(milliseconds: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '저장된 근로계약서',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '선택한 언어로 번역되어 근로계약서 상세 내용을 확인할 수 있습니다.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageInfo(Color languageColor, String languageName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: languageColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(  // ClipOval 추가
                  child: Image.asset(
                    widget.flagImagePath,
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  languageName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '선택된 언어로 계약서가 표시됩니다.',
              style: TextStyle(
                color: languageColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerList(BuildContext context, Map<String, List<dynamic>> workerGroups, String langCode) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView.builder(
        itemCount: workerGroups.length,
        itemBuilder: (context, index) {
          final koreanName = workerGroups.keys.elementAt(index);
          final workerContract = workerGroups[koreanName]!.first;

          return FadeInUp(
            delay: Duration(milliseconds: 50 + index * 50),
            child: _buildWorkerContractItem(context, workerContract, langCode),
          );
        },
      ),
    );
  }

  Widget _buildWorkerContractItem(BuildContext context, dynamic workerContract, String langCode) {
    final languageColor = getLanguageColor();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ContractDetailScreen(
              langCode: langCode,
              contract: workerContract,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
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
            transitionDuration: const Duration(milliseconds: 100),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: languageColor.withOpacity(0.9),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: languageColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
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
                      fontWeight: FontWeight.w900,
                      color: languageColor,
                    ),
                  ),
                  if (langCode != 'ko') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: languageColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            langCode == 'en' ? 'EN' : langCode == 'vi' ? 'VI' : 'KO',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: languageColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            workerContract['workerName'][
                            langCode == 'en' ? 'english' :
                            langCode == 'vi' ? 'vietnamese' : 'korean'
                            ],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
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
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color languageColor) {
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
            '저장된 근로계약서가 없습니다.',
            style: TextStyle(
              fontSize: 20,
              color: languageColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '새 근로계약서를 작성해보세요.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}