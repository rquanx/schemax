import 'package:graphx/graphx.dart';
import 'package:schemax/schemax.dart';

class BuildingSprite extends GSprite {
  final BuildingElement config;
  final RendererCore renderer;

  final bool debug = false;

  BuildingSprite(this.config, this.renderer);

  Future<void> addedToStage() async {
    super.addedToStage();
    final rect = renderer.rectTransformWithConfig(config);
    final tap = GSprite();
    tap.graphics.beginFill(const Color(0xFFFFFFFF));
    tap.graphics.drawRect(0, 0, rect.width, rect.height);
    tap.graphics.endFill();
    tap.alpha = debug ? 0.5 : 0;
    tap.onTap.add((e) {
      renderer.triggerTap(this);
    });
    addChild(tap);
    setProps(x: rect.x, y: rect.y);
  }
}

class BuildingElement extends SchemaElement {
  BuildingElement(super.config);

  static void register() {
    SchemaElement.registerType('building', (map) => BuildingElement(map));
  }

  Map<String, dynamic> toMap() {
    final map = super.toMap();
    return <String, dynamic>{...map};
  }

  @override
  Future<GDisplayObject> build(renderer) async {
    return BuildingSprite(this, renderer);
  }
}
