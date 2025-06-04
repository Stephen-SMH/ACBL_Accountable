import 'dart:convert';
import 'package:accountable/backend/app_state.dart';
import 'package:flutter/material.dart'
    hide showDialog, AlertDialog, TextButton, FormField, TextField, Form;
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class AddTransactionForm extends StatefulWidget {
  const AddTransactionForm({
    super.key,
    this.initialNotes,
    this.initialAmount,
    this.initialCategory, // Added initialCategory
  });
  final String? initialNotes;
  final String? initialAmount;
  final String? initialCategory; // Added initialCategory

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _amountKey = const TextFieldKey("amount");
  final _notesKey = const TextFieldKey("notes");
  final _categoryKey = const TextFieldKey("category");
  final _typeKey = const TextFieldKey("transactionType");
  final _dateKey = const TextFieldKey("date");

  DateTime? selectedDate;
  String? selectedTransactionType;
  final List<String> categories = [
    'food',
    'personal',
    'utility',
    'transportation',
    'health',
    'leisure',
    'other'
  ];

  final List<String> transactionTypes = ['Withdraw', 'Deposit'];

  String selectedCategory = 'food';

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    if (widget.initialCategory != null) {
      selectedCategory = widget.initialCategory!;
    }
  }

  void _pickDate(BuildContext context) async {
    final now = DateTime.now();
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          onSubmit: (context, values) {
            // Handle form submission

            // Here you can send the formData to your backend or save it locally

            final double amount = double.tryParse(values[_amountKey]) ?? 0.0;
            final double finalAmount =
                selectedCategory == 'Withdraw' ? amount : amount;

            final String notes = values[_notesKey] ?? '';

            final TransactionType transType =
                stringToTransType(selectedCategory!);

            debugPrint(
                'Transaction Type: $transType, Amount: $finalAmount, Notes: $notes');

            final newTrans = Trans(
              transName: notes,
              transactionDate: selectedDate ?? DateTime.now(),
              amount: finalAmount,
              transType: transType,
            );

            Provider.of<TransList>(context, listen: false)
                .addTransaction(newTrans);
            Navigator.of(context).pop(); // This dismisses the dialog

            // Optional: Show confirmation after closing
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transaction saved!')),
            );
          },
          child: SingleChildScrollView( // Wrap with SingleChildScrollView
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormField(
                      //validator: const NotEmptyValidator(),
                      key: _amountKey,
                      label: const Text('Amount (THB)'),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: widget.initialAmount ?? ''),
                      ),
                      
                    ),
                    FormField(
                      key: _dateKey,
                      label: const Text('Date'),
                      child: ListTile(
                        title: Text(selectedDate == null
                            ? 'Select Date'
                            : '${selectedDate!.toLocal()}'.split(' ')[0]),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _pickDate(context),
                      ),
                    ),
                    FormField(
                      key: _notesKey,
                      label: const Text('Notes'),
                      child: TextField(
                        controller: TextEditingController(text: widget.initialNotes ?? ''),
                      ),
                    ),
                    FormField(
                      key: _categoryKey,
                      label: const Text('Category'),
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: categories
                            .map((cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;

                            selectedTransactionType =
                                transactionTypes.contains(value)
                                    ? value
                                    : selectedTransactionType;
                            debugPrint('Selected Category: $selectedCategory');
                          });
                        },
                      ),
                    ),
                    FormField(
                      key: _typeKey,
                      label: const Text('Transaction Type'),
                      child: DropdownButtonFormField<String>(
                        value: selectedTransactionType,
                        items: ['Withdraw', 'Deposit']
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTransactionType = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ).gap(24),
                const Gap(24),
                FormErrorBuilder(
                  builder: (context, errors, child) {
                    return PrimaryButton(
                      onPressed:
                          errors.isEmpty ? () => context.submitForm() : null,
                      child: const Text('Save Transaction'),
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
