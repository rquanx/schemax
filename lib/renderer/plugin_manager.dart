import 'package:flutter/material.dart';
import '../plugins/interactive.dart';

import 'core.dart';

/// Coordinates lifecycle hooks for interactive plugins.
class RendererPluginManager {
  RendererPluginManager([List<InteractivePlugin>? plugins])
    : _plugins = List.unmodifiable(plugins ?? const []);

  final List<InteractivePlugin> _plugins;

  bool get hasPlugins => _plugins.isNotEmpty;

  void attach(RendererCore renderer) {
    if (!hasPlugins) {
      return;
    }
    for (final plugin in _plugins) {
      plugin.onAttach(renderer);
    }
  }

  void handleMove(
    RendererCore renderer,
    ScaleUpdateDetails details,
    double x,
    double y,
  ) {
    if (!hasPlugins) {
      return;
    }
    for (final plugin in _plugins) {
      plugin.onMove(renderer, details, x, y);
    }
  }

  void handleScale(
    RendererCore renderer,
    ScaleUpdateDetails details,
    double scale,
  ) {
    if (!hasPlugins) {
      return;
    }
    for (final plugin in _plugins) {
      plugin.onScale(renderer, details, scale);
    }
  }
}
