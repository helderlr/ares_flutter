import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ScreenCaptureService {
  static Future<Uint8List?> capturePng(GlobalKey key) async {
    final RenderObject? renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      return null;
    }
    final ui.Image image = await renderObject.toImage(pixelRatio: 3.0);
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  static Future<void> sharePngBytes({
    required Uint8List bytes,
    required String fileName,
    String? text,
  }) async {
    final Directory directory = await getTemporaryDirectory();
    final File file = File('${directory.path}/$fileName.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      <XFile>[XFile(file.path, mimeType: 'image/png')],
      text: text,
    );
  }

  static Future<void> sharePdfFile({
    required Uint8List bytes,
    required String fileName,
    String? text,
  }) async {
    final Directory directory = await getTemporaryDirectory();
    final File file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      <XFile>[XFile(file.path, mimeType: 'application/pdf')],
      text: text,
    );
  }
}
