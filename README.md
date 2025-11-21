# SchemaX

SchemaX is a Flutter + [GraphX](https://pub.dev/packages/graphx) rendering engine that turns structured schema data into highly interactive canvases. Provide a JSON schema describing the background and elements of your scene and SchemaX delivers a widget with panning, zooming, animation hooks, and a plugin system.

> Build touch-friendly, schema-driven canvases for Flutter. SchemaX handles viewport math so you can focus on the story your scene tells.

## Highlights

- **Schema-first workflow** — Encode backgrounds, element bounds, and custom metadata with `Schema`/`SchemaElement`. SchemaX restores the layout on any screen and enforces clamped bounds.
- **Smooth gestures** — Dragging, pinch-to-zoom, focus points, and `tweenTo`/`tweenBack` animations are built in, making it easy to guide the user to a specific element.
- **Extensible plugins** — Implement `InteractivePlugin` to react to gestures and render overlays such as coordinate axes or visibility trackers (`ViewportVisibilityPlugin`).
- **Event hooks** — Use `renderer.onClick`/`renderer.onZoom` to coordinate Flutter UI with GraphX nodes.
- **Utility toolbox** — Helpers for image caching, zoom compensation, looping animations, and more reduce glue code.

## Installation

```yaml
dependencies:
  schemax: ^1.1.0 # use the published version when available
  # or when developing locally:
  # schemax:
  #   path: ../schemax
```

```bash
flutter pub get
```

## Quick Start

1. **Register a custom element**

   ```dart
   class BuildingElement extends SchemaElement {
     BuildingElement(super.config);

     static void register() {
       SchemaElement.registerType('building', BuildingElement.new);
     }

     @override
     Future<GDisplayObject> build(RendererCore renderer) async {
       final rect = renderer.rectTransformWithConfig(this);
       final sprite = GSprite()..setPosition(rect.x, rect.y);
       // Draw anything you need inside the sprite.
       sprite.onTap.add((_) => renderer.triggerTap(this));
       return sprite;
     }
   }
   ```

2. **Load the schema**

   ```dart
   final schemaJson =
       jsonDecode(await rootBundle.loadString('assets/schema.json'));
   final schema = Schema.fromMap(schemaJson);
   ```

3. **Render with `RendererWidget`**

   ```dart
   class SocialMap extends HookWidget {
     const SocialMap({super.key});

     @override
     Widget build(BuildContext context) {
       socialMapInit(); // registers SchemaElement types
       final schema = Schema.fromMap(kMySchema);
       return RendererWidget(
         schema: schema,
         interactivePlugins: [
           CoordinateAxisPlugin(valueMode: AxisValueMode.transformed),
           ViewportVisibilityPlugin(
             onVisible: (element) => debugPrint('visible ${element?.id}'),
           ),
         ],
         onControllerReady: (controller) {
           controller.renderer.onClick((payload) {
             if (payload is BuildingSprite) payload.showInfo();
           });
         },
       );
     }
   }
   ```

## Schema Structure

| Field                           | Type                  | Description                                                                                                                                                |
| ------------------------------- | --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `background`                    | `String`              | URL or asset path for the background image. Images are loaded via `loadImage` and cached automatically.                                                    |
| `align`                         | `center` / `left-top` | Default alignment of the background on the stage. `left-top` works with `focusPointX/Y` to define the initial viewport.                                    |
| `scaleable` / `draggable`       | `bool`                | Enable or disable pinch-zoom/drag gestures.                                                                                                                |
| `options.minScale` / `maxScale` | `double`              | Zoom limits applied by `RendererCore.clampedScale`.                                                                                                        |
| `options.focusPointX/Y`         | `double`              | Initial focus point in schema coordinates.                                                                                                                 |
| `elements`                      | `List<Map>`           | Raw element configuration. Each entry must include `id`, `type`, `x`, `y`, `width`, and `height`. Custom keys are parsed by your `SchemaElement` subclass. |

Register new element types via `SchemaElement.registerType`, then override `build` to return any `GDisplayObject`. See `example/lib/social_map` for an end-to-end implementation.

## Plugin System

`InteractivePlugin` exposes `onAttach`, `onMove`, and `onScale`. The `RendererPluginManager` dispatches every gesture to each plugin in order, letting you render overlays or react to viewport changes without touching gesture logic.

Built-in plugins include:

- `CoordinateAxisPlugin` — draws top/left axes with ticks and labels using either schema coordinates or transformed stage values.
- `ViewportVisibilityPlugin` — reports which element meets a visibility threshold within the current viewport.

Plugins have full access to `RendererCore` helpers (`stageToViewportX/Y`, `stageToSchemaX/Y`, `rectTransform*`, etc.) so you can position overlays precisely.

## Controller & Core APIs

- `RendererWidget` — wraps `SceneBuilderWidget` with a `GestureDetector`, instantiating a `RendererController` unless you provide one.
- `RendererController` — holds the `RendererCore`, translates Flutter gestures to renderer interactions, and forwards events to plugins.
- `RendererCore` essentials:
  - `onClick` / `onZoom` to listen for tap propagation and zoom changes (`ZoomEventData`).
  - `tweenTo(Base, ViewportAnimationConfig)` / `tweenBack()` for focus animations.
  - `resetTransform()` / `resetContentInitialPosition()` to return to the starting view.
  - `rectTransform*`, `stageToSchema*`, `stageToViewport*` for converting between coordinate spaces.

## Utilities & Animation Helpers

- `helper/zoom.keepElementSize` keeps an overlay visually stable while the canvas zooms; `calcKeepSizeZoom` returns the compensation factor.
- `utils/animate.breathingAnimation` plus `utils/utils.LoopManager` produce looping tween sequences (used by the sample “breathing” indicator).
- `utils/image.loadImage` wraps network/local image loading with caching; `utils/file.loadImageFromPath` leverages `DefaultCacheManager`.

## Example App

The `example/` directory ships with a “social map” demo. It showcases schema parsing, a custom building element, animated info cards, and plugin overlays.

```bash
cd example
flutter run
```

## Development & Testing

- `flutter analyze` — static analysis.
- `flutter test` — run unit/widget tests (add your own as needed).

## License

SchemaX is distributed under the MIT License (see `LICENSE`).
