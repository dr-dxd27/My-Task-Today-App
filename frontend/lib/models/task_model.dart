class Task {
  final int? id;
  final String title;
  final String? description;
  final String priority;
  final String importance;
  final String status;
  final String? dueDate;
  final bool checked;

  Task({
    this.id,
    required this.title,
    this.description,
    this.priority = 'NOT_URGENT',
    this.importance = 'NOT_IMPORTANT',
    this.status = 'TODO',
    this.dueDate,
    this.checked = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'] ?? 'NOT_URGENT',
      importance: json['importance'] ?? 'NOT_IMPORTANT',
      status: json['status'] ?? 'TODO',
      dueDate: json['dueDate'],
      checked: json['checked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'importance': importance,
      'status': status,
      'dueDate': dueDate,
      'checked': checked,
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? priority,
    String? importance,
    String? status,
    String? dueDate,
    bool? checked,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      importance: importance ?? this.importance,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      checked: checked ?? this.checked,
    );
  }
}