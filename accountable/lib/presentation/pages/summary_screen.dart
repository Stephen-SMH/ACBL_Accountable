import 'package:flutter/cupertino.dart'; // Import only Material components needed
import 'package:graphic/graphic.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Label;
import '../../backend/app_state.dart';
import 'package:intl/intl.dart'; // Import for DateFormat
import 'dart:ui'; // Import for Color

// Custom color palette for the pie chart
const List<Color> customChartColors = [
  Color(0xFF42A5F5), // Blue
  Color(0xFF66BB6A), // Green
  Color(0xFFFFCA28), // Amber
  Color(0xFFEF5350), // Red
  Color(0xFFAB47BC), // Purple
  Color(0xFF78909C), // Blue Grey
  Color(0xFF26A69A), // Teal
  Color(0xFFD4E157), // Lime
  Color(0xFFFF7043), // Deep Orange
  Color(0xFF8D6E63), // Brown
];

// Helper function to get icon based on transaction type
IconData _getIconForTransactionType(TransactionType type) {
  switch (type) {
    case TransactionType.food:
      return CupertinoIcons.cart;
    case TransactionType.personal:
      return CupertinoIcons.person;
    case TransactionType.utility:
      return CupertinoIcons.lightbulb;
    case TransactionType.transportation:
      return CupertinoIcons.car;
    case TransactionType.health:
      return CupertinoIcons.bandage;
    case TransactionType.leisure:
      return CupertinoIcons.gamecontroller;
    case TransactionType.other:
      return CupertinoIcons.square_grid_2x2;
    default:
      return CupertinoIcons.square_grid_2x2; // Default fallback
  }
}

class BudgetSummaryScreen extends StatelessWidget {
  const BudgetSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transList = Provider.of<TransList>(context);
    final insights = transList.generateInsights();

    final chartData = insights.entries.map((entry) {
      return {'category': transTypeToString(entry.key), 'amount': entry.value};
    }).toList();

    final insightListTiles =
        insights.entries.where((entry) => entry.value > 0).map((entry) {
      // Get the specific category type
      final categoryType = entry.key;
      // Filter transactions for this category
      final categoryTransactions = transList.transactions
          .where((trans) => trans.transType == categoryType)
          .toList();

      debugPrint("Category: $categoryType, Transactions: $categoryTransactions");
      debugPrint("Chart Data: $chartData");

      return Card(
        child: GestureDetector(
          onTap: () {
            _showCategoryTransactions(
                context, categoryType, categoryTransactions);
          },
          child: Row(
            children: [
              Icon(_getIconForTransactionType(categoryType)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(transTypeToString(categoryType)),
              ),
              Text(entry.value.toStringAsFixed(2)),
            ],
          ),
        ),
      );
    }).toList();

    return Scaffold(
      child: SafeArea(
        child: Column(
          children: [
            // Title text instead of navigation bar
            const Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
              child: Text(
                'Budget Summary',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    chartData.isEmpty
                        ? const Center(
                            child: Text(
                                'No transaction data available for summary.'))
                        : SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3, // Responsive height
                            child: Container(
                              margin: const EdgeInsets.only(top: 10),
                              width: MediaQuery.of(context).size.width * 0.8, // Responsive width
                              child: Chart(
                                data: chartData,
                                variables: {
                                  'category': Variable(
                                    accessor: (Map map) =>
                                        map['category'] as String,
                                  ),
                                  'amount': Variable(
                                    accessor: (Map map) => map['amount'] as num,
                                    scale: LinearScale(min: 0),
                                  ),
                                },
                                transforms: [
                                  Proportion(
                                    variable: 'amount',
                                    as: 'percent',
                                  )
                                ],
                                marks: [
                                  IntervalMark(
                                    position:
                                        Varset('percent') / Varset('category'),
                                    label: LabelEncode(
                                        encoder: (tuple) {
                                          final category = tuple['category'].toString();
                                          final percentValue = tuple['percent'] * 100;
                                          if (percentValue > 5.0) { // Only show label if percentage is significant
                                            final percent = percentValue.toStringAsFixed(1);
                                            return Label(
                                              '$category\n${percent}%',
                                              LabelStyle(
                                                textStyle: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black, // Ensure good contrast
                                                ),
                                              ),
                                            );
                                          }
                                          return Label(''); // Hide label for small percentages
                                        }),
                                    color: ColorEncode(
                                        variable: 'category',
                                        values: customChartColors), // Use custom colors
                                    modifiers: [StackModifier()],
                                  )
                                ],
                                coord: PolarCoord(
                                  transposed: true,
                                  dimCount: 1,
                                  startRadius: 0.4,
                                ),
                                selections: {'tap': PointSelection()},
                              ),
                            ),
                          ),
                    // Legend
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Wrap(
                        spacing: 16.0,
                        runSpacing: 8.0,
                        children: chartData.asMap().entries.map((entry) {
                          final index = entry.key;
                          final data = entry.value;
                          final category = data['category'];
                          final amount = data['amount'] as double; // Explicitly cast to double
                          final total = transList.totalAmount;
                          final percent = total == 0 ? 0.0 : (amount / total) * 100; // Handle division by zero

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: customChartColors[index % customChartColors.length],
                              ),
                              const SizedBox(width: 8),
                              Text('$category (${percent.toStringAsFixed(1)}%)'),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: insightListTiles.isEmpty
                          ? const Center(child: Text('No spending details.'))
                          : ListView(
                              children: insightListTiles,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryTransactions(BuildContext context,
      TransactionType categoryType, List<Trans> transactions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${transTypeToString(categoryType)} Transactions'),
          content: transactions.isEmpty
              ? const Text('No transactions found.')
              : SizedBox(
                  height: 300,
                  child: SingleChildScrollView(
                    child: Column(
                      children: transactions.map((trans) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                          
                            
                            children: [

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                trans.transName,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                DateFormat('yyyy-MM-dd')
                                    .format(trans.transactionDate),
                                style: const TextStyle(
                                    
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.blue),
                              ),
                                ],
                              ),
                              
                              Text(
                                '${trans.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const Divider(),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
          
          
        );
      },
    );
  }
}
