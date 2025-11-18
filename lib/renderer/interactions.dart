import 'package:flutter/material.dart';

import 'core.dart';
import 'plugin_manager.dart';

/// Centralizes all touch interactions so that [RendererCore] can stay
/// focused on drawing and animation responsibilities.
class RendererInteractions {
  RendererInteractions(this.renderer, this.pluginManager);

  final RendererCore renderer;
  final RendererPluginManager pluginManager;

  double _contentX = 0.0;
  double _contentY = 0.0;
  double _initDX = 0.0;
  double _initDY = 0.0;
  double _grabScale = 1.0;

  void handleScaleStart(ScaleStartDetails details) {
    if (details.pointerCount == 1) {
      _contentX = renderer.viewportX;
      _contentY = renderer.viewportY;
      _initDX = details.focalPoint.dx;
      _initDY = details.focalPoint.dy;
    }
    _grabScale = renderer.viewportScale;
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount == 1 && renderer.isDraggable) {
      final x = _gestureClampedX(details);
      final y = _gestureClampedY(details);
      renderer.setViewportPosition(x, y);
      pluginManager.handleMove(renderer, details, x, y);
      return;
    }
    if (!renderer.isScaleEnabled) {
      return;
    }
    _updateScale(details);
  }

  void _updateScale(ScaleUpdateDetails details) {
    final focalPoint = renderer.pointFromNative(details.localFocalPoint);
    final contentFocalX =
        (focalPoint.x - renderer.viewportX) / renderer.viewportScale;
    final contentFocalY =
        (focalPoint.y - renderer.viewportY) / renderer.viewportScale;
    final newScale = _gestureClampedScale(details);
    final newX = focalPoint.x - contentFocalX * newScale;
    final newY = focalPoint.y - contentFocalY * newScale;

    final bg = renderer.backgroundBitmap;
    final bgWidth = bg.width * newScale;
    final bgHeight = bg.height * newScale;

    var clampX = newX;
    var clampY = newY;
    if (bgWidth > renderer.stageWidth) {
      clampX = clampX.clamp(-(bgWidth - renderer.stageWidth), 0.0);
    } else {
      clampX = (renderer.stageWidth - bgWidth) / 2;
    }
    if (bgHeight > renderer.stageHeight) {
      clampY = clampY.clamp(-(bgHeight - renderer.stageHeight), 0.0);
    } else {
      clampY = (renderer.stageHeight - bgHeight) / 2;
    }

    renderer.setZoom(newScale);
    renderer.setViewportPosition(clampX, clampY);
    pluginManager.handleScale(renderer, details, newScale);
  }

  double _gestureClampedX(ScaleUpdateDetails details) {
    final moveX = details.focalPoint.dx - _initDX;
    final newX = _contentX + moveX;
    return renderer.clampedX(newX);
  }

  double _gestureClampedY(ScaleUpdateDetails details) {
    final moveY = details.focalPoint.dy - _initDY;
    final newY = _contentY + moveY;
    return renderer.clampedY(newY);
  }

  double _gestureClampedScale(ScaleUpdateDetails details) {
    final scale = details.scale * _grabScale;
    return renderer.clampedScale(scale);
  }
}
