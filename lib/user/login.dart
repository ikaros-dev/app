import 'package:flutter/material.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
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
  bool _isObscure = true;
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
            const SizedBox(height: kToolbarHeight), // 距离顶部一个工具栏的高度
            buildTitle(), // Login
            buildTitleLine(), // 标题下面的下滑线
            const SizedBox(height: 50),
            buildBaseUrlTextField(), // 输入基础服务器URL
            const SizedBox(height: 20),
            buildUsernameTextField(), // 输入用户名
            const SizedBox(height: 20),
            buildPasswordTextField(context), // 输入密码
            const SizedBox(height: 50),
            buildLoginButton(context), // 登录按钮
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget buildTitle() {
    return const Padding(
        // 设置边距
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
        // 是否显示文字
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
                // 修改 state 内部变量, 且需要界面内容更新, 需要使用 setState()
                setState(() {
                  _isObscure = !_isObscure;
                  _eyeColor = (_isObscure
                      ? Colors.grey
                      : Theme.of(context).iconTheme.color)!;
                });
              },
            )));
  }

  Widget buildForgetPasswordText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () {
            // Navigator.pop(context);
            print("忘记密码");
          },
          child: const Text("忘记密码？",
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ),
      ),
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
      await AuthApi().login(_baseUrl, _username, _password);
      Toast.show(context, "登录成功");
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const MyApp()));
    } catch (e) {
      Toast.show(context, "登录失败 by username: $_username, password: $_password, error: $e");
    } finally {}
  }
}
