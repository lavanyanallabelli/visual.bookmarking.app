import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<void> _askPermissions() async {
    await Permission.storage.request();
    await Permission.photos.request();
  }

  Future<void> _loadScreenshots() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedPaths = prefs.getStringList('screenshots');

    if (savedPaths != null) {
      // ✅ Remove paths where file doesn't exist
      savedPaths.removeWhere((path) => !File(path).existsSync());
      setState(() {
        _screenshotPaths = savedPaths;
      });
    }
  }

  Future<void> _saveScreenshots() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('screenshots', _screenshotPaths);
  }

  void _listenForScreenshots() {
    _eventChannel.receiveBroadcastStream().listen((event) async {
      final Map<String, dynamic> data = jsonDecode(event);
      String originalPath = data['path'];
      String appName = data['app'];

      print("📸 Screenshot detected: $originalPath");

      final appDir = await getApplicationDocumentsDirectory();
      final newPath = '${appDir.path}/${path.basename(originalPath)}';
      await File(originalPath).copy(newPath);

      if (!_screenshotPaths.contains(newPath)) {
        setState(() {
          _screenshotPaths.add(newPath);
        });
        _saveScreenshots();
        _uploadScreenshot(newPath);
      }
    });
  }

  Future<void> _uploadScreenshot(String filePath) async {
    setState(() => _isUploading = true);

    try {
      File file = File(filePath);
      if (!file.existsSync()) return;

      String fileName = path.basename(filePath);
      Reference storageRef = FirebaseStorage.instance.ref(
        'screenshots/$fileName',
      );
      await storageRef.putFile(file);
      String downloadURL = await storageRef.getDownloadURL();

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
                if (!File(imagePath).existsSync()) {
                  return const Icon(Icons.broken_image, color: Colors.grey);
                }
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

class FullScreenImagePage extends StatelessWidget {
  final String imagePath;
  const FullScreenImagePage({super.key, required this.imagePath});

  Future<void> _openApp() async {
    if (imagePath.contains("Instagram")) {
      final Uri url = Uri.parse('instagram://');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await launchUrl(Uri.parse('https://instagram.com'));
      }
    } else if (imagePath.contains("YouTube")) {
      final Uri url = Uri.parse('youtube://');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await launchUrl(Uri.parse('https://youtube.com'));
      }
    } else {
      print("No matching app detected.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(child: Center(child: Image.file(File(imagePath)))),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              onPressed: _openApp,
              child: const Text("Open in Source App"),
            ),
          ),
        ],
      ),
    );
  }
}
