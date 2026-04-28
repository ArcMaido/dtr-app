import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkSettingsService {
  static final WorkSettingsService _instance = WorkSettingsService._internal();
  static const _lunchStartKey = 'lunch_start_minutes';
  static const _lunchEndKey = 'lunch_end_minutes';
  static const _shiftStartKey = 'shift_start_minutes';
  static const _shiftEndKey = 'shift_end_minutes';
  static const _renderedGoalKey = 'rendered_goal_hours';

  static const TimeOfDay defaultLunchStart = TimeOfDay(hour: 12, minute: 0);
  static const TimeOfDay defaultLunchEnd = TimeOfDay(hour: 13, minute: 0);
  static const TimeOfDay defaultShiftStart = TimeOfDay(hour: 8, minute: 30);
  static const TimeOfDay defaultShiftEnd = TimeOfDay(hour: 17, minute: 30);
  static const double defaultRenderedGoalHours = 160.0;

  factory WorkSettingsService() => _instance;

  WorkSettingsService._internal();

  Future<TimeOfDay> getLunchStart() async {
    final prefs = await SharedPreferences.getInstance();
    return _timeOfDayFromMinutes(
      prefs.getInt(_lunchStartKey) ?? _minutesOfDay(defaultLunchStart),
    );
  }

  Future<TimeOfDay> getLunchEnd() async {
    final prefs = await SharedPreferences.getInstance();
    return _timeOfDayFromMinutes(
      prefs.getInt(_lunchEndKey) ?? _minutesOfDay(defaultLunchEnd),
    );
  }

  Future<void> saveLunchBreak(TimeOfDay start, TimeOfDay end) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lunchStartKey, _minutesOfDay(start));
    await prefs.setInt(_lunchEndKey, _minutesOfDay(end));
  }

  Future<TimeOfDay> getShiftStart() async {
    final prefs = await SharedPreferences.getInstance();
    return _timeOfDayFromMinutes(
      prefs.getInt(_shiftStartKey) ?? _minutesOfDay(defaultShiftStart),
    );
  }

  Future<TimeOfDay> getShiftEnd() async {
    final prefs = await SharedPreferences.getInstance();
    return _timeOfDayFromMinutes(
      prefs.getInt(_shiftEndKey) ?? _minutesOfDay(defaultShiftEnd),
    );
  }

  Future<void> saveShiftTimes(TimeOfDay start, TimeOfDay end) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_shiftStartKey, _minutesOfDay(start));
    await prefs.setInt(_shiftEndKey, _minutesOfDay(end));
  }

  Future<double> getRenderedGoalHours() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_renderedGoalKey) ?? defaultRenderedGoalHours;
  }

  Future<void> saveRenderedGoalHours(double hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_renderedGoalKey, hours);
  }

  double calculateWorkedHours(
    DateTime? timeIn,
    DateTime? timeOut,
    TimeOfDay lunchStart,
    TimeOfDay lunchEnd,
    TimeOfDay shiftStart,
  ) {
    if (timeIn == null || timeOut == null || !timeOut.isAfter(timeIn)) {
      return 0.0;
    }

    final lunchStartDate = _timeOnDate(timeIn, lunchStart);
    final lunchEndDate = _timeOnDate(timeIn, lunchEnd);
    final shiftStartDate = _timeOnDate(timeIn, shiftStart);

    // Treat as whole-day work only when the time range spans both sides of lunch.
    final spansLunchWindow =
        timeIn.isBefore(lunchStartDate) && timeOut.isAfter(lunchEndDate);

    // For whole-day logs, early time-ins are counted from shift start.
    final effectiveTimeIn = spansLunchWindow && timeIn.isBefore(shiftStartDate)
        ? shiftStartDate
        : timeIn;

    if (!timeOut.isAfter(effectiveTimeIn)) {
      return 0.0;
    }

    final totalMinutes = timeOut.difference(effectiveTimeIn).inMinutes;
    final lunchOverlapMinutes = spansLunchWindow
        ? _calculateOverlapMinutes(
            effectiveTimeIn,
            timeOut,
            lunchStartDate,
            lunchEndDate,
          )
        : 0;

    final workedMinutes = totalMinutes - lunchOverlapMinutes;
    return workedMinutes > 0 ? workedMinutes / 60.0 : 0.0;
  }

  int _calculateOverlapMinutes(
    DateTime workStart,
    DateTime workEnd,
    DateTime breakStart,
    DateTime breakEnd,
  ) {
    DateTime effectiveBreakEnd = breakEnd;
    if (!effectiveBreakEnd.isAfter(breakStart)) {
      effectiveBreakEnd = breakEnd.add(const Duration(days: 1));
    }

    final overlapStart = workStart.isAfter(breakStart) ? workStart : breakStart;
    final overlapEnd =
        workEnd.isBefore(effectiveBreakEnd) ? workEnd : effectiveBreakEnd;

    if (!overlapEnd.isAfter(overlapStart)) {
      return 0;
    }
    return overlapEnd.difference(overlapStart).inMinutes;
  }

  DateTime _timeOnDate(DateTime date, TimeOfDay timeOfDay) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
  }

  int _minutesOfDay(TimeOfDay timeOfDay) {
    return timeOfDay.hour * 60 + timeOfDay.minute;
  }

  TimeOfDay _timeOfDayFromMinutes(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }
}
