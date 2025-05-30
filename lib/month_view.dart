// lib/month_view.dart (REVISI BLOK JADWAL & FULL DAY/TASK/BIRTHDAY)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calendar/day_view.dart'; // Import CalendarEvent model
import 'dart:math'; // Untuk fungsi max dan min

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
  final int _displayEndTimeHour = 17; // 5 PM (5 PM = 17:00)

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      1,
    );
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
    final DateTime epoch = DateTime(2000, 1, 1);
    return ((date.year - epoch.year) * 12) + (date.month - epoch.month);
  }

  DateTime _getMonthForPageIndex(int index) {
    final DateTime epoch = DateTime(2000, 1, 1);
    return DateTime(epoch.year + (index ~/ 12), epoch.month + (index % 12));
  }

  void _initializeEvents() {
    // Current date is Friday, May 30, 2025 at 10:20:15 AM WIB.
    DateTime today = DateTime(2025, 5, 30); // Simulate today as May 30, 2025
    DateTime baseToday = DateTime(today.year, today.month, today.day);
    DateTime tomorrow = baseToday.add(const Duration(days: 1)); // May 31
    DateTime june1 = baseToday.add(const Duration(days: 2)); // June 1
    DateTime june3 = baseToday.add(const Duration(days: 4)); // June 3
    DateTime june6 = baseToday.add(const Duration(days: 7)); // June 6
    DateTime may15 = DateTime(today.year, today.month, 15); // May 15
    DateTime may14 = DateTime(today.year, today.month, 14); // May 14
    DateTime may13 = DateTime(today.year, today.month, 13); // May 13

    // Clear existing events for fresh start in Month View
    eventsPerDate = {};

    // Events for May 30
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

    // Events for May 31
    eventsPerDate[_getDateKey(tomorrow)] = [
      CalendarEvent(
        id: 't1',
        title: 'Client Call',
        startTime: tomorrow.copyWith(hour: 11, minute: 0),
        endTime: tomorrow.copyWith(hour: 12, minute: 0),
        color: Colors.red,
      ),
    ];

    // Full day event example for June 1
    eventsPerDate[_getDateKey(june1)] = [
      CalendarEvent(
        id: 'fd1',
        title: 'Full Day Workshop',
        startTime: DateTime(june1.year, june1.month, june1.day, 0, 0),
        endTime: DateTime(june1.year, june1.month, june1.day, 23, 59),
        color: Colors.teal,
      ),
      CalendarEvent(
        // Other event on the same day
        id: 'fd2',
        title: 'Quick Sync',
        startTime: june1.copyWith(hour: 10, minute: 0),
        endTime: june1.copyWith(hour: 10, minute: 30),
        color: Colors.indigo,
      ),
    ];

    // Events with intentional overlap for splitting test for June 3
    eventsPerDate[_getDateKey(june3)] = [
      CalendarEvent(
        id: 'overlap1',
        title: 'Meeting A',
        startTime: june3.copyWith(hour: 10, minute: 0),
        endTime: june3.copyWith(hour: 11, minute: 30),
        color: Colors.deepOrange,
      ),
      CalendarEvent(
        id: 'overlap2',
        title: 'Meeting B',
        startTime: june3.copyWith(hour: 10, minute: 45),
        endTime: june3.copyWith(hour: 12, minute: 0),
        color: Colors.cyan,
      ),
      CalendarEvent(
        id: 'overlap3',
        title: 'Meeting C',
        startTime: june3.copyWith(hour: 11, minute: 0),
        endTime: june3.copyWith(hour: 12, minute: 30),
        color: Colors.pink,
      ),
      CalendarEvent(
        // Another one to force more columns
        id: 'overlap4',
        title: 'Meeting D',
        startTime: june3.copyWith(hour: 10, minute: 15),
        endTime: june3.copyWith(hour: 11, minute: 0),
        color: Colors.brown,
      ),
    ];

    // Another event, spanning across midnight for June 6
    eventsPerDate[_getDateKey(june6)] = [
      CalendarEvent(
        id: 'span1',
        title: 'Cross-day event',
        startTime: june6.copyWith(hour: 22, minute: 0),
        endTime: june6
            .add(const Duration(days: 1))
            .copyWith(hour: 2, minute: 0),
        color: Colors.brown,
      ),
    ];

    // Some events in the middle of the month (May 15)
    eventsPerDate[_getDateKey(may15)] = [
      CalendarEvent(
        id: 'mm1',
        title: 'Project Deadline',
        startTime: may15.copyWith(hour: 16, minute: 0),
        endTime: may15.copyWith(hour: 17, minute: 0),
        color: Colors.deepPurple,
      ),
      // Contoh acara yang tumpang tindih untuk tanggal 15
      CalendarEvent(
        id: 'mm2',
        title: 'Review A',
        startTime: may15.copyWith(hour: 15, minute: 0),
        endTime: may15.copyWith(hour: 16, minute: 30),
        color: Colors.indigo,
      ),
      CalendarEvent(
        id: 'mm3',
        title: 'Review B',
        startTime: may15.copyWith(hour: 15, minute: 45),
        endTime: may15.copyWith(hour: 17, minute: 0),
        color: Colors.lime,
      ),
    ];

    // Contoh Task dan Birthday untuk tanggal 14 dan 13
    eventsPerDate[_getDateKey(may14)] = [
      CalendarEvent(
        id: 'task1',
        title: 'Selesaikan Laporan',
        startTime: DateTime(
          may14.year,
          may14.month,
          may14.day,
          0,
          0,
        ), // Task full-day (seperti full day event)
        endTime: DateTime(may14.year, may14.month, may14.day, 23, 59),
        color: Colors.grey, // Warna task
      ),
      CalendarEvent(
        id: 'regular1',
        title: 'Diskusi Desain',
        startTime: may14.copyWith(hour: 10, minute: 0),
        endTime: may14.copyWith(hour: 11, minute: 0),
        color: Colors.lightBlue,
      ),
    ];

    eventsPerDate[_getDateKey(may13)] = [
      CalendarEvent(
        id: 'bday1',
        title: 'Ulang Tahun Andi',
        startTime: DateTime(
          may13.year,
          may13.month,
          may13.day,
          0,
          0,
        ), // Birthday full-day
        endTime: DateTime(may13.year, may13.month, may13.day, 23, 59),
        color: Colors.pink, // Warna birthday
      ),
      CalendarEvent(
        id: 'regular2',
        title: 'Presentasi Internal',
        startTime: may13.copyWith(hour: 13, minute: 0),
        endTime: may13.copyWith(hour: 14, minute: 30),
        color: Colors.amber,
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
    final DateTime firstDayOfMonth = DateTime(month.year, month.month, 1);
    final int firstWeekdayOfMonth = firstDayOfMonth.weekday % 7;

    final DateTime startDate = firstDayOfMonth.subtract(
      Duration(days: firstWeekdayOfMonth),
    );

    const int totalDaysInGrid = 6 * 7;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.5, // Rasio ini disesuaikan untuk 6 baris penuh
      ),
      itemCount: totalDaysInGrid,
      itemBuilder: (context, index) {
        final DateTime currentDate = startDate.add(Duration(days: index));
        return _buildDayCell(currentDate, month);
      },
    );
  }

  Widget _buildDayCell(DateTime date, DateTime displayMonth) {
    final bool isToday =
        date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;
    final bool isSelected =
        date.day == _selectedDate.day &&
        date.month == _selectedDate.month &&
        date.year == _selectedDate.year;
    final bool isCurrentMonth =
        date.month == displayMonth.month && date.year == displayMonth.year;

    List<CalendarEvent> dayEvents = _getEventsForDate(date);
    List<CalendarEvent> fullDayAndTaskBirthdayEvents = [];
    List<CalendarEvent> scheduledTimeEvents = [];

    for (var event in dayEvents) {
      // Logic to classify full day events, tasks, and birthdays
      // For simplicity, any event spanning the entire day (00:00 to 23:59) is considered 'full-day' for display purposes here.
      if (event.startTime.hour == 0 &&
          event.startTime.minute == 0 &&
          event.endTime.hour == 23 &&
          event.endTime.minute == 59 &&
          event.startTime.day == event.endTime.day) {
        fullDayAndTaskBirthdayEvents.add(event);
      } else {
        scheduledTimeEvents.add(event);
      }
    }

    // Sort scheduled events by start time for consistent display
    scheduledTimeEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    bool hasEventsBeforeDisplayTime = false;
    bool hasEventsAfterDisplayTime = false;

    // Check for events outside display range
    for (var event in scheduledTimeEvents) {
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
    // We aim for maximum 3 columns for scheduled events
    List<List<CalendarEvent>> eventColumns = _calculateMonthViewEventLayout(
      scheduledTimeEvents,
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          if (!isCurrentMonth) {
            _focusedMonth = DateTime(date.year, date.month, 1);
            _pageController.jumpToPage(_calculateInitialPageIndex(date));
          }
        });
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
            // Full Day / Task / Birthday Event Indicators (Garis Panjang)
            ...fullDayAndTaskBirthdayEvents
                .map(
                  (event) => Container(
                    height: 4, // Tinggi garis
                    width: double.infinity, // Panjang penuh
                    margin: const EdgeInsets.only(left: 4, right: 4, bottom: 2),
                    decoration: BoxDecoration(
                      color: event.color, // Warna event
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )
                .take(2), // Ambil maksimal 2 garis untuk menghindari overflow
            // Events indicator (blocks for scheduled time events)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double availableHeight = constraints.maxHeight;

                  // Perkirakan tinggi yang dibutuhkan untuk panah dan teks 'more'
                  double reservedHeightForIndicators = 0;
                  if (hasEventsBeforeDisplayTime)
                    reservedHeightForIndicators += 16;
                  if (hasEventsAfterDisplayTime)
                    reservedHeightForIndicators += 16;

                  // Hitung tinggi yang tersisa untuk blok event
                  double remainingHeightForBlocks = max(
                    0,
                    availableHeight - reservedHeightForIndicators,
                  );

                  // Tinggi per blok event (fixed height per block for clarity)
                  const double eventBlockHeight = 12.0;
                  const double eventBlockMargin = 2.0;
                  final double totalEventBlockSpace =
                      eventBlockHeight + eventBlockMargin;

                  // Hitung berapa banyak total blok event yang bisa ditampilkan secara vertikal
                  int maxTotalBlocksVertically =
                      (remainingHeightForBlocks / totalEventBlockSpace).floor();
                  maxTotalBlocksVertically = max(
                    0,
                    maxTotalBlocksVertically,
                  ); // Pastikan tidak negatif

                  // Batasi jumlah kolom yang akan ditampilkan (misal, maks 3 kolom)
                  int maxColumnsToDisplay = min(eventColumns.length, 3);
                  if (maxColumnsToDisplay == 0 &&
                      scheduledTimeEvents.isNotEmpty) {
                    maxColumnsToDisplay = 1; // Minimal 1 kolom jika ada event
                  } else if (maxColumnsToDisplay == 0) {
                    return SizedBox.shrink(); // Tidak ada event, tidak ada tampilan
                  }

                  // Hitung berapa banyak event yang bisa ditampilkan per kolom
                  int maxEventsPerColumn =
                      (maxTotalBlocksVertically / maxColumnsToDisplay).floor();
                  maxEventsPerColumn = max(
                    0,
                    maxEventsPerColumn,
                  ); // Pastikan tidak negatif

                  List<Widget> eventWidgets = [];

                  if (hasEventsBeforeDisplayTime) {
                    eventWidgets.add(
                      const Icon(
                        Icons.arrow_drop_up,
                        size: 16,
                        color: Colors.grey,
                      ),
                    );
                  }

                  // Build event blocks in columns
                  int eventsShownCount = 0;
                  List<Widget> columnWidgets = [];
                  for (
                    int colIndex = 0;
                    colIndex < maxColumnsToDisplay;
                    colIndex++
                  ) {
                    List<Widget> currentColumnBlocks = [];
                    if (colIndex < eventColumns.length) {
                      List<CalendarEvent> currentEventsInThisColumn =
                          eventColumns[colIndex];
                      for (
                        int i = 0;
                        i <
                            min(
                              currentEventsInThisColumn.length,
                              maxEventsPerColumn,
                            );
                        i++
                      ) {
                        currentColumnBlocks.add(
                          Container(
                            height: eventBlockHeight,
                            margin: const EdgeInsets.symmetric(
                              vertical: eventBlockMargin / 2,
                            ),
                            decoration: BoxDecoration(
                              color: currentEventsInThisColumn[i].color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                        eventsShownCount++;
                      }
                    }
                    columnWidgets.add(
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: currentColumnBlocks,
                        ),
                      ),
                    );
                  }
                  if (columnWidgets.isNotEmpty) {
                    eventWidgets.add(
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: columnWidgets,
                      ),
                    );
                  }

                  // Add "more" indicator if there are more events than can be shown
                  if (scheduledTimeEvents.length > eventsShownCount) {
                    eventWidgets.add(
                      Text(
                        '+${scheduledTimeEvents.length - eventsShownCount} more',
                        style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (hasEventsAfterDisplayTime) {
                    eventWidgets.add(
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 16,
                        color: Colors.grey,
                      ),
                    );
                  }

                  // Wrap with Flexible to constrain overall height within Expanded
                  return Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Takes minimum space
                      children: eventWidgets,
                    ),
                  );
                },
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
