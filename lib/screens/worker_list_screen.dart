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
      // workerName이 이제 Map 형태이므로 korean 키로 접근
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Text('근로자 목록',
          style: const TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [  // 여기에 홈 버튼 추가
          IconButton(
            icon: const Icon(Icons.home, color: Colors.black),
            onPressed: () {
              // 모든 화면을 팝하고 메인으로 이동
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: workerGroups.length,
        itemBuilder: (context, index) {
          final koreanName = workerGroups.keys.elementAt(index);
          final workerContract = workerGroups[koreanName]!.first;  // 첫 번째 계약 정보 가져오기


          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.black87, width: 1),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workerContract['workerName']['korean'],  // 한글 이름
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (langCode != 'ko') ...[  // 한글이 아닐 때만 번역된 이름 표시
                    const SizedBox(height: 4),
                    Text(
                      workerContract['workerName'][
                      langCode == 'en' ? 'english' :
                      langCode == 'vi' ? 'vietnamese' : 'korean'
                      ],
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
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
            ),
          );
        },
      ),
    );
  }
}