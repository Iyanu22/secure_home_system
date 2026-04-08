class MotionService {
  // Simply checks if the value is "1" or "true"
  static String decryptBase64Motion(String value) {
    try {
      value = value.trim();
      if (value == "1") return "true";
      if (value == "0") return "false";
      return "Invalid";
    } catch (e) {
      return "Invalid";
    }
  }
}