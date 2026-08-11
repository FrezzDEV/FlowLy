import 'package:bloc/bloc.dart';
import '../../../models/loading_enum.dart';
import '../../../models/song_model.dart';
import '../../../repositories/get_home_page.dart';
import '../../../models/user.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetHomePage repo = GetHomePage();

  HomeCubit() : super(HomeState.initial());

  Future<void> getUsers() async {
    emit(state.copyWith(status: LoadPage.loading, clearError: true));

    try {
      final users = await repo.getUsers();
      final songs = await repo.getSongs();

      emit(state.copyWith(
        users: users,
        songs: songs,
        status: LoadPage.loaded,
        clearError: true,
      ));
    } catch (error) {
      final message = error.toString();
      emit(state.copyWith(
        status: LoadPage.error,
        errorMessage: message,
      ));
    }
  }
}
