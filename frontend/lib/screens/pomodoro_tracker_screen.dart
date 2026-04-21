import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../services/theme_service.dart';

class PomodoroTrackerScreen extends StatefulWidget {
  const PomodoroTrackerScreen({super.key});

  @override
  State<PomodoroTrackerScreen> createState() => _PomodoroTrackerScreenState();
}

class _PomodoroTrackerScreenState extends State<PomodoroTrackerScreen> {
  String _selectedRange = 'WEEK';
  bool _isLoadingStats = true;
  bool _isLoadingRecords = true;

  // Stats
  int _totalSessions = 0;
  int _totalMinutes = 0;
  List<Map<String, dynamic>> _dailyStats = [];

  // Records
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadRecords();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.pomodoroStats}?range=$_selectedRange'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _totalSessions = data['totalSessions'] ?? 0;
          _totalMinutes = data['totalMinutes'] ?? 0;
          _dailyStats = List<Map<String, dynamic>>.from(
              data['dailyStats'] ?? []);
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingStats = false);
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoadingRecords = true);
    try {
      final response = await http.get(Uri.parse(ApiConfig.pomodoroRecords));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _records = List<Map<String, dynamic>>.from(data);
          _isLoadingRecords = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingRecords = false);
      debugPrint('Error loading records: $e');
    }
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String _getRangeLabel() {
    return switch (_selectedRange) {
      'WEEK'  => '7 Hari Terakhir',
      'MONTH' => '30 Hari Terakhir',
      'YEAR'  => '12 Bulan Terakhir',
      _       => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Tracker'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<ThemeService>(
            builder: (context, themeService, _) => IconButton(
              icon: Icon(
                  themeService.isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: themeService.toggle,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Trends
            _buildSectionHeader(Icons.trending_up, 'Trends', Colors.deepPurple),
            const SizedBox(height: 12),

            // Range selector
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: ['WEEK', 'MONTH', 'YEAR'].map((range) {
                  final selected = _selectedRange == range;
                  final label = switch (range) {
                    'WEEK'  => 'Week',
                    'MONTH' => 'Month',
                    'YEAR'  => 'Year',
                    _       => range,
                  };
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedRange = range);
                        _loadStats();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.deepPurple
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
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

            const SizedBox(height: 16),

            // Summary cards
            if (_isLoadingStats)
              const Center(child: CircularProgressIndicator())
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.local_fire_department,
                      iconColor: Colors.orange,
                      label: 'Total Sesi',
                      value: '$_totalSessions',
                      sub: _getRangeLabel(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.access_time,
                      iconColor: Colors.deepPurple,
                      label: 'Total Fokus',
                      value: _formatMinutes(_totalMinutes),
                      sub: _getRangeLabel(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bar chart
              if (_dailyStats.isNotEmpty)
                _buildBarChart(),
            ],

            const SizedBox(height: 24),

            // Section Focus Record
            _buildSectionHeader(
                Icons.history, 'Focus Record', Colors.deepPurple),
            const SizedBox(height: 12),

            if (_isLoadingRecords)
              const Center(child: CircularProgressIndicator())
            else if (_records.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada sesi pomodoro selesai',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...(_records.map((record) => _buildRecordCard(record))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.deepPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          Text(sub,
              style: TextStyle(
                  fontSize: 10, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final maxCount = _dailyStats
        .map((d) => (d['sessionCount'] as int?) ?? 0)
        .fold(0, (a, b) => a > b ? a : b);
    final maxValue = maxCount == 0 ? 1 : maxCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.deepPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sesi per ${_selectedRange == 'YEAR' ? 'Bulan' : 'Hari'}',
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _dailyStats.map((day) {
                final count = (day['sessionCount'] as int?) ?? 0;
                final ratio = count / maxValue;
                final isToday = day['date'] ==
                    DateTime.now().toIso8601String().split('T')[0];

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Count label
                        if (count > 0)
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.deepPurple.withValues(alpha: 0.7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 2),
                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: count == 0 ? 4 : (100 * ratio).clamp(4, 100),
                          decoration: BoxDecoration(
                            color: isToday
                                ? Colors.deepPurple
                                : count == 0
                                    ? Colors.grey.withValues(alpha: 0.2)
                                    : Colors.deepPurple.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Label
                        Text(
                          day['label'] ?? '',
                          style: TextStyle(
                            fontSize: _selectedRange == 'MONTH' ? 8 : 10,
                            color: isToday
                                ? Colors.deepPurple
                                : Colors.grey.shade500,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final taskTitle = record['taskTitle'] as String?;
    final duration = (record['durationMinutes'] as int?) ?? 0;
    final startedAt = record['startedAt'] as String? ?? '-';
    final endedAt = record['endedAt'] as String? ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.deepPurple.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timer,
                color: Colors.deepPurple, size: 20),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskTitle ?? 'Tanpa Task',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: taskTitle != null
                        ? null
                        : Colors.grey.shade500,
                    fontStyle: taskTitle != null
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text(
                      startedAt,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Duration badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.deepPurple.withValues(alpha: 0.3)),
            ),
            child: Text(
              _formatMinutes(duration),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}