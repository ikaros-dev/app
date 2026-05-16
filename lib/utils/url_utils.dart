class UrlUtils {
  // 需要编码的特殊字符映射
  static const Map<String, String> specialChars = {
    ' ': '%20',
    '!': '%21',
    '"': '%22',
    '#': '%23',
    '\$': '%24',
    '%': '%25',
    '&': '%26',
    "'": '%27',
    '(': '%28',
    ')': '%29',
    '*': '%2A',
    '+': '%2B',
    ',': '%2C',
    '/': '%2F',
    ':': '%3A',
    ';': '%3B',
    '=': '%3D',
    '?': '%3F',
    '@': '%40',
    '[': '%5B',
    '\\': '%5C',
    ']': '%5D',
    '^': '%5E',
    '`': '%60',
    '{': '%7B',
    '|': '%7C',
    '}': '%7D',
    '~': '%7E',
  };

  static String getCoverUrl(String base, String url) {
    if (url.startsWith("http")) return url;
    if (!url.startsWith('/')) url = '/$url';
    return base + url;
  }



  /// 对路径的每个部分进行编码和特殊字符处理
  static String encodePathSegments(String url) {
    try {
      // 分离协议和主机
      RegExp urlPattern = RegExp(r'^(https?://[^/]+)(/.*)$');
      Match? match = urlPattern.firstMatch(url);

      if (match == null) return _encodeLocalPath(url);

      String baseUrl = match.group(1)!;
      String path = match.group(2)!;

      // 分离查询参数和锚点
      String query = '';
      String fragment = '';

      int queryIndex = path.indexOf('?');
      if (queryIndex != -1) {
        query = path.substring(queryIndex);
        path = path.substring(0, queryIndex);
      }

      int fragmentIndex = path.indexOf('#');
      if (fragmentIndex != -1) {
        fragment = path.substring(fragmentIndex);
        path = path.substring(0, fragmentIndex);
      }

      // 按 / 分割路径
      List<String> segments = path.split('/');

      // 对每个段进行处理
      List<String> encodedSegments = segments.map((segment) {
        if (segment.isEmpty) return segment;

        // 第一步：URL编码
        String encoded = Uri.encodeComponent(segment);

        // 第二步：特殊字符替换（如果需要）
        encoded = _replaceSpecialChars(encoded);

        return encoded;
      }).toList();

      // 重新拼接
      String encodedPath = encodedSegments.join('/');

      return baseUrl + encodedPath + query + fragment;
    } catch (e) {
      return _encodeLocalPath(url);
    }
  }

  /// 处理本地路径（没有协议的情况）
  static String _encodeLocalPath(String path) {
    List<String> segments = path.split('/');
    List<String> encodedSegments = segments.map((segment) {
      if (segment.isEmpty) return segment;
      return Uri.encodeComponent(segment);
    }).toList();
    return encodedSegments.join('/');
  }

  /// 可选：特殊字符二次替换
  static String _replaceSpecialChars(String encoded) {
    String result = encoded;
    specialChars.forEach((code, char) {
      result = result.replaceAll(code, char);
    });
    return result;
  }
}
