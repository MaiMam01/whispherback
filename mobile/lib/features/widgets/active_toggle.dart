import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ActiveToggle extends StatefulWidget {
  const ActiveToggle({
    super.key,
    required this.isActive,
    required this.onToggle,
  });

  final bool isActive;
  final VoidCallback onToggle;

  @override
  State<ActiveToggle> createState() => _ActiveToggleState();
}

class _ActiveToggleState extends State<ActiveToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (widget.isActive) _controller.value = 1;
  }

  @override
  void didUpdateWidget(ActiveToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.reverse(from: 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final glow = widget.isActive
              ? BoxShadow(
                  color: AppColors.brandLight.withValues(alpha: 0.55),
                  blurRadius: 32,
                  spreadRadius: 4,
                )
              : null;
          return Transform.rotate(
            angle: _controller.value * 0.25 * 3.14159,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isActive ? AppColors.brand : AppColors.card,
                border: Border.all(
                  color: widget.isActive ? AppColors.brandLight : AppColors.muted,
                  width: 3,
                ),
                boxShadow: glow != null ? [glow] : null,
              ),
              child: Icon(
                Icons.power_settings_new,
                size: 64,
                color: widget.isActive ? Colors.white : AppColors.muted,
              ),
            ),
          );
        },
      ),
    );
  }
}
