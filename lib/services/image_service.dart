import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import '../models/board_item.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<List<BoardItem>> pickAndProcessImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isEmpty) {
        return [];
      }

      final newItems = <BoardItem>[];

      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        final offset = i * 20.0;

        final bytes = await File(image.path).readAsBytes();
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
          imageSource: image.path,
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
