import 'dart:ui';
import 'package:flutter/material.dart';
import 'applyJob.dart';
import 'header.dart';
import 'phoneNumber.dart';
import 'otp_purpose.dart';

class UploadViewPage extends StatelessWidget {
  const UploadViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        children: [
          const JobTopBar(),

          // HEADER
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ---------------------- 1. ALL CVs----------------------
                  SizedBox(
                    width: 260,
                    child: GlassAnimatedButton(
                      icon: Icons.people_alt_rounded,
                      label: "View All CVs",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                NumberPage(purpose: OtpPurpose.viewCv),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ---------------------- 2. UPLOAD CV ----------------------
                  SizedBox(
                    width: 260,
                    child: GlassAnimatedButton(
                      icon: Icons.upload_file,
                      label: "Upload CV",
                      onTap: () {
                        showDisclaimerPopup(context, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ApplyJobPage(),
                            ),
                          );
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// DISCLAIMER POPUP (FULL WORKING)
// -------------------------------------------------------

void showDisclaimerPopup(BuildContext context, VoidCallback onAgree) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      bool agreed = false;

      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 40,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF7F8FF), Color(0xFFE4E7FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Disclaimer",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D0C9F),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "By uploading your CV, you authorize the company to view "
                      "and process your information. You agree that it may be "
                      "shared with our partner companies for potential job opportunities.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, height: 1.4),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "உங்கள் CV-வை பதிவேற்றுவதன் மூலம், நீங்கள் உங்கள் தகவலை "
                      "நிறுவனம் பார்வையிட்டு செயலாக்க அனுமதி வழங்குகிறீர்கள். "
                      "மேலும், உங்கள் பணி வாய்ப்புகளுக்காக எங்கள் பிற நிறுவனங்களுடன் "
                      "பகிரப்படலாம் என்பதை நீங்கள் ஒப்புக்கொள்கிறீர்கள்.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, height: 1.4),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Checkbox(
                          value: agreed,
                          onChanged: (val) {
                            setState(() => agreed = val!);
                          },
                        ),
                        const Expanded(
                          child: Text(
                            "Agree Terms & Conditions",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D0C9F),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: agreed
                            ? () {
                                Navigator.pop(context);
                                onAgree();
                              }
                            : null,
                        child: const Text(
                          "Continue",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// -------------------------------------------------------
// CUSTOM GLASS BUTTON
// -------------------------------------------------------

class GlassAnimatedButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const GlassAnimatedButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<GlassAnimatedButton> createState() => _GlassAnimatedButtonState();
}

class _GlassAnimatedButtonState extends State<GlassAnimatedButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
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
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: EdgeInsets.only(bottom: _hover ? 8 : 0),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color.fromARGB(255, 193, 204, 250)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: const Color.fromARGB(206, 112, 111, 111),
                width: 1.2,
              ),
              boxShadow: _hover
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 25,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 24, color: Colors.black),
                      const SizedBox(width: 12),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
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
