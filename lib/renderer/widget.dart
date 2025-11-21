import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:graphx/graphx.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../plugins/interactive.dart';
import './controller.dart';
import './core.dart';
import './schema.dart';

class RendererWidget extends HookConsumerWidget {
  final Schema schema;
  final List<InteractivePlugin>? interactivePlugins;
  final RendererController? controller;
  final void Function(RendererController controller)? onControllerReady;

  const RendererWidget({
    super.key,
    required this.schema,
    this.onCreated,
    this.interactivePlugins,
    this.controller,
    this.onControllerReady,
  });

  final void Function(RendererCore renderer)? onCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final providedController = controller;
    final rendererController = useMemoized(
      () =>
          providedController ??
          RendererController(
            schema: schema,
            viewportSize: Size(w, h),
            interactivePlugins: interactivePlugins,
          ),
      [providedController, schema, w, h],
    );

    useEffect(() {
      onCreated?.call(rendererController.renderer);
      onControllerReady?.call(rendererController);
      return null;
    }, [rendererController]);

    return GestureDetector(
      onTap: rendererController.handleTap,
      onScaleStart: rendererController.handleScaleStart,
      onScaleUpdate: rendererController.handleScaleUpdate,
      child: SceneBuilderWidget(
        autoSize: true,
        builder: () => SceneController(front: rendererController.renderer),
      ),
    );
  }
}
