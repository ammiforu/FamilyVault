class HomeMaintenanceTask {
  final String id;
  String taskName; // e.g. Replace HVAC Filter, Test Smoke Alarms
  String area; // HVAC, Plumbing, Roof, Safety, Yard
  int intervalMonths;
  DateTime lastCompletedDate;
  String assignedMember;
  String notes;

  HomeMaintenanceTask({
    required this.id,
    required this.taskName,
    this.area = 'General',
    this.intervalMonths = 3,
    required this.lastCompletedDate,
    this.assignedMember = 'Entire Family',
    this.notes = '',
  });

  DateTime get nextDueDate => DateTime(
    lastCompletedDate.year,
    lastCompletedDate.month + intervalMonths,
    lastCompletedDate.day,
  );

  int get daysUntilDue => nextDueDate.difference(DateTime.now()).inDays;
  bool get isDue => daysUntilDue <= 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskName': taskName,
    'area': area,
    'intervalMonths': intervalMonths,
    'lastCompletedDate': lastCompletedDate.toIso8601String(),
    'assignedMember': assignedMember,
    'notes': notes,
  };

  factory HomeMaintenanceTask.fromJson(Map<String, dynamic> json) => HomeMaintenanceTask(
    id: json['id'] as String? ?? '',
    taskName: json['taskName'] as String? ?? 'Task',
    area: json['area'] as String? ?? 'General',
    intervalMonths: json['intervalMonths'] as int? ?? 3,
    lastCompletedDate: json['lastCompletedDate'] != null
        ? DateTime.tryParse(json['lastCompletedDate'] as String) ?? DateTime.now()
        : DateTime.now(),
    assignedMember: json['assignedMember'] as String? ?? 'Entire Family',
    notes: json['notes'] as String? ?? '',
  );
}
