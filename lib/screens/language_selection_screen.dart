import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'worker_list_screen.dart';
import 'dart:convert';

class LanguageSelectionScreen extends StatelessWidget {
  final bool isViewMode;

  const LanguageSelectionScreen({
    Key? key,
    this.isViewMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          '언어 선택',
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
              children: const [
                Text(
                  '원하는 언어를 선택하세요',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '작성된 근로계약서를 선택한 언어로 확인할 수 있습니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // 언어 선택 버튼 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLanguageButton(
                    context,
                    '한국어',
                    'ko',
                    Colors.indigo,
                    Icons.language,
                  ),
                  const SizedBox(height: 20),
                  _buildLanguageButton(
                    context,
                    '영어 (English)',
                    'en',
                    Colors.teal,
                    Icons.language,
                  ),
                  const SizedBox(height: 20),
                  _buildLanguageButton(
                    context,
                    '베트남어 (Tiếng Việt)',
                    'vi',
                    Colors.deepPurple,
                    Icons.language,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(
      BuildContext context,
      String label,
      String langCode,
      Color color,
      IconData icon,
      ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onLanguageSelected(context, langCode),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onLanguageSelected(BuildContext context, String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    final contracts = prefs.getStringList('contracts') ?? [];

    if (contracts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장된 계약서가 없습니다'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerListScreen(
          langCode: langCode,
          contracts: contracts.map((e) => json.decode(e)).toList(),
        ),
      ),
    );
  }
}