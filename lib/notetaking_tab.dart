import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studystreak/notes_model.dart';
import 'package:studystreak/photo_taker.dart';
import 'package:camera/camera.dart';
import 'package:studystreak/drawing_canvas.dart';
import 'package:studystreak/ocr_helper.dart';
import 'theme_model.dart';

class NoteTakingTab extends StatelessWidget {
  const NoteTakingTab({super.key});

  void _showFullScreenNote(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext imageDialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(File(imagePath), fit: BoxFit.contain),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.text_snippet),
                label: const Text("Extract Text"),
                onPressed: () async {
                  Navigator.of(imageDialogContext).pop(); // close first dialog

                  await Future.delayed(const Duration(milliseconds: 100));

                  final text = await extractTextFromImage(imagePath);

                  // Save the OCR result as a new note
                  Provider.of<NotesState>(context, listen: false)
                      .addTextNote(text);

                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text("Text Extracted & Saved"),
                        content: SingleChildScrollView(
                          child: Text(text.isEmpty ? "No text found." : text),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            child: const Text("Close"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String appTheme = Provider.of<Customization>(context).appTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notes",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: appTheme == 'light' ? Colors.blue : const Color.fromARGB(255, 7, 31, 43),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'camera',
            onPressed: () async {
              await availableCameras().then((cameras) => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          PhotoWindow(camera: cameras.first))));
            },
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'drawing',
            onPressed: () async {
              final imagePath = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DrawingCanvas()),
              );
              if (imagePath != null) {
                final notesState =
                    Provider.of<NotesState>(context, listen: false);
                await notesState.addNote(XFile(imagePath));
              }
            },
            child: const Icon(Icons.draw),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration( // const 
          image: DecorationImage(
            image: appTheme == 'light' ? AssetImage('assets/images/notes_background.png') : AssetImage('assets/images/darkmode_notes.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Consumer<NotesState>(
          builder: (context, values, child) {
            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: values.notes.length,
              itemBuilder: (context, index) {
                final note = values.notes[index];
                return GestureDetector(
                  onTap: () {
                    if (note.image != null &&
                        File(note.image!.path).existsSync()) {
                      _showFullScreenNote(context, note.image!.path);
                    } else if (note.image == null && note.text.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Text("Note Text"),
                            content: SingleChildScrollView(
                              child: Text(note.text),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text("Close"),
                              )
                            ],
                          );
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Image file not found.")),
                      );
                    }
                  },
                  child: Card(
                    elevation: 4,
                    child: Column(
                      children: [
                        if (note.image != null)
                          Expanded(
                            child: (note.image != null &&
                                    File(note.image!.path).existsSync())
                                ? Image.file(
                                    File(note.image!.path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  )
                                : Center(
                                    child: Text(
                                      "Image not found",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            note.text.isEmpty
                                ? "File No. ${index + 1}"
                                : note.text,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
