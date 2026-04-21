import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  String get _todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadTasks() async {
    try {
      final allTasks = await _taskService.getAllTasks();
      // Tampilkan task hari ini + task tanpa dueDate
      final filtered = allTasks.where((t) {
        if (t.dueDate == null || t.dueDate!.isEmpty) return true;
        return t.dueDate == _todayDate;
      }).toList();
      setState(() {
        _tasks = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<void> _toggleCheck(Task task) async {
    try {
      await _taskService.toggleCheck(task.id!);
      _loadTasks();
    } catch (e) {
      debugPrint('Error toggling task: $e');
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _taskService.deleteTask(task.id!);
      _loadTasks();
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'NOT_URGENT';
    String importance = 'NOT_IMPORTANT';
    DateTime selectedDate = DateTime.now(); // Default hari ini, tanpa toggle

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Task Baru'),
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

                // Date picker langsung — default hari ini, tanpa toggle
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
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tanggal',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500),
                              ),
                              Text(
                                '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_drop_down,
                            color: Colors.grey.shade500),
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
                _loadTasks();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getUrgencyColor(String priority, String importance) {
    if (importance == 'IMPORTANT' && priority == 'URGENT') {
      return Colors.red;       // Important & Urgent
    } else if (importance == 'IMPORTANT' && priority == 'NOT_URGENT') {
      return Colors.blue;      // Important & Not Urgent
    } else if (importance == 'NOT_IMPORTANT' && priority == 'URGENT') {
      return Colors.orange;    // Not Important & Urgent
    }
    return Colors.grey;        // Not Important & Not Urgent
  }

  @override
  Widget build(BuildContext context) {
    final doneTasks = _tasks.where((t) => t.checked).toList();
    final pendingTasks = _tasks.where((t) => !t.checked).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Checklist', style: TextStyle(fontSize: 16)),
            Text(
              'Hari ini — ${pendingTasks.length} pending, ${doneTasks.length} selesai',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTasks),
          Consumer<ThemeService>(
            builder: (context, themeService, _) => IconButton(
              icon: Icon(themeService.isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: themeService.toggle,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checklist,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada task hari ini',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + untuk menambah task baru',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Pending tasks
                    if (pendingTasks.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.pending_actions,
                              size: 18, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text(
                            'Pending (${pendingTasks.length})',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...pendingTasks
                          .map((task) => _buildTaskCard(task)),
                      const SizedBox(height: 16),
                    ],

                    // Done tasks
                    if (doneTasks.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 18, color: Colors.green),
                          const SizedBox(width: 6),
                          Text(
                            'Selesai (${doneTasks.length})',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...doneTasks.map((task) => _buildTaskCard(task)),
                    ],
                  ],
                ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: task.checked
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      color: task.checked ? Colors.green.withValues(alpha: 0.05) : Colors.white,
      child: ListTile(
        leading: Checkbox(
          value: task.checked,
          activeColor: Colors.green,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4)),
          onChanged: (_) => _toggleCheck(task),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration:
                task.checked ? TextDecoration.lineThrough : null,
            color: task.checked ? Colors.grey : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  task.description!,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            // Due date jika ada
            if (task.dueDate != null && task.dueDate!.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 11, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Text(
                    task.dueDate!,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBadge(
              task.priority == 'URGENT' ? 'Urgent' : 'Not Urgent',
              _getUrgencyColor(task.priority, task.importance),
            ),
            const SizedBox(width: 4),
            _buildBadge(
              task.importance == 'IMPORTANT' ? 'Important' : 'Not Important',
              _getUrgencyColor(task.priority, task.importance),
            ),
            const SizedBox(width: 4),
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}