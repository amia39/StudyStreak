import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<String> extractTextFromImage(String imagePath) async {
  final exists = File(imagePath).existsSync();

  final inputImage = InputImage.fromFilePath(imagePath);
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
  await textRecognizer.close();

  return recognizedText.text.trim();
}
