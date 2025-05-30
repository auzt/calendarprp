// lib/month_view.dart
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
  late DateTime _selectedDate;
  Map<String, List<CalendarEvent>> eventsPerDate = {};

  final int _displayStartTimeHour = 8;
  final int _displayEndTimeHour = 17;
  final int _maxEventColumnsInMiniView = 2;

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
    _initializeEvents();

    _pageController.addListener(() {
      final newMonthPageIndex = _pageController.page?.round();
      if (newMonthPageIndex == null) return;

      final newMonthCandidate = _getMonthForPageIndex(newMonthPageIndex);
      if (_focusedMonth.month != newMonthCandidate.month ||
          _focusedMonth.year != newMonthCandidate.year) {
        setState(() {
          _focusedMonth = newMonthCandidate;
          DateTime today = DateTime.now();
          if (today.year == _focusedMonth.year &&
              today.month == _focusedMonth.month) {
            _selectedDate = DateTime(today.year, today.month, today.day);
          } else {
            int targetDay = _selectedDate.day;
            int daysInNewFocusedMonth = DateUtils.getDaysInMonth(
              _focusedMonth.year,
              _focusedMonth.month,
            );
            if (targetDay > daysInNewFocusedMonth) {
              targetDay = daysInNewFocusedMonth;
            }
            _selectedDate = DateTime(
              _focusedMonth.year,
              _focusedMonth.month,
              targetDay,
            );
          }
        });
      }
    });
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
    // Event initialization code remains the same
    DateTime today = DateTime(2025, 5, 30);
    DateTime baseToday = DateTime(today.year, today.month, today.day);
    DateTime day14 = DateTime(2025, 5, 14);
    DateTime day15 = DateTime(2025, 5, 15);
    DateTime day20 = DateTime(2025, 5, 20);
    DateTime day21 = DateTime(2025, 5, 21); // Day with no events for testing
    eventsPerDate = {};
    eventsPerDate[_getDateKey(day14)] = [
      CalendarEvent(
        id: 'fullday_may14',
        title: 'Full Day Task',
        startTime: DateTime(day14.year, day14.month, day14.day, 0, 0),
        endTime: DateTime(day14.year, day14.month, day14.day, 23, 59),
        color: Colors.lightBlue.shade300,
      ),
      CalendarEvent(
        id: 'early_may14',
        title: 'Early Bird Meeting',
        startTime: day14.copyWith(hour: 7, minute: 0),
        endTime: day14.copyWith(hour: 7, minute: 45),
        color: Colors.purple,
      ),
    ];
    eventsPerDate[_getDateKey(day15)] = [
      CalendarEvent(
        id: 'fullday_may15',
        title: 'Conference Day',
        startTime: DateTime(day15.year, day15.month, day15.day, 0, 0),
        endTime: DateTime(day15.year, day15.month, day15.day, 23, 59),
        color: Colors.red.shade400,
      ),
      CalendarEvent(
        id: 'timed1_may15',
        title: 'Session 1',
        startTime: day15.copyWith(hour: 9, minute: 0),
        endTime: day15.copyWith(hour: 10, minute: 30),
        color: Colors.green,
      ),
      CalendarEvent(
        id: 'timed2_may15',
        title: 'Session 2',
        startTime: day15.copyWith(hour: 10, minute: 0),
        endTime: day15.copyWith(hour: 11, minute: 0),
        color: Colors.orange,
      ),
      CalendarEvent(
        id: 'timed3_may15',
        title: 'Lunch Briefing',
        startTime: day15.copyWith(hour: 12, minute: 30),
        endTime: day15.copyWith(hour: 13, minute: 30),
        color: Colors.teal,
      ),
      CalendarEvent(
        id: 'late_may15',
        title: 'Debrief',
        startTime: day15.copyWith(hour: 17, minute: 30),
        endTime: day15.copyWith(hour: 18, minute: 0),
        color: Colors.indigo,
      ),
    ];
    eventsPerDate[_getDateKey(day20)] = [
      CalendarEvent(
        id: 'late_may20',
        title: 'Evening Event',
        startTime: day20.copyWith(hour: 18, minute: 0),
        endTime: day20.copyWith(hour: 19, minute: 0),
        color: Colors.deepPurple,
      ),
    ];
    eventsPerDate[_getDateKey(baseToday)] = [
      CalendarEvent(
        id: 'today_event',
        title: 'Today Main Event',
        startTime: baseToday.copyWith(hour: 10),
        endTime: baseToday.copyWith(hour: 11, minute: 30),
        color: Colors.amber,
      ),
    ];
    // Day 21 will have no events by default (eventsPerDate[_getDateKey(day21)] will be null)
  }

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  List<CalendarEvent> _getEventsForDate(DateTime date) {
    return eventsPerDate[_getDateKey(date)] ?? [];
  }

  void _showEventPreviewPopup(BuildContext context, DateTime date) {
    List<CalendarEvent> events = _getEventsForDate(date);
    if (events.isEmpty)
      return; // Tambahan: jangan tampilkan popup jika tidak ada event

    events.sort((a, b) => a.startTime.compareTo(b.startTime));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Jadwal ${DateFormat('EEE, d MMM yy').format(date)}",
          ), // Format sedikit diubah
          contentPadding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 8.0),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.35,
            child: ListView.builder(
              // events.isEmpty sudah ditangani di atas
              itemCount: events.length,
              itemBuilder: (BuildContext context, int index) {
                CalendarEvent event = events[index];
                bool isFullDay =
                    event.startTime.hour == 0 &&
                    event.startTime.minute == 0 &&
                    event.endTime.hour == 23 &&
                    event.endTime.minute == 59 &&
                    DateUtils.isSameDay(event.startTime, event.endTime);
                return Card(
                  elevation: 1.0,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  color: event.color.withOpacity(0.1),
                  child: ListTile(
                    leading: Icon(Icons.circle, color: event.color, size: 12),
                    title: Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      isFullDay
                          ? "Sepanjang hari"
                          : "${DateFormat.Hm().format(event.startTime)} - ${DateFormat.Hm().format(event.endTime)}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    dense: true,
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Lihat Detail Hari"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DayViewCalendar(initialDate: date),
                  ),
                );
              },
            ),
            TextButton(
              child: const Text("Tutup"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('MMMM yyyy').format(_focusedMonth),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: false,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Go to Today',
            onPressed: () {
              DateTime today = DateTime.now();
              int pageIndex = _calculateInitialPageIndex(today);
              if (_pageController.hasClients &&
                  (_focusedMonth.month != today.month ||
                      _focusedMonth.year != today.year)) {
                _pageController.jumpToPage(pageIndex);
              } else {
                setState(() {
                  _focusedMonth = DateTime(today.year, today.month, 1);
                  _selectedDate = today;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeekdayHeader(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
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
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children:
            weekdays
                .map(
                  (day) => Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade700,
                        fontSize: 12,
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
    final int firstWeekdayOffset = (firstDayOfMonth.weekday + 6) % 7;
    final DateTime startDate = firstDayOfMonth.subtract(
      Duration(days: firstWeekdayOffset),
    );
    const int totalDaysInGrid = 6 * 7;

    return LayoutBuilder(
      builder: (context, constraints) {
        double availableHeight = constraints.maxHeight;
        double cellHeight = availableHeight / 6.0;
        double screenWidth = MediaQuery.of(context).size.width;
        double cellWidth = screenWidth / 7.0;
        double calculatedAspectRatio = cellWidth / cellHeight;
        if (cellHeight <= 0 ||
            cellWidth <= 0 ||
            calculatedAspectRatio.isNaN ||
            calculatedAspectRatio.isInfinite) {
          calculatedAspectRatio = 0.6;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: calculatedAspectRatio,
          ),
          itemCount: totalDaysInGrid,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final DateTime currentDate = startDate.add(Duration(days: index));
            if (index % 7 == 0) {
              int dayOfYear = int.parse(DateFormat("D").format(currentDate));
              int weekOfYear =
                  ((dayOfYear - currentDate.weekday + 10) / 7).floor();
              if (weekOfYear == 0) {
                weekOfYear =
                    ((dayOfYear +
                                DateTime(currentDate.year - 1, 12, 28).weekday -
                                1 +
                                10) /
                            7)
                        .floor();
              }
              return Stack(
                children: [
                  _buildDayCell(currentDate, month),
                  Positioned(
                    left: 3,
                    bottom: 3,
                    child: Text(
                      '$weekOfYear',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              );
            }
            return _buildDayCell(currentDate, month);
          },
        );
      },
    );
  }

  Widget _buildDayCell(DateTime date, DateTime displayMonth) {
    final bool isActualToday = DateUtils.isSameDay(date, DateTime.now());
    final bool isCurrentlySelected = DateUtils.isSameDay(date, _selectedDate);
    final bool isCurrentMonth = DateUtils.isSameMonth(date, displayMonth);

    List<CalendarEvent> dayEvents = _getEventsForDate(
      date,
    ); // Ambil event untuk tanggal ini
    bool hasAnyEvents = dayEvents.isNotEmpty; // Cek apakah ada event

    List<CalendarEvent> fullDayTypeEvents = [];
    List<CalendarEvent> timedEvents = [];

    if (hasAnyEvents) {
      // Hanya proses event jika ada
      for (var event in dayEvents) {
        if (event.startTime.hour == 0 &&
            event.startTime.minute == 0 &&
            event.endTime.hour == 23 &&
            event.endTime.minute == 59 &&
            DateUtils.isSameDay(event.startTime, event.endTime)) {
          fullDayTypeEvents.add(event);
        } else {
          timedEvents.add(event);
        }
      }
      timedEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    bool hasEventsBeforeDisplayWindow = false;
    bool hasEventsAfterDisplayWindow = false;
    if (isCurrentMonth && hasAnyEvents) {
      // Cek panah hanya jika ada event
      for (var event in timedEvents) {
        // timedEvents mungkin kosong jika semua full-day
        if (event.startTime.isBefore(
          date.copyWith(hour: _displayStartTimeHour),
        )) {
          hasEventsBeforeDisplayWindow = true;
        }
        if (event.endTime.isAfter(date.copyWith(hour: _displayEndTimeHour))) {
          hasEventsAfterDisplayWindow = true;
        }
      }
    }

    Color cellBackgroundColor = Colors.transparent;
    if (isActualToday) {
      cellBackgroundColor = Colors.yellow.shade300;
    } else if (isCurrentlySelected && isCurrentMonth) {
      cellBackgroundColor = Colors.grey.shade200;
    } else if (isCurrentlySelected && !isCurrentMonth) {
      cellBackgroundColor = Colors.grey.shade100;
    }

    return GestureDetector(
      onTap: () {
        // Update state pemilihan tanggal selalu berjalan
        setState(() {
          _selectedDate = date;
          if (!isCurrentMonth) {
            _focusedMonth = DateTime(date.year, date.month, 1);
            _pageController.jumpToPage(_calculateInitialPageIndex(date));
          }
        });
        // Hanya tampilkan popup jika ada event
        if (hasAnyEvents) {
          _showEventPreviewPopup(context, date);
        }
      },
      onDoubleTap:
          hasAnyEvents // Hanya aktifkan double tap jika ada event
              ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DayViewCalendar(initialDate: date),
                  ),
                );
              }
              : null, // Nonaktifkan double tap jika tidak ada event
      child: Container(
        decoration: BoxDecoration(
          color: cellBackgroundColor,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 0.5),
            left: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isCurrentMonth &&
                hasAnyEvents) // Tampilkan full day events hanya jika ada
              ...fullDayTypeEvents
                  .take(2)
                  .map(
                    (event) => Container(
                      height: 4,
                      margin: const EdgeInsets.only(
                        left: 2,
                        right: 2,
                        top: 1,
                        bottom: 1,
                      ),
                      decoration: BoxDecoration(
                        color: event.color,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 3.0,
                      left: 3.0,
                      right: 2.0,
                    ),
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 13, // PERBESAR FONT ANGKA TANGGAL
                        fontWeight:
                            isActualToday && isCurrentMonth
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color:
                            isCurrentMonth
                                ? (isActualToday
                                    ? Colors.black
                                    : Colors.black87)
                                : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  // Tampilkan mini schedule area hanya jika current month dan ada event
                  if (isCurrentMonth && hasAnyEvents)
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double miniDayViewHeight = constraints.maxHeight;
                          if (miniDayViewHeight <= 10)
                            return const SizedBox.shrink();

                          // Filter timed events yang masuk jendela waktu (timedEvents mungkin sudah kosong)
                          List<CalendarEvent> eventsInWindow =
                              timedEvents.where((e) {
                                DateTime windowStartTime = date.copyWith(
                                  hour: _displayStartTimeHour,
                                );
                                DateTime windowEndTime = date.copyWith(
                                  hour: _displayEndTimeHour,
                                );
                                return e.startTime.isBefore(windowEndTime) &&
                                    e.endTime.isAfter(windowStartTime);
                              }).toList();

                          // Jika tidak ada timedEvents di window, tidak perlu render bloknya
                          if (eventsInWindow.isEmpty &&
                              !hasEventsBeforeDisplayWindow &&
                              !hasEventsAfterDisplayWindow) {
                            return const SizedBox.shrink(); // Kosongkan jika tidak ada timed event di window dan tidak ada panah
                          }

                          List<List<CalendarEvent>> eventColumns =
                              _calculateEventLayoutForMiniView(
                                eventsInWindow,
                                _maxEventColumnsInMiniView,
                              );
                          List<Widget> positionedEventBlocks = [];
                          double totalWindowHours =
                              (_displayEndTimeHour - _displayStartTimeHour)
                                  .toDouble();
                          if (totalWindowHours <= 0 &&
                              eventsInWindow.isNotEmpty)
                            return const SizedBox.shrink(); // Hindari error jika window hours 0

                          double arrowContainerHeight =
                              (hasEventsBeforeDisplayWindow ||
                                      hasEventsAfterDisplayWindow)
                                  ? 16.0
                                  : 0.0;
                          double drawableHeight = max(
                            0,
                            miniDayViewHeight - arrowContainerHeight,
                          );

                          if (eventsInWindow.isNotEmpty &&
                              totalWindowHours > 0) {
                            // Hanya proses jika ada event di window dan window valid
                            for (
                              int colIdx = 0;
                              colIdx < eventColumns.length;
                              colIdx++
                            ) {
                              double columnWidth =
                                  (constraints.maxWidth / eventColumns.length) -
                                  (eventColumns.length > 1 ? 0.5 : 0);
                              for (CalendarEvent event
                                  in eventColumns[colIdx]) {
                                DateTime eventStartClamped =
                                    event.startTime.isBefore(
                                          date.copyWith(
                                            hour: _displayStartTimeHour,
                                          ),
                                        )
                                        ? date.copyWith(
                                          hour: _displayStartTimeHour,
                                        )
                                        : event.startTime;
                                DateTime eventEndClamped =
                                    event.endTime.isAfter(
                                          date.copyWith(
                                            hour: _displayEndTimeHour,
                                          ),
                                        )
                                        ? date.copyWith(
                                          hour: _displayEndTimeHour,
                                        )
                                        : event.endTime;
                                if (eventStartClamped.isAfter(
                                      eventEndClamped,
                                    ) ||
                                    eventStartClamped.isAtSameMomentAs(
                                      eventEndClamped,
                                    ))
                                  continue;
                                double startOffsetHours =
                                    (eventStartClamped.hour +
                                        eventStartClamped.minute / 60.0) -
                                    _displayStartTimeHour;
                                double endOffsetHours =
                                    (eventEndClamped.hour +
                                        eventEndClamped.minute / 60.0) -
                                    _displayStartTimeHour;
                                double top =
                                    (startOffsetHours / totalWindowHours) *
                                    drawableHeight;
                                double height =
                                    ((endOffsetHours - startOffsetHours) /
                                        totalWindowHours) *
                                    drawableHeight;
                                height = max(2.0, height);
                                if (top < 0) top = 0;
                                if (height < 0) height = 0;
                                if (top + height > drawableHeight)
                                  height = drawableHeight - top;
                                if (height < 0) height = 0;
                                positionedEventBlocks.add(
                                  Positioned(
                                    top: top,
                                    left:
                                        colIdx *
                                        (columnWidth +
                                            (eventColumns.length > 1
                                                ? 0.5
                                                : 0)),
                                    width: columnWidth,
                                    height: height,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: event.color.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(
                                          0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                          return Container(
                            margin: const EdgeInsets.only(
                              top: 1,
                              right: 1,
                              bottom: 1,
                            ),
                            width: double.infinity,
                            child: Stack(
                              children: [
                                ...positionedEventBlocks,
                                if (hasEventsBeforeDisplayWindow ||
                                    hasEventsAfterDisplayWindow)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    height: arrowContainerHeight,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        if (hasEventsBeforeDisplayWindow)
                                          Icon(
                                            Icons.arrow_drop_up,
                                            size: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        if (hasEventsBeforeDisplayWindow &&
                                            hasEventsAfterDisplayWindow)
                                          SizedBox(width: 2),
                                        if (hasEventsAfterDisplayWindow)
                                          Icon(
                                            Icons.arrow_drop_down,
                                            size: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Expanded(child: Container()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<List<CalendarEvent>> _calculateEventLayoutForMiniView(
    List<CalendarEvent> events,
    int maxColumns,
  ) {
    if (events.isEmpty) return [];
    List<CalendarEvent> sortedEvents = List.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    List<List<CalendarEvent>> columns = [];
    for (CalendarEvent event in sortedEvents) {
      bool placed = false;
      for (int i = 0; i < columns.length; i++) {
        bool canPlaceInThisColumn = true;
        for (CalendarEvent existingEvent in columns[i]) {
          if (_eventsOverlap(event, existingEvent)) {
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
        if (columns.length < maxColumns) {
          columns.add([event]);
        } else {
          if (columns.isNotEmpty) {
            columns.last.add(event);
          } else {
            columns.add([event]);
          }
        }
      }
    }
    return columns;
  }

  bool _eventsOverlap(CalendarEvent event1, CalendarEvent event2) {
    return event1.startTime.isBefore(event2.endTime) &&
        event2.startTime.isBefore(event1.endTime);
  }
}
