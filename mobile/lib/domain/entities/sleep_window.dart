import 'package:equatable/equatable.dart';

class SleepWindow extends Equatable {
  const SleepWindow({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.label = 'Sleep',
    this.active = false,
  });

  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String label;
  final bool active;

  bool contains(DateTime now) =>
      now.isAfter(startTime) && now.isBefore(endTime);

  @override
  List<Object?> get props => [id, startTime, endTime, label, active];
}
