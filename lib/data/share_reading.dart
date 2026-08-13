import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// 把挂在 [boundaryKey] 上的 [RepaintBoundary]（比如离屏渲染的分享卡
/// widget）截成一张 PNG 的字节数据——只负责截图，不负责调起分享面板，
/// 拿到字节后可以先给用户看预览，确认了再调 [shareImageBytes]。
Future<Uint8List?> captureRepaintBoundaryPng(
  GlobalKey boundaryKey, {
  double pixelRatio = 3,
}) async {
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;

  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return null;
  return byteData.buffer.asUint8List();
}

/// 把已经截好的 PNG 字节调起系统分享面板——WhatsApp、Instagram、Threads
/// 等等只要手机上装了，都会自动出现在分享列表里，不用针对每个 App 单独
/// 接一遍。
Future<void> shareImageBytes(
  Uint8List bytes, {
  String fileName = 'tarot-reading.png',
  String? text,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
      text: text,
    ),
  );
}
