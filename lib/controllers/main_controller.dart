import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song_model.dart';

enum LoopModeType { none, all, one }

class MainController extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<SongModel> _songs = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isShuffled = false;
  LoopModeType _loopMode = LoopModeType.none;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  List<SongModel> get songs => List.unmodifiable(_songs);
  List<SongModel> get audios => List.unmodifiable(_songs);
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isShuffled => _isShuffled;
  LoopModeType get loopMode => _loopMode;
  Duration get position => _position;
  Duration get duration => _duration;
  SongModel? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _songs.length ? _songs[_currentIndex] : null;
  String? get getCurrentAudioTitle => currentSong?.songname;

  MainController() {
    _subscriptions.add(player.positionStream.listen((value) {
      _position = value;
      notifyListeners();
    }));
    _subscriptions.add(player.durationStream.listen((value) {
      _duration = value ?? Duration.zero;
      notifyListeners();
    }));
    _subscriptions.add(player.currentIndexStream.listen((value) {
      if (value != null) {
        _currentIndex = value;
        _saveRecentlyPlayed();
        notifyListeners();
      }
    }));
    _subscriptions.add(player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    }));
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
      _songs = [
        ...recent,
        ..._songs.where((song) => !recent.any((item) => item.songid == song.songid)),
      ];
      notifyListeners();
    }
  }

  Future<void> _saveRecentlyPlayed() async {
    final song = currentSong;
    if (song == null) return;
    try {
      final box = Hive.box('RecentlyPlayed');
      await box.put(song.songid ?? song.songname ?? DateTime.now().toIso8601String(), {
        'songname': song.songname,
        'fullname': song.name,
        'username': song.userid,
        'cover': song.coverImageUrl,
        'track': song.trackid,
        'id': song.songid,
        'created': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Recently played is optional and must not interrupt playback.
    }
  }

  Future<void> setPlaylist(List<SongModel> songs, {int startIndex = 0}) async {
    _songs = List<SongModel>.from(songs);
    if (_songs.isEmpty) {
      await player.stop();
      _currentIndex = 0;
      notifyListeners();
      return;
    }

    final sources = _songs.map(_toSource).toList(growable: false);
    final playlist = ConcatenatingAudioSource(children: sources);
    _currentIndex = startIndex.clamp(0, _songs.length - 1);
    await player.setAudioSource(playlist, initialIndex: _currentIndex);
    await player.play();
    notifyListeners();
  }

  Future<void> playSong(List<SongModel> songs, int initial) async {
    await setPlaylist(songs, startIndex: initial);
  }

  Future<void> playOrPause() async {
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> play() => player.play();
  Future<void> pause() => player.pause();
  Future<void> stop() => player.stop();
  Future<void> next() => player.seekToNext();

  Future<void> previous() async {
    if (_position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
    } else {
      await player.seekToPrevious();
    }
  }

  Future<void> seek(Duration value) => player.seek(value);

  void toggleLoop() {
    switch (_loopMode) {
      case LoopModeType.none:
        _loopMode = LoopModeType.all;
        player.setLoopMode(LoopMode.all);
        break;
      case LoopModeType.all:
        _loopMode = LoopModeType.one;
        player.setLoopMode(LoopMode.one);
        break;
      case LoopModeType.one:
        _loopMode = LoopModeType.none;
        player.setLoopMode(LoopMode.off);
        break;
    }
    notifyListeners();
  }

  void setLoopMode(LoopModeType mode) {
    _loopMode = mode;
    player.setLoopMode(switch (mode) {
      LoopModeType.none => LoopMode.off,
      LoopModeType.all => LoopMode.all,
      LoopModeType.one => LoopMode.one,
    });
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    player.setShuffleModeEnabled(_isShuffled);
    notifyListeners();
  }

  void addToPlaylist(SongModel song) {
    _songs.add(song);
    final source = player.audioSource;
    if (source is ConcatenatingAudioSource) {
      source.add(_toSource(song));
    }
    notifyListeners();
  }

  void insertToPlaylist(int index, SongModel song) {
    final safeIndex = index.clamp(0, _songs.length);
    _songs.insert(safeIndex, song);
    final source = player.audioSource;
    if (source is ConcatenatingAudioSource) {
      source.insert(safeIndex, _toSource(song));
    }
    notifyListeners();
  }

  void removeFromPlaylist(int index) {
    if (index < 0 || index >= _songs.length) return;
    _songs.removeAt(index);
    final source = player.audioSource;
    if (source is ConcatenatingAudioSource && index < source.length) {
      source.removeAt(index);
    }
    notifyListeners();
  }

  void changeIndex(int newIndex, int oldIndex) {
    if (oldIndex < 0 || oldIndex >= _songs.length) return;
    final safeNewIndex = newIndex.clamp(0, _songs.length - 1);
    final song = _songs.removeAt(oldIndex);
    _songs.insert(safeNewIndex, song);
    final source = player.audioSource;
    if (source is ConcatenatingAudioSource) {
      final sourceChildren = List<AudioSource>.from(source.children);
      final moved = sourceChildren.removeAt(oldIndex);
      sourceChildren.insert(safeNewIndex, moved);
      source.clear();
      source.addAll(sourceChildren);
    }
    notifyListeners();
  }

  void addToFavorite({
    required String name,
    required String fullname,
    required String username,
    required String cover,
    required String track,
  }) {
    final box = Hive.box('liked');
    box.put(name, {
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

  SongModel? find(List<SongModel> source, String? path) =>
      source.where((song) => song.trackid == path).firstOrNull;

  SongModel? findByname(List<SongModel> source, String? title) =>
      source.where((song) => song.songname == title).firstOrNull;

  AudioSource _toSource(SongModel song) {
    final url = song.trackid;
    if (url == null || url.isEmpty) {
      throw ArgumentError('Song ${song.songname ?? ''} has no audio URL');
    }
    return AudioSource.uri(
      Uri.parse(url),
      tag: song,
    );
  }

  void close() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    player.dispose();
  }

  @override
  void dispose() {
    close();
    super.dispose();
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final value in this) {
      return value;
    }
    return null;
  }
}
