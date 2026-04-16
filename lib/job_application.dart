import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart';

class JobApplicationPage extends StatefulWidget {
  final String jobName;
  final int jobId;

  const JobApplicationPage({
    super.key,
    required this.jobName,
    required this.jobId,
  });

  @override
  State<JobApplicationPage> createState() => _JobApplicationPageState();
}

class _JobApplicationPageState extends State<JobApplicationPage> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  File? selectedCV;
  bool isLoading = false;

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }

  InputDecoration fieldStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  // ---------------- PICK CV (OPTIONAL) ----------------
  Future<void> pickCV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result == null || result.files.isEmpty) return;

    final path = result.files.first.path;
    if (path == null) return;

    final file = File(path);
    final sizeMB = file.lengthSync() / (1024 * 1024);

    if (sizeMB > 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("File must be under 10MB")));
      return;
    }

    setState(() => selectedCV = file);
  }

  // ---------------- SUBMIT ----------------
  Future<void> submitApplication() async {
    if (fullNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }
    // PHONE 10 DIGIT VALIDATION
    if (phoneController.text.trim().length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number must be exactly 10 digits")),
      );
      return;
    }
    setState(() => isLoading = true);

    try {
      final uri = Uri.parse(
        'https://thedevfriends.com/job/api/job_application.php',
      );
      final request = http.MultipartRequest('POST', uri);

      request.fields.addAll({
        'job_id': widget.jobId.toString(),
        'full_name': fullNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'location': locationController.text.trim(),
      });

      // -------- CV OPTIONAL --------
      if (selectedCV != null) {
        final ext = selectedCV!.path.split('.').last.toLowerCase();
        String mime = 'application/octet-stream';

        if (ext == 'pdf') mime = 'application/pdf';
        if (ext == 'doc') mime = 'application/msword';
        if (ext == 'docx') {
          mime =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        }
        request.files.add(
          await http.MultipartFile.fromPath(
            'cv',
            selectedCV!.path,
            contentType: MediaType(mime.split('/')[0], mime.split('/')[1]),
          ),
        );
      }
      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception("Server error");
      }

      final body = await response.stream.bytesToString();
      final jsonData = jsonDecode(body);

      if (jsonData['success'] == true) {
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(Icons.check, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Application Submitted",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonData['message'] ?? "Failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF120B4A), Color(0xFF3F03E3)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Job Application",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F2FF),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: fullNameController,
                          decoration: fieldStyle("Full Name"),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: phoneController,
                          decoration: fieldStyle("Phone Number"),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),

                        const SizedBox(height: 16),
                        TextField(
                          controller: locationController,
                          decoration: fieldStyle("Location"),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () async {
                            // Allow replacing the CV even if one is already selected
                            await pickCV();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.upload_file,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    selectedCV == null
                                        ? "Upload CV (Optional)"
                                        : selectedCV!.path
                                              .split(Platform.pathSeparator)
                                              .last,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (selectedCV != null)
                                  GestureDetector(
                                    onTap: () {
                                      // Delete the selected CV
                                      setState(() => selectedCV = null);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: isLoading ? null : submitApplication,

                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text("Submit"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget uploadBox({required String text}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.upload_file, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
