import 'package:accountable/backend/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddTransaction extends StatefulWidget {
  final String? initialAmount;
  final String? initialNotes;

  const AddTransaction({
    super.key,
    this.initialAmount,
    this.initialNotes,
  });

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  String transactionType = 'Withdraw';
  String? selectedCategory;
  DateTime? selectedDate;
  final List<String> categories = [
    'food',
    'personal',
    'utility',
    'transportation',
    'health',
    'leisure',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      amountController.text = widget.initialAmount!;
    }
    if (widget.initialNotes != null) {
      notesController.text = widget.initialNotes!;
      _autoGenerateCategory(widget.initialNotes!);
    }
    selectedDate = DateTime.now();
  }

  Future<void> _autoGenerateCategory(String notes) async {
    final tempTrans = Trans(
      transName: notes,
      transactionDate: DateTime.now(),
      amount: 0.0,
      transType: TransactionType.other,
    );
    await tempTrans.generateCategory();

    if (tempTrans.transType != TransactionType.other) {
      setState(() {
        selectedCategory =
            transTypeToString(tempTrans.transType).toLowerCase();
      });
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _showTransactionTypeDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: ['Deposit', 'Withdraw']
              .map((type) => ListTile(
                    title: Text(type),
                    onTap: () {
                      setState(() {
                        transactionType = type;
                      });
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        );
      },
    );
  }

  void _showCategoryDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: categories
              .map((cat) => ListTile(
                    title: Text(cat),
                    onTap: () {
                      setState(() {
                        selectedCategory = cat;
                      });
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        );
      },
    );
  }

  void _showValidationError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text('Amount'),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter amount',
                  suffixText: 'THB',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Date'),
              ListTile(
                title: Text(selectedDate == null
                    ? 'Select Date'
                    : '${selectedDate!.toLocal()}'.split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              const Text('Notes'),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  hintText: 'Enter notes',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Category'),
              ListTile(
                title: Text(selectedCategory ?? 'Select Category'),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: _showCategoryDialog,
              ),
              const SizedBox(height: 16),
              const Text('Transaction Type'),
              ListTile(
                title: Text(transactionType),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: _showTransactionTypeDialog,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (amountController.text.isEmpty ||
                      selectedCategory == null) {
                    _showValidationError('Please fill in all required fields');
                    return;
                  }

                  final double amount =
                      double.tryParse(amountController.text) ?? 0.0;
                  final double finalAmount =
                      transactionType == 'Withdraw' ? amount : amount;

                  final TransactionType transType =
                      stringToTransType(selectedCategory!);

                  final newTrans = Trans(
                    transName: notesController.text,
                    transactionDate: selectedDate ?? DateTime.now(),
                    amount: finalAmount,
                    transType: transType,
                  );

                  Provider.of<TransList>(context, listen: false)
                      .addTransaction(newTrans);

                  Navigator.pop(context);
                },
                child: const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
