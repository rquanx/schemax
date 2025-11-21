import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../plugins/interactive.dart';
import '../renderer/core.dart';
import '../renderer/schema.dart';

/// Emits callbacks when schema elements meet a visibility threshold inside
/// the viewport.
class ViewportVisibilityPlugin extends InteractivePlugin {
  ViewportVisibilityPlugin({this.onVisible, this.visibilityThreshold = 0.25});

  final double visibilityThreshold;
  final void Function(SchemaElement? element)? onVisible;

  void _notifyVisible(RendererCore renderer) {
    final element = renderer.schemaElements.firstWhereOrNull((element) {
      final rect = renderer.rectTransformWithConfig(element);
      final scale = renderer.viewportScale;
      final elementRect = Rect.fromLTWH(
        rect.x,
        rect.y,
        rect.width,
        rect.height,
      );

      final viewportOffset = renderer.viewportPosition;
      final viewportRect = Rect.fromLTWH(
        -viewportOffset.dx / scale,
        -viewportOffset.dy / scale,
        renderer.stageWidth / scale,
        renderer.stageHeight / scale,
      );

      final intersection = elementRect.intersect(viewportRect);
      if (intersection.isEmpty) {
        return false;
      }

      final visibleArea = viewportRect.width * viewportRect.height;
      final intersectionArea = intersection.width * intersection.height;
      final visibleRatio = intersectionArea / visibleArea;
      return visibleRatio > visibilityThreshold;
    });
    onVisible?.call(element);
  }

  @override
  void onMove(
    RendererCore renderer,
    ScaleUpdateDetails details,
    double x,
    double y,
  ) {
    _notifyVisible(renderer);
  }

  @override
  void onScale(
    RendererCore renderer,
    ScaleUpdateDetails details,
    double scale,
  ) {
    _notifyVisible(renderer);
  }
}
