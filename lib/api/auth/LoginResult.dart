/// 登录结果
class LoginResult {
  /// 是否登录成功
  final bool success;

  /// 是否需要2FA验证
  final bool twoFactorRequired;

  /// 错误信息
  final String? message;

  LoginResult({
    required this.success,
    this.twoFactorRequired = false,
    this.message,
  });
}
