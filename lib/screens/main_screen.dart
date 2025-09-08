import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/time_tracking_provider.dart';
import '../theme/bundesbank_theme.dart';
import '../widgets/time_display_card.dart';
import '../widgets/progress_indicator_card.dart';
import '../widgets/break_status_card.dart';
import 'settings_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimeTrackingProvider>(
      builder: (context, provider, child) {
        if (!provider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: BundesbankColors.lightGray,
          appBar: AppBar(
            title: const Text(
              'Gleitzeitrechner',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TimeDisplayCard(provider: provider),
                  const SizedBox(height: 16),
                  ProgressIndicatorCard(provider: provider),
                  const SizedBox(height: 16),
                  BreakStatusCard(provider: provider),
                  if (provider.hasReachedDailyLimit) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: BundesbankColors.warningOrange,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning,
                              color: BundesbankColors.backgroundWhite,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tägliche Arbeitszeit von 10 Stunden erreicht!',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: BundesbankColors.backgroundWhite,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}