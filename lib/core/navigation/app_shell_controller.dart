import 'package:flutter_riverpod/flutter_riverpod.dart';

final appShellTabControllerProvider =
    NotifierProvider<AppShellTabController, int>(AppShellTabController.new);

class AppShellTabController extends Notifier<int> {
  static const homeTab = 0;
  static const portfolioTab = 1;
  static const scanTab = 2;
  static const settingsTab = 3;

  @override
  int build() => homeTab;

  void selectTab(int index, {String reason = 'user'}) {
    if (state == index) {
      return;
    }

    state = index;
  }

  void keepScanSelected({String reason = 'picker-return'}) {
    selectTab(scanTab, reason: reason);
  }
}
