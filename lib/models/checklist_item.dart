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
