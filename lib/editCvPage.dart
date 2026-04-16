import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class EditCvPage extends StatefulWidget {
  final String phone;
  const EditCvPage({super.key, required this.phone});

  @override
  State<EditCvPage> createState() => _EditCvPageState();
}

class _EditCvPageState extends State<EditCvPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController jobExpectationController =
      TextEditingController();

  String selectedQualification = "O/L";
  int? selectedLocationId;
  int? selectedCategoryId;

  List<Map<String, dynamic>> locations = [];
  List<Map<String, dynamic>> categories = [];

  File? selectedPhoto;
  File? selectedCV;
  String? existingPhotoUrl;
  String? existingCvName;

  bool loading = false;
  bool fetching = true;

  final String baseUrl = "https://thedevfriends.com/job";

  @override
  void initState() {
    super.initState();
    phoneController.text = widget.phone;
    initData();
  }

  // Mukkiyam: Dropdowns load aanathukku appuram thaan Profile load aaganum
  Future<void> initData() async {
    await fetchDropdowns();
    await loadProfile();
  }

  // ---------------- FETCH DROPDOWNS ----------------
  Future<void> fetchDropdowns() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/CvUpload.php?action=get_dropdowns"),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          locations = (data['locations'] as List)
              .map(
                (item) => {
                  "id": int.tryParse(item['id'].toString()),
                  "name": item['name'].toString(),
                },
              )
              .toList();

          categories = (data['categories'] as List)
              .map(
                (item) => {
                  "id": int.tryParse(item['id'].toString()),
                  "name": item['name'].toString(),
                },
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Dropdown Fetch Error: $e");
    }
  }

  // ---------------- AUTO-FILL LOGIC (FETCH PROFILE) ----------------
  Future<void> loadProfile() async {
    setState(() => fetching = true);
    try {
      // Phone format fix (94 -> 0)
      String searchPhone = widget.phone.trim();
      if (searchPhone.startsWith("94")) {
        searchPhone = "0" + searchPhone.substring(2);
      }

      final uri = Uri.parse(
        "$baseUrl/api/EditCv.php?action=get_cv&phone=$searchPhone",
      );
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final response = json.decode(res.body);
        if (response["success"] == true) {
          final cv = response["data"];

          setState(() {
            // Text values auto-fill
            nameController.text = cv["fullname"] ?? "";
            jobExpectationController.text = cv["jobexpectation"] ?? "";
            selectedQualification = cv["qualification"] ?? "O/L";
            existingPhotoUrl = cv["photo"];
            existingCvName = cv["cv_file"]?.toString().split('/').last;

            // --- Dropdown Matching Logic ---
            // Database-la irunthu vara Name-ai vachu unga list-la ulla ID-ai kandupidikkuthu
            if (cv['location'] != null) {
              try {
                selectedLocationId = locations.firstWhere(
                  (l) =>
                      l['name'].toString().trim() ==
                      cv['location'].toString().trim(),
                )['id'];
              } catch (e) {
                debugPrint("Location match not found");
              }
            }

            if (cv['job_category'] != null) {
              try {
                selectedCategoryId = categories.firstWhere(
                  (c) =>
                      c['name'].toString().trim() ==
                      cv['job_category'].toString().trim(),
                )['id'];
              } catch (e) {
                debugPrint("Category match not found");
              }
            }
          });
        } else {
          _toast(response["message"] ?? "CV not found");
        }
      }
    } catch (e) {
      _toast("Error loading profile: $e");
    } finally {
      setState(() => fetching = false);
    }
  }

  // ---------------- UPDATE CV ----------------
  Future<void> updateCV() async {
    if (nameController.text.isEmpty ||
        selectedLocationId == null ||
        selectedCategoryId == null) {
      _toast("Please fill all required fields");
      return;
    }

    setState(() => loading = true);
    try {
      final uri = Uri.parse("$baseUrl/api/EditCv.php?action=update_cv");
      final request = http.MultipartRequest("POST", uri);

      request.fields["fullname"] = nameController.text;
      request.fields["phonenumber"] = phoneController.text;
      request.fields["qualification"] = selectedQualification;
      request.fields["location_id"] = selectedLocationId.toString();
      request.fields["job_category"] = selectedCategoryId.toString();
      request.fields["jobexpectation"] = jobExpectationController.text;

      if (selectedPhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath("photo", selectedPhoto!.path),
        );
      }
      if (selectedCV != null) {
        request.files.add(
          await http.MultipartFile.fromPath("cv_file", selectedCV!.path),
        );
      }

      final res = await request.send();
      final body = await res.stream.bytesToString();
      final decoded = json.decode(body);

      if (decoded["success"] == true) {
        _toast("Profile updated successfully");
        if (mounted) Navigator.pop(context, true);
      } else {
        _toast(decoded["message"] ?? "Update failed");
      }
    } catch (e) {
      _toast("Update error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  // ---------------- UI HELPERS ----------------

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null)
      setState(() => selectedPhoto = File(result.files.single.path!));
  }

  Future<void> pickCV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["pdf", "doc", "docx", "jpg", "png"],
    );
    if (result != null)
      setState(() => selectedCV = File(result.files.single.path!));
  }

  @override
  Widget build(BuildContext context) {
    if (fetching)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2FF),
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF100B4A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),

            const Text(
              "Location",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            DropdownButtonFormField<int>(
              initialValue: selectedLocationId,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: locations
                  .map(
                    (l) => DropdownMenuItem<int>(
                      value: l['id'],
                      child: Text(l['name']),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedLocationId = v),
            ),
            const SizedBox(height: 15),

            const Text(
              "Qualification",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            DropdownButtonFormField<String>(
              initialValue: selectedQualification,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                "O/L",
                "A/L",
                "Diploma",
                "HND",
                "Bachelor",
                "Master",
              ].map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
              onChanged: (v) => setState(() => selectedQualification = v!),
            ),
            const SizedBox(height: 15),

            const Text(
              "Job Category",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            DropdownButtonFormField<int>(
              initialValue: selectedCategoryId,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: categories
                  .map(
                    (c) => DropdownMenuItem<int>(
                      value: c['id'],
                      child: Text(c['name']),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedCategoryId = v),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: jobExpectationController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Job Expectation",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            fileSelector(
              "Update Photo",
              selectedPhoto,
              existingPhotoUrl,
              pickPhoto,
              Icons.camera_alt,
            ),
            const SizedBox(height: 10),
            fileSelector(
              "Update CV File",
              selectedCV,
              existingCvName,
              pickCV,
              Icons.description,
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : updateCV,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Update Profile",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget fileSelector(
    String label,
    File? file,
    String? old,
    VoidCallback tap,
    IconData icon,
  ) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      leading: Icon(icon, color: const Color(0xFF100B4A)),
      title: Text(file != null ? file.path.split('/').last : (old ?? label)),
      trailing: const Icon(Icons.edit, size: 20),
      onTap: tap,
    );
  }
}
