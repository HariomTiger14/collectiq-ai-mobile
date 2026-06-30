import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appShellTabControllerProvider =
    NotifierProvider<AppShellTabController, int>(AppShellTabController.new);

class AppShellTabController extends Notifier<int> {
  static const homeTab = 0;
  static const scanTab = 1;
  static const portfolioTab = 2;
  static const settingsTab = 3;

  @override
  int build() {
    return homeTab;
  }

  void selectTab(int index, {String reason = 'user'}) {
    if (state == index) {
      debugPrint('[AppShell] selected tab unchanged: $index ($reason)');
      return;
    }

    debugPrint('[AppShell] selected tab $state -> $index ($reason)');
    state = index;
  }

  void keepScanSelected({String reason = 'picker-return'}) {
    selectTab(scanTab, reason: reason);
  }
}
