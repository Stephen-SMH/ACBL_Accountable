import 'dart:io';

import 'package:accountable/backend/app_state.dart';
import 'package:accountable/presentation/pages/addTransaction.dart';
import 'package:accountable/presentation/widgets/AddTransactionForm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart'
    hide Colors, showDialog, AlertDialog, TextButton, Scaffold, Card;
import 'package:accountable/services/ocr_service.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({super.key});

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  bool isAutomaticUpload = false;
  final OcrService _ocrService = OcrService();
  String? _selectedFilePath;
  Map<String, String?>? _ocrResult;
  bool _isProcessing = false;

  Future<void> _pickAndProcessFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        setState(() {
          _selectedFilePath = filePath;
          _ocrResult = null;
          _isProcessing = true;
        });

        print("Selected file: $filePath");

        Map<String, String?> ocrData =
            await _ocrService.extractSlipData(filePath);

        setState(() {
          _ocrResult = ocrData;
          _isProcessing = false;
        });

        if (_ocrResult != null) {
          print(
              "OCR Result: Recipient: ${_ocrResult!['recipient']}, Amount: ${_ocrResult!['amount']}");
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTransaction(
                  initialAmount: _ocrResult!['amount'],
                  initialNotes: _ocrResult!['recipient'],
                ),
              ),
            );
          }
        } else {
          _showErrorMessage('Failed to extract data from slip.');
        }
      } else {
        print("File picking cancelled.");
      }
    } catch (e) {
      print("Error during file picking or OCR: $e");
      if (mounted) {
        _showErrorMessage('Error: $e');
      }
      setState(() {
        _selectedFilePath = null;
        _ocrResult = null;
        _isProcessing = false;
      });
    }
  }

  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SwitchListTile(
                title: const Text('Automatic Upload'),
                value: isAutomaticUpload,
                onChanged: (value) {
                  setState(() {
                    isAutomaticUpload = value;
                  });
                },
              ),
              const SizedBox(height: 50),
              const Icon(
                Icons.cloud_upload,
                color: Colors.indigo,
                size: 80,
              ),
              const SizedBox(height: 30),
              PrimaryButton(
                onPressed: () {
                  _pickAndProcessFile();
                },
                child: const Text('Select File'),
              ),
              if (_selectedFilePath != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Selected: ${_selectedFilePath!.split(Platform.pathSeparator).last}',
                  style: const TextStyle(color: Colors.gray),
                ),
              ],
              if (_ocrResult != null) ...[
                const SizedBox(height: 10),
                Text('Recipient: ${_ocrResult!['recipient'] ?? 'N/A'}'),
                Text('Amount: ${_ocrResult!['amount'] ?? 'N/A'}'),
              ],
              const Spacer(),
              PrimaryButton(
                shape : ButtonShape.rectangle,
                leading: const Icon(Icons.add),
                


               
                onPressed: () {
                  showDialog(
                    barrierColor: Colors.blue,
                    context: context,
                    builder: (context) {
                      return const Card(child: AddTransactionForm());
                    },
                  );
                },
                child: const Text('Add a transaction manually'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
