import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../services/timer_service.dart';
import '../services/task_service.dart';
import '../services/theme_service.dart';
import 'pomodoro_tracker_screen.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _taskService.getAllTasks();
      setState(() => _tasks = tasks.where((t) => !t.checked).toList());
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Color _getModeColor(TimerMode mode) {
    switch (mode) {
      case TimerMode.pomodoro:
        return Colors.deepPurple;
      case TimerMode.shortBreak:
        return Colors.teal;
      case TimerMode.longBreak:
        return Colors.blue;
    }
  }

  String _getModeLabel(TimerMode mode) {
    switch (mode) {
      case TimerMode.pomodoro:
        return 'Pomodoro';
      case TimerMode.shortBreak:
        return 'Short Break';
      case TimerMode.longBreak:
        return 'Long Break';
    }
  }

  void _showSetTimeDialog(TimerService timer) {
    final mode = timer.mode;
    final color = _getModeColor(mode);
    final hourController = TextEditingController(
        text: (timer.defaultDurations[mode]! ~/ 3600).toString());
    final minController = TextEditingController(
        text: ((timer.defaultDurations[mode]! % 3600) ~/ 60).toString());
    final secController = TextEditingController(
        text: (timer.defaultDurations[mode]! % 60).toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Set Waktu — ${_getModeLabel(mode)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input jam:menit:detik
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hourController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jam',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(':',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: minController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Menit',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(':',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: secController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Detik',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tombol tambah ke preset
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Simpan sebagai Preset'),
                    onPressed: () {
                      final h = int.tryParse(hourController.text) ?? 0;
                      final m = int.tryParse(minController.text) ?? 0;
                      final s = int.tryParse(secController.text) ?? 0;
                      final total = h * 3600 + m * 60 + s;
                      if (total > 0) {
                        timer.addPreset(mode, total);
                        setDialogState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Preset ${timer.formatDuration(total)} ditambahkan!'),
                          ),
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Daftar preset
                const Text('Preset Tersimpan',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (timer.presets[mode] ?? []).map((seconds) {
                    final isDefault =
                        seconds == timer.defaultDurations[mode];
                    return InputChip(
                      label: Text(timer.formatDuration(seconds)),
                      backgroundColor:
                          isDefault ? color.withValues(alpha: 0.15) : null,
                      side: BorderSide(
                          color: isDefault ? color : Colors.grey.shade300),
                      labelStyle: TextStyle(
                        color: isDefault ? color : null,
                        fontWeight: isDefault ? FontWeight.bold : null,
                      ),
                      onPressed: () {
                        final h = seconds ~/ 3600;
                        final m = (seconds % 3600) ~/ 60;
                        final s = seconds % 60;
                        hourController.text = h.toString();
                        minController.text = m.toString();
                        secController.text = s.toString();
                      },
                      deleteIcon: isDefault
                          ? null
                          : const Icon(Icons.close, size: 16),
                      onDeleted: isDefault
                          ? null
                          : () {
                              timer.removePreset(mode, seconds);
                              setDialogState(() {});
                            },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: color),
              onPressed: () {
                final h = int.tryParse(hourController.text) ?? 0;
                final m = int.tryParse(minController.text) ?? 0;
                final s = int.tryParse(secController.text) ?? 0;
                final total = h * 3600 + m * 60 + s;
                if (total > 0) {
                  timer.setDuration(total);
                  Navigator.pop(context);
                }
              },
              child: const Text('Set Waktu',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFinishedDialog(TimerService timer) {
    final isPomodoro = timer.mode == TimerMode.pomodoro;
    final cycleCount = timer.cycleCount;

    // Tentukan break berikutnya berdasarkan siklus
    final nextIsLongBreak = isPomodoro && cycleCount % 2 == 1;
    final nextBreakLabel = nextIsLongBreak ? 'Long Break' : 'Short Break';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isPomodoro ? '🎉 Pomodoro Selesai!' : '✅ Break Selesai!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isPomodoro
                ? 'Kerja keras! Selanjutnya: $nextBreakLabel'
                : 'Istirahat selesai. Siap fokus lagi?'),
            if (isPomodoro) ...[
              const SizedBox(height: 8),
              // Indikator siklus
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (i) {
                  final done = i < (timer.pomodoroCount % 2 == 0 ? 2 : timer.pomodoroCount % 2);
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: done ? Colors.deepPurple : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              Text(
                'Pomodoro ${timer.pomodoroCount} — siklus ke ${(timer.pomodoroCount / 2).ceil()}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (isPomodoro && timer.selectedTaskId != null) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Selesaikan Task?'),
                    content: Text('Tandai "${timer.selectedTaskTitle}" sebagai selesai?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Tidak'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Ya, Selesai'),
                      ),
                    ],
                  ),
                );
                // ← PERUBAHAN: keduanya tetap quit
                if (confirm == null) return; // user dismiss dialog → tidak melakukan apa-apa
                if (confirm == true) {
                  await timer.quit(completeTask: true);  // Ya → quit + centang task
                  if (mounted) _loadTasks();
                } else {
                  // Tidak → timer tetap jalan, tidak quit, tidak centang
                  return;
                }
                if (mounted) _loadTasks();
              } else {
                await timer.quit();
                if (mounted) _loadTasks();
              }
            },
            child: const Text('Quit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerService>(
      builder: (context, timer, _) {
        final color = _getModeColor(timer.mode);

        // Tampilkan dialog selesai
        if (timer.state == TimerState.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && timer.state == TimerState.finished) {
              _showFinishedDialog(timer);
              timer.reset();
            }
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pomodoro Timer'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            actions: [
              // Indikator timer berjalan (saat di screen lain)
              if (timer.state == TimerState.running)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Chip(
                    label: Text(
                      timer.formattedTime,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: color.withValues(alpha: 0.1),
                    side: BorderSide(color: color),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.bar_chart_outlined),
                tooltip: 'Pomodoro Tracker',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PomodoroTrackerScreen(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.timer_outlined),
                tooltip: 'Set Waktu',
                onPressed: timer.state == TimerState.idle
                    ? () => _showSetTimeDialog(timer)
                    : null,
              ),  
              Consumer<ThemeService>(
                builder: (context, themeService, _) => IconButton(
                  icon: Icon(themeService.isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: themeService.toggle,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Mode selector
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: TimerMode.values.map((mode) {
                      final selected = timer.mode == mode;
                      final modeColor = _getModeColor(mode);
                      return Expanded(
                        child: GestureDetector(
                          onTap: timer.state == TimerState.idle ||
                                  timer.state == TimerState.paused
                              ? () => timer.setMode(mode)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? modeColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getModeLabel(mode),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // Auto mode toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Mode Manual',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                    Switch(
                      value: timer.isAutoMode,
                      activeThumbColor: color,
                      onChanged: (val) => timer.setAutoMode(val),
                    ),
                    Text('Mode Otomatis',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),

                const SizedBox(height: 24),

                // Timer circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CircularProgressIndicator(
                        value: timer.progress,
                        strokeWidth: 12,
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timer.formattedTime,
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: color,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          _getModeLabel(timer.mode),
                          style: TextStyle(
                              fontSize: 14,
                              color: color.withValues(alpha: 0.7)),
                        ),
                        if (timer.selectedTaskTitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              timer.selectedTaskTitle!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Pomodoro count
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${timer.pomodoroCount} pomodoro selesai',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Task selector
                if (timer.mode == TimerMode.pomodoro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        hint: const Text('Pilih task (opsional)'),
                        value: timer.selectedTaskId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Tanpa task'),
                          ),
                          ..._tasks.map((task) => DropdownMenuItem(
                                value: task.id,
                                child: Text(task.title,
                                    overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: timer.state == TimerState.idle
                            ? (id) {
                                final task = id == null
                                    ? null
                                    : _tasks.firstWhere((t) => t.id == id);
                                timer.setTask(id, task?.title);
                              }
                            : null,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Reset
                    IconButton(
                      onPressed: timer.state != TimerState.idle
                          ? timer.reset
                          : null,
                      icon: const Icon(Icons.refresh),
                      iconSize: 32,
                      tooltip: 'Reset',
                    ),
                    const SizedBox(width: 8),

                    // Quit
                    if (timer.sessionActive)
                      IconButton(
                        onPressed: () async {
                          if (timer.selectedTaskId != null) {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Quit Pomodoro?'),
                                content: Text('Tandai "${timer.selectedTaskTitle}" sebagai selesai?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Tidak'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Ya, Selesai'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await timer.quit(completeTask: true);
                              if (mounted) _loadTasks();
                            }
                            // confirm == false atau null → tidak melakukan apa-apa, timer tetap jalan
                          } else {
                            await timer.quit();
                            if (mounted) _loadTasks();
                          }
                        },
                        icon: const Icon(Icons.stop_circle_outlined,
                            color: Colors.red),
                        iconSize: 32,
                        tooltip: 'Quit',
                      ),

                    const SizedBox(width: 8),

                    // Play/Pause
                    ElevatedButton(
                      onPressed: timer.state == TimerState.running
                          ? timer.pause
                          : timer.start,
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
                          Icon(
                            timer.state == TimerState.running
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timer.state == TimerState.running
                                ? 'Pause'
                                : 'Mulai',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Next
                    IconButton(
                      onPressed: () => timer.next(),
                      icon: const Icon(Icons.skip_next),
                      iconSize: 32,
                      tooltip: 'Next',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Set time button
                OutlinedButton.icon(
                  onPressed: timer.state == TimerState.idle
                      ? () => _showSetTimeDialog(timer)
                      : null,
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Atur Waktu & Preset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                  ),
                ),

                const SizedBox(height: 12),

                // Info tips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tips',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: color)),
                      const SizedBox(height: 6),
                      Text(
                        '• Timer tetap berjalan saat pindah screen\n'
                        '• Mode Otomatis: timer langsung lanjut ke break\n'
                        '• Mode Manual: pilih sendiri setelah timer selesai\n'
                        '• Jika pilih task & klik Quit/Selesai, task otomatis tercentang',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}