import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: ContactPage()),
  );
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  // URL launcher function
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  // Email launcher with fallback
  Future<void> openEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'thedevfriends2017@gmail.com',
      query: 'subject=Contact from App&body=Hello Team,',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      final String gmailWeb =
          "https://mail.google.com/mail/?view=cm&fs=1&to=thedevfriends2017@gmail.com";
      await _launchURL(gmailWeb);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng officeLocation = LatLng(9.6680435, 80.015643);

    const myGradient = LinearGradient(
      colors: [
        Color.fromARGB(255, 16, 11, 74),
        Color.fromARGB(255, 63, 3, 227),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Contact Us",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: myGradient),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 1. TOP GRADIENT CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: myGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.headset_mic, color: Colors.white, size: 50),
                    SizedBox(height: 15),
                    Text(
                      "Have Questions?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "We are here to help you. Reach out to our team anytime.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 2. MAIN CONTACT INFO CARD
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildContactItem(
                      Icons.email,
                      "Email",
                      "thedevfriends2017@gmail.com",
                      "",
                    ),
                    _buildContactItem(
                      Icons.phone,
                      "Phone",
                      "+94 78 727 4513",
                      "tel:+94787274513",
                    ),
                    _buildContactItem(
                      Icons.location_on,
                      "Address",
                      "220 Stanley Rd, Jaffna",
                      "https://www.google.com/maps/search/?api=1&query=9.6680435,80.015643",
                    ),
                    _buildContactItem(
                      Icons.language,
                      "Website",
                      "www.thedevfriends.com",
                      "https://www.thedevfriends.com",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 3. LIVE MAP SECTION
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "  Visit Our Office",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: officeLocation,
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: 'com.thedevfriends.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: officeLocation,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 4. APPLICANT SUPPORT CARD
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.support_agent,
                            color: Color.fromARGB(255, 16, 11, 74),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "TDF Support Team",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 16, 11, 74),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            63,
                            3,
                            227,
                          ).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromARGB(
                              255,
                              63,
                              3,
                              227,
                            ).withOpacity(0.1),
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "N. Piratheep",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color.fromARGB(255, 16, 11, 74),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Office - 0762709414",
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              "Mobile - 0787274513",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 5. FOLLOW US SECTION (WRAPPED IN CARD AS REQUESTED)
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Icon(
                              Icons.share,
                              size: 20,
                              color: Color.fromARGB(255, 16, 11, 74),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Follow Us",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color.fromARGB(255, 16, 11, 74),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 1.6,
                        children: [
                          _buildSocialCard(
                            "WhatsApp",
                            FontAwesomeIcons.whatsapp,
                            Colors.green,
                            "https://wa.me/94787274513",
                          ),
                          _buildSocialCard(
                            "Facebook",
                            FontAwesomeIcons.facebook,
                            Colors.blue[800]!,
                            "https://www.facebook.com/share/19wHBeNUgz/",
                          ),
                          _buildSocialCard(
                            "Instagram",
                            FontAwesomeIcons.instagram,
                            Colors.pink,
                            "https://www.instagram.com/tdfjobbank",
                          ),
                          _buildSocialCard(
                            "LinkedIn",
                            FontAwesomeIcons.linkedin,
                            Colors.blue[700]!,
                            "https://www.linkedin.com/company/tdftech/",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 6. OFFICE HOURS SECTION
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.access_time_filled_rounded,
                            color: Color.fromARGB(255, 16, 11, 74),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Service Hours",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 16, 11, 74),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Monday - Saturday",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            "9.30 AM - 8.30 PM",
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.amber[800],
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                "We typically respond to emails within 24 hours.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget for Contact Items
  Widget _buildContactItem(
    IconData icon,
    String title,
    String subtitle,
    String url,
  ) {
    return ListTile(
      onTap: title == "Email" ? openEmail : () => _launchURL(url),
      leading: CircleAvatar(
        backgroundColor: const Color.fromARGB(255, 63, 3, 227).withOpacity(0.1),
        child: Icon(
          icon,
          color: const Color.fromARGB(255, 16, 11, 74),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 12,
        color: Colors.grey,
      ),
    );
  }

  // Helper Widget for Social Media Cards
  Widget _buildSocialCard(
    String title,
    IconData icon,
    Color color,
    String url,
  ) {
    return InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color.fromARGB(255, 194, 193, 193)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color.fromARGB(255, 16, 11, 74),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
