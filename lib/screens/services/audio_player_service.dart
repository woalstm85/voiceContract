import 'package:audioplayers/audioplayers.dart';

/// 오디오 파일 재생을 담당하는 서비스 클래스
class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  // 상태 변경 콜백
  late Function(bool) _onPlayStateChanged;

  // 게터
  bool get isPlaying => _isPlaying;

  // 초기화
  void init({required Function(bool) onPlayStateChanged}) {
    _onPlayStateChanged = onPlayStateChanged;

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
      _onPlayStateChanged(_isPlaying);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _onPlayStateChanged(_isPlaying);
    });
  }

  // 재생 시작
  Future<void> startPlayback(String audioFilePath) async {
    if (audioFilePath.isEmpty) {
      throw Exception('오디오 파일 경로가 제공되지 않았습니다');
    }

    try {
      await _audioPlayer.play(DeviceFileSource(audioFilePath));
      _isPlaying = true;
      _onPlayStateChanged(_isPlaying);
    } catch (e) {
      print('오디오 재생 오류: $e');
      rethrow;
    }
  }

  // 재생 중지
  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
      _onPlayStateChanged(_isPlaying);
    } catch (e) {
      print('오디오 중지 오류: $e');
    }
  }

  // 리소스 정리
  void dispose() {
    _audioPlayer.dispose();
  }
}