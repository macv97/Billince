class SharedExpense {
  final String id;
  String title;
  double amount;
  String payer;
  List<String> participants;
  DateTime date;

  SharedExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.payer,
    required this.participants,
    required this.date,
  });
}
