import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/work_day.dart';
import '../models/gleitzeit_settings.dart';

class StorageService {
  static const String _currentWorkDayKey = 'current_work_day';
  static const String _settingsKey = 'gleitzeit_settings';
  static const String _workHistoryKey = 'work_history';
  static const String _lastSaveTimeKey = 'last_save_time';
  
  late SharedPreferences _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  Future<WorkDay?> loadCurrentWorkDay() async {
    final String? jsonString = _prefs.getString(_currentWorkDayKey);
    if (jsonString == null) return null;
    
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final workDay = WorkDay.fromJson(json);
      
      final now = DateTime.now();
      final isSameDay = workDay.date.year == now.year &&
          workDay.date.month == now.month &&
          workDay.date.day == now.day;
      
      if (!isSameDay) {
        await saveToHistory(workDay);
        return null;
      }
      
      return workDay;
    } catch (e) {
      return null;
    }
  }
  
  Future<void> saveCurrentWorkDay(WorkDay workDay) async {
    final String jsonString = jsonEncode(workDay.toJson());
    await _prefs.setString(_currentWorkDayKey, jsonString);
    await _prefs.setString(_lastSaveTimeKey, DateTime.now().toIso8601String());
  }
  
  Future<void> clearCurrentWorkDay() async {
    await _prefs.remove(_currentWorkDayKey);
  }
  
  Future<GleitzeitSettings> loadSettings() async {
    final String? jsonString = _prefs.getString(_settingsKey);
    if (jsonString == null) {
      return const GleitzeitSettings();
    }
    
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return GleitzeitSettings.fromJson(json);
    } catch (e) {
      return const GleitzeitSettings();
    }
  }
  
  Future<void> saveSettings(GleitzeitSettings settings) async {
    final String jsonString = jsonEncode(settings.toJson());
    await _prefs.setString(_settingsKey, jsonString);
  }
  
  Future<List<WorkDay>> loadWorkHistory() async {
    final String? jsonString = _prefs.getString(_workHistoryKey);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => WorkDay.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> saveToHistory(WorkDay workDay) async {
    final history = await loadWorkHistory();
    
    history.removeWhere((day) =>
        day.date.year == workDay.date.year &&
        day.date.month == workDay.date.month &&
        day.date.day == workDay.date.day);
    
    history.add(workDay);
    
    history.sort((a, b) => b.date.compareTo(a.date));
    
    if (history.length > 365) {
      history.removeRange(365, history.length);
    }
    
    final String jsonString = jsonEncode(
      history.map((day) => day.toJson()).toList(),
    );
    await _prefs.setString(_workHistoryKey, jsonString);
  }
  
  Future<DateTime?> getLastSaveTime() async {
    final String? timeString = _prefs.getString(_lastSaveTimeKey);
    if (timeString == null) return null;
    
    try {
      return DateTime.parse(timeString);
    } catch (e) {
      return null;
    }
  }
  
  Future<Duration> calculateCurrentBalance() async {
    final history = await loadWorkHistory();
    final settings = await loadSettings();
    
    Duration totalWorked = Duration.zero;
    Duration totalExpected = Duration.zero;
    
    for (final day in history) {
      totalWorked += day.netWorkDuration;
      totalExpected += settings.dailyTargetDuration;
    }
    
    return totalWorked - totalExpected;
  }
}