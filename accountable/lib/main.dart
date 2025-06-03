// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:accountable/backend/app_state.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'router.dart'; // import your router

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransList()),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp.router(
      routerConfig: router,
      title: 'Accountable',
      theme: ThemeData(
        colorScheme: ColorSchemes.lightBlue(),
        radius: 1.0,
      ),
    );
  }
}
