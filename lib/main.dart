// lib/main.dart
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:window_size/window_size.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set minimum window size if running on desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowMinSize(const Size(768, 850)); // Minimum window size
    setWindowTitle('KML Generator');
    
    // Get screen size and calculate center position
    final screen = await getCurrentScreen();
    if (screen != null) {
      final screenFrame = screen.visibleFrame;
      const windowWidth = 800.0;
      const windowHeight = 890.0;
      final left = (screenFrame.width - windowWidth) / 2;
      final top = (screenFrame.height - windowHeight) / 2;
      
      setWindowFrame(Rect.fromLTWH(left, top, windowWidth, windowHeight));
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KML Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}