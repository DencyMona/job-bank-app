import 'dart:io';
import 'dart:convert';
import 'homepage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ApplyJobPage extends StatefulWidget {
  final String? jobName;

  const ApplyJobPage({super.key, this.jobName});

  @override
  State<ApplyJobPage> createState() => _ApplyJobPageState();
}

class _ApplyJobPageState extends State<ApplyJobPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController jobExpectationController =
      TextEditingController();

  String selectedQualification = "O/L";
  File? selectedCV;
  File? selectedPhoto;
  bool loading = false;

  List<Map<String, dynamic>> locations = [];
  List<Map<String, dynamic>> categories = [];
  int? selectedLocationId;
  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();

    fetchDropdownData();
  }

  // Optimized to fetch everything in one go
  Future<void> fetchDropdownData() async {
    try {
      var response = await http.get(
        Uri.parse(
          "https://thedevfriends.com/job/api/CvUpload.php?action=get_dropdowns",
        ),
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          locations = List<Map<String, dynamic>>.from(data['locations']);
          categories = List<Map<String, dynamic>>.from(data['categories']);
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  InputDecoration fieldStyle(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> pickCV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["pdf", "doc", "docx", "jpg", "jpeg", "png", "tiff"],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => selectedCV = File(result.files.single.path!));
    }
  }

  Future<void> pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["jpg", "jpeg", "png"],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => selectedPhoto = File(result.files.single.path!));
    }
  }

  Future<void> submitCV() async {
    if (nameController.text.isEmpty ||
        phoneController.text.length != 10 ||
        selectedPhoto == null ||
        selectedCV == null ||
        selectedLocationId == null ||
        selectedCategoryId == null) {
      String message = "Please fill all fields";
      if (phoneController.text.length != 10 &&
          phoneController.text.isNotEmpty) {
        message = "Phone number must be exactly 10 digits";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    setState(() => loading = true);

    try {
      var uri = Uri.parse(
        "https://thedevfriends.com/job/api/CvUpload.php?action=upload_cv",
      );
      var request = http.MultipartRequest('POST', uri);

      request.fields['fullname'] = nameController.text;
      request.fields['phonenumber'] = phoneController.text;
      request.fields['qualification'] = selectedQualification;
      request.fields['jobexpectation'] = jobExpectationController.text;
      request.fields['location_id'] = selectedLocationId.toString();
      request.fields['job_category'] = selectedCategoryId.toString();

      request.files.add(
        await http.MultipartFile.fromPath('photo', selectedPhoto!.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('cv_file', selectedCV!.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Success!")));
        Navigator.pop(context);
      } else {
        throw jsonResponse['message'] ?? "Upload failed";
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    jobExpectationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use PopScope to intercept the back button
    return PopScope(
      canPop: false, // Prevents the default back action (Navigator.pop)
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false, // This clears the navigation history
        );
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF100B4A), Color(0xFF3F03E3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                headerSection(context),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F2FF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.jobName != null)
                            Text(
                              widget.jobName!,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 20),

                          TextField(
                            controller: nameController,
                            decoration: fieldStyle("Full Name", ""),
                          ),
                          const SizedBox(height: 20),

                          TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: fieldStyle(
                              "Phone Number",
                              "07xxxxxxxx",
                            ),
                          ),
                          const SizedBox(height: 20),

                          // LOCATION DROPDOWN
                          dropdownLabel("Location"),
                          customDropdown<int>(
                            value: selectedLocationId,
                            hint: "Select Location",
                            items: locations.map((loc) {
                              return DropdownMenuItem<int>(
                                value: int.parse(loc['id'].toString()),
                                child: Text(loc['name'].toString()),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => selectedLocationId = val),
                          ),

                          const SizedBox(height: 20),

                          // QUALIFICATION DROPDOWN
                          dropdownLabel("Qualification"),
                          customDropdown<String>(
                            value: selectedQualification,
                            items:
                                [
                                  "O/L",
                                  "A/L",
                                  "Diploma",
                                  "HND",
                                  "Bachelor",
                                  "Master",
                                ].map((q) {
                                  return DropdownMenuItem(
                                    value: q,
                                    child: Text(q),
                                  );
                                }).toList(),
                            onChanged: (val) =>
                                setState(() => selectedQualification = val!),
                          ),

                          const SizedBox(height: 20),

                          // CATEGORY DROPDOWN
                          dropdownLabel("Category"),
                          customDropdown<int>(
                            value: selectedCategoryId,
                            hint: "Select Category",
                            items: categories.map((cat) {
                              return DropdownMenuItem<int>(
                                value: int.parse(cat['id'].toString()),
                                child: Text(cat['name'].toString()),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => selectedCategoryId = val),
                          ),

                          const SizedBox(height: 20),

                          TextField(
                            controller: jobExpectationController,
                            minLines: 3,
                            maxLines: 5,
                            decoration: fieldStyle(
                              "Job Expectation",
                              "Ex: Office Assistant...",
                            ),
                          ),

                          const SizedBox(height: 25),
                          uploadTile(
                            "Your Photo *",
                            selectedPhoto,
                            pickPhoto,
                            Icons.camera_alt,
                          ),
                          const SizedBox(height: 25),
                          uploadTile(
                            "CV *",
                            selectedCV,
                            pickCV,
                            Icons.upload_file,
                          ),

                          const SizedBox(height: 30),
                          submitButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget headerSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Upload CV",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 36, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget dropdownLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget customDropdown<T>({
    required List<DropdownMenuItem<T>> items,
    T? value,
    String? hint,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: hint != null ? Text(hint) : null,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget uploadTile(
    String title,
    File? file,
    VoidCallback onTap,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              children: [
                Icon(icon, size: 30, color: const Color(0xFF2E1ECC)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file == null ? "Tap to Upload" : file.path.split('/').last,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget submitButton() {
    return ElevatedButton(
      onPressed: loading ? null : submitCV,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        backgroundColor: const Color(0xFF05822E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              "Submit",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
