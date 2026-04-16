import 'package:flutter/material.dart';
import 'homepage.dart';
import 'header.dart';
import 'job_application.dart';
import 'job_img.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewJobs extends StatefulWidget {
  final Job job;
  final List<Job> allJobs;

  const ViewJobs({super.key, required this.job, this.allJobs = const []});

  @override
  State<ViewJobs> createState() => _ViewJobsState();
}

class _ViewJobsState extends State<ViewJobs> {
  final ScrollController _scrollController = ScrollController();
  List<Job> relatedJobs = [];
  bool _isDescriptionExpanded = false;
  bool _isDescriptionLong = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkDescriptionLength();
  }

  void _checkDescriptionLength() {
    const int maxLines = 10;

    final textSpan = TextSpan(
      text: widget.job.description,
      style: const TextStyle(fontSize: 15, height: 1.5),
    );

    final textPainter = TextPainter(
      text: textSpan,
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(
      maxWidth: MediaQuery.of(context).size.width - 40,
    ); // minus padding

    setState(() {
      _isDescriptionLong = textPainter.didExceedMaxLines;
    });
  }

  @override
  void initState() {
    super.initState();
    loadRelatedJobs();
  }

  void loadRelatedJobs() {
    print("Current Job ID: ${widget.job.id}");
    print("Current CategoryID: ${widget.job.categoryId}");

    for (var j in widget.allJobs) {
      print("Job: ${j.title} | ID: ${j.id} | CategoryID: ${j.categoryId}");
    }

    if (widget.job.categoryId == 0) {
      setState(() => relatedJobs = []);
      return;
    }

    setState(() {
      relatedJobs = widget.allJobs.where((j) {
        return j.id != widget.job.id &&
            j.categoryId != 0 &&
            j.categoryId == widget.job.categoryId;
      }).toList();
    });

    print("Related Count: ${relatedJobs.length}");
  }

  void scrollRight() {
    const double cardWidth = 300;
    _scrollController.animateTo(
      _scrollController.offset + cardWidth,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(covariant ViewJobs oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.job.id != oldWidget.job.id) {
      loadRelatedJobs();
    }
  }

  Future<void> openWhatsApp(String phone, String message) async {
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (phone.startsWith('0')) {
      phone = '94${phone.substring(1)}';
    } else if (!phone.startsWith('94')) {
      phone = '94$phone';
    }

    final Uri url = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unable to open WhatsApp")));
    }
  }

  //for capital letter
  String toTitleCase(String text) {
    if (text.isEmpty) return text;

    return text
        .toLowerCase()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final jobTitle = job.title;
    final company = job.company;
    final location = job.location;

    final String phoneNumber = job.phone;
    const String whatsappMessage = "Hello, I am interested in this job.";

    //dummy data
    print(job.advertisementFiles);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const JobTopBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IMAGE
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: job.image.isNotEmpty
                        ? Image.network(
                            Uri.encodeFull(job.image),
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 240,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 240,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                              );
                            },
                          )
                        : Container(
                            height: 240,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 50,
                            ),
                          ),
                  ),

                  const SizedBox(height: 25),

                  // JOB TITLE
                  Text(
                    jobTitle.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // COMPANY
                  Row(
                    children: [
                      const Icon(Icons.business, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          company.toUpperCase(),
                          style: const TextStyle(fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // LOCATION
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text("Area - $location"),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // PHONE NUMBER
                  if (job.phone.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          job.phone,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 18),

                  // JOB TYPE & SALARY BADGES
                  Row(
                    children: [
                      ...job.type.split(',').map((t) {
                        t = t.trim();
                        Color color;
                        switch (t.toLowerCase()) {
                          case "full-time":
                            color = Colors.blue;
                            break;
                          case "part-time":
                            color = Colors.orange;
                            break;
                          case "contract":
                            color = Colors.purple;
                            break;
                          case "remote":
                            color = Colors.teal;
                            break;
                          case "internship":
                            color = Colors.brown;
                            break;
                          default:
                            color = Colors.grey;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _badge(t, color),
                        );
                      }).toList(),

                      // Salary badge
                      if (job.salary.trim().isNotEmpty &&
                          job.salary != "0" &&
                          job.salary != "0.0" &&
                          job.salary != "0.00")
                        _badge(job.salary, Colors.green),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // REQUIRED SKILLS
                  if (job.tags.isNotEmpty) ...[
                    Text(
                      "Required Skills",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: job.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 234, 234, 234),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // DESCRIPTION WITH SEE MORE / SEE LESS
                  if (widget.job.description.trim().isNotEmpty) ...[
                    const Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      widget.job.description,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                      maxLines: _isDescriptionExpanded ? null : 10,
                      overflow: _isDescriptionExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),

                    if (_isDescriptionLong)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _isDescriptionExpanded ? "See Less" : "See More",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],

                  // ADVERTISEMENT BUTTON
                  if (job.advertisementFiles.isNotEmpty)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                JobImageView(files: job.advertisementFiles),
                          ),
                        );
                      },

                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(209, 0, 70, 2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.download,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Advertisement",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // RELATED JOBS
                  if (relatedJobs.isNotEmpty) ...[
                    Text(
                      "More in ${widget.job.category}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 180,
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            // BouncingScrollPhysics horizontal list-ukku nallathu
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: relatedJobs.map((rJob) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth: 320,
                                      maxWidth: 360,
                                    ),
                                    child: JobCard(
                                      job: rJob,
                                      showFullTime: rJob.type
                                          .toLowerCase()
                                          .contains("full"),
                                      showPartTime: rJob.type
                                          .toLowerCase()
                                          .contains("part"),
                                      urgent: rJob.urgent,
                                      allJobs: widget.allJobs,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          // Scroll Right Arrow Indicator
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              ignoring: false,
                              child: GestureDetector(
                                onTap: () {
                                  _scrollController.animateTo(
                                    _scrollController.offset + 300,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  width: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.white.withOpacity(0.0),
                                        Colors.white.withOpacity(0.8),
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      radius: 15,
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  // BUTTONS
                  Row(
                    children: [
                      if (job.phone.isNotEmpty)
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                openWhatsApp(job.phone, whatsappMessage),
                            child: _actionBtn("Whatsapp", Colors.green),
                          ),
                        ),

                      if (job.phone.isNotEmpty && job.showApplyButton)
                        const SizedBox(width: 20),

                      if (job.showApplyButton)
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JobApplicationPage(
                                    jobName: job.title,
                                    jobId: job.id,
                                  ),
                                ),
                              );
                            },
                            child: _actionBtn(
                              "Apply Now",
                              const Color(0xFF4A90E2),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }

  Widget _actionBtn(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
