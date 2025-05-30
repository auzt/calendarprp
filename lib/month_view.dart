// lib/month_view.dart (REVISI ULANG)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calendar/day_view.dart'; // Import CalendarEvent model
import 'dart:math'; // Untuk fungsi min

class MonthViewCalendar extends StatefulWidget {
  final DateTime initialDate;

  const MonthViewCalendar({super.key, required this.initialDate});

  @override
  State<MonthViewCalendar> createState() => _MonthViewCalendarState();
}

class _MonthViewCalendarState extends State<MonthViewCalendar> {
  late PageController _pageController;
  late DateTime _focusedMonth;
  late DateTime
  _selectedDate; // Keep track of the selected date for highlighting
  Map<String, List<CalendarEvent>> eventsPerDate = {}; // Data event

  // Define display range for events in a day block for arrow indicators
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
    // Initialize page controller to start at the current month's page index
    _pageController = PageController(
      initialPage: _calculateInitialPageIndex(widget.initialDate),
    );
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _initializeEvents(); // Initialize dummy events for demonstration
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _calculateInitialPageIndex(DateTime date) {
    // Arbitrary starting year, e.g., 2000, to calculate page index
    // This allows navigating many years back/forward.
    final DateTime epoch = DateTime(2000, 1, 1);
    return ((date.year - epoch.year) * 12) + (date.month - epoch.month);
  }

  DateTime _getMonthForPageIndex(int index) {
    final DateTime epoch = DateTime(2000, 1, 1);
    return DateTime(epoch.year + (index ~/ 12), epoch.month + (index % 12));
  }

  void _initializeEvents() {
    DateTime today = DateTime.now();
    DateTime baseToday = DateTime(today.year, today.month, today.day);
    DateTime tomorrow = baseToday.add(const Duration(days: 1));
    DateTime dayAfterTomorrow = baseToday.add(const Duration(days: 2));
    DateTime twoDaysAfterTomorrow = baseToday.add(const Duration(days: 4));
    DateTime nextWeek = baseToday.add(const Duration(days: 7));
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

    // Events with intentional overlap for splitting test
    eventsPerDate[_getDateKey(twoDaysAfterTomorrow)] = [
      CalendarEvent(
        id: 'overlap1',
        title: 'Meeting A',
        startTime: twoDaysAfterTomorrow.copyWith(hour: 10, minute: 0),
        endTime: twoDaysAfterTomorrow.copyWith(hour: 11, minute: 30),
        color: Colors.deepOrange,
      ),
      CalendarEvent(
        id: 'overlap2',
        title: 'Meeting B',
        startTime: twoDaysAfterTomorrow.copyWith(hour: 10, minute: 45),
        endTime: twoDaysAfterTomorrow.copyWith(hour: 12, minute: 0),
        color: Colors.cyan,
      ),
      CalendarEvent(
        id: 'overlap3',
        title: 'Meeting C',
        startTime: twoDaysAfterTomorrow.copyWith(hour: 11, minute: 0),
        endTime: twoDaysAfterTomorrow.copyWith(hour: 12, minute: 30),
        color: Colors.pink,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('MMMM y').format(_focusedMonth),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildWeekdayHeader(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection:
                  Axis.vertical, // Scroll vertikal untuk ganti bulan
              onPageChanged: (index) {
                setState(() {
                  _focusedMonth = _getMonthForPageIndex(index);
                });
              },
              itemBuilder: (context, index) {
                final month = _getMonthForPageIndex(index);
                return _buildMonthGrid(month);
              },
            ),
          ),
        ],
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

  Widget _buildMonthGrid(DateTime month) {
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final DateTime firstDayOfMonth = DateTime(month.year, month.month, 1);
    final int firstWeekday =
        firstDayOfMonth.weekday % 7; // Sunday = 0, Monday = 1, etc.

    List<Widget> dayCells = [];

    // Add leading empty cells for days before the 1st of the month
    for (int i = 0; i < firstWeekday; i++) {
      dayCells.add(const SizedBox.shrink());
    }

    // Add cells for each day of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final DateTime currentDay = DateTime(month.year, month.month, day);
      dayCells.add(_buildDayCell(currentDay));
    }

    // Calculate total number of cells needed for 6 rows (assuming 7 columns)
    int totalCellsNeeded = 6 * 7;
    // Add trailing empty cells to fill the grid if needed
    while (dayCells.length < totalCellsNeeded) {
      dayCells.add(const SizedBox.shrink());
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        // Adjust childAspectRatio to make cells larger.
        // Screen height / (6 rows * cell height) / (screen width / 7 columns * cell width)
        // A value of 1.0 would mean square cells. Lower value means taller cells.
        // We want cells to fill the expanded height, so it's a bit tricky.
        // A common practice is to calculate based on screen size, or use a fixed ratio.
        // Let's try to make it fill.
        childAspectRatio:
            0.5, // Disesuaikan agar sel lebih besar dan 6 baris penuh
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

    // Sort scheduled events by start time for consistent display
    scheduledEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    bool hasEventsBeforeDisplayTime = false;
    bool hasEventsAfterDisplayTime = false;

    // Check for events outside display range
    for (var event in scheduledEvents) {
      if (event.startTime.isBefore(
        date.copyWith(hour: _displayStartTimeHour, minute: 0),
      )) {
        hasEventsBeforeDisplayTime = true;
      }
      if (event.endTime.isAfter(
        date.copyWith(hour: _displayEndTimeHour, minute: 0),
      )) {
        hasEventsAfterDisplayTime = true;
      }
    }

    // Logic for splitting overlapping events (simplified for MonthView)
    List<List<CalendarEvent>> eventColumns = _calculateMonthViewEventLayout(
      scheduledEvents,
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        // Navigate to DayView for this date
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DayViewCalendar(initialDate: date),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: isToday ? BorderRadius.circular(8) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date number
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
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
            ),
            // Full Day Event Indicator
            if (fullDayEvents.isNotEmpty)
              Container(
                height: 4,
                width: double.infinity,
                margin: const EdgeInsets.only(left: 4, right: 4, bottom: 2),
                decoration: BoxDecoration(
                  color: fullDayEvents.first.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            // Events indicator (blocks)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasEventsBeforeDisplayTime)
                      const Icon(
                        Icons.arrow_drop_up,
                        size: 16,
                        color: Colors.grey,
                      ),
                    // Display events based on calculated columns
                    Flexible(
                      // Use Flexible to limit height of event blocks
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // Align to top
                        children:
                            eventColumns.take(3).map((columnEvents) {
                              // Limit to 3 columns for space
                              return Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children:
                                      columnEvents.take(2).map((event) {
                                        // Limit to 2 events per column
                                        // Calculate block height (fixed for simplicity in month view)
                                        // We are not trying to represent exact duration scale here,
                                        // but rather presence and visual splitting.
                                        double blockHeight =
                                            12.0; // Fixed height for each event block
                                        return Container(
                                          height: blockHeight,
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: event.color,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    if (scheduledEvents.length >
                        (eventColumns.length * 2).clamp(
                          0,
                          scheduledEvents.length,
                        )) // Indicate more events if not all shown
                      Text(
                        '+${scheduledEvents.length - (eventColumns.length * 2)} more',
                        style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                      ),
                    if (hasEventsAfterDisplayTime)
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

  // Simplified event layout calculation for MonthView
  // Aims to put overlapping events side-by-side if space allows
  List<List<CalendarEvent>> _calculateMonthViewEventLayout(
    List<CalendarEvent> events,
  ) {
    if (events.isEmpty) return [];

    List<List<CalendarEvent>> columns = [];

    for (CalendarEvent event in events) {
      bool placed = false;
      for (int i = 0; i < columns.length; i++) {
        bool canPlaceInThisColumn = true;
        for (CalendarEvent existingEventInColumn in columns[i]) {
          if (_eventsOverlap(event, existingEventInColumn)) {
            canPlaceInThisColumn = false;
            break;
          }
        }
        if (canPlaceInThisColumn) {
          columns[i].add(event);
          placed = true;
          break;
        }
      }
      if (!placed) {
        columns.add([event]);
      }
    }
    return columns;
  }

  bool _eventsOverlap(CalendarEvent event1, CalendarEvent event2) {
    return event1.startTime.isBefore(event2.endTime) &&
        event2.startTime.isBefore(event1.endTime);
  }
}
