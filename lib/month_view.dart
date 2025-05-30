// lib/month_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Make sure you have intl: ^0.19.0 in pubspec.yaml
import 'package:calendar/day_view.dart'; // Import CalendarEvent model

class MonthViewCalendar extends StatefulWidget {
  final DateTime initialDate;

  const MonthViewCalendar({super.key, required this.initialDate});

  @override
  State<MonthViewCalendar> createState() => _MonthViewCalendarState();
}

class _MonthViewCalendarState extends State<MonthViewCalendar> {
  late DateTime _focusedMonth;
  late DateTime
  _selectedDate; // Keep track of the selected date for highlighting
  Map<String, List<CalendarEvent>> eventsPerDate = {}; // Data event

  // Define display range for events in a day block
  final int _displayStartTimeHour = 8;
  final int _displayEndTimeHour = 17; // 5 PM

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      1,
    );
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _initializeEvents(); // Initialize dummy events for demonstration
  }

  // A simplified event initialization for MonthView.
  // In a real app, this data would come from a shared state/database.
  void _initializeEvents() {
    DateTime today = DateTime.now();
    DateTime baseToday = DateTime(today.year, today.month, today.day);
    DateTime tomorrow = baseToday.add(const Duration(days: 1));
    DateTime dayAfterTomorrow = baseToday.add(const Duration(days: 2));
    DateTime nextWeek = baseToday.add(const Duration(days: 7));
    DateTime startOfMonth = DateTime(today.year, today.month, 1);
    DateTime midMonth = DateTime(today.year, today.month, 15);

    // Clear existing events for fresh start in Month View
    eventsPerDate = {};

    // Events for today (similar to day_view, for consistency)
    eventsPerDate[_getDateKey(baseToday)] = [
      CalendarEvent(
        id: '1',
        title: 'Meeting Tim',
        startTime: baseToday.copyWith(hour: 9, minute: 0),
        endTime: baseToday.copyWith(hour: 10, minute: 30),
        color: Colors.blue,
      ),
      CalendarEvent(
        id: '2',
        title: 'Presentasi Project',
        startTime: baseToday.copyWith(hour: 9, minute: 30),
        endTime: baseToday.copyWith(hour: 10, minute: 15),
        color: Colors.green,
      ),
      CalendarEvent(
        id: '3',
        title: 'Review Code',
        startTime: baseToday.copyWith(hour: 14, minute: 15),
        endTime: baseToday.copyWith(hour: 15, minute: 45),
        color: Colors.orange,
      ),
      CalendarEvent(
        // Event melebihi batas bawah (setelah 5 sore)
        id: '3a',
        title: 'Late Meeting',
        startTime: baseToday.copyWith(hour: 17, minute: 30),
        endTime: baseToday.copyWith(hour: 18, minute: 30),
        color: Colors.red,
      ),
      CalendarEvent(
        // Event dimulai sebelum batas atas (sebelum 8 pagi)
        id: '3b',
        title: 'Early Call',
        startTime: baseToday.copyWith(hour: 7, minute: 0),
        endTime: baseToday.copyWith(hour: 7, minute: 45),
        color: Colors.purple,
      ),
    ];

    // Events for tomorrow
    eventsPerDate[_getDateKey(tomorrow)] = [
      CalendarEvent(
        id: 't1',
        title: 'Client Call',
        startTime: tomorrow.copyWith(hour: 11, minute: 0),
        endTime: tomorrow.copyWith(hour: 12, minute: 0),
        color: Colors.red,
      ),
    ];

    // Full day event example
    eventsPerDate[_getDateKey(dayAfterTomorrow)] = [
      CalendarEvent(
        id: 'fd1',
        title: 'Full Day Workshop',
        startTime: DateTime(
          dayAfterTomorrow.year,
          dayAfterTomorrow.month,
          dayAfterTomorrow.day,
          0,
          0,
        ),
        endTime: DateTime(
          dayAfterTomorrow.year,
          dayAfterTomorrow.month,
          dayAfterTomorrow.day,
          23,
          59,
        ),
        color: Colors.teal,
      ),
      CalendarEvent(
        // Other event on the same day
        id: 'fd2',
        title: 'Quick Sync',
        startTime: dayAfterTomorrow.copyWith(hour: 10, minute: 0),
        endTime: dayAfterTomorrow.copyWith(hour: 10, minute: 30),
        color: Colors.indigo,
      ),
    ];

    // Another event, spanning across midnight
    eventsPerDate[_getDateKey(nextWeek)] = [
      CalendarEvent(
        id: 'span1',
        title: 'Cross-day event',
        startTime: nextWeek.copyWith(hour: 22, minute: 0),
        endTime: nextWeek
            .add(const Duration(days: 1))
            .copyWith(hour: 2, minute: 0),
        color: Colors.brown,
      ),
    ];

    // Some events in the middle of the month
    eventsPerDate[_getDateKey(midMonth)] = [
      CalendarEvent(
        id: 'mm1',
        title: 'Project Deadline',
        startTime: midMonth.copyWith(hour: 16, minute: 0),
        endTime: midMonth.copyWith(hour: 17, minute: 0),
        color: Colors.deepPurple,
      ),
    ];
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<CalendarEvent> _getEventsForDate(DateTime date) {
    return eventsPerDate[_getDateKey(date)] ?? [];
  }

  void _changeMonth(int monthOffset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + monthOffset,
        1,
      );
      // Adjust selected date to the new month, keeping the day if possible
      int newDay = _selectedDate.day;
      if (newDay >
          DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day) {
        newDay =
            DateTime(
              _focusedMonth.year,
              _focusedMonth.month + 1,
              0,
            ).day; // Cap to last day of month
      }
      _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, newDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('MMMM y').format(_focusedMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Bulan Sebelumnya',
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    1,
                  );
                  _selectedDate = DateTime.now();
                });
              },
              icon: const Icon(Icons.calendar_today),
              tooltip: 'Bulan Ini',
            ),
            IconButton(
              onPressed: () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Bulan Selanjutnya',
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [_buildWeekdayHeader(), Expanded(child: _buildMonthGrid())],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    final List<String> weekdays = [
      'Min',
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children:
            weekdays
                .map(
                  (day) => Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            day == 'Min' || day == 'Sab'
                                ? Colors.red
                                : Colors.black87,
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildMonthGrid() {
    final int daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final DateTime firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final int firstWeekday =
        firstDayOfMonth.weekday % 7; // Sunday = 0, Monday = 1, etc.

    List<Widget> dayCells = [];

    // Add leading empty cells for days before the 1st of the month
    for (int i = 0; i < firstWeekday; i++) {
      dayCells.add(const SizedBox.shrink());
    }

    // Add cells for each day of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final DateTime currentDay = DateTime(
        _focusedMonth.year,
        _focusedMonth.month,
        day,
      );
      dayCells.add(_buildDayCell(currentDay));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8, // Adjust as needed
      ),
      itemCount: dayCells.length,
      itemBuilder: (context, index) => dayCells[index],
    );
  }

  Widget _buildDayCell(DateTime date) {
    final bool isToday =
        date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;
    final bool isSelected =
        date.day == _selectedDate.day &&
        date.month == _selectedDate.month &&
        date.year == _selectedDate.year;
    final bool isCurrentMonth = date.month == _focusedMonth.month;

    List<CalendarEvent> dayEvents = _getEventsForDate(date);
    List<CalendarEvent> fullDayEvents = [];
    List<CalendarEvent> scheduledEvents = [];

    for (var event in dayEvents) {
      // Check if it's a full day event
      if (event.startTime.hour == 0 &&
          event.startTime.minute == 0 &&
          event.endTime.hour == 23 &&
          event.endTime.minute == 59 &&
          event.startTime.day == event.endTime.day) {
        fullDayEvents.add(event);
      } else {
        scheduledEvents.add(event);
      }
    }

    bool hasEventsBeforeDisplayTime = false;
    bool hasEventsAfterDisplayTime = false;

    // Check for events outside display range
    for (var event in scheduledEvents) {
      if (event.startTime.hour < _displayStartTimeHour) {
        hasEventsBeforeDisplayTime = true;
      }
      if (event.endTime.hour >= _displayEndTimeHour) {
        // Check if event ends at or after _displayEndTimeHour
        hasEventsAfterDisplayTime = true;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          // Optionally, navigate to DayView for this date
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DayViewCalendar(initialDate: date),
            ),
          );
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: isToday ? BorderRadius.circular(8) : null,
        ),
        child: Column(
          children: [
            // Date number
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: BoxDecoration(
                color: isToday ? Colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color:
                      isToday
                          ? Colors.white
                          : isCurrentMonth
                          ? Colors.black87
                          : Colors.grey.shade400,
                ),
              ),
            ),
            // Full Day Event Indicator
            if (fullDayEvents.isNotEmpty)
              Container(
                height: 4,
                width: double.infinity,
                margin: const EdgeInsets.only(top: 2, left: 2, right: 2),
                decoration: BoxDecoration(
                  color:
                      fullDayEvents
                          .first
                          .color, // Use first full-day event color
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            // Events indicator (blocks)
            Expanded(
              child: SingleChildScrollView(
                physics:
                    const NeverScrollableScrollPhysics(), // Prevent scrolling inside cell
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasEventsBeforeDisplayTime) // Panah turun untuk jadwal sebelum jam 8 pagi
                      const Icon(
                        Icons.arrow_drop_up,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ...scheduledEvents.take(2).map((event) {
                      // Display up to 2 events as blocks
                      // Calculate block height based on duration (scaled)
                      double durationInMinutes =
                          event.endTime
                              .difference(event.startTime)
                              .inMinutes
                              .toDouble();
                      double blockHeight =
                          (durationInMinutes / 60) *
                          8; // Scale factor, adjust as needed

                      // Clamp block height to a reasonable range
                      blockHeight = blockHeight.clamp(4.0, 20.0);

                      return Container(
                        height: blockHeight,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: event.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }).toList(),
                    if (scheduledEvents.length > 2) // Indicate more events
                      Text(
                        '+${scheduledEvents.length - 2} more',
                        style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                      ),
                    if (hasEventsAfterDisplayTime) // Panah atas untuk jadwal setelah jam 5 sore
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 16,
                        color: Colors.grey,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
