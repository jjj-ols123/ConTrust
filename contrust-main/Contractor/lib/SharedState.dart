
// ignore_for_file: file_names

class SharedState {
  static final SharedState _instance = SharedState._internal();

  factory SharedState() {
    return _instance;
  }

  SharedState._internal();

  final List<Map<String, String>> clients = [];

  void addClient(String name, String project, String status) {
    clients.add({
      'name': name,
      'project': project,
      'status': status,
    });
  }
}