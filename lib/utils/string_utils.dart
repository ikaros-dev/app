class StringUtils {
  static String emptyHint(String? original, String hintElse) {
    if (original == null || original == '' || original.trim() == '') {
      return hintElse;
    }
    return original;
  }
}
