import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'profile.dart';
import 'editCvPage.dart';
import 'homepage.dart';
import 'viewJobs.dart';
import 'old_recommended_job.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDetailsPage extends StatefulWidget {
  final String phone;
  const UserDetailsPage({super.key, required this.phone});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  bool loading = true;
  bool error = false;
  String errorMessage = "";
  int currentCompanyPage = 0;
  final int itemsPerPage = 5;

  int currentJobPage = 0;
  final int jobsPerPage = 5;

  int currentAllSubPage = 0;
  final int subsPerPage = 5;

  // User fields
  String fullName = "User";
  String phoneNumber = "";
  String location = "";
  String qualification = "";
  String jobExpectation = "";
  String photoUrl = "";
  String subscriptionStatus = "";
  String uploadedAt = "";
  String planName = "-";
  String planDescription = "";
  String subscriptionState = "-";
  String subscriptionStartDate = "-";
  String subscriptionEndDate = "-";
  bool isPremium = false;
  int recCount = 0;
  int companyLimit = 0;

  List<dynamic> recommendedCompanies = [];
  List<dynamic> oldRecommendedCompanies = [];
  List<Map<String, dynamic>> allSubscriptions = [];
  List<Map<String, dynamic>> appliedJobs = [];

  final String apiBaseUrl = "https://thedevfriends.com/job/api/";
  final String siteBaseUrl = "https://thedevfriends.com/job/";

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  void _showLogoutDialog() {
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
              logout(); // call centralized logout
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String dbPhone = widget.phone.startsWith("94")
        ? "0${widget.phone.substring(2)}"
        : widget.phone;

    try {
      await http.post(
        Uri.parse("https://thedevfriends.com/job/api/login_check.php"),
        body: {"action": "logout", "phone": dbPhone, "role": "user"},
      );
    } catch (e) {
      debugPrint("Logout API error: $e");
    }

    await prefs.setBool("is_user_logged_in", false);
    await prefs.remove("user_phone");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
      (route) => false,
    );
  }

  Future<void> updateDeviceID(String deviceId) async {
    String dbPhone = widget.phone.startsWith("94")
        ? "0${widget.phone.substring(2)}"
        : widget.phone;

    try {
      await http.post(
        Uri.parse("${apiBaseUrl}login_check.php"),
        body: {
          "action": "update",
          "phone": dbPhone,
          "device_id": deviceId,
          "role": "user",
        },
      );
    } catch (e) {
      debugPrint("Device update error: $e");
    }
  }

  Future<void> fetchUserDetails() async {
    setState(() {
      loading = true;
      error = false;
      errorMessage = "";
    });

    final phone = Uri.encodeQueryComponent(widget.phone);
    final url = Uri.parse(
      '$apiBaseUrl/UserDetails.php?action=user_details&phone=$phone',
    );

    try {
      final res = await http.get(url);
      if (res.statusCode != 200) throw Exception("Server error");

      final data = jsonDecode(res.body);
      if (data["success"] != true) throw Exception(data["message"] ?? "Error");

      final user = data["user"];

      setState(() {
        fullName = user["fullname"] ?? "User";
        phoneNumber = user["phonenumber"] ?? "-";
        location = user["location"] ?? "-";
        qualification = user["qualification"] ?? "-";
        jobExpectation = user["jobexpectation"] ?? "-";
        uploadedAt = user["uploaded_at"] ?? "-";

        final sub = user["subscription"];
        planName = sub?["plan_name"] ?? "-";
        planDescription = sub?["description"] ?? "";
        subscriptionState = sub?["status"] ?? "-";
        subscriptionStartDate = sub?["start_date"] ?? "-";
        subscriptionEndDate = sub?["end_date"] ?? "-";
        isPremium = sub?["is_premium"] ?? false;

        recommendedCompanies = user['recommended_companies'] ?? [];
        oldRecommendedCompanies = user['old_recommended_companies'] ?? [];
        recCount = int.tryParse(user["rec_count"]?.toString() ?? "0") ?? 0;
        companyLimit = user["company_limit"] ?? 0;

        // IMAGE LOGIC
        String dbPhoto = user["photo"] ?? "";
        if (dbPhoto.isEmpty) {
          photoUrl = "${siteBaseUrl}uploads/cv_img/default.png";
        } else if (dbPhoto.startsWith("http")) {
          photoUrl = dbPhoto;
        } else if (dbPhoto.contains("uploads/")) {
          String cleanPath = dbPhoto.replaceAll("../", "");
          photoUrl = siteBaseUrl + cleanPath;
        } else {
          photoUrl = "${siteBaseUrl}uploads/cv_img/$dbPhoto";
        }

        // Applied Jobs logic
        final jobs = user["applied_jobs"] as List<dynamic>? ?? [];

        appliedJobs = jobs.map((e) {
          // Determine posted date
          String postedAt =
              e['requested_at']?.toString() ??
              e['applied_at']?.toString() ??
              "-";

          // Determine closing date
          String closingDate =
              e['closing_date']?.toString() ?? e['deadline']?.toString() ?? "-";

          // --- IMAGE LOGIC ---
          String rawImage = e['image']?.toString() ?? '';
          String finalImageUrl = '';
          if (rawImage.isEmpty) {
            finalImageUrl = "${siteBaseUrl}uploads/job_img/default.png";
          } else if (rawImage.startsWith("http")) {
            finalImageUrl = rawImage;
          } else if (rawImage.contains("uploads/")) {
            String cleanPath = rawImage.replaceAll("../", "");
            finalImageUrl = siteBaseUrl + cleanPath;
          } else {
            finalImageUrl = "${siteBaseUrl}uploads/job_img/$rawImage";
          }

          // --- ADVERTISEMENT FILES LOGIC (CORRECT) ---
          List<String> ads = [];

          if (e['advertisement_file'] != null) {
            if (e['advertisement_file'] is List) {
              ads = List<String>.from(e['advertisement_file']);
            } else {
              ads = [e['advertisement_file'].toString()];
            }
          }

          return {
            "job_title": e["job_title"] ?? "-",
            "company_name": e["company_name"] ?? "-",
            "job_type": e["job_type"] ?? "-",
            "salary": e["salary"] ?? "-",
            "location": e["job_location"] ?? "-",
            "company_phone": e["company_phone"] ?? "",
            "status_code": e["status_code"]?.toString() ?? "0",
            "status_text": e["status"] ?? "Pending",
            "image": finalImageUrl,
            "advertisement_file": ads,
            "description": e['description']?.toString() ?? "",
            "show_apply_button": e['show_apply_button']?.toString() ?? "0",
            "posted_date": postedAt,
            "closing_date": closingDate,
          };
        }).toList();
        loading = false;
      });
    } catch (e) {
      debugPrint("ERROR: $e");
      setState(() {
        loading = false;
        error = true;
        errorMessage = "Unable to load user details";
      });
    }
  }

  Future<void> _openCvFile(String cvFile) async {
    final fullUrl = cvFile.startsWith("http") ? cvFile : "$siteBaseUrl$cvFile";
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cannot open CV file")));
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
    return false;
  }

  Color _getStatusColor(String statusCode) {
    switch (statusCode) {
      case "1":
        return Colors.green;
      case "2":
        return Colors.red;
      case "0":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF100B4A),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _showLogoutDialog();
              },
            ),
          ],
        ),

        body: RefreshIndicator(
          onRefresh: fetchUserDetails,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: fetchUserDetails,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(), // <-- add this
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --card1 :CV DETAILS CARD
                      Card(
                        color: const Color.fromARGB(255, 234, 225, 248),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 35,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: photoUrl.isNotEmpty
                                          ? NetworkImage(photoUrl)
                                          : null,
                                      child: photoUrl.isEmpty
                                          ? const Icon(Icons.person, size: 35)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fullName,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              const Divider(),

                              _detailRow("Phone Number", phoneNumber),
                              _detailRow("Location", location),
                              _detailRow("Qualification", qualification),
                              _detailRow("Job Expectation", jobExpectation),
                              _editCvRow(context, widget.phone),
                              _detailRow("Uploaded At", uploadedAt),
                              _detailRow(
                                "Subscription Status",
                                subscriptionState,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // -- card 2 :CURRENT SUBSCRIPTION CARD
                      Card(
                        color: const Color.fromARGB(255, 251, 236, 253),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Current Subscription",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              _detailRow("Plan Name", planName),
                              if (planDescription.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    planDescription,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              _detailRow("Start", subscriptionStartDate),
                              _detailRow("End", subscriptionEndDate),
                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "old jobs",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(
                                      Icons.remove_red_eye,
                                      size: 16,
                                    ),
                                    label: const Text("View"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        216,
                                        210,
                                        234,
                                      ),
                                      foregroundColor: const Color.fromARGB(
                                        255,
                                        39,
                                        39,
                                        39,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 4,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: const BorderSide(
                                          color: Color.fromARGB(
                                            255,
                                            205,
                                            203,
                                            203,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => OldRecommendedPage(
                                            oldCompanies:
                                                oldRecommendedCompanies,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),

                              _detailRow(
                                "Recommendations",
                                "$recCount/$companyLimit",
                              ),
                              const SizedBox(height: 8),

                              // --- PAGINATED LIST ---
                              if (recommendedCompanies.isNotEmpty) ...[
                                Builder(
                                  builder: (context) {
                                    int startIndex =
                                        currentCompanyPage * itemsPerPage;
                                    int endIndex = startIndex + itemsPerPage;
                                    var visibleCompanies = recommendedCompanies
                                        .sublist(
                                          startIndex,
                                          endIndex > recommendedCompanies.length
                                              ? recommendedCompanies.length
                                              : endIndex,
                                        );

                                    return Column(
                                      children: [
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: visibleCompanies.length,
                                          itemBuilder: (context, index) {
                                            final company =
                                                visibleCompanies[index];

                                            return Card(
                                              color: const Color.fromARGB(
                                                255,
                                                249,
                                                240,
                                                250,
                                              ),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                  ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      company["company_name"] ??
                                                          "-",
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),

                                                    Text(
                                                      "Job type: ${company["job_type"] ?? "-"}",
                                                    ),

                                                    Text(
                                                      "Location: ${company["company_location"] ?? "-"}",
                                                    ),
                                                    Text(
                                                      "Phone: ${company["company_phone"] ?? "-"}",
                                                    ),
                                                    Text(
                                                      "Posted at: ${company["created_at"] ?? "-"}",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 10),

                                        // --- NAVIGATION BAR (Bottom-most) ---
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              top: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed:
                                                    currentCompanyPage > 0
                                                    ? () => setState(
                                                        () =>
                                                            currentCompanyPage--,
                                                      )
                                                    : null,
                                                icon: const Icon(
                                                  Icons.arrow_back_ios,
                                                  size: 14,
                                                ),
                                                label: const Text("Prev"),
                                                style: ElevatedButton.styleFrom(
                                                  elevation: 0,
                                                ),
                                              ),
                                              Text(
                                                " ${currentCompanyPage + 1} / ${(recommendedCompanies.length / itemsPerPage).ceil()}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              ElevatedButton.icon(
                                                onPressed:
                                                    (currentCompanyPage + 1) *
                                                            itemsPerPage <
                                                        recommendedCompanies
                                                            .length
                                                    ? () => setState(
                                                        () =>
                                                            currentCompanyPage++,
                                                      )
                                                    : null,
                                                label: const Text("Next"),
                                                icon: const Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 14,
                                                ),

                                                style: ElevatedButton.styleFrom(
                                                  elevation: 0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ] else
                                const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text("No recommended companies found"),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // -- Card 3 : Applied Jobs Section --
                      if (appliedJobs.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  "Applied Jobs",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF100B4A),
                                  ),
                                ),
                              ),
                              const Divider(
                                thickness: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                              Builder(
                                builder: (context) {
                                  // Pagination Logic
                                  int startIndex = currentJobPage * jobsPerPage;
                                  int endIndex = startIndex + jobsPerPage;
                                  var visibleJobs = appliedJobs.sublist(
                                    startIndex,
                                    endIndex > appliedJobs.length
                                        ? appliedJobs.length
                                        : endIndex,
                                  );

                                  return Column(
                                    children: [
                                      ListView.builder(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: visibleJobs.length,
                                        itemBuilder: (context, index) {
                                          final json = visibleJobs[index];

                                          // Map JSON to Job model
                                          final jobModel = Job.fromJson({
                                            "id": json['id']?.toString() ?? "0",
                                            "title": json['job_title'] ?? "",
                                            "company":
                                                json['company_name'] ?? "",
                                            "location": json['location'] ?? "-",
                                            "phone":
                                                json['company_phone'] ?? "",
                                            "image": json['image'] ?? "",
                                            "type": json['job_type'] ?? "",
                                            "salary": json['salary'] ?? "",
                                            "status":
                                                json['status_code'] ?? "0",
                                            "posted_date":
                                                json['posted_date'] ?? "-",
                                            "closing_date":
                                                json['closing_date'] ?? "-",
                                            "category": "",
                                            "urgent": "0",
                                            "badge_color": "#FFD700",
                                            "description":
                                                json['description'] ?? "-",
                                            "show_apply_button":
                                                json['show_apply_button'] ??
                                                "0",
                                            "advertisement_file":
                                                json['advertisement_file'],
                                          });

                                          return InkWell(
                                            onTap: () {
                                              // Open detailed job view
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ViewJobs(
                                                    job: jobModel,
                                                    allJobs: const [],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: JobCard(
                                              job: jobModel,
                                              allJobs: const [],
                                              urgent: false,
                                              showFullTime: jobModel.type
                                                  .toLowerCase()
                                                  .contains("full"),
                                              showPartTime: jobModel.type
                                                  .toLowerCase()
                                                  .contains("part"),
                                              showIntern: jobModel.type
                                                  .toLowerCase()
                                                  .contains("intern"),
                                              showRemote: jobModel.type
                                                  .toLowerCase()
                                                  .contains("remote"),
                                              showContract: jobModel.type
                                                  .toLowerCase()
                                                  .contains("contract"),
                                              showStatus: true,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      // Pagination Controls
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: currentJobPage > 0
                                                  ? () => setState(
                                                      () => currentJobPage--,
                                                    )
                                                  : null,
                                              icon: const Icon(
                                                Icons.chevron_left,
                                              ),
                                              label: const Text("Prev"),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.grey[200],
                                                foregroundColor: const Color(
                                                  0xFF100B4A,
                                                ),
                                                elevation: 0,
                                              ),
                                            ),
                                            Text(
                                              "${currentJobPage + 1} / ${(appliedJobs.length / jobsPerPage).ceil()}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed:
                                                  (currentJobPage + 1) *
                                                          jobsPerPage <
                                                      appliedJobs.length
                                                  ? () => setState(
                                                      () => currentJobPage++,
                                                    )
                                                  : null,
                                              label: const Text("Next"),
                                              icon: const Icon(
                                                Icons.chevron_right,
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.grey[200],
                                                foregroundColor: const Color(
                                                  0xFF100B4A,
                                                ),
                                                elevation: 0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      // -- card 4 :ALL SUBSCRIPTIONS CARD
                      if (allSubscriptions.isNotEmpty)
                        Card(
                          color: const Color.fromARGB(255, 247, 238, 238),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "All Subscriptions",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(),

                                Builder(
                                  builder: (context) {
                                    // Pagination Logic
                                    int startIndex =
                                        currentAllSubPage * subsPerPage;
                                    int endIndex = startIndex + subsPerPage;
                                    var visibleSubs = allSubscriptions.sublist(
                                      startIndex,
                                      endIndex > allSubscriptions.length
                                          ? allSubscriptions.length
                                          : endIndex,
                                    );

                                    return Column(
                                      children: [
                                        // ListView with shrinkWrap (No fixed height)
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: visibleSubs.length,
                                          itemBuilder: (context, index) {
                                            final sub = visibleSubs[index];
                                            return Card(
                                              color: const Color.fromARGB(
                                                255,
                                                254,
                                                251,
                                                251,
                                              ),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      sub["plan_name"] ?? "-",
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "Status: ${sub["status"] ?? "-"}",
                                                    ),
                                                    Text(
                                                      "Amount: ${sub["amount"] ?? "-"}",
                                                    ),
                                                    Text(
                                                      "Start: ${sub["start_date"] ?? "-"}",
                                                    ),
                                                    Text(
                                                      "End: ${sub["end_date"] ?? "-"}",
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 12),

                                        // --- PAGINATION BAR ---
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            ElevatedButton(
                                              onPressed: currentAllSubPage > 0
                                                  ? () => setState(
                                                      () => currentAllSubPage--,
                                                    )
                                                  : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
                                              ),
                                              child: const Text("Previous"),
                                            ),
                                            Text(
                                              "${currentAllSubPage + 1} / ${(allSubscriptions.length / subsPerPage).ceil()}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed:
                                                  (currentAllSubPage + 1) *
                                                          subsPerPage <
                                                      allSubscriptions.length
                                                  ? () => setState(
                                                      () => currentAllSubPage++,
                                                    )
                                                  : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
                                              ),
                                              child: const Text("Next"),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
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
}

// DETAIL ROW WIDGET (for text fields)
Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            color: Color.fromARGB(255, 36, 36, 36),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w500),
            softWrap: true,
          ),
        ),
      ],
    ),
  );
}

// EDIT CV ROW WIDGET
Widget _editCvRow(BuildContext context, String phone) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Edit your CV",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to Edit CV Page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditCvPage(phone: phone)),
            );

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Edit CV clicked")));
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text("Edit"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 216, 210, 234),
            foregroundColor: const Color.fromARGB(255, 39, 39, 39),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(
                color: Color.fromARGB(255, 205, 203, 203),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// CV ROW WIDGET (clickable CV file)
Widget _cvRow(
  BuildContext context,
  String title,
  String? name,
  String? file,
  String baseUrl,
) {
  final displayName = (name == null || name.isEmpty) ? "Download CV" : name;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text("$title:", style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(
          child: file != null && file.isNotEmpty
              ? InkWell(
                  onTap: () async {
                    final fullUrl = file.startsWith("http")
                        ? file
                        : "$baseUrl$file";
                    final uri = Uri.parse(fullUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Cannot open CV file")),
                      );
                    }
                  },
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    textAlign: TextAlign.right,
                  ),
                )
              : Text("-", textAlign: TextAlign.right),
        ),
      ],
    ),
  );
}
