import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:revengi/utils/platform.dart';
import 'package:revengi/utils/dartinfo.dart';

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
      final elfParser = ElfParser(
        flutterLibPath: isWeb() ? null : _libflutterFile?.path,
        appLibPath: isWeb() ? null : _libappFile?.path,
        flutterLibBytes: isWeb() ? Uint8List.fromList(_libflutterBytes) : null,
        appLibBytes: isWeb() ? Uint8List.fromList(_libappBytes) : null,
      );

      final rodataInfo = elfParser.extractRodataInfo();
      final snapshotInfo = elfParser.extractSnapshotHashFlags();
      String? dartVersion = rodataInfo?.$2;

      if (dartVersion == null && rodataInfo != null) {
        final sdkInfo = await elfParser.getSdkInfo();
        dartVersion = sdkInfo?.dartVersion;
      }
      final result = StringBuffer();
      if (rodataInfo != null) {
        result.writeln('Engine IDs: ${rodataInfo.$1.join(", ")}');
        result.writeln('Dart Version: ${dartVersion ?? "unknown"}');
        result.writeln('Architecture: ${rodataInfo.$3}');
      }

      if (snapshotInfo != null) {
        result.writeln('Snapshot Hash: ${snapshotInfo.$1}');
        result.writeln('Flags: [${snapshotInfo.$2.join(", ")}]');
      }

      setState(() {
        _result = result.toString();
      });
    } catch (e) {
      setState(() {
        _error = 'An error occurred during analysis: $e';
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
                    child: SelectableText.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 14),
                        children:
                            _result!.split('\n').map((line) {
                              if (line.isEmpty) {
                                return const TextSpan(text: '\n');
                              }
                              final parts = line.split(': ');
                              if (parts.length == 2) {
                                return TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${parts[0]}: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: parts[1],
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const TextSpan(text: '\n'),
                                  ],
                                );
                              }
                              return TextSpan(text: '$line\n');
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
