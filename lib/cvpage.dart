import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

class CVPage extends StatefulWidget {
  final String pdfUrl;
  final String phone;

  const CVPage({super.key, required this.pdfUrl, required this.phone});

  @override
  State<CVPage> createState() => _CVPageState();
}

class _CVPageState extends State<CVPage> {
  String? localPath;
  bool isImage = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFileTypeAndLoad();
  }

  /// கோப்பு வகையைச் சரிபார்த்து அதற்கேற்ப லோட் செய்யும்
  void _checkFileTypeAndLoad() {
    final url = widget.pdfUrl.toLowerCase();
    if (url.endsWith('.pdf')) {
      isImage = false;
      loadPdfFromUrl();
    } else {
      isImage = true;
      // படங்கள் என்றால் நேரடியாக URL-ஐப் பயன்படுத்தலாம்
      setState(() {
        localPath = widget.pdfUrl;
        isLoading = false;
      });
    }
  }

  /// PDF-ஐ மட்டும் தற்காலிகமாகப் பதிவிறக்கிப் பாதையை உருவாக்கும்
  Future<void> loadPdfFromUrl() async {
    try {
      final encodedUrl = Uri.encodeFull(widget.pdfUrl);
      final response = await http.get(Uri.parse(encodedUrl));

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File(
          "${directory.path}/temp_cv_${DateTime.now().millisecondsSinceEpoch}.pdf",
        );
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          setState(() {
            localPath = file.path;
            isLoading = false;
          });
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error loading PDF: $e");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load PDF: $e")));
      }
    }
  }

  /// WhatsApp-ஐத் திறக்கும்
  Future<void> openWhatsApp() async {
    String phone = widget.phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (phone.startsWith('0')) {
      phone = '94${phone.substring(1)}';
    } else if (!phone.startsWith('94') && phone.length == 9) {
      phone = '94$phone';
    }

    final Uri whatsappUri = Uri.parse("whatsapp://send?phone=$phone");

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        final Uri webUri = Uri.parse("https://wa.me/$phone");
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("WhatsApp Error: $e");
    }
  }

  /// கோப்பைச் சேமிக்கும் (Image அல்லது PDF இரண்டிற்கும் வேலை செய்யும்)
  Future<void> downloadFile() async {
    if (localPath == null) return;

    try {
      String? fileToSave;

      // படம் என்றால் முதலில் அதைப் பதிவிறக்கி தற்காலிகப் பாதையை உருவாக்க வேண்டும்
      if (isImage) {
        final response = await http.get(Uri.parse(Uri.encodeFull(localPath!)));
        final directory = await getTemporaryDirectory();
        final file = File("${directory.path}/downloaded_cv_image.jpg");
        await file.writeAsBytes(response.bodyBytes);
        fileToSave = file.path;
      } else {
        fileToSave = localPath;
      }

      final params = SaveFileDialogParams(
        sourceFilePath: fileToSave!,
        fileName: isImage ? "CV_Image.jpg" : "CV_Document.pdf",
      );

      final result = await FlutterFileDialog.saveFile(params: params);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File saved successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("CV Viewer", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF130d5a),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : localPath == null
          ? const Center(child: Text("Unable to load CV"))
          : isImage
          ? Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  localPath!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const CircularProgressIndicator();
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Text("Image format not supported"),
                ),
              ),
            )
          : PDFView(
              filePath: localPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageSnap: true,
              backgroundColor: Colors.white,
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.phone.isNotEmpty)
            FloatingActionButton(
              heroTag: "whatsapp_btn",
              backgroundColor: Colors.green,
              onPressed: openWhatsApp,
              child: const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 15),
          FloatingActionButton(
            heroTag: "download_btn",
            backgroundColor: Colors.blue,
            onPressed: downloadFile,
            child: const Icon(Icons.download, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
