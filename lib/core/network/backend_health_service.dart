import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/env.dart';

enum BackendStatus {
  unknown,
  checking,
  online,
  unavailable,
}

class BackendHealthService {
  BackendHealthService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  Future<bool> check() async {
    try {
      final response = await _client
          .get(Env.apiUri('/health'))
          .timeout(const Duration(seconds: 75));

      if (response.statusCode != 200) return false;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return false;
      return decoded['status'] == 'healthy' || decoded['status'] == 'ok';
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
