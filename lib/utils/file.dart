import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

Future<ui.Image> loadImageFromPath(String path, [bool cache = true]) async {
  final file = cache
      ? await DefaultCacheManager().getSingleFile(path)
      : File(path);
  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes, allowUpscaling: false);
  return (await codec.getNextFrame()).image;
}
