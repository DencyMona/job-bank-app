import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

class JobImageView extends StatefulWidget {
  final List<String> files;

  const JobImageView({super.key, required this.files});

  @override
  State<JobImageView> createState() => _JobImageViewState();
}

class _JobImageViewState extends State<JobImageView> {
  late PageController _pageController;
  int currentIndex = 0;
  bool downloading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- Download Logic ---
  Future<void> downloadFile(String fileUrl) async {
    setState(() => downloading = true);
    try {
      Uint8List bytes;
      String extension = path.extension(fileUrl).isNotEmpty
          ? path.extension(fileUrl)
          : ".png";

      if (fileUrl.startsWith("http")) {
        // From Web
        final response = await http.get(Uri.parse(fileUrl));
        bytes = response.bodyBytes;
      } else {
        // From Local Assets
        final byteData = await rootBundle.load(fileUrl);
        bytes = byteData.buffer.asUint8List();
      }

      final fileName =
          "job_file_${DateTime.now().millisecondsSinceEpoch}$extension";
      final params = SaveFileDialogParams(data: bytes, fileName: fileName);

      final filePath = await FlutterFileDialog.saveFile(params: params);

      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File saved successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Clean list to avoid empty strings
    final files = widget.files.where((e) => e.trim().isNotEmpty).toList();

    // --- INTHA PRINT LOGIC-AH ADD PANNUNGA ---
    debugPrint("========================================");
    debugPrint("TOTAL FILES RECEIVED: ${files.length}");
    for (int i = 0; i < files.length; i++) {
      debugPrint("FILE [$i] PATH: ${files[i]}");
    }
    debugPrint("========================================");
    // ----------------------------------------

    if (files.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "No files available",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "${currentIndex + 1} / ${files.length}",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: downloading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: () => downloadFile(files[currentIndex]),
                    icon: const Icon(Icons.download_rounded),
                  ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: files.length,
        onPageChanged: (index) => setState(() => currentIndex = index),
        itemBuilder: (context, index) {
          final String file = files[index];
          final bool isPdf = file.toLowerCase().endsWith(".pdf");
          final bool isNetwork = file.startsWith("http");

          return Center(
            child: isPdf
                ? _buildPdfViewer(file, isNetwork)
                : _buildImageViewer(file, isNetwork),
          );
        },
      ),
    );
  }

  // --- PDF Helper ---
  Widget _buildPdfViewer(String path, bool isNetwork) {
    if (isNetwork) {
      return const PDF().fromUrl(
        path,
        placeholder: (progress) => Center(
          child: Text("$progress %", style: TextStyle(color: Colors.white)),
        ),
        errorWidget: (error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "PDF Load Failed!\nError: ${error.toString()}\n\nPath: $path",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ),
      );
    } else {
      return const PDF().fromAsset(path);
    }
  }

  // --- Image Helper ---
  Widget _buildImageViewer(String path, bool isNetwork) {
    return InteractiveViewer(
      clipBehavior: Clip.none,
      minScale: 1.0,
      maxScale: 4.0,
      child: isNetwork
          ? Image.network(
              path,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.grey, size: 50),
            )
          : Image.asset(
              path,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.grey, size: 50),
            ),
    );
  }
}
