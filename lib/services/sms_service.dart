import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../database/database_helper.dart';
import 'notification_service.dart';

// Top-level function for background execution - Stubbed
@pragma('vm:entry-point')
void onBackgroundMessage(dynamic message) async {
  debugPrint("SMS Service Stub: Background message received");
}

class SmsService {
  static final SmsService instance = SmsService();

  Future<void> init() async {
    debugPrint("SMS Service Stub: Listener initialized (Telephony disabled)");
  }

  Future<void> initSmsListener() async {
    debugPrint("SMS Service Stub: Listener initialized (Telephony disabled)");
  }

  void processSms(dynamic message) {
    debugPrint("SMS Service Stub: Processing SMS (Telephony disabled)");
  }
}
