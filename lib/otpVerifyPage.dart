import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_purpose.dart';
import 'dart:io';
import 'userDetails.dart';
import 'companyDetails.dart';
import 'ViewAllCVPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

class OtpVerifyPage extends StatefulWidget {
  final String verificationId;
  final String phone;
  final OtpPurpose purpose;

  const OtpVerifyPage({
    super.key,
    required this.verificationId,
    required this.phone,
    required this.purpose,
  });

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final TextEditingController otpController = TextEditingController();
  bool loading = false;
  int secondsRemaining = 60;
  Timer? timer;
  bool canResend = false;
  late String _currentVerificationId;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    startTimer();

    otpController.addListener(() {
      if (otpController.text.length == 6 && !loading) {
        verifyOTP();
      }
    });
  }

  void startTimer() {
    timer?.cancel();
    setState(() {
      secondsRemaining = 60;
      canResend = false;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining == 0) {
        t.cancel();
        setState(() => canResend = true);
      } else {
        setState(() => secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  // --- OTP சரிபார்க்கும் முறை ---
  Future<void> verifyOTP() async {
    if (otpController.text.trim().length != 6) return;

    setState(() => loading = true);

    try {
      // 1. Firebase Verification
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
        smsCode: otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // 2. Local-aa Login Session-ai Save pannunga
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_phone', widget.phone);

      // 3. Backend-la Device ID-ai Update pannunga
      await updateDeviceInBackend(widget.phone);

      if (!mounted) return;
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone Verified Successfully!")),
      );

      goNextPage();
    } catch (e) {
      setState(() => loading = false);
    }
  }

  // --- Backend Update Function ---
  Future<void> updateDeviceInBackend(String phone) async {
    try {
      String deviceId = "";
      var deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        var androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else {
        var iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? "unknown";
      }

      String dbPhone = phone.startsWith("94")
          ? "0${phone.substring(2)}"
          : phone;

      await http.post(
        Uri.parse("https://thedevfriends.com/job/api/login_check.php"),
        body: {"phone": dbPhone, "device_id": deviceId},
      );
    } catch (e) {
      debugPrint("Backend update error: $e");
    }
  }

  // --- OTP மீண்டும் அனுப்பும் முறை ---
  Future<void> resendOtp() async {
    if (!canResend) return;

    setState(() => loading = true);

    String formattedPhone = widget.phone.startsWith('94')
        ? "+${widget.phone}"
        : "+94${widget.phone}";

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Verification Failed")),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          loading = false;
          _currentVerificationId = verificationId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP resent successfully")),
        );
        startTimer();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _currentVerificationId = verificationId;
      },
    );
  }

  // --- அடுத்த பக்கத்திற்குச் செல்லுதல் ---
  void goNextPage() {
    Widget nextPage;
    switch (widget.purpose) {
      case OtpPurpose.userDetails:
        nextPage = UserDetailsPage(phone: widget.phone);
        break;
      case OtpPurpose.companyDetails:
        nextPage = CompanyDetailsPage(phone: widget.phone);
        break;
      case OtpPurpose.viewCv:
        nextPage = AllViewCVPage(companyPhone: widget.phone);
        break;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Verify Phone",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Enter the 6-digit code sent to +94 ${widget.phone}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // --- Countdown Timer UI ---
            Center(
              child: Column(
                children: [
                  Text(
                    "00:${secondsRemaining.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: secondsRemaining < 10 ? Colors.red : Colors.blue,
                    ),
                  ),
                  const Text(
                    "Remaining time",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: !loading,
              decoration: InputDecoration(
                hintText: "000000",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: "",
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25259A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: loading ? null : verifyOTP,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Verify OTP",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // --- Resend Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive code? "),
                TextButton(
                  onPressed: canResend ? resendOtp : null,
                  child: Text(
                    canResend ? "Resend Now" : "Wait for countdown",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: canResend ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
