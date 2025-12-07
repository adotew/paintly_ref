import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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

        // 1. Bild komprimieren und speichern
        // Wir nutzen .jpg für konsistente Kompression
        final fileName = '${_uuid.v4()}.jpg';
        final targetPath = '${appDir.path}/$fileName';

        // Komprimierung: Max 1500px Kante, 85% Qualität
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          image.path,
          targetPath,
          minWidth: 1500,
          minHeight: 1500,
          quality: 85,
        );

        if (compressedFile == null) {
          // Fallback falls Kompression fehlschlägt: Original kopieren
          await File(image.path).copy(targetPath);
        }

        // 2. Dimensionen bestimmen (vom (komprimierten) Bild im Storage)
        final savedFile = File(targetPath);
        final bytes = await savedFile.readAsBytes();
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
