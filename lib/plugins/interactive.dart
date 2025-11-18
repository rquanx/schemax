import 'package:flutter/material.dart';
import 'package:schemax/renderer/core.dart';

abstract class InteractivePlugin {
  void onAttach(RendererCore renderer) {}
  onMove(
    RendererCore renderer,
    ScaleUpdateDetails details,
    double x,
    double y,
  ) {}
  onScale(RendererCore renderer, ScaleUpdateDetails details, double scale) {}
}
