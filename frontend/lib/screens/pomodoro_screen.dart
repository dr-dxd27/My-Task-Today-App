import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/pomodoro_service.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  final TaskService _taskService = TaskService();
  final PomodoroService _pomodoroService = PomodoroService();

  List<Task> _tasks = [];
  Task? _selectedTask;
  PomodoroSession? _currentSession;

  // Timer
  Timer? _timer;
  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isFinished = false;

  // Mode: 0 = Pomodoro, 1 = Short Break, 2 = Long Break
  int _mode = 0;
  final List<String> _modeLabels = ['Pomodoro', 'Short Break', 'Long Break'];
  final List<int> _modeDurations = [25, 5, 15];
  final List<Color> _modeColors = [Colors.deepPurple, Colors.teal, Colors.blue];

  int _pomodoroCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _taskService.getAllTasks();
      setState(() => _tasks = tasks.where((t) => !t.checked).toList());
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  void _setMode(int mode) {
    _timer?.cancel();
    setState(() {
      _mode = mode;
      _totalSeconds = _modeDurations[mode] * 60;
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
      _isFinished = false;
    });
  }

  void _startTimer() async {
    if (_selectedTask == null && _mode == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih task terlebih dahulu!')),
      );
      return;
    }

    if (_mode == 0 && _selectedTask != null && !_isRunning) {
      try {
        final session = await _pomodoroService.startSession(
          _selectedTask!.id!,
          _modeDurations[_mode],
        );
        setState(() => _currentSession = session);
      } catch (e) {
        debugPrint('Error starting session: $e');
      }
    }

    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onTimerFinished();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
      _isFinished = false;
      _currentSession = null;
    });
  }

  void _onTimerFinished() async {
    setState(() {
      _isRunning = false;
      _isFinished = true;
    });

    if (_mode == 0) {
      setState(() => _pomodoroCount++);
      if (_currentSession != null) {
        try {
          await _pomodoroService.completeSession(_currentSession!.id!);
        } catch (e) {
          debugPrint('Error completing session: $e');
        }
      }
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_mode == 0 ? 'Pomodoro Selesai! 🎉' : 'Break Selesai!'),
          content: Text(_mode == 0
              ? 'Bagus! Kamu telah menyelesaikan 1 pomodoro. Saatnya istirahat!'
              : 'Istirahat selesai. Siap untuk pomodoro berikutnya?'),
          actions: [
            if (_mode == 0) ...[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _setMode(1);
                },
                child: const Text('Short Break (5 min)'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _setMode(2);
                },
                child: const Text('Long Break (15 min)'),
              ),
            ] else
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _setMode(0);
                },
                child: const Text('Mulai Pomodoro'),
              ),
          ],
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  double get _progress => _remainingSeconds / _totalSeconds;

  @override
  Widget build(BuildContext context) {
    final color = _modeColors[_mode];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Mode selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(_modeLabels[i]),
                  selected: _mode == i,
                  onSelected: (_) => _setMode(i),
                  selectedColor: _modeColors[i].withOpacity(0.2),
                ),
              )),
            ),

            const SizedBox(height: 32),

            // Timer circle
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 12,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      _modeLabels[_mode],
                      style: TextStyle(
                        fontSize: 16,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Pomodoro count
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '$_pomodoroCount Pomodoro selesai hari ini',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Task selector (hanya saat mode Pomodoro)
            if (_mode == 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Task>(
                    isExpanded: true,
                    hint: const Text('Pilih task yang dikerjakan'),
                    value: _selectedTask,
                    items: _tasks.map((task) => DropdownMenuItem(
                      value: task,
                      child: Text(task.title, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: _isRunning ? null : (task) {
                      setState(() => _selectedTask = task);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset
                IconButton(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  iconSize: 32,
                  tooltip: 'Reset',
                ),
                const SizedBox(width: 16),

                // Play/Pause
                ElevatedButton(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(140, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        _isRunning ? 'Pause' : 'Mulai',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Skip
                IconButton(
                  onPressed: _onTimerFinished,
                  icon: const Icon(Icons.skip_next),
                  iconSize: 32,
                  tooltip: 'Skip',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teknik Pomodoro',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Pilih task yang ingin dikerjakan\n'
                    '2. Set timer 25 menit dan fokus bekerja\n'
                    '3. Istirahat 5 menit setelah timer selesai\n'
                    '4. Setiap 4 pomodoro, ambil istirahat panjang 15 menit',
                    style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}