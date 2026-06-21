import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oral Cancer Detection',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _result = '';
  double _confidence = 0.0;
  bool _loading = false;
  String _imageBase64 = '';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBase64 = base64Encode(bytes);
      _loading = true;
      _result = '';
    });
    await _sendToAPI(_imageBase64);
  }

  Future<void> _sendToAPI(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      );
      var json = jsonDecode(response.body);
      setState(() {
        _result = json['prediction'];
        _confidence = json['confidence'] * 100;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: Check API server!';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oral Cancer Detection'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageBase64.isNotEmpty)
              Image.memory(base64Decode(_imageBase64), height: 250)
            else
              const Icon(Icons.image, size: 150, color: Colors.grey),
            const SizedBox(height: 20),
            if (_loading)
              const CircularProgressIndicator(color: Colors.red)
            else if (_result.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _result.contains('Normal')
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _result.contains('Normal')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Column(children: [
                  Text(
                    _result.contains('Normal') ? '✅ $_result' : '⚠️ $_result',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _result.contains('Normal')
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confidence: ${_confidence.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 16),
                  ),
                ]),
              ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo),
              label: const Text('Image Select Karo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}