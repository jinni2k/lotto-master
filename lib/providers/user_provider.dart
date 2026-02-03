import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  bool _isPremium = false;

  bool get isPremium => _isPremium;

  void setPremium(bool value) {
    if (_isPremium == value) {
      return;
    }
    _isPremium = value;
    notifyListeners();
  }
}

class UserProviderScope extends InheritedNotifier<UserProvider> {
  const UserProviderScope({
    super.key,
    required UserProvider notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static UserProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UserProviderScope>();
    if (scope == null || scope.notifier == null) {
      throw StateError('UserProviderScope is not found in widget tree.');
    }
    return scope.notifier!;
  }
}
