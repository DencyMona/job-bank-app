import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'otp_service.dart';
import 'otpEnter.dart';
import 'otp_purpose.dart';
import 'homepage.dart';
import 'userDetails.dart';
import 'companyDetails.dart';
import 'ViewAllCVPage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NumberPage extends StatefulWidget {
  final OtpPurpose purpose;

  const NumberPage({super.key, required this.purpose});

  @override
  State<NumberPage> createState() => _NumberPageState();
}

class _NumberPageState extends State<NumberPage> {
  TextEditingController phoneController = TextEditingController();
  bool loading = false;

  // --- DEVICE ID FUNCTION ---
  Future<String> getUniqueId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      var iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "unknown_ios";
    }
    return "unknown_device";
  }

  // --- SAVE LOGIN SESSION ---
  Future<void> saveSession(String phone) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    switch (widget.purpose) {
      case OtpPurpose.userDetails:
        await prefs.setBool("is_user_logged_in", true);
        await prefs.setString("user_phone", phone);
        break;
      case OtpPurpose.companyDetails:
        await prefs.setBool("is_company_logged_in", true);
        await prefs.setString("company_phone", phone);
        break;
      case OtpPurpose.viewCv:
        await prefs.setBool("is_recruiter_logged_in", true);
        await prefs.setString("recruiter_phone", phone);
        break;
    }
  }

  // --- SEND OTP / DIRECT LOGIN LOGIC ---
  void sendOtp() async {
    String phone = phoneController.text.trim();
    if (phone.length != 9) {
      showError("Enter valid 9 digit number");
      return;
    }

    String fullPhone = "94$phone";
    String dbPhone = "0$phone";
    String deviceId = await getUniqueId();

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("https://thedevfriends.com/job/api/login_check.php"),
        body: {"phone": dbPhone, "device_id": deviceId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == "direct_login" && data["device_match"] == true) {
          await saveSession(fullPhone);
          setState(() => loading = false);

          if (!mounted) return;

          Widget nextPage;
          switch (widget.purpose) {
            case OtpPurpose.userDetails:
              nextPage = UserDetailsPage(phone: fullPhone);
              break;
            case OtpPurpose.companyDetails:
              nextPage = CompanyDetailsPage(phone: fullPhone);
              break;
            case OtpPurpose.viewCv:
              nextPage = AllViewCVPage(companyPhone: fullPhone);
              break;
            default:
              nextPage = const HomePage();
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => nextPage),
          );
          return;
        }

        // --- NEW DEVICE / OTP FLOW ---
        String otp = OTPService.generateOtp();
        bool sent = await OTPService.sendOtp(fullPhone, otp);

        if (!mounted) return;
        setState(() => loading = false);

        if (sent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CodePage(
                phone: fullPhone,
                otp: otp,
                purpose: widget.purpose,
                deviceId: deviceId,
              ),
            ),
          );
        } else {
          showError("OTP sending failed");
        }
      }
    } catch (e) {
      setState(() => loading = false);
      showError("Connection Error: $e");
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Your Phone"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Image.asset("assets/number.png", height: 160)),
              const SizedBox(height: 25),
              const Text(
                "Enter your mobile number",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "We will send an OTP to verify your identity.",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.number,
                maxLength: 9,
                decoration: const InputDecoration(
                  prefixText: "+94 ",
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFFFFF),
                        Color.fromARGB(255, 193, 204, 250),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: loading ? null : sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Color.fromARGB(255, 37, 37, 154),
                          )
                        : const Text(
                            "Send OTP",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
