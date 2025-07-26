
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screenshot_gallery_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

 //✅ Initialize Firebase
  await Firebase.initializeApp();

  print("✅ Firebase Connected!");

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Screenshot Detector',
      theme: ThemeData(primarySwatch: Colors.blue),
      home:
          const ScreenshotGalleryPage(), // ✅ Navigate directly to gallery page
    );
  }
}

// 

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:firebase_core/firebase_core.dart';
// 
// void main() async{
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  // print("✅ Firebase Connected!");
  // runApp(const MainApp());
  // 
// }
// 
// class MainApp extends StatefulWidget {
  // const MainApp({super.key});
// 
  // @override
  // State<MainApp> createState() => _MainAppState();
// }
// 
// class _MainAppState extends State<MainApp> {
 // EventChannel to receive data from native Android
  // static const EventChannel _eventChannel =
      // EventChannel('com.example.screenshot/events');
// 
  // String _lastScreenshot = 'No screenshot detected yet';
// 
  // @override
  // void initState() {
    // super.initState();
    // _askPermissions();
    // _startListening();
  // }
// 
//  Request permissions for reading screenshots
  // Future<void> _askPermissions() async {
    // await Permission.storage.request(); // For older Android versions
    // await Permission.photos.request();  // For newer Android versions
  // }
// 
//  Listen to screenshot events from native code
  // void _startListening() {
    // _eventChannel.receiveBroadcastStream().listen((event) {
      // setState(() {
        // _lastScreenshot = event.toString();
      // });
    // }, onError: (error) {
      // print('Error: $error');
    // });
  // }
// 
  // @override
  // Widget build(BuildContext context) {
    // return MaterialApp(
      // home: Scaffold(
        // appBar: AppBar(title: const Text('Screenshot Detector')),
        // body: Center(
          // child: Text(
            // 'Last Screenshot Path:\n$_lastScreenshot',
            // textAlign: TextAlign.center,
            // style: const TextStyle(fontSize: 16),
          // ),
        // ),
      // ),
    // );
  // }
// }