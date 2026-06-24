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
  static String get freeTrainingOn =>
      _string('free_training_on', WorkoutText.freeTrainingOn);
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
  static String get routeHistoryTitle =>
      _string('route_history_title', WorkoutText.routeHistoryTitle);
  static String get routeHistoryDetailTitle => _string(
    'route_history_detail_title',
    WorkoutText.routeHistoryDetailTitle,
  );
  static String get routeHistoryCurrent =>
      _string('route_history_current', WorkoutText.routeHistoryCurrent);
  static String get routeHistoryRecording =>
      _string('route_history_recording', WorkoutText.routeHistoryRecording);
  static String get routeHistoryEmpty =>
      _string('route_history_empty', WorkoutText.routeHistoryEmpty);
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

  static String localizedWorkoutTypeTitle(String title) {
    if (title == outdoorRun ||
        title == WorkoutText.outdoorRun ||
        title == '户外' ||
        title == '户外') {
      return outdoorRun;
    }
    if (title == indoorRun ||
        title == WorkoutText.indoorRun ||
        title == '室内' ||
        title == '室内') {
      return indoorRun;
    }
    if (title == fitnessWalk ||
        title == WorkoutText.fitnessWalk ||
        title == '健走') {
      return fitnessWalk;
    }
    if (title == hiking || title == WorkoutText.hiking || title == '徒步') {
      return hiking;
    }
    return title;
  }

  static String _string(String key, String fallback) {
    return ResourceLoader.string('workout', key, fallback: fallback);
  }
}

/// 运动模块 const 文案。供 const mock / 默认数据使用；动态读取请走 [WorkoutResource]。
class WorkoutText {
  WorkoutText._();

  static const heroTitle = 'Ready for today\'s workout';
  static const heroSubtitle = 'Connect GPS / Start tracking';
  static const startWorkout = 'Start Workout';
  static const outdoorRun = 'Outdoor';
  static const indoorRun = 'Indoor';
  static const fitnessWalk = 'Fitness Walk';
  static const hiking = 'Hiking';
  static const goalKm = 'Distance';
  static const distanceUnit = 'km';
  static const goalDuration = 'Duration';
  static const durationUnit = 'min';
  static const goalCalorie = 'Calories';
  static const freeTraining = 'Free Training';
  static const noGoal = 'No goal';
  static const freeTrainingOn = 'Enabled';
  static const beginnerRunner = 'Beginner';
  static const persistent = 'Persistent';
  static const hundredKm = '100 km';
  static const trackingEndHint = 'Hold to end';
  static const trackingMusicTitle = 'Workout Music';
  static const trackingMusicStatus = 'Playing';
  static const trackingMusicPaused = 'Paused';
  static const trackingMusicIdle = 'No music imported';
  static const trackingDistanceLabel = 'Distance (km)';
  static const trackingTargetTemplate = 'Goal {{value}} km';
  static const trackingStartHint = 'Start';
  static const metricDistance = 'Distance';
  static const metricDuration = 'Duration';
  static const metricPace = 'Pace';
  static const metricCalorieKcal = 'Calories (kcal)';
  static const metricPaceMinKm = 'Pace (min/km)';
  static const goalAchievementTitle = 'Goals & Achievements';
  static const edit = 'Edit';
  static const goalAchievementHint =
      'Achievement badges light up when you reach goals';
  static const achievementBadge = 'Badges';
  static const viewMore = 'View More';
  static const editGoalTitle = 'Edit Workout Goal';
  static const editGoalSubtitle = 'Set goals to keep yourself moving every day';
  static const targetDistance = 'Target Distance';
  static const targetDistanceSuggestion = 'Recommended 3.00 - 20.00 km';
  static const targetDuration = 'Target Duration';
  static const targetDurationSuggestion = 'Recommended 10 - 300 min';
  static const targetCalorie = 'Target Calories';
  static const targetCalorieSuggestion = 'Recommended 100 - 2000 kcal';
  static const saveGoal = 'Save Goal';
  static const restoreDefault = 'Restore Default';
  static const freeTrainingTip = 'No goal will be set when enabled';
  static const goalSuggestionTitle = 'Goal Suggestions';
  static const suggestionDistance =
      'Distance: beginners 3-5 km, advanced 5-10 km';
  static const suggestionDuration = 'Duration: 30-60 min helps improve cardio';
  static const suggestionCalorie =
      'Calories: 300-600 kcal helps maintain fitness';
  static const resultCompleteTitle = 'Workout Complete!';
  static const resultCompleteSubtitle = 'Great job keeping active today';
  static const resultDone = 'Done';
  static const resultShare = 'Share';
  static const resultDate = 'May 20, 2024 19:30';
  static const resultSteps = 'Steps';
  static const resultAvgSpeed = 'Avg speed (km/h)';
  static const resultElevation = 'Elevation gain (m)';
  static const exitConfirmTitle = 'End this workout?';
  static const exitConfirmMessage =
      'This workout is still active. Going back will not save it.';
  static const exitConfirmBack = 'Go Back';
  static const exitConfirmContinue = 'Continue';
  static const trackingImportMusic = 'Import Music';
  static const trackingRoute = 'Route';
  static const routeHistoryTitle = 'Workout History';
  static const routeHistoryDetailTitle = 'Workout Details';
  static const routeHistoryCurrent = 'Current Route';
  static const routeHistoryRecording = 'Recording';
  static const routeHistoryEmpty = 'No workout data';
  static const musicListTitle = 'Music List';
  static const musicListEmpty = 'No music yet. Import music files first.';
}

/// 运动页模块路由定义（对齐 HomeRouteTable 写法）。
class WorkoutRouteTable {
  WorkoutRouteTable._();

  static const String pathEditGoal = '/workout/edit-goal';
  static const String pathTracking = '/workout/tracking';
  static const String pathResult = '/workout/result';
  static const String pathMusicList = '/workout/music-list';
  static const String pathRouteHistory = '/workout/route-history';
  static const String pathRouteHistoryDetail = '/workout/route-history/detail';
}
