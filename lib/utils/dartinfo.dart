import 'dart:io';
import 'dart:typed_data';
import 'package:native_stack_traces/elf.dart';
import 'package:archive/archive_io.dart';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';

// Based on https://github.com/worawit/blutter/blob/main/extract_dart_info.py python implementation

class DartSDKInfo {
  final String? dartVersion;

  const DartSDKInfo({this.dartVersion});
}

class ZipHeaderInfo {
  final String filename;
  final Uint8List fileData;
  final int nextOffset;
  final int compressionMethod;

  ZipHeaderInfo(
    this.filename,
    this.fileData,
    this.nextOffset,
    this.compressionMethod,
  );
}

class ElfParser {
  final String? flutterLibPath;
  final String? appLibPath;
  final Uint8List? flutterLibBytes;
  final Uint8List? appLibBytes;
  final Dio _dio;

  ElfParser({
    this.flutterLibPath,
    this.appLibPath,
    this.flutterLibBytes,
    this.appLibBytes,
  }) : _dio = Dio(BaseOptions(validateStatus: (status) => status! < 500)) {
    if (flutterLibPath == null && flutterLibBytes == null) {
      throw ArgumentError(
        'Either flutterLibPath or flutterLibBytes must be provided',
      );
    }
  }

  Uint8List _getBytes(String? path, Uint8List? bytes) {
    if (bytes != null) return bytes;
    if (path != null) return File(path).readAsBytesSync();
    throw ArgumentError('Either path or bytes must be provided');
  }

  (List<String>, String?, String)? extractRodataInfo() {
    try {
      final bytes = _getBytes(flutterLibPath, flutterLibBytes);
      final elf = Elf.fromBuffer(bytes);
      if (elf == null) return null;

      final architecture = elf.architecture!;

      final rodataSections = elf.namedSections('.rodata');
      if (rodataSections.isEmpty) return null;

      final rodata = rodataSections.first;
      final rawDataBytes = bytes.sublist(
        rodata.offset,
        rodata.offset + rodata.length,
      );
      final rawData = String.fromCharCodes(rawDataBytes);

      final regex = RegExp(r'\x00([a-f\d]{40})(?=\x00)');
      final matches = regex.allMatches(rawData);
      final engineIds = matches.map((match) => match.group(1)!).toList();

      final epos = rawData.indexOf(' (stable) (');
      String? dartVersion;
      if (epos != -1) {
        final pos = rawData.lastIndexOf('\x00', epos) + 1;
        dartVersion = rawData.substring(pos, epos);
      }

      return (engineIds, dartVersion, architecture);
    } catch (e) {
      return null;
    }
  }

  (String, List<String>)? extractSnapshotHashFlags() {
    try {
      final bytes = _getBytes(appLibPath, appLibBytes);
      final elf = Elf.fromBuffer(bytes);
      if (elf == null) return null;

      int vmSnapshotDataOffset = 0;
      for (final symbol in elf.dynamicSymbols) {
        if (symbol.name == vmDataSymbolName) {
          vmSnapshotDataOffset = symbol.value;
          break;
        }
      }

      final dataStart = vmSnapshotDataOffset + 20;
      final snapshotHash = String.fromCharCodes(
        bytes.sublist(dataStart, dataStart + 32),
      );

      final flagsData = bytes.sublist(dataStart + 32, dataStart + 288);
      final nullTerminator = flagsData.indexOf(0);
      final flags =
          String.fromCharCodes(
            flagsData.sublist(0, nullTerminator),
          ).trim().split(' ').where((f) => f.isNotEmpty).toList();

      return (snapshotHash, flags);
    } catch (e) {
      return null;
    }
  }

  Future<DartSDKInfo?> getSdkInfo() async {
    final rodataInfo = extractRodataInfo();
    final engineIds = rodataInfo?.$1;
    if (engineIds == null || engineIds.isEmpty) return null;

    for (final engineId in engineIds) {
      final sdkUrl =
          'https://storage.googleapis.com/flutter_infra_release/flutter/$engineId/dart-sdk-windows-x64.zip';

      try {
        final response = await _dio.headUri(Uri.parse(sdkUrl));
        if (response.statusCode == 200) {
          final contentLengthList = response.headers['content-length'];
          if (contentLengthList != null && contentLengthList.isNotEmpty) {
            final commitData = await _getDartCommit(sdkUrl);

            return DartSDKInfo(dartVersion: commitData.$2);
          }
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  Future<(String?, String?)> _getDartCommit(String sdkUrl) async {
    try {
      final response = await _dio.get(
        sdkUrl,
        options: Options(
          headers: {"Range": "bytes=0-4096"},
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode! ~/ 10 != 20) return (null, null);

      final bytes = response.data as Uint8List;
      final data = bytes.buffer.asByteData();
      var offset = 0;
      String? commitId;
      String? dartVersion;

      while (offset < bytes.length - 30 &&
          (commitId == null || dartVersion == null)) {
        if (data.getUint32(offset, Endian.little) != 0x04034b50) break;

        final headerInfo = _extractZipHeaderInfo(data, offset, bytes);
        if (headerInfo == null) break;

        offset = headerInfo.nextOffset;

        if (headerInfo.compressionMethod == 8) {
          try {
            final decompressed = Inflate(headerInfo.fileData).getBytes();
            final content = utf8.decode(decompressed).trim();
            if (headerInfo.filename == 'dart-sdk/revision') {
              commitId = content;
            } else if (headerInfo.filename == 'dart-sdk/version') {
              dartVersion = content;
            }
          } catch (_) {}
        }
      }

      return (commitId, dartVersion);
    } catch (e) {
      return (null, null);
    }
  }

  ZipHeaderInfo? _extractZipHeaderInfo(
    ByteData data,
    int offset,
    Uint8List bytes,
  ) {
    try {
      final compMethod = data.getUint16(offset + 8, Endian.little);
      final compSize = data.getUint32(offset + 18, Endian.little);
      final fnameLen = data.getUint16(offset + 26, Endian.little);
      final extraLen = data.getUint16(offset + 28, Endian.little);

      final fnameStart = offset + 30;
      final fnameEnd = fnameStart + fnameLen;
      final filename = utf8.decode(
        bytes.sublist(fnameStart, fnameEnd),
        allowMalformed: true,
      );

      final fileDataStart = fnameEnd + extraLen;
      final fileDataEnd = fileDataStart + compSize;

      if (fileDataEnd > bytes.length) return null;

      final fileData = bytes.sublist(fileDataStart, fileDataEnd);
      return ZipHeaderInfo(filename, fileData, fileDataEnd, compMethod);
    } catch (e) {
      return null;
    }
  }
}
