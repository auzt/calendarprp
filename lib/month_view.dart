// lib/month_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calendar/day_view.dart'; // Import CalendarEvent model
import 'dart:math'; // Untuk fungsi max dan min

class MonthViewCalendar extends StatefulWidget {
  final DateTime initialDate;

  const MonthViewCalendar({super.key, required this.initialDate}); //

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
  // This helps decide when to show up/down arrows if events are outside this visual window.
  // Based on screenshot, events seem to be primarily shown, so this might be less critical
  // unless a day cell gets extremely crowded.
  final int _displayStartTimeHour = 8; //
  final int _displayEndTimeHour = 17; // 5 PM (5 PM = 17:00)

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      1,
    ); //
    _pageController = PageController(
      initialPage: _calculateInitialPageIndex(widget.initialDate),
    ); //
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    ); //
    _initializeEvents(); // Initialize dummy events for demonstration

    // Add listener to rebuild when page changes to update selectedDate if needed
    _pageController.addListener(() {
      final newMonth = _getMonthForPageIndex(_pageController.page!.round());
      if (_focusedMonth.month != newMonth.month ||
          _focusedMonth.year != newMonth.year) {
        setState(() {
          _focusedMonth = newMonth;
          // If the selectedDate is not in the new focused month,
          // update selectedDate to the first visible day of the new focused month.
          // Or, more simply, if today is in this new month, select today.
          DateTime today = DateTime.now();
          if (today.month == _focusedMonth.month &&
              today.year == _focusedMonth.year) {
            _selectedDate = DateTime(today.year, today.month, today.day);
          } else {
            // If selected date is not in the current month, update it
            if (_selectedDate.month != _focusedMonth.month ||
                _selectedDate.year != _focusedMonth.year) {
              _selectedDate = DateTime(
                _focusedMonth.year,
                _focusedMonth.month,
                1,
              );
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose(); //
    super.dispose(); //
  }

  int _calculateInitialPageIndex(DateTime date) {
    final DateTime epoch = DateTime(
      2000,
      1,
      1,
    ); // Reference epoch for page calculation
    return ((date.year - epoch.year) * 12) + (date.month - epoch.month); //
  }

  DateTime _getMonthForPageIndex(int index) {
    final DateTime epoch = DateTime(2000, 1, 1); //
    return DateTime(epoch.year + (index ~/ 12), epoch.month + (index % 12)); //
  }

  void _initializeEvents() {
    // Current time is Friday, May 30, 2025. Data based on screenshot and provided file.
    DateTime today = DateTime(2025, 5, 30); // Screenshot date
    DateTime baseToday = DateTime(today.year, today.month, today.day); //

    // Dates from screenshot context & existing file
    DateTime day14 = DateTime(2025, 5, 14); //
    DateTime day15 = DateTime(2025, 5, 15); //
    DateTime day20 = DateTime(2025, 5, 20); // Implied from screenshot for arrow

    eventsPerDate = {}; //

    // Events for May 14, 2025 (matching screenshot style for full day)
    eventsPerDate[_getDateKey(day14)] = [
      CalendarEvent(
        id: 'task1_may14',
        title: 'Task Full Day', // Represents a full-day style event/task
        startTime: DateTime(day14.year, day14.month, day14.day, 0, 0), //
        endTime: DateTime(day14.year, day14.month, day14.day, 23, 59), //
        color: Colors.lightBlue.shade300, // Light blue line
      ),
    ];

    // Events for May 15, 2025 (multiple overlapping, like screenshot)
    eventsPerDate[_getDateKey(day15)] = [
      CalendarEvent(
        // Full red line at the top
        id: 'fullday_may15',
        title: 'All Day Conference',
        startTime: DateTime(day15.year, day15.month, day15.day, 0, 0),
        endTime: DateTime(day15.year, day15.month, day15.day, 23, 59),
        color: Colors.red.shade400,
      ),
      CalendarEvent(
        // Simulating the three smaller blocks
        id: 'block1_may15',
        title: 'Meeting A',
        startTime: day15.copyWith(hour: 9, minute: 0),
        endTime: day15.copyWith(hour: 10, minute: 0),
        color: Colors.lightBlue.shade200,
      ),
      CalendarEvent(
        id: 'block2_may15',
        title: 'Meeting B',
        startTime: day15.copyWith(hour: 9, minute: 15), // Overlap
        endTime: day15.copyWith(hour: 10, minute: 15),
        color: Colors.lightBlue.shade300,
      ),
      CalendarEvent(
        id: 'block3_may15',
        title: 'Meeting C',
        startTime: day15.copyWith(hour: 9, minute: 30), // Overlap
        endTime: day15.copyWith(hour: 10, minute: 30),
        color: Colors.lightBlue.shade400,
      ),
      CalendarEvent(
        // Another event to potentially push things and test "more"
        id: 'block4_may15',
        title: 'Follow up',
        startTime: day15.copyWith(hour: 11, minute: 0),
        endTime: day15.copyWith(hour: 12, minute: 0),
        color: Colors.green,
      ),
    ];

    // Event for May 20 to potentially show a down arrow (event later in day)
    eventsPerDate[_getDateKey(day20)] = [
      CalendarEvent(
        id: 'late_may20',
        title: 'Evening Event',
        startTime: day20.copyWith(hour: 18, minute: 0), // Outside 8-5 window
        endTime: day20.copyWith(hour: 19, minute: 0),
        color: Colors.purple,
      ),
    ];

    // Events for May 30 (Today in screenshot)
    // No specific event markers in screenshot for 30, but can add some.
    eventsPerDate[_getDateKey(baseToday)] = [
      CalendarEvent(
        id: 'today_meeting_1',
        title: 'Morning Standup',
        startTime: baseToday.copyWith(hour: 9, minute: 0),
        endTime: baseToday.copyWith(hour: 9, minute: 30),
        color: Colors.orange,
      ),
      CalendarEvent(
        id: 'today_meeting_2',
        title: 'Team Sync',
        startTime: baseToday.copyWith(hour: 14, minute: 0),
        endTime: baseToday.copyWith(hour: 15, minute: 0),
        color: Colors.teal,
      ),
    ];
  }

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date); // Consistent key format
  }

  List<CalendarEvent> _getEventsForDate(DateTime date) {
    return eventsPerDate[_getDateKey(date)] ?? []; //
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('MMMM yyyy').format(_focusedMonth), // Format: May 2025
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white, // Match screenshot
        foregroundColor: Colors.black, // Match screenshot
        centerTitle: false, // Align to left like screenshot
        elevation: 1, // Slight shadow
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Go to Today',
            onPressed: () {
              DateTime today = DateTime.now();
              int pageIndex = _calculateInitialPageIndex(today);
              if (_pageController.hasClients) {
                _pageController.jumpToPage(pageIndex);
              }
              setState(() {
                _focusedMonth = DateTime(today.year, today.month, 1);
                _selectedDate = DateTime(today.year, today.month, today.day);
              });
            },
          ),
          // Add other icons from screenshot if needed (e.g., view type)
        ],
      ),
      body: Column(
        children: [
          _buildWeekdayHeader(), //
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection:
                  Axis.vertical, // Scroll vertikal untuk ganti bulan
              onPageChanged: (index) {
                // Listener in initState handles state update
              },
              itemBuilder: (context, index) {
                final month = _getMonthForPageIndex(index);
                return _buildMonthGrid(month); //
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    final List<String> weekdays = [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ]; // Screenshot uses SUN first
    // Adjusting to start with MON as per typical calendars, but screenshot seems to start MON
    // final List<String> weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Match screenshot
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10), // Increased padding
      child: Row(
        children:
            weekdays
                .map(
                  (day) => Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.normal, // Screenshot is not bold
                        color: Colors.grey.shade700, // Match screenshot
                        fontSize: 12, // Match screenshot
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildMonthGrid(DateTime month) {
    final DateTime firstDayOfMonth = DateTime(month.year, month.month, 1); //
    // Weekday in Dart: 1 (Mon) to 7 (Sun). Screenshot starts week on Monday.
    // To match a grid starting Monday:
    // If firstDayOfMonth.weekday is 1 (Mon), offset is 0.
    // If firstDayOfMonth.weekday is 7 (Sun), offset is 6.
    final int firstWeekdayOffset =
        (firstDayOfMonth.weekday + 6) % 7; // Mon=0, Tue=1 ... Sun=6

    final DateTime startDate = firstDayOfMonth.subtract(
      Duration(days: firstWeekdayOffset),
    ); //

    const int totalDaysInGrid =
        6 * 7; // Show 6 weeks to cover all month layouts

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, //
        childAspectRatio:
            0.65, // Adjusted for more height, to show events & week numbers
      ),
      itemCount: totalDaysInGrid, //
      physics:
          const NeverScrollableScrollPhysics(), // PageView handles scrolling
      itemBuilder: (context, index) {
        final DateTime currentDate = startDate.add(Duration(days: index)); //
        // Add week number to the left of Monday cell
        if (index % 7 == 0) {
          // If it's the first day of the week (Monday)
          int weekOfYear =
              ((currentDate
                              .difference(DateTime(currentDate.year, 1, 1))
                              .inDays +
                          DateTime(currentDate.year, 1, 1).weekday) /
                      7)
                  .ceil();
          return Stack(
            // Use Stack to overlay week number
            children: [
              _buildDayCell(currentDate, month),
              Positioned(
                left: 3,
                top: 3,
                child: Text(
                  '$weekOfYear', // Calculate week number
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                ),
              ),
            ],
          );
        }
        return _buildDayCell(currentDate, month); //
      },
    );
  }

  Widget _buildDayCell(DateTime date, DateTime displayMonth) {
    final bool isToday = DateUtils.isSameDay(date, DateTime.now()); //
    final bool isSelected = DateUtils.isSameDay(date, _selectedDate); //
    final bool isCurrentMonth = DateUtils.isSameMonth(date, displayMonth); //

    List<CalendarEvent> dayEvents = _getEventsForDate(date); //
    List<CalendarEvent> fullDayTypeEvents = []; // For horizontal bars
    List<CalendarEvent> timedEvents = []; // For small blocks

    for (var event in dayEvents) {
      // Heuristic: if event is 00:00 to 23:59, it's a full-day type for display
      if (event.startTime.hour == 0 &&
          event.startTime.minute == 0 &&
          event.endTime.hour == 23 &&
          event.endTime.minute == 59 &&
          DateUtils.isSameDay(event.startTime, event.endTime)) {
        fullDayTypeEvents.add(event); //
      } else {
        timedEvents.add(event); //
      }
    }
    timedEvents.sort((a, b) => a.startTime.compareTo(b.startTime)); //

    // Check for events outside the "typical" viewable part of the day for arrows
    bool hasEventsBeforeDisplayWindow = false; //
    bool hasEventsAfterDisplayWindow = false; //
    if (isCurrentMonth) {
      // Only show arrows for current month days
      for (var event in timedEvents) {
        if (event.startTime.hour < _displayStartTimeHour) {
          hasEventsBeforeDisplayWindow = true; //
        }
        if (event.endTime.hour >= _displayEndTimeHour) {
          // Use >= for end time check
          hasEventsAfterDisplayWindow = true; //
        }
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date; //
          if (!isCurrentMonth) {
            _focusedMonth = DateTime(date.year, date.month, 1); //
            _pageController.jumpToPage(_calculateInitialPageIndex(date)); //
          }
        });
        // Optionally navigate to DayView:
        // Navigator.push(context, MaterialPageRoute(builder: (context) => DayViewCalendar(initialDate: date)));
      },
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Colors.yellow.shade300
                  : Colors.transparent, // Yellow for selected (today)
          border: Border(
            // Mimic screenshot cell borders
            top: BorderSide(color: Colors.grey.shade300, width: 0.5),
            left: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date number
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 13, // Slightly smaller than screenshot header
                    fontWeight: FontWeight.normal,
                    color:
                        isCurrentMonth
                            ? (isToday
                                ? Colors.black
                                : Colors.black87) // Today black, others normal
                            : Colors.grey.shade400, //
                  ),
                ),
              ),
            ),

            // Full Day type Event Indicators (Horizontal Bars like screenshot May 14, 15)
            if (isCurrentMonth)
              ...fullDayTypeEvents
                  .take(2)
                  .map(
                    (event) => Container(
                      // Max 2 full-day bars
                      height: 5, // Height of the bar
                      margin: const EdgeInsets.only(
                        left: 2,
                        right: 2,
                        bottom: 1.5,
                      ), //
                      decoration: BoxDecoration(
                        color: event.color, //
                        borderRadius: BorderRadius.circular(1), //
                      ),
                    ),
                  ),

            // Timed Event Indicators (Small blocks, max 3 side-by-side)
            if (isCurrentMonth && timedEvents.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: LayoutBuilder(
                  // Use LayoutBuilder to determine available width for blocks
                  builder: (context, constraints) {
                    const int maxBlocksToShow = 3;
                    const double blockHeight = 5.0; //
                    const double blockMargin = 1.0;
                    double availableWidth = constraints.maxWidth;
                    double blockWidth =
                        (availableWidth - (maxBlocksToShow - 1) * blockMargin) /
                        maxBlocksToShow;
                    blockWidth = max(5.0, blockWidth); // ensure minimum width

                    List<Widget> eventBlockWidgets = [];
                    int shownBlocks = 0;

                    // Simple layout: show first few events as blocks
                    for (
                      int i = 0;
                      i < timedEvents.length && shownBlocks < maxBlocksToShow;
                      i++
                    ) {
                      eventBlockWidgets.add(
                        Container(
                          width: blockWidth,
                          height: blockHeight,
                          margin: EdgeInsets.only(
                            right:
                                (shownBlocks < maxBlocksToShow - 1)
                                    ? blockMargin
                                    : 0,
                          ),
                          decoration: BoxDecoration(
                            color: timedEvents[i].color,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      );
                      shownBlocks++;
                    }

                    if (eventBlockWidgets.isEmpty)
                      return const SizedBox.shrink();

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Center blocks
                          children: eventBlockWidgets,
                        ),
                        if (timedEvents.length > shownBlocks)
                          Padding(
                            padding: const EdgeInsets.only(top: 1.0),
                            child: Text(
                              '+${timedEvents.length - shownBlocks}', // Show how many more
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            const Spacer(), // Pushes arrow to the bottom
            // Arrow indicator like on May 20 in screenshot (downward arrow)
            if (isCurrentMonth &&
                (hasEventsBeforeDisplayWindow || hasEventsAfterDisplayWindow))
              Align(
                alignment: Alignment.bottomCenter,
                child: Icon(
                  hasEventsAfterDisplayWindow
                      ? Icons.arrow_drop_down_sharp
                      : Icons.arrow_drop_up_sharp, //
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            if (isCurrentMonth &&
                (hasEventsBeforeDisplayWindow || hasEventsAfterDisplayWindow))
              const SizedBox(height: 2), // Small padding for the arrow
          ],
        ),
      ),
    );
  }

  // This simplified layout is not used as blocks are now fixed height/count
  // List<List<CalendarEvent>> _calculateMonthViewEventLayout(List<CalendarEvent> events) { ... }
  // bool _eventsOverlap(CalendarEvent event1, CalendarEvent event2) { ... }
}
