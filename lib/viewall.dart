import 'package:flutter/material.dart';
import 'cvpage.dart';

class ViewAllPage extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> cvList;

  const ViewAllPage({super.key, required this.category, required this.cvList});

  String formatPhone(String phone) {
    if (phone.startsWith("0")) return "+94${phone.substring(1)}";
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF130d5a),
        title: Text(
          "$category - All CVs",
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: cvList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            final cv = cvList[index];

            // Safe phone formatting
            final String formattedPhone = cv["phone"] != null
                ? formatPhone(cv["phone"].toString())
                : "";

            // Use backend-provided URL or default avatar
            final String imageUrl =
                (cv["image"] != null && cv["image"].toString().isNotEmpty)
                ? cv["image"].toString()
                : "https://thedevfriends.com/job/uploads/cv_img/default_avatar.png";

            // Use backend-provided PDF URL
            final String pdfUrl =
                (cv["cv_file"] != null && cv["cv_file"].toString().isNotEmpty)
                ? cv["cv_file"].toString()
                : "https://thedevfriends.com/job/uploads/cv/default_cv.pdf";

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CVPage(
                      pdfUrl: pdfUrl,
                      phone: formattedPhone.replaceAll("+94", ""),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 255, 255, 255),
                      Color.fromARGB(255, 219, 225, 250),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(12),
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
                      backgroundImage: NetworkImage(imageUrl),
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cv["name"] ?? "",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF130d5a),
                      ),
                    ),
                    Text(
                      cv["location"] != null ? cv["location"].toString() : "",
                      style: const TextStyle(fontSize: 9),
                    ),
                    Text(formattedPhone, style: const TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
