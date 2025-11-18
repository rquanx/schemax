/// 循环任务管理器，实现类似 JavaScript 中递归 setTimeout 的效果
class LoopManager {
  // 循环状态控制
  bool _isRunning = false;

  // 任务执行间隔
  final Duration interval;

  // 要执行的任务
  final Function task;

  // 构造函数，需要传入任务和时间间隔
  LoopManager({required this.task, required this.interval});

  // 递归执行的核心方法
  Future<void> _run() async {
    if (!_isRunning) return;

    // 执行任务
    task();

    // 延迟后继续执行
    await Future.delayed(interval);
    _run();
  }

  // 启动循环
  void start() {
    if (!_isRunning) {
      _isRunning = true;
      _run();
    }
  }

  // 停止循环
  void stop() {
    _isRunning = false;
  }

  // 检查是否正在运行
  bool get isRunning => _isRunning;
}

double? toDouble(dynamic value) {
  return value is int
      ? value * 1.0
      : value is double
      ? value
      : value is String
      ? double.parse(value)
      : null;
}
