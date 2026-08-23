import 'package:bloc/bloc.dart';

import '../../../data/models/loading_enum.dart';
import '../../../domain/entities/song_model.dart';
import '../../../domain/entities/user.dart';
import '../../../data/repositories/get_genre_data.dart';
import '../../player/domain/main_controller.dart';

part 'genre_state.dart';

class GenreCubit extends Cubit<GenreState> {
  final repo = GenreRepository();

  GenreCubit() : super(GenreState.initial());

  void init(String tag) async {
    try {
      emit(state.copyWith(status: LoadPage.loading));
      final users = await repo.getUsers(tag);
      final songs = await repo.getSongs(tag);
      emit(state.copyWith(
        status: LoadPage.loaded,
        users: users,
        songs: songs,
      ));
    } catch (e) {
      emit(state.copyWith(status: LoadPage.error));
    }
  }

  void playSongs(MainController controller, int initial) {
    controller.playSong(controller.convertToAudio(state.songs), initial);
  }
}
