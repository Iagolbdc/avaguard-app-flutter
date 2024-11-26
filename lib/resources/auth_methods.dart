import 'dart:convert';

import 'package:avaguard/incident_report_page.dart';
import 'package:avaguard/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthMethods {
  static Future<void> loginUser({
    required String email,
    required String password,
    required SharedPreferences prefs,
    required Function(String) showSnackBar,
    required BuildContext context,
  }) async {
    if (email.isNotEmpty && password.isNotEmpty) {
      var body = {"email": email, "password": password};

      var response = await http.post(
        Uri.parse("https://avaguard-api.vercel.app/signIn"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse["user"] != null) {
        var myUserId = jsonResponse["user"]["userId"];

        prefs.setString('userId', myUserId);

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => IncidentReportPage(
                userId: jsonResponse["user"]["userId"],
              ),
            ),
            (Route<dynamic> route) => false);
      } else {
        final String? erro = jsonResponse["error"];
        if (erro!.isNotEmpty) {
          showSnackBar(erro);
        }
      }
    }
  }
}
