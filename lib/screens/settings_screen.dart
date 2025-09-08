import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/time_tracking_provider.dart';
import '../theme/bundesbank_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _weeklyHoursController;
  late bool _enableMobileWork;
  late double _mobileWorkPercentage;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TimeTrackingProvider>();
    _weeklyHoursController = TextEditingController(
      text: provider.settings.weeklyHours.toString(),
    );
    _enableMobileWork = provider.settings.enableMobileWork;
    _mobileWorkPercentage = provider.settings.mobileWorkPercentage;
  }

  @override
  void dispose() {
    _weeklyHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BundesbankColors.lightGray,
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: Consumer<TimeTrackingProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arbeitszeit',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _weeklyHoursController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Wochenstunden',
                            suffixText: 'Stunden',
                            helperText: 'Standard: 40 Stunden (Vollzeit)',
                            prefixIcon: Icon(
                              Icons.timer,
                              color: BundesbankColors.bundesbankBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: BundesbankColors.bundesbankBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: BundesbankColors.bundesbankBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tägliches Arbeitsziel: ${provider.formatDuration(provider.dailyTarget)} Stunden',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mobiles Arbeiten',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Mobiles Arbeiten aktiviert'),
                          subtitle: const Text('Max. 60% der Arbeitszeit'),
                          value: _enableMobileWork,
                          thumbColor: WidgetStateProperty.all(BundesbankColors.bundesbankBlue),
                          onChanged: (value) {
                            setState(() {
                              _enableMobileWork = value;
                            });
                          },
                        ),
                        if (_enableMobileWork) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Anteil mobiles Arbeiten: ${(_mobileWorkPercentage * 100).toInt()}%',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Slider(
                            value: _mobileWorkPercentage,
                            min: 0.0,
                            max: 0.6,
                            divisions: 12,
                            activeColor: BundesbankColors.bundesbankBlue,
                            label: '${(_mobileWorkPercentage * 100).toInt()}%',
                            onChanged: (value) {
                              setState(() {
                                _mobileWorkPercentage = value;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gleitzeitkontostand',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getBalanceColor(provider.settings.currentBalance)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getBalanceColor(provider.settings.currentBalance)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                provider.settings.currentBalance.isNegative
                                    ? '-${provider.formatDuration(provider.settings.currentBalance.abs())}'
                                    : '+${provider.formatDuration(provider.settings.currentBalance)}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: _getBalanceColor(provider.settings.currentBalance),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Aktueller Kontostand',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: BundesbankColors.darkGray,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (provider.settings.isBalanceInWarningRange()) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: BundesbankColors.warningOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: BundesbankColors.warningOrange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: BundesbankColors.warningOrange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provider.settings.currentBalance.inHours <= -10
                                        ? 'Minusstunden-Grenze erreicht! Vorgesetzter wird informiert.'
                                        : 'Plusstunden-Grenze erreicht! Vorgesetzter wird informiert.',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _saveSettings(context, provider),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Einstellungen speichern',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getBalanceColor(Duration balance) {
    final hours = balance.inHours;
    if (hours < -10 || hours > 20) {
      return BundesbankColors.errorRed;
    } else if (hours < -5 || hours > 15) {
      return BundesbankColors.warningOrange;
    } else if (balance.isNegative) {
      return BundesbankColors.darkGray;
    } else {
      return BundesbankColors.successGreen;
    }
  }

  Future<void> _saveSettings(BuildContext context, TimeTrackingProvider provider) async {
    final weeklyHours = double.tryParse(_weeklyHoursController.text);
    
    if (weeklyHours == null || weeklyHours <= 0 || weeklyHours > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte geben Sie eine gültige Stundenzahl ein (1-60)'),
          backgroundColor: BundesbankColors.errorRed,
        ),
      );
      return;
    }

    final newSettings = provider.settings.copyWith(
      weeklyHours: weeklyHours,
      enableMobileWork: _enableMobileWork,
      mobileWorkPercentage: _mobileWorkPercentage,
    );

    await provider.updateSettings(newSettings);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Einstellungen gespeichert'),
          backgroundColor: BundesbankColors.successGreen,
        ),
      );
      Navigator.pop(context);
    }
  }
}