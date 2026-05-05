class ChecklistItem {
  final String id;
  String title;
  bool isDone;

  ChecklistItem({
    required this.id,
    required this.title,
    this.isDone = false,
  });
}

class ShoppingList {
  final String id;
  String title;
  DateTime dateCreated;
  List<ChecklistItem> items;

  ShoppingList({
    required this.id,
    required this.title,
    required this.dateCreated,
    required this.items,
  });
}
