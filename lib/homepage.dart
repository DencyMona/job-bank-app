import 'package:flutter/material.dart';
import 'header.dart';
import 'viewJobs.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'imageView.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

// CUSTOM CLIPPER FOR TRAPEZOID
class TrapezoidClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double slant = 18;
    Path path = Path();
    path.moveTo(slant, 0);
    path.lineTo(size.width - slant, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// 1. CORNER RIBBON PAINTER (Fixes the alignment issue)
class CornerRibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Drawing the triangle
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Drawing Text "URGENT"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'URGENT',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    // Center logic for the text on the diagonal
    canvas.translate(size.width * 0.25, size.height * 0.25);
    canvas.rotate(-0.785398);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

Color hexToColor(String code) {
  String cleanHex = code.replaceAll('#', '');
  if (cleanHex.length == 6) {
    cleanHex = "FF$cleanHex";
  }
  return Color(int.parse(cleanHex, radix: 16));
}

// JOB MODEL
class Job {
  final int id;
  final String title;
  final String company;
  final int categoryId;
  final String category;
  final String location;
  final String phone;
  final String type;
  final String status;
  final String badgeColor;
  final bool urgent;
  final String? planName;
  final String closingDate;
  final String image;
  final List<String> advertisementFiles;
  final String? applicationFile;
  final String? postedDate;
  final List<String> tags;
  final String description;
  final String salary;
  final bool showApplyButton;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.categoryId,
    required this.category,
    required this.location,
    required this.phone,
    required this.type,
    required this.status,
    required this.badgeColor,
    required this.urgent,
    required this.planName,
    required this.closingDate,
    required this.image,
    required this.advertisementFiles,
    this.applicationFile,
    this.postedDate,
    this.tags = const [],
    required this.description,
    required this.salary,
    required this.showApplyButton,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    List<String> ads = [];
    final adValue = json['advertisement_file'];

    if (adValue is List) {
      ads = adValue
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (adValue is String && adValue.isNotEmpty) {
      try {
        final decoded = jsonDecode(adValue);
        if (decoded is List) {
          ads = decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (e) {
        print("ADS decode error: $e");
      }
    }
    print(
      "Debug: Title: ${json['title']} | PlanID: ${json['subscription_plan_id']} | PlanName: ${json['plan_name']}",
    );

    return Job(
      id: int.tryParse(json["id"].toString()) ?? 0,
      title: json["title"] ?? "",
      company: json["company"] ?? "",
      categoryId: int.tryParse(json["category_id"].toString()) ?? 0,
      category:
          (json["category_name"] != null &&
              json["category_name"].toString().trim().isNotEmpty)
          ? json["category_name"].toString()
          : "",
      location: json["location"] ?? "",
      phone: json['phone'] ?? '',
      type: json["type"] ?? "",
      salary: json["salary"] ?? "",
      status: json["status"] ?? "",
      badgeColor:
          (json['badge_color'] != null &&
              json['badge_color'].toString().isNotEmpty)
          ? json['badge_color'].toString()
          : "#FFD700",
      urgent: (json["urgent"] == "1" || json["urgent"] == 1),
      planName:
          (json['plan_name'] == null ||
              [
                'default',
                'none',
                '',
              ].contains(json['plan_name'].toString().toLowerCase()) ||
              json['subscription_plan_id'].toString() == "0")
          ? null
          : json['plan_name'].toString(),
      closingDate: json["closing_date"] ?? "",
      image: json["image"] ?? "",
      advertisementFiles: ads,
      applicationFile: json["application_file"],
      postedDate: json["posted_date"],
      tags: json['tags'] is String
          ? (json['tags'] as String)
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : json['tags'] is List
          ? List<String>.from(json['tags'])
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : [],
      description: json["description"] ?? "",
      showApplyButton: json["show_apply_button"] == "1",
    );
  }
}

List<String> cleanUrls(List<dynamic> rawList) {
  return rawList.map((e) {
    String url = e.toString();
    url = url
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .trim();
    return url;
  }).toList();
}

// HOME PAGE
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchLocation = "";
  String searchJob = "";
  String selectedJobType = "";

  List<Job> allJobs = [];
  bool loading = true;

  //Load More
  int currentPage = 1;
  final int jobsPerPage = 10;

  int get totalPages => (filteredJobs.length / jobsPerPage).ceil();

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    setState(() => loading = true);
    try {
      final response = await http.get(
        Uri.parse("https://thedevfriends.com/job/jobs_api.php"),
      );

      if (response.statusCode == 200) {
        print("RAW API: ${response.body}");
        final jsonData = jsonDecode(response.body);
        List jobsList = jsonData["jobs"] ?? [];

        setState(() {
          allJobs = jobsList.map((e) => Job.fromJson(e)).toList();
          loading = false;
        });
      } else {
        print("HTTP ERROR: ${response.statusCode}");
        setState(() => loading = false);
      }
    } catch (e) {
      print("ERROR: $e");
      setState(() => loading = false);
    }
  }

  List<Job> get filteredJobs {
    return allJobs.where((job) {
      // Normalize strings
      String jobLocation = job.location.toLowerCase();
      String jobTitle = job.title.toLowerCase();
      String jobType = job.type
          .toLowerCase()
          .replaceAll('-', '')
          .replaceAll(' ', '');

      String searchLoc = searchLocation.toLowerCase();
      String searchJobText = searchJob.toLowerCase();
      String selectedType = selectedJobType
          .toLowerCase()
          .replaceAll('-', '')
          .replaceAll(' ', '');

      bool matchLocation = searchLoc.isEmpty || jobLocation.contains(searchLoc);
      bool matchJob = searchJobText.isEmpty || jobTitle.contains(searchJobText);
      bool matchJobType = selectedType.isEmpty || jobType == selectedType;

      return matchLocation && matchJob && matchJobType;
    }).toList();
  }

  //load more
  List<Job> get pagedJobs {
    final start = (currentPage - 1) * jobsPerPage;
    final end = start + jobsPerPage;
    return filteredJobs.sublist(
      start,
      end > filteredJobs.length ? filteredJobs.length : end,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (currentPage > 1) {
          setState(() {
            currentPage--;
          });
          return false;
        }
        return true;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: Column(
                    children: [
                      const JobTopBar(),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: fetchJobs,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                SearchRow(
                                  onLocationChanged: (text) => setState(() {
                                    searchLocation = text;
                                    currentPage = 1;
                                  }),
                                  onJobChanged: (text) => setState(() {
                                    searchJob = text;
                                    currentPage = 1;
                                  }),
                                  onJobTypeSelected: (type) => setState(() {
                                    selectedJobType = selectedJobType == type
                                        ? ""
                                        : type;
                                    currentPage = 1;
                                  }),
                                  currentSelectedType: selectedJobType,
                                ),
                                JobsTitleRow(
                                  shownCount: pagedJobs.length,
                                  totalCount: filteredJobs.length,
                                  currentPage: currentPage,
                                  totalPages: totalPages,
                                ),
                                HomeSlider(),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: pagedJobs.length,
                                  itemBuilder: (context, index) {
                                    final job = pagedJobs[index];
                                    final type = job.type.toLowerCase();

                                    return JobCard(
                                      job: job,
                                      showFullTime: type.contains("full"),
                                      showPartTime: type.contains("part"),
                                      showIntern: type.contains("intern"),
                                      showRemote: type.contains("remote"),
                                      showContract: type.contains("contract"),
                                      urgent: job.urgent,
                                      allJobs: allJobs,
                                    );
                                  },
                                ),
                                if (totalPages > 1)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left),
                                          onPressed: currentPage > 1
                                              ? () => setState(
                                                  () => currentPage--,
                                                )
                                              : null,
                                        ),
                                        Text(
                                          "Page $currentPage of $totalPages",
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right),
                                          onPressed: currentPage < totalPages
                                              ? () => setState(
                                                  () => currentPage++,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
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
      ),
    );
  }
}

//search row
class SearchRow extends StatefulWidget {
  final Function(String) onLocationChanged;
  final Function(String) onJobChanged;
  final Function(String) onJobTypeSelected;
  final String currentSelectedType;

  const SearchRow({
    super.key,
    required this.onLocationChanged,
    required this.onJobChanged,
    required this.onJobTypeSelected,
    required this.currentSelectedType,
  });

  @override
  State<SearchRow> createState() => _SearchRowState();
}

class _SearchRowState extends State<SearchRow> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController jobController = TextEditingController();
  final FocusNode locationFocus = FocusNode();
  final FocusNode jobFocus = FocusNode();

  List<String> locationList = [];
  List<String> jobList = [];
  List<String> filteredLocations = [];
  List<String> filteredJobs = [];

  List<String> jobTypeList = [
    "Full-time",
    "Part-time",
    "Contract",
    "Remote",
    "Internship",
  ];

  @override
  void initState() {
    super.initState();
    fetchLocations();
    fetchCategories();
  }

  Future<void> fetchLocations() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://thedevfriends.com/job/jobs_api.php?action=locations",
        ),
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["success"] == true) {
          setState(() {
            locationList = List<String>.from(jsonData["locations"]);
          });
        }
      }
    } catch (e) {
      print("Error fetching locations: $e");
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.43.48/job/jobs_api.php?action=categories"),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["success"] == true) {
          setState(() {
            jobList = List<String>.from(jsonData["categories"]);
          });
        }
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  void _updateFilteredLocations(String value) {
    setState(() {
      filteredLocations = locationList
          .where((item) => item.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  void _updateFilteredJobs(String value) {
    setState(() {
      filteredJobs = jobList
          .where((item) => item.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (!locationFocus.hasFocus && !jobFocus.hasFocus) {
          FocusScope.of(context).unfocus();
          setState(() {
            filteredLocations.clear();
            filteredJobs.clear();
          });
        }
      },
      child: Column(
        children: [
          _topSearchBar(),
          if (locationFocus.hasFocus && filteredLocations.isNotEmpty)
            _suggestionList(filteredLocations, true),
          if (jobFocus.hasFocus && filteredJobs.isNotEmpty)
            _suggestionList(filteredJobs, false),
        ],
      ),
    );
  }

  Widget _topSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade400, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildLocationBox()),
          Container(height: 18, width: 1, color: Colors.grey),
          Expanded(child: _buildJobBox()),
          Container(height: 18, width: 1, color: Colors.grey),
          _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildLocationBox() {
    return Row(
      children: [
        const Icon(Icons.location_on, size: 18),
        const SizedBox(width: 3),
        Expanded(
          child: TextField(
            controller: locationController,
            focusNode: locationFocus,
            onChanged: (value) {
              widget.onLocationChanged(value);
              _updateFilteredLocations(value);
            },
            onTap: () {
              _updateFilteredLocations(locationController.text);
            },
            decoration: const InputDecoration(
              hintText: "Location",
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobBox() {
    return Row(
      children: [
        const Icon(Icons.search, size: 18),
        const SizedBox(width: 3),
        Expanded(
          child: TextField(
            controller: jobController,
            focusNode: jobFocus,
            onChanged: (value) {
              widget.onJobChanged(value);
              _updateFilteredJobs(value);
            },
            onTap: () {
              _updateFilteredJobs(jobController.text);
            },
            decoration: const InputDecoration(
              hintText: "Jobs",
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => _buildFilterBottomSheet(),
        );
      },
      child: const Icon(Icons.tune, size: 20),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...jobTypeList.map((type) => _filterOption(type)).toList(),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onJobTypeSelected("");
              setState(() {
                jobController.clear();
                filteredJobs = jobList;
              });
            },
            child: const Text("Clear Filter"),
          ),
        ],
      ),
    );
  }

  Widget _filterOption(String type) {
    bool selected =
        widget.currentSelectedType
            .toLowerCase()
            .replaceAll(' ', '')
            .replaceAll('-', '') ==
        type.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
    return ListTile(
      title: Text(type),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : null,
      onTap: () {
        Navigator.pop(context);
        widget.onJobTypeSelected(type);
      },
    );
  }

  Widget _suggestionList(List<String> list, bool isLocation) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(blurRadius: 8, color: Colors.black12, offset: Offset(0, 3)),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: list.length,
        itemBuilder: (context, index) {
          return ListTile(
            dense: true,
            title: Text(list[index]),
            onTap: () {
              setState(() {
                if (isLocation) {
                  locationController.text = list[index];
                  widget.onLocationChanged(list[index]);
                  filteredLocations.clear();
                  FocusScope.of(context).unfocus();
                } else {
                  jobController.text = list[index];
                  widget.onJobChanged(list[index]);
                  filteredJobs.clear();
                  FocusScope.of(context).unfocus();
                }
              });
            },
          );
        },
      ),
    );
  }
}

// TITLE ROW
class JobsTitleRow extends StatelessWidget {
  final int shownCount;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  const JobsTitleRow({
    super.key,
    required this.shownCount,
    required this.totalCount,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFFFFF), Color.fromARGB(255, 193, 204, 250)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "All Jobs",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1),
          Text(
            "Showing $shownCount of $totalCount ads ",
            style: const TextStyle(fontSize: 10, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

//Sliding image section
class HomeSlider extends StatelessWidget {
  HomeSlider({super.key});

  final List<String> sliderImages = [
    "assets/I1.jpg",
    "assets/I4.jpg",
    "assets/I3.jpg",
    "assets/I2.jpg",
    "assets/I5.png",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 160,
          autoPlay: true,
          enlargeCenterPage: true,
          autoPlayInterval: const Duration(seconds: 3),
          viewportFraction: 0.88,
        ),
        items: sliderImages.map((imgPath) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageViewPage(imagePath: imgPath),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imgPath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// JOB CARD WIDGET
class JobCard extends StatelessWidget {
  final Job job;
  final bool showFullTime;
  final bool showPartTime;
  final bool showIntern;
  final bool showRemote;
  final bool showContract;
  final bool urgent;
  final List<Job> allJobs;
  final bool showStatus;
  final bool isRelatedCard;

  const JobCard({
    super.key,
    required this.job,
    this.isRelatedCard = false,
    this.showFullTime = false,
    this.showPartTime = false,
    this.showIntern = false,
    this.showRemote = false,
    this.showContract = false,
    required this.urgent,
    required this.allJobs,
    this.showStatus = false,
  });

  String getDaysLeft() {
    if (job.closingDate.isEmpty) return "";
    try {
      final close = DateTime.parse(job.closingDate);
      final now = DateTime.now();
      final difference = close.difference(now).inDays;
      if (difference < 0) return "Closed";
      return "$difference Days left";
    } catch (e) {
      return "Invalid date";
    }
  }

  String getPostedDaysAgo() {
    if (job.postedDate == null || job.postedDate!.isEmpty) return "—";
    try {
      final posted = DateTime.parse(job.postedDate!);
      final now = DateTime.now();
      final difference = now.difference(posted).inDays;
      if (difference == 0) return "Posted today";
      if (difference == 1) return "Posted 1 day ago";
      return "Posted $difference days ago";
    } catch (e) {
      return "Invalid date";
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewJobs(job: job, allJobs: allJobs),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFDFEFF), Color(0xFFE3E8FF)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- IMAGE SECTION ---
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: job.image.isNotEmpty
                      ? Image.network(
                          Uri.encodeFull(job.image),
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 100,
                          width: 100,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported),
                        ),
                ),
                if (job.urgent)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: SizedBox(
                      width: 45,
                      height: 45,
                      child: CustomPaint(painter: CornerRibbonPainter()),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // --- CONTENT SECTION ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TITLE (Responsive - Next line if long)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        fit: FlexFit.tight,
                        child: Text(
                          job.title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          softWrap: true,
                          maxLines: isRelatedCard ? 1 : 2,
                          overflow: isRelatedCard
                              ? TextOverflow.ellipsis
                              : TextOverflow.visible,
                        ),
                      ),
                      if (job.planName != null && job.planName!.isNotEmpty)
                        _buildPlanBadge(job.planName!, job.badgeColor),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 2. COMPANY NAME
                  Text(
                    job.company.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                    softWrap: true,
                  ),

                  const SizedBox(height: 10),

                  // 3. LOCATION & BADGES
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 6.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Location row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 13,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            job.location,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      // Conditional Badges
                      if (showFullTime) _buildBadge("F-Time"),
                      if (showPartTime) _buildBadge("P-Time"),
                      if (showIntern) _buildBadge("Intern"),
                      if (showRemote) _buildBadge("Remote"),
                      if (showContract) _buildBadge("Contract"),
                    ],
                  ),
                  if (showStatus)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: job.status == "1" ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        job.status == "1" ? "Approved" : "Pending",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // 4. BOTTOM DATES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getPostedDaysAgo(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black45,
                        ),
                      ),
                      Text(
                        getDaysLeft(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Badge UI Helper
  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 240, 194, 255).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color.fromARGB(255, 76, 3, 84).withOpacity(0.2),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 78, 0, 127),
        ),
      ),
    );
  }

  // Premium Badge Helper
  Widget _buildPlanBadge(String plan, String hexColor) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: hexToColor(hexColor),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.workspace_premium, color: Colors.white, size: 14),
      ),
    );
  }
}
