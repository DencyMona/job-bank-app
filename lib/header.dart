import 'package:flutter/material.dart';
import 'uploadJob.dart';
import 'applyJob.dart';
import 'homepage.dart';
import 'contact.dart';
import 'profile.dart' as profile;

class HeaderPage extends StatelessWidget {
  const HeaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(child: Column(children: [JobTopBar()])),
    );
  }
}

// -------------------------------------------------------
// TOP BAR
// -------------------------------------------------------
class JobTopBar extends StatelessWidget {
  final String? title;
  const JobTopBar({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ---------------- Logo ----------------
                  Container(
                    height: 65,
                    width: 65,
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Image.asset("assets/logo2.png", fit: BoxFit.contain),
                  ),

                  const Spacer(),

                  // ------------- Navigation + Button (Centered Column) -------------
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // Content-ai horizontal-ah center seiyum
                    children: [
                      // -------- Navigation Row (JOBS, CV, Profile) --------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildNavLink(context, "JOBS", const HomePage()),
                          const SizedBox(width: 20),
                          _buildNavLink(context, "CV", const ApplyJobPage()),
                          const SizedBox(width: 20),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const profile.ProfilePage(),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // -------- Upload Job + Contact --------
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildActionButton(
                            context,
                            "Upload Job",
                            const UploadJobPage(
                              companyId: "0",
                              companyName: "",
                              phoneNumber: "",
                              fromCompany: false,
                            ),
                          ),
                          _buildActionButton(
                            context,
                            "Contact Us",
                            const ContactPage(),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Ithu Column-ai right side thallamal center-il vaikka help seiyum
                  const Spacer(),
                ],
              ),
            ),

            // -------- Optional Title --------
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper Methods (Same as before but with slightly adjusted sizes for better look)
  Widget _buildNavLink(BuildContext context, String text, Widget page) {
    return InkWell(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => page),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      ),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFC1CCFA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
