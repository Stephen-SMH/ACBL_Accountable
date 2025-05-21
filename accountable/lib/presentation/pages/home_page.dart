import 'package:accountable/backend/app_state.dart';
import 'package:accountable/presentation/pages/transaction_details_screen.dart';
import 'package:accountable/presentation/pages/addTransaction.dart';
import 'package:accountable/presentation/widgets/AddTransactionForm.dart';
import 'package:flutter/material.dart' hide Card, IconButton, showDialog;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Colors, Scaffold;

class HomePage extends StatefulWidget {
  final String detailsPath;

  const HomePage({super.key, required this.detailsPath});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransList>(context, listen: false).getTransactionsFromDB();
    });
  }

  IconData _getIconForType(TransactionType type) {
    switch (type) {
      case TransactionType.food:
        return Icons.shopping_cart;
      case TransactionType.personal:
        return Icons.person;
      case TransactionType.utility:
        return Icons.lightbulb;
      case TransactionType.transportation:
        return Icons.directions_bus;
      case TransactionType.health:
        return Icons.health_and_safety;
      case TransactionType.leisure:
        return Icons.movie;
      case TransactionType.other:
      default:
        return Icons.category;
    }
  }

  String getFormattedDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  List<DailyTransList> getAllDaysInMonth(AppState appState, DateTime date) {
    final year = date.year;
    final month = date.month;
    final lastDay = DateUtils.getDaysInMonth(year, month);

    List<DailyTransList> allDays = [];

    for (int day = 1; day <= lastDay; day++) {
      final dateForDay = DateTime(year, month, day);
      final dailyList = appState.getDailyTransList(dateForDay);
      if (dailyList.transactions.isNotEmpty) {
        allDays.add(dailyList);
      }
    }

    return allDays;
  }

  void _showDatePicker(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        debugPrint("Selected date: $pickedDate");
        selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TransList>(
        builder: (context, transList, child) {
          final appState = AppState();
          appState.transList = transList;

          final allDailyTrans = getAllDaysInMonth(appState, selectedDate);
          final totalExpense = allDailyTrans
              .expand((day) => day.transactions)
              .fold(0.0, (sum, t) => sum + t.amount)
              .toStringAsFixed(2);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Month Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month - 1,
                            );
                          });
                        },
                        child: const Icon(RadixIcons.arrowLeft),
                      ),
                      PrimaryButton(
                        leading: const StatedWidget.map(
                          states: {
                            'disabled': Icon(Icons.close),
                            {WidgetState.hovered, WidgetState.focused}:
                                Icon(Icons.date_range_sharp),
                            WidgetState.pressed: Icon(Icons.date_range_rounded),
                           
                          },
                          child: Icon(Icons.date_range_rounded),
                        ),
                        onPressed: () {
                          _showDatePicker(context);
                        },
                        child: StatedWidget(
                          focused: const Text('Choose your date'),
                          hovered: const Text('Choose your date'),
                          pressed: const Text('Choose your date'),
                          child: Text(
                            '${getMonthName(selectedDate.month)} ${selectedDate.year}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month + 1,
                            );
                          });
                        },
                        child: const Icon(RadixIcons.arrowRight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Monthly Total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Monthly Total: $totalExpense',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (allDailyTrans.isEmpty)
                    const Center(
                      child: Text("No transactions for this month.",
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ...allDailyTrans.map((dailyList) {
                      final dayTotal = dailyList.transactions
                          .fold(0.0, (sum, t) => sum + t.amount)
                          .toStringAsFixed(2);

                      final expenseWidgets =
                          dailyList.transactions.map((trans) {
                        return _buildExpenseItem(
                          icon: _getIconForType(trans.transType),
                          title: transTypeToString(trans.transType),
                          subtitle: trans.transName,
                          amount: trans.amount.toStringAsFixed(2),
                          context: context,
                          transaction: trans,
                        );
                      }).toList();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDayExpense(
                          day: getFormattedDate(dailyList.getDate()),
                          totalExpense: dayTotal,
                          expenses: expenseWidgets,
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Add Transaction"),
        backgroundColor: Colors.green,
        onPressed: () {
          showDialog(
            barrierColor: Colors.grey,
            context: context,
            builder: (context) {
              return const Card(child: AddTransactionForm());
            },
          );
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (context) => const AddTransaction(),
          //   ),
          // );
        },
      ),
    );
  }

  Widget _buildDayExpense({
  required String day,
  required String totalExpense,
  required List<Widget> expenses,
}) {
  return Card(
    filled: true,
    fillColor: Colors.lightBlueAccent,
    borderColor: Colors.orange[200],
    
    
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date and daily total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  
                  const SizedBox(width: 4),
                  Text(
                    'Total: $totalExpense',
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // List of transactions for the day
          ...expenses,
        ],
      ),
    ),
  );
}

  Widget _buildExpenseItem({
  required IconData icon,
  required String title,
  required String subtitle,
  required String amount,
  required BuildContext context,
  Trans? transaction,
}) {
  return InkWell(
    onTap: () {
      if (transaction != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(
              transaction: transaction,
            ),
          ),
        );
      }
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
          Text('$amount THB',
              style: const TextStyle(fontSize: 16, color: Colors.black)),
        ],
      ),
    ),
  );
}


}
