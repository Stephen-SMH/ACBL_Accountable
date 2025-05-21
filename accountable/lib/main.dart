import 'package:accountable/backend/app_state.dart';
import 'package:flutter/cupertino.dart';

// Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'firebase_options.dart';

import 'package:accountable/presentation/pages/home_page.dart';
import 'package:accountable/presentation/pages/file_upload_screen.dart';
import 'package:accountable/presentation/pages/summary_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => TransList(),
        ),
        ChangeNotifierProvider(
          create: (context) => AppState(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// --- App Entry ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: 'My Ap',
      home: const MainSegmentedControl(),
      theme: ThemeData(
        colorScheme: ColorSchemes.lightGray(),
        radius: 1.0,
      ),
    );
  }
}

class MainSegmentedControl extends StatefulWidget {
  const MainSegmentedControl({super.key});

  @override
  State<MainSegmentedControl> createState() => _MainSegmentedControlState();
}

class _MainSegmentedControlState extends State<MainSegmentedControl> {
  int _selectedIndex = 0;

  final Map<int, Widget> children = const {
    0: Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Home',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    1: Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'New',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    2: Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Summary',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemIndigo.withOpacity(0.1),
        border: null,
        middle: CupertinoSlidingSegmentedControl<int>(
          groupValue: _selectedIndex,
          onValueChanged: (value) {
            setState(() {
              _selectedIndex = value!;
            });
          },
          thumbColor: CupertinoColors.systemIndigo.withOpacity(0.8),
          backgroundColor: CupertinoColors.systemBackground,
          children: children,
        ),
        trailing: _selectedIndex == 0
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.add,
                  color: CupertinoColors.systemIndigo,
                ),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).push(
                    CupertinoPageRoute(
                      builder: (context) => const FileUploadScreen(),
                    ),
                  );
                },
              )
            : null,
      ),
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildPage(_selectedIndex),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomePage(detailsPath: '/transaction_details');
      case 1:
        //return const FileUploadScreen();
      case 2:
        return const BudgetSummaryScreen();
      default:
        return const HomePage(detailsPath: '/transaction_details');
    }
  }
}
