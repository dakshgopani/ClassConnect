import 'package:flutter/material.dart';

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  const BreadcrumbItem({
    required this.label,
    this.onTap,
    this.icon,
  });
}

typedef CCBreadcrumbItem = BreadcrumbItem;

class CCBreadcrumbBar extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final VoidCallback? onBack;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? trailing;
  final String? badgeText;

  const CCBreadcrumbBar({
    super.key,
    required this.items,
    this.onBack,
    this.subtitle,
    this.actions,
    this.trailing,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 22),
            onPressed: onBack ?? () => Navigator.pop(context),
            tooltip: 'Back',
            hoverColor: const Color(0xFFF1F5F9),
            splashRadius: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._buildBreadcrumbList(context),
                      if (badgeText != null && badgeText!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            badgeText!,
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildBreadcrumbList(BuildContext context) {
    final widgets = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;

      final itemWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.icon != null) ...[
            Icon(
              item.icon,
              size: 15,
              color: isLast
                  ? const Color(0xFF0F172A)
                  : (item.onTap != null ? const Color(0xFF3B82F6) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            item.label,
            style: TextStyle(
              color: isLast
                  ? const Color(0xFF0F172A)
                  : (item.onTap != null ? const Color(0xFF3B82F6) : const Color(0xFF64748B)),
              fontSize: isLast ? 16 : 14,
              fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: isLast ? -0.2 : 0,
            ),
          ),
        ],
      );

      if (isLast) {
        widgets.add(itemWidget);
      } else {
        widgets.add(
          MouseRegion(
            cursor: item.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: item.onTap,
              child: itemWidget,
            ),
          ),
        );
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '/',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}
