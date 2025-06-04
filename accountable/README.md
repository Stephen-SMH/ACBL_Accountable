# Accountable (Ena)

Use LLMs and Object Recognition to automatically put your transaction into a lightweight budgeting system!

### Key Features
*   **Transaction Management**: Core functionality for adding, viewing, and summarizing financial transactions.
*   **Document Processing**: Supports PDF and image file uploads for data extraction.
*   **AI Integration**: Leverages Google Gemini for text analysis and custom models for object detection in images.
*   **Local Persistence**: Uses SQFlite for robust local data storage.
*   **Camera Access**: Direct camera integration for capturing transaction-related images.
*   **Cross-Platform**: Developed with Flutter for deployment on Android, iOS, Web, and Desktop.

### Technologies
*   **Framework**: Flutter (Dart)
*   **AI/ML**: TensorFlow Lite, Google Gemini API
*   **Database**: SQFlite
*   **State Management**: Provider
*   **Navigation**: Go Router
*   **UI**: Shadcn Flutter
*   **Utilities**: `file_picker`, `image_picker`, `path_provider`, `video_player`, `syncfusion_flutter_pdf`, `graphic`, `intl`, `flutter_dotenv`, `image`.

### Getting Started

#### Prerequisites
*   Flutter SDK (>= `3.5.3`)
*   Dart SDK

#### Installation
1.  **Clone**: `git clone [repository_url]`
2.  **Navigate**: `cd accountable`
3.  **Dependencies**: `flutter pub get`

#### Environment Variables (`.env`)
Create a `.env` file in the root directory:
```
GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```
*   **`GEMINI_API_KEY`**: Required for Google Gemini API access.

#### Running the Application
```bash
flutter run
```
To specify a platform: `flutter run -d [android|ios|chrome|windows|macos|linux]`

### Project Structure
*   `lib/`: Application source code.
    *   `backend/`: Application state and business logic.
    *   `presentation/pages/`: Main UI screens.
    *   `presentation/widgets/`: Reusable UI components.
    *   `services/`: External API integrations (Gemini, object detection).
*   `assets/`: Static resources (TFLite models, Tesseract data, images).
*   `android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/`: Platform-specific build configurations.
