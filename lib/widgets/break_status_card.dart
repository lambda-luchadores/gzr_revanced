import 'package:flutter/material.dart';
import '../providers/time_tracking_provider.dart';
import '../theme/bundesbank_theme.dart';

class BreakStatusCard extends StatelessWidget {
  final TimeTrackingProvider provider;

  const BreakStatusCard({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pausenstatus',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBreakInfo(
                  context,
                  Icons.coffee,
                  'Automatische Pause',
                  provider.formatDuration(provider.currentBreakDuration),
                  BundesbankColors.bundesbankBlue,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: BundesbankColors.mediumGray,
                ),
                _buildBreakInfo(
                  context,
                  Icons.schedule,
                  'Pausenfenster',
                  '11:15 - 14:30',
                  BundesbankColors.darkGray,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBreakRules(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakInfo(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: BundesbankColors.darkGray,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildBreakRules(BuildContext context) {
    final workDuration = provider.currentWorkDuration;
    final rules = <String>[];
    
    if (workDuration < const Duration(hours: 6)) {
      rules.add('Keine Pause erforderlich (< 6 Stunden)');
    } else if (workDuration < const Duration(hours: 9)) {
      rules.add('30 Minuten Pause (ab 6 Stunden Arbeitszeit)');
    } else {
      rules.add('45 Minuten Pause (ab 9 Stunden Arbeitszeit)');
    }
    
    if (provider.currentWorkDay != null) {
      final now = DateTime.now();
      if (provider.currentWorkDay!.isInBreakWindow(now)) {
        rules.add('Jetzt ist Pausenzeit möglich');
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BundesbankColors.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: BundesbankColors.darkGray,
              ),
              const SizedBox(width: 8),
              Text(
                'Pausenregelung',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: BundesbankColors.darkGray,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rules.map((rule) => Padding(
                padding: const EdgeInsets.only(left: 24, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: BundesbankColors.darkGray,
                          ),
                    ),
                    Expanded(
                      child: Text(
                        rule,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: BundesbankColors.darkGray,
                            ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (!provider.requiresBreak) {
      return BundesbankColors.successGreen;
    }
    
    if (provider.currentWorkDay != null) {
      final now = DateTime.now();
      if (provider.currentWorkDay!.isInBreakWindow(now)) {
        return BundesbankColors.bundesbankGold;
      }
    }
    
    if (provider.requiresExtendedBreak) {
      return BundesbankColors.warningOrange;
    }
    
    return BundesbankColors.bundesbankBlue;
  }

  String _getStatusText() {
    if (!provider.requiresBreak) {
      return 'Keine Pause nötig';
    }
    
    if (provider.requiresExtendedBreak) {
      return '45 Min Pause';
    }
    
    return '30 Min Pause';
  }
}