import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class MatrixScreen extends StatefulWidget {
  const MatrixScreen({super.key});

  @override
  State<MatrixScreen> createState() => _MatrixScreenState();
}

class _MatrixScreenState extends State<MatrixScreen> {
  final TaskService _taskService = TaskService();
  Map<String, List<Task>> _matrix = {
    'DO_FIRST': [],
    'SCHEDULE': [],
    'DELEGATE': [],
    'ELIMINATE': [],
  };
  bool _isLoading = true;

  final _quadrantConfig = {
    'DO_FIRST': {
      'title': 'Do First',
      'subtitle': 'Urgent & Important',
      'icon': Icons.bolt,
      'color': Colors.red,
      'priority': 'URGENT',
      'importance': 'IMPORTANT',
    },
    'SCHEDULE': {
      'title': 'Schedule',
      'subtitle': 'Not Urgent & Important',
      'icon': Icons.calendar_today,
      'color': Colors.blue,
      'priority': 'NOT_URGENT',
      'importance': 'IMPORTANT',
    },
    'DELEGATE': {
      'title': 'Delegate',
      'subtitle': 'Urgent & Not Important',
      'icon': Icons.people,
      'color': Colors.orange,
      'priority': 'URGENT',
      'importance': 'NOT_IMPORTANT',
    },
    'ELIMINATE': {
      'title': 'Eliminate',
      'subtitle': 'Not Urgent & Not Important',
      'icon': Icons.delete_outline,
      'color': Colors.grey,
      'priority': 'NOT_URGENT',
      'importance': 'NOT_IMPORTANT',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadMatrix();
  }

  Future<void> _loadMatrix() async {
    setState(() => _isLoading = true);
    try {
      final matrix = await _taskService.getMatrix();
      setState(() {
        _matrix = {
          'DO_FIRST': matrix['DO_FIRST'] ?? [],
          'SCHEDULE': matrix['SCHEDULE'] ?? [],
          'DELEGATE': matrix['DELEGATE'] ?? [],
          'ELIMINATE': matrix['ELIMINATE'] ?? [],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading matrix: $e');
    }
  }

  void _showAddTaskDialog(String quadrant) {
    final config = _quadrantConfig[quadrant]!;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final color = config['color'] as Color;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(config['icon'] as IconData, color: color, size: 20),
            const SizedBox(width: 8),
            Text('Tambah ke ${config['title']}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (color as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                config['subtitle'] as String,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Task *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              final task = Task(
                title: titleController.text,
                description: descController.text,
                priority: config['priority'] as String,
                importance: config['importance'] as String,
              );
              await _taskService.createTask(task);
              if (context.mounted) Navigator.pop(context);
              _loadMatrix();
            },
            child: const Text('Simpan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _taskService.deleteTask(task.id!);
      _loadMatrix();
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  Future<void> _toggleCheck(Task task) async {
    try {
      await _taskService.toggleCheck(task.id!);
      _loadMatrix();
    } catch (e) {
      debugPrint('Error toggling task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eisenhower Matrix'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMatrix,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Header labels
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: Center(
                          child: Text('URGENT',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade400)),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text('NOT URGENT',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade400)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Row(
                      children: [
                        // IMPORTANT label (rotated)
                        RotatedBox(
                          quarterTurns: 3,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('IMPORTANT',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade400)),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: _buildQuadrant('DO_FIRST'),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _buildQuadrant('DELEGATE'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: _buildQuadrant('SCHEDULE'),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _buildQuadrant('ELIMINATE'),
                              ),
                            ],
                          ),
                        ),
                        // NOT IMPORTANT label (rotated)
                        RotatedBox(
                          quarterTurns: 1,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('NOT IMPORTANT',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade400)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuadrant(String quadrant) {
    final config = _quadrantConfig[quadrant]!;
    final tasks = _matrix[quadrant] ?? [];
    final color = config['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Quadrant header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(config['icon'] as IconData, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    config['title'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _showAddTaskDialog(quadrant),
                  child: Icon(Icons.add_circle_outline, color: color, size: 18),
                ),
              ],
            ),
          ),
          // Task list
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada task',
                      style: TextStyle(
                          fontSize: 12, color: color.withOpacity(0.5)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(6),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: color.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => _toggleCheck(task),
                              child: Icon(
                                task.checked
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: task.checked
                                    ? Colors.green
                                    : color.withOpacity(0.5),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  decoration: task.checked
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.checked
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () => _deleteTask(task),
                              child: Icon(Icons.close,
                                  size: 16,
                                  color: Colors.grey.shade400),
                            ),
                          ],
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