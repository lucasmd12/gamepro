import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicControlsWidget extends StatefulWidget {
  const MusicControlsWidget({super.key});

  @override
  State<MusicControlsWidget> createState() => _MusicControlsWidgetState();
}

class _MusicControlsWidgetState extends State<MusicControlsWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = true;
  double _currentVolume = 0.5;
  Offset _position = const Offset(200, 400);
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setVolume(_currentVolume);
    _playIntroMusic();

    // Optional: Listen to player state changes if needed for more complex logic
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        // If not looping, handle completion (e.g., play next song)
        // Since we are looping, this might not be strictly necessary
      }
    });
  }

  Future<void> _playIntroMusic() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop the music
    await _audioPlayer.play(AssetSource('audio/intro_music.mp3'));
    setState(() {
      _isPlaying = true;
    });
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  Future<void> _increaseVolume() async {
    setState(() {
      _currentVolume = (_currentVolume + 0.1).clamp(0.0, 1.0);
    });
    await _audioPlayer.setVolume(_currentVolume);
  }

  Future<void> _decreaseVolume() async {
    setState(() {
      _currentVolume = (_currentVolume - 0.1).clamp(0.0, 1.0);
    });
    await _audioPlayer.setVolume(_currentVolume);
  }

  Future<void> _closeWidget() async {
    await _audioPlayer.stop();
    setState(() {
      _isVisible = false;
    });
  }

  IconData _getVolumeIcon() {
    if (_currentVolume == 0) {
      return Icons.volume_off;
    } else if (_currentVolume < 0.5) {
      return Icons.volume_down;
    } else {
      return Icons.volume_up;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink(); // Hide the widget if not visible
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Draggable(
        feedback: _buildControlsUi(), // Visual feedback when dragging
        childWhenDragging: Container(), // Hide original widget while dragging
        onDraggableCanceled: (velocity, offset) {
          setState(() {
            _position = offset;
          });
        },
        child: _buildControlsUi(), // The actual widget to display
      ),
    );
  }

  Widget _buildControlsUi() {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      color: Colors.black87, // Dark background
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: _playPause,
              tooltip: _isPlaying ? 'Pause Music' : 'Play Music',
            ),
            IconButton(
              icon: const Icon(Icons.volume_down, color: Colors.white),
              onPressed: _decreaseVolume,
              tooltip: 'Volume Down',
            ),
            Icon(
              _getVolumeIcon(),
              color: Colors.white,
              size: 20,
            ),
            IconButton(
              icon: const Icon(Icons.volume_up, color: Colors.white),
              onPressed: _increaseVolume,
              tooltip: 'Volume Up',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent),
              onPressed: _closeWidget,
              tooltip: 'Close Controls',
            ),
          ],
        ),
      ),
    );
  }
}