class AccessUrlCondition {
  /// 条件名称，例如 "quality"
  final String name;

  /// 条件类型，例如 "select"
  final String type;

  /// 显示标签，例如 "清晰度"
  final String label;

  /// 是否必填
  final bool required;

  /// 默认值
  final String defaultValue;

  /// 描述
  final String description;

  /// 可选值列表，例如 ["original", "1080p", "720p"]
  final List<String> options;

  AccessUrlCondition({
    required this.name,
    required this.type,
    required this.label,
    required this.required,
    required this.defaultValue,
    required this.description,
    required this.options,
  });

  factory AccessUrlCondition.fromJson(Map<String, dynamic> json) {
    return AccessUrlCondition(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      required: json['required'] as bool? ?? false,
      defaultValue: json['defaultValue'] as String? ?? '',
      description: json['description'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// 文件流（原始流）标识常量
const String qualityFileStream = "ikaros_filestream";

/// 获取清晰度优先级（数字越小优先级越高）
int getQualityPriority(String quality) {
  switch (quality.toLowerCase()) {
    case 'original':
      return 0;
    case '4k':
      return 1;
    case '1080p':
      return 2;
    case '720p':
      return 3;
    case '480p':
      return 4;
    case '360p':
      return 5;
    default:
      return 9;
  }
}

/// 从条件列表中选出最优清晰度（排除文件流和原画）
/// 返回清晰度名称，如果没有可选的非原画选项则返回null
String? pickBestQuality(List<AccessUrlCondition> conditions) {
  var qualityCondition = conditions
      .where((c) => c.name.toLowerCase() == "quality")
      .firstOrNull;
  if (qualityCondition == null || qualityCondition.options.isEmpty) return null;
  var sorted = qualityCondition.options
      .where((q) => q.isNotEmpty && q != "original")
      .toList();
  if (sorted.isEmpty) return null;
  sorted.sort((a, b) => getQualityPriority(a).compareTo(getQualityPriority(b)));
  return sorted.first;
}

/// 根据清晰度条件选项获取可读的显示标签
String getQualityLabel(String quality) {
  switch (quality.toLowerCase()) {
    case 'original':
      return '原画';
    case '4k':
      return '4K';
    case '1080p':
      return '1080P';
    case '720p':
      return '720P';
    case '480p':
      return '480P';
    case '360p':
      return '360P';
    case qualityFileStream:
      return '文件流';
    default:
      return quality;
  }
}
