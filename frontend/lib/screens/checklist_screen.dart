import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

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

  Future<void> _loadTasks() async {
    try {
      final tasks = await _taskService.getAllTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
                final task = Task(
                  title: titleController.text,
                  description: descController.text,
                  priority: priority,
                  importance: importance,
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

  @override
  Widget build(BuildContext context) {
    final doneTasks = _tasks.where((t) => t.checked).toList();
    final pendingTasks = _tasks.where((t) => !t.checked).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
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
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checklist, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada task', style: TextStyle(color: Colors.grey)),
                      Text('Tap + untuk menambah task baru',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (pendingTasks.isNotEmpty) ...[
                      Text(
                        'Pending (${pendingTasks.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ...pendingTasks.map((task) => _buildTaskCard(task)),
                      const SizedBox(height: 16),
                    ],
                    if (doneTasks.isNotEmpty) ...[
                      Text(
                        'Selesai (${doneTasks.length})',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey[600]),
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
      child: ListTile(
        leading: Checkbox(
          value: task.checked,
          onChanged: (_) => _toggleCheck(task),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.checked ? TextDecoration.lineThrough : null,
            color: task.checked ? Colors.grey : null,
          ),
        ),
        subtitle: task.description != null && task.description!.isNotEmpty
            ? Text(task.description!)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBadge(task.priority == 'URGENT' ? 'Urgent' : 'Not Urgent',
                task.priority == 'URGENT' ? Colors.red : Colors.grey),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteTask(task),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}