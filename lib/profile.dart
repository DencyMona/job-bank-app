import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'phoneNumber.dart';
import 'otp_purpose.dart';
import 'companyDetails.dart';
import 'userDetails.dart';
import 'homepage.dart';
import 'package:http/http.dart' as http;
import 'ViewAllCVPage.dart';
import 'approval.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> saveLogin({
    required String phoneNumber,
    required OtpPurpose purpose,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    switch (purpose) {
      case OtpPurpose.userDetails:
        await prefs.setBool("is_user_logged_in", true);
        await prefs.setString("user_phone", phoneNumber);
        break;
      case OtpPurpose.companyDetails:
        await prefs.setBool("is_company_logged_in", true);
        await prefs.setString("company_phone", phoneNumber);
        break;
      case OtpPurpose.viewCv:
        await prefs.setBool("is_recruiter_logged_in", true);
        await prefs.setString("recruiter_phone", phoneNumber);
        break;
    }
  }

  Future<void> logout(BuildContext context, String role, String phone) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String dbPhone = phone.startsWith("94") ? "0${phone.substring(2)}" : phone;

    try {
      await http.post(
        Uri.parse("https://thedevfriends.com/job/api/login_check.php"),
        body: {"action": "logout", "phone": dbPhone, "role": role},
      );
    } catch (e) {
      print("Logout API error: $e");
    }

    // Clear only the role-specific SharedPreferences
    switch (role) {
      case "user":
        await prefs.setBool("is_user_logged_in", false);
        await prefs.remove("user_phone");
        break;
      case "company":
        await prefs.setBool("is_company_logged_in", false);
        await prefs.remove("company_phone");
        break;
      case "recruiter":
        await prefs.setBool("is_recruiter_logged_in", false);
        await prefs.remove("recruiter_phone");
        break;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
      (route) => false,
    );
  }

  Future<bool> checkSubscriptionStatus(String phone) async {
    try {
      final response = await http.post(
        Uri.parse("https://thedevfriends.com/job/api/check_plan.php"),
        body: {"phone": phone},
      );

      if (response.statusCode == 200) {
        return response.body.trim() == "1";
      }
    } catch (e) {
      print("Plan check error: $e");
    }
    return false;
  }

  // --- Reusable navigation
  Future<void> _handleNavigation({
    required BuildContext context,
    required OtpPurpose purpose,
    required Widget Function(String phone) destinationBuilder,
    required String loginKey,
    required String phoneKey,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool(loginKey) ?? false;
    String phone = prefs.getString(phoneKey) ?? "";
    String formattedPhone = phone.replaceAll('+', '');

    if (isLoggedIn && phone.isNotEmpty) {
      if (purpose == OtpPurpose.viewCv) {
        try {
          final response = await http.post(
            Uri.parse("https://thedevfriends.com/job/api/login_check.php"),
            body: {"action": "check_plan", "phone": formattedPhone},
          );

          print("API Response: ${response.body}");

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            if (data['status'] == 'approved') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => destinationBuilder(phone)),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ApprovalDisclaimerPage(),
                ),
              );
            }
          }
        } catch (e) {
          print("Error checking plan: $e");
        }
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destinationBuilder(phone)),
        );
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NumberPage(purpose: purpose)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Profile", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 16, 11, 74),
                  Color.fromARGB(255, 63, 3, 227),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // HomePageக்கு navigate செய்யும்
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
              );
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // --- HEADER TEXT ---
              const Text(
                "Manage everything in one place.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 16, 11, 74),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Access your user profile and company details quickly.\nStay updated and stay connected.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 0, 0, 0),
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // --- TWO SQUARE BUTTONS ROW ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. USER DETAILS BUTTON
                  GlassAnimatedButton(
                    icon: Icons.person,
                    label: "User\nDetails",
                    isSquare: true,
                    gradientColors: [
                      Colors.orange.shade50,
                      Colors.orange.shade200,
                    ],
                    onTap: () {
                      _handleNavigation(
                        context: context,
                        purpose: OtpPurpose.userDetails,
                        destinationBuilder: (phone) =>
                            UserDetailsPage(phone: phone),
                        loginKey: "is_user_logged_in",
                        phoneKey: "user_phone",
                      );
                    },
                  ),

                  const SizedBox(width: 20),

                  // 2. COMPANY DETAILS BUTTON
                  GlassAnimatedButton(
                    icon: Icons.business,
                    label: "Company\nDetails",
                    isSquare: true,
                    gradientColors: [Colors.cyan.shade50, Colors.cyan.shade200],
                    onTap: () {
                      _handleNavigation(
                        context: context,
                        purpose: OtpPurpose.companyDetails,
                        destinationBuilder: (phone) =>
                            CompanyDetailsPage(phone: phone),
                        loginKey: "is_company_logged_in",
                        phoneKey: "company_phone",
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 35),
              // --- RECRUITMENT SECTION HEADER ---
              Column(
                children: [
                  const Text(
                    "Talent Acquisition",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Color.fromARGB(255, 16, 11, 74),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "Review applicant resumes and manage your hiring pipeline effortlessly.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 3. FIND YOUR CANDIDATES BUTTON (WIDE)
              GlassAnimatedButton(
                icon: Icons.search_rounded,
                label: "Find your Candidates",
                isSquare: false,
                width: 320,
                gradientColors: [
                  const Color.fromARGB(255, 248, 224, 250),
                  const Color.fromARGB(255, 174, 128, 234),
                ],
                onTap: () {
                  _handleNavigation(
                    context: context,
                    purpose: OtpPurpose.viewCv,
                    destinationBuilder: (phone) =>
                        AllViewCVPage(companyPhone: phone),
                    loginKey: "is_recruiter_logged_in",
                    phoneKey: "recruiter_phone",
                  );
                },
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------
// ADAPTIVE GLASS ANIMATED BUTTON
// -------------------------------------------------------
class GlassAnimatedButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSquare;
  final double width;
  final List<Color>? gradientColors;

  const GlassAnimatedButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSquare = false,
    this.width = 260,
    this.gradientColors,
  });

  @override
  State<GlassAnimatedButton> createState() => _GlassAnimatedButtonState();
}

class _GlassAnimatedButtonState extends State<GlassAnimatedButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    double finalWidth = widget.isSquare ? 150 : widget.width;
    double? finalHeight = widget.isSquare ? 150 : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            width: finalWidth,
            height: finalHeight,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: EdgeInsets.only(bottom: _hover ? 8 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors:
                    widget.gradientColors ??
                    [Colors.white, const Color.fromARGB(255, 193, 204, 250)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: const Color.fromARGB(
                  206,
                  112,
                  111,
                  111,
                ).withOpacity(0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_hover ? 0.2 : 0.1),
                  blurRadius: _hover ? 18 : 12,
                  offset: Offset(0, _hover ? 6 : 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: widget.isSquare
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.icon,
                              size: 40,
                              color: const Color.fromARGB(255, 16, 11, 74),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color.fromARGB(255, 16, 11, 74),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.icon,
                              size: 24,
                              color: const Color.fromARGB(255, 16, 11, 74),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color.fromARGB(255, 16, 11, 74),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
