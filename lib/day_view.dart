import 'package:flutter/material.dart';
import 'dart:async';

// Model untuk Event
class CalendarEvent {
  String id;
  String title;
  DateTime startTime;
  DateTime endTime;
  Color color;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.color = Colors.blue,
  });

  CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    Color? color,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
    );
  }
}

// Model untuk layout event (untuk splitting)
class EventLayout {
  CalendarEvent event;
  double left;
  double width;
  int column;
  int totalColumns;

  EventLayout({
    required this.event,
    required this.left,
    required this.width,
    required this.column,
    required this.totalColumns,
  });
}

class DayViewCalendar extends StatefulWidget {
  final DateTime initialDate;

  const DayViewCalendar({super.key, required this.initialDate});

  @override
  State<DayViewCalendar> createState() => _DayViewCalendarState();
}

class _DayViewCalendarState extends State<DayViewCalendar> {
  late DateTime selectedDate;
  Map<String, List<CalendarEvent>> eventsPerDate = {};

  final double hourHeight = 60.0;
  final double timeColumnWidth = 80.0;
  final int minuteInterval = 5;
  late ScrollController _scrollController;
  final GlobalKey _scrollKey = GlobalKey();

  // Untuk drag indicator
  bool _isDragging = false;
  DateTime? _dragTargetTime;
  CalendarEvent? _draggedEvent;
  DateTime? _originalSelectedDateOnDragStart;
  DateTime? _lastUpdateTime;

  // Untuk auto-scroll
  Timer? _autoScrollTimer;
  double _autoScrollVelocity = 0.0;
  static const double _kAutoScrollPixelsPerTick = 8.0;
  static const Duration _kAutoScrollTimerDuration = Duration(milliseconds: 16);

  // Untuk undo functionality
  CalendarEvent? _lastMovedEvent;
  DateTime? _originalEventDateForUndo;
  DateTime? _originalStartTimeForUndo;
  DateTime? _originalEndTimeForUndo;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    _scrollController = ScrollController();
    _initializeEvents();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  void _initializeEvents() {
    DateTime today = DateTime.now();
    DateTime baseToday = DateTime(today.year, today.month, today.day);
    DateTime yesterday = baseToday.subtract(const Duration(days: 1));
    DateTime tomorrow = baseToday.add(const Duration(days: 1));

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
    ];

    eventsPerDate[_getDateKey(yesterday)] = [
      CalendarEvent(
        id: 'y1',
        title: 'Planning Sprint',
        startTime: yesterday.copyWith(hour: 10, minute: 0),
        endTime: yesterday.copyWith(hour: 11, minute: 0),
        color: Colors.purple,
      ),
      CalendarEvent(
        id: 'y2',
        title: 'Lunch Meeting',
        startTime: yesterday.copyWith(hour: 12, minute: 0),
        endTime: yesterday.copyWith(hour: 13, minute: 30),
        color: Colors.teal,
      ),
    ];

    eventsPerDate[_getDateKey(tomorrow)] = [
      CalendarEvent(
        id: 't1',
        title: 'Client Call',
        startTime: tomorrow.copyWith(hour: 11, minute: 0),
        endTime: tomorrow.copyWith(hour: 12, minute: 0),
        color: Colors.red,
      ),
    ];
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<CalendarEvent> get currentEvents {
    return eventsPerDate[_getDateKey(selectedDate)] ?? [];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime currentSelectedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    if (currentSelectedDate.isAtSameMomentAs(today)) {
      double targetPosition = (now.hour * hourHeight) - 100;
      if (targetPosition < 0) targetPosition = 0;
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      double targetPosition = (8 * hourHeight) - 100;
      if (targetPosition < 0) targetPosition = 0;
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _changeDate(int dayOffset) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: dayOffset));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
    String dateString = _formatDate(selectedDate);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pindah ke tanggal: $dateString'),
        duration: const Duration(milliseconds: 800),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _manageAutoScrollTimer() {
    if (_autoScrollVelocity != 0.0 && _isDragging) {
      if (_autoScrollTimer == null || !_autoScrollTimer!.isActive) {
        _autoScrollTimer = Timer.periodic(_kAutoScrollTimerDuration, (timer) {
          if (!_isDragging || _autoScrollVelocity == 0.0) {
            timer.cancel();
            _autoScrollTimer = null;
            return;
          }

          if (_scrollController.hasClients) {
            double currentOffset = _scrollController.offset;
            double newOffset = (currentOffset + _autoScrollVelocity).clamp(
              _scrollController.position.minScrollExtent,
              _scrollController.position.maxScrollExtent,
            );

            if (currentOffset != newOffset) {
              _scrollController.jumpTo(newOffset);
            } else {
              // Mencapai batas scroll, hentikan timer untuk arah ini
              timer.cancel();
              _autoScrollTimer = null;
            }
          } else {
            // No clients, cancel timer
            timer.cancel();
            _autoScrollTimer = null;
          }
        });
      }
    } else {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                _formatDate(selectedDate),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            IconButton(
              onPressed: () => _changeDate(-1),
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Hari Sebelumnya',
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  selectedDate = DateTime.now();
                });
                _scrollToCurrentTime();
              },
              icon: const Icon(Icons.today),
              tooltip: 'Hari Ini',
            ),
            IconButton(
              onPressed: () => _changeDate(1),
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Hari Selanjutnya',
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showHelpDialog(),
            icon: const Icon(Icons.help_outline),
            tooltip: 'Bantuan',
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (DragEndDetails details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! > 0) {
                _changeDate(-1);
              } else if (details.primaryVelocity! < 0) {
                _changeDate(1);
              }
            }
          },
          child: Stack(
            children: [
              SingleChildScrollView(
                key: _scrollKey,
                controller: _scrollController,
                child: SizedBox(
                  height: 24 * hourHeight,
                  child: Row(
                    children: [
                      _buildTimeColumn(),
                      Expanded(child: _buildEventColumn()),
                    ],
                  ),
                ),
              ),
              if (_isDragging && _dragTargetTime != null)
                _buildDragTimeIndicator(),
              _buildSwipeIndicator(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewEvent,
        tooltip: 'Tambah Event (atau klik area kalender kanan)',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSwipeIndicator() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swipe, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Swipe ganti tanggal • Tap +event • Drag ke tepi scroll',
                  style: TextStyle(color: Colors.white, fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeColumn() {
    return Container(
      width: timeColumnWidth,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        children: List.generate(24, (index) {
          return Container(
            height: hourHeight,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(top: 4, left: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              '${index.toString().padLeft(2, '0')}:00',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEventColumn() {
    return Container(
      height: 24 * hourHeight,
      width: double.infinity,
      child: Stack(
        children: [
          _buildGridLines(),
          _buildCurrentTimeIndicator(),
          _buildTapArea(),
          ..._buildLayoutedEvents(),
          _buildOverlayDragTarget(),
        ],
      ),
    );
  }

  Widget _buildTapArea() {
    return Positioned.fill(
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          if (!_isPositionOccupied(details.localPosition.dy)) {
            _createEventAtPosition(details.localPosition.dy);
          }
        },
        child: Container(color: Colors.transparent),
      ),
    );
  }

  bool _isPositionOccupied(double yPosition) {
    double hours = yPosition / hourHeight;
    DateTime tapTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    ).add(Duration(minutes: (hours * 60).round()));

    for (CalendarEvent event in currentEvents) {
      if (tapTime.isAfter(event.startTime) && tapTime.isBefore(event.endTime)) {
        return true;
      }
      if (tapTime.isAtSameMomentAs(event.startTime)) {
        return true;
      }
    }
    return false;
  }

  Widget _buildGridLines() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime currentSelectedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    bool isToday = currentSelectedDate.isAtSameMomentAs(today);
    List<Widget> gridLines = [];
    for (int hour = 0; hour < 24; hour++) {
      bool isCurrentHour = isToday && hour == now.hour;
      double top = hour * hourHeight;
      gridLines.add(
        Positioned(
          top: top,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              color: isCurrentHour ? Colors.blue : Colors.grey.shade300,
            ),
          ),
        ),
      );
    }
    return Stack(children: gridLines);
  }

  Widget _buildOverlayDragTarget() {
    return Positioned.fill(
      child: Builder(
        builder: (context) {
          return DragTarget<CalendarEvent>(
            onMove: (details) {
              try {
                DateTime now = DateTime.now();
                if (_lastUpdateTime != null &&
                    now.difference(_lastUpdateTime!).inMilliseconds < 16) {
                  return;
                }
                _lastUpdateTime = now;

                Offset globalPosition = details.offset;

                // --- Auto Scroll Zone Detection ---
                RenderBox? scrollAreaRenderBox =
                    _scrollKey.currentContext?.findRenderObject() as RenderBox?;
                if (scrollAreaRenderBox != null &&
                    _scrollController.hasClients) {
                  Offset scrollAreaGlobalOffset = scrollAreaRenderBox
                      .localToGlobal(Offset.zero);
                  double viewportTopY = scrollAreaGlobalOffset.dy;
                  double viewportHeight = scrollAreaRenderBox.size.height;
                  double viewportBottomY = viewportTopY + viewportHeight;
                  const double scrollZoneHeight = 60.0;

                  if (globalPosition.dy < viewportTopY + scrollZoneHeight) {
                    _autoScrollVelocity = -_kAutoScrollPixelsPerTick;
                  } else if (globalPosition.dy >
                      viewportBottomY - scrollZoneHeight) {
                    _autoScrollVelocity = _kAutoScrollPixelsPerTick;
                  } else {
                    _autoScrollVelocity = 0.0;
                  }
                  _manageAutoScrollTimer();
                } else {
                  _autoScrollVelocity = 0.0;
                  _manageAutoScrollTimer();
                }
                // --- End Auto Scroll Zone Detection ---

                RenderBox? dragTargetRenderBox =
                    context.findRenderObject() as RenderBox?;
                if (dragTargetRenderBox != null) {
                  Offset localOffset = dragTargetRenderBox.globalToLocal(
                    globalPosition,
                  );
                  double localY = localOffset.dy;
                  double hours = localY / hourHeight;
                  int targetHour = hours.floor();
                  int targetMinute = ((hours - targetHour) * 60).round();
                  targetMinute =
                      (targetMinute ~/ minuteInterval) * minuteInterval;
                  if (targetMinute >= 60) {
                    targetHour += 1;
                    targetMinute = 0;
                  }
                  DateTime? newDragTargetTime;
                  if (targetHour >= 0 &&
                      targetHour < 24 &&
                      targetMinute >= 0 &&
                      targetMinute < 60) {
                    DateTime baseDate = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                    );
                    newDragTargetTime = baseDate.copyWith(
                      hour: targetHour,
                      minute: targetMinute,
                    );
                  }
                  if (_dragTargetTime != newDragTargetTime) {
                    setState(() {
                      _dragTargetTime = newDragTargetTime;
                    });
                  }
                }
              } catch (e) {
                print('Error in drag calculation: $e');
              }
            },
            onWillAcceptWithDetails: (data) {
              return data.data != null;
            },
            onAcceptWithDetails: (details) {
              _autoScrollTimer?.cancel();
              _autoScrollTimer = null;
              _autoScrollVelocity = 0.0;
              try {
                _lastMovedEvent = details.data;
                _originalStartTimeForUndo = details.data.startTime;
                _originalEndTimeForUndo = details.data.endTime;
                _originalEventDateForUndo =
                    _originalSelectedDateOnDragStart ?? selectedDate;

                if (_dragTargetTime != null) {
                  _moveEventToTime(
                    details.data,
                    _dragTargetTime!,
                    showUndo: true,
                  );
                }
              } catch (e) {
                print('Error in drop: $e');
              }
              setState(() {
                _isDragging = false;
                _dragTargetTime = null;
                _draggedEvent = null;
                _originalSelectedDateOnDragStart = null;
                _lastUpdateTime = null;
              });
            },
            onLeave: (data) {
              _autoScrollTimer?.cancel();
              _autoScrollTimer = null;
              _autoScrollVelocity = 0.0;
              setState(() {
                _dragTargetTime = null;
              });
            },
            builder: (context, candidateData, rejectedData) {
              bool isHighlighted = candidateData.isNotEmpty;
              Color? backgroundColor;
              if (isHighlighted) {
                backgroundColor = Colors.orange.withOpacity(0.08);
              }
              return IgnorePointer(
                ignoring: !isHighlighted,
                child: Container(
                  color: backgroundColor ?? Colors.transparent,
                  child:
                      isHighlighted
                          ? Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.6),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                          : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCurrentTimeIndicator() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime currentSelectedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    bool isToday = currentSelectedDate.isAtSameMomentAs(today);
    if (!isToday) return const SizedBox.shrink();

    double topPosition =
        (now.hour * hourHeight) + ((now.minute / 60) * hourHeight);
    return Positioned(
      top: topPosition,
      left: 0,
      right: 0,
      child: Container(
        height: 2,
        color: Colors.red,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(child: Container(height: 2, color: Colors.red)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLayoutedEvents() {
    List<EventLayout> layouts = _calculateEventLayouts();
    return layouts.map((layout) => _buildDraggableEvent(layout)).toList();
  }

  List<EventLayout> _calculateEventLayouts() {
    List<CalendarEvent> events = currentEvents;
    if (events.isEmpty) return [];

    List<CalendarEvent> sortedEvents = List.from(events);
    sortedEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    List<EventLayout> layouts = [];
    List<CalendarEvent> processedEvents = [];

    for (CalendarEvent event in sortedEvents) {
      if (processedEvents.contains(event)) continue;

      List<CalendarEvent> overlappingGroup = [event];

      for (CalendarEvent otherEvent in sortedEvents) {
        if (event == otherEvent || processedEvents.contains(otherEvent))
          continue;
        if (overlappingGroup.contains(otherEvent)) continue;

        bool overlapsWithCurrentGroup = false;
        for (CalendarEvent groupEvent in overlappingGroup) {
          if (_eventsOverlap(groupEvent, otherEvent)) {
            overlapsWithCurrentGroup = true;
            break;
          }
        }
        if (overlapsWithCurrentGroup) {
          overlappingGroup.add(otherEvent);
        }
      }

      for (var e in overlappingGroup) {
        if (!processedEvents.contains(e)) processedEvents.add(e);
      }

      overlappingGroup.sort((a, b) {
        int comp = a.startTime.compareTo(b.startTime);
        if (comp == 0) {
          return a.endTime.compareTo(b.endTime);
        }
        return comp;
      });

      List<List<CalendarEvent>> columns = [];

      for (CalendarEvent currentEventInGroup in overlappingGroup) {
        int targetCol = -1;
        for (int i = 0; i < columns.length; i++) {
          bool canPlace = true;
          for (CalendarEvent placedEvent in columns[i]) {
            if (_eventsOverlap(currentEventInGroup, placedEvent)) {
              canPlace = false;
              break;
            }
          }
          if (canPlace) {
            targetCol = i;
            break;
          }
        }

        if (targetCol == -1) {
          columns.add([]);
          targetCol = columns.length - 1;
        }
        columns[targetCol].add(currentEventInGroup);
      }

      int totalColumnsInGroup = columns.isNotEmpty ? columns.length : 1;
      for (int colIdx = 0; colIdx < columns.length; colIdx++) {
        for (CalendarEvent ev in columns[colIdx]) {
          layouts.add(
            EventLayout(
              event: ev,
              left: colIdx.toDouble() / totalColumnsInGroup.toDouble(),
              width: 1.0 / totalColumnsInGroup.toDouble(),
              column: colIdx,
              totalColumns: totalColumnsInGroup,
            ),
          );
        }
      }
    }
    return layouts;
  }

  bool _eventsOverlap(CalendarEvent event1, CalendarEvent event2) {
    return event1.startTime.isBefore(event2.endTime) &&
        event2.startTime.isBefore(event1.endTime);
  }

  Widget _buildDraggableEvent(EventLayout layout) {
    CalendarEvent event = layout.event;
    double top = _getEventTopPosition(event);
    double height = _getEventHeight(event);
    double leftPadding = 4;
    double rightPadding = 4;

    double screenWidth = MediaQuery.of(context).size.width;
    double availableWidthForEvents =
        screenWidth - timeColumnWidth - leftPadding - rightPadding;

    double eventWidth =
        (availableWidthForEvents * layout.width).clamp(
          50.0,
          availableWidthForEvents,
        ) -
        (layout.totalColumns > 1 ? 2 : 0);
    double eventLeft = leftPadding + (availableWidthForEvents * layout.left);

    return Positioned(
      top: top,
      left: eventLeft,
      width: eventWidth,
      height: height,
      child: LongPressDraggable<CalendarEvent>(
        data: event,
        onDragStarted: () {
          setState(() {
            _isDragging = true;
            _draggedEvent = event;
            _originalSelectedDateOnDragStart = selectedDate;
            _lastUpdateTime = null;
            _autoScrollTimer?.cancel();
            _autoScrollTimer = null;
            _autoScrollVelocity = 0.0;
          });
        },
        onDragEnd: (details) {
          _autoScrollTimer?.cancel();
          _autoScrollTimer = null;
          _autoScrollVelocity = 0.0;
          setState(() {
            _isDragging = false;
            _dragTargetTime = null;
            _draggedEvent = null;
            _originalSelectedDateOnDragStart = null;
            _lastUpdateTime = null;
          });
        },
        feedback: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: eventWidth,
            height: height,
            decoration: BoxDecoration(
              color: event.color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (height > 30)
                  Flexible(
                    child: Text(
                      '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
        childWhenDragging: Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400, width: 2),
          ),
          child: Center(
            child: Icon(
              Icons.drag_handle,
              color: Colors.grey.shade600,
              size: 24,
            ),
          ),
        ),
        child: GestureDetector(
          onTap: () => _showEventDetails(event),
          child: Container(
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (height > 30)
                  Flexible(
                    child: Text(
                      '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragTimeIndicator() {
    if (_dragTargetTime == null || !_isDragging) {
      return const SizedBox.shrink();
    }

    double startTimeY =
        (_dragTargetTime!.hour * hourHeight) +
        (_dragTargetTime!.minute * hourHeight / 60);

    if (_scrollController.hasClients) {
      startTimeY -= _scrollController.offset;
    }

    String timeText = _formatTime(_dragTargetTime!);
    if (_draggedEvent != null) {
      Duration eventDuration = _draggedEvent!.endTime.difference(
        _draggedEvent!.startTime,
      );
      DateTime newEndTime = _dragTargetTime!.add(eventDuration);
      timeText =
          '${_formatTime(_dragTargetTime!)} - ${_formatTime(newEndTime)}';
    }

    return Positioned(
      left: timeColumnWidth + 10,
      top: startTimeY - 25,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width - timeColumnWidth - 40,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    timeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getEventTopPosition(CalendarEvent event) {
    int hour = event.startTime.hour;
    int minute = event.startTime.minute;
    return (hour * hourHeight) + (minute * hourHeight / 60);
  }

  double _getEventHeight(CalendarEvent event) {
    Duration duration = event.endTime.difference(event.startTime);
    return (duration.inMinutes * hourHeight / 60).clamp(20.0, double.infinity);
  }

  void _createEventAtPosition(double yPosition) {
    double hours = yPosition / hourHeight;
    int targetHour = hours.floor();
    int targetMinute = ((hours - targetHour) * 60).round();
    targetMinute = (targetMinute ~/ minuteInterval) * minuteInterval;
    if (targetMinute >= 60) {
      targetHour += 1;
      targetMinute = 0;
    }
    if (targetHour < 0) targetHour = 0;
    if (targetHour >= 24) targetHour = 23;

    DateTime baseDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    DateTime startTime = baseDate.copyWith(
      hour: targetHour,
      minute: targetMinute,
    );
    DateTime endTime = startTime.add(const Duration(hours: 1));

    String eventId = DateTime.now().millisecondsSinceEpoch.toString();
    List<Color> eventColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    Color randomColor = eventColors[eventId.hashCode % eventColors.length];

    CalendarEvent newEvent = CalendarEvent(
      id: eventId,
      title: 'Event ${_formatTime(startTime)}',
      startTime: startTime,
      endTime: endTime,
      color: randomColor,
    );

    setState(() {
      List<CalendarEvent> events = List.from(currentEvents);
      events.add(newEvent);
      eventsPerDate[_getDateKey(selectedDate)] = events;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Event dibuat: ${_formatTime(startTime)} - ${_formatTime(endTime)}',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              List<CalendarEvent> events = List.from(currentEvents);
              events.removeWhere((e) => e.id == eventId);
              eventsPerDate[_getDateKey(selectedDate)] = events;
            });
          },
        ),
      ),
    );
  }

  void _moveEventToTime(
    CalendarEvent event,
    DateTime targetTime, {
    bool showUndo = false,
  }) {
    Duration eventDuration = event.endTime.difference(event.startTime);
    DateTime newEndTime = targetTime.add(eventDuration);

    if (showUndo) {
      _lastMovedEvent = event.copyWith();
      _originalStartTimeForUndo = event.startTime;
      _originalEndTimeForUndo = event.endTime;
      _originalEventDateForUndo = selectedDate;
    }

    setState(() {
      String currentDayKey = _getDateKey(selectedDate);
      List<CalendarEvent> dayEvents = List.from(
        eventsPerDate[currentDayKey] ?? [],
      );
      int index = dayEvents.indexWhere((e) => e.id == event.id);

      if (index != -1) {
        dayEvents[index] = event.copyWith(
          startTime: targetTime,
          endTime: newEndTime,
        );
        eventsPerDate[currentDayKey] = dayEvents;
      } else {
        print("Error: Event to move not found in current day's list.");
        return;
      }
    });
    if (!mounted) return;
    if (showUndo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${event.title} dipindah ke ${_formatTime(targetTime)} - ${_formatTime(newEndTime)}',
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'BATALKAN',
            textColor: Colors.white,
            onPressed: () => _undoMoveEvent(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${event.title} dipindah ke ${_formatTime(targetTime)} - ${_formatTime(newEndTime)}',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _undoMoveEvent() {
    if (_lastMovedEvent == null ||
        _originalEventDateForUndo == null ||
        _originalStartTimeForUndo == null ||
        _originalEndTimeForUndo == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada aksi untuk dibatalkan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    CalendarEvent eventToRestore = _lastMovedEvent!;
    DateTime originalDate = _originalEventDateForUndo!;
    DateTime originalStartTime = _originalStartTimeForUndo!;
    DateTime originalEndTime = _originalEndTimeForUndo!;

    setState(() {
      eventsPerDate.forEach((dateKey, eventList) {
        eventList.removeWhere((e) => e.id == eventToRestore.id);
      });

      String originalDateKey = _getDateKey(originalDate);
      List<CalendarEvent> originalDateEvents = List.from(
        eventsPerDate[originalDateKey] ?? [],
      );

      originalDateEvents.add(
        eventToRestore.copyWith(
          startTime: originalStartTime,
          endTime: originalEndTime,
        ),
      );
      eventsPerDate[originalDateKey] = originalDateEvents;

      if (!_isSameDay(selectedDate, originalDate)) {
        selectedDate = originalDate;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrentTime();
        });
      }
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${eventToRestore.title} dikembalikan ke posisi semula.'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );

    _lastMovedEvent = null;
    _originalEventDateForUndo = null;
    _originalStartTimeForUndo = null;
    _originalEndTimeForUndo = null;
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  void _addNewEvent() {
    DateTime baseDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    DateTime now = DateTime.now();
    int defaultHour = 9;
    int defaultMinute = 0;

    if (_isSameDay(baseDate, DateTime(now.year, now.month, now.day))) {
      defaultHour = now.hour;
      defaultMinute = (now.minute ~/ minuteInterval) * minuteInterval;
    }

    CalendarEvent newEvent = CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Event Baru',
      startTime: baseDate.copyWith(hour: defaultHour, minute: defaultMinute),
      endTime: baseDate.copyWith(hour: defaultHour + 1, minute: defaultMinute),
      color: Colors.orange,
    );

    setState(() {
      List<CalendarEvent> events = List.from(currentEvents);
      events.add(newEvent);
      eventsPerDate[_getDateKey(selectedDate)] = events;
    });
  }

  void _showEventDetails(CalendarEvent event) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(event.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mulai: ${_formatDateTime(event.startTime)}'),
                Text('Selesai: ${_formatDateTime(event.endTime)}'),
                const SizedBox(height: 16),
                const Text(
                  'Tips:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('• Long press untuk drag & drop event'),
                const Text('• Drop precision: 5 menit'),
                const Text('• Drag ke tepi atas/bawah untuk scroll otomatis'),
                const Text('• Tombol BATALKAN untuk undo'),
                const Text('• Klik di area kalender (kanan) untuk buat event'),
                const Text('• Swipe horizontal untuk ganti tanggal'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    List<CalendarEvent> events = List.from(currentEvents);
                    events.removeWhere((e) => e.id == event.id);
                    eventsPerDate[_getDateKey(selectedDate)] = events;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Hapus'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _showHelpDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.help_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text('Cara Menggunakan Calendar'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📅 Navigasi Tanggal:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Swipe kiri/kanan untuk ganti tanggal'),
                Text('• Atau gunakan tombol ← hari ini → di AppBar'),
                SizedBox(height: 12),
                Text(
                  '🎯 Membuat Event Baru:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '• Klik di area kalender (sebelah kanan) untuk buat event',
                ),
                Text('• Atau gunakan tombol + di kanan bawah'),
                SizedBox(height: 12),
                Text(
                  '🎯 Memindah Event:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Long press event lalu drag ke jam yang diinginkan'),
                Text('• Drag ke tepi atas/bawah view untuk scroll otomatis'),
                Text('• Precision 5 menit (snap ke 10:00, 10:05, 10:10, dst)'),
                Text('• Tombol "BATALKAN" untuk undo pindah event'),
                Text('• Events overlap akan otomatis split'),
                SizedBox(height: 12),
                Text(
                  '⚙️ Fitur Lainnya:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Tap event untuk lihat detail/hapus'),
                Text('• Scroll vertical untuk lihat jam lain'),
                Text('• Garis merah = waktu sekarang (hanya hari ini)'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Mengerti'),
              ),
            ],
          ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    List<String> days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    List<String> months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    String dayName =
        days[dateTime.weekday %
            7]; // Senin adalah 1, Minggu adalah 7. %7 agar index array pas.
    if (dateTime.weekday == 7)
      dayName =
          days[0]; // Handle Minggu sebagai index 0 jika perlu. Atau sesuaikan array `days`.
    else
      dayName = days[dateTime.weekday % 7];

    String monthName = months[dateTime.month];
    return '$dayName, ${dateTime.day} $monthName ${dateTime.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }
}

class CalendarApp extends StatelessWidget {
  const CalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Day View Calendar',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: DayViewCalendar(initialDate: DateTime.now()),
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() {
  runApp(const CalendarApp());
}
