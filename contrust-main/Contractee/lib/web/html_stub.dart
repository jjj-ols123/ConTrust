library;

class _Location {
  String origin = '';
  String href = '';
}

class Window {
  final _Location location = _Location();
}

class _Body {
  void append(dynamic _) {}
}

class Document {
  dynamic body = _Body();
}

class AnchorElement {
  AnchorElement({String? href});
  String? download;
  String? target;
  void click() {}
  void remove() {}
  dynamic style;
}

class _DummyStream {
  void listen([Function? _]) {}
}

class IFrameElement {
  dynamic style = _Style();
  dynamic src;
  String? allow;
  final _DummyStream onError = _DummyStream();
  bool? allowFullscreen;
}

class _Style {
  dynamic border;
  dynamic width;
  dynamic height;
}

final Window window = Window();
final Document document = Document();
