import 'dart:typed_data';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:revengi/utils/platform.dart';
import 'package:revengi/utils/dio.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import 'package:web/web.dart' as web;

class MTHookAnalysisScreen extends StatefulWidget {
  const MTHookAnalysisScreen({super.key});

  @override
  State<MTHookAnalysisScreen> createState() => _MTHookAnalysisScreenState();
}

class _MTHookAnalysisScreenState extends State<MTHookAnalysisScreen> {
  bool _isAnalyzing = false;
  String? _error;
  String? _successMessage;
  String? _fileName;
  List<int> _fileBytes = [];
  late double _uploadProgress;
  late double _downloadProgress;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null) {
      if (isWeb()) {
        setState(() {
          _fileName = result.files.first.name;
          _fileBytes = result.files.first.bytes!;
          _error = null;
          _successMessage = null;
        });
      } else {
        setState(() {
          _error = null;
          _successMessage = null;
        });
      }
    }
  }

  Future<void> _analyzeFile() async {
    if (_fileBytes.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _successMessage = null;
      _uploadProgress = 0;
      _downloadProgress = 0;
    });

    try {
      final formData = FormData.fromMap({
        'apk_file': MultipartFile.fromBytes(_fileBytes, filename: _fileName),
      });

      final response = await dio.post(
        '/mthook',
        data: formData,
        options: Options(responseType: ResponseType.bytes),
        onSendProgress: (int sent, int total) {
          setState(() {
            _uploadProgress = sent / total;
          });
        },
        onReceiveProgress: (int received, int total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      // Save response bytes to file
      final filename =
          response.headers['content-disposition']?.first
              .split('filename=')[1]
              .replaceAll('"', '') ??
          'output.zip';

      final bytes = Uint8List.fromList(response.data);
      String url = web.URL.createObjectURL(
        web.Blob(
          <JSUint8Array>[bytes.toJS].toJS,
          web.BlobPropertyBag(type: ResponseType.bytes.toString()),
        ),
      );
      web.Document htmlDocument = web.document;
      web.HTMLAnchorElement anchor =
          htmlDocument.createElement('a') as web.HTMLAnchorElement;
      anchor.href = url;
      anchor.style.display = filename;
      anchor.download = filename;
      web.document.body!.add(anchor);
      anchor.click();
      anchor.remove();

      setState(() {
        _successMessage = 'Download started...';
      });
    } on DioException catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      setState(() {
        if (username == "guest") {
          _error = "Guest users cannot use this feature";
        } else {
          if (e.response?.data != null &&
              e.response?.data is Map &&
              e.response?.data['detail'] != null) {
            _error =
                e.response?.data?['detail'] ??
                'An error occurred during analysis';
          }
        }
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
                    if (_fileBytes.isNotEmpty)
                      Text(
                        'Selected: $_fileName',
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
                                (_fileBytes.isEmpty) || _isAnalyzing
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
            if (_isAnalyzing) ...[
              if (_uploadProgress > 0 && _uploadProgress < 1)
                Column(
                  children: [
                    const Text('Uploading...'),
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 8),
                  ],
                ),
              if (_downloadProgress > 0 && _downloadProgress < 1)
                Column(
                  children: [
                    const Text('Downloading...'),
                    LinearProgressIndicator(value: _downloadProgress),
                    const SizedBox(height: 8),
                  ],
                ),
              if (_uploadProgress == 0 && _downloadProgress == 0)
                const Center(child: CircularProgressIndicator()),
            ] else if (_error != null)
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
