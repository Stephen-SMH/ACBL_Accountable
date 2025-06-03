import 'dart:io';

import 'package:accountable/backend/app_state.dart';
import 'package:accountable/presentation/pages/addTransaction.dart';
import 'package:accountable/presentation/widgets/AddTransactionForm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart'
    hide
        Colors,
        showDialog,
        AlertDialog,
        TextButton,
        Scaffold,
        Card,
        Divider,
        IconButton;
import 'package:accountable/services/gemini_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide TextField;

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({super.key});

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  bool isAutomaticUpload = false;
  String? _selectedFilePath;
  Map<String, String?>? _ocrResult;
  final ImagePicker _picker = ImagePicker();
  XFile? _capturedImage;

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
        });

        print("Selected file: $filePath");
        
        // Read file as bytes
        final bytes = await File(filePath).readAsBytes();
        
        // Process with Gemini API
        Map<String, String?> ocrData = 
            await GeminiService.instance.extractData(bytes, isSlip: true);

        setState(() {
          _ocrResult = ocrData;
        });

        if (_ocrResult != null && _ocrResult!['recipient'] != null && _ocrResult!['amount'] != null) {
          print("Gemini Result: Recipient: ${_ocrResult!['recipient']}, Amount: ${_ocrResult!['amount']}");
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTransaction(
                  initialAmount: _ocrResult!['amount'],
                  initialNotes: _ocrResult!['recipient'],
                  initialCategory: _ocrResult!['category'],
                ),
              ),
            );
          }
        } else {
          _showErrorMessage('Failed to extract data from slip. Please try again or add manually.');
        }
      } else {
        print("File picking cancelled.");
      }
    } catch (e) {
      print("Error during file picking or Gemini processing: $e");
      if (mounted) {
        _showErrorMessage('Error: $e');
      }
      setState(() {
        _selectedFilePath = null;
        _ocrResult = null;
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

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 100,
      );
      if (photo != null) {
        setState(() {
          _capturedImage = photo;
        });
        _confirmImageDialog(File(photo.path));
      }
    } catch (e) {
      debugPrint("Error taking photo: $e");
    }
  }

  void _confirmImageDialog(File imageFile) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Photo"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(imageFile, height: 200),
              const SizedBox(height: 12),
              const Text("Do you want to use this photo?"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Dismiss only
              child: const Text("Retake"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showProcessOptionDialog(imageFile);
              },
              child: const Text("Use Photo"),
            ),
          ],
        );
      },
    );
  }

  void _showProcessOptionDialog(File imageFile) {
    String? manualAmount;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Choose Method"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("How would you like to provide the amount?"),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        manualAmount = '';
                      });
                    },
                    child: const Text("Manual"),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop(); // Close this
                      _showOcrHintDialogForAmount(imageFile);
                    },
                    child: const Text("Auto (OCR Amount)"),
                  ),
                  if (manualAmount != null) ...[
                    const SizedBox(height: 16),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: "Enter Amount"),
                      onChanged: (value) {
                        manualAmount = value;
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (manualAmount != null && manualAmount!.isNotEmpty) {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddTransactionForm(
                                initialNotes: _ocrResult?['recipient'] ?? '',
                                initialAmount: manualAmount,
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text("Confirm"),
                    ),
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showOcrHintDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tip for OCR"),
          content: const Text(
              "Make sure the price tag is clearly visible and well-lit in the photo. Try to avoid glare or blurry shots."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close hint
                _takePhoto(); // Start camera again
              },
              child: const Text("Take Picture"),
            ),
          ],
        );
      },
    );
  }

  void _showOcrHintDialogForAmount(File notesImageFile) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Hint for OCR"),
          content: const Text(
              "Take a photo of the price tag or screen showing the amount."),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                if (!mounted) return;

                final XFile? amountPhoto = await _picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1920,
                  maxHeight: 1080,
                  imageQuality: 100,
                );

                if (!mounted) return;

                if (amountPhoto != null) {
                  final bytes = await File(amountPhoto!.path).readAsBytes();
                  
                  if (!mounted) return;

                  final result = await GeminiService.instance.extractData(bytes, isSlip: false);
                  final String? price = result['price'];

                  if (!mounted) return;

                  if (price != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTransactionForm(
                          initialNotes: _ocrResult?['recipient'] ?? '',
                          initialAmount: price,
                        ),
                      ),
                    );
                  } else {
                    _showErrorMessage('Could not detect a valid price in the image. Please try again or enter manually.');
                  }
                }
              },
              child: const Text("Take Photo"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            padding: const EdgeInsets.all(16),
            filled: true,
            borderWidth: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // UPLOAD SLIP SECTION
                const Text(
                  "UPLOAD SLIP",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text("Upload bank slip for automatic processing"),
                const SizedBox(height: 16),
                PrimaryButton(
                  child: const Text('Select File'),
                  onPressed: () {
                    _pickAndProcessFile();
                  },
                ),
                const SizedBox(height: 20),
                const Divider(
                  color: Colors.blue,
                  height: 40,
                  thickness: 2.2,
                ),

                // CAPTURE OBJECT SECTION
                const Text(
                  "CAPTURE OBJECT",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text("Capture object photo for price extraction"),
                const SizedBox(height: 16),
                PrimaryButton(
                  child: const Text('Take Photo'),
                  onPressed: () => _takePhoto(),
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
                const SizedBox(height: 20),
                const Spacer(),
                PrimaryButton(
                  shape: ButtonShape.rectangle,
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
                const Divider(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
