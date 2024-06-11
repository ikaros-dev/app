class UrlUtils {
  static String getCoverUrl(String base, String url){
    if (url.startsWith("http")) return url;
    if (!url.startsWith('/')) url = '/$url';
    return base + url;
  }
}