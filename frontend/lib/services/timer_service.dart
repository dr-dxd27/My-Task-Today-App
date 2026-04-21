import 'dart:async';
import 'package:flutter/material.dart';
import 'task_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

enum TimerMode { pomodoro, shortBreak, longBreak }
enum TimerState { idle, running, paused, finished }

class TimerService extends ChangeNotifier {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  final TaskService _taskService = TaskService();

  // Mode & state
  TimerMode _mode = TimerMode.pomodoro;
  TimerState _state = TimerState.idle;
  bool _isAutoMode = false;
  bool _sessionActive = false;

  // Durasi default (dalam detik)
  final Map<TimerMode, int> _defaultDurations = {
    TimerMode.pomodoro: 25 * 60,
    TimerMode.shortBreak: 5 * 60,
    TimerMode.longBreak: 15 * 60,
  };

  // Preset custom per mode
  final Map<TimerMode, List<int>> _presets = {
    TimerMode.pomodoro: [25 * 60, 30 * 60, 45 * 60],
    TimerMode.shortBreak: [5 * 60, 10 * 60],
    TimerMode.longBreak: [15 * 60, 20 * 60, 30 * 60],
  };

  int _remainingSeconds = 25 * 60;
  int _totalSeconds = 25 * 60;
  Timer? _timer;
  int _pomodoroCount = 0;
  int? _currentSessionId;

  // Task terpilih
  int? _selectedTaskId;
  String? _selectedTaskTitle;

  // Getters
  TimerMode get mode => _mode;
  TimerState get state => _state;
  bool get isAutoMode => _isAutoMode;
  bool get sessionActive => _sessionActive;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  int get pomodoroCount => _pomodoroCount;
  double get progress => _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 1.0;
  int? get selectedTaskId => _selectedTaskId;
  String? get selectedTaskTitle => _selectedTaskTitle;
  Map<TimerMode, List<int>> get presets => _presets;
  Map<TimerMode, int> get defaultDurations => _defaultDurations;
  int? get currentSessionId => _currentSessionId;

  String get formattedTime {
    final min = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final sec = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  String formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void setMode(TimerMode mode) {
    _stopTimer();
    _mode = mode;
    _totalSeconds = _defaultDurations[mode]!;
    _remainingSeconds = _totalSeconds;
    _state = TimerState.idle;
    notifyListeners();
  }

  void setDuration(int seconds) {
    _stopTimer();
    _totalSeconds = seconds;
    _remainingSeconds = seconds;
    _defaultDurations[_mode] = seconds;
    _state = TimerState.idle;
    notifyListeners();
  }

  void setAutoMode(bool auto) {
    _isAutoMode = auto;
    notifyListeners();
  }

  void setTask(int? taskId, String? taskTitle) {
    _selectedTaskId = taskId;
    _selectedTaskTitle = taskTitle;
    notifyListeners();
  }

  void addPreset(TimerMode mode, int seconds) {
    if (!_presets[mode]!.contains(seconds)) {
      _presets[mode]!.add(seconds);
      _presets[mode]!.sort();
      notifyListeners();
    }
  }

  void removePreset(TimerMode mode, int seconds) {
    // Tidak bisa hapus default
    if (seconds == _defaultDurations[mode]) return;
    _presets[mode]!.remove(seconds);
    notifyListeners();
  }

  void start() {
    _checkDayReset();
    if (_state == TimerState.running) return;
    _sessionActive = true;
    _state = TimerState.running;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _onFinished();
      } else {
        _remainingSeconds--;
        notifyListeners();
      }
    });
    // Simpan sesi ke backend hanya saat mode Pomodoro
    if (_mode == TimerMode.pomodoro) {
      _startSessionToBackend();
    }
    notifyListeners();
  }

  Future<void> _startSessionToBackend() async {
    try {
      final body = {
        'durationMinutes': _totalSeconds ~/ 60,
        if (_selectedTaskId != null) 'taskId': _selectedTaskId,
      };
      final response = await http.post(
        Uri.parse('${ApiConfig.pomodoro}/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentSessionId = data['id'];
      }
    } catch (e) {
      debugPrint('Error starting session: $e');
    }
  }

  void pause() {
    _stopTimer();
    _state = TimerState.paused;
    notifyListeners();
  }

  void reset() {
    _stopTimer();
    _remainingSeconds = _totalSeconds;
    _state = TimerState.idle;
    notifyListeners();
  }

  Future<void> quit({bool completeTask = false}) async {
    _stopTimer();
    if (completeTask && _selectedTaskId != null) {
      try {
        final task = await _taskService.getTaskById(_selectedTaskId!);
        if (!task.checked) {
          await _taskService.toggleCheck(_selectedTaskId!);
        }
      } catch (e) {
        debugPrint('Error completing task: $e');
      }
    }
    // Complete session di backend
    if (_sessionActive && _currentSessionId != null) {
      await _completeSessionToBackend(_currentSessionId!);
    }
    if (_sessionActive) _pomodoroCount++;
    _sessionActive = false;
    _currentSessionId = null; // ← reset
    _remainingSeconds = _totalSeconds;
    _state = TimerState.idle;
    _selectedTaskId = null;
    _selectedTaskTitle = null;
    _cycleCount = 0;
    setMode(TimerMode.pomodoro);
    notifyListeners();
  }

  Future<void> _completeSessionToBackend(int sessionId) async {
    try {
      await http.put(
        Uri.parse('${ApiConfig.pomodoro}/$sessionId/complete'),
      );
    } catch (e) {
      debugPrint('Error completing session: $e');
    }
  }

  // Tambah variabel di dalam class TimerService
  int _cycleCount = 0; // hitungan pomodoro dalam satu siklus

  // Tambahkan setelah: int _cycleCount = 0;
  String _lastDate = '';

  String get _todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _checkDayReset() {
    final today = _todayDate;
    if (_lastDate.isNotEmpty && _lastDate != today) {
      _pomodoroCount = 0;
      _cycleCount = 0;
    }
    _lastDate = today;
  }

  int get cycleCount => _cycleCount;

  void next() {
    if (_mode == TimerMode.pomodoro) {
      _cycleCount++;
      // Genap → Long Break, Ganjil → Short Break
      if (_cycleCount % 2 == 0) {
        setMode(TimerMode.longBreak);   // pomodoro ke-2, ke-4, ke-6... → long break
      } else {
        setMode(TimerMode.shortBreak);  // pomodoro ke-1, ke-3, ke-5... → short break
      }
    } else {
      // Setelah break apapun (short maupun long) → kembali ke pomodoro
      setMode(TimerMode.pomodoro);
    }
    if (_isAutoMode) start();
    notifyListeners();
  }

  void _onFinished() {
    _stopTimer();
    _remainingSeconds = 0;
    _state = TimerState.finished;
    notifyListeners();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}