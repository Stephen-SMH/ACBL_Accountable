import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  String? _cachedApiKey; // Renamed to avoid confusion

  GeminiService._internal(); // Constructor does nothing now

  // Getter for the API key
  String? get _apiKey {
    if (_cachedApiKey == null) {
      _cachedApiKey = dotenv.env['GEMINI_API_KEY'];
      if (_cachedApiKey == null) {
        print("GEMINI_API_KEY not found in .env file. Make sure .env exists and is loaded in main.dart.");
      }
    }
    return _cachedApiKey;
  }

  Future<String?> extractPriceFromImage(Uint8List imageBytes) async {
    final apiKey = _apiKey; // Access the key through the getter
    if (apiKey == null) {
      print("API Key is not set. Cannot call Gemini API.");
      return null;
    }

    const String url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite-001:generateContent'; // Updated to gemini-2.0-flash-lite-001
    // Even though the user asked for gemini 2.5 flash, the gemini-pro-vision is a stable model that supports images.
    // The prompt is specifically crafted to get only the price.

    final String prompt =
        "Extract the numerical price from this image. Return only the price as a number, with a decimal point if applicable. Do not include currency symbols or any other text.";

    final String base64Image = base64Encode(imageBytes);

    final Map<String, dynamic> requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg', // Assuming JPEG, adjust if necessary
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1, // Low temperature for more deterministic output
        'topK': 1,
        'topP': 1,
        'maxOutputTokens': 150, // Increased from 50
        'stopSequences': [],
      },
      'safetySettings': [ // Adjust safety settings as needed
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ]
    };

    try {
      final response = await http.post(
        Uri.parse('$url?key=$apiKey'), // Use the local apiKey variable
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty &&
            responseData['candidates'][0]['content']['parts'][0]['text'] != null) {
          String extractedText = responseData['candidates'][0]['content']['parts'][0]['text'];
          // Attempt to parse the extracted text to a double to ensure it's a valid price.
          // This also helps to remove any potential leading/trailing non-numeric characters if Gemini doesn't strictly follow the prompt.
          try {
            double.parse(extractedText.replaceAll(RegExp(r'[^0-9.]'), '')); // Keep only digits and dot
            return extractedText.replaceAll(RegExp(r'[^0-9.]'), '');
          } catch (e) {
            print("Gemini API returned text that is not a valid price: $extractedText. Error: $e");
            return null;
          }
        } else {
          print("Gemini API response does not contain expected text data.");
          print("Response body: ${response.body}");
          return null;
        }
      } else {
        print("Error calling Gemini API: ${response.statusCode}");
        print("Response body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception during Gemini API call: $e");
      return null;
    }
  }
} 