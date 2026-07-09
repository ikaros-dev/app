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
    default:
      return quality;
  }
}
