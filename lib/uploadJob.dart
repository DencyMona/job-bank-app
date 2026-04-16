import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class UploadJobPage extends StatefulWidget {
  final String? companyName;
  final String? phoneNumber;
  final String companyId;
  final bool fromCompany;

  const UploadJobPage({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.phoneNumber,
    this.fromCompany = false,
  });

  @override
  State<UploadJobPage> createState() => _UploadJobPageState();
}

class _UploadJobPageState extends State<UploadJobPage> {
  final TextEditingController companyController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedJobType;
  File? logoFile;
  List<PlatformFile> posterFiles = [];
  List<String> locations = [];
  String? selectedLocation;
  bool loadingLocations = false;
  int companyId = 1;
  DateTime? selectedClosingDate;
  bool loading = false;
  List<String> categories = [];
  String? selectedCategory;
  bool loadingCategories = false;

  // ---------------- NEW: INIT STATE ----------------
  @override
  void initState() {
    super.initState();

    if (widget.companyName != null) {
      companyController.text = widget.companyName!;
    }
    if (widget.phoneNumber != null) {
      phoneController.text = widget.phoneNumber!;
    }
    fetchLocations();
    fetchCategories();
  }

  //check name phone validation
  Future<bool> checkPhoneCompanyMatch() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://thedevfriends.com/job/jobs_api.php?action=validate_phone&phone=${phoneController.text}&company_name=${companyController.text}",
        ),
      );

      // Debug
      print("Server Response: ${response.body}");

      if (response.body.isEmpty) {
        print("Error: Server returned an empty response");
        return false;
      }

      final data = jsonDecode(response.body);
      if (data['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Validation failed")),
        );
        return false;
      }
      return true;
    } catch (e) {
      print("Validation error detail: $e");
      return false;
    }
  }

  // ---------------- FILE PICKERS ----------------
  Future pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => logoFile = File(result.files.single.path!));
    }
  }

  Future pickPosters() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        setState(() => posterFiles = result.files);
      }
    } catch (e) {
      print("Error picking posters: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to pick files: $e")));
    }
  }

  // ---------------- TEMP FILE CREATOR ----------------
  Future<File> _createTempFile(String fileName, Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  // ---------------- UPLOAD JOB POSTERS ----------------
  Future<void> _uploadPosters(http.MultipartRequest request) async {
    for (var f in posterFiles) {
      File fileToUpload;
      if (f.bytes != null) {
        fileToUpload = await _createTempFile(f.name, f.bytes!);
      } else if (f.path != null) {
        fileToUpload = File(f.path!);
      } else {
        continue;
      }
      request.files.add(
        await http.MultipartFile.fromPath(
          'poster[]',
          fileToUpload.path,
          filename: f.name,
        ),
      );
    }
  }

  // ---------------- Categories----------------
  Future<void> fetchCategories() async {
    setState(() => loadingCategories = true);
    try {
      final res = await http.get(
        Uri.parse(
          "https://thedevfriends.com/job/jobs_api.php?action=categories",
        ),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          categories = List<String>.from(data['categories']);
        });
      }
    } catch (e) {
      print("Category fetch error: $e");
    }
    setState(() => loadingCategories = false);
  }

  // ---------------- LOCATION----------------
  Future<void> fetchLocations() async {
    setState(() => loadingLocations = true);
    try {
      final res = await http.get(
        Uri.parse(
          "https://thedevfriends.com/job/jobs_api.php?action=locations",
        ),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          locations = List<String>.from(data['locations']);
        });
      }
    } catch (e) {
      print("Location fetch error: $e");
    }
    setState(() => loadingLocations = false);
  }

  // ---------------- SUBMIT JOB ----------------
  Future<void> submitJob() async {
    if (companyController.text.isEmpty ||
        jobTitleController.text.isEmpty ||
        selectedJobType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Required fields missing")));
      return;
    }

    try {
      setState(() => loading = true);

      var uri = Uri.parse(
        "https://thedevfriends.com/job/jobs_api.php?action=upload",
      );
      var request = http.MultipartRequest('POST', uri);

      // Check if coming from Company Dashboard
      bool isFromDashboard = widget.fromCompany;

      if (isFromDashboard) {
        request.fields['from_company'] = "1";
        request.fields['company_id'] = widget.companyId
            .toString(); // Pass the ID
      } else {
        request.fields['from_company'] = "0";
        request.fields['company_id'] = "";
      }

      // Normalizing Phone Number
      String phone = phoneController.text.replaceAll(' ', '');
      if (phone.startsWith('+94'))
        phone = '0' + phone.substring(3);
      else if (phone.startsWith('94'))
        phone = '0' + phone.substring(2);

      request.fields['phone'] = phone;
      request.fields['company_name'] = companyController.text;
      request.fields['job_title'] = jobTitleController.text;
      request.fields['job_type'] = selectedJobType!;
      request.fields['email'] = emailController.text;
      request.fields['salary'] = salaryController.text;
      request.fields['location'] = selectedLocation ?? "";
      request.fields['category_id'] =
          selectedCategory ?? ""; // Ensure ID is sent
      request.fields['closing_date'] = selectedClosingDate != null
          ? selectedClosingDate!.toIso8601String().split('T')[0]
          : "";
      request.fields['tags'] = tagsController.text;
      request.fields['description'] = descriptionController.text;

      request.fields['show_apply_button'] = "1";

      // Logo Upload
      if (logoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('logo', logoFile!.path),
        );
      }

      // Multi-Poster Upload
      await _uploadPosters(request);

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseBody);

      setState(() => loading = false);

      if (jsonResponse['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Success!")));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${jsonResponse['message']}")),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      print("Submit Error: $e");
    }
  }

  void _clearFields() {
    companyController.clear();
    emailController.clear();
    phoneController.clear();
    salaryController.clear();
    jobTitleController.clear();
    tagsController.clear();
    descriptionController.clear();
    setState(() {
      selectedClosingDate = null;
      logoFile = null;
      posterFiles = [];
      selectedJobType = null;
    });
  }

  @override
  void dispose() {
    companyController.dispose();
    emailController.dispose();
    phoneController.dispose();
    salaryController.dispose();
    jobTitleController.dispose();
    tagsController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              _buildHeader(),
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
                        buildLabel("Company Name"),
                        buildTextField(
                          companyController,
                          //isReadOnly: widget.companyName != null,
                        ),

                        buildLabel("Email"),
                        buildTextField(emailController, hint: "abc@gmail.com"),

                        buildLabel("Phone"),
                        buildTextField(
                          phoneController,
                          hint: "Enter 10-digit phone number",
                          keyboard: TextInputType.phone,
                          //isReadOnly: widget.phoneNumber != null,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),

                        buildLabel("Salary"),
                        buildTextField(
                          salaryController,
                          keyboard: TextInputType.number,
                        ),

                        buildLabel("Job Title"),
                        buildTextField(jobTitleController),

                        buildLabel("Job Type"),
                        buildDropdown(),

                        buildLabel("Location"),
                        buildLocationDropdown(),

                        buildLabel("Category"),
                        buildCategoryDropdown(),

                        buildLabel("Tags / Skills"),
                        buildTextField(tagsController, hint: "PHP, Design"),

                        buildLabel("Job Description"),
                        buildDescriptionField(descriptionController),

                        buildLabel("Closing Date "),
                        buildDatePicker(),

                        const SizedBox(height: 20),
                        buildSingleFilePicker(
                          "Upload Logo",
                          logoFile,
                          pickLogo,
                        ),
                        const SizedBox(height: 15),
                        buildFilePickerMultiple(
                          "Upload Poster",
                          posterFiles,
                          pickPosters,
                        ),

                        const SizedBox(height: 25),
                        Center(
                          child: ElevatedButton(
                            onPressed: loading ? null : submitJob,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(200, 55),
                              backgroundColor: const Color(0xFF098414),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Submit",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 40),
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

  Widget buildCategoryDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: selectedCategory,
        hint: loadingCategories
            ? const Text("Loading categories...")
            : const Text("Select Category"),
        items: categories.map((cat) {
          return DropdownMenuItem(value: cat, child: Text(cat));
        }).toList(),
        onChanged: (value) {
          setState(() => selectedCategory = value);
        },
      ),
    ),
  );

  Widget buildLocationDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: selectedLocation,
        hint: loadingLocations
            ? const Text("Loading locations...")
            : const Text("Select Location"),
        items: locations.map((loc) {
          return DropdownMenuItem(value: loc, child: Text(loc));
        }).toList(),
        onChanged: (value) {
          setState(() => selectedLocation = value);
        },
      ),
    ),
  );

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Upload Job",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, size: 38, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 15, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    ),
  );

  Widget buildTextField(
    TextEditingController controller, {
    String? hint,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool isReadOnly = false, // Keep this false
  }) => TextField(
    controller: controller,
    keyboardType: keyboard,
    inputFormatters: inputFormatters,
    readOnly: isReadOnly, // This will now be false
    decoration: InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    ),
  );

  //Dropdown
  Widget buildDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedJobType,
        hint: const Text("Select Job Type"),
        items: const [
          DropdownMenuItem(value: "Full-time", child: Text("Full-time")),
          DropdownMenuItem(value: "Part-time", child: Text("Part-time")),
          DropdownMenuItem(value: "Contract", child: Text("Contract")),
          DropdownMenuItem(value: "Remote", child: Text("Remote")),
          DropdownMenuItem(value: "Internship", child: Text("Internship")),
        ],
        onChanged: (value) => setState(() => selectedJobType = value),
      ),
    ),
  );

  //Description
  Widget buildDescriptionField(TextEditingController controller) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: TextField(
      controller: controller,
      maxLines: 8,
      decoration: const InputDecoration(border: InputBorder.none),
    ),
  );

  //logo
  Widget buildSingleFilePicker(String label, File? file, VoidCallback onTap) {
    bool isPdf = file != null && file.path.toLowerCase().endsWith('.pdf');

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          children: [
            Icon(
              isPdf ? Icons.picture_as_pdf : Icons.image,
              color: isPdf ? Colors.red : Colors.black,
              size: 30,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                file == null ? label : file.path.split('/').last,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDatePicker() {
    return InkWell(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          setState(() => selectedClosingDate = pickedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 15),
                Text(
                  selectedClosingDate == null
                      ? "Select Closing Date "
                      : "${selectedClosingDate!.day}/${selectedClosingDate!.month}/${selectedClosingDate!.year}",
                  style: TextStyle(
                    fontSize: 16,
                    color: selectedClosingDate == null
                        ? Colors.grey[600]
                        : Colors.black,
                  ),
                ),
              ],
            ),
            if (selectedClosingDate != null)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: () => setState(() => selectedClosingDate = null),
              ),
          ],
        ),
      ),
    );
  }

  // Advertisement
  Widget buildFilePickerMultiple(
    String label,
    List<PlatformFile> files,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with upload icon
            Row(
              children: [
                const Icon(Icons.upload_file, size: 30, color: Colors.black87),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // List of selected files
            if (files.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: files.map((f) {
                    final isPdf = f.name.toLowerCase().endsWith('.pdf');
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPdf ? Colors.red[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPdf ? Colors.red : Colors.blue,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPdf ? Icons.picture_as_pdf : Icons.image,
                            size: 18,
                            color: isPdf ? Colors.red : Colors.blue,
                          ),
                          const SizedBox(width: 5),
                          SizedBox(
                            width: 100,
                            child: Text(
                              f.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
