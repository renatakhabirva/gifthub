import 'package:flutter/material.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final bool isFullscreen;
  final bool isMuted;

  const VideoPlayerScreen({
    required this.videoUrl,
    this.isFullscreen = false,
    this.isMuted = false,
    Key? key,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    try {
      _controller = VideoPlayerController.network(widget.videoUrl)
        ..initialize()
            .then((_) {
              if (mounted) {
                setState(() {
                  _isInitialized = true;
                });
              }

              _controller.setVolume(widget.isMuted ? 0.0 : 1.0);
          _controller.play();
        }).catchError((error) {
          print('Ошибка инициализации видео: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Не удалось загрузить видео')),
            );
          }
        });
    } catch (e) {
      print('Критическая ошибка при создании VideoPlayerController: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка воспроизведения видео')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: backgroundBeige.withOpacity(0),
      body: Center(
        child: widget.isFullscreen
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller),
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: darkGreen,
                  bufferedColor: buttonGreenOpacity,
                  backgroundColor: lightGrey,
                ),
              ),
            ],
          ),
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );
  }
}