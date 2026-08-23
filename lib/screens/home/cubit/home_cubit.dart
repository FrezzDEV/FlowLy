import 'package:bloc/bloc.dart';
import 'package:flowly/data/models/loading_enum.dart';
import 'package:flowly/domain/entities/song_model.dart';
import 'package:flowly/data/repositories/get_home_page.dart';
import 'package:flowly/domain/entities/user.dart';

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

    // Load each Home section independently. A failing users endpoint must not
    // prevent the song recommendations from rendering.
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

    // HomeScreen contains a guaranteed local demo recommendation, so it must
    // still render even when both remote endpoints are unavailable.
    final error = songsError ?? usersError;
    emit(state.copyWith(
      users: users,
      songs: songs,
      status: LoadPage.loaded,
      errorMessage: error == null ? null : error.toString(),
    ));
  }
}
