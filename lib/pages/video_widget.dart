
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';


class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({
    required this.videoUrl,
    super.key,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      _controller = VideoPlayerController.network(widget.videoUrl);
      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          if (kIsWeb) {
            _controller.setVolume(0);
          }
          _controller.play();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки видео: $e';
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(_error!),
      );
    }

    return _isInitialized
        ? AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    )
        : const Center(child: CircularProgressIndicator());
  }

  @override
  void dispose() {
    if (_controller.value.isInitialized) {
      _controller.pause(); // Остановить воспроизведение
      _controller.removeListener(() {}); // Удалить слушателей
    }
    _controller.dispose();
    super.dispose();
  }

}