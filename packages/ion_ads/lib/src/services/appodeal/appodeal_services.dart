//ignore_for_file: constant_identifier_names
class AppodealServices {
  static const int ADJUST = 0x01; // 0b0001
  static const int APPSFLYER = 0x02; // 0b0010
  static const int FACEBOOK = 0x04; // 0b0100
  static const int FIREBASE = 0x08; // 0b1000

  /// For all services
  static const int ALL = ADJUST | APPSFLYER | FACEBOOK | FIREBASE;
}
