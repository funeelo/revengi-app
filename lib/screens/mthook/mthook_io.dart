import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:revengi/dio.dart';
import 'package:revengi/platform.dart' show getDownloadsDirectory;

class MTHookAnalysisScreen extends StatefulWidget {
  const MTHookAnalysisScreen({super.key});

  @override
  State<MTHookAnalysisScreen> createState() => _MTHookAnalysisScreenState();
}

class _MTHookAnalysisScreenState extends State<MTHookAnalysisScreen> {
  File? _selectedFile;
  bool _isAnalyzing = false;
  String? _error;
  String? _successMessage;
  String? _fileName;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _error = null;
        _successMessage = null;
      });
    }
  }

  Future<void> _analyzeFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final formData = FormData.fromMap({
        'apk_file': await MultipartFile.fromFile(
          _selectedFile!.path,
          filename:
              _fileName ??
              _selectedFile!.path.split(Platform.pathSeparator).last,
        ),
      });

      final response = await dio.post(
        '/mthook',
        data: formData,
        options: Options(responseType: ResponseType.bytes),
      );

      // Save response bytes to file
      final Directory dir = Directory(getDownloadsDirectory());
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      final filename = response.headers['content-disposition']?.first
          .split('filename=')[1]
          .replaceAll('"', '');
      var outputFile = File('${dir.path}/$filename');
      if (outputFile.existsSync()) {
        final randomNumber = DateTime.now().millisecondsSinceEpoch;
        final newFilename = filename?.replaceAll('.zip', '_$randomNumber.zip');
        outputFile = File('${dir.path}/$newFilename');
      }
      await outputFile.writeAsBytes(response.data);

      setState(() {
        _successMessage = 'Saved to: ${outputFile.path}';
      });
    } on DioException catch (e) {
      setState(() {
        _error =
            e.response?.data?['detail'] ?? 'An error occurred during analysis';
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MT Hook Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select APK File',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedFile != null)
                      Text(
                        'Selected: ${_fileName ?? _selectedFile!.path.split(Platform.pathSeparator).last}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isAnalyzing ? null : _pickFile,
                            icon: const Icon(Icons.file_upload),
                            label: const Text('Choose APK'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                (_selectedFile == null) || _isAnalyzing
                                    ? null
                                    : _analyzeFile,
                            icon: const Icon(Icons.analytics),
                            label: Text(
                              _isAnalyzing ? 'Generating...' : 'Generate',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isAnalyzing)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red[900]),
                  ),
                ),
              )
            else if (_successMessage != null)
              Card(
                color: Colors.green[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _successMessage!,
                    style: TextStyle(color: Colors.green[900]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
