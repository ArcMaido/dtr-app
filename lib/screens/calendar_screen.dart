import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/time_record.dart';
import '../services/database_service.dart';
import '../services/work_settings_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_utils.dart';
import '../widgets/app_bottom_navigation.dart';
import 'home_screen.dart';
import 'export_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DatabaseService _dbService = DatabaseService();
  final WorkSettingsService _settingsService = WorkSettingsService();
  TimeOfDay _defaultShiftStart = WorkSettingsService.defaultShiftStart;
  TimeOfDay _defaultShiftEnd = WorkSettingsService.defaultShiftEnd;

  static const Color _fullDayColor = Color(0xFFD9EBE1);
  static const Color _halfDayColor = Color(0xFFDDEFF8);
  static const Color _incompleteColor = Color(0xFFFBE2D3);
  static const double _fullDayThreshold = 7.5;

  // Saturday special times
  static const TimeOfDay _saturdayTimeIn = TimeOfDay(hour: 9, minute: 0);
  static const TimeOfDay _saturdayTimeOut = TimeOfDay(hour: 16, minute: 0);
  DateTime _selectedMonth = DateTime.now();
  Map<DateTime, TimeRecord> _recordsMap = {};
  double _monthTotalHours = 0.0;
  double _renderedTotalHours = 0.0;

  @override
  void initState() {
    super.initState();
    _loadShiftSettings();
    _loadMonthRecords();
  }

  Future<void> _loadShiftSettings() async {
    final shiftStart = await _settingsService.getShiftStart();
    final shiftEnd = await _settingsService.getShiftEnd();
    if (!mounted) {
      return;
    }
    setState(() {
      _defaultShiftStart = shiftStart;
      _defaultShiftEnd = shiftEnd;
    });
  }

  Future<void> _loadMonthRecords() async {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    final records = await _dbService.getRecordsForRange(firstDay, lastDay);
    final allRecords = await _dbService.getAllRecords();
    final monthTotal = records.fold<double>(
      0,
      (sum, item) => sum + (item.totalHours ?? 0),
    );
    final renderedTotal = allRecords.fold<double>(
      0,
      (sum, item) => sum + (item.totalHours ?? 0),
    );
    if (!mounted) {
      return;
    }

    final map = <DateTime, TimeRecord>{};
    for (var record in records) {
      final key =
          DateTime(record.date.year, record.date.month, record.date.day);
      map[key] = record;
    }

    setState(() {
      _recordsMap = map;
      _monthTotalHours = monthTotal;
      _renderedTotalHours = renderedTotal;
    });
  }

  TimeOfDay _timeOfDayFromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  String _formatTimeOfDay(BuildContext context, TimeOfDay? timeOfDay) {
    return timeOfDay == null ? 'Not set' : timeOfDay.format(context);
  }

  Color _dayFillColor(TimeRecord? record) {
    if (record == null) {
      return Colors.white.withOpacity(0.9);
    }

    final totalHours = record.totalHours ?? 0.0;
    if (record.timeOut == null) {
      return _incompleteColor;
    }

    if (totalHours >= _fullDayThreshold) {
      return _fullDayColor;
    }

    return _halfDayColor;
  }

  Color _dayAccentColor(TimeRecord? record) {
    if (record == null) {
      return Colors.transparent;
    }

    final totalHours = record.totalHours ?? 0.0;
    if (record.timeOut == null) {
      return AppTheme.clay.withOpacity(0.55);
    }

    if (totalHours >= _fullDayThreshold) {
      return AppTheme.moss.withOpacity(0.70);
    }

    return AppTheme.clay.withOpacity(0.70);
  }

  Widget _buildCalendarLegend() {
    Widget legendItem(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.moss,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          legendItem(_fullDayColor, 'Full day'),
          const SizedBox(width: 14),
          legendItem(_halfDayColor, 'Half day'),
        ],
      ),
    );
  }

  DateTime? _combineDateAndTime(DateTime date, TimeOfDay? timeOfDay) {
    if (timeOfDay == null) {
      return null;
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
  }

  Future<void> _editDayRecord(DateTime date, TimeRecord? record) async {
    TimeOfDay? selectedTimeIn =
        record?.timeIn != null ? _timeOfDayFromDateTime(record!.timeIn!) : null;
    TimeOfDay? selectedTimeOut = record?.timeOut != null
        ? _timeOfDayFromDateTime(record!.timeOut!)
        : null;

    // Check if the date is Saturday
    final isSaturday = date.weekday == DateTime.saturday;
    final defaultTimeIn = isSaturday ? _saturdayTimeIn : _defaultShiftStart;
    final defaultTimeOut = isSaturday ? _saturdayTimeOut : _defaultShiftEnd;
    final morningTimeIn = isSaturday
        ? const TimeOfDay(hour: 9, minute: 0)
        : const TimeOfDay(hour: 8, minute: 30);
    const morningTimeOut = TimeOfDay(hour: 12, minute: 0);
    final afternoonTimeIn = isSaturday
        ? const TimeOfDay(hour: 13, minute: 0)
        : const TimeOfDay(hour: 13, minute: 30);
    final afternoonTimeOut = isSaturday
        ? const TimeOfDay(hour: 16, minute: 0)
        : const TimeOfDay(hour: 17, minute: 30);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void applyPreset(TimeOfDay timeIn, TimeOfDay timeOut) {
              setDialogState(() {
                selectedTimeIn = timeIn;
                selectedTimeOut = timeOut;
              });
            }

            Future<void> editPresetTimes(
              TimeOfDay timeIn,
              TimeOfDay timeOut,
            ) async {
              applyPreset(timeIn, timeOut);

              final pickedTimeIn = await showTimePicker(
                context: dialogContext,
                initialTime: timeIn,
              );
              if (pickedTimeIn != null) {
                setDialogState(() {
                  selectedTimeIn = pickedTimeIn;
                });
              }

              final pickedTimeOut = await showTimePicker(
                context: dialogContext,
                initialTime: timeOut,
              );
              if (pickedTimeOut != null) {
                setDialogState(() {
                  selectedTimeOut = pickedTimeOut;
                });
              }
            }

            return AlertDialog(
              title: Text(
                  'Edit ${DateFormat('MMM dd, yyyy').format(date)}${isSaturday ? ' (Saturday)' : ''}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Quick presets',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.pine.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        onPressed: () =>
                            editPresetTimes(morningTimeIn, morningTimeOut),
                        avatar: const Icon(Icons.wb_sunny_outlined,
                            size: 14, color: AppTheme.moss),
                        label: const Text('Half Day Morning'),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.moss,
                        ),
                        backgroundColor: AppTheme.moss.withOpacity(0.10),
                        side:
                            BorderSide(color: AppTheme.moss.withOpacity(0.25)),
                      ),
                      ActionChip(
                        onPressed: () =>
                            editPresetTimes(afternoonTimeIn, afternoonTimeOut),
                        avatar: const Icon(Icons.nights_stay_outlined,
                            size: 14, color: AppTheme.clay),
                        label: const Text('Half Day Afternoon'),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.clay,
                        ),
                        backgroundColor: AppTheme.clay.withOpacity(0.10),
                        side:
                            BorderSide(color: AppTheme.clay.withOpacity(0.25)),
                      ),
                      ActionChip(
                        onPressed: () =>
                            applyPreset(defaultTimeIn, defaultTimeOut),
                        avatar: const Icon(Icons.access_time,
                            size: 14, color: AppTheme.pine),
                        label: const Text('Default Shift'),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.pine,
                        ),
                        backgroundColor: AppTheme.mist,
                        side:
                            BorderSide(color: AppTheme.pine.withOpacity(0.18)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Time In'),
                    subtitle: Text(
                      _formatTimeOfDay(dialogContext, selectedTimeIn),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: selectedTimeIn ?? defaultTimeIn,
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
                    subtitle: Text(
                      _formatTimeOfDay(dialogContext, selectedTimeOut),
                    ),
                    trailing: const Icon(Icons.access_time_filled),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: selectedTimeOut ?? defaultTimeOut,
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final timeIn = _combineDateAndTime(date, selectedTimeIn);
                    final timeOut = _combineDateAndTime(date, selectedTimeOut);
                    if (timeIn != null &&
                        timeOut != null &&
                        !timeOut.isAfter(timeIn)) {
                      _showSnackBar('Time Out must be after Time In');
                      return;
                    }

                    final updated = TimeRecord(
                      id: record?.id,
                      date: date,
                      timeIn: timeIn,
                      timeOut: timeOut,
                    );
                    await _dbService.saveTimeRecord(updated);
                    if (!mounted) {
                      return;
                    }
                    await _loadMonthRecords();
                    Navigator.pop(dialogContext);
                    _showSnackBar('Record saved');
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

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadMonthRecords();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadMonthRecords();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final weekdayOfFirst = firstDay.weekday;
    final leadingEmptyCells = weekdayOfFirst % 7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Calendar'),
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
            children: [
              Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                            width: 9,
                            height: 9,
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
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE, MMM d').format(now),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('yyyy').format(now),
                        style: const TextStyle(
                          color: Color(0xDDF0F7FF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _buildCalendarLegend(),

              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Monthly Worked Hours',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.moss,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_monthTotalHours.toStringAsFixed(2)}h',
                              style: const TextStyle(
                                fontSize: 22,
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
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Hours',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.clay,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_renderedTotalHours.toStringAsFixed(2)}h',
                              style: const TextStyle(
                                fontSize: 22,
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
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: AppTheme.pine),
                    onPressed: _previousMonth,
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.pine,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppTheme.pine),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weekday Headers
              GridView.count(
                crossAxisCount: 7,
                childAspectRatio: 1.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map((day) => Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.moss,
                            ),
                          ),
                        ))
                    .toList(),
              ),

              // Calendar Days
              GridView.count(
                crossAxisCount: 7,
                childAspectRatio: 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Empty cells for days before month starts
                  ...List.generate(leadingEmptyCells, (index) => Container()),

                  // Days of the month
                  ...List.generate(
                    lastDay.day,
                    (index) {
                      final day = index + 1;
                      final date = DateTime(
                          _selectedMonth.year, _selectedMonth.month, day);
                      final record = _recordsMap[DateTime(
                          _selectedMonth.year, _selectedMonth.month, day)];

                      return _buildDayCell(date, record);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        onDestinationSelected: (index) async {
          if (index == 0) {
            await Navigator.pushReplacement(
              context,
              NavigationUtils.noAnimationRoute(const HomeScreen()),
            );
          } else if (index == 2) {
            await Navigator.pushReplacement(
              context,
              NavigationUtils.noAnimationRoute(const ExportScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildDayCell(DateTime date, TimeRecord? record) {
    final isToday = date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;

    final hasRecord = record != null;
    final fillColor = _dayFillColor(record);
    final accentColor = _dayAccentColor(record);

    return GestureDetector(
      onTap: () => _showDayDetails(date, record),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isToday ? AppTheme.clay : AppTheme.moss.withOpacity(0.25),
            width: isToday ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: fillColor,
        ),
        child: Stack(
          children: [
            if (hasRecord)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isToday ? AppTheme.clay : AppTheme.ink,
                    ),
                  ),
                  if (record != null)
                    Text(
                      '${record.totalHours?.toStringAsFixed(1) ?? '0'}h',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.moss,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetails(DateTime date, TimeRecord? record) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(DateFormat('MMM dd, yyyy').format(date)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record != null) ...[
              Text('Time In: ${record.formatTime(record.timeIn)}'),
              const SizedBox(height: 8),
              Text('Time Out: ${record.formatTime(record.timeOut)}'),
              const SizedBox(height: 8),
              Text(
                'Total Hours: ${(record.totalHours ?? 0).toStringAsFixed(2)}',
              ),
            ] else
              const Text('No record for this day'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _editDayRecord(date, record);
            },
            child: Text(record == null ? 'Add Time' : 'Edit Times'),
          ),
          if (record?.id != null)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: dialogContext,
                  builder: (confirmContext) => AlertDialog(
                    title: const Text('Remove Time'),
                    content: const Text(
                      'This will remove Time In and Time Out for this date. Continue?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(confirmContext, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(confirmContext, true),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) {
                  return;
                }

                await _dbService.deleteRecord(record!.id!);
                if (!mounted) {
                  return;
                }
                Navigator.pop(dialogContext);
                await _loadMonthRecords();
                _showSnackBar('Time removed for this date');
              },
              child: const Text('Remove Time'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
