import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'homepage.dart';
import 'profile.dart';
import 'uploadJob.dart';
import 'ViewAllCVPage.dart';
//import 'Analysis.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyDetailsPage extends StatefulWidget {
  final String phone;
  const CompanyDetailsPage({super.key, required this.phone});

  @override
  State<CompanyDetailsPage> createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<CompanyDetailsPage> {
  Map<String, dynamic>? company;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchCompany();
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              logout(context);
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> fetchCompany() async {
    try {
      final url = Uri.parse(
        'https://thedevfriends.com/job/api/companyDetails.php?phone=${widget.phone}',
      );
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          setState(() {
            company = data['company'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Company not found';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${res.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Connection Error: $e';
        isLoading = false;
      });
    }
  }

  Future<bool> _goHome() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
    return false;
  }

  Future<void> updateDeviceID(String deviceId) async {
    String dbPhone = widget.phone.startsWith("94")
        ? "0${widget.phone.substring(2)}"
        : widget.phone;

    try {
      await http.post(
        Uri.parse("https://thedevfriends.com/job/api/login_check.php"),
        body: {
          "action": "update",
          "phone": dbPhone,
          "device_id": deviceId,
          "role": "company",
        },
      );
    } catch (e) {
      debugPrint("Device update error: $e");
    }
  }

  //logout
  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String dbPhone = widget.phone;

    if (dbPhone.startsWith("94")) {
      dbPhone = "0${dbPhone.substring(2)}";
    }

    try {
      await http.post(
        Uri.parse("https://thedevfriends.com/job/api/login_check.php"),
        body: {"action": "logout", "phone": dbPhone, "role": "company"},
      );
    } catch (e) {
      print("Logout API error: $e");
    }

    await prefs.setBool("is_company_logged_in", false);
    await prefs.remove("company_phone");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  // --- CARD 1: COMPANY DETAILS ---
  Widget buildCompanyCard() {
    String? rawPath = (company?['image'] ?? company?['logo'])
        ?.toString()
        .trim();

    String baseUrl = "https://thedevfriends.com/job/";
    String imageUrl;

    if (rawPath == null || rawPath.isEmpty || rawPath == 'null') {
      imageUrl = "${baseUrl}uploads/default.png";
    } else if (rawPath.startsWith('http')) {
      imageUrl = rawPath;
    } else {
      String cleanPath = rawPath.replaceAll("../", "").replaceAll("./", "");
      if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);

      if (cleanPath.contains("uploads/")) {
        imageUrl = "$baseUrl$cleanPath";
      } else {
        imageUrl = "${baseUrl}uploads/$cleanPath";
      }
    }

    return Card(
      elevation: 3,
      color: const Color.fromARGB(255, 243, 227, 253),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Company logo on left
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  backgroundImage: imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.person, size: 35, color: Colors.blue)
                      : null,
                ),
                const SizedBox(width: 16),

                // Company name centered vertically
                Expanded(
                  child: Center(
                    child: Text(
                      company?['name']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF100B4A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow(Icons.email, "Email", company?['email']),
            _infoRow(Icons.phone, "Phone", company?['phone']),
            _infoRow(Icons.location_on, "Location", company?['location']),
          ],
        ),
      ),
    );
  }

  // --- CARD 2: CURRENT SUBSCRIPTION  ---
  Widget buildCurrentSubscriptionCard() {
    final sub = company?['subscription'] ?? {};
    final limits = sub['limits'] ?? {};

    return Card(
      elevation: 3,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Current Subscription",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(),
            Text(
              "Plan: ${sub['plan']?.toString() ?? '-'}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              "Description: ${sub['description']?.toString() ?? 'No description'}",
            ),
            Text(
              "Price: Rs. ${sub['price']?.toString() ?? '0.00'}",
              style: const TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
              ),
            ),

            // LIMITS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _limitInfo(Icons.work_outline, "Jobs Limit", limits['jobs']),
                _limitInfo(
                  Icons.description_outlined,
                  "CVs Limit",
                  limits['cvs'],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Start: ${sub['start']?.toString() ?? '-'}",
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  "End: ${sub['end']?.toString() ?? '-'}",
                  style: const TextStyle(fontSize: 11, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Limits
  Widget _limitInfo(IconData icon, String label, dynamic value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        Text(label, style: const TextStyle(fontSize: 10)),
        Text(
          value?.toString() ?? '0',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // --- CARD 3: PREVIOUS SUBSCRIPTIONS ---
  Widget buildHistoryCard() {
    final history = (company?['history'] as List<dynamic>?) ?? [];
    if (history.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Previous Subscriptions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...history
                .map(
                  (h) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      h['plan'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${h['start']} to ${h['end']}"),
                    trailing: Text("Rs. ${h['price']}"),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  // --- CARD 4: FIND CANDIDATES CTA ---
  Widget buildFindCandidatesCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.white, const Color.fromARGB(255, 229, 253, 227)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left side: Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Find Your Candidates",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 1, 120, 9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Find the best candidates suited for your company's growth by joining us.",
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllViewCVPage(companyPhone: widget.phone),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 2, 100, 22),
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
              ),
              child: const Icon(Icons.arrow_forward_ios, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  /*
  // --- CARD 5: JOB ANALYSIS CTA ---
  Widget buildJobAnalysisCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.red.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left side: Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Job Analysis",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "We’ll share your job openings across our Facebook and WhatsApp groups for wider reach. ",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => JobAnalysisPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
              ),
              child: const Icon(Icons.arrow_forward_ios, size: 18),
            ),
          ],
        ),
      ),
    );
  }
*/
  // --- CARD 6: JOBS ---
  int currentJobPage = 0;
  final int jobsPerPage = 5;

  Widget buildJobsCard() {
    final List<dynamic> jobsListRaw = company?['job_requests'] ?? [];
    final List<Job> companyJobs = jobsListRaw.map((json) {
      String rawPath =
          json['image']?.toString() ?? json['job_image']?.toString() ?? "";
      String finalImageUrl = "";

      if (rawPath.isNotEmpty) {
        if (rawPath.startsWith('http')) {
          finalImageUrl = rawPath;
        } else {
          String pathWithFolder = rawPath.contains('uploads/')
              ? rawPath
              : 'uploads/$rawPath';
          finalImageUrl = "https://thedevfriends.com/job/$pathWithFolder";
        }
        finalImageUrl = Uri.parse(finalImageUrl).toString();
      }

      return Job.fromJson({
        "id": json['id']?.toString() ?? "0",
        "title": json['job_title']?.toString() ?? "",
        "company":
            json['company_name']?.toString() ??
            company?['name']?.toString() ??
            "",
        "category": json['category']?.toString() ?? "",
        "location": json['location']?.toString() ?? "",
        "phone": json['phone']?.toString() ?? "",
        "image": finalImageUrl,
        "advertisement_file": json['advertisement_file'],
        "type": json['job_type']?.toString() ?? "",
        "status": json['status']?.toString() ?? "1",
        "salary": json['salary']?.toString() ?? "",
        "badge_color": json['badge_color']?.toString() ?? "#FFD700",
        "urgent": json['urgent']?.toString() ?? "0",
        "plan_name": json['plan_name']?.toString() ?? "",
        "subscription_plan_id": json['subscription_plan_id']?.toString() ?? "0",
        "closing_date": json['closing_date']?.toString() ?? "",
        "application_file": json['application_file']?.toString(),
        "posted_date": json['requested_at']?.toString(),
        "tags": json['tags'] ?? "",
        "description": json['description']?.toString() ?? "",
        "show_apply_button": json['show_apply_button']?.toString() ?? "0",
      });
    }).toList();

    // Pagination logic
    final int totalJobs = companyJobs.length;
    final int jobLimit =
        int.tryParse(
          company?['subscription']?['limits']?['jobs']?.toString() ?? '0',
        ) ??
        0;

    final int startIndex = currentJobPage * jobsPerPage;
    final int endIndex = (startIndex + jobsPerPage) > companyJobs.length
        ? companyJobs.length
        : startIndex + jobsPerPage;
    final List<Job> paginatedJobs = companyJobs.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Upload button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Jobs",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Total: $totalJobs / $jobLimit jobs",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UploadJobPage(
                        companyId: company?['id']?.toString() ?? '',
                        companyName: company?['name']?.toString() ?? '',
                        phoneNumber: company?['phone']?.toString() ?? '',
                        fromCompany: true,
                      ),
                    ),
                  ).then((value) => fetchCompany());
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Upload Job"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF100B4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // No jobs message
        if (companyJobs.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No jobs posted yet."),
            ),
          )
        else
          Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paginatedJobs.length,
                itemBuilder: (context, index) {
                  final jobItem = paginatedJobs[index];
                  return JobCard(
                    job: jobItem,
                    allJobs: companyJobs,
                    urgent: jobItem.urgent,
                    showFullTime: jobItem.type.toLowerCase().contains("full"),
                    showPartTime: jobItem.type.toLowerCase().contains("part"),
                    showIntern: jobItem.type.toLowerCase().contains("intern"),
                    showRemote: jobItem.type.toLowerCase().contains("remote"),
                    showContract: jobItem.type.toLowerCase().contains(
                      "contract",
                    ),
                    showStatus: true,
                  );
                },
              ),

              // Pagination buttons
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: currentJobPage > 0
                          ? () => setState(() => currentJobPage--)
                          : null,
                      icon: const Icon(Icons.arrow_back_ios, size: 14),
                      label: const Text("Prev"),
                      style: ElevatedButton.styleFrom(elevation: 0),
                    ),
                    Text(
                      "${currentJobPage + 1} / ${(companyJobs.length / jobsPerPage).ceil()}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                          (currentJobPage + 1) * jobsPerPage <
                              companyJobs.length
                          ? () => setState(() => currentJobPage++)
                          : null,
                      label: const Text("Next"),
                      icon: const Icon(Icons.arrow_forward_ios, size: 14),
                      style: ElevatedButton.styleFrom(elevation: 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value?.toString() ?? '-')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _goHome,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF100B4A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),

          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: showLogoutDialog,
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    buildCompanyCard(),
                    const SizedBox(height: 10),
                    buildCurrentSubscriptionCard(),
                    const SizedBox(height: 10),
                    buildFindCandidatesCard(),
                    const SizedBox(height: 10),
                    /* buildJobAnalysisCard(),
                    const SizedBox(height: 10),*/
                    buildHistoryCard(),
                    buildJobsCard(),
                  ],
                ),
              ),
      ),
    );
  }
}
