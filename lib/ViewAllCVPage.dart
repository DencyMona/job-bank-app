import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'cvpage.dart';
import 'viewall.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class AllViewCVPage extends StatefulWidget {
  final String companyPhone;
  const AllViewCVPage({super.key, required this.companyPhone});

  @override
  State<AllViewCVPage> createState() => _AllViewCVPageState();
}

class _AllViewCVPageState extends State<AllViewCVPage> {
  List<Map<String, String>> cvList = [];
  bool loading = true;
  int cvLimit = 0;

  final String apiBaseUrl = "https://thedevfriends.com/job/api/";

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await updateDeviceID();
    await fetchCVs();
  }

  String _getDbFormattedPhone(String phone) {
    String p = phone.trim();
    if (p.startsWith("+94")) return "0${p.substring(3)}";
    if (p.startsWith("94") && p.length > 10) return "0${p.substring(2)}";
    return p;
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              logout();
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    String dbPhone = _getDbFormattedPhone(widget.companyPhone);

    try {
      final response = await http.post(
        Uri.parse("${apiBaseUrl}login_check.php"),
        body: {"action": "logout", "phone": dbPhone, "role": "recruiter"},
      );

      print("Logout response: ${response.body}");
    } catch (e) {
      debugPrint("Logout API error: $e");
    }

    await prefs.setBool("is_recruiter_logged_in", false);
    await prefs.remove("recruiter_phone");

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
      (route) => false,
    );
  }

  Future<String> getDeviceId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? "unknown";
      }
    } catch (e) {
      debugPrint("Device ID error: $e");
    }
    return "unknown";
  }

  Future<void> updateDeviceID() async {
    String dbPhone = _getDbFormattedPhone(widget.companyPhone);
    String deviceId = await getDeviceId();

    try {
      await http.post(
        Uri.parse("${apiBaseUrl}login_check.php"),
        body: {
          "action": "update",
          "phone": dbPhone,
          "device_id": deviceId,
          "role": "recruiter",
        },
      );
    } catch (e) {
      debugPrint("Device update error: $e");
    }
  }

  Future<void> fetchCVs() async {
    String formattedPhone = _getDbFormattedPhone(widget.companyPhone);
    final url = Uri.parse('${apiBaseUrl}cv_filter.php');

    try {
      final response = await http.post(url, body: {'phone': formattedPhone});
      if (!mounted) return;

      final data = json.decode(response.body);

      if (data['status'] == "success") {
        setState(() {
          cvLimit = data['cv_limit_from_plan'] ?? 100;
          List cvs = data['cvs'] ?? [];
          cvList = cvs.map<Map<String, String>>((cv) {
            return {
              "name": cv['fullname']?.toString() ?? "Unknown",
              "phone": cv['phonenumber']?.toString() ?? "",
              "location": cv['location']?.toString() ?? "",
              "edu": cv['qualification']?.toString() ?? "",
              // Uri.encodeFull spaces matrum special characters-ai handle seiyum
              "image": Uri.encodeFull(
                cv['photo']?.toString() ??
                    "https://thedevfriends.com/job/uploads/cv_img/default_avatar.png",
              ),
              "cv_file": Uri.encodeFull(
                cv['cv_file']?.toString() ??
                    "https://thedevfriends.com/job/uploads/cv/default_cv.pdf",
              ),
            };
          }).toList();
          loading = false;
        });
      } else {
        setState(() => loading = false);
        _msg(data['message'] ?? "Error");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _msg("Server connection error");
    }
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String formatPhoneDisplay(String phone) {
    if (phone.startsWith("0")) return "+94${phone.substring(1)}";
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    List<String> allCategories = [
      "O/L",
      "A/L",
      "Diploma",
      "HND",
      "Bachelor",
      "Master",
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 37, 37, 154),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 15,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Job Seekers",
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF130d5a),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${cvList.length} / $cvLimit",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF130d5a),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ...[
                              "O/L",
                              "A/L",
                              "Diploma",
                              "HND",
                              "Bachelor",
                              "Master",
                            ]
                            .where(
                              (cat) => cvList.any((cv) => cv["edu"] == cat),
                            )
                            .map((cat) => buildCategoryBlock(cat))
                            .toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildCategoryBlock(String category) {
    List<Map<String, String>> filtered = cvList
        .where((cv) => cv["edu"] == category)
        .take(3)
        .toList();

    int totalInCategory = cvList.where((cv) => cv["edu"] == category).length;

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (totalInCategory > 3)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewAllPage(
                          category: category,
                          cvList: cvList
                              .where((cv) => cv["edu"] == category)
                              .toList(),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "View All →",
                    style: TextStyle(fontSize: 13, color: Colors.blue),
                  ),
                ),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 0.70,
            ),
            itemBuilder: (context, index) {
              final cv = filtered[index];
              final formattedPhone = formatPhoneDisplay(cv["phone"]!);

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CVPage(
                        pdfUrl: cv['cv_file']!,
                        phone: formattedPhone.replaceAll("+94", ""),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 255, 255, 255),
                        Color(0xFFD0D8FB),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color.fromARGB(255, 136, 136, 136),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: NetworkImage(cv['image']!),
                        onBackgroundImageError: (exception, stackTrace) {
                          debugPrint(
                            "Image Load Error for ${cv['name']}: $exception",
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cv["name"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF130d5a),
                        ),
                      ),

                      const SizedBox(height: 1),
                      Text(
                        cv["location"]!,
                        style: const TextStyle(fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        formattedPhone,
                        style: const TextStyle(fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
