class Expense {
  final String id;
  String title;
  double amount;
  DateTime date;
  String module;
  String? attachedFileName;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.module,
    this.attachedFileName,
  });
}
