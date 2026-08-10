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
      preload: true,
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
    queue.removeAt(index);
    final current = player.currentIndex ?? 0;
    final sources = queue.map((track) => AudioSource.uri(Uri.parse(track.audioUrl))).toList();
    final safeIndex = current.clamp(0, queue.length - 1);
    await player.setAudioSources(sources, initialIndex: safeIndex, preload: true);
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex || oldIndex < 0 || oldIndex >= queue.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final track = queue.removeAt(oldIndex);
    queue.insert(newIndex.clamp(0, queue.length), track);
    final currentId = currentTrack.id;
    final sources = queue.map((track) => AudioSource.uri(Uri.parse(track.audioUrl))).toList();
    final current = queue.indexWhere((track) => track.id == currentId);
    await player.setAudioSources(sources, initialIndex: current < 0 ? 0 : current, preload: true);
  }

  Future<void> clearQueue() async {
    if (queue.isEmpty) return;
    final current = currentTrack;
    queue
      ..clear()
      ..add(current);
    await player.setAudioSources([AudioSource.uri(Uri.parse(current.audioUrl))], preload: true);
  }

  Future<void> dispose() => player.dispose();
}
