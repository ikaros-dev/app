/// 登录结果
class LoginResult {
  /// 是否登录成功
  final bool success;

  /// 是否需要TOTP二步验证
  final bool totpRequired;

  /// TOTP临时令牌（在totpRequired=true时返回）
  final String? tempToken;

  /// 错误信息
  final String? message;

  LoginResult({
    required this.success,
    this.totpRequired = false,
    this.tempToken,
    this.message,
  });
}
