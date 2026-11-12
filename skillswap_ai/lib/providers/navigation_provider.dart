import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainNavNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    if (index >= 0 && index < 5) {
      state = index;
    }
  }
}

final mainNavIndexProvider = NotifierProvider<MainNavNotifier, int>(MainNavNotifier.new);

