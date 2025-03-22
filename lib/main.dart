import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
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
      title: 'GleitZeitRechner Revanced',
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
  // Zeiterfassung Konfiguration
  static const int workDayStartHour = 6; // Frühester Arbeitsbeginn
  static const int workDayEndHour = 20; // Spätestes Arbeitsende
  static const int maxWorkHoursPerDay = 10; // Maximale Arbeitszeit ohne Pausen
  
  // Aktuelle Zeiten
  DateTime? _startTime = DateTime.now();
  Timer? _timer;
  Duration _elapsedWorkTime = Duration.zero;
  Duration _breakTime = Duration.zero;
  Duration _requiredBreakTime = Duration.zero;
  
  // Benutzereinstellungen
  int _weeklyWorkHours = 39; // Standard: Vollzeit 40h
  TimeOfDay _manualStartTime = TimeOfDay(hour: 8, minute: 0); // Standardwert: 8:00 Uhr

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Benutzereinstellungen laden
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _weeklyWorkHours = prefs.getInt('weeklyWorkHours') ?? 39;
      
      // Gespeicherten Dienstbeginn laden (falls vorhanden)
      final savedHour = prefs.getInt('startTimeHour');
      final savedMinute = prefs.getInt('startTimeMinute');
      if (savedHour != null && savedMinute != null) {
        _manualStartTime = TimeOfDay(hour: savedHour, minute: savedMinute);
      }
    });
  }

  // Benutzereinstellungen speichern
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('weeklyWorkHours', _weeklyWorkHours);
    await prefs.setInt('startTimeHour', _manualStartTime.hour);
    await prefs.setInt('startTimeMinute', _manualStartTime.minute);
  }
  
  // Prüfen, ob manuelle Startzeit verwendet werden soll
  bool _useManualStartTime() {
    final now = TimeOfDay.now();
    
    // Wenn die aktuelle Zeit zu weit von der manuellen Startzeit entfernt ist
    // (mehr als 10 Minuten), dann manuelle Startzeit verwenden
    int currentMinutes = now.hour * 60 + now.minute;
    int manualMinutes = _manualStartTime.hour * 60 + _manualStartTime.minute;
    
    int diff = (currentMinutes - manualMinutes).abs();
    return diff > 10;
  }

  // Timer starten und aktualisieren
  void _startTimer() {
    // Startzeit basierend auf manueller Einstellung oder aktueller Zeit setzen
    if (_startTime == null) {
      final now = DateTime.now();
      
      // Manuelle Startzeit oder aktuelle Zeit verwenden
      if (_useManualStartTime()) {
        _startTime = DateTime(
          now.year, now.month, now.day, 
          _manualStartTime.hour, 
          _manualStartTime.minute
        );
        
        // Falls die manuelle Startzeit in der Zukunft liegt, auf aktuelle Zeit setzen
        if (_startTime!.isAfter(now)) {
          _startTime = now;
        }
      } else {
        _startTime = now;
      }
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return; // Überprüfen, ob das Widget noch montiert ist
      setState(() {
        if (_startTime == null) return; // Sicherheitscheck
        
        final now = DateTime.now();
        _elapsedWorkTime = now.difference(_startTime!);
        
        // Pausenberechnung
        final elapsedHours = _elapsedWorkTime.inMinutes / 60;
        
        if (elapsedHours >= 9) {
          // Nach 9 Stunden: 30 + 15 = 45 Minuten Pause
          _requiredBreakTime = const Duration(minutes: 45);
        } else if (elapsedHours >= 6) {
          // Nach 6 Stunden: 30 Minuten Pause
          _requiredBreakTime = const Duration(minutes: 30);
        } else {
          _requiredBreakTime = Duration.zero;
        }
        
        // Aktuelle Pausenzeit berechnen (nur nach 6 Stunden)
        if (elapsedHours >= 6) {
          final minutesOver6h = (_elapsedWorkTime.inMinutes - (6 * 60));
          _breakTime = Duration(minutes: minutesOver6h < 30 ? minutesOver6h : 30);
          
          // Zusätzliche 15 Minuten Pause nach 9 Stunden
          if (elapsedHours >= 9) {
            final minutesOver9h = (_elapsedWorkTime.inMinutes - (9 * 60));
            _breakTime += Duration(minutes: minutesOver9h < 15 ? minutesOver9h : 15);
          }
        }
      });
    });
  }

  // Berechnung des Arbeitsfortschritts in Prozent
  double _calculateWorkdayProgress() {
    // Bei fehlender Startzeit 0% zurückgeben
    if (_startTime == null) return 0.0;
    
    // Berechnung des täglichen Arbeitsstunden-Solls (Wochenstunden / 5)
    final dailyHours = _weeklyWorkHours / 5;
    
    // Fortschritt basierend auf verstrichener Arbeitszeit (ohne Pausen)
    final effectiveWorkTime = _elapsedWorkTime - _breakTime;
    final progress = (effectiveWorkTime.inMinutes / (dailyHours * 60)) * 100;
    
    // Sicherstellen, dass der Wert nicht negativ oder NaN ist
    return progress.isNaN || progress < 0 ? 0.0 : progress;
  }

  // Berechnung der frühesten Endzeit
  DateTime _calculateEarliestEndTime() {
    // Berechnung des täglichen Arbeitsstunden-Solls (Wochenstunden / 5)
    final dailyHours = _weeklyWorkHours / 5;
    
    // Früheste Endzeit = Startzeit + tägliche Sollzeit + Pausenzeit
    if (_startTime == null) return DateTime.now(); // Fallback
    
    return _startTime!.add(Duration(minutes: (dailyHours * 60).round()))
                     .add(_requiredBreakTime);
  }

  // Berechnung der spätesten Endzeit (10-Stunden-Limit)
  DateTime _calculateLatestEndTime() {
    // Späteste Endzeit = Startzeit + 10 Stunden + Pausenzeit
    if (_startTime == null) return DateTime.now(); // Fallback
    
    return _startTime!.add(const Duration(hours: maxWorkHoursPerDay))
                     .add(_requiredBreakTime);
  }

  @override
  Widget build(BuildContext context) {
    // Sicherstellen, dass die App nicht abstürzt, wenn keine Startzeit vorhanden ist
    if (_startTime == null) {
      _startTimer(); // Timer starten, falls noch nicht geschehen
    }
    
    final workdayProgress = _calculateWorkdayProgress();
    final effectiveWorkTime = _elapsedWorkTime - _breakTime;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GleitZeitRechner Revanced',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hauptzeitanzeige
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
                          _formatDuration(effectiveWorkTime),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: workdayProgress / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${workdayProgress.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Dienst- und Pauseninformationen
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Dienstbeginn:', style: TextStyle(fontSize: 16)),
                        Text(
                          _startTime != null 
                            ? DateFormat('HH:mm').format(_startTime!) 
                            : '--:--',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pausenzeit:', style: TextStyle(fontSize: 16)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_formatDuration(_breakTime)} / ${_formatDuration(_requiredBreakTime)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${(_breakTime.inMinutes * 100 / (_requiredBreakTime.inMinutes == 0 ? 1 : _requiredBreakTime.inMinutes)).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: _requiredBreakTime > Duration.zero && _breakTime < _requiredBreakTime 
                                  ? Colors.red 
                                  : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Zeitinfos
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Früheste Endzeit:', style: TextStyle(fontSize: 16)),
                        Text(
                          _startTime != null 
                            ? DateFormat('HH:mm').format(_calculateEarliestEndTime()) 
                            : '--:--',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Späteste Endzeit:', style: TextStyle(fontSize: 16)),
                        Text(
                          _startTime != null 
                            ? DateFormat('HH:mm').format(_calculateLatestEndTime())
                            : '--:--',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Arbeitszeitrahmen-Visualisierung
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Arbeitszeitrahmen (6:00 - 20:00):', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: WorkdayTimelinePainter(
                          startTime: _startTime,
                          currentTime: DateTime.now(),
                          earliestEndTime: _startTime != null ? _calculateEarliestEndTime() : null,
                          latestEndTime: _startTime != null ? _calculateLatestEndTime() : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Formatiert Dauer in lesbares Format
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }

  // Dialog für Einstellungen
  void _showSettingsDialog() {
    int tempWeeklyHours = _weeklyWorkHours;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Einstellungen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Wöchentliche Arbeitszeit:'),
            DropdownButton<int>(
              value: tempWeeklyHours,
              items: [39, 40].map((hours) {
                return DropdownMenuItem<int>(
                  value: hours,
                  child: Text('$hours Stunden'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  tempWeeklyHours = value;
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dienstbeginn:'),
                TextButton(
                  onPressed: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: _manualStartTime,
                    );
                    if (picked != null) {
                      setState(() {
                        _manualStartTime = picked;
                      });
                    }
                  },
                  child: Text(_manualStartTime.format(context)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _weeklyWorkHours = tempWeeklyHours;
                _saveSettings();
              });
              Navigator.pop(context);
              
              // Dialog zum Neustarten der Zeitmessung anzeigen
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Zeitmessung neu starten?'),
                    content: const Text(
                      'Möchtest du die Zeitmessung mit dem neuen '
                      'Dienstbeginn neu starten?'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Nein'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _startTime = null;
                            _elapsedWorkTime = Duration.zero;
                            _breakTime = Duration.zero;
                            _requiredBreakTime = Duration.zero;
                            _timer?.cancel();
                            _timer = null;
                          });
                          _startTimer();
                          Navigator.pop(context);
                        },
                        child: const Text('Ja'),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}

// Custom Painter für Zeitverlauf-Visualisierung
class WorkdayTimelinePainter extends CustomPainter {
  final DateTime? startTime;
  final DateTime currentTime;
  final DateTime? earliestEndTime;
  final DateTime? latestEndTime;
  
  static const workdayStartHour = 6;  // 6:00 Uhr
  static const workdayEndHour = 20;   // 20:00 Uhr
  static const totalWorkdayMinutes = (workdayEndHour - workdayStartHour) * 60;
  
  WorkdayTimelinePainter({
    required this.startTime,
    required this.currentTime,
    this.earliestEndTime,
    this.latestEndTime,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    
    // Hintergrund des Zeitstrahls zeichnen
    final Paint backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height / 3), 
        const Radius.circular(4)
      ),
      backgroundPaint
    );
    
    // Funktionszeit (9-15 Uhr) markieren - 180 bis 540 Minuten nach 6 Uhr
    final Paint functionalTimePaint = Paint()
      ..color = Colors.blue.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    
    final functionalTimeStartX = (180 / totalWorkdayMinutes) * width;
    final functionalTimeWidth = ((540 - 180) / totalWorkdayMinutes) * width;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(functionalTimeStartX, 0, functionalTimeWidth, height / 3),
        const Radius.circular(0)
      ),
      functionalTimePaint
    );
    
    // Pausenzeit (11:15-14:30) markieren - 315 bis 510 Minuten nach 6 Uhr
    final Paint breakTimePaint = Paint()
      ..color = Colors.orange.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    
    final breakStartX = (315 / totalWorkdayMinutes) * width;
    final breakWidth = ((510 - 315) / totalWorkdayMinutes) * width;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(breakStartX, 0, breakWidth, height / 3),
        const Radius.circular(0)
      ),
      breakTimePaint
    );
    
    // Zeitmarkierungen (Stunden)
    final Paint timeLabelPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1;
      
    final TextStyle textStyle = TextStyle(
      color: Colors.black87,
      fontSize: 10,
    );
    
    // Jede zweite Stunde markieren
    for (int hour = workdayStartHour; hour <= workdayEndHour; hour += 2) {
      final minutesFromStart = (hour - workdayStartHour) * 60;
      final xPos = (minutesFromStart / totalWorkdayMinutes) * width;
      
      // Vertikale Linie zeichnen
      canvas.drawLine(
        Offset(xPos, 0),
        Offset(xPos, height / 3),
        timeLabelPaint
      );
      
      // Stundentext - direkt mit Canvas zeichnen statt TextPainter
      final String timeText = '$hour:00';
      final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(textAlign: ui.TextAlign.center, fontSize: 10.0)
      )
        ..pushStyle(ui.TextStyle(color: Colors.black87))
        ..addText(timeText);
      
      final ui.Paragraph paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: 50));
      
      canvas.drawParagraph(
        paragraph, 
        Offset(xPos - paragraph.width / 2, height / 3 + 2)
      );
    }
    
    // Wenn keine Startzeit vorhanden ist, nur Grundlegende Anzeige darstellen
    if (startTime == null) return;
    
    try {
      // Zeitpunkte in Minuten seit 6 Uhr umrechnen
      final int startTimeMinutes = _getMinutesSince6am(startTime!);
      final int currentTimeMinutes = _getMinutesSince6am(currentTime);
      final int? earliestEndMinutes = earliestEndTime != null ? _getMinutesSince6am(earliestEndTime!) : null;
      final int? latestEndMinutes = latestEndTime != null ? _getMinutesSince6am(latestEndTime!) : null;
      
      // Aktuellen Fortschritt zeichnen
      if (startTimeMinutes <= currentTimeMinutes) {
        final Paint progressPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;
        
        final startX = (startTimeMinutes / totalWorkdayMinutes) * width;
        final progressWidth = ((currentTimeMinutes - startTimeMinutes) / totalWorkdayMinutes) * width;
        
        if (progressWidth > 0 && progressWidth.isFinite) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(startX, 0, progressWidth, height / 3),
              const Radius.circular(0)
            ),
            progressPaint
          );
        }
      }
      
      // Start- und Endzeit-Marker
      final Paint markerPaint = Paint()
        ..strokeWidth = 2;
        
      // Startzeit
      if (startTimeMinutes >= 0 && startTimeMinutes <= totalWorkdayMinutes) {
        markerPaint.color = Colors.green;
        final startX = (startTimeMinutes / totalWorkdayMinutes) * width;
        _drawTimeMarker(canvas, startX, height, markerPaint, 'Start');
      }
      
      // Aktuelle Zeit
      if (currentTimeMinutes >= 0 && currentTimeMinutes <= totalWorkdayMinutes) {
        markerPaint.color = Colors.blue;
        final currentX = (currentTimeMinutes / totalWorkdayMinutes) * width;
        _drawTimeMarker(canvas, currentX, height, markerPaint, 'Jetzt');
      }
      
      // Früheste Endzeit
      if (earliestEndMinutes != null && earliestEndMinutes >= 0 && earliestEndMinutes <= totalWorkdayMinutes) {
        markerPaint.color = Colors.orange;
        final earliestEndX = (earliestEndMinutes / totalWorkdayMinutes) * width;
        _drawTimeMarker(canvas, earliestEndX, height, markerPaint, 'Frühest');
      }
      
      // Späteste Endzeit
      if (latestEndMinutes != null && latestEndMinutes >= 0 && latestEndMinutes <= totalWorkdayMinutes) {
        markerPaint.color = Colors.red;
        final latestEndX = (latestEndMinutes / totalWorkdayMinutes) * width;
        _drawTimeMarker(canvas, latestEndX, height, markerPaint, 'Spätest');
      }
    } catch (e) {
      // Fehlerbehandlung - falls es zu Ausnahmen bei der Zeichnung kommt
      print('Fehler beim Zeichnen der Zeitleiste: $e');
    }
  }
  
  void _drawTimeMarker(Canvas canvas, double xPos, double height, Paint paint, String label) {
    // Überprüfen, ob die Position gültig ist
    if (xPos.isNaN || xPos.isInfinite) return;
    
    // Vertikale Linie
    canvas.drawLine(
      Offset(xPos, 0),
      Offset(xPos, height),
      paint
    );
    
    // Marker-Punkt
    canvas.drawCircle(
      Offset(xPos, height / 1.5),
      4,
      paint
    );
    
    // Label - direkt mit Canvas zeichnen statt TextPainter
    final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: ui.TextAlign.center, 
        fontSize: 10.0,
        fontWeight: ui.FontWeight.bold,
      )
    )
      ..pushStyle(ui.TextStyle(color: paint.color))
      ..addText(label);
    
    final ui.Paragraph paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: 50));
    
    canvas.drawParagraph(
      paragraph, 
      Offset(xPos - paragraph.width / 2, height - paragraph.height)
    );
  }
  
  int _getMinutesSince6am(DateTime time) {
    // Sicherstellen, dass die Stunde nicht kleiner als die Anfangsstunde ist
    int hoursSince6 = time.hour - workdayStartHour;
    if (hoursSince6 < 0) hoursSince6 = 0;
    return hoursSince6 * 60 + time.minute;
  }
  
  @override
  bool shouldRepaint(covariant WorkdayTimelinePainter oldDelegate) {
    return oldDelegate.startTime != startTime ||
           oldDelegate.currentTime != currentTime ||
           oldDelegate.earliestEndTime != earliestEndTime ||
           oldDelegate.latestEndTime != latestEndTime;
  }
}
