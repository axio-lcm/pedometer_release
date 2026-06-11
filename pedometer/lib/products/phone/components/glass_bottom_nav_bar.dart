import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';

/// 三栏玻璃胶囊底部导航：首页选中态为绿色胶囊。
class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const GlassBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  static const _icons = [Icons.home_rounded, Icons.directions_run_rounded, Icons.person_rounded];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      // heightFactor: 1.0 让其在垂直方向收缩包裹（否则在 bottomNavigationBar
      // 的有界约束下会撑满高度，导致胶囊被垂直居中到屏幕中部）。
      child: Center(
        heightFactor: 1.0,
        child: Container(
          margin: EdgeInsets.only(bottom: AppSpacing.lg),
          width: 300,
          height: 62,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: const Color(0xDB030F14),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.strokeCard),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < _icons.length; i++)
                Expanded(child: _item(i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final selected = i == currentIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(i),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 64 : 44,
          height: 44,
          decoration: selected
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.brandGreenLight, AppColors.brandGreen],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: [
                    BoxShadow(color: AppColors.brandGreen.withValues(alpha: 0.4), blurRadius: 14),
                  ],
                )
              : null,
          child: Icon(
            _icons[i],
            size: 24,
            color: selected ? AppColors.bgPrimary : const Color(0xB3A5A5A5),
          ),
        ),
      ),
    );
  }
}
