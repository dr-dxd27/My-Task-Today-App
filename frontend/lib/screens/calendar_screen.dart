import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../services/task_service.dart';
import '../services/habit_service.dart';
import '../services/theme_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TaskService _taskService = TaskService();
  final HabitService _habitService = HabitService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _tasksByDate = {};
  List<Task> _selectedTasks = [];
  List<Habit> _habitsThisMonth = [];
  bool _isLoading = true;

  // Urutan hari untuk cek customDays
  final List<String> _dayNames = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY',
    'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadData(_focusedDay);
  }

  Future<void> _loadData(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      final tasks =
          await _taskService.getTasksByMonth(date.year, date.month);
      final habits =
          await _habitService.getHabitsForMonth(date.year, date.month);

      final Map<DateTime, List<Task>> grouped = {};
      for (final task in tasks) {
        if (task.dueDate != null) {
          final parts = task.dueDate!.split('-');
          final day = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          grouped[day] = [...(grouped[day] ?? []), task];
        }
      }

      setState(() {
        _tasksByDate = grouped;
        _habitsThisMonth = habits;
        _isLoading = false;
        if (_selectedDay != null) {
          _selectedTasks = _getTasksForDay(_selectedDay!);
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading calendar: $e');
    }
  }

  List<Task> _getTasksForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _tasksByDate[key] ?? [];
  }

  // Cek apakah ada habit aktif pada hari tertentu
  bool _hasHabitOnDay(DateTime day) {
    if (_habitsThisMonth.isEmpty) return false;
    final dayName = _dayNames[day.weekday - 1];

    return _habitsThisMonth.any((habit) {
      // Cek startDate
      if (habit.startDate != null) {
        final parts = habit.startDate!.split('-');
        final start = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]));
        if (day.isBefore(start)) return false;
      }
      // Cek endDate
      if (habit.endDate != null) {
        final parts = habit.endDate!.split('-');
        final end = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]));
        if (day.isAfter(end)) return false;
      }
      // Cek customDays
      if (habit.durationType == 'CUSTOM') {
        return habit.customDays.contains(dayName);
      }
      return true;
    });
  }

  // Habit yang aktif pada hari yang dipilih
  List<Habit> _getHabitsForSelectedDay(DateTime day) {
    if (_habitsThisMonth.isEmpty) return [];
    final dayName = _dayNames[day.weekday - 1];

    return _habitsThisMonth.where((habit) {
      if (habit.startDate != null) {
        final parts = habit.startDate!.split('-');
        final start = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]));
        if (day.isBefore(start)) return false;
      }
      if (habit.endDate != null) {
        final parts = habit.endDate!.split('-');
        final end = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]));
        if (day.isAfter(end)) return false;
      }
      if (habit.durationType == 'CUSTOM') {
        return habit.customDays.contains(dayName);
      }
      return true;
    }).toList();
  }

  Color _getTaskColor(Task task) {
    if (task.priority == 'URGENT' && task.importance == 'IMPORTANT') {
      return Colors.red;
    } else if (task.priority == 'NOT_URGENT' &&
        task.importance == 'IMPORTANT') {
      return Colors.blue;
    } else if (task.priority == 'URGENT' &&
        task.importance == 'NOT_IMPORTANT') {
      return Colors.orange;
    }
    return const Color(0xFF795548);
  }

  String _getQuadrantLabel(Task task) {
    if (task.priority == 'URGENT' && task.importance == 'IMPORTANT') {
      return 'Do First';
    }
    if (task.priority == 'NOT_URGENT' && task.importance == 'IMPORTANT') {
      return 'Schedule';
    }
    if (task.priority == 'URGENT' && task.importance == 'NOT_IMPORTANT') {
      return 'Delegate';
    }
    return 'Eliminate';
  }

  Color _getHabitColor(String template) {
    return switch (template) {
      'DRINK_WATER'        => Colors.cyan,
      'EXERCISE'     => Colors.green,
      'MARTIAL_ARTS' => Colors.deepOrange,
      'GOOD_MORNING' => Colors.amber,
      'GOOD_NIGHT'   => Colors.indigo,
      _              => Colors.purple,
    };
  }

  String _getHabitEmoji(String template) {
    return switch (template) {
      'DRINK_WATER'        => '💧',
      'EXERCISE'     => '🏃',
      'MARTIAL_ARTS' => '🥋',
      'GOOD_MORNING' => '☀️',
      'GOOD_NIGHT'   => '🌙',
      _              => '✏️',
    };
  }

  Future<void> _toggleCheck(Task task) async {
    try {
      await _taskService.toggleCheck(task.id!);
      _loadData(_focusedDay);
    } catch (e) {
      debugPrint('Error toggling task: $e');
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _taskService.deleteTask(task.id!);
      _loadData(_focusedDay);
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  Future<void> _toggleHabitLog(Habit habit) async {
    try {
      await _habitService.toggleLog(habit.id!);
      _loadData(_focusedDay);
    } catch (e) {
      debugPrint('Error toggling habit log: $e');
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'NOT_URGENT';
    String importance = 'NOT_IMPORTANT';
    DateTime selectedDate = _selectedDay ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Task *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'URGENT', child: Text('Urgent')),
                    DropdownMenuItem(
                        value: 'NOT_URGENT', child: Text('Not Urgent')),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => priority = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: importance,
                  decoration: const InputDecoration(
                    labelText: 'Importance',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'IMPORTANT', child: Text('Important')),
                    DropdownMenuItem(
                        value: 'NOT_IMPORTANT',
                        child: Text('Not Important')),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => importance = val!),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                        ),
                      ],
                    ),
                  ),
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
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                final dueDate =
                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                final task = Task(
                  title: titleController.text,
                  description: descController.text,
                  priority: priority,
                  importance: importance,
                  dueDate: dueDate,
                );
                await _taskService.createTask(task);
                if (context.mounted) Navigator.pop(context);
                _loadData(_focusedDay);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  // Dot task per kuadran
  List<Widget> _buildTaskDots(List<Task> tasks) {
    final Map<String, Color> quadrantColors = {};
    for (final task in tasks) {
      final key = '${task.priority}_${task.importance}';
      if (!quadrantColors.containsKey(key)) {
        quadrantColors[key] = _getTaskColor(task);
      }
    }
    return quadrantColors.values.take(4).map((color) {
      return Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Habit untuk hari yang dipilih
    final selectedDayHabits = _selectedDay != null
        ? _getHabitsForSelectedDay(_selectedDay!)
        : <Habit>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(_focusedDay),
          ),
          Consumer<ThemeService>(
            builder: (context, themeService, _) => IconButton(
              icon: Icon(themeService.isDark
                  ? Icons.light_mode
                  : Icons.dark_mode),
              onPressed: themeService.toggle,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar<Task>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getTasksForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final hasTask = events.isNotEmpty;
                final hasHabit = _hasHabitOnDay(day);

                if (!hasTask && !hasHabit) return const SizedBox.shrink();

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dot task per kuadran
                      if (hasTask) ..._buildTaskDots(events),
                      // 1 dot ungu untuk habit
                      if (hasHabit)
                        Container(
                          width: 6,
                          height: 6,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(
                            color: Colors.purple,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 0,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedTasks = _getTasksForDay(selectedDay);
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadData(focusedDay);
            },
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildLegend(Colors.red, 'Do First'),
                  const SizedBox(width: 8),
                  _buildLegend(Colors.blue, 'Schedule'),
                  const SizedBox(width: 8),
                  _buildLegend(Colors.orange, 'Delegate'),
                  const SizedBox(width: 8),
                  _buildLegend(const Color(0xFF795548), 'Eliminate'),
                  const SizedBox(width: 12),
                  Container(
                      width: 1, height: 12, color: Colors.grey.shade300),
                  const SizedBox(width: 12),
                  _buildLegend(Colors.purple, '🔁 Habit'),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_selectedTasks.isEmpty && selectedDayHabits.isEmpty)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available,
                                size: 48,
                                color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada task atau habit\npada tanggal ini',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Section Habit
                          if (selectedDayHabits.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.loop,
                                    size: 18, color: Colors.purple),
                                const SizedBox(width: 6),
                                Text(
                                  'Habit (${selectedDayHabits.length})',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...selectedDayHabits
                                .map((habit) => _buildHabitCard(habit)),
                            const SizedBox(height: 16),
                          ],

                          // Section Task
                          if (_selectedTasks.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.task_alt,
                                    size: 18, color: Colors.blue),
                                const SizedBox(width: 6),
                                Text(
                                  'Task (${_selectedTasks.length})',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._selectedTasks
                                .map((task) => _buildTaskCard(task)),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final color = _getHabitColor(habit.template);
    final emoji = _getHabitEmoji(habit.template);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      color: color.withValues(alpha: 0.07),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(
          habit.name,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (habit.motto != null && habit.motto!.isNotEmpty)
              Text(
                habit.motto!,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500),
              ),
            // Info target air khusus WATER
            if (habit.template == 'WATER' &&
                habit.waterTargetAmount != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.local_drink_outlined,
                      size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    'Target: ${habit.waterTargetAmount} '
                    '${habit.waterTargetUnit == 'CUPS' ? 'cups' : 'L'}',
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                habit.completedToday
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color:
                    habit.completedToday ? Colors.green : Colors.grey,
              ),
              onPressed: () => _toggleHabitLog(habit),
              tooltip: 'Selesai hari ini',
            ),
            habit.completedToday
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              Colors.green.withValues(alpha: 0.4)),
                    ),
                    child: const Text('Done',
                        style: TextStyle(
                            fontSize: 11, color: Colors.green)),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text('Habit',
                        style:
                            TextStyle(fontSize: 11, color: color)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final color = _getTaskColor(task);
    final isChecked = task.checked;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      color: isChecked ? Colors.grey.shade200 : Colors.white,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            if (isChecked) ...[
              const Icon(Icons.check_circle,
                  color: Colors.green, size: 18),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color:
                      isChecked ? Colors.grey.shade500 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        subtitle:
            task.description != null && task.description!.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      task.description!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  )
                : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                _getQuadrantLabel(task),
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                isChecked
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                color: isChecked ? Colors.green : Colors.grey,
                size: 22,
              ),
              onPressed: () => _toggleCheck(task),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Colors.red.shade300, size: 20),
              onPressed: () => _deleteTask(task),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }
}