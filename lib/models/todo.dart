import 'package:flutter/material.dart';
import 'package:todo/utils/enums.dart';

class Todo {
  final String id;
  final String userId;
  String title;
  String? description; // For detailed info
  TodoStage stage; // For Kanban stage
  bool isDone;
  final DateTime createdAt;
  
  // Scheduling Fields
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  
  // NEW Kanban Tracking Fields (The time the task entered InProgress/Done)
  DateTime? inProgressAt;
  DateTime? doneAt;

  Todo({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.stage = TodoStage.Todo,
    required this.isDone,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.inProgressAt, // NEW
    this.doneAt,       // NEW
  });

  factory Todo.fromMap(Map<String, dynamic> map) {
    TodoStage parseStage(String stageString) {
      switch (stageString) {
        case 'InProgress':
          return TodoStage.InProgress;
        case 'Done':
          return TodoStage.Done;
        case 'Todo':
        default:
          return TodoStage.Todo;
      }
    }
    
    DateTime? parseDateTime(dynamic value) {
      if (value is String) return DateTime.tryParse(value);
      return null;
    }
    
    TimeOfDay? parseTimeOfDay(dynamic value) {
      if (value is String) {
        try {
          final parts = value.split(':');
          if (parts.length >= 2) {
            return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
        } catch (e) { }
      }
      return null;
    }

    return Todo(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      description: map['description'],
      stage: parseStage(map['stage'] ?? 'Todo'),
      isDone: map['is_done'],
      createdAt: DateTime.parse(map['created_at']),
      startDate: parseDateTime(map['start_date']),
      endDate: parseDateTime(map['end_date']),
      startTime: parseTimeOfDay(map['start_time']),
      endTime: parseTimeOfDay(map['end_time']),
      inProgressAt: parseDateTime(map['in_progress_at']), // Mapped
      doneAt: parseDateTime(map['done_at']),             // Mapped
    );
  }

  Map<String, dynamic> toMap() {
    String? formatTimeOfDay(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    }

    return {
      'title': title,
      'description': description,
      'stage': stage.dbValue,
      'is_done': isDone,
      'start_date': startDate?.toIso8601String().split('T').first, 
      'end_date': endDate?.toIso8601String().split('T').first,
      'start_time': formatTimeOfDay(startTime),
      'end_time': formatTimeOfDay(endTime),
      'in_progress_at': inProgressAt?.toIso8601String(), // Mapped
      'done_at': doneAt?.toIso8601String(),             // Mapped
    };
  }

  Todo copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TodoStage? stage,
    bool? isDone,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    DateTime? inProgressAt, // Copied
    DateTime? doneAt,       // Copied
  }) {
    return Todo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      stage: stage ?? this.stage,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      inProgressAt: inProgressAt ?? this.inProgressAt,
      doneAt: doneAt ?? this.doneAt,
    );
  }
}