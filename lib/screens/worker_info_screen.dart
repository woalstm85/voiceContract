import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart'; // 애니메이션 효과 추가
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
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _setupSignatureListener();
    _setupVoiceServiceListeners();
    _scrollController.addListener(_scrollListener);
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

  // 스크롤 위치에 따라 앱바 색상 변경
  void _scrollListener() {
    if (_scrollController.offset > 10 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 10 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
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
      _showErrorSnackBar();
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
      _showErrorSnackBar('서명 저장 중 오류가 발생했습니다');
    }
  }

  void _showErrorSnackBar([String? message]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? '이름과 서명을 모두 입력해주세요'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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
      backgroundColor: Colors.indigo[80], // 배경색 변경
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(), // 헤더 추가
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      child: _buildInfoCard(
                        _buildWorkerNameSection(),
                        Icons.person,
                        '근로자 기본 정보',
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay: const Duration(milliseconds: 200),
                      child: _buildInfoCard(
                        _buildSignatureSection(),
                        Icons.draw,
                        '서명 정보',
                      ),
                    ),
                    const SizedBox(height: 10), // 하단 버튼과의 간격
                  ],
                ),
              ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  // AppBar 위젯
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: _isScrolled ? 4.0 : 0.0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      title: FadeIn(
        child: Text(
          '근로자 정보',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1.2, // worker_list_screen과 동일한 스타일
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: Colors.indigo,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.home,
            color: Colors.indigo,
          ),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ],
    );
  }

  // 헤더 위젯
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo, Colors.indigoAccent],
        ),
      ),
      child: FadeInDown(
        delay: const Duration(milliseconds: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '근로자 정보 입력',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,

              ),
            ),

            Text(
              '음성으로 이름을 입력하고 서명을 추가해주세요.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 정보 카드 컨테이너
  Widget _buildInfoCard(Widget child, IconData icon, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          color: Colors.indigo.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카드 헤더
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.indigo),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          // 카드 내용
          child,
        ],
      ),
    );
  }

  Widget _buildWorkerNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _getStatusColor(),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor().withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        readOnly: true,
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: '음성으로 이름을 말씀해주세요.',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                          ),
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 음성 인식 버튼
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_voiceService.isRecording ? Colors.red : Colors.teal).withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: FloatingActionButton(
                elevation: 4,
                backgroundColor: _voiceService.isRecording ? Colors.red : Colors.teal,
                onPressed: _toggleListening,
                tooltip: _voiceService.isRecording ? '녹음 중지' : '녹음 시작',
                child: Icon(

                  _voiceService.isRecording ? Icons.mic_off : Icons.mic,
                  color: Colors.white,

                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 음성 인식 상태 안내 텍스트
        Text(
          _voiceService.isRecording
              ? '말씀하신 내용을 인식하고 있습니다...'
              : '마이크 버튼을 눌러 이름을 말씀해주세요',
          style: TextStyle(
            fontSize: 12,
            color: _voiceService.isRecording ? Colors.red : Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.indigoAccent, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: GridPainter(),
                ),
                Signature(
                  controller: _signatureController,
                  height: 180,
                  backgroundColor: Colors.transparent,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 서명 상태 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _hasSignature ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hasSignature ? Colors.green.withOpacity(0.5) : Colors.orange.withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _hasSignature ? Icons.check_circle : Icons.info_outline,
                    color: _hasSignature ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _hasSignature ? '서명 완료' : '서명 필요',
                    style: TextStyle(
                      color: _hasSignature ? Colors.green : Colors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // 서명 지우기 버튼
            TextButton.icon(
              onPressed: () => _signatureController.clear(),
              icon: const Icon(Icons.delete_outline, color: Colors.orange),
              label: const Text('서명 지우기', style: TextStyle(color: Colors.orange)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Colors.orange.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: FadeInUp(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '이 전',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _saveWorkerInfo,
                child: const Text(
                  '확 인',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _nameController.dispose();
    _signatureController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
}