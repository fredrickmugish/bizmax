class StringUtils {
  static String interpolate(String string, Map<String, String> params) {
    String result = string;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}
