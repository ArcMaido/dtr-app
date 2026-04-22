import 'package:intl/intl.dart';

class TimeRecord {
  final int? id;
  final DateTime date;
  final DateTime? timeIn;
  final DateTime? timeOut;
  final double? totalHours;

  TimeRecord({
    required this.date, this.id,
    this.timeIn,
    this.timeOut,
    this.totalHours,
  });

  // Calculate total hours worked
  double calculateHours() {
    if (timeIn != null && timeOut != null) {
      return timeOut!.difference(timeIn!).inMinutes / 60.0;
    }
    return 0.0;
  }

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'timeIn': timeIn?.toIso8601String(),
      'timeOut': timeOut?.toIso8601String(),
      'totalHours': calculateHours(),
    };
  }

  // Create TimeRecord from Map
  factory TimeRecord.fromMap(Map<String, dynamic> map) {
    return TimeRecord(
      id: map['id'],
      date: DateTime.parse(map['date']),
      timeIn: map['timeIn'] != null ? DateTime.parse(map['timeIn']) : null,
      timeOut: map['timeOut'] != null ? DateTime.parse(map['timeOut']) : null,
      totalHours: map['totalHours'],
    );
  }

  // Format time for display
  String formatTime(DateTime? time) {
    if (time == null) return 'Not set';
    return DateFormat('hh:mm a').format(time);
  }

  // Format date for display
  String formatDate() {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  TimeRecord copyWith({
    int? id,
    DateTime? date,
    DateTime? timeIn,
    DateTime? timeOut,
    double? totalHours,
  }) {
    return TimeRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      timeIn: timeIn ?? this.timeIn,
      timeOut: timeOut ?? this.timeOut,
      totalHours: totalHours ?? this.totalHours,
    );
  }
}
