import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:revengi/platform.dart';
import 'package:revengi/dio.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

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
      type: isWeb() ? FileType.custom : FileType.any,
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
    if ((isWeb() && _fileBytes.isEmpty) ||
        (!isWeb() && _selectedFile == null)) {
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
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      setState(() {
        if (username == "guest") {
          _error = "Guest users cannot use this feature";
        } else {
          _error =
              e.response?.data?['detail'] ??
              'An error occurred during analysis';
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
  String? _fileName;
  List<int> _libappBytes = [];
  List<int> _libflutterBytes = [];

  Future<void> _pickLibappFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null) {
      if (isWeb()) {
        setState(() {
          _fileName = result.files.first.name;
          _libappBytes = result.files.first.bytes!;
          _libappFile = null;
          _error = null;
          _result = null;
        });
      } else {
        setState(() {
          _libappFile = File(result.files.single.path!);
          _fileName = result.files.first.name;
          _error = null;
          _result = null;
        });
      }

      final bytes = isWeb() ? _libappBytes : await _libappFile!.readAsBytes();
      final elfMagic = bytes.sublist(0, 4);
      if (elfMagic[0] != 0x7f ||
          elfMagic[1] != 0x45 ||
          elfMagic[2] != 0x4c ||
          elfMagic[3] != 0x46) {
        setState(() {
          _error = 'Please select a valid ELF file';
          _libappFile = null;
          _libappBytes = [];
        });
      }
      if (_fileName != 'libapp.so') {
        setState(() {
          _error = 'Please select a valid libapp.so file';
          _libappFile = null;
          _libappBytes = [];
        });
      }
    }
  }

  Future<void> _pickLibflutterFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null) {
      if (isWeb()) {
        setState(() {
          _fileName = result.files.first.name;
          _libflutterBytes = result.files.first.bytes!;
          _libflutterFile = null;
          _error = null;
          _result = null;
        });
      } else {
        setState(() {
          _fileName = result.files.first.name;
          _libflutterFile = File(result.files.single.path!);
          _error = null;
          _result = null;
        });
      }
      final bytes =
          isWeb() ? _libflutterBytes : await _libflutterFile!.readAsBytes();
      final elfMagic = bytes.sublist(0, 4);
      if (elfMagic[0] != 0x7f ||
          elfMagic[1] != 0x45 ||
          elfMagic[2] != 0x4c ||
          elfMagic[3] != 0x46) {
        setState(() {
          _error = 'Please select a valid ELF file';
          _libflutterFile = null;
          _libflutterBytes = [];
        });
      }
      if (_fileName != 'libflutter.so') {
        setState(() {
          _error = 'Please select a valid libflutter.so file';
          _libflutterFile = null;
          _libflutterBytes = [];
        });
      }
    }
  }

  Future<void> _analyzeFiles() async {
    if ((isWeb() && (_libappBytes.isEmpty || _libflutterBytes.isEmpty)) ||
        (!isWeb() && (_libappFile == null || _libflutterFile == null))) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _result = null;
    });

    try {
      final formData = FormData.fromMap({
        'libapp':
            isWeb()
                ? MultipartFile.fromBytes(_libappBytes, filename: 'libapp.so')
                : await MultipartFile.fromFile(
                  _libappFile!.path,
                  filename:
                      _libappFile!.path.split(Platform.pathSeparator).last,
                ),
        'libflutter':
            isWeb()
                ? MultipartFile.fromBytes(
                  _libflutterBytes,
                  filename: 'libflutter.so',
                )
                : await MultipartFile.fromFile(
                  _libflutterFile!.path,
                  filename:
                      _libflutterFile!.path.split(Platform.pathSeparator).last,
                ),
      });

      final response = await dio.post('/analyze/flutter', data: formData);

      setState(() {
        _result = response.data.toString();
      });
    } on DioException catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      setState(() {
        if (username == "guest") {
          _error = "Guest users cannot use this feature";
        } else {
          _error =
              e.response?.data?['detail'] ??
              'An error occurred during analysis';
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
                          (_libappFile != null || _libappBytes.isNotEmpty)
                              ? isWeb()
                                  ? Text('libapp.so')
                                  : Text(
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
                          (_libflutterFile != null ||
                                  _libflutterBytes.isNotEmpty)
                              ? isWeb()
                                  ? const Text('libflutter.so')
                                  : Text(
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
                            (isWeb()
                                        ? (_libappBytes.isEmpty ||
                                            _libflutterBytes.isEmpty)
                                        : (_libappFile == null ||
                                            _libflutterFile == null)) ||
                                    _isAnalyzing
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
