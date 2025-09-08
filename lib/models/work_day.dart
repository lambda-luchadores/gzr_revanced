import 'package:flutter/material.dart';

class WorkDay {
  final DateTime date;
  DateTime startTime;
  DateTime? endTime;
  Duration manualBreakDuration;
  bool isActive;
  
  WorkDay({
    required this.date,
    required this.startTime,
    this.endTime,
    this.manualBreakDuration = Duration.zero,
    this.isActive = true,
  });
  
  Duration get workDuration {
    final end = endTime ?? DateTime.now();
    if (end.isBefore(startTime)) return Duration.zero;
    return end.difference(startTime);
  }
  
  Duration get automaticBreakDuration {
    final totalWork = workDuration;
    
    if (totalWork >= const Duration(hours: 9)) {
      return const Duration(minutes: 45);
    } else if (totalWork >= const Duration(hours: 6)) {
      return const Duration(minutes: 30);
    }
    return Duration.zero;
  }
  
  Duration get totalBreakDuration {
    return manualBreakDuration.compareTo(automaticBreakDuration) > 0 
        ? manualBreakDuration 
        : automaticBreakDuration;
  }
  
  Duration get netWorkDuration {
    final net = workDuration - totalBreakDuration;
    return net.isNegative ? Duration.zero : net;
  }
  
  bool get hasReachedDailyLimit {
    return netWorkDuration >= const Duration(hours: 10);
  }
  
  bool get requiresBreak {
    return workDuration >= const Duration(hours: 6);
  }
  
  bool get requiresExtendedBreak {
    return workDuration >= const Duration(hours: 9);
  }
  
  TimeOfDay get startTimeOfDay {
    return TimeOfDay(hour: startTime.hour, minute: startTime.minute);
  }
  
  TimeOfDay? get endTimeOfDay {
    if (endTime == null) return null;
    return TimeOfDay(hour: endTime!.hour, minute: endTime!.minute);
  }
  
  bool isInBreakWindow(DateTime time) {
    final timeOfDay = TimeOfDay(hour: time.hour, minute: time.minute);
    final breakStart = const TimeOfDay(hour: 11, minute: 15);
    final breakEnd = const TimeOfDay(hour: 14, minute: 30);
    
    final timeMinutes = timeOfDay.hour * 60 + timeOfDay.minute;
    final startMinutes = breakStart.hour * 60 + breakStart.minute;
    final endMinutes = breakEnd.hour * 60 + breakEnd.minute;
    
    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }
  
  bool isInGleitzeitWindow(DateTime time) {
    final hour = time.hour;
    return hour >= 6 && hour < 20;
  }
  
  bool isInFunktionszeit(DateTime time) {
    final hour = time.hour;
    return hour >= 9 && hour < 15;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'manualBreakDuration': manualBreakDuration.inMinutes,
      'isActive': isActive,
    };
  }
  
  factory WorkDay.fromJson(Map<String, dynamic> json) {
    return WorkDay(
      date: DateTime.parse(json['date']),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      manualBreakDuration: Duration(minutes: json['manualBreakDuration'] ?? 0),
      isActive: json['isActive'] ?? true,
    );
  }
}