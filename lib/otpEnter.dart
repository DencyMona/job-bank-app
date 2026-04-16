import 'package:flutter/material.dart';
import 'dart:async';
import 'otp_purpose.dart';
import 'ViewAllCVPage.dart';
import 'userDetails.dart';
import 'dart:io';
import 'companyDetails.dart';
import 'otp_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class CodePage extends StatefulWidget {
  final String phone;
  final String otp;
  final OtpPurpose purpose;
  final String deviceId;

  const CodePage({
    super.key,
    required this.phone,
    required this.otp,
    required this.purpose,
    required this.deviceId,
  });

  @override
  State<CodePage> createState() => _CodePageState();
}

class _CodePageState extends State<CodePage> {
  TextEditingController otpController = TextEditingController();
  bool loading = false;

  // Timer variables
  late String currentOtp;
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    currentOtp = widget.otp;
    startTimer();
  }

  void startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _timer?.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  // --- DEVICE ID EDUKKUM FUNCTION ---
  Future<String> getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      var iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "unknown";
    }
    return "unknown";
  }

  // --- BACKEND-LA DEVICE ID UPDATE PANNUM FUNCTION ---
  Future<void> updateDeviceID() async {
    String dbPhone = widget.phone;

    // Normalize phone for backend
    if (dbPhone.startsWith("94")) {
      dbPhone = "0${dbPhone.substring(2)}";
    }

    String role;
    switch (widget.purpose) {
      case OtpPurpose.userDetails:
        role = "user";
        break;
      case OtpPurpose.companyDetails:
        role = "company";
        break;
      case OtpPurpose.viewCv:
        role = "recruiter";
        break;
    }

    try {
      await http.post(
        Uri.parse("https://123.231.101.232/job/api/login_check.php"),
        body: {
          "action": "update",
          "phone": dbPhone,
          "device_id": widget.deviceId,
          "role": role,
        },
      );
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  // Resend OTP logic
  void resendOtp() async {
    setState(() => loading = true);

    String newOtp = OTPService.generateOtp();
    bool sent = await OTPService.sendOtp(widget.phone, newOtp);

    setState(() => loading = false);

    if (sent) {
      currentOtp = newOtp;
      startTimer();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("OTP Resent Successfully!")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to resend OTP")));
    }
  }

  void verifyOtp() async {
    String enteredOtp = otpController.text.trim();

    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid 6-digit OTP")));
      return;
    }

    setState(() => loading = true);

    if (enteredOtp == currentOtp) {
      try {
        // 1. Save login session according to purpose
        SharedPreferences prefs = await SharedPreferences.getInstance();
        switch (widget.purpose) {
          case OtpPurpose.userDetails:
            await prefs.setBool('is_user_logged_in', true);
            await prefs.setString('user_phone', widget.phone);
            break;
          case OtpPurpose.companyDetails:
            await prefs.setBool('is_company_logged_in', true);
            await prefs.setString('company_phone', widget.phone);
            break;
          case OtpPurpose.viewCv:
            await prefs.setBool('is_recruiter_logged_in', true);
            await prefs.setString('recruiter_phone', widget.phone);
            break;
        }

        // 2. Register device in backend
        await updateDeviceID();

        setState(() => loading = false);
        goNextPage();
      } catch (e) {
        setState(() => loading = false);
        debugPrint("Error during session save: $e");
      }
    } else {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid OTP. Try again.")));
    }
  }

  void goNextPage() {
    switch (widget.purpose) {
      case OtpPurpose.userDetails:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetailsPage(phone: widget.phone),
          ),
          (route) => false,
        );
        break;
      case OtpPurpose.companyDetails:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => CompanyDetailsPage(phone: widget.phone),
          ),
          (route) => false,
        );
        break;
      case OtpPurpose.viewCv:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => AllViewCVPage(companyPhone: widget.phone),
          ),
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Enter OTP"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Image.asset("assets/code.png", height: 160)),
              const SizedBox(height: 25),
              Text(
                "OTP sent to ${widget.phone}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Check your SMS messages for the 6-digit code.",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: otpController,
                maxLength: 6,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Enter OTP",
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
              ),
              const SizedBox(height: 10),

              // Countdown & Resend Button UI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _canResend
                      ? TextButton(
                          onPressed: loading ? null : resendOtp,
                          child: const Text(
                            "Resend OTP",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        )
                      : Text(
                          "Resend in $_secondsRemaining s",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ],
              ),

              const SizedBox(height: 20),

              // Verify Button
              SizedBox(
                height: 55,
                width: double.infinity,
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
                    onPressed: loading ? null : verifyOtp,
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
                            "Verify OTP",
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
