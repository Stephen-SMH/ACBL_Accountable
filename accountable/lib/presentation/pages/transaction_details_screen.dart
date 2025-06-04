import 'package:accountable/backend/app_state.dart';
import 'package:accountable/presentation/pages/addTransaction.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class TransactionDetailScreen extends StatelessWidget {
  final Trans transaction; // Add transaction field

  const TransactionDetailScreen(
      {super.key, required this.transaction}); // Update constructor

  // Helper function to get icon based on transaction type
  IconData _getIconForType(TransactionType type) {
    switch (type) {
      case TransactionType.food:
        return CupertinoIcons.cart;
      case TransactionType.personal:
        return CupertinoIcons.person;
      case TransactionType.utility:
        return CupertinoIcons.lightbulb;
      case TransactionType.transportation:
        return CupertinoIcons.bus;
      case TransactionType.health:
        return CupertinoIcons.bandage;
      case TransactionType.leisure:
        return CupertinoIcons.film;
      case TransactionType.other:
      default:
        return CupertinoIcons.square_grid_2x2;
    }
  }

  // Helper function to get string representation of transaction type
  String _getStringForType(TransactionType type) {
    return transTypeToString(type); // Use existing helper
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEE dd MMM yy')
        .format(transaction.transactionDate); // Format the date

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: 'Back',
        middle: const Text('Transaction Detail'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedDate, // Use formatted date
                style: const TextStyle(
                    color: CupertinoColors.systemGrey, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemIndigo.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.arrow_up,
                        color: CupertinoColors
                            .systemRed), // Assuming all are expenses for now
                    const SizedBox(width: 8),
                    Text(
                        transaction.amount
                            .toStringAsFixed(2), // Use transaction amount
                        style: const TextStyle(
                            color: CupertinoColors.white, fontSize: 20)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildInfoTile(
                  _getIconForType(transaction.transType),
                  _getStringForType(transaction.transType),
                  context), // Use transaction type icon and string
              const SizedBox(height: 10),
              _buildInfoTile(CupertinoIcons.pencil, transaction.transName,
                  context), // Use transaction name/notes
              const SizedBox(height: 20),
              // _buildSlipInfo(), // Keep slip info for now, might need adjustment later
              const Spacer(),
              Center(
                child: CupertinoButton(
                  onPressed: () {
                    _showDeleteConfirmation(context);
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                        color: CupertinoColors.systemRed, fontSize: 18),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              // TODO: Implement delete functionality
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String text, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemIndigo.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: CupertinoColors.white),
          const SizedBox(width: 8),
          Expanded(
            // Wrap Text in Expanded to prevent overflow and allow alignment
            child: Text(text,
                style: const TextStyle(
                    color: CupertinoColors.white, fontSize: 16)),
          ),
          Align(
            // Keep Align for the edit button
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.pencil,
                  color: CupertinoColors.white),
              onPressed: () {
                // Use proper Cupertino navigation
                Navigator.of(context, rootNavigator: true)
                    .push(CupertinoPageRoute(
                        builder: (context) => AddTransaction(
                              initialAmount: transaction.amount.toString(),
                              initialNotes: transaction.transName,
                            )));
              },
            ),
          )
        ],
      ),
    );
  }

/*
  Widget _buildSlipInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemIndigo.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Slip Info',
              style: TextStyle(color: CupertinoColors.white, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: CupertinoColors.white,
                child: Icon(CupertinoIcons.person,
                    color: CupertinoColors.systemIndigo),
              ),
              const SizedBox(width: 8),
              const Text('You',
                  style: TextStyle(color: CupertinoColors.white, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
*/
}
