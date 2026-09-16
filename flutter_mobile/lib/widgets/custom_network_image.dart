import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final double? width;
  final double? height;
  final Map<String, String>? headers;

  const CustomNetworkImage(
    this.imageUrl, {
    super.key,
    this.fit,
    this.errorBuilder,
    this.width,
    this.height,
    this.headers,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last.replaceAll(RegExp(r'\s+'), '');
        final Uint8List bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: errorBuilder,
        );
      } catch (e) {
        if (errorBuilder != null) {
          return errorBuilder!(context, e, null);
        }
        return const Icon(Icons.broken_image);
      }
    }

    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      headers: headers,
      errorBuilder: errorBuilder,
    );
  }
}
