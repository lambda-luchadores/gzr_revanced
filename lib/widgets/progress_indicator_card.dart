import 'package:flutter/material.dart';
import '../providers/time_tracking_provider.dart';
import '../theme/bundesbank_theme.dart';

class ProgressIndicatorCard extends StatelessWidget {
  final TimeTrackingProvider provider;

  const ProgressIndicatorCard({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final progress = provider.currentNetDuration.inMinutes /
        provider.dailyTarget.inMinutes;
    final progressClamped = progress.clamp(0.0, 1.5);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tagesfortschritt',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _getProgressColor(progress),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressClamped > 1.0 ? 1.0 : progressClamped,
                minHeight: 24,
                backgroundColor: BundesbankColors.mediumGray,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(progress),
                ),
              ),
            ),
            if (progressClamped > 1.0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (progressClamped - 1.0) * 2,
                  minHeight: 12,
                  backgroundColor: BundesbankColors.mediumGray,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    BundesbankColors.bundesbankGold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Überstunden',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BundesbankColors.bundesbankGold,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeInfo(
                  context,
                  'Verbleibend',
                  provider.formatDuration(provider.remainingWork),
                  BundesbankColors.darkGray,
                ),
                _buildTimeInfo(
                  context,
                  'Tagesziel',
                  provider.formatDuration(provider.dailyTarget),
                  BundesbankColors.bundesbankBlue,
                ),
                if (provider.overtime > Duration.zero)
                  _buildTimeInfo(
                    context,
                    'Überstunden',
                    '+${provider.formatDuration(provider.overtime)}',
                    BundesbankColors.bundesbankGold,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
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

  Color _getProgressColor(double progress) {
    if (progress < 0.9) {
      return BundesbankColors.bundesbankBlue;
    } else if (progress < 1.0) {
      return BundesbankColors.successGreen;
    } else if (progress < 1.25) {
      return BundesbankColors.bundesbankGold;
    } else {
      return BundesbankColors.warningOrange;
    }
  }
}