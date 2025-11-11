library ui_web;

class _PlatformViewRegistry {
  void registerViewFactory(String viewType, dynamic Function(int) viewFactory) {}
}

final _PlatformViewRegistry platformViewRegistry = _PlatformViewRegistry();
