import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PomodoroSession {
  final int? id;
  final int? taskId;
  final int durationMinutes;
  final String? startedAt;
  final String? endedAt;
  final bool completed;

  PomodoroSession({
    this.id,
    this.taskId,
    this.durationMinutes = 25,
    this.startedAt,
    this.endedAt,
    this.completed = false,
  });

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'],
      taskId: json['task']?['id'],
      durationMinutes: json['durationMinutes'] ?? 25,
      startedAt: json['startedAt'],
      endedAt: json['endedAt'],
      completed: json['completed'] ?? false,
    );
  }
}

class PomodoroService {
  Future<PomodoroSession> startSession(int taskId, int duration) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.pomodoro}/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'taskId': taskId, 'durationMinutes': duration}),
    );
    if (response.statusCode == 200) {
      return PomodoroSession.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to start session');
  }

  Future<PomodoroSession> completeSession(int sessionId) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.pomodoro}/$sessionId/complete'),
    );
    if (response.statusCode == 200) {
      return PomodoroSession.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to complete session');
  }
}