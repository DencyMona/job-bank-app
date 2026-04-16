import 'package:flutter/material.dart';

class ImageViewPage extends StatelessWidget {
  final String imagePath;

  const ImageViewPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(child: InteractiveViewer(child: Image.asset(imagePath))),
    );
  }
}
