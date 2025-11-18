import 'package:flutter/material.dart';

import '../plugins/interactive.dart';
import 'core.dart';
import 'interactions.dart';
import 'plugin_manager.dart';
import 'schema.dart';

/// Public facade that wires the renderer, gesture handling, and plugins.
class RendererController {
  RendererController({
    required Schema schema,
    required Size viewportSize,
    List<InteractivePlugin>? interactivePlugins,
  })  : renderer = RendererCore(
          schema,
          initScreenWidth: viewportSize.width,
          initScreenHeight: viewportSize.height,
        ),
        pluginManager = RendererPluginManager(interactivePlugins) {
    renderer.pluginManager = pluginManager;
    interactions = RendererInteractions(renderer, pluginManager);
  }

  final RendererCore renderer;
  late final RendererInteractions interactions;
  final RendererPluginManager pluginManager;

  void handleScaleStart(ScaleStartDetails details) {
    interactions.handleScaleStart(details);
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    interactions.handleScaleUpdate(details);
  }

  void handleTap() {
    renderer.onElementTap();
  }
}
