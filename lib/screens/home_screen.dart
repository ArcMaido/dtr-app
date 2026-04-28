import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/time_record.dart';
import '../services/database_service.dart';
import '../services/work_settings_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_utils.dart';
import 'calendar_screen.dart';
import 'export_screen.dart';
import '../widgets/app_bottom_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  final WorkSettingsService _settingsService = WorkSettingsService();
  // Regular weekday times
  static const TimeOfDay _regularTimeIn = TimeOfDay(hour: 8, minute: 30);
  static const TimeOfDay _regularTimeOut = TimeOfDay(hour: 17, minute: 30);
  static const TimeOfDay _halfDayMorningIn = TimeOfDay(hour: 8, minute: 0);
  static const TimeOfDay _halfDayMorningOut = TimeOfDay(hour: 12, minute: 0);
  static const TimeOfDay _halfDayAfternoonIn = TimeOfDay(hour: 13, minute: 30);
  static const TimeOfDay _halfDayAfternoonOut = TimeOfDay(hour: 17, minute: 30);

  // Saturday times
  static const TimeOfDay _saturdayTimeIn = TimeOfDay(hour: 9, minute: 0);
  static const TimeOfDay _saturdayTimeOut = TimeOfDay(hour: 16, minute: 0);
  static const TimeOfDay _saturdayHalfDayMorningIn =
      TimeOfDay(hour: 9, minute: 0);
  static const TimeOfDay _saturdayHalfDayMorningOut =
      TimeOfDay(hour: 12, minute: 0);
  static const TimeOfDay _saturdayHalfDayAfternoonIn =
      TimeOfDay(hour: 13, minute: 0);
  static const TimeOfDay _saturdayHalfDayAfternoonOut =
      TimeOfDay(hour: 16, minute: 0);
  TimeRecord? _todayRecord;
  double _totalRenderedHours = 0.0;
  double _renderedGoalHours = WorkSettingsService.defaultRenderedGoalHours;
  TimeOfDay _lunchStart = WorkSettingsService.defaultLunchStart;
  TimeOfDay _lunchEnd = WorkSettingsService.defaultLunchEnd;
  TimeOfDay _shiftStart = WorkSettingsService.defaultShiftStart;
  TimeOfDay _shiftEnd = WorkSettingsService.defaultShiftEnd;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadSettings();
    await _loadTodayRecord();
  }

  Future<void> _loadTodayRecord() async {
    final today = DateTime.now();
    var record = await _dbService.getRecordForDate(today);

    if (record == null) {
      // Create empty record - user must manually set times
      final emptyRecord = TimeRecord(
        date: today,
        timeIn: null,
        timeOut: null,
      );
      await _dbService.saveTimeRecord(emptyRecord);
      record = await _dbService.getRecordForDate(today) ?? emptyRecord;
    }

    final allRecords = await _dbService.getAllRecords();
    final totalRenderedHours = allRecords.fold<double>(
      0,
      (sum, item) => sum + (item.totalHours ?? 0),
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _todayRecord = record;
      _totalRenderedHours = totalRenderedHours;
    });
  }

  Future<TimeRecord> _ensureTodayRecord() async {
    if (_todayRecord != null) {
      return _todayRecord!;
    }

    await _loadTodayRecord();
    return _todayRecord!;
  }

  Future<void> _loadSettings() async {
    final lunchStart = await _settingsService.getLunchStart();
    final lunchEnd = await _settingsService.getLunchEnd();
    final shiftStart = await _settingsService.getShiftStart();
    final shiftEnd = await _settingsService.getShiftEnd();
    final renderedGoalHours = await _settingsService.getRenderedGoalHours();
    if (!mounted) {
      return;
    }
    setState(() {
      _lunchStart = lunchStart;
      _lunchEnd = lunchEnd;
      _shiftStart = shiftStart;
      _shiftEnd = shiftEnd;
      _renderedGoalHours = renderedGoalHours;
    });
  }

  Future<void> _editRenderedGoal() async {
    double? draftGoal = _renderedGoalHours;

    final updatedGoal = await showDialog<double?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set Rendered Goal'),
        content: TextFormField(
          initialValue: _renderedGoalHours.toStringAsFixed(0),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Goal hours',
            hintText: 'Enter total rendered hours',
          ),
          autofocus: true,
          onChanged: (value) {
            draftGoal = double.tryParse(value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, draftGoal);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updatedGoal == null || updatedGoal <= 0) {
      return;
    }

    await _settingsService.saveRenderedGoalHours(updatedGoal);
    if (!mounted) {
      return;
    }

    setState(() {
      _renderedGoalHours = updatedGoal;
    });
    _showSnackBar('Rendered goal updated');
  }

  double _remainingRenderedHours() {
    return math.max(0.0, _renderedGoalHours - _totalRenderedHours);
  }

  String _formattedRenderedTimeLeft() {
    final remainingHours = _remainingRenderedHours();
    if (remainingHours <= 0) {
      return 'Goal achieved';
    }

    final remainingWholeHours = remainingHours.ceil();
    final remainingDays = remainingWholeHours ~/ 8;
    final remainingDayHours = remainingWholeHours % 8;
    return '${remainingDays}d ${remainingDayHours}h remaining';
  }

  Future<void> _recordTimeIn() async {
    final todayRecord = await _ensureTodayRecord();
    final today = DateTime.now();
    final shiftStartToday = DateTime(
      today.year,
      today.month,
      today.day,
      _regularTimeIn.hour,
      _regularTimeIn.minute,
    );

    // Before or at 8:30 AM, clamp to 8:30 AM. After 8:30 AM, use current time.
    final stampedTimeIn =
        today.isAfter(shiftStartToday) ? today : shiftStartToday;

    final updated = todayRecord.copyWith(timeIn: stampedTimeIn);
    await _dbService.saveTimeRecord(updated);
    await _loadTodayRecord();
    _showSnackBar(
        'Time In set: ${DateFormat('hh:mm a').format(stampedTimeIn)}');
  }

  Future<void> _recordTimeOut() async {
    final todayRecord = await _ensureTodayRecord();
    final today = DateTime.now();
    final shiftEndToday = DateTime(
      today.year,
      today.month,
      today.day,
      _regularTimeOut.hour,
      _regularTimeOut.minute,
    );

    // Before 5:30 PM, use current time. At or after 5:30 PM, clamp to 5:30 PM.
    final stampedTimeOut =
        today.isBefore(shiftEndToday) ? today : shiftEndToday;

    if (todayRecord.timeIn != null &&
        !stampedTimeOut.isAfter(todayRecord.timeIn!)) {
      _showSnackBar('Time Out must be after Time In');
      return;
    }

    final updated = todayRecord.copyWith(timeOut: stampedTimeOut);
    await _dbService.saveTimeRecord(updated);
    await _loadTodayRecord();
    _showSnackBar(
        'Time Out set: ${DateFormat('hh:mm a').format(stampedTimeOut)}');
  }

  Future<void> _applyHalfDayMorning() async {
    final todayRecord = await _ensureTodayRecord();
    final today = DateTime.now();
    final isSaturday = today.weekday == DateTime.saturday;

    final morning = isSaturday ? _saturdayHalfDayMorningIn : _halfDayMorningIn;
    final morningOut =
        isSaturday ? _saturdayHalfDayMorningOut : _halfDayMorningOut;

    final timeIn = DateTime(
      today.year,
      today.month,
      today.day,
      morning.hour,
      morning.minute,
    );
    final timeOut = DateTime(
      today.year,
      today.month,
      today.day,
      morningOut.hour,
      morningOut.minute,
    );
    final updated = todayRecord.copyWith(timeIn: timeIn, timeOut: timeOut);
    await _dbService.saveTimeRecord(updated);
    await _loadTodayRecord();
    _showSnackBar('Half Day Morning applied');
  }

  Future<void> _applyHalfDayAfternoon() async {
    final todayRecord = await _ensureTodayRecord();
    final today = DateTime.now();
    final isSaturday = today.weekday == DateTime.saturday;

    final afternoon =
        isSaturday ? _saturdayHalfDayAfternoonIn : _halfDayAfternoonIn;
    final afternoonOut =
        isSaturday ? _saturdayHalfDayAfternoonOut : _halfDayAfternoonOut;

    final timeIn = DateTime(
      today.year,
      today.month,
      today.day,
      afternoon.hour,
      afternoon.minute,
    );
    final timeOut = DateTime(
      today.year,
      today.month,
      today.day,
      afternoonOut.hour,
      afternoonOut.minute,
    );
    final updated = todayRecord.copyWith(timeIn: timeIn, timeOut: timeOut);
    await _dbService.saveTimeRecord(updated);
    await _loadTodayRecord();
    _showSnackBar('Half Day Afternoon applied');
  }

  Future<void> _applyDefaultShift() async {
    final todayRecord = await _ensureTodayRecord();
    final today = DateTime.now();
    final isSaturday = today.weekday == DateTime.saturday;

    final defaultIn = isSaturday ? _saturdayTimeIn : _regularTimeIn;
    final defaultOut = isSaturday ? _saturdayTimeOut : _regularTimeOut;

    final timeIn = DateTime(
      today.year,
      today.month,
      today.day,
      defaultIn.hour,
      defaultIn.minute,
    );
    final timeOut = DateTime(
      today.year,
      today.month,
      today.day,
      defaultOut.hour,
      defaultOut.minute,
    );
    final updated = todayRecord.copyWith(timeIn: timeIn, timeOut: timeOut);
    await _dbService.saveTimeRecord(updated);
    await _loadTodayRecord();
    _showSnackBar('Default shift applied');
  }

  Future<void> _editTodayTimes() async {
    TimeOfDay? selectedTimeIn = _todayRecord?.timeIn != null
        ? TimeOfDay.fromDateTime(_todayRecord!.timeIn!)
        : null;
    TimeOfDay? selectedTimeOut = _todayRecord?.timeOut != null
        ? TimeOfDay.fromDateTime(_todayRecord!.timeOut!)
        : null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            String formatTime(TimeOfDay? value) {
              return value == null ? 'Not set' : value.format(dialogContext);
            }

            return AlertDialog(
              title: const Text('Edit Today\'s Time'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Time In'),
                    subtitle: Text(formatTime(selectedTimeIn)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: selectedTimeIn ?? _shiftStart,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedTimeIn = picked;
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Time Out'),
                    subtitle: Text(formatTime(selectedTimeOut)),
                    trailing: const Icon(Icons.access_time_filled),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: selectedTimeOut ?? _shiftEnd,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedTimeOut = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      selectedTimeIn = null;
                      selectedTimeOut = null;
                    });
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final today = DateTime.now();
                    final newTimeIn = selectedTimeIn == null
                        ? null
                        : DateTime(
                            today.year,
                            today.month,
                            today.day,
                            selectedTimeIn!.hour,
                            selectedTimeIn!.minute,
                          );
                    final newTimeOut = selectedTimeOut == null
                        ? null
                        : DateTime(
                            today.year,
                            today.month,
                            today.day,
                            selectedTimeOut!.hour,
                            selectedTimeOut!.minute,
                          );

                    if (newTimeIn != null &&
                        newTimeOut != null &&
                        !newTimeOut.isAfter(newTimeIn)) {
                      _showSnackBar('Time Out must be after Time In');
                      return;
                    }

                    final updated = (await _ensureTodayRecord()).copyWith(
                      timeIn: newTimeIn,
                      timeOut: newTimeOut,
                    );
                    await _dbService.saveTimeRecord(updated);
                    if (!mounted) {
                      return;
                    }
                    await _loadTodayRecord();
                    Navigator.pop(dialogContext);
                    _showSnackBar('Time updated');
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editLunchBreak() async {
    final start = await _pickTime(initial: _lunchStart);
    if (start == null) {
      return;
    }

    final end = await _pickTime(initial: _lunchEnd);
    if (end == null) {
      return;
    }

    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    if (endMinutes <= startMinutes) {
      _showSnackBar('End time must be after start time');
      return;
    }

    if (!mounted) {
      return;
    }

    await _settingsService.saveLunchBreak(start, end);
    setState(() {
      _lunchStart = start;
      _lunchEnd = end;
    });
    await _loadTodayRecord();
    _showSnackBar('Lunch break updated');
  }

  Future<void> _editGlobalShiftTimes() async {
    final start = await _pickTime(initial: _shiftStart);
    if (start == null) {
      return;
    }

    final end = await _pickTime(initial: _shiftEnd);
    if (end == null) {
      return;
    }

    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    if (endMinutes <= startMinutes) {
      _showSnackBar('Time Out must be after Time In');
      return;
    }

    await _settingsService.saveShiftTimes(start, end);
    if (!mounted) {
      return;
    }

    setState(() {
      _shiftStart = start;
      _shiftEnd = end;
    });

    // Keep today's record aligned with global defaults after saving new shift.
    final today = DateTime.now();
    final updated = _todayRecord?.copyWith(
      timeIn: DateTime(
        today.year,
        today.month,
        today.day,
        start.hour,
        start.minute,
      ),
      timeOut: DateTime(
        today.year,
        today.month,
        today.day,
        end.hour,
        end.minute,
      ),
    );
    if (updated != null) {
      await _dbService.saveTimeRecord(updated);
      await _loadTodayRecord();
    }
    _showSnackBar('Global shift time updated');
  }

  Future<TimeOfDay?> _pickTime({required TimeOfDay initial}) {
    return showTimePicker(
      context: context,
      initialTime: initial,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayWorkedHours = _todayRecord?.totalHours ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1, -1),
            end: Alignment(1, 1),
            colors: [Color(0xFFF8FBFF), Color(0xFFE8F3FF)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Card(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.pine, AppTheme.moss],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF7CFFB2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'LIVE CALENDAR',
                              style: TextStyle(
                                color: Colors.white,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('EEEE, MMMM d').format(now),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Track today quickly and keep your hours updated.',
                          style: TextStyle(
                            color: Color(0xDDF2F8FF),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Worked Hours',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.moss,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${todayWorkedHours.toStringAsFixed(2)}h',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.pine,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      color: const Color(0xFFE9FDFF),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Rendered Hours',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.clay,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_totalRenderedHours.toStringAsFixed(2)}h',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.clay,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: const Color(0xFFF3FBFF),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Rendered Goal',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.pine,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _editRenderedGoal,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                    color: AppTheme.pine,
                                  ),
                                  tooltip: 'Edit rendered goal',
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_renderedGoalHours.toStringAsFixed(0)}h',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.clay,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      color: AppTheme.mist.withOpacity(0.75),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Remaining',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.moss,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formattedRenderedTimeLeft(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.moss,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Global Shift Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Global Shift Time',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_shiftStart.format(context)} - ${_shiftEnd.format(context)}',
                            style: const TextStyle(color: AppTheme.moss),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _editGlobalShiftTimes,
                        icon: const Icon(Icons.schedule, color: AppTheme.clay),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Lunch Break Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Excluded Time',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_lunchStart.format(context)} - ${_lunchEnd.format(context)}',
                            style: const TextStyle(color: AppTheme.moss),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _editLunchBreak,
                        icon: const Icon(Icons.edit, color: AppTheme.clay),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time Capture',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.pine,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Quick tap for default schedule. Tap Time In or Time Out to customize.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.moss,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _editTodayTimes,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.moss.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppTheme.moss.withOpacity(0.25),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.login,
                                              size: 15, color: AppTheme.moss),
                                          SizedBox(width: 6),
                                          Text(
                                            'Time In',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.moss,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _todayRecord?.formatTime(
                                                _todayRecord?.timeIn) ??
                                            '--:--',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.pine,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _editTodayTimes,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.clay.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppTheme.clay.withOpacity(0.25),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.logout,
                                              size: 15, color: AppTheme.clay),
                                          SizedBox(width: 6),
                                          Text(
                                            'Time Out',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.clay,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _todayRecord?.formatTime(
                                                _todayRecord?.timeOut) ??
                                            '--:--',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.pine,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _recordTimeIn,
                              icon: const Icon(Icons.login),
                              label: const Text('Set Time-In'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.moss,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _recordTimeOut,
                              icon: const Icon(Icons.logout),
                              label: const Text('Set Time-Out'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.clay,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Shortcuts',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.moss,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            onPressed: _applyHalfDayMorning,
                            avatar: const Icon(
                              Icons.wb_sunny_outlined,
                              size: 14,
                              color: AppTheme.moss,
                            ),
                            label: const Text('Morning'),
                            labelStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.moss,
                            ),
                            backgroundColor: AppTheme.moss.withOpacity(0.10),
                            side: BorderSide(
                              color: AppTheme.moss.withOpacity(0.25),
                            ),
                          ),
                          ActionChip(
                            onPressed: _applyHalfDayAfternoon,
                            avatar: const Icon(
                              Icons.nights_stay_outlined,
                              size: 14,
                              color: AppTheme.clay,
                            ),
                            label: const Text('Afternoon'),
                            labelStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.clay,
                            ),
                            backgroundColor: AppTheme.clay.withOpacity(0.10),
                            side: BorderSide(
                              color: AppTheme.clay.withOpacity(0.25),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0,
        onDestinationSelected: (index) async {
          if (index == 1) {
            await Navigator.pushReplacement(
              context,
              NavigationUtils.noAnimationRoute(const CalendarScreen()),
            );
            if (!mounted) {
              return;
            }
            await _loadTodayRecord();
          } else if (index == 2) {
            await Navigator.pushReplacement(
              context,
              NavigationUtils.noAnimationRoute(const ExportScreen()),
            );
            if (!mounted) {
              return;
            }
            await _loadTodayRecord();
          }
        },
      ),
    );
  }
}
