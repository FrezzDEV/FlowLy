import 'package:just_audio/just_audio.dart';

import '../models/track.dart';

class PlayerService {
  PlayerService() : player = AudioPlayer();

  final AudioPlayer player;
  final List<Track> queue = List<Track>.from(demoTracks);

  Track get currentTrack {
    final index = player.currentIndex ?? 0;
    return queue[index.clamp(0, queue.length - 1)];
  }

  Future<void> initialize() async {
    await player.setAudioSources(
      queue.map((track) => AudioSource.uri(Uri.parse(track.audioUrl))).toList(),
      initialIndex: 0,
      preload: false,
    );
  }

  Future<void> playTrack(Track track) async {
    final index = queue.indexWhere((item) => item.id == track.id);
    if (index < 0) return;
    await player.seek(Duration.zero, index: index);
    await player.play();
  }

  Future<void> toggle() => player.playing ? player.pause() : player.play();
  Future<void> next() => player.seekToNext();
  Future<void> previous() => player.seekToPrevious();
  Future<void> seek(Duration position) => player.seek(position);
  Future<void> setShuffle(bool enabled) => player.setShuffleModeEnabled(enabled);
  Future<void> setRepeat(bool enabled) => player.setLoopMode(enabled ? LoopMode.all : LoopMode.off);

  Future<void> removeFromQueue(int index) async {
    if (queue.length <= 1 || index < 0 || index >= queue.length) return;
    final currentId = currentTrack.id;
    queue.removeAt(index);
    final sources = queue.map((track) => AudioSource.uri(Uri.parse(track.audioUrl))).toList();
    final safeIndex = queue.indexWhere((track) => track.id == currentId).clamp(0, queue.length - 1);
    await player.setAudioSources(sources, initialIndex: safeIndex, preload: false);
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex || oldIndex < 0 || oldIndex >= queue.length) return;
    final currentId = currentTrack.id;
    if (newIndex > oldIndex) newIndex -= 1;
    final track = queue.removeAt(oldIndex);
    queue.insert(newIndex.clamp(0, queue.length), track);
    final sources = queue.map((track) => AudioSource.uri(Uri.parse(track.audioUrl))).toList();
    final current = queue.indexWhere((track) => track.id == currentId).clamp(0, queue.length - 1);
    await player.setAudioSources(sources, initialIndex: current, preload: false);
  }

  Future<void> clearQueue() async {
    final current = currentTrack;
    queue
      ..clear()
      ..add(current);
    await player.setAudioSources([AudioSource.uri(Uri.parse(current.audioUrl))], preload: false);
  }

  Future<void> dispose() => player.dispose();
}
