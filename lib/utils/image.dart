import 'dart:async';
import 'package:graphx/graphx.dart';
import 'package:schemax/utils/file.dart';

Future<GBitmap> loadNetworkImage(String url) async {
  final texture = await ResourceLoader.loadNetworkTexture(url, cacheId: url);
  return GBitmap(texture);
}

Future<GBitmap> loadLocalImage(String path) async {
  final texture = await ResourceLoader.loadTexture(path);
  return GBitmap(texture);
}

Future<GBitmap> loadImage(String path, [bool cache = true]) async {
  final isUrl = path.startsWith('http');
  if (isUrl) {
    if (!cache) {
      return loadNetworkImage(path);
    }
    final cached = ResourceLoader.textureCache[path];
    if (cached != null) {
      return GBitmap(cached);
    }
    final image = await loadImageFromPath(path);
    final texture = GTexture.fromImage(image);
    ResourceLoader.textureCache[path] = texture;
    return GBitmap(texture);
  } else {
    return loadLocalImage(path);
  }
}
