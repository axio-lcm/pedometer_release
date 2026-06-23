import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/resource_loader.dart';

/// 运动页模块静态资源（对齐 HomeResource / MainResource 写法）。
class WorkoutResource {
  WorkoutResource._();

  static Color get background => ResourceLoader.color(
    'workout',
    'workout_bg',
    fallbackModule: 'common',
    fallback: AppColors.bgPrimary,
  );

  /// 室内运动无地图，运动区域使用的纯色背景。
  static const indoorBackground = Color(0xFF202935);

  static String get heroTitle => _string('hero_title', WorkoutText.heroTitle);
  static String get heroSubtitle =>
      _string('hero_subtitle', WorkoutText.heroSubtitle);
  static String get startWorkout =>
      _string('start_workout', WorkoutText.startWorkout);
  static String get outdoorRun =>
      _string('outdoor_run', WorkoutText.outdoorRun);
  static String get indoorRun => _string('indoor_run', WorkoutText.indoorRun);
  static String get fitnessWalk =>
      _string('fitness_walk', WorkoutText.fitnessWalk);
  static String get hiking => _string('hiking', WorkoutText.hiking);
  static String get goalKm => _string('goal_km', WorkoutText.goalKm);
  static String get distanceUnit =>
      _string('distance_unit', WorkoutText.distanceUnit);
  static String get goalDuration =>
      _string('goal_duration', WorkoutText.goalDuration);
  static String get durationUnit =>
      _string('duration_unit', WorkoutText.durationUnit);
  static String get goalCalorie =>
      _string('goal_calorie', WorkoutText.goalCalorie);
  static String get freeTraining =>
      _string('free_training', WorkoutText.freeTraining);
  static String get noGoal => _string('no_goal', WorkoutText.noGoal);
  static String get beginnerRunner =>
      _string('beginner_runner', WorkoutText.beginnerRunner);
  static String get persistent => _string('persistent', WorkoutText.persistent);
  static String get hundredKm => _string('hundred_km', WorkoutText.hundredKm);
  static String get trackingEndHint =>
      _string('tracking_end_hint', WorkoutText.trackingEndHint);
  static String get trackingMusicTitle =>
      _string('tracking_music_title', WorkoutText.trackingMusicTitle);
  static String get trackingMusicStatus =>
      _string('tracking_music_status', WorkoutText.trackingMusicStatus);
  static String get trackingMusicPaused =>
      _string('tracking_music_paused', WorkoutText.trackingMusicPaused);
  static String get trackingMusicIdle =>
      _string('tracking_music_idle', WorkoutText.trackingMusicIdle);
  static String get trackingDistanceLabel =>
      _string('tracking_distance_label', WorkoutText.trackingDistanceLabel);
  static String get trackingStartHint =>
      _string('tracking_start_hint', WorkoutText.trackingStartHint);
  static String get metricDistance =>
      _string('metric_distance', WorkoutText.metricDistance);
  static String get metricDuration =>
      _string('metric_duration', WorkoutText.metricDuration);
  static String get metricPace =>
      _string('metric_pace', WorkoutText.metricPace);
  static String get metricCalorieKcal =>
      _string('metric_calorie_kcal', WorkoutText.metricCalorieKcal);
  static String get metricPaceMinKm =>
      _string('metric_pace_min_km', WorkoutText.metricPaceMinKm);
  static String get goalAchievementTitle =>
      _string('goal_achievement_title', WorkoutText.goalAchievementTitle);
  static String get edit => _string('edit', WorkoutText.edit);
  static String get goalAchievementHint =>
      _string('goal_achievement_hint', WorkoutText.goalAchievementHint);
  static String get achievementBadge =>
      _string('achievement_badge', WorkoutText.achievementBadge);
  static String get viewMore => _string('view_more', WorkoutText.viewMore);
  static String get editGoalTitle =>
      _string('edit_goal_title', WorkoutText.editGoalTitle);
  static String get editGoalSubtitle =>
      _string('edit_goal_subtitle', WorkoutText.editGoalSubtitle);
  static String get targetDistance =>
      _string('target_distance', WorkoutText.targetDistance);
  static String get targetDistanceSuggestion => _string(
    'target_distance_suggestion',
    WorkoutText.targetDistanceSuggestion,
  );
  static String get targetDuration =>
      _string('target_duration', WorkoutText.targetDuration);
  static String get targetDurationSuggestion => _string(
    'target_duration_suggestion',
    WorkoutText.targetDurationSuggestion,
  );
  static String get targetCalorie =>
      _string('target_calorie', WorkoutText.targetCalorie);
  static String get targetCalorieSuggestion =>
      _string('target_calorie_suggestion', WorkoutText.targetCalorieSuggestion);
  static String get saveGoal => _string('save_goal', WorkoutText.saveGoal);
  static String get restoreDefault =>
      _string('restore_default', WorkoutText.restoreDefault);
  static String get freeTrainingTip =>
      _string('free_training_tip', WorkoutText.freeTrainingTip);
  static String get goalSuggestionTitle =>
      _string('goal_suggestion_title', WorkoutText.goalSuggestionTitle);
  static String get suggestionDistance =>
      _string('suggestion_distance', WorkoutText.suggestionDistance);
  static String get suggestionDuration =>
      _string('suggestion_duration', WorkoutText.suggestionDuration);
  static String get suggestionCalorie =>
      _string('suggestion_calorie', WorkoutText.suggestionCalorie);
  static String get resultCompleteTitle =>
      _string('result_complete_title', WorkoutText.resultCompleteTitle);
  static String get resultCompleteSubtitle =>
      _string('result_complete_subtitle', WorkoutText.resultCompleteSubtitle);
  static String get resultDone =>
      _string('result_done', WorkoutText.resultDone);
  static String get resultShare =>
      _string('result_share', WorkoutText.resultShare);
  static String get resultSteps =>
      _string('result_steps', WorkoutText.resultSteps);
  static String get resultAvgSpeed =>
      _string('result_avg_speed', WorkoutText.resultAvgSpeed);
  static String get resultElevation =>
      _string('result_elevation', WorkoutText.resultElevation);
  static String get exitConfirmTitle =>
      _string('exit_confirm_title', WorkoutText.exitConfirmTitle);
  static String get exitConfirmMessage =>
      _string('exit_confirm_message', WorkoutText.exitConfirmMessage);
  static String get exitConfirmBack =>
      _string('exit_confirm_back', WorkoutText.exitConfirmBack);
  static String get exitConfirmContinue =>
      _string('exit_confirm_continue', WorkoutText.exitConfirmContinue);
  static String get trackingImportMusic =>
      _string('tracking_import_music', WorkoutText.trackingImportMusic);
  static String get trackingRoute =>
      _string('tracking_route', WorkoutText.trackingRoute);
  static String get musicListTitle =>
      _string('music_list_title', WorkoutText.musicListTitle);
  static String get musicListEmpty =>
      _string('music_list_empty', WorkoutText.musicListEmpty);

  static String trackingTarget(String value) {
    return _string(
      'tracking_target_template',
      WorkoutText.trackingTargetTemplate,
    ).replaceAll('{{value}}', value);
  }

  static String _string(String key, String fallback) {
    return ResourceLoader.string('workout', key, fallback: fallback);
  }
}

/// 运动模块 const 文案。供 const mock / 默认数据使用；动态读取请走 [WorkoutResource]。
class WorkoutText {
  WorkoutText._();

  static const heroTitle = '准备开始今天的训练';
  static const heroSubtitle = '连接 GPS / 开启记录';
  static const startWorkout = '开始运动';
  static const outdoorRun = '户外';
  static const indoorRun = '室内';
  static const fitnessWalk = '健走';
  static const hiking = '徒步';
  static const goalKm = '公里数';
  static const distanceUnit = '公里';
  static const goalDuration = '时长';
  static const durationUnit = '分钟';
  static const goalCalorie = '消耗';
  static const freeTraining = '自由训练';
  static const noGoal = '不设定目标';
  static const freeTrainingOn = '已开启';
  static const beginnerRunner = '初级跑者';
  static const persistent = '坚持不懈';
  static const hundredKm = '百公里';
  static const trackingEndHint = '长按结束';
  static const trackingMusicTitle = '运动音乐';
  static const trackingMusicStatus = '播放中';
  static const trackingMusicPaused = '已暂停';
  static const trackingMusicIdle = '未导入音乐';
  static const trackingDistanceLabel = '累计距离（公里）';
  static const trackingTargetTemplate = '目标 {{value}} 公里';
  static const trackingStartHint = '开始';
  static const metricDistance = '距离';
  static const metricDuration = '时长';
  static const metricPace = '配速';
  static const metricCalorieKcal = '消耗 (kcal)';
  static const metricPaceMinKm = '配速 (min/km)';
  static const goalAchievementTitle = '运动目标与成就';
  static const edit = '编辑';
  static const goalAchievementHint = '达成目标后自动点亮成就徽章';
  static const achievementBadge = '成就徽章';
  static const viewMore = '查看更多';
  static const editGoalTitle = '编辑运动目标';
  static const editGoalSubtitle = '设定目标，激励自己，每天进步一点点';
  static const targetDistance = '目标距离';
  static const targetDistanceSuggestion = '建议 3.00 - 20.00 公里';
  static const targetDuration = '目标时长';
  static const targetDurationSuggestion = '建议 10 - 300 分钟';
  static const targetCalorie = '目标消耗';
  static const targetCalorieSuggestion = '建议 100 - 2000 kcal';
  static const saveGoal = '保存目标';
  static const restoreDefault = '恢复默认';
  static const freeTrainingTip = '开启后将不设定任何目标';
  static const goalSuggestionTitle = '目标建议';
  static const suggestionDistance = '距离：初学者建议 3-5 公里，进阶者 5-10 公里';
  static const suggestionDuration = '时长：建议 30-60 分钟，有助于提升心肺能力';
  static const suggestionCalorie = '消耗：建议 300-600 kcal，保持健康体重';
  static const resultCompleteTitle = '运动完成！';
  static const resultCompleteSubtitle = '太棒了！今天又是坚持运动的一天';
  static const resultDone = '完成';
  static const resultShare = '分享';
  static const resultDate = '2024年5月20日 19:30';
  static const resultSteps = '步数 (步)';
  static const resultAvgSpeed = '平均速度 (km/h)';
  static const resultElevation = '累计爬升 (m)';
  static const exitConfirmTitle = '确认结束本次运动？';
  static const exitConfirmMessage = '运动尚未结束，返回将不会保存本次运动记录。';
  static const exitConfirmBack = '确认返回';
  static const exitConfirmContinue = '继续运动';
  static const trackingImportMusic = '导入音乐';
  static const trackingRoute = '运动轨迹';
  static const musicListTitle = '音乐列表';
  static const musicListEmpty = '暂无音乐，请先导入音乐文件';
}

/// 运动页模块路由定义（对齐 HomeRouteTable 写法）。
class WorkoutRouteTable {
  WorkoutRouteTable._();

  static const String pathEditGoal = '/workout/edit-goal';
  static const String pathTracking = '/workout/tracking';
  static const String pathResult = '/workout/result';
  static const String pathMusicList = '/workout/music-list';
}
