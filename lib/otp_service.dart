import 'package:http/http.dart' as http;

class OTPService {
  static const String apiKey = "atjjlVnKTeCK9LYMP0rj"; // your API Key
  static const String userId = "31149"; // your User ID
  static const String senderId = "NotifyDEMO"; // trial sender

  static Future<bool> sendOtp(String phoneNumber, String otp) async {
    final url = Uri.parse("https://app.notify.lk/api/v1/send");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "user_id": userId,
        "api_key": apiKey,
        "sender_id": senderId,
        "to": phoneNumber,
        "message": "Your OTP is: $otp",
      },
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    return response.statusCode == 200;
  }

  static String generateOtp() {
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
        .toString()
        .substring(0, 6);
  }
}
