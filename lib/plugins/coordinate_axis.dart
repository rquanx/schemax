import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:graphx/graphx.dart';
import '../plugins/interactive.dart';
import '../renderer/core.dart';

enum AxisValueMode { schema, transformed }

class CoordinateAxisPlugin extends InteractivePlugin {
  final AxisValueMode valueMode;
  final int horizontalTickCount;
  final int verticalTickCount;
  final double tickLength;
  final double majorTickInterval;
  final double minorTickInterval;
  final double minorTickScale;
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
    this.majorTickInterval = 50,
    this.minorTickInterval = 10,
    this.minorTickScale = .5,
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
    final drewTicks = _drawValueAlignedAxisTicks(
      renderer: renderer,
      line: line,
      labels: labels,
      isHorizontal: true,
      length: width,
    );
    if (!drewTicks) {
      _drawEvenlyDistributedTicks(
        renderer: renderer,
        line: line,
        labels: labels,
        isHorizontal: true,
        length: width,
        tickCount: horizontalTickCount,
      );
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
    final drewTicks = _drawValueAlignedAxisTicks(
      renderer: renderer,
      line: line,
      labels: labels,
      isHorizontal: false,
      length: height,
    );
    if (!drewTicks) {
      _drawEvenlyDistributedTicks(
        renderer: renderer,
        line: line,
        labels: labels,
        isHorizontal: false,
        length: height,
        tickCount: verticalTickCount,
      );
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

  bool _drawValueAlignedAxisTicks({
    required RendererCore renderer,
    required GShape line,
    required GSprite labels,
    required bool isHorizontal,
    required double length,
  }) {
    if (minorTickInterval <= 0) {
      return false;
    }

    final startValue = _valueAt(
      stageX: isHorizontal ? 0 : 0,
      stageY: isHorizontal ? 0 : 0,
      isX: isHorizontal,
    );
    final endValue = _valueAt(
      stageX: isHorizontal ? length : 0,
      stageY: isHorizontal ? 0 : length,
      isX: isHorizontal,
    );
    final minValue = math.min(startValue, endValue);
    final maxValue = math.max(startValue, endValue);
    if (!minValue.isFinite || !maxValue.isFinite) {
      return false;
    }
    if ((maxValue - minValue).abs() < _tickEpsilon) {
      return false;
    }

    var tickValue = _ceilToMultiple(minValue, minorTickInterval);
    if (tickValue > maxValue + _tickEpsilon) {
      return false;
    }
    var renderedTicks = false;
    const maxIterations = 2000;
    var iterations = 0;
    while (tickValue <= maxValue + _tickEpsilon && iterations < maxIterations) {
      final stagePos = _stagePositionForValue(
        renderer,
        tickValue,
        isHorizontal,
      );
      if (stagePos != null && stagePos >= -1 && stagePos <= length + 1) {
        renderedTicks = true;
        final isMajorTick =
            majorTickInterval > 0 &&
            _isMultipleOf(tickValue, majorTickInterval);
        final currentTickLength = isMajorTick
            ? tickLength
            : math.max(1.0, tickLength * minorTickScale);
        if (isHorizontal) {
          line.graphics.moveTo(stagePos, 0);
          line.graphics.lineTo(stagePos, currentTickLength);
        } else {
          line.graphics.moveTo(0, stagePos);
          line.graphics.lineTo(currentTickLength, stagePos);
        }
        if (isMajorTick) {
          final label = _buildLabel(_formatValue(tickValue));
          final bounds = label.bounds;
          if (isHorizontal) {
            final labelWidth = bounds?.width ?? 0;
            label.setPosition(stagePos - labelWidth / 2, tickLength + 2);
          } else {
            final labelHeight = bounds?.height ?? 0;
            final top = math.max(0.0, stagePos - labelHeight / 2);
            label.setPosition(tickLength + 4, top);
          }
          labels.addChild(label);
        }
      }
      iterations++;
      tickValue += minorTickInterval;
    }
    return renderedTicks;
  }

  void _drawEvenlyDistributedTicks({
    required RendererCore renderer,
    required GShape line,
    required GSprite labels,
    required bool isHorizontal,
    required double length,
    required int tickCount,
  }) {
    final ticks = math.max(2, tickCount);
    final delta = length / (ticks - 1);
    for (var i = 0; i < ticks; i++) {
      final pos = delta * i;
      if (isHorizontal) {
        line.graphics.moveTo(pos, 0);
        line.graphics.lineTo(pos, tickLength);
      } else {
        line.graphics.moveTo(0, pos);
        line.graphics.lineTo(tickLength, pos);
      }
      final label = _buildLabel(
        _formatValue(
          _valueAt(
            stageX: isHorizontal ? pos : 0,
            stageY: isHorizontal ? 0 : pos,
            isX: isHorizontal,
          ),
        ),
      );
      final bounds = label.bounds;
      if (isHorizontal) {
        final labelWidth = bounds?.width ?? 0;
        label.setPosition(pos - labelWidth / 2, tickLength + 2);
      } else {
        final labelHeight = bounds?.height ?? 0;
        final top = math.max(0.0, pos - labelHeight / 2);
        label.setPosition(tickLength + 4, top);
      }
      labels.addChild(label);
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

  double? _stagePositionForValue(
    RendererCore renderer,
    double value,
    bool isX,
  ) {
    if (!value.isFinite) {
      return null;
    }
    final viewportScale = renderer.viewportScale;
    final viewportOffset = isX ? renderer.viewportX : renderer.viewportY;
    if (valueMode == AxisValueMode.transformed) {
      return value * viewportScale + viewportOffset;
    }
    final canvas = renderer.canvasRect;
    final origin = isX ? canvas.x : canvas.y;
    final scaled = origin + value * canvas.scale;
    return scaled * viewportScale + viewportOffset;
  }

  double _ceilToMultiple(double value, double step) {
    final normalizedRemainder = _positiveRemainder(value, step);
    if (normalizedRemainder.abs() < _tickEpsilon) {
      return value - normalizedRemainder;
    }
    return value + (step - normalizedRemainder);
  }

  bool _isMultipleOf(double value, double step) {
    if (step <= 0) {
      return false;
    }
    final remainder = _positiveRemainder(value, step);
    return remainder < _tickEpsilon || (step - remainder) < _tickEpsilon;
  }

  double _positiveRemainder(double value, double step) {
    var remainder = value % step;
    if (remainder < 0) {
      remainder += step.abs();
    }
    return remainder;
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

  static const double _tickEpsilon = 1e-4;
}
