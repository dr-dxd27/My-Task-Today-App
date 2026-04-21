import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/habit_model.dart';

class HabitService {
  Future<List<Habit>> getAllHabits() async {
    final response = await http.get(Uri.parse(ApiConfig.habits));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Habit.fromJson(e)).toList();
    }
    throw Exception('Failed to load habits');
  }

  Future<List<Habit>> getHabitsForMonth(int year, int month) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.habits}/calendar?year=$year&month=$month'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Habit.fromJson(e)).toList();
    }
    throw Exception('Failed to load habits for month');
  }

  Future<Habit> createHabit(Habit habit) async {
    final response = await http.post(
      Uri.parse(ApiConfig.habits),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(habit.toJson()),
    );
    if (response.statusCode == 200) {
      return Habit.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create habit');
  }

  Future<Habit> updateHabit(int id, Habit habit) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.habits}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(habit.toJson()),
    );
    if (response.statusCode == 200) {
      return Habit.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update habit');
  }

  Future<void> deleteHabit(int id) async {
    final response = await http.delete(Uri.parse('${ApiConfig.habits}/$id'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete habit');
    }
  }

  Future<void> toggleLog(int habitId, {String? date, String? notes}) async {
    final queryDate = date ?? DateTime.now().toIso8601String().split('T')[0];
    await http.post(
      Uri.parse('${ApiConfig.habits}/$habitId/log?date=$queryDate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'notes': notes ?? ''}),
    );
  }

  Future<void> updateWaterLog(int habitId, int amount, {String? date}) async {
    final queryDate = date ?? DateTime.now().toIso8601String().split('T')[0];
    await http.patch(
      Uri.parse('${ApiConfig.habits}/$habitId/log/water?date=$queryDate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'amount': amount}),
    );
  }
}