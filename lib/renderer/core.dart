import 'package:graphx/graphx.dart';
import 'package:events_emitter/events_emitter.dart';
import '../utils/image.dart';
import 'plugin_manager.dart';
import './schema.dart';

class ViewportAnimationConfig {
  double? viewportAnchorX;
  double? viewportAnchorY;
  double? targetScale;
  double? targetCoverage;
  ViewportAnimationConfig({
    this.viewportAnchorX = 0.5,
    this.viewportAnchorY = 0.58,
    this.targetScale,
    this.targetCoverage = 0.3,
  });
}

class ViewportStateSnapshot {
  final double x;
  final double y;
  final double scale;

  ViewportStateSnapshot({
    required this.x,
    required this.y,
    required this.scale,
  });
}

class ZoomEventData {
  final double prevScale;
  final double nextScale;
  ZoomEventData({required this.prevScale, required this.nextScale});
}

class ViewportTransform {
  double x;
  double y;
  double width;
  double height;
  double scale;
  ViewportTransform({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.scale,
  });
}

class RendererCore extends GSprite {
  RendererCore(
    this._schema, {
    required double initScreenHeight,
    required double initScreenWidth,
  }) : _initScreenHeight = initScreenHeight,
       _initScreenWidth = initScreenWidth;

  final double _initScreenWidth;
  final double _initScreenHeight;
  final Schema _schema;
  final GSprite _viewport = GSprite();
  final ViewportTransform _canvasRect = ViewportTransform(
    x: 0,
    y: 0,
    width: 0,
    height: 0,
    scale: 0,
  );
  final EventEmitter _event = EventEmitter();

  ViewportStateSnapshot? _previousViewportState;
  RendererPluginManager? _pluginManager;
  double? _stageW;
  double? _stageH;
  dynamic _tapData;

  double get stageWidth {
    if (_stageW != null) {
      return _stageW!;
    }
    _stageW = stage?.stageWidth;
    return _stageW ?? _initScreenWidth;
  }

  double get stageHeight {
    if (_stageH != null) {
      return _stageH!;
    }
    _stageH = stage?.stageHeight;
    return _stageH ?? _initScreenHeight;
  }

  Schema get schema => _schema;
  bool get isDraggable => schema.draggable;
  bool get isScaleEnabled => schema.scaleable;
  Iterable<SchemaElement> get schemaElements => schema.elements;

  double get viewportScale => _viewport.scale;
  double get viewportX => _viewport.x;
  double get viewportY => _viewport.y;
  Offset get viewportPosition => Offset(_viewport.x, _viewport.y);

  ViewportTransform get canvasRect => ViewportTransform(
    x: _canvasRect.x,
    y: _canvasRect.y,
    width: _canvasRect.width,
    height: _canvasRect.height,
    scale: _canvasRect.scale,
  );

  void setViewportPosition(double x, double y) {
    _viewport.setPosition(x, y);
  }

  set pluginManager(RendererPluginManager? manager) {
    _pluginManager = manager;
  }

  RendererPluginManager? get pluginManager => _pluginManager;

  Future<void> _buildBG() async {
    final bg = await loadImage(schema.background);

    /// 进行背景缩放适配，保证不存在破绽
    final heightScale = stageHeight / bg.height;
    final widthScale = stageWidth / bg.width;

    final scale = widthScale > heightScale ? widthScale : heightScale;
    bg.setScale(scale, scale);
    _viewport.addChild(bg);
    _canvasRect.width = bg.width;
    _canvasRect.height = bg.height;
    _canvasRect.scale = scale;

    if (schema.align == 'center') {
      _canvasRect.x = stageWidth / 2 - bg.width / 2;
      _canvasRect.y = bg.height / 2 - stageHeight / 2;
    }
  }

  Future<void> _buildElements() async {
    for (final element in (schema.elements)) {
      final ele = await element.build(this);
      _viewport.addChild(ele);
    }
  }

  /// 触发点击事件,记录当前触发元素
  void triggerTap(dynamic data) {
    _tapData = data;
  }

  List<GDisplayObject> get elements => List.unmodifiable(_viewport.children);

  @override
  Future<void> addedToStage() async {
    super.addedToStage();
    await _buildBG();
    await _buildElements();
    addChild(_viewport);
    resetContentInitialPosition();
    _pluginManager?.attach(this);
  }

  void onElementTap() {
    _event.emit('click', _tapData);
    _tapData = null;
  }

  /// 计算 X 坐标范围限制
  double clampedX(double newX, [double? scale]) {
    final bg = backgroundBitmap;
    final bgWidth = bg.width * (scale ?? viewportScale);
    if (schema.align == 'center') {
      final x1 = bgWidth / 2;
      final x2 = stageWidth - bgWidth / 2;
      final minX = x2 > x1 ? x1 : x2;
      final maxX = x2 > x1 ? x2 : x1;
      return newX.clamp(minX, maxX);
    } else if (schema.align == 'left-top') {
      final x1 = 0.0;
      final x2 = stageWidth - bgWidth;
      final minX = x2 > x1 ? x1 : x2;
      final maxX = x2 > x1 ? x2 : x1;
      return newX.clamp(minX, maxX);
    }
    return 0.0;
  }

  /// 计算 Y 坐标范围限制
  double clampedY(double newY, [double? scale]) {
    final bg = backgroundBitmap;
    final bgHeight = bg.height * (scale ?? viewportScale);

    if (schema.align == 'center') {
      final y1 = bgHeight / 2;
      final y2 = stageHeight - bgHeight / 2;
      final minY = y2 > y1 ? y1 : y2;
      final maxY = y2 > y1 ? y2 : y1;
      return newY.clamp(minY, maxY);
    } else if (schema.align == 'left-top') {
      final y1 = 0.0;
      final y2 = stageHeight - bgHeight;
      final minY = y2 > y1 ? y1 : y2;
      final maxY = y2 > y1 ? y2 : y1;
      return newY.clamp(minY, maxY);
    }
    return 0.0;
  }

  double clampedScale(double scale) {
    final minScale = schema.options.minScale;
    final maxScale = schema.options.maxScale;
    return scale.clamp(minScale, maxScale);
  }

  /// 根据当前缩放倍数进行换算，讲 schema 坐标，换算为初始缩放下的坐标
  GRect rectTransformWithConfig(Base config) {
    final x = config.x * _canvasRect.scale + _canvasRect.x;
    final y = config.y * _canvasRect.scale + _canvasRect.y;
    final width = config.width * _canvasRect.scale;
    final height = config.height * _canvasRect.scale;
    return GRect(x, y, width, height);
  }

  GRect rectTransform(
    double ix,
    double iy, [
    double iWidth = 0,
    double iHeight = 0,
  ]) {
    final x = ix * _canvasRect.scale + _canvasRect.x;
    final y = iy * _canvasRect.scale + _canvasRect.y;
    final width = iWidth * _canvasRect.scale;
    final height = iHeight * _canvasRect.scale;
    return GRect(x, y, width, height);
  }

  double stageToViewportX(double stageX) {
    return (stageX - viewportX) / viewportScale;
  }

  double stageToViewportY(double stageY) {
    return (stageY - viewportY) / viewportScale;
  }

  double stageToSchemaX(double stageX) {
    final local = stageToViewportX(stageX);
    return (local - _canvasRect.x) / _canvasRect.scale;
  }

  double stageToSchemaY(double stageY) {
    final local = stageToViewportY(stageY);
    return (local - _canvasRect.y) / _canvasRect.scale;
  }

  GPoint pointFromNative(Offset point) {
    return GPoint.fromNative(point);
  }

  GBitmap get backgroundBitmap => _viewport.children.first as GBitmap;

  double setZoom(double scale) {
    final prevScale = viewportScale;
    final nextScale = clampedScale(scale);
    _viewport.scale = nextScale;
    _event.emit(
      "zoom",
      ZoomEventData(prevScale: prevScale, nextScale: nextScale),
    );
    return nextScale;
  }

  onClick(Function(dynamic element) cb) {
    _event.on('click', cb);
  }

  void resetTransform() {
    _viewport.pivotX = _viewport.pivotY = _viewport.rotation = 0;
    _viewport.scale = 1;
    resetContentInitialPosition();
  }

  void resetContentInitialPosition() {
    _viewport.scale = 1;
    if (schema.align == 'center') {
      _viewport.alignPivot();
      _viewport.centerInStage();
    } else if (schema.align == 'left-top') {
      final rect = rectTransform(
        schema.options.focusPointX,
        schema.options.focusPointY,
      );
      final focusX = schema.options.focusPointX > 0 ? -rect.x : 0.0;
      final focusY = schema.options.focusPointY > 0 ? -rect.y : 0.0;

      if (schema.options.focusScale != viewportScale) {
        _viewport.tween(
          duration: .2,
          scale: schema.options.focusScale,
          ease: GEase.easeInOut,
          x: focusX,
          y: focusY,
          onComplete: () {
            _event.emit(
              'zoom',
              ZoomEventData(prevScale: 1, nextScale: schema.options.focusScale),
            );
          },
        );
      }
    }
  }

  void onZoom(Function(ZoomEventData data) cb) {
    _event.on('zoom', cb);
  }

  void tweenTo(
    Base config,
    ViewportAnimationConfig animationConfig, {
    Function? onComplete,
    double Function(double)? ease,
    double? duration,
  }) {
    final targetCoverage = animationConfig.targetCoverage ?? 0.3;
    final targetAreaSize = stageWidth * stageHeight * targetCoverage;

    /// 初始缩放下元素的尺寸信息，比例缩放后得到的是在 屏幕尺寸下元素的尺寸
    final rect = rectTransformWithConfig(config);

    /// 计算初始缩放下，地图左上角坐标
    final rectCenterX = rect.x + rect.width / 2;
    final rectCenterY = rect.y + rect.height / 2;
    final stageCenterX = stageWidth * (animationConfig.viewportAnchorX ?? 0.5);
    final stageCenterY =
        stageHeight * (animationConfig.viewportAnchorY ?? 0.58);

    final elementArea = rect.width * rect.height;
    final derivedScale = targetAreaSize / elementArea;
    final calculatedScale = Math.sqrt(derivedScale);
    final finalScale = clampedScale(
      animationConfig.targetScale ?? calculatedScale,
    );
    final targetX = stageCenterX - rectCenterX * finalScale;
    final targetY = stageCenterY - rectCenterY * finalScale;

    final finalX = clampedX(targetX, finalScale);
    final finalY = clampedY(targetY, finalScale);
    final currentScale = viewportScale;
    _previousViewportState = ViewportStateSnapshot(
      x: _viewport.x,
      y: _viewport.y,
      scale: _viewport.scale,
    );
    _viewport.tween(
      duration: duration ?? .2,
      scale: finalScale,
      ease: ease ?? GEase.easeInOut,
      x: finalX,
      y: finalY,
      onComplete: onComplete,
    );
    _event.emit(
      'zoom',
      ZoomEventData(prevScale: currentScale, nextScale: finalScale),
    );
  }

  void tweenBack({
    Function? onComplete,
    double Function(double)? ease,
    double? duration,
  }) {
    final snapshot = _previousViewportState;
    if (snapshot == null) {
      return;
    }
    final currentScale = viewportScale;
    _viewport.tween(
      duration: duration ?? .2,
      scale: snapshot.scale,
      ease: ease ?? GEase.easeInOut,
      x: snapshot.x,
      y: snapshot.y,
      onComplete: onComplete,
    );
    _event.emit(
      'zoom',
      ZoomEventData(
        prevScale: currentScale,
        nextScale: _previousViewportState?.scale ?? currentScale,
      ),
    );
  }
}
