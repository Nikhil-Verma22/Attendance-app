import 'package:flutter/material.dart';
import '../theme.dart';

class ThreeNumberBar extends StatelessWidget {
  final int totalPlanned;
  final int conducted;
  final int attended;
  final bool isSafe;

  const ThreeNumberBar({
    super.key,
    required this.totalPlanned,
    required this.conducted,
    required this.attended,
    required this.isSafe,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        
        // Graceful defaults to prevent division by zero
        final int planned = totalPlanned <= 0 ? 30 : totalPlanned;
        final int activeConducted = conducted.clamp(0, planned);
        final int activeAttended = attended.clamp(0, activeConducted);

        // Compute fractional ratios
        final double conductedFraction = activeConducted / planned;
        final double attendedFraction = activeAttended / planned;

        // Visual Colors based on safety status
        final Color conductedColor = isSafe 
            ? AppTheme.success.withOpacity(0.3) 
            : AppTheme.error.withOpacity(0.3);
            
        final Color attendedColor = isSafe 
            ? AppTheme.success 
            : AppTheme.error;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bar representation
            Stack(
              children: [
                // 1. Light grey bar representing total planned length
                Container(
                  height: 10.0,
                  width: totalWidth,
                  decoration: BoxDecoration(
                    color: AppTheme.neutralBorder.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                // 2. Muted red/green bar representing conducted portion
                Container(
                  height: 10.0,
                  width: totalWidth * conductedFraction,
                  decoration: BoxDecoration(
                    color: conductedColor,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                // 3. Bright red/green bar representing attended portion
                Container(
                  height: 10.0,
                  width: totalWidth * attendedFraction,
                  decoration: BoxDecoration(
                    color: attendedColor,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            // Legend / Numeric Indicators with responsive compact styling
            () {
              final double screenWidth = MediaQuery.of(context).size.width;
              final bool isCompact = screenWidth < 380;
              final double circleSize = isCompact ? 6.0 : 8.0;
              final double legendSpacing = isCompact ? 8.0 : 12.0;
              final double legendRunSpacing = isCompact ? 2.0 : 4.0;
              final double legendFontSize = isCompact ? 10.0 : 12.0;

              return Wrap(
                spacing: legendSpacing,
                runSpacing: legendRunSpacing,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: const BoxDecoration(
                          color: AppTheme.neutralBorder,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Planned: $planned',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: legendFontSize,
                            ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          color: conductedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Conducted: $conducted',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: legendFontSize,
                            ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          color: attendedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Attended: $attended',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: attendedColor,
                              fontSize: legendFontSize,
                            ),
                      ),
                    ],
                  ),
                ],
              );
            }(),
          ],
        );
      },
    );
  }
}
