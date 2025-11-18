import 'package:example/social_map/social_map.dart';
import 'package:flutter/material.dart';
import 'package:schemax/schemax.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    socialMapInit();
    final json = {
      "align": "left-top",
      "options": {"maxScale": 3, "minScale": 1, "focusPointX": 388},
      "id": "2",
      "name": "map",
      "background": "{your_background_image}",
      "elements": [
        // your element config
      ],
    };
    final schema = Schema.fromMap(json);
    return Scaffold(
      body: RendererWidget(
        schema: schema,
        interactivePlugins: [
          ViewportVisibilityPlugin(
            onVisible: (e) {
              print("visible ${e?.id}");
            },
          ),
          CoordinateAxisPlugin(),
        ],
        onCreated: (renderer) {
          renderer.onClick((element) async {
            print('click $element');
          });
        },
      ),
    );
  }
}
