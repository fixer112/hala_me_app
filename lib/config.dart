import 'package:flutter/foundation.dart';

class AppConfig {
  static const bool release = kReleaseMode;
  static const bool HTTPS = release;

  static const DOMAIN_PATH = release ? "hala.altechtic.com" : "10.0.2.2:8000";

  static const String API_ENDPATH = "api/v1";
  static const String PUBLIC_FOLDER = "public";
  static const String PROTOCOL = HTTPS ? "https://" : "http://";
  static const String RAW_BASE_URL = "$PROTOCOL$DOMAIN_PATH";
  static const String BASE_URL = "$RAW_BASE_URL/$API_ENDPATH";

  static const String BASE_PATH = "$RAW_BASE_URL/$PUBLIC_FOLDER/";
}

class PusherConfig {
  static const String id = "1211308";
  static const String key = "7e06e8c5809f7d127162";
  static const String secret = "b9b51ee4f03ba35351c1";
  static const String cluster = "mt1";
  static const bool encrypted = true;
}
