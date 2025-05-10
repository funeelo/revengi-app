import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:revengi/platform.dart';
import 'package:revengi/dio.dart';

class AnalysisCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const AnalysisCard({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final card = Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color:
                    isDarkMode
                        ? Theme.of(context).primaryColorLight
                        : Theme.of(context).primaryColorDark,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    if (isWeb()) {
      return Center(child: SizedBox(width: 300, height: 200, child: card));
    } else if (isWindows()) {
      return Center(child: SizedBox(width: 300, height: 200, child: card));
    } else if (isLinux()) {
      return Center(child: SizedBox(width: 300, height: 200, child: card));
    } else {
      return card;
    }
  }
}

class JniAnalysisScreen extends StatefulWidget {
  const JniAnalysisScreen({super.key});

  @override
  State<JniAnalysisScreen> createState() => _JniAnalysisScreenState();
}

class _JniAnalysisScreenState extends State<JniAnalysisScreen> {
  File? _selectedFile;
  bool _isAnalyzing = false;
  String? _result;
  String? _error;
  String? _fileName;
  List<int> _fileBytes = [];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
    );

    if (result != null) {
      if (isWeb()) {
        setState(() {
          _selectedFile = null;
          _fileName = result.files.first.name;
          _fileBytes = result.files.first.bytes!;
          _error = null;
          _result = null;
        });
      } else {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.first.name;
          _error = null;
          _result = null;
        });
      }
    }
  }

  Future<void> _analyzeFile() async {
    if (isWeb() && _fileBytes.isEmpty) {
      return;
    } else if (!isWeb() && _selectedFile == null) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _result = null;
    });

    try {
      final formData = FormData.fromMap({
        'apk_file':
            isWeb()
                ? MultipartFile.fromBytes(_fileBytes, filename: _fileName)
                : await MultipartFile.fromFile(
                  _selectedFile!.path,
                  filename:
                      _fileName ??
                      _selectedFile!.path.split(Platform.pathSeparator).last,
                ),
      });

      final response = await dio.post('/analyze/jni', data: formData);

      setState(() {
        _result = response.data.toString();
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
      appBar: AppBar(title: const Text('JNI Analysis')),
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
                    if (_selectedFile != null || _fileBytes.isNotEmpty)
                      isWeb()
                          ? Text(
                            'Selected: $_fileName',
                            style: const TextStyle(color: Colors.green),
                          )
                          : Text(
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
                                (isWeb()
                                            ? _fileBytes.isEmpty
                                            : _selectedFile == null) ||
                                        _isAnalyzing
                                    ? null
                                    : _analyzeFile,
                            icon: const Icon(Icons.analytics),
                            label: Text(
                              _isAnalyzing ? 'Analyzing...' : 'Analyze',
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
            else if (_result != null)
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(_result!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FlutterAnalysisScreen extends StatefulWidget {
  const FlutterAnalysisScreen({super.key});

  @override
  State<FlutterAnalysisScreen> createState() => _FlutterAnalysisScreenState();
}

class _FlutterAnalysisScreenState extends State<FlutterAnalysisScreen> {
  File? _libappFile;
  File? _libflutterFile;
  bool _isAnalyzing = false;
  String? _result;
  String? _error;

  Future<void> _pickLibappFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null) {
      setState(() {
        _libappFile = File(result.files.single.path!);
        _error = null;
        _result = null;
      });
      if (_libappFile!.path.split(Platform.pathSeparator).last != 'libapp.so') {
        setState(() {
          _error = 'Please select a valid libapp.so file';
          _libappFile = null;
        });
      }
    }
  }

  Future<void> _pickLibflutterFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null) {
      setState(() {
        _libflutterFile = File(result.files.single.path!);
        _error = null;
        _result = null;
      });
    }
  }

  Future<void> _analyzeFiles() async {
    if (_libappFile == null || _libflutterFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _result = null;
    });

    try {
      final formData = FormData.fromMap({
        'libapp': await MultipartFile.fromFile(
          _libappFile!.path,
          filename: _libappFile!.path.split(Platform.pathSeparator).last,
        ),
        'libflutter': await MultipartFile.fromFile(
          _libflutterFile!.path,
          filename: _libflutterFile!.path.split(Platform.pathSeparator).last,
        ),
      });

      final response = await dio.post('/analyze/flutter', data: formData);

      setState(() {
        _result = response.data.toString();
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
      appBar: AppBar(title: const Text('Flutter Analysis')),
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
                      'Select Library Files',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.library_books),
                      title: const Text('libapp'),
                      subtitle:
                          _libappFile != null
                              ? Text(
                                _libappFile!.path
                                    .split(Platform.pathSeparator)
                                    .last,
                                style: const TextStyle(color: Colors.green),
                              )
                              : const Text('No file selected'),
                      trailing: ElevatedButton(
                        onPressed: _isAnalyzing ? null : _pickLibappFile,
                        child: const Text('Choose File'),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.library_books),
                      title: const Text('libflutter'),
                      subtitle:
                          _libflutterFile != null
                              ? Text(
                                _libflutterFile!.path
                                    .split(Platform.pathSeparator)
                                    .last,
                                style: const TextStyle(color: Colors.green),
                              )
                              : const Text('No file selected'),
                      trailing: ElevatedButton(
                        onPressed: _isAnalyzing ? null : _pickLibflutterFile,
                        child: const Text('Choose File'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            (_libappFile == null ||
                                    _libflutterFile == null ||
                                    _isAnalyzing)
                                ? null
                                : _analyzeFiles,
                        icon: const Icon(Icons.analytics),
                        label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze'),
                      ),
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
            else if (_result != null)
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(_result!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BlutterAnalysisScreen extends StatefulWidget {
  const BlutterAnalysisScreen({super.key});

  @override
  State<BlutterAnalysisScreen> createState() => _BlutterAnalysisScreenState();
}

class _BlutterAnalysisScreenState extends State<BlutterAnalysisScreen> {
  File? _apkFile;
  File? _libappFile;
  File? _libflutterFile;
  bool _isAnalyzing = false;
  String? _error;
  String? _successMessage;

  Future<void> _pickApkFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null) {
      setState(() {
        _apkFile = File(result.files.single.path!);
        _error = null;
        _successMessage = null;
      });

      if (_apkFile!.path.split(Platform.pathSeparator).last.endsWith('.zip')) {
        // If the selected file is a zip file, extract the files from it
        await _extractFilesFromZip();
      } else if (_apkFile!.path
          .split(Platform.pathSeparator)
          .last
          .endsWith('.apk')) {
        await _extractFilesFromApk();
      }
    }
  }

  Future<void> _extractFilesFromZip() async {
    // In case user only has lib files and not the APK
    // assuming _apkFile is the zip file as selected
    if (_apkFile == null) return;

    final Directory directory = Directory.systemTemp;
    final apkPath = _apkFile!.path;
    final zipFile = File(apkPath);

    try {
      final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());

      for (final file in archive) {
        if (file.isFile && file.name == 'libapp.so') {
          final data = file.content as List<int>;
          _libappFile = File('${directory.path}/libapp.so')
            ..writeAsBytesSync(data);
        } else if (file.isFile && file.name == 'libflutter.so') {
          final data = file.content as List<int>;
          _libflutterFile = File('${directory.path}/libflutter.so')
            ..writeAsBytesSync(data);
        }
      }

      setState(() {
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to extract files from ZIP';
      });
    }
  }

  Future<void> _extractFilesFromApk() async {
    if (_apkFile == null) return;

    final Directory directory = Directory.systemTemp;
    final apkPath = _apkFile!.path;
    final zipFile = File(apkPath);

    try {
      final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());

      for (final file in archive) {
        if (file.isFile && file.name == 'lib/arm64-v8a/libapp.so') {
          final data = file.content as List<int>;
          _libappFile = File('${directory.path}/libapp.so')
            ..writeAsBytesSync(data);
        } else if (file.isFile && file.name == 'lib/arm64-v8a/libflutter.so') {
          final data = file.content as List<int>;
          _libflutterFile = File('${directory.path}/libflutter.so')
            ..writeAsBytesSync(data);
        }
      }

      setState(() {
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to extract files from APK';
      });
    }
  }

  Future<void> _analyzeFiles() async {
    if (_libappFile == null || _libflutterFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final formData = FormData.fromMap({
        'libapp': await MultipartFile.fromFile(
          _libappFile!.path,
          filename: _libappFile!.path.split(Platform.pathSeparator).last,
        ),
        'libflutter': await MultipartFile.fromFile(
          _libflutterFile!.path,
          filename: _libflutterFile!.path.split(Platform.pathSeparator).last,
        ),
      });

      final response = await dio.post(
        '/blutter',
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
      final selectedFileName =
          _apkFile!.path.split(Platform.pathSeparator).last.split('.').first;
      var outputFile = File(
        '${dir.path}/$filename'.replaceAll(".zip", '_$selectedFileName.zip'),
      );
      if (outputFile.existsSync()) {
        final randomNumber = DateTime.now().millisecondsSinceEpoch;
        final newFilename = filename?.replaceAll('.zip', '_$randomNumber.zip');
        outputFile = File('${dir.path}/$newFilename');
      }
      await outputFile.writeAsBytes(response.data);

      setState(() {
        _successMessage = 'Analysis saved to: ${outputFile.path}';
      });
    } on DioException catch (e) {
      setState(() {
        if (e.response?.data != null &&
            e.response?.data is Map &&
            e.response?.data['detail'] != null) {
          _error =
              e.response?.data?['detail'] ??
              'An error occurred during analysis';
        } else if (e.type == DioExceptionType.connectionTimeout) {
          _error = 'Connection timeout';
        } else if (e.type == DioExceptionType.connectionError) {
          _error = 'No internet connection';
        } else {
          _error =
              'An error occurred during analysis, please make sure you\'ve selected the correct files';
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
      appBar: AppBar(title: const Text('Blutter Analysis')),
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
                      'Select APK/Zip File',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.android),
                      title: const Text('APK/Zip File'),
                      subtitle:
                          _apkFile != null
                              ? Text(
                                _apkFile!.path
                                    .split(Platform.pathSeparator)
                                    .last,
                                style: const TextStyle(color: Colors.green),
                              )
                              : const Text('No file selected'),
                      trailing: ElevatedButton(
                        onPressed: _isAnalyzing ? null : _pickApkFile,
                        child: const Text('Choose File'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            (_apkFile == null || _isAnalyzing)
                                ? null
                                : _analyzeFiles,
                        icon: const Icon(Icons.analytics),
                        label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze'),
                      ),
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
