import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'views/app_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GourmetGoApp());
}

class GourmetGoApp extends StatelessWidget {
  const GourmetGoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'GourmetGo',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB64E2E),
        surface: const Color(0xFFFFFBF7),
      ),
      useMaterial3: true,
    ),
    home: const AuthGate(),
  );
}
