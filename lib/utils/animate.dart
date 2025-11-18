import 'package:graphx/graphx.dart';
import 'utils.dart';

LoopManager breathingAnimation(GDisplayObject element, int duration) {
  final source = element.scale;
  final second = duration / 1000.0;
  void run() {
    element.tween(
      duration: second,
      scale: source / 1.5,
      ease: GEase.easeOut,
      onComplete: () {
        element.tween(duration: second, scale: source, ease: GEase.easeOut);
      },
    );
  }

  return LoopManager(
    task: run,
    interval: Duration(milliseconds: duration * 2),
  );
}
