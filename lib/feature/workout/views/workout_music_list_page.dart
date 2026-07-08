import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_view_model.dart';

class WorkoutMusicListPage extends StatelessWidget {
  static const String routeName = WorkoutRouteTable.pathMusicList;

  const WorkoutMusicListPage({super.key});

  WorkoutTrackingViewModel get _controller =>
      Get.isRegistered<WorkoutTrackingViewModel>()
      ? Get.find<WorkoutTrackingViewModel>()
      : Get.put(WorkoutTrackingViewModel());

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: WorkoutResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _WorkoutMusicListBackground()),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTopNavigationBar(
                    title: WorkoutResource.musicListTitle,
                    onBack: _back,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Obx(() {
                    final tracks = controller.musicTracks;
                    if (tracks.isEmpty) {
                      return _MusicListEmptyState(
                        onImport: controller.importMusic,
                      );
                    }
                    return GlassCard(
                      radius: AppRadius.xl,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < tracks.length; i++)
                            _MusicListRow(
                              key: ValueKey('music-${tracks[i].name}-$i'),
                              name: tracks[i].name,
                              current: tracks[i].current,
                              playing:
                                  tracks[i].current &&
                                  controller.musicPlaying.value,
                              showDivider: i != tracks.length - 1,
                              onTap: () => controller.playMusicAt(i),
                              onDelete: () => controller.deleteMusicAt(i),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MusicListRow extends StatefulWidget {
  final String name;
  final bool current;
  final bool playing;
  final bool showDivider;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  const _MusicListRow({
    super.key,
    required this.name,
    required this.current,
    required this.playing,
    required this.showDivider,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_MusicListRow> createState() => _MusicListRowState();
}

class _MusicListRowState extends State<_MusicListRow> {
  static const double _rowHeight = 62;
  static const double _deleteActionWidth = 52;

  double _dragOffset = 0;
  bool _deleting = false;

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(
        -_deleteActionWidth,
        0,
      );
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final shouldOpen =
        _dragOffset.abs() > _deleteActionWidth * 0.42 ||
        details.primaryVelocity != null && details.primaryVelocity! < -220;
    setState(() {
      _dragOffset = shouldOpen ? -_deleteActionWidth : 0;
    });
  }

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() => _deleting = true);
    try {
      await widget.onDelete();
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  void _tapRow() {
    if (_dragOffset < 0) {
      setState(() => _dragOffset = 0);
      return;
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRect(
          child: SizedBox(
            height: _rowHeight,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Positioned(
                  right: 0,
                  width: _deleteActionWidth,
                  top: 10,
                  bottom: 10,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 170),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.translationValues(
                      _deleteActionWidth + _dragOffset,
                      0,
                      0,
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _delete,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          color: AppColors.accentPink.withValues(alpha: 0.92),
                        ),
                        child: Icon(
                          _deleting
                              ? Icons.hourglass_empty_rounded
                              : Icons.delete_rounded,
                          color: AppColors.white,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 170),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.translationValues(_dragOffset, 0, 0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _tapRow,
                      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                      onHorizontalDragEnd: _handleHorizontalDragEnd,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCardBottom.withValues(
                            alpha: 0.01,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                color: widget.current
                                    ? AppColors.brandGreen.withValues(
                                        alpha: 0.2,
                                      )
                                    : AppColors.surfaceIcon.withValues(
                                        alpha: 0.72,
                                      ),
                              ),
                              child: Icon(
                                widget.playing
                                    ? Icons.equalizer_rounded
                                    : Icons.music_note_rounded,
                                color: widget.current
                                    ? AppColors.brandGreen
                                    : AppColors.textSecondary,
                                size: 22,
                              ),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                widget.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: widget.current
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontSize: 16,
                                  fontWeight: widget.current
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (widget.current)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.brandGreen,
                                size: 20,
                              ),
                            SizedBox(width: AppSpacing.sm),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.showDivider)
          Padding(
            padding: EdgeInsetsDirectional.only(start: 38 + AppSpacing.md),
            child: Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}

class _MusicListEmptyState extends StatelessWidget {
  final VoidCallback onImport;

  const _MusicListEmptyState({required this.onImport});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(
            Icons.library_music_outlined,
            color: AppColors.textSecondary,
            size: 44,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            WorkoutResource.musicListEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          SizedBox(height: AppSpacing.xl),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onImport,
            child: Container(
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.full),
                color: AppColors.brandGreen,
              ),
              child: Text(
                WorkoutResource.trackingImportMusic,
                style: TextStyle(
                  color: AppColors.bgPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutMusicListBackground extends StatelessWidget {
  const _WorkoutMusicListBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgPrimary,
            AppColors.bgRadialBlue.withValues(alpha: 0.72),
            AppColors.bgPrimary,
          ],
        ),
      ),
    );
  }
}
