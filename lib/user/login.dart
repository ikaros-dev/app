import 'package:flutter/material.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/LoginResult.dart';
import 'package:ikaros/main.dart';
import 'package:ikaros/utils/message_utils.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<StatefulWidget> createState() {
    return LoginState();
  }
}

class LoginState extends State<LoginView> {
  final GlobalKey _formKey = GlobalKey<FormState>();
  late String _baseUrl, _username, _password;
  String _twoFactorCode = "";
  String _tempToken = "";
  bool _isObscure = true;
  bool _twoFactorRequired = false;
  Color _eyeColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: kToolbarHeight),
            buildTitle(),
            buildTitleLine(),
            const SizedBox(height: 50),
            buildBaseUrlTextField(),
            const SizedBox(height: 20),
            buildUsernameTextField(),
            const SizedBox(height: 20),
            buildPasswordTextField(context),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: Icon(
                  _twoFactorRequired ? Icons.lock : Icons.lock_open,
                  size: 16,
                ),
                label: Text(
                  _twoFactorRequired ? '关闭两步验证' : '开启两步验证',
                  style: const TextStyle(fontSize: 13),
                ),
                onPressed: () {
                  setState(() {
                    _twoFactorRequired = !_twoFactorRequired;
                  });
                },
              ),
            ),
            if (_twoFactorRequired) ...[
              buildTwoFactorCodeTextField(),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 30),
            buildLoginButton(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget buildTitle() {
    return const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'Login',
          style: TextStyle(fontSize: 42),
        ));
  }

  Widget buildTitleLine() {
    return Padding(
        padding: const EdgeInsets.only(left: 12.0, top: 4.0),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            color: Colors.black,
            width: 40,
            height: 2,
          ),
        ));
  }

  Widget buildBaseUrlTextField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: '服务器URL'),
      validator: (v) {
        if (v == null || v.isEmpty) {
          return '请输入服务器URL, 格式: http://domain:port';
        }
        return null;
      },
      onSaved: (v) => _baseUrl = v!,
    );
  }

  Widget buildUsernameTextField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: '用户名'),
      validator: (v) {
        if (v == null || v.isEmpty) {
          return '请输入用户名';
        }
        return null;
      },
      onSaved: (v) => _username = v!,
    );
  }

  Widget buildPasswordTextField(BuildContext context) {
    return TextFormField(
        obscureText: _isObscure,
        onSaved: (v) => _password = v!,
        validator: (v) {
          if (v!.isEmpty) {
            return '请输入密码';
          }
          return null;
        },
        onFieldSubmitted: (value) {
          _password = value;
          login();
        },
        decoration: InputDecoration(
            labelText: "密码",
            suffixIcon: IconButton(
              icon: Icon(
                Icons.remove_red_eye,
                color: _eyeColor,
              ),
              onPressed: () {
                setState(() {
                  _isObscure = !_isObscure;
                  _eyeColor = (_isObscure
                      ? Colors.grey
                      : Theme.of(context).iconTheme.color)!;
                });
              },
            )));
  }

  Widget buildTwoFactorCodeTextField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: '两步验证码'),
      keyboardType: TextInputType.number,
      maxLength: 6,
      validator: (v) {
        if (v == null || v.isEmpty) {
          return '请输入两步验证码';
        }
        return null;
      },
      onSaved: (v) => _twoFactorCode = v!,
    );
  }

  Widget buildLoginButton(BuildContext context) {
    return Align(
      child: SizedBox(
        height: 45,
        width: 270,
        child: ElevatedButton(
          style: ButtonStyle(
              shape: WidgetStateProperty.all(const StadiumBorder(
                  side: BorderSide(style: BorderStyle.none)))),
          onPressed: login,
          child: const Text('登录', style: TextStyle(color: Colors.blue)),
        ),
      ),
    );
  }

  void login() async {
    var state = (_formKey.currentState as FormState);
    bool result = state.validate();
    if (!result) {
      Toast.show(context, "服务地址或用户名或密码错误");
      return;
    }
    state.save();
    try {
      if (_baseUrl.endsWith("/")) {
        _baseUrl = _baseUrl.substring(0, _baseUrl.length - 1);
      }
      _username = _username.trim();
      _password = _password.trim();

      LoginResult loginResult;

      if (_tempToken.isNotEmpty && _twoFactorCode.isNotEmpty) {
        loginResult = await AuthApi().validateTotp(
            _baseUrl, _tempToken, _twoFactorCode);
      } else {
        loginResult = await AuthApi().login(
            _baseUrl, _username, _password);
      }

      if (loginResult.totpRequired) {
        setState(() {
          _twoFactorRequired = true;
          _tempToken = loginResult.tempToken ?? "";
        });
        Toast.show(context, loginResult.message ?? "需要二步验证");
        return;
      }

      if (!loginResult.success) {
        Toast.show(context, loginResult.message ?? "登录失败");
        return;
      }

      Toast.show(context, "登录成功");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const MyApp()));
    } catch (e) {
      Toast.show(context, "登录失败: $e");
    }
  }
}
