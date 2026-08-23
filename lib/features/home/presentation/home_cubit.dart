import 'package:bloc/bloc.dart';

import 'package:flowly/data/models/loading_enum.dart';
import '../../../domain/entities/song_model.dart';
import '../../../domain/entities/user.dart';
import 'package:flowly/data/repositories/get_home_page.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetHomePage repo = GetHomePage();

  HomeCubit() : super(HomeState.initial());

  Future<void> getUsers() async {
    emit(state.copyWith(status: LoadPage.loading, clearError: true));

    List<User> users = const [];
    List<SongModel> songs = const [];
    Object? usersError;
    Object? songsError;

    try {
      users = await repo.getUsers();
    } catch (error) {
      usersError = error;
    }

    try {
      songs = await repo.getSongs();
    } catch (error) {
      songsError = error;
    }

    final error = songsError ?? usersError;
    emit(state.copyWith(
      users: users,
      songs: songs,
      status: LoadPage.loaded,
      errorMessage: error == null ? null : error.toString(),
    ));
  }
}
