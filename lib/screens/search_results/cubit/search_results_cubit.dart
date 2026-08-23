import 'package:bloc/bloc.dart';
import 'package:flowly/features/player/domain/main_controller.dart';
import 'package:flowly/data/models/loading_enum.dart';
import 'package:flowly/domain/entities/song_model.dart';
import 'package:flowly/domain/entities/user.dart';
import 'package:flowly/data/repositories/get_search_results.dart';

part 'search_results_state.dart';

class SearchResultsCubit extends Cubit<SearchResultsState> {
  final repo = SearchRepository();

  SearchResultsCubit() : super(SearchResultsState.initial());
  void searchSongs(String tag) async {
    if (state.isSong) {
      try {
        emit(state.copyWith(status: LoadPage.loading));
        var songs = await repo.getSongs(tag.toString());
        emit(state.copyWith(
          status: LoadPage.loaded,
          songs: songs,
        ));
      } catch (e) {
        emit(state.copyWith(status: LoadPage.error));
      }
    } else {
      try {
        emit(state.copyWith(status: LoadPage.loading));
        var users = await repo.getUsers(tag.toString());
        emit(state.copyWith(
          status: LoadPage.loaded,
          users: users,
        ));
      } catch (e) {
        emit(state.copyWith(status: LoadPage.error));
      }
    }
  }

  void playSongs(MainController controller, int initial) {
    controller.playSong(controller.convertToAudio(state.songs), initial);
  }

  void isNullToggle() {
    emit(state.copyWith(isNull: !state.isNull));
  }

  void isSongToggle() {
    emit(state.copyWith(isSong: !state.isSong));
  }
}
