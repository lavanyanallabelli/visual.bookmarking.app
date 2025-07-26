import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class ScreenshotGalleryPage extends StatefulWidget {
  const ScreenshotGalleryPage({super.key});

  @override
  _ScreenshotGalleryPageState createState() => _ScreenshotGalleryPageState();
}

class _ScreenshotGalleryPageState extends State<ScreenshotGalleryPage> {
  static const EventChannel _eventChannel = EventChannel(
    'com.example.screenshot/events',
  );
  List<String> _screenshotPaths = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _askPermissions();
    _loadScreenshots();
    _listenForScreenshots();
  }

  /// ✅ Ask for storage permissions
  Future<void> _askPermissions() async {
    await Permission.storage.request();
    await Permission.photos.request();
  }

  /// ✅ Load saved screenshots from local storage
  Future<void> _loadScreenshots() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedPaths = prefs.getStringList('screenshots');
    if (savedPaths != null) {
      setState(() {
        _screenshotPaths = savedPaths;
      });
    }
  }

  /// ✅ Save screenshot list locally
  Future<void> _saveScreenshots() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('screenshots', _screenshotPaths);
  }

  /// ✅ Listen for new screenshots
  void _listenForScreenshots() {
    _eventChannel.receiveBroadcastStream().listen((event) {
      String filePath = event.toString();
      print("📸 Screenshot detected: $filePath");

      if (!_screenshotPaths.contains(filePath)) {
        setState(() {
          _screenshotPaths.add(filePath);
        });
        _saveScreenshots(); // persist locally
        _uploadScreenshot(filePath); // upload in background
      }
    });
  }

  /// ✅ Upload screenshot to Firebase
  Future<void> _uploadScreenshot(String filePath) async {
    setState(() => _isUploading = true);

    try {
      File file = File(filePath);
      String fileName = path.basename(filePath);

      // Upload to Firebase Storage
      Reference storageRef = FirebaseStorage.instance.ref(
        'screenshots/$fileName',
      );
      await storageRef.putFile(file);
      String downloadURL = await storageRef.getDownloadURL();

      // Save URL in Firestore
      await FirebaseFirestore.instance.collection('screenshots').add({
        'url': downloadURL,
        'timestamp': DateTime.now().toIso8601String(),
      });

      print("✅ Uploaded $fileName to Firebase!");
    } catch (e) {
      print("❌ Error uploading screenshot: $e");
    }

    setState(() => _isUploading = false);
  }

  /// ✅ Open image in full-screen
  void _openFullScreen(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImagePage(imagePath: imagePath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Screenshot Gallery")),
      body: _screenshotPaths.isEmpty
          ? const Center(child: Text("No screenshots yet"))
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _screenshotPaths.length,
              itemBuilder: (context, index) {
                String imagePath = _screenshotPaths[index];
                return GestureDetector(
                  onTap: () => _openFullScreen(imagePath),
                  child: Image.file(File(imagePath), fit: BoxFit.cover),
                );
              },
            ),
      floatingActionButton: _isUploading
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          : null,
    );
  }
}

/// ✅ Full-screen Image Page
class FullScreenImagePage extends StatelessWidget {
  final String imagePath;
  const FullScreenImagePage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(child: Image.file(File(imagePath))),
    );
  }
}
