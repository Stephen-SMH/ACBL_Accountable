import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  String? _cachedApiKey;

  GeminiService._internal();

  String? get _apiKey {
    if (_cachedApiKey == null) {
      _cachedApiKey = dotenv.env['GEMINI_API_KEY'];
      if (_cachedApiKey == null) {
        print("GEMINI_API_KEY not found in .env file. Make sure .env exists and is loaded in main.dart.");
      }
    }
    return _cachedApiKey;
  }

  Future<Map<String, String?>> extractData(Uint8List bytes, {bool isSlip = true}) async {
    final apiKey = _apiKey;
    if (apiKey == null) {
      print("API Key is not set. Cannot call Gemini API.");
      return isSlip ? {'recipient': null, 'amount': null, 'category': null} : {'price': null};
    }

    const String url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent';
        
    final String prompt = isSlip
        ? "Extract recipient name (store name) and total amount from this banking slip. Then categorize the store into one of these categories: food, personal, utility, transportation, health, leisure, or other. Return as JSON: {recipient: string, amount: string, category: string}"
        : "Extract only the numeric price value from this product image. Return as JSON: {price: string}";

    final String base64Image = base64Encode(bytes);

    final Map<String, dynamic> requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'topK': 1,
        'topP': 1,
        'maxOutputTokens': 150,
        'stopSequences': [],
        "thinkingConfig": {
          "thinkingBudget": 0
        }
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ]
    };

    try {
      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print("Gemini API Request Body: ${jsonEncode(requestBody)}");
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Gemini API Success Response: ${response.body}");
        
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty &&
            responseData['candidates'][0]['content']['parts'][0]['text'] != null) {
          String extractedText = responseData['candidates'][0]['content']['parts'][0]['text'];
          print("Extracted Text: $extractedText");
          
          try {
            if (isSlip) {
              // Clean up the response if it contains markdown code blocks
              if (extractedText.trim().startsWith('```')) {
                extractedText = extractedText
                    .replaceFirst(RegExp(r'^```json\s*'), '')
                    .replaceFirst(RegExp(r'\s*```$'), '');
              }
              
              final json = jsonDecode(extractedText) as Map<String, dynamic>;
              print("Parsed JSON: $json");
              final result = {
                'recipient': json['recipient']?.toString(),
                'amount': json['amount']?.toString(),
                'category': json['category']?.toString().toLowerCase(),
              };
              print("Final Result: $result");
              return result;
            } else {
              // For price extraction, first try to parse JSON if it's in that format
              if (extractedText.trim().startsWith('```')) {
                extractedText = extractedText
                    .replaceFirst(RegExp(r'^```json\s*'), '')
                    .replaceFirst(RegExp(r'\s*```$'), '');
                
                try {
                  final json = jsonDecode(extractedText) as Map<String, dynamic>;
                  return {'price': json['price']?.toString()};
                } catch (e) {
                  // If JSON parsing fails, fall back to regex extraction
                  final cleaned = extractedText.replaceAll(RegExp(r'[^0-9.]'), '');
                  return {'price': cleaned};
                }
              } else {
                final cleaned = extractedText.replaceAll(RegExp(r'[^0-9.]'), '');
                return {'price': cleaned};
              }
            }
          } catch (e) {
            print("Failed to parse Gemini response: $e");
            print("Raw response text: $extractedText");
            return isSlip ? {'recipient': null, 'amount': null, 'category': null} : {'price': null};
          }
        } else {
          print("Gemini API response does not contain expected text data.");
          print("Response body: ${response.body}");
          return isSlip ? {'recipient': null, 'amount': null, 'category': null} : {'price': null};
        }
      } else {
        print("Error calling Gemini API: ${response.statusCode}");
        print("Response body: ${response.body}");
        return isSlip ? {'recipient': null, 'amount': null, 'category': null} : {'price': null};
      }
    } catch (e) {
      print("Exception during Gemini API call: $e");
      return isSlip ? {'recipient': null, 'amount': null, 'category': null} : {'price': null};
    }
  }

  Future<String?> extractPriceFromImage(Uint8List imageBytes) async {
    final result = await extractData(imageBytes, isSlip: false);
    return result['price'];
  }

  Future<String?> generateCategoryFromText(String text) async {
    final apiKey = _apiKey;
    if (apiKey == null) {
      print("API Key is not set. Cannot call Gemini API.");
      return null;
    }

    const String url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent';
        
    final String prompt = "Categorize the following text into one of these categories: food, personal, utility, transportation, health, leisure, or other. Return only the category name as a string. Text: \"$text\"";

    final Map<String, dynamic> requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'topK': 1,
        'topP': 1,
        'maxOutputTokens': 50,
        'stopSequences': [],
        "thinkingConfig": {
          "thinkingBudget": 0
        }
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ]
    };

    try {
      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print("Gemini API Category Request Body: ${jsonEncode(requestBody)}");
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Gemini API Category Success Response: ${response.body}");
        
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty &&
            responseData['candidates'][0]['content']['parts'][0]['text'] != null) {
          String extractedText = responseData['candidates'][0]['content']['parts'][0]['text'];
          print("Extracted Category Text: $extractedText");
          // Clean up the response if it contains markdown code blocks or extra quotes
          extractedText = extractedText
              .replaceFirst(RegExp(r'^```json\s*'), '')
              .replaceFirst(RegExp(r'\s*```$'), '')
              .replaceAll('"', '')
              .trim();
          
          final List<String> categories = [
            'food', 'personal', 'utility', 'transportation', 'health', 'leisure', 'other'
          ];
          
          // Simple check to ensure the extracted category is one of the valid ones
          if (categories.contains(extractedText.toLowerCase())) {
            return extractedText.toLowerCase();
          } else {
            print("Extracted category '$extractedText' is not in the predefined list. Returning 'other'.");
            return 'other';
          }
        } else {
          print("Gemini API category response does not contain expected text data.");
          return null;
        }
      } else {
        print("Error calling Gemini API for category: ${response.statusCode}");
        print("Response body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception during Gemini API category call: $e");
      return null;
    }
  }
}
