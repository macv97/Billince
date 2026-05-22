class SharedChecklistLog {
  final String id;
  final String action; // 'Añadido', 'Modificado', 'Eliminado'
  final String userName;
  final String itemTitle;
  final DateTime createdAt;

  SharedChecklistLog({
    required this.id,
    required this.action,
    required this.userName,
    required this.itemTitle,
    required this.createdAt,
  });
}

class SharedChecklistItem {
  final String id;
  String title;
  bool isDone;
  List<String> tags;
  final String addedBy;
  final DateTime createdAt;

  SharedChecklistItem({
    required this.id,
    required this.title,
    required this.isDone,
    required this.tags,
    required this.addedBy,
    required this.createdAt,
  });
}

class SharedChecklist {
  final String id;
  final String name;
  final String currency; // Not strictly used, but good to have parity
  final List<String> members;
  String? myMemberName;
  final List<SharedChecklistItem> items;
  final List<SharedChecklistLog> logs;

  SharedChecklist({
    required this.id,
    required this.name,
    this.currency = '€',
    required this.members,
    this.myMemberName,
    required this.items,
    required this.logs,
  });
}
