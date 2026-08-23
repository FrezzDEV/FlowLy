import 'package:flowly/features/player/domain/main_controller.dart';

class GlobalGestureService {
  GlobalGestureService._();

  static MainController? controller;

  static void attach(MainController value) {
    controller = value;
  }

  static Future<void> next() async {
    final value = controller;
    if (value == null) return;
    await value.next();
  }

  static Future<void> previous() async {
    final value = controller;
    if (value == null) return;
    await value.previous();
  }
}
