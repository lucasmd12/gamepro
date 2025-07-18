import 'package:flutter/material.dart';
import 'dart:io';

class ImagePreviewWidget extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const ImagePreviewWidget({
    super.key,
    this.imageFile,
    this.imageUrl,
    this.width = 100,
    this.height = 100,
    this.fit = BoxFit.cover,
  }) : assert(imageFile != null || imageUrl != null, 'Either imageFile or imageUrl must be provided.');

  @override
  Widget build(BuildContext context) {
    if (imageFile != null) {
      return Image.file(imageFile!, width: width, height: height, fit: fit);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
      );
    } else {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 50, color: Colors.grey),
      );
    }
  }
}


