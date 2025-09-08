import 'dart:async';
import 'package:flutter/material.dart';
import '../models/work_day.dart';
import '../models/gleitzeit_settings.dart';
import '../services/storage_service.dart';

class TimeTrackingProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  WorkDay? _currentWorkDay;
  GleitzeitSettings _settings = const GleitzeitSettings();
  Timer? _timer;
  Timer? _autoSaveTimer;
  bool _isInitialized = false;
  
  WorkDay? get currentWorkDay => _currentWorkDay;
  GleitzeitSettings get settings => _settings;
  bool get isInitialized => _isInitialized;
  bool get isTracking => _currentWorkDay != null && _currentWorkDay!.isActive;
  
  Duration get currentWorkDuration => _currentWorkDay?.workDuration ?? Duration.zero;
  Duration get currentNetDuration => _currentWorkDay?.netWorkDuration ?? Duration.zero;
  Duration get currentBreakDuration => _currentWorkDay?.totalBreakDuration ?? Duration.zero;
  Duration get dailyTarget => _settings.dailyTargetDuration;
  Duration get remainingWork {
    final remaining = dailyTarget - currentNetDuration;
    return remaining.isNegative ? Duration.zero : remaining;
  }
  Duration get overtime {
    final over = currentNetDuration - dailyTarget;
    return over.isNegative ? Duration.zero : over;
  }
  
  bool get hasReachedDailyLimit => _currentWorkDay?.hasReachedDailyLimit ?? false;
  bool get requiresBreak => _currentWorkDay?.requiresBreak ?? false;
  bool get requiresExtendedBreak => _currentWorkDay?.requiresExtendedBreak ?? false;
  
  Future<void> initialize() async {
    await _storageService.init();
    await _loadSettings();
    await _loadOrCreateWorkDay();
    _startTimers();
    _isInitialized = true;
    notifyListeners();
  }
  
  Future<void> _loadSettings() async {
    _settings = await _storageService.loadSettings();
    final balance = await _storageService.calculateCurrentBalance();
    _settings = _settings.copyWith(currentBalance: balance);
  }
  
  Future<void> _loadOrCreateWorkDay() async {
    final savedWorkDay = await _storageService.loadCurrentWorkDay();
    
    if (savedWorkDay != null) {
      _currentWorkDay = savedWorkDay;
    } else {
      final now = DateTime.now();
      DateTime startTime = now;
      
      if (now.hour < 6) {
        startTime = DateTime(now.year, now.month, now.day, 6, 0);
      } else if (now.hour >= 20) {
        startTime = DateTime(now.year, now.month, now.day, 19, 59);
      }
      
      _currentWorkDay = WorkDay(
        date: DateTime(now.year, now.month, now.day),
        startTime: startTime,
      );
      
      await _saveCurrentWorkDay();
    }
  }
  
  void _startTimers() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isTracking) {
        notifyListeners();
        
        if (hasReachedDailyLimit) {
          _showDailyLimitNotification();
        }
      }
    });
    
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_currentWorkDay != null) {
        _saveCurrentWorkDay();
      }
    });
  }
  
  Future<void> _saveCurrentWorkDay() async {
    if (_currentWorkDay != null) {
      await _storageService.saveCurrentWorkDay(_currentWorkDay!);
    }
  }
  
  Future<void> updateStartTime(DateTime newStartTime) async {
    if (_currentWorkDay == null) return;
    
    final now = DateTime.now();
    final combinedTime = DateTime(
      _currentWorkDay!.date.year,
      _currentWorkDay!.date.month,
      _currentWorkDay!.date.day,
      newStartTime.hour,
      newStartTime.minute,
    );
    
    if (combinedTime.hour < 6 || combinedTime.hour >= 20) {
      throw Exception('Start time must be between 6:00 and 20:00');
    }
    
    if (combinedTime.isAfter(now)) {
      throw Exception('Start time cannot be in the future');
    }
    
    _currentWorkDay!.startTime = combinedTime;
    await _saveCurrentWorkDay();
    notifyListeners();
  }
  
  Future<void> stopTracking() async {
    if (_currentWorkDay == null) return;
    
    _currentWorkDay!.endTime = DateTime.now();
    _currentWorkDay!.isActive = false;
    
    await _storageService.saveToHistory(_currentWorkDay!);
    await _storageService.clearCurrentWorkDay();
    
    _currentWorkDay = null;
    notifyListeners();
  }
  
  Future<void> updateSettings(GleitzeitSettings newSettings) async {
    _settings = newSettings;
    await _storageService.saveSettings(_settings);
    notifyListeners();
  }
  
  void _showDailyLimitNotification() {
  }
  
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
  
  String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}