import 'package:flutter/material.dart';
import 'package:revengi/utils/platform.dart';

class AnalysisCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const AnalysisCard({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final card = Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color:
                    isDarkMode
                        ? Theme.of(context).primaryColorLight
                        : Theme.of(context).primaryColorDark,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    if (isWeb()) {
      return Center(child: SizedBox(width: 300, height: 200, child: card));
    } else if (isWindows()) {
      return Center(child: SizedBox(width: 300, height: 200, child: card));
    } else if (isLinux()) {
      return Center(child: SizedBox(width: 300, height: 200, child: card));
    } else {
      return card;
    }
  }
}
