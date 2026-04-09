import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/task_model.dart';

class TaskService {
  // Ambil semua task
  Future<List<Task>> getAllTasks() async {
    final response = await http.get(Uri.parse(ApiConfig.tasks));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Task.fromJson(e)).toList();
    }
    throw Exception('Failed to load tasks');
  }

  // Eisenhower Matrix
  Future<Map<String, List<Task>>> getMatrix() async {
    final response = await http.get(Uri.parse(ApiConfig.matrix));
    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      return data.map((key, value) {
        List<Task> tasks = (value as List).map((e) => Task.fromJson(e)).toList();
        return MapEntry(key, tasks);
      });
    }
    throw Exception('Failed to load matrix');
  }

  // Calendar
  Future<List<Task>> getTasksByMonth(int year, int month) async {
    final url = '${ApiConfig.calendar}?year=$year&month=$month';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Task.fromJson(e)).toList();
    }
    throw Exception('Failed to load calendar tasks');
  }

  // Checklist
  Future<List<Task>> getUncheckedTasks() async {
    final response = await http.get(Uri.parse(ApiConfig.checklist));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Task.fromJson(e)).toList();
    }
    throw Exception('Failed to load checklist');
  }

  // Buat task baru
  Future<Task> createTask(Task task) async {
    final response = await http.post(
      Uri.parse(ApiConfig.tasks),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(task.toJson()),
    );
    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create task');
  }

  // Update task
  Future<Task> updateTask(int id, Task task) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.tasks}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(task.toJson()),
    );
    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update task');
  }

  // Toggle checklist
  Future<Task> toggleCheck(int id) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.tasks}/$id/check'),
    );
    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to toggle task');
  }

  // Hapus task
  Future<void> deleteTask(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.tasks}/$id'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete task');
    }
  }
}