import 'package:graphx/graphx.dart';
import 'package:schemax/renderer/core.dart';

double calcKeepSizeZoom(double prev, double next) {
  final scale = next / prev;
  return 1 / scale;
}

void keepElementSize(
  RendererCore renderer,
  GDisplayObject obj, [
  Function(ZoomEventData zoom, double scale)? onScale,
]) {
  final initialScale = obj.scale;
  var lastZoom = 1.0;

  renderer.onZoom((zoom) {
    // 累积总缩放
    lastZoom = zoom.nextScale;
    // 基于初始缩放值和当前画布缩放计算补偿
    final newScale = initialScale / lastZoom;
    obj.setScale(newScale);
    onScale?.call(zoom, newScale);
  });
}
