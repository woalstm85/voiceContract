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
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          '언어 선택',
          style: TextStyle(color: Colors.black),

        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLanguageButton(context, '한국어', 'ko', Colors.blue),
            const SizedBox(height: 20),
            _buildLanguageButton(context, '영어', 'en', Colors.green),
            const SizedBox(height: 20),
            _buildLanguageButton(context, '배트남어', 'vi', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
      BuildContext context,
      String label,
      String langCode,
      Color color,
      ) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () => _onLanguageSelected(context, langCode),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w600,
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