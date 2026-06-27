import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ConsultaActionItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const ConsultaActionItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });
}

class ConsultaActionBar extends StatelessWidget {
  final List<ConsultaActionItem> items;

  const ConsultaActionBar({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final Color barColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBlue
        : AppColors.lightBlue;
    return Container(
      width: double.infinity,
      color: barColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items
            .map(
              (ConsultaActionItem item) => Expanded(
                child: _buildActionItem(item),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildActionItem(ConsultaActionItem item) {
    return InkWell(
      onTap: item.isLoading ? null : item.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(item.icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
