import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key});

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  late final ScribbleNotifier notifier;
  double currentStrokeWidth = 5.0;
  Color currentColor = Colors.black;
  bool isEraser = false;

  @override
  void initState() {
    super.initState();
    notifier = ScribbleNotifier()
      ..setStrokeWidth(currentStrokeWidth)
      ..setColor(currentColor);
  }

  @override
  void dispose() {
    notifier.dispose();
    super.dispose();
  }

  Future<String?> _saveDrawing() async {
    try {
      const double pixelRatio = 3.0;

      final ByteData imageData =
          await notifier.renderImage(pixelRatio: pixelRatio);
      final Uint8List drawingBytes = imageData.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(
        drawingBytes,
        targetHeight: (300 * pixelRatio).toInt(),
        targetWidth: (300 * pixelRatio).toInt(),
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image drawingImage = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();

      // White background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, drawingImage.width.toDouble(),
            drawingImage.height.toDouble()),
        paint..color = Colors.white,
      );

      canvas.drawImage(drawingImage, Offset.zero, Paint());

      // Save as PNG
      final ui.Image finalImage = await recorder
          .endRecording()
          .toImage(drawingImage.width, drawingImage.height);
      final ByteData? pngData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);

      if (pngData == null) throw Exception("PNG encoding failed");

      final pngBytes = pngData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(pngBytes);

      return path;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving drawing: $e')),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing Canvas'),
        backgroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: notifier.undo,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: notifier.clear,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final path = await _saveDrawing();
              if (path != null && mounted) Navigator.pop(context, path);
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white, // Change this to your desired background color
        child: Scribble(
          notifier: notifier,
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.palette),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Color'),
                  content: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Colors.black,
                      Colors.red,
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                    ]
                        .map((color) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  currentColor = color;
                                  isEraser = false;
                                });
                                notifier.setColor(color);
                                Navigator.pop(context);
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                color: color,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.brush),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: const Text('Stroke Width'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Slider(
                            value: currentStrokeWidth,
                            min: 1,
                            max: 20,
                            divisions: 19,
                            onChanged: (value) {
                              setState(() => currentStrokeWidth = value);
                              notifier.setStrokeWidth(value);
                              if (isEraser) {
                                notifier.setStrokeWidth(value * 2);
                              }
                            },
                          ),
                          Text(
                              'Size: ${currentStrokeWidth.toStringAsFixed(1)}'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.auto_fix_high,
                  color: isEraser ? Colors.blue : Colors.grey),
              onPressed: () {
                setState(() {
                  isEraser = !isEraser;
                  if (isEraser) {
                    notifier.setColor(Colors.white);
                    notifier.setStrokeWidth(currentStrokeWidth * 2);
                  } else {
                    notifier.setColor(currentColor);
                    notifier.setStrokeWidth(currentStrokeWidth);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
