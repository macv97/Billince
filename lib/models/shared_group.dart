import 'shared_expense.dart';
import 'shared_file.dart';

class SharedExpenseGroup {
  final String id;
  String title;
  List<String> members;
  List<SharedExpense> expenses;
  List<SharedFile> files;
  String currency;
  String? myMemberName;

  SharedExpenseGroup({
    required this.id,
    required this.title,
    required this.members,
    required this.expenses,
    required this.files,
    this.currency = '\$',
    this.myMemberName,
  });
}
