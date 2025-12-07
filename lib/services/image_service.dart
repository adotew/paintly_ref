import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/board_item.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  Future<List<BoardItem>> pickAndProcessImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isEmpty) {
        return [];
      }

      final appDir = await getApplicationDocumentsDirectory();
      final newItems = <BoardItem>[];

      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        final offset = i * 20.0;

        // 1. Bild dauerhaft speichern
        final fileExtension = path.extension(image.path);
        final fileName = '${_uuid.v4()}$fileExtension';
        final savedImage = await File(
          image.path,
        ).copy('${appDir.path}/$fileName');

        // 2. Dimensionen bestimmen (vom gespeicherten Bild)
        final bytes = await savedImage.readAsBytes();
        final decodedImage = await decodeImageFromList(bytes);

        double w = decodedImage.width.toDouble();
        double h = decodedImage.height.toDouble();

        const double maxDimension = 300.0;
        if (w > maxDimension || h > maxDimension) {
          if (w > h) {
            h = maxDimension * (h / w);
            w = maxDimension;
          } else {
            w = maxDimension * (w / h);
            h = maxDimension;
          }
        }

        final newItem = BoardItem(
          // Wir speichern nur den Dateinamen, um Pfad-Probleme bei Updates (iOS) zu vermeiden
          imageSource: fileName,
          x: offset,
          y: offset,
          width: w,
          height: h,
        );
        newItems.add(newItem);
      }

      return newItems;
    } catch (e) {
      // Re-throw to let the UI handle the error (e.g. show SnackBar)
      throw Exception('Error picking images: $e');
    }
  }
}
