import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song_model.dart';

enum LoopModeType { none, all, one }

class MainController extends ChangeNotifier {
  AudioPlayer? _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<SongModel> _songs = [];
  int _currentIndex = 0;
  bool _isShuffled = false;
  LoopModeType _loopMode = LoopModeType.none;
  bool _disposed = false;

  List<SongModel> get songs => List.unmodifiable(_songs);
  List<SongModel> get audios => List.unmodifiable(_songs);
  int get currentIndex => _currentIndex;
  bool get isPlaying => _player?.playing ?? false;
  bool get isShuffled => _isShuffled;
  LoopModeType get loopMode => _loopMode;
  Duration get position => _player?.position ?? Duration.zero;
  Duration get duration => _player?.duration ?? Duration.zero;
  SongModel? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _songs.length ? _songs[_currentIndex] : null;
  String? get getCurrentAudioTitle => currentSong?.songname;

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;

    final player = AudioPlayer();
    _player = player;
    _subscriptions.add(player.playerStateStream.listen((_) => _safeNotify()));
    _subscriptions.add(player.positionStream.listen((_) => _safeNotify()));
    _subscriptions.add(player.durationStream.listen((_) => _safeNotify()));
    _subscriptions.add(player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _songs.length) {
        _currentIndex = index;
      }
      _safeNotify();
    }));
    _subscriptions.add(player.shuffleModeEnabledStream.listen((enabled) {
      _isShuffled = enabled;
      _safeNotify();
    }));
    return player;
  }

  Future<void> init() async {
    final box = Hive.box('RecentlyPlayed');
    final recent = <SongModel>[];

    for (var i = 0; i < box.length; i++) {
      final value = box.getAt(i);
      if (value is Map) {
        recent.add(SongModel(
          songid: value['id']?.toString(),
          songname: value['songname']?.toString(),
          userid: value['username']?.toString(),
          trackid: value['track']?.toString(),
          duration: '',
          coverImageUrl: value['cover']?.toString(),
          name: value['fullname']?.toString(),
        ));
      }
    }

    if (recent.isNotEmpty) {
      _songs = recent;
      _safeNotify();
    }
  }

  Future<void> setPlaylist(List<SongModel> songs, {int startIndex = 0}) async {
    final player = _ensurePlayer();
    _songs = List<SongModel>.from(songs);

    if (_songs.isEmpty) {
      await player.stop();
      _currentIndex = 0;
      _safeNotify();
      return;
    }

    _currentIndex = startIndex.clamp(0, _songs.length - 1);
    final sources = <AudioSource>[];
    var sourceIndex = 0;

    for (final song in _songs) {
      final raw = song.trackid?.trim();
      if (raw == null || raw.isEmpty) continue;

      final uri = Uri.tryParse(raw);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        continue;
      }

      sources.add(AudioSource.uri(uri));
      if (sources.length - 1 < _currentIndex) {
        sourceIndex = sources.length - 1;
      }
    }

    if (sources.isEmpty) {
      await player.stop();
      _safeNotify();
      return;
    }

    try {
      await player.setAudioSources(
        sources,
        initialIndex: sourceIndex.clamp(0, sources.length - 1),
        initialPosition: Duration.zero,
      );
      await _applyLoopMode();
      await player.setShuffleModeEnabled(_isShuffled);
      _safeNotify();
    } on PlayerException catch (error, stackTrace) {
      debugPrint('AudioPlayer load failed: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      await player.stop();
      _safeNotify();
    } catch (error, stackTrace) {
      debugPrint('AudioPlayer load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await player.stop();
      _safeNotify();
    }
  }

  Future<void> playSong(List<SongModel> songs, int initial) async {
    await setPlaylist(songs, startIndex: initial);
    await play();
  }

  Future<void> playOrPause() async {
    final player = _ensurePlayer();
    if (player.playing) {
      await player.pause();
    } else {
      await play();
    }
  }

  Future<void> play() async {
    final player = _ensurePlayer();
    if (player.audioSources.isEmpty && _songs.isNotEmpty) {
      await setPlaylist(_songs, startIndex: _currentIndex);
    }
    if (player.audioSources.isNotEmpty) {
      await player.play();
    }
  }

  Future<void> pause() async {
    final player = _player;
    if (player != null) await player.pause();
  }

  Future<void> stop() async {
    final player = _player;
    if (player != null) {
      await player.stop();
      _safeNotify();
    }
  }

  Future<void> next() async {
    final player = _player;
    if (player == null) return;
    if (player.hasNext) {
      await player.seekToNext();
      _currentIndex = player.currentIndex ?? _currentIndex;
      return;
    }
    if (_songs.isNotEmpty && _currentIndex < _songs.length - 1 && player.audioSources.isNotEmpty) {
      _currentIndex += 1;
      await player.seek(Duration.zero, index: _currentIndex.clamp(0, player.sequence.length - 1));
    }
    _safeNotify();
  }

  Future<void> previous() async {
    final player = _player;
    if (player == null) return;
    if (player.hasPrevious) {
      await player.seekToPrevious();
      _currentIndex = player.currentIndex ?? _currentIndex;
      return;
    }
    if (player.position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
      return;
    }
    if (_songs.isNotEmpty && _currentIndex > 0 && player.audioSources.isNotEmpty) {
      _currentIndex -= 1;
      await player.seek(Duration.zero, index: _currentIndex.clamp(0, player.sequence.length - 1));
    }
    _safeNotify();
  }

  Future<void> seek(Duration value) async {
    final player = _player;
    if (player != null) await player.seek(value);
  }

  void toggleLoop() {
    _loopMode = switch (_loopMode) {
      LoopModeType.none => LoopModeType.all,
      LoopModeType.all => LoopModeType.one,
      LoopModeType.one => LoopModeType.none,
    };
    unawaited(_applyLoopMode());
    _safeNotify();
  }

  void setLoopMode(LoopModeType mode) {
    _loopMode = mode;
    unawaited(_applyLoopMode());
    _safeNotify();
  }

  Future<void> _applyLoopMode() async {
    final player = _player;
    if (player == null) return;
    final mode = switch (_loopMode) {
      LoopModeType.none => LoopMode.off,
      LoopModeType.all => LoopMode.all,
      LoopModeType.one => LoopMode.one,
    };
    await player.setLoopMode(mode);
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    final player = _player;
    if (player != null) {
      unawaited(player.setShuffleModeEnabled(_isShuffled));
    }
    _safeNotify();
  }

  Future<void> addToPlaylist(SongModel song) async {
    _songs.add(song);
    final raw = song.trackid?.trim();
    final player = _player;
    if (player != null && player.audioSources.isNotEmpty && raw != null && raw.isNotEmpty) {
      final uri = Uri.tryParse(raw);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        await player.addAudioSource(AudioSource.uri(uri));
      }
    }
    _safeNotify();
  }

  Future<void> insertToPlaylist(int index, SongModel song) async {
    final safeIndex = index.clamp(0, _songs.length);
    _songs.insert(safeIndex, song);
    _safeNotify();
  }

  Future<void> removeFromPlaylist(int index) async {
    if (index < 0 || index >= _songs.length) return;
    _songs.removeAt(index);
    if (_currentIndex >= _songs.length) {
      _currentIndex = _songs.isEmpty ? 0 : _songs.length - 1;
    }
    _safeNotify();
  }

  Future<void> changeIndex(int newIndex, int oldIndex) async {
    if (oldIndex < 0 || oldIndex >= _songs.length) return;
    final safeNewIndex = newIndex.clamp(0, _songs.length - 1);
    final song = _songs.removeAt(oldIndex);
    _songs.insert(safeNewIndex, song);
    _currentIndex = safeNewIndex;
    _safeNotify();
  }

  Future<void> addToFavorite({
    required String name,
    required String fullname,
    required String username,
    required String cover,
    required String track,
  }) async {
    final box = Hive.box('liked');
    final key = track.isNotEmpty ? track : name;
    await box.put(key, {
      'songname': name,
      'fullname': fullname,
      'username': username,
      'cover': cover,
      'track': track,
    });
  }

  List<SongModel> convertToAudio(List<SongModel> songs) => List<SongModel>.from(songs);

  List<SongModel> converLocalSongToAudio(List<dynamic> songs) => songs.map((audio) {
        final item = audio as Map;
        return SongModel(
          songid: item['id']?.toString(),
          songname: item['songname']?.toString(),
          userid: item['username']?.toString(),
          trackid: item['track']?.toString(),
          duration: '',
          coverImageUrl: item['cover']?.toString(),
          name: item['fullname']?.toString(),
        );
      }).toList();

  SongModel? find(List<SongModel> source, String? path) {
    for (final song in source) {
      if (song.trackid == path) return song;
    }
    return null;
  }

  SongModel? findByname(List<SongModel> source, String? title) {
    for (final song in source) {
      if (song.songname == title) return song;
    }
    return null;
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    final player = _player;
    if (player != null) {
      unawaited(player.dispose());
    }
    super.dispose();
  }
}
