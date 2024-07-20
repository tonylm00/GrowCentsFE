import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/mifid_result.dart';

class MifidProvider with ChangeNotifier {
  final String url = 'http://10.0.2.2:5000/mifid/execute';
  MifidResult? _result;

  MifidResult? get result => _result;

  Future<void> executeMifid(Map<String, int> answers) async {
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode(answers);

    final response = await http.post(Uri.parse(url), headers: headers, body: body);
    final responsePayload = json.decode(response.body);

    _result = MifidResult(
      riskProfile: responsePayload[0],
      assetAllocation: responsePayload[1],
    );

    notifyListeners();
  }
}
