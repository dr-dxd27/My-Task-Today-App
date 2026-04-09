import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TaskService _taskService = TaskService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _tasksByDate = {};
  List<Task> _selectedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadTasksForMonth(_focusedDay);
  }

  Future<void> _loadTasksForMonth(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _taskService.getTasksByMonth(date.year, date.month);
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

  Color _getPriorityColor(Task task) {
    if (task.priority == 'URGENT' && task.importance == 'IMPORTANT') {
      return Colors.red;
    } else if (task.priority == 'NOT_URGENT' && task.importance == 'IMPORTANT') {
      return Colors.blue;
    } else if (task.priority == 'URGENT' && task.importance == 'NOT_IMPORTANT') {
      return Colors.orange;
    }
    return Colors.grey;
  }

  String _getQuadrantLabel(Task task) {
    if (task.priority == 'URGENT' && task.importance == 'IMPORTANT') return 'Do First';
    if (task.priority == 'NOT_URGENT' && task.importance == 'IMPORTANT') return 'Schedule';
    if (task.priority == 'URGENT' && task.importance == 'NOT_IMPORTANT') return 'Delegate';
    return 'Eliminate';
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
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                    DropdownMenuItem(value: 'NOT_URGENT', child: Text('Not Urgent')),
                  ],
                  onChanged: (val) => setDialogState(() => priority = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: importance,
                  decoration: const InputDecoration(
                    labelText: 'Importance',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'IMPORTANT', child: Text('Important')),
                    DropdownMenuItem(value: 'NOT_IMPORTANT', child: Text('Not Important')),
                  ],
                  onChanged: (val) => setDialogState(() => importance = val!),
                ),
                const SizedBox(height: 12),
                // Date picker
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
                _loadTasksForMonth(_focusedDay);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadTasksForMonth(_focusedDay),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Calendar widget
          TableCalendar<Task>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getTasksForDay,
            calendarStyle: CalendarStyle(
              markerDecoration: const BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
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
              _loadTasksForMonth(focusedDay);
            },
          ),

          const Divider(height: 1),

          // Task list for selected day
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              _selectedDay != null
                                  ? 'Tidak ada task pada tanggal ini'
                                  : 'Pilih tanggal untuk melihat task',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _selectedTasks.length,
                        itemBuilder: (context, index) {
                          final task = _selectedTasks[index];
                          final color = _getPriorityColor(task);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.15),
                                child: Icon(
                                  task.checked
                                      ? Icons.check
                                      : Icons.radio_button_unchecked,
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.checked
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.checked ? Colors.grey : null,
                                ),
                              ),
                              subtitle: task.description != null &&
                                      task.description!.isNotEmpty
                                  ? Text(task.description!)
                                  : null,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: color.withOpacity(0.4)),
                                ),
                                child: Text(
                                  _getQuadrantLabel(task),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: color,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}