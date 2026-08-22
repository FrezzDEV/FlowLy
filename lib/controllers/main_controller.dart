import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song_model.dart';

enum LoopModeType { none, all, one }

class MainController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<SongModel> _songs = [];
  int _currentIndex = 0;
  bool _isShuffled = false;
  LoopModeType _loopMode = LoopModeType.none;
  bool _disposed = false;

  List<SongModel> get songs => List.unmodifiable(_songs);
  List<SongModel> get audios => List.unmodifiable(_songs);
  int get currentIndex => _currentIndex;
  bool get isPlaying => _player.playing;
  bool get isShuffled => _isShuffled;
  LoopModeType get loopMode => _loopMode;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  SongModel? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _songs.length ? _songs[_currentIndex] : null;
  String? get getCurrentAudioTitle => currentSong?.songname;

  Future<void> init() async {
    if (_subscriptions.isNotEmpty) return;

    _subscriptions.add(_player.playerStateStream.listen((_) => _safeNotify()));
    _subscriptions.add(_player.positionStream.listen((_) => _safeNotify()));
    _subscriptions.add(_player.durationStream.listen((_) => _safeNotify()));
    _subscriptions.add(_player.currentIndexStream.listen((index) {
      if (index != null && index < _songs.length) {
        _currentIndex = index;
      }
      _safeNotify();
    }));
    _subscriptions.add(_player.shuffleModeEnabledStream.listen((enabled) {
      _isShuffled = enabled;
      _safeNotify();
    }));

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
    _songs = List<SongModel>.from(songs);
    if (_songs.isEmpty) {
      await _player.stop();
      _currentIndex = 0;
      _safeNotify();
      return;
    }

    _currentIndex = startIndex.clamp(0, _songs.length - 1);
    final sources = <AudioSource>[];

    for (final song in _songs) {
      final url = song.trackid?.trim();
      if (url == null || url.isEmpty) continue;
      sources.add(AudioSource.uri(Uri.parse(url)));
    }

    if (sources.isEmpty) {
      await _player.stop();
      _safeNotify();
      return;
    }

    try {
      await _player.setAudioSources(
        sources,
        initialIndex: _currentIndex.clamp(0, sources.length - 1),
        initialPosition: Duration.zero,
      );
      await _applyLoopMode();
      await _player.setShuffleModeEnabled(_isShuffled);
      _safeNotify();
    } on PlayerException catch (error, stackTrace) {
      debugPrint('AudioPlayer load failed: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      await _player.stop();
      _safeNotify();
    } catch (error, stackTrace) {
      debugPrint('AudioPlayer load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _player.stop();
      _safeNotify();
    }
  }

  Future<void> playSong(List<SongModel> songs, int initial) async {
    await setPlaylist(songs, startIndex: initial);
    await play();
  }

  Future<void> playOrPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await play();
    }
  }

  Future<void> play() async {
    if (_player.audioSources.isEmpty) {
      final song = currentSong;
      if (song != null) {
        await setPlaylist(_songs, startIndex: _currentIndex);
      }
    }
    if (_player.audioSources.isNotEmpty) {
      await _player.play();
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> stop() async {
    await _player.stop();
    _safeNotify();
  }

  Future<void> next() async {
    if (_player.hasNext) {
      await _player.seekToNext();
      _currentIndex = _player.currentIndex ?? _currentIndex;
      return;
    }
    if (_songs.isNotEmpty && _currentIndex < _songs.length - 1) {
      _currentIndex += 1;
      await _player.seek(Duration.zero, index: _currentIndex);
    }
  }

  Future<void> previous() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      _currentIndex = _player.currentIndex ?? _currentIndex;
      return;
    }
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_songs.isNotEmpty && _currentIndex > 0) {
      _currentIndex -= 1;
      await _player.seek(Duration.zero, index: _currentIndex);
    }
  }

  Future<void> seek(Duration value) async {
    await _player.seek(value);
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
    final mode = switch (_loopMode) {
      LoopModeType.none => LoopMode.off,
      LoopModeType.all => LoopMode.all,
      LoopModeType.one => LoopMode.one,
    };
    await _player.setLoopMode(mode);
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    unawaited(_player.setShuffleModeEnabled(_isShuffled));
    _safeNotify();
  }

  Future<void> addToPlaylist(SongModel song) async {
    _songs.add(song);
    if (_player.audioSources.isNotEmpty && song.trackid?.isNotEmpty == true) {
      await _player.addAudioSource(AudioSource.uri(Uri.parse(song.trackid!.trim())));
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

  List<SongModel> convertToAudio(List<SongModel> songs) =>
      List<SongModel>.from(songs);

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
    unawaited(_player.dispose());
    super.dispose();
  }
}
