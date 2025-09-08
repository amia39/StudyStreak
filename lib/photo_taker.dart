import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:studystreak/notes_model.dart';

class PhotoWindow extends StatefulWidget {
  const PhotoWindow({super.key, required this.camera});

  final CameraDescription camera;

  @override
  PhotoWindowState createState() => PhotoWindowState();
}

class PhotoWindowState extends State<PhotoWindow> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  // set up the camera at max resolution
  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.max,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  // remove controller once done
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller); // Showing the camera view
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();

            final directory = await getApplicationDocumentsDirectory();
            final name = DateTime.now().millisecondsSinceEpoch.toString();
            final imagePath = join(directory.path, '$name.jpg');
            await image.saveTo(imagePath);

            if (!mounted) return;

            // saving the image to NotesState
            Provider.of<NotesState>(context, listen: false)
                .addNote(XFile(imagePath));

            Navigator.pop(context);
          } catch (e) {
            print("Error taking photo: $e");
          }
        },
        label: const Text("Take Photo"),
        icon: const Icon(Icons.camera_alt),
      ),
    );
  }
}
