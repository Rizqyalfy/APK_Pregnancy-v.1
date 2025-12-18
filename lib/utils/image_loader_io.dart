import 'dart:io';
import 'package:flutter/material.dart';

Widget imageThumbnail(String path, {double width = 56, double height = 56}) {
  if (path.startsWith('http')) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _placeholder(width, height),
      ),
    );
  }

  if (path.startsWith('assets/')) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _placeholder(width, height),
      ),
    );
  }

  // Assume local file path
  final file = File(path);
  if (file.existsSync()) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        file,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _placeholder(width, height),
      ),
    );
  }

  return _placeholder(width, height);
}

Widget _placeholder(double width, double height) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Icon(Icons.photo, color: Colors.grey[500]),
  );
}

Widget imagePreview(String path) {
  if (path.startsWith('http')) {
    return Image.network(
      path,
      fit: BoxFit.contain,
      errorBuilder: (c, e, s) => _placeholder(200, 200),
    );
  }

  if (path.startsWith('assets/')) {
    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (c, e, s) => _placeholder(200, 200),
    );
  }

  final file = File(path);
  if (file.existsSync()) {
    return Image.file(
      file,
      fit: BoxFit.contain,
      errorBuilder: (c, e, s) => _placeholder(200, 200),
    );
  }

  return _placeholder(200, 200);
}
