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

  @override
  Widget build(BuildContext context) {
    final workerGroups = groupContractsByWorker(contracts);

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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.indigo.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.1),
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
              MaterialPageRoute(
                builder: (context) => ContractDetailScreen(
                  langCode: langCode,
                  contract: workerContract,
                ),
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
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person, size: 28, color: Colors.indigo),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workerContract['workerName']['korean'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      if (langCode != 'ko') ...[
                        const SizedBox(height: 4),
                        Text(
                          workerContract['workerName'][
                          langCode == 'en' ? 'english' :
                          langCode == 'vi' ? 'vietnamese' : 'korean'
                          ],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.indigo,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.document_scanner_outlined,
            size: 80,
            color: Colors.indigo[200],
          ),
          const SizedBox(height: 16),
          Text(
            '저장된 근로계약서가 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.indigo[400],
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