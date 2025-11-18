import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:graphx/graphx.dart';
import 'package:schemax/plugins/interactive.dart';
import 'package:schemax/renderer/core.dart';

enum AxisValueMode { schema, transformed }

class CoordinateAxisPlugin extends InteractivePlugin {
  final AxisValueMode valueMode;
  final int horizontalTickCount;
  final int verticalTickCount;
  final double tickLength;
  final Color axisColor;
  Color? axisBgColor;
  final TextStyle? labelStyle;
  final EdgeInsets panelMargin;
  final EdgeInsets panelPadding;

  RendererCore? _renderer;
  GSprite? _overlayLayer;
  GShape? _topAxisLine;
  GShape? _leftAxisLine;
  GSprite? _topLabels;
  GSprite? _leftLabels;
  GSprite? _infoPanel;
  GShape? _infoBg;
  GText? _infoText;

  CoordinateAxisPlugin({
    this.valueMode = AxisValueMode.schema,
    this.horizontalTickCount = 12,
    this.verticalTickCount = 12,
    this.tickLength = 16,
    this.axisColor = const Color(0xB3FFFFFF),
    this.labelStyle,
    this.panelMargin = const EdgeInsets.all(12),
    this.panelPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.axisBgColor = const Color.fromRGBO(0, 0, 0, 0.4),
  });

  @override
  void onAttach(RendererCore renderer) {
    _renderer = renderer;
    _ensureOverlay(renderer);
    _updateAxis();
    renderer.onZoom((event) => _updateAxis());
  }

  @override
  void onMove(
    RendererCore renderer,
    ScaleUpdateDetails details,
    double x,
    double y,
  ) {
    _updateAxis();
  }

  @override
  void onScale(
    RendererCore renderer,
    ScaleUpdateDetails details,
    double scale,
  ) {
    _updateAxis();
  }

  void _ensureOverlay(RendererCore renderer) {
    if (_overlayLayer != null) {
      return;
    }
    final layer = GSprite();
    renderer.addChild(layer);
    _overlayLayer = layer;
    _topAxisLine = GShape();
    _leftAxisLine = GShape();
    _topLabels = GSprite();
    _leftLabels = GSprite();
    _infoPanel = GSprite();
    _infoBg = GShape();
    _infoText = GText(
      text: '',
      textStyle:
          labelStyle ?? const TextStyle(fontSize: 20, color: Colors.white),
    );

    layer.addChild(_topAxisLine!);
    layer.addChild(_leftAxisLine!);
    layer.addChild(_topLabels!);
    layer.addChild(_leftLabels!);
    layer.addChild(_infoPanel!);
    _infoPanel!.addChild(_infoBg!);
    _infoPanel!.addChild(_infoText!);
  }

  void _updateAxis() {
    final renderer = _renderer;
    final topLine = _topAxisLine;
    final leftLine = _leftAxisLine;
    if (renderer == null || topLine == null || leftLine == null) {
      return;
    }
    _drawHorizontalAxis(renderer, topLine);
    _drawVerticalAxis(renderer, leftLine);
    _updateInfoPanel(renderer);
  }

  void _drawHorizontalAxis(RendererCore renderer, GShape line) {
    final width = renderer.stageWidth;
    line.graphics.clear();
    if (axisBgColor != null) {
      line.graphics.beginFill(axisBgColor!);
      line.graphics.drawRect(0, 0, width, tickLength / 2);
      line.graphics.endFill();
    }

    line.graphics.lineStyle(2, axisColor);
    line.graphics.moveTo(axisBgColor == null ? 0 : tickLength / 2, 0);
    line.graphics.lineTo(width, 0);

    final labels = _topLabels!;
    _clearChildren(labels);
    final ticks = math.max(2, horizontalTickCount);
    final dx = width / (ticks - 1);
    for (var i = 0; i < ticks; i++) {
      final x = dx * i;
      line.graphics.moveTo(x, 0);
      line.graphics.lineTo(x, tickLength);
      final label = _buildLabel(
        _formatValue(_valueAt(stageX: x, stageY: 0, isX: true)),
      );
      final bounds = label.bounds;
      final labelWidth = bounds?.width ?? 0;
      label.setPosition(x - labelWidth / 2, tickLength + 2);
      labels.addChild(label);
    }
  }

  void _drawVerticalAxis(RendererCore renderer, GShape line) {
    final height = renderer.stageHeight;
    line.graphics.clear();
    if (axisBgColor != null) {
      line.graphics.beginFill(axisBgColor!);
      line.graphics.drawRect(0, 0, tickLength / 2, height);
      line.graphics.endFill();
    }
    line.graphics.lineStyle(2, axisColor);
    line.graphics.moveTo(0, axisBgColor == null ? 0 : tickLength / 2);
    line.graphics.lineTo(0, height);

    final labels = _leftLabels!;
    _clearChildren(labels);
    final ticks = math.max(2, verticalTickCount);
    final dy = height / (ticks - 1);
    for (var i = 0; i < ticks; i++) {
      final y = dy * i;
      line.graphics.moveTo(0, y);
      line.graphics.lineTo(tickLength, y);
      final label = _buildLabel(
        _formatValue(_valueAt(stageX: 0, stageY: y, isX: false)),
      );
      final bounds = label.bounds;
      final labelHeight = bounds?.height ?? 0;
      final top = math.max(0.0, y - labelHeight / 2);
      label.setPosition(tickLength + 4, top);
      labels.addChild(label);
    }
  }

  void _updateInfoPanel(RendererCore renderer) {
    final infoPanel = _infoPanel;
    final infoBg = _infoBg;
    final infoText = _infoText;
    if (infoPanel == null || infoBg == null || infoText == null) {
      return;
    }
    final xValue = _formatValue(_valueAt(stageX: 0, stageY: 0, isX: true));
    final yValue = _formatValue(_valueAt(stageX: 0, stageY: 0, isX: false));
    final scaleValue = renderer.scale.toStringAsFixed(2);
    infoText.text = 'x: $xValue\ny: $yValue\nscale: $scaleValue';
    final bounds = infoText.bounds;
    final textWidth = bounds?.width ?? 0;
    final textHeight = bounds?.height ?? 0;
    final width = textWidth + panelPadding.horizontal;
    final height = textHeight + panelPadding.vertical;

    final graphics = infoBg.graphics;
    graphics.clear();
    graphics.beginFill(const Color(0xB3000000));
    graphics.drawRect(0, 0, width, height);
    graphics.endFill();
    infoText.setPosition(panelPadding.left, panelPadding.top);

    final panelX = renderer.stageWidth - width - panelMargin.right;
    final panelY = renderer.stageHeight - height - panelMargin.bottom;
    infoPanel.setPosition(panelX, panelY);
  }

  GText _buildLabel(String text) {
    return GText(
      text: text,
      textStyle:
          labelStyle ?? const TextStyle(fontSize: 11, color: Colors.white),
    );
  }

  void _clearChildren(GSprite sprite) {
    for (var i = sprite.numChildren - 1; i >= 0; i--) {
      sprite.removeChildAt(i);
    }
  }

  double _valueAt({
    required double stageX,
    required double stageY,
    required bool isX,
  }) {
    final renderer = _renderer!;
    if (isX) {
      if (valueMode == AxisValueMode.transformed) {
        return renderer.stageToViewportX(stageX);
      }
      return renderer.stageToSchemaX(stageX);
    } else {
      if (valueMode == AxisValueMode.transformed) {
        return renderer.stageToViewportY(stageY);
      }
      return renderer.stageToSchemaY(stageY);
    }
  }

  String _formatValue(double value) {
    final absValue = value.abs();
    if (absValue >= 1000) {
      return value.toStringAsFixed(0);
    }
    if (absValue >= 100) {
      return value.toStringAsFixed(1);
    }
    if (absValue >= 1) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(0);
  }
}
