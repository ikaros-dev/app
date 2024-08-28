import 'dart:async';

class ThrottleController {
  Timer? _timer;

  void run(Function action, Duration interval) {
    if (_timer?.isActive ?? false) {
      return; // 如果Timer还在计时中，则不执行新的action
    }
    _timer = Timer(interval, () {
      action();
      _timer = null; // 计时结束后重置Timer
    });
  }

}