import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/song_model.dart';

enum LoopModeType { none, all, one }

class MainController extends ChangeNotifier {
  List<SongModel> _songs = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isShuffled = false;
  LoopModeType _loopMode = LoopModeType.none;

  List<SongModel> get songs => List.unmodifiable(_songs);
  List<SongModel> get audios => List.unmodifiable(_songs);
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isShuffled => _isShuffled;
  LoopModeType get loopMode => _loopMode;
  Duration get position => Duration.zero;
  Duration get duration => Duration.zero;
  SongModel? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _songs.length ? _songs[_currentIndex] : null;
  String? get getCurrentAudioTitle => currentSong?.songname;

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
      final recentIds = recent
          .map((song) => song.songid)
          .whereType<String>()
          .toSet();
      _songs = [
        ...recent,
        ..._songs.where(
          (song) => song.songid == null || !recentIds.contains(song.songid),
        ),
      ];
      notifyListeners();
    }
  }

  Future<void> setPlaylist(List<SongModel> songs, {int startIndex = 0}) async {
    _songs = List<SongModel>.from(songs);
    _currentIndex = _songs.isEmpty ? 0 : startIndex.clamp(0, _songs.length - 1);
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> playSong(List<SongModel> songs, int initial) async {
    await setPlaylist(songs, startIndex: initial);
    await play();
  }

  Future<void> playOrPause() async {
    if (_songs.isEmpty) return;
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  Future<void> play() async {
    if (_songs.isEmpty) return;
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> pause() async {
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> stop() async {
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> next() async {
    if (_songs.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _songs.length;
    notifyListeners();
  }

  Future<void> previous() async {
    if (_songs.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _songs.length) % _songs.length;
    notifyListeners();
  }

  Future<void> seek(Duration value) async {}

  void toggleLoop() {
    _loopMode = switch (_loopMode) {
      LoopModeType.none => LoopModeType.all,
      LoopModeType.all => LoopModeType.one,
      LoopModeType.one => LoopModeType.none,
    };
    notifyListeners();
  }

  void setLoopMode(LoopModeType mode) {
    _loopMode = mode;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    notifyListeners();
  }

  Future<void> addToPlaylist(SongModel song) async {
    _songs.add(song);
    notifyListeners();
  }

  Future<void> insertToPlaylist(int index, SongModel song) async {
    final safeIndex = index.clamp(0, _songs.length);
    _songs.insert(safeIndex, song);
    notifyListeners();
  }

  Future<void> removeFromPlaylist(int index) async {
    if (index < 0 || index >= _songs.length) return;
    _songs.removeAt(index);
    if (_currentIndex >= _songs.length) {
      _currentIndex = _songs.isEmpty ? 0 : _songs.length - 1;
    }
    notifyListeners();
  }

  Future<void> changeIndex(int newIndex, int oldIndex) async {
    if (oldIndex < 0 || oldIndex >= _songs.length) return;
    final safeNewIndex = newIndex.clamp(0, _songs.length - 1);
    final song = _songs.removeAt(oldIndex);
    _songs.insert(safeNewIndex, song);
    _currentIndex = safeNewIndex;
    notifyListeners();
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
}
