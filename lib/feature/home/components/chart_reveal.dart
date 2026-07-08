import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';

/// 图表入场动画驱动器：挂载即从 0→1 平滑推进一次，供圆环 / 折线「从起点画到终点」。
///
/// [replayKey] 变化时重放（如数据从空变为有值）；不变则只在首次挂载播放一次，
/// 避免实时数据每次微调都重新触发动画。
class ChartRevealBuilder extends StatefulWidget {
  const ChartRevealBuilder({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 1800),
    this.curve = Curves.easeInOutCubic,
    this.replayKey,
  });

  final Widget Function(BuildContext context, double t) builder;
  final Duration duration;
  final Curve curve;
  final Object? replayKey;

  @override
  State<ChartRevealBuilder> createState() => _ChartRevealBuilderState();
}

class _ChartRevealBuilderState extends State<ChartRevealBuilder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ChartRevealBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replayKey != widget.replayKey) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => widget.builder(context, _animation.value),
    );
  }
}

/// 把完整折线 [full] 按进度 [t]（0→1）沿 **x 轴**裁出「从起点画到当前」的点。
///
/// 适用于 x 为任意刻度（如按时间映射）的折线：保留前沿左侧的全部点，再在前沿插值
/// 一个移动笔尖点，得到左→右连续生长的折线；[t] 为 1 返回完整曲线。
List<FlSpot> revealSpots(List<FlSpot> full, double t) {
  final n = full.length;
  if (n == 0) return const <FlSpot>[];
  if (t >= 1 || n == 1) return full;
  final tt = t < 0 ? 0.0 : t;
  final edge = full.first.x + (full.last.x - full.first.x) * tt;
  final spots = <FlSpot>[];
  for (var i = 0; i < n; i++) {
    final spot = full[i];
    if (spot.x <= edge + 1e-9) {
      spots.add(spot);
      continue;
    }
    if (i > 0) {
      final prev = full[i - 1];
      final span = spot.x - prev.x;
      if (span > 1e-9) {
        final frac = (edge - prev.x) / span;
        if (frac > 1e-6) {
          spots.add(FlSpot(edge, prev.y + (spot.y - prev.y) * frac));
        }
      }
    }
    break;
  }
  if (spots.isEmpty) spots.add(full.first);
  return spots;
}

/// 按进度 [t] 裁出索引为 x（0,1,2…）的折线点，前沿插值移动笔尖。
List<FlSpot> revealLineSpots(List<double> values, double t) {
  return revealSpots(
    [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
    t,
  );
}
