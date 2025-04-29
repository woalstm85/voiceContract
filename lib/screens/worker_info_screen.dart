import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'speech_recognition_screen.dart';
import 'package:contact/screens/services/voice_recognition_service.dart';
import 'package:contact/screens/widgets/grid_painter.dart';
import 'package:contact/widgets/wave_pulse_loading.dart';

class WorkerInfoScreen extends StatefulWidget {
  const WorkerInfoScreen({Key? key}) : super(key: key);

  @override
  State<WorkerInfoScreen> createState() => _WorkerInfoScreenState();
}

class _WorkerInfoScreenState extends State<WorkerInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool _hasSignature = false;
  final VoiceRecognitionService _voiceService = VoiceRecognitionService();

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _setupSignatureListener();
    _setupVoiceServiceListeners();
  }

  void _setupSignatureListener() {
    _signatureController.addListener(() {
      final hasSignature = _signatureController.isNotEmpty;
      if (hasSignature != _hasSignature) {
        setState(() {
          _hasSignature = hasSignature;
        });
      }
    });
  }

  void _setupVoiceServiceListeners() {
    // 음성 인식 상태가 변경될 때마다 UI 업데이트
    _voiceService.addStatusListener((status) {
      setState(() {});
    });

    // 음성 인식 결과가 나오면 텍스트 필드 업데이트
    _voiceService.addRecognizedTextListener((text) {
      setState(() {
        _nameController.text = text;
      });
    });
  }

  Future<void> _toggleListening() async {
    if (_voiceService.isRecording) {
      await _voiceService.stopRecording();
    } else {
      context.showWavePulseLoading(message: '음성인식 준비 중...');
      await _voiceService.startRecording();
      context.hideWavePulseLoading();
    }
  }

  Future<void> _saveWorkerInfo() async {
    if (_nameController.text.isEmpty || !_hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이름과 서명을 모두 입력해주세요'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    try {
      final signature = await _signatureController.toPngBytes();
      final prefs = await SharedPreferences.getInstance();

      // 기존 정보 불러오기
      final currentWorkerString = prefs.getString('current_worker');
      if (currentWorkerString != null) {
        final currentWorker = json.decode(currentWorkerString);
        currentWorker['signature'] = base64Encode(signature!);

        // 업데이트된 정보 저장
        await prefs.setString('current_worker', json.encode(currentWorker));

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SpeechRecognitionScreen(),
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving worker info: $e');
    }
  }

  // 상태에 따른 색상 가져오기
  Color _getStatusColor() {
    return _voiceService.getStatusColor();
  }

  // 상태에 따른 아이콘 가져오기
  IconData _getStatusIcon() {
    return _voiceService.getStatusIcon();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        centerTitle: true,
        title: const Text(
          '근로자 정보',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkerNameSection(),
            const SizedBox(height: 32),
            _buildSignatureSection(),
            const Spacer(),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '근로자명',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _getStatusColor(),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        readOnly: true,
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: '음성으로 이름을 말씀해주세요',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                          ),
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            FloatingActionButton(
              backgroundColor: _voiceService.isRecording ? Colors.red : Colors.teal,
              onPressed: _toggleListening,
              child: Icon(_voiceService.isRecording ? Icons.mic_off : Icons.mic, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '서명',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.indigoAccent, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              CustomPaint(
                size: const Size(double.infinity, 200),
                painter: GridPainter(),
              ),
              Signature(
                controller: _signatureController,
                height: 200,
                backgroundColor: Colors.transparent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => _signatureController.clear(),
              child: const Text('서명 지우기', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '이 전',
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _saveWorkerInfo,
            child: const Text(
              '확 인',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _nameController.dispose();
    _signatureController.dispose();
    super.dispose();
  }
}