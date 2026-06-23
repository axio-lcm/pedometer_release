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
                              name: tracks[i].name,
                              current: tracks[i].current,
                              playing:
                                  tracks[i].current &&
                                  controller.musicPlaying.value,
                              showDivider: i != tracks.length - 1,
                              onTap: () => controller.playMusicAt(i),
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

class _MusicListRow extends StatelessWidget {
  final String name;
  final bool current;
  final bool playing;
  final bool showDivider;
  final VoidCallback onTap;

  const _MusicListRow({
    required this.name,
    required this.current,
    required this.playing,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    color: current
                        ? AppColors.brandGreen.withValues(alpha: 0.2)
                        : AppColors.surfaceIcon.withValues(alpha: 0.72),
                  ),
                  child: Icon(
                    playing
                        ? Icons.equalizer_rounded
                        : Icons.music_note_rounded,
                    color: current
                        ? AppColors.brandGreen
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: current
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (current)
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.brandGreen,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
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
