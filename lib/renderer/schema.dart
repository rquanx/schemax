import 'dart:convert';

import 'package:graphx/graphx.dart';
import '../utils/utils.dart';
import './core.dart';

class SchemaOptions {
  SchemaOptions([Map<String, dynamic> config = const {}])
    : _config = Map.unmodifiable(config),
      minScale = (toDouble(config['minScale'])) ?? 1,
      maxScale = (toDouble(config['maxScale'])) ?? 2,
      // 兼容旧版本配置
      focusPointX =
          (toDouble(config['focusPointX'] ?? config['fpCenterX'])) ?? 0,
      focusPointY =
          (toDouble(config['focusPointY'] ?? config['fpCenterY'])) ?? 0,
      focusScale = (toDouble(config['focusScale'] ?? config['fpScale'])) ?? 0;
  final Map<String, dynamic> _config;
  final double minScale;
  final double maxScale;
  final double focusPointX;
  final double focusPointY;
  final double focusScale;

  Map<String, dynamic> toMap() => Map<String, dynamic>.from(_config);

  String toJson() => json.encode(toMap());

  factory SchemaOptions.fromJson(String source) =>
      SchemaOptions.fromMap(json.decode(source) as Map<String, dynamic>);

  factory SchemaOptions.fromMap(Map<String, dynamic> map) => SchemaOptions(map);
}

abstract class Base {
  Base(Map<String, dynamic> config)
    : config = Map.unmodifiable(config),
      x = toDouble(config['x']) ?? 0,
      y = toDouble(config['y']) ?? 0,
      width = toDouble(config['width']) ?? 0,
      height = toDouble(config['height']) ?? 0;

  final Map<String, dynamic> config;
  final double x;
  final double y;
  final double width;
  final double height;
}

abstract class SchemaElement extends Base {
  SchemaElement(super.config) : id = config['id'], type = config['type'];

  final String id;
  final String type;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  String toJson() => json.encode(toMap());

  factory SchemaElement.fromJson(String source) =>
      SchemaElement.fromMap(json.decode(source) as Map<String, dynamic>);

  static final Map<String, SchemaElement Function(Map<String, dynamic>)>
  _typeRegistry = {};

  // 子类调用此方法注册自己
  static void registerType(
    String type,
    SchemaElement Function(Map<String, dynamic>) factory,
  ) {
    _typeRegistry[type] = factory;
  }

  // 动态创建实例
  factory SchemaElement.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String;
    final factory = _typeRegistry[type];
    if (factory == null) {
      throw UnsupportedError('Unknown type: $type');
    }
    return factory(map);
  }

  // 抽象方法：子类必须实现
  Future<GDisplayObject> build(RendererCore renderer);
}

class Schema {
  Schema(Map<String, dynamic> schema)
    : background = schema['background'],
      scaleable = schema['scaleable'] ?? true,
      draggable = schema['draggable'] ?? true,
      options = SchemaOptions.fromMap(schema['options'] ?? {}),
      align = schema['align'] ?? 'center',
      id = schema['id'],
      _elements = (((schema['elements'] as List?) ?? [])
          .map((e) => SchemaElement.fromMap(e))
          .toList());

  final String version = '1.0.0';
  final List<SchemaElement> _elements;
  final String background;
  final bool scaleable;
  final bool draggable;
  final String id;
  final SchemaOptions options;
  final String align;

  List<SchemaElement> get elements => List.unmodifiable(_elements);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'background': background,
      'elements': _elements.map((e) => e.toMap()).toList(),
      'scaleable': scaleable,
      'draggable': draggable,
      'options': options.toMap(),
      'align': align,
      'id': id,
    };
  }

  String toJson() => json.encode(toMap());

  factory Schema.fromJson(String source) =>
      Schema.fromMap(json.decode(source) as Map<String, dynamic>);

  factory Schema.fromMap(Map<String, dynamic> map) => Schema(map);
}
