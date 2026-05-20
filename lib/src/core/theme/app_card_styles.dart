import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Professional card decoration system.
/// Provides consistent, layered card styles across the app.
class AppCardStyles {
  AppCardStyles._();

  // ── SHADOWS ──────────────────────────────────────────
  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: const Color(0xFF1F2937).withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFF1F2937).withValues(alpha: 0.06),
      offset: const Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: const Color(0xFF1F2937).withValues(alpha: 0.05),
      offset: const Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: const Color(0xFF1F2937).withValues(alpha: 0.06),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0xFF1F2937).withValues(alpha: 0.06),
      offset: const Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: const Color(0xFF1F2937).withValues(alpha: 0.05),
      offset: const Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> coloredShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.2),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.08),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];

  // ── CARD DECORATIONS ─────────────────────────────────

  /// Default flat card — clean white, subtle border
  static BoxDecoration get flat => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFF1F3F5), width: 1),
  );

  /// Subtle raised card — white + soft shadow (most common)
  static BoxDecoration get raised => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(14),
    boxShadow: subtleShadow,
  );

  /// Elevated card — more depth for key sections
  static BoxDecoration get elevated => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: mediumShadow,
  );

  /// Hero card — highest emphasis
  static BoxDecoration get hero => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    boxShadow: elevatedShadow,
  );

  /// Glass card — frosted glass effect
  static BoxDecoration glass({Color? tint}) => BoxDecoration(
    color: (tint ?? Colors.white).withValues(alpha: 0.75),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Accent left border card  
  static BoxDecoration accentLeft(Color color) => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: subtleShadow,
    border: Border(
      left: BorderSide(color: color, width: 3.5),
      top: BorderSide(color: const Color(0xFFF1F3F5), width: 0.5),
      right: BorderSide(color: const Color(0xFFF1F3F5), width: 0.5),
      bottom: BorderSide(color: const Color(0xFFF1F3F5), width: 0.5),
    ),
  );

  /// Stat card with colored top accent
  static BoxDecoration statCard(Color color) => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(14),
    boxShadow: subtleShadow,
    border: Border(
      top: BorderSide(color: color, width: 3),
      left: BorderSide(color: const Color(0xFFF1F3F5), width: 0.5),
      right: BorderSide(color: const Color(0xFFF1F3F5), width: 0.5),
      bottom: BorderSide(color: const Color(0xFFF1F3F5), width: 0.5),
    ),
  );

  /// Gradient card for hero sections
  static BoxDecoration gradient(List<Color> colors) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ),
    borderRadius: BorderRadius.circular(18),
    boxShadow: coloredShadow(colors.first),
  );

  /// Soft tinted card  
  static BoxDecoration tinted(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: color.withValues(alpha: 0.12), width: 1),
  );

  /// Interactive / hoverable card
  static BoxDecoration interactive({bool isHovered = false}) => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(14),
    boxShadow: isHovered ? mediumShadow : subtleShadow,
    border: Border.all(
      color: isHovered ? AppColors.primary.withValues(alpha: 0.2) : const Color(0xFFF1F3F5),
      width: isHovered ? 1.5 : 1,
    ),
  );

  // ── GRADIENT PRESETS ─────────────────────────────────
  static const List<Color> primaryGradient = [Color(0xFF2C5282), Color(0xFF1A365D)];
  static const List<Color> blueGradient = [Color(0xFF3B82F6), Color(0xFF1D4ED8)];
  static const List<Color> emeraldGradient = [Color(0xFF10B981), Color(0xFF059669)];
  static const List<Color> sunsetGradient = [Color(0xFFF97316), Color(0xFFEA580C)];
  static const List<Color> violetGradient = [Color(0xFF8B5CF6), Color(0xFF6D28D9)];
  static const List<Color> roseGradient = [Color(0xFFF43F5E), Color(0xFFE11D48)];
  static const List<Color> darkGradient = [Color(0xFF1E293B), Color(0xFF0F172A)];
}

/// Reusable professional stat card widget
class ProStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const ProStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppCardStyles.statCard(color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (subtitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subtitle!,
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Professional section header with subtle styling
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              letterSpacing: -0.2,
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

/// Quick action chip button
class ProActionChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ProActionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<ProActionChip> createState() => _ProActionChipState();
}

class _ProActionChipState extends State<ProActionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withValues(alpha: 0.12) : widget.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? widget.color.withValues(alpha: 0.3) : widget.color.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: widget.color),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
