import 'package:flutter/material.dart';
import '../providers/time_tracking_provider.dart';
import '../theme/bundesbank_theme.dart';

class TimeDisplayCard extends StatelessWidget {
  final TimeTrackingProvider provider;

  const TimeDisplayCard({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BundesbankColors.bundesbankBlue,
              BundesbankColors.bundesbankBlue.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                'Arbeitszeit heute',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: BundesbankColors.backgroundWhite.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                provider.formatDuration(provider.currentNetDuration),
                style: theme.textTheme.displayLarge?.copyWith(
                  color: BundesbankColors.backgroundWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 64,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '(Brutto: ${provider.formatDuration(provider.currentWorkDuration)})',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: BundesbankColors.backgroundWhite.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEditableTimeInfo(
                    context,
                    'Arbeitsbeginn',
                    provider.currentWorkDay != null
                        ? provider.formatTime(provider.currentWorkDay!.startTime)
                        : '--:--',
                    () => _showTimePicker(context, provider),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: BundesbankColors.backgroundWhite.withValues(alpha: 0.3),
                  ),
                  _buildTimeInfo(
                    context,
                    'Erwartetes Ende',
                    _calculateExpectedEndTime(provider),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(BuildContext context, String label, String time) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: BundesbankColors.backgroundWhite.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: BundesbankColors.backgroundWhite,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildEditableTimeInfo(BuildContext context, String label, String time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BundesbankColors.backgroundWhite.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.edit,
                  size: 14,
                  color: BundesbankColors.backgroundWhite.withValues(alpha: 0.7),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: BundesbankColors.backgroundWhite,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateExpectedEndTime(TimeTrackingProvider provider) {
    if (provider.currentWorkDay == null) return '--:--';
    
    final expectedWorkDuration = provider.dailyTarget + provider.currentBreakDuration;
    final expectedEndTime = provider.currentWorkDay!.startTime.add(expectedWorkDuration);
    
    if (expectedEndTime.hour >= 20) {
      return '20:00';
    }
    
    return provider.formatTime(expectedEndTime);
  }

  Future<void> _showTimePicker(BuildContext context, TimeTrackingProvider provider) async {
    if (provider.currentWorkDay == null) return;
    
    final currentTime = provider.currentWorkDay!.startTimeOfDay;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: BundesbankColors.backgroundWhite,
              hourMinuteColor: BundesbankColors.lightGray,
              hourMinuteTextColor: BundesbankColors.bundesbankBlue,
              dayPeriodColor: BundesbankColors.lightGray,
              dayPeriodTextColor: BundesbankColors.bundesbankBlue,
              dialHandColor: BundesbankColors.bundesbankBlue,
              dialBackgroundColor: BundesbankColors.lightGray,
              dialTextColor: BundesbankColors.textBlack,
              entryModeIconColor: BundesbankColors.bundesbankBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != currentTime) {
      try {
        final now = DateTime.now();
        final newStartTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        
        await provider.updateStartTime(newStartTime);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Arbeitsbeginn auf ${provider.formatTime(newStartTime)} geändert'),
              backgroundColor: BundesbankColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: BundesbankColors.errorRed,
            ),
          );
        }
      }
    }
  }
}