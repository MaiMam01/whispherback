import 'package:flutter_test/flutter_test.dart';
import 'package:whisperback/domain/entities/playback_schedule.dart';
import 'package:whisperback/services/scheduler/schedule_fire_helper.dart';

PlaybackSchedule _schedule({
  required int intervalMinutes,
  int startHour = 9,
  int startMinute = 0,
}) {
  return PlaybackSchedule(
    id: 's1',
    playlistId: 'p1',
    playlistName: 'Test',
    enabled: true,
    alarmEnabled: false,
    intervalMinutes: intervalMinutes,
    startTime: DateTime(2026, 1, 1, startHour, startMinute),
    endTime: DateTime(2026, 1, 1, 23, 0),
    daysMask: 127,
  );
}

void main() {
  test('slotToFire skips slots missed by more than 90 seconds', () {
    final schedule = _schedule(intervalMinutes: 10);
    // Missed 9:00 and 9:10; at 9:16 the next due slot is 9:20 (not 9:10).
    final now = DateTime(2026, 6, 12, 9, 16);
    expect(
      ScheduleFireHelper.slotToFire(schedule, now, null),
      isNull,
    );
    expect(
      ScheduleFireHelper.nextFireTime(schedule, now),
      DateTime(2026, 6, 12, 9, 20),
    );
  });

  test('slotToFire fires within 90 second grace window', () {
    final schedule = _schedule(intervalMinutes: 10);
    final slot = DateTime(2026, 6, 12, 9, 10);
    final now = DateTime(2026, 6, 12, 9, 11, 30);
    expect(ScheduleFireHelper.slotToFire(schedule, now, null), slot);
  });

  test('nextFireTime advances after lastFired', () {
    final schedule = _schedule(intervalMinutes: 10);
    final lastFired = DateTime(2026, 6, 12, 9, 10);
    final now = DateTime(2026, 6, 12, 9, 11);
    expect(
      ScheduleFireHelper.nextFireTime(schedule, now, lastFired: lastFired),
      DateTime(2026, 6, 12, 9, 20),
    );
    expect(
      ScheduleFireHelper.slotToFire(schedule, now, lastFired),
      isNull,
    );
  });

  test('upcomingEvents lists multiple future slots', () {
    final schedule = _schedule(intervalMinutes: 15);
    final now = DateTime(2026, 6, 12, 9, 0);
    final events = ScheduleFireHelper.upcomingEvents(
      [schedule],
      now,
      limit: 3,
    );
    expect(events.length, 3);
    expect(events[0].when, DateTime(2026, 6, 12, 9, 0));
    expect(events[1].when, DateTime(2026, 6, 12, 9, 15));
    expect(events[2].when, DateTime(2026, 6, 12, 9, 30));
  });
}
