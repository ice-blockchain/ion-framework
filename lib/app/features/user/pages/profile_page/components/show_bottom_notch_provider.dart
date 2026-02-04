import 'package:flutter/material.dart';

class ShowBottomNotchProvider extends InheritedWidget {
  const ShowBottomNotchProvider({
    required this.show,
    required super.child,
    super.key,
  });

  final bool show;

  static ShowBottomNotchProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShowBottomNotchProvider>();
  }

  @override
  bool updateShouldNotify(ShowBottomNotchProvider old) => show != old.show;
}
