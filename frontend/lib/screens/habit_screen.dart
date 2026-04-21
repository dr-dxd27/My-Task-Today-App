import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit_model.dart';
import '../services/habit_service.dart';
import '../services/theme_service.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final HabitService _habitService = HabitService();
  List<Habit> _habits = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _templates = [
    {'type': 'DRINK_WATER',  'label': 'Drink Water 💧',  'motto': 'Stay hydrated every day!',         'color': Colors.cyan},
    {'type': 'EXERCISE',     'label': 'Exercise 🏃',     'motto': 'Move your body, boost your mood!', 'color': Colors.green},
    {'type': 'MARTIAL_ARTS', 'label': 'Martial Arts 🥋', 'motto': 'Train hard, fight easy.',          'color': Colors.deepOrange},
    {'type': 'GOOD_MORNING', 'label': 'Good Morning ☀️', 'motto': 'Start the day with intention.',    'color': Colors.amber},
    {'type': 'GOOD_NIGHT',   'label': 'Good Night 🌙',   'motto': 'Rest well, recover strong.',       'color': Colors.indigo},
    {'type': 'CUSTOM',       'label': 'Custom ✏️',       'motto': '',                                 'color': Colors.purple},
  ];

  final List<Map<String, String>> _weekDays = [
    {'key': 'MONDAY',    'label': 'Sen'},
    {'key': 'TUESDAY',   'label': 'Sel'},
    {'key': 'WEDNESDAY', 'label': 'Rab'},
    {'key': 'THURSDAY',  'label': 'Kam'},
    {'key': 'FRIDAY',    'label': 'Jum'},
    {'key': 'SATURDAY',  'label': 'Sab'},
    {'key': 'SUNDAY',    'label': 'Min'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    try {
      final habits = await _habitService.getAllHabits();
      setState(() {
        _habits = habits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading habits: $e');
    }
  }

  Color _getTemplateColor(String template) {
    final t = _templates.firstWhere(
      (e) => e['type'] == template,
      orElse: () => _templates.last,
    );
    return t['color'] as Color;
  }

  String _getTemplateLabel(String template) {
    final t = _templates.firstWhere(
      (e) => e['type'] == template,
      orElse: () => _templates.last,
    );
    return t['label'] as String;
  }

  String _formatDuration(Habit habit) {
    if (habit.durationType == 'ALL_TIME') return 'All Time';
    if (habit.durationType == 'CUSTOM') {
      if (habit.customDays.isEmpty) return 'Custom';
      final labels = habit.customDays.map((day) {
        return _weekDays
            .firstWhere((d) => d['key'] == day,
                orElse: () => {'key': day, 'label': day})['label']!;
      }).join(', ');
      return labels;
    }
    final unit = switch (habit.durationType) {
      'DAY'  => 'Hari',
      'WEEK' => 'Minggu',
      'YEAR' => 'Tahun',
      _      => '',
    };
    return '${habit.durationValue} $unit';
  }

  void _showFormDialog({Habit? existing}) {
    String selectedTemplate = existing?.template ?? 'CUSTOM';
    final nameController = TextEditingController(text: existing?.name ?? '');
    final mottoController = TextEditingController(text: existing?.motto ?? '');
    String durationType = existing?.durationType ?? 'ALL_TIME';
    final durationController = TextEditingController(
        text: existing?.durationValue?.toString() ?? '');
    List<String> notifTimes = List.from(existing?.notifTimes ?? []);
    List<String> customDays = List.from(existing?.customDays ?? []);
    int? waterTargetAmount = existing?.waterTargetAmount;
    String waterTargetUnit = existing?.waterTargetUnit ?? 'CUPS';
    final waterTargetController = TextEditingController(
        text: existing?.waterTargetAmount?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final color = _getTemplateColor(selectedTemplate);

          return AlertDialog(
            title: Text(existing == null ? 'Tambah Habit' : 'Edit Habit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Template selector
                  const Text('Template',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _templates.map((t) {
                      final isSelected = selectedTemplate == t['type'];
                      final tColor = t['color'] as Color;
                      return ChoiceChip(
                        label: Text(t['label'] as String,
                            style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        selectedColor: tColor.withValues(alpha: 0.2),
                        side: BorderSide(
                            color: isSelected
                                ? tColor
                                : Colors.grey.shade300),
                        onSelected: (_) {
                          setDialogState(() {
                            selectedTemplate = t['type'] as String;
                            if (mottoController.text.isEmpty ||
                                _templates.any((e) =>
                                    e['motto'] == mottoController.text)) {
                              mottoController.text = t['motto'] as String;
                            }
                            if (t['type'] != 'CUSTOM' &&
                                nameController.text.isEmpty) {
                              final words = (t['label'] as String).split(' ');
                              nameController.text = words.length >= 2
                                  ? '${words[0]} ${words[1]}'
                                  : words[0];
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Nama
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Habit *',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Motto
                  TextField(
                    controller: mottoController,
                    decoration: const InputDecoration(
                      labelText: 'Motto / Deskripsi',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),

                  // Water target — khusus DRINK_WATER
                  if (selectedTemplate == 'DRINK_WATER') ...[
                    const SizedBox(height: 16),
                    const Text('Target Konsumsi Air',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: waterTargetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: waterTargetUnit == 'CUPS'
                                  ? 'Jumlah Cups'
                                  : 'Jumlah Liter',
                              border: const OutlineInputBorder(),
                              suffixText:
                                  waterTargetUnit == 'CUPS' ? 'cups' : 'L',
                            ),
                            onChanged: (val) {
                              waterTargetAmount = int.tryParse(val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: ['CUPS', 'LITER'].map((unit) {
                            final isSelected = waterTargetUnit == unit;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: ChoiceChip(
                                label: Text(
                                  unit == 'CUPS' ? 'Cups' : 'Liter',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: isSelected,
                                selectedColor:
                                    Colors.cyan.withValues(alpha: 0.2),
                                side: BorderSide(
                                    color: isSelected
                                        ? Colors.cyan
                                        : Colors.grey.shade300),
                                onSelected: (_) => setDialogState(
                                    () => waterTargetUnit = unit),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Durasi
                  const Text('Durasi',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: ['DAY', 'WEEK', 'YEAR', 'ALL_TIME', 'CUSTOM']
                        .map((type) {
                      final label = switch (type) {
                        'DAY'      => 'Hari',
                        'WEEK'     => 'Minggu',
                        'YEAR'     => 'Tahun',
                        'ALL_TIME' => 'All Time',
                        'CUSTOM'   => 'Custom',
                        _          => type,
                      };
                      return ChoiceChip(
                        label: Text(label,
                            style: const TextStyle(fontSize: 12)),
                        selected: durationType == type,
                        selectedColor: color.withValues(alpha: 0.2),
                        side: BorderSide(
                            color: durationType == type
                                ? color
                                : Colors.grey.shade300),
                        onSelected: (_) =>
                            setDialogState(() => durationType = type),
                      );
                    }).toList(),
                  ),

                  // Input jumlah untuk DAY/WEEK/YEAR
                  if (durationType != 'ALL_TIME' &&
                      durationType != 'CUSTOM') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Jumlah ${switch (durationType) {
                          'DAY'  => 'Hari',
                          'WEEK' => 'Minggu',
                          'YEAR' => 'Tahun',
                          _      => '',
                        }}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],

                  // Custom day picker
                  if (durationType == 'CUSTOM') ...[
                    const SizedBox(height: 12),
                    const Text('Pilih Hari',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _weekDays.map((day) {
                        final isSelected = customDays.contains(day['key']);
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              if (isSelected) {
                                customDays.remove(day['key']);
                              } else {
                                customDays.add(day['key']!);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? color : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                day['label']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (customDays.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Pilih minimal 1 hari',
                          style: TextStyle(
                              fontSize: 11, color: Colors.red.shade300),
                        ),
                      ),
                  ],

                  const SizedBox(height: 16),

                  // Notif times
                  Row(
                    children: [
                      const Text('Waktu Notifikasi',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tambah'),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            final formatted =
                                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            if (!notifTimes.contains(formatted)) {
                              setDialogState(() => notifTimes.add(formatted));
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (notifTimes.isEmpty)
                    Text(
                      'Belum ada waktu notifikasi',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      children: notifTimes.map((time) {
                        return Chip(
                          label: Text(time),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () =>
                              setDialogState(() => notifTimes.remove(time)),
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
                onPressed: () async {
                  if (nameController.text.isEmpty) return;
                  if (durationType == 'CUSTOM' && customDays.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Pilih minimal 1 hari untuk Custom')),
                    );
                    return;
                  }
                  final habit = Habit(
                    name: nameController.text,
                    motto: mottoController.text,
                    notifTimes: notifTimes,
                    durationType: durationType,
                    durationValue: (durationType != 'ALL_TIME' &&
                            durationType != 'CUSTOM')
                        ? int.tryParse(durationController.text)
                        : null,
                    customDays: durationType == 'CUSTOM' ? customDays : [],
                    template: selectedTemplate,
                    waterTargetAmount: selectedTemplate == 'DRINK_WATER'
                        ? int.tryParse(waterTargetController.text)
                        : null,
                    waterTargetUnit: selectedTemplate == 'DRINK_WATER'
                        ? waterTargetUnit
                        : null,
                    startDate: existing?.startDate ??
                        DateTime.now().toIso8601String().split('T')[0],
                  );
                  if (existing == null) {
                    await _habitService.createHabit(habit);
                  } else {
                    await _habitService.updateHabit(existing.id!, habit);
                  }
                  if (context.mounted) Navigator.pop(context);
                  _loadHabits();
                },
                child: Text(
                  existing == null ? 'Simpan' : 'Update',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Dialog catat minum air
  void _showWaterDialog(Habit habit) {
    final color = _getTemplateColor(habit.template);
    final target = habit.waterTargetAmount ?? 0;
    final unit = habit.waterTargetUnit == 'CUPS' ? 'cups' : 'L';
    int currentAmount = habit.currentWaterAmount;
    final controller =
        TextEditingController(text: currentAmount.toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Text('💧 ', style: TextStyle(fontSize: 20)),
              Text('Catat Minum Air',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress
              if (target > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$currentAmount / $target $unit',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 16),
                    ),
                    Text(
                      '${((currentAmount / target) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: target > 0
                        ? (currentAmount / target).clamp(0.0, 1.0)
                        : 0,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Input jumlah
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah yang sudah diminum',
                  border: const OutlineInputBorder(),
                  suffixText: unit,
                  helperText: target > 0 ? 'Target: $target $unit' : null,
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val) ?? 0;
                  setDialogState(() => currentAmount = parsed);
                },
              ),

              const SizedBox(height: 12),

              // Quick add
              if (target > 0) ...[
                Text('Quick Add',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [1, 2, 3].map((qty) {
                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        final newAmount =
                            (habit.currentWaterAmount + qty)
                                .clamp(0, target * 2);
                        controller.text = newAmount.toString();
                        setDialogState(() => currentAmount = newAmount);
                      },
                      child: Text('+$qty $unit',
                          style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                ),
              ],
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
                await _habitService.updateWaterLog(
                    habit.id!, currentAmount);
                if (context.mounted) Navigator.pop(context);
                _loadHabits();
              },
              child: const Text('Simpan',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteHabit(Habit habit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Habit?'),
        content:
            Text('Hapus "${habit.name}"? Data log tetap tersimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _habitService.deleteHabit(habit.id!);
      _loadHabits();
    }
  }

  Future<void> _toggleLog(Habit habit) async {
    await _habitService.toggleLog(habit.id!);
    _loadHabits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadHabits),
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
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.loop,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada habit',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + untuk menambah habit baru',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _habits.length,
                  itemBuilder: (context, index) {
                    final habit = _habits[index];
                    final color = _getTemplateColor(habit.template);
                    final isWater = habit.template == 'DRINK_WATER';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: color.withValues(alpha: 0.4)),
                      ),
                      color: color.withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row utama
                            Row(
                              children: [
                                // Avatar
                                CircleAvatar(
                                  backgroundColor:
                                      color.withValues(alpha: 0.15),
                                  child: Text(
                                    _getTemplateLabel(habit.template)
                                        .split(' ')
                                        .last,
                                    style:
                                        const TextStyle(fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        habit.name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: color),
                                      ),
                                      if (habit.motto != null &&
                                          habit.motto!.isNotEmpty)
                                        Text(
                                          habit.motto!,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Colors.grey.shade500),
                                        ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.timer_outlined,
                                              size: 12, color: color),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              _formatDuration(habit),
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: color),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (habit.notifTimes
                                              .isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Icon(
                                                Icons
                                                    .notifications_outlined,
                                                size: 12,
                                                color: color),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                habit.notifTimes
                                                    .join(', '),
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: color),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Trailing buttons
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Water: tombol catat | Lainnya: toggle done
                                    if (isWater)
                                      IconButton(
                                        icon: Icon(
                                            Icons.local_drink_outlined,
                                            color: color),
                                        onPressed: () =>
                                            _showWaterDialog(habit),
                                        tooltip: 'Catat minum air',
                                      )
                                    else
                                      IconButton(
                                        icon: Icon(
                                          habit.completedToday
                                              ? Icons.check_circle
                                              : Icons
                                                  .radio_button_unchecked,
                                          color: habit.completedToday
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                        onPressed: () =>
                                            _toggleLog(habit),
                                        tooltip: 'Selesai hari ini',
                                      ),
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined,
                                          color: color),
                                      onPressed: () =>
                                          _showFormDialog(existing: habit),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          color: Colors.red.shade300),
                                      onPressed: () =>
                                          _deleteHabit(habit),
                                      tooltip: 'Hapus',
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Water progress bar — hanya DRINK_WATER
                            if (isWater &&
                                habit.waterTargetAmount != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.local_drink_outlined,
                                          size: 13, color: color),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${habit.currentWaterAmount} / ${habit.waterTargetAmount} '
                                        '${habit.waterTargetUnit == 'CUPS' ? 'cups' : 'L'}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: color,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  if (habit.completedToday)
                                    const Text(
                                      '✅ Target tercapai!',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: habit.waterTargetAmount! > 0
                                      ? (habit.currentWaterAmount /
                                              habit.waterTargetAmount!)
                                          .clamp(0.0, 1.0)
                                      : 0,
                                  minHeight: 8,
                                  backgroundColor:
                                      color.withValues(alpha: 0.15),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    habit.completedToday
                                        ? Colors.green
                                        : color,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}