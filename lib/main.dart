import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zeiterfassung',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TimeTrackingPage(),
    );
  }
}

class TimeTrackingPage extends StatefulWidget {
  const TimeTrackingPage({super.key});

  @override
  State<TimeTrackingPage> createState() => _TimeTrackingPageState();
}

class _TimeTrackingPageState extends State<TimeTrackingPage> {
  // Konstanten
  static const int workDayStartHour = 6; // Frühester Arbeitsbeginn
  static const int workDayEndHour = 20; // Spätestes Arbeitsende
  static const int maxWorkHoursPerDay = 10; // Maximale Arbeitszeit
  
  // State-Variablen
  DateTime? _startTime;
  Timer? _timer;
  Duration _elapsedWorkTime = Duration.zero;
  Duration _breakTime = Duration.zero;
  Duration _requiredBreakTime = Duration.zero;
  
  // Benutzereinstellungen
  int _weeklyWorkHours = 40; // Standard: Vollzeit 40h
  TimeOfDay _manualStartTime = TimeOfDay(hour: 8, minute: 0);

  // Timer starten
  void _startTimer() {
    // Einfacher Timer zum Aktualisieren der verstrichenen Zeit
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_startTime != null) {
          final now = DateTime.now();
          _elapsedWorkTime = now.difference(_startTime!);
        }
      });
    });
  }

  // Dauer formatieren
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }
  
  // Berechnung des Arbeitsfortschritts in Prozent
  double _calculateWorkdayProgress() {
    // Bei fehlender Startzeit 0% zurückgeben
    if (_startTime == null) return 0.0;
    
    // Berechnung des täglichen Arbeitsstunden-Solls (Wochenstunden / 5)
    final dailyHours = _weeklyWorkHours / 5;
    
    // Fortschritt basierend auf verstrichener Arbeitszeit
    final progress = (_elapsedWorkTime.inMinutes / (dailyHours * 60)) * 100;
    
    // Sicherstellen, dass der Wert zwischen 0 und 100 liegt
    return progress.clamp(0.0, 100.0);
  }

  // Einstellungen-Dialog anzeigen
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Einstellungen'),
        content: const Text('Hier kannst du deine Einstellungen anpassen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zeiterfassung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Nur die Hauptzeitanzeige behalten
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Arbeitszeit heute:', style: TextStyle(fontSize: 18)),
                        Text(
                          _formatDuration(_elapsedWorkTime),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _calculateWorkdayProgress() / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_calculateWorkdayProgress().toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Restlicher Platz für zukünftige Elemente
            Expanded(
              child: Center(
                child: Text(
                  'Aktuelle Zeit: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}