import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_record.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_utils.dart';
import '../widgets/app_bottom_navigation.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'about_screen.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final DatabaseService _dbService = DatabaseService();
  static const String _startDateKey = 'export_start_date';
  static const String _endDateKey = 'export_end_date';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<TimeRecord> _records = [];
  bool _isLoading = false;
  int _currentPage = 0;
  static const int _recordsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _initializeDateRangeAndLoad();
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Future<void> _initializeDateRangeAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStart = prefs.getString(_startDateKey);
    final savedEnd = prefs.getString(_endDateKey);
    final earliestRecordedDate = await _dbService.getEarliestRecordedDate();

    DateTime start = _dateOnly(_startDate);
    DateTime end = _dateOnly(DateTime.now());

    if (savedStart != null && savedEnd != null) {
      start = _dateOnly(DateTime.parse(savedStart));
      // End date always follows the current day so latest Time In/Out is included.
      end = _dateOnly(DateTime.now());
    } else {
      // First time opening Export: default start date to earliest actual entry.
      if (earliestRecordedDate != null) {
        start = _dateOnly(earliestRecordedDate);
      }

      if (start.isAfter(end)) {
        end = start;
      }

      await _saveDateRange(start, end);
    }

    // Keep start aligned with the first actual recorded day in Calendar data.
    if (earliestRecordedDate != null && start.isAfter(earliestRecordedDate)) {
      start = _dateOnly(earliestRecordedDate);
    }

    if (start.isAfter(end)) {
      end = start;
    }

    await _saveDateRange(start, end);

    if (!mounted) {
      return;
    }

    setState(() {
      _startDate = start;
      _endDate = end;
    });

    await _loadRecords();
  }

  Future<void> _saveDateRange(DateTime start, DateTime end) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_startDateKey, _dateOnly(start).toIso8601String());
    await prefs.setString(_endDateKey, _dateOnly(end).toIso8601String());
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await _dbService.getRecordsForRange(_startDate, _endDate);
    if (!mounted) {
      return;
    }
    setState(() {
      _records = records;
      _isLoading = false;
      _currentPage = 0;
    });
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final normalizedStart = _dateOnly(picked);
      final normalizedEnd = _endDate.isBefore(normalizedStart)
          ? normalizedStart
          : _dateOnly(_endDate);
      setState(() {
        _startDate = normalizedStart;
        _endDate = normalizedEnd;
      });
      await _saveDateRange(_startDate, _endDate);
      _loadRecords();
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final normalizedEnd = _dateOnly(picked);
      final normalizedStart = _startDate.isAfter(normalizedEnd)
          ? normalizedEnd
          : _dateOnly(_startDate);
      setState(() {
        _startDate = normalizedStart;
        _endDate = normalizedEnd;
      });
      await _saveDateRange(_startDate, _endDate);
      _loadRecords();
    }
  }

  int _getPageItemCount() {
    final totalPages = (_records.length / _recordsPerPage).ceil();
    final isLastPage = _currentPage == totalPages - 1;
    if (!isLastPage) {
      return _recordsPerPage;
    }
    final remainder = _records.length % _recordsPerPage;
    return remainder == 0 ? _recordsPerPage : remainder;
  }

  Future<bool> _ensureExportPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) {
      return true;
    }

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) {
      return true;
    }

    _showSnackBar(
      'Please allow Files permission so exports can be saved in Downloads or Documents.',
    );
    return false;
  }

  String _getFolderLabelFromPath(String path) {
    if (path.contains('/Download/')) {
      return 'Downloads';
    }
    if (path.contains('/Documents/')) {
      return 'Documents';
    }
    return 'Files';
  }

  Future<void> _openFolderInFiles(String folderName) async {
    if (!Platform.isAndroid) {
      return;
    }

    final folderUri = folderName == 'Documents'
        ? 'content://com.android.externalstorage.documents/document/primary%3ADocuments'
        : 'content://com.android.externalstorage.documents/document/primary%3ADownload';

    try {
      // Try opening directly in Files by Google first.
      final filesByGoogleIntent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: folderUri,
        type: 'vnd.android.document/directory',
        package: 'com.google.android.apps.nbu.files',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await filesByGoogleIntent.launch();
      return;
    } catch (_) {
      _showSnackBar(
        'File saved. Could not open Files by Google automatically. Open Files by Google and check $folderName.',
      );
    }
  }

  Future<void> _exportCSV() async {
    if (_records.isEmpty) {
      _showSnackBar('No records found in this date range.');
      return;
    }

    final exportableRecords = _records
        .where((record) => record.timeIn != null || record.timeOut != null)
        .toList();

    if (exportableRecords.isEmpty) {
      _showSnackBar('No actual time entries to export.');
      return;
    }

    final hasPermission = await _ensureExportPermission();
    if (!hasPermission) {
      return;
    }

    try {
      final csv = await ExportService.exportToCSV(exportableRecords);
      final timestamp = ExportService.generateTimestamp();
      final file =
          await ExportService.saveCSVFile(csv, 'DTR_Export_$timestamp.csv');
      final fileName = file.path.split(Platform.pathSeparator).last;
      final folderName = _getFolderLabelFromPath(file.path);
      _showSnackBar(
        'CSV saved in $folderName as $fileName.',
      );
      await _openFolderInFiles(folderName);
    } catch (e) {
      _showSnackBar('Could not save CSV to Downloads/Documents. Please check Files permission and try again.');
    }
  }

  Future<void> _exportPDF() async {
    if (_records.isEmpty) {
      _showSnackBar('No records found in this date range.');
      return;
    }

    final exportableRecords = _records
        .where((record) => record.timeIn != null || record.timeOut != null)
        .toList();

    if (exportableRecords.isEmpty) {
      _showSnackBar('No actual time entries to export.');
      return;
    }

    final hasPermission = await _ensureExportPermission();
    if (!hasPermission) {
      return;
    }

    try {
      final pdfBytes = await ExportService.exportToPDF(exportableRecords);
      final timestamp = ExportService.generateTimestamp();
      final file = await ExportService.savePdfFile(
        pdfBytes,
        'DTR_Export_$timestamp.pdf',
      );
      final fileName = file.path.split(Platform.pathSeparator).last;
      final folderName = _getFolderLabelFromPath(file.path);
      _showSnackBar(
        'PDF saved in $folderName as $fileName.',
      );
      await _openFolderInFiles(folderName);
    } catch (e) {
      _showSnackBar('Could not save PDF to Downloads/Documents. Please check Files permission and try again.');
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all time records. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _dbService.clearAllRecords();
      await _loadRecords();
      _showSnackBar('All data cleared');
    } catch (e) {
      _showSnackBar('Clear failed: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalHours = _records.fold<double>(
        0, (sum, record) => sum + (record.totalHours ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Center'),
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
              Card(
                child: Container(
                  width: double.infinity,
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
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7CFFB2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'LIVE REPORTING',
                            style: TextStyle(
                              color: Colors.white,
                              letterSpacing: 1.2,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Export Your Records',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEE, MMM d yyyy').format(now),
                        style: const TextStyle(
                          color: Color(0xDDF0F7FF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Export Summary',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppTheme.pine, AppTheme.moss],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Records Found',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEAF5FF),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_records.length}',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rendered Hours',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEAF5FF),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${totalHours.toStringAsFixed(2)}h',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Date Range',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectStartDate,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(_startDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectEndDate,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'End Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(_endDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
              const SizedBox(height: 24),

              const Text(
                'Export Format',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exportCSV,
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Export as CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.moss,
                    foregroundColor: AppTheme.sand,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exportPDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export as PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.clay,
                    foregroundColor: AppTheme.sand,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearAllData,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Clear All Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.clay,
                    side: const BorderSide(color: AppTheme.clay),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Records List Preview
              const Text(
                'Preview',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_records.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No records found for selected date range'),
                  ),
                )
              else
                Column(
                  children: [
                    // Records per page
                    Text(
                      'Showing page ${_currentPage + 1} of ${(_records.length / _recordsPerPage).ceil()} (${_records.length} total records)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Records list for current page
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _getPageItemCount(),
                      itemBuilder: (context, index) {
                        final actualIndex = _currentPage * _recordsPerPage + index;
                        final record = _records[actualIndex];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.formatDate(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${record.formatTime(record.timeIn)} - ${record.formatTime(record.timeOut)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${(record.totalHours ?? 0).toStringAsFixed(1)}h',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.moss,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Pagination controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.moss,
                            foregroundColor: AppTheme.sand,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _currentPage < (_records.length / _recordsPerPage).ceil() - 1
                              ? () => setState(() => _currentPage++)
                              : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.moss,
                            foregroundColor: AppTheme.sand,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 2,
        onDestinationSelected: (index) async {
          if (index == 0) {
            await Navigator.pushReplacement(
              context,
              NavigationUtils.noAnimationRoute(const HomeScreen()),
            );
          } else if (index == 1) {
            await Navigator.pushReplacement(
              context,
              NavigationUtils.noAnimationRoute(const CalendarScreen()),
            );
          } else if (index == 3) {
            await Navigator.pushReplacement(
              context,
              NavigationUtils.noAnimationRoute(const AboutScreen()),
            );
          }
        },
      ),
    );
  }
}