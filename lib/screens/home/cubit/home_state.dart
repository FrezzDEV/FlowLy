part of 'home_cubit.dart';

class HomeState {
  final LoadPage status;
  final List<User> users;
  final List<SongModel> songs;
  final String? errorMessage;

  HomeState({
    required this.status,
    required this.users,
    required this.songs,
    this.errorMessage,
  });

  factory HomeState.initial() {
    return HomeState(
      songs: const [],
      status: LoadPage.initial,
      users: const [],
    );
  }

  HomeState copyWith({
    LoadPage? status,
    List<User>? users,
    List<SongModel>? songs,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      users: users ?? this.users,
      songs: songs ?? this.songs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
