import 'package:flutter/material.dart';

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

  // Untuk drag indicator dan cross-date detection
  bool _isDragging = false;
  DateTime? _dragTargetTime;
  CalendarEvent? _draggedEvent;
  String _dragDirection = ''; // 'left', 'right', atau ''
  DateTime? _originalSelectedDate; // Untuk undo
  int _dragOffset = 0; // Berapa hari offset dari tanggal asli
  DateTime? _lastUpdateTime; // Untuk throttling smooth update

  // Untuk undo functionality
  CalendarEvent? _lastMovedEvent;
  DateTime? _originalEventDate;
  DateTime? _originalStartTime;
  DateTime? _originalEndTime;

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
    // Buat events untuk beberapa tanggal sebagai demo
    DateTime today = DateTime.now();
    DateTime baseToday = DateTime(today.year, today.month, today.day);
    DateTime yesterday = baseToday.subtract(const Duration(days: 1));
    DateTime tomorrow = baseToday.add(const Duration(days: 1));

    // Events untuk hari ini
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

    // Events untuk kemarin
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

    // Events untuk besok
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
    super.dispose();
  }

  void _scrollToCurrentTime() {
    DateTime now = DateTime.now();
    // Hanya scroll ke waktu saat ini jika selectedDate adalah hari ini
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime currentSelectedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    if (currentSelectedDate.isAtSameMomentAs(today)) {
      double targetPosition = (now.hour * hourHeight) - 100;
      if (targetPosition < 0) targetPosition = 0;

      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // Untuk tanggal lain, scroll ke jam 8 pagi
      double targetPosition = (8 * hourHeight) - 100;
      if (targetPosition < 0) targetPosition = 0;

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

    // Auto scroll setelah ganti tanggal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });

    // Tampilkan snackbar untuk feedback
    String dateString = _formatDate(selectedDate);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pindah ke tanggal: $dateString'),
        duration: const Duration(milliseconds: 800),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
            // Tombol navigasi tanggal
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
            // Deteksi swipe gesture
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! > 0) {
                // Swipe ke kanan = hari sebelumnya
                _changeDate(-1);
              } else if (details.primaryVelocity! < 0) {
                // Swipe ke kiri = hari selanjutnya
                _changeDate(1);
              }
            }
          },
          child: Stack(
            children: [
              SingleChildScrollView(
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
              // Indikator swipe
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
                  'Swipe ganti tanggal • Tap +event • Drag jauh = +hari',
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
          // Area untuk tap (di belakang events)
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
          // Cek apakah tap di area kosong (tidak ada event)
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
      // Juga cek jika tap tepat di start time
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

    // Hanya tampilkan garis setiap jam (bukan setiap 5 menit)
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
                // Throttling untuk smooth update (max 60fps)
                DateTime now = DateTime.now();
                if (_lastUpdateTime != null &&
                    now.difference(_lastUpdateTime!).inMilliseconds < 16) {
                  return;
                }
                _lastUpdateTime = now;

                // Gunakan koordinat global untuk akurasi lebih baik
                Offset globalPosition = details.offset;

                // Dapatkan screen bounds
                double screenWidth = MediaQuery.of(context).size.width;
                double timeColumnEnd = timeColumnWidth;
                double eventColumnStart = timeColumnEnd;
                double eventColumnEnd = screenWidth;

                // Konversi ke koordinat relatif terhadap screen
                double globalX = globalPosition.dx;

                // Inisialisasi jika belum ada originalSelectedDate
                if (_originalSelectedDate == null) {
                  _originalSelectedDate = selectedDate;
                  _dragOffset = 0;
                }

                String newDragDirection = '';
                int newDragOffset = 0;

                // Debug print untuk troubleshooting
                // print('GlobalX: $globalX, TimeColumnEnd: $timeColumnEnd, EventColumnEnd: $eventColumnEnd');

                // Deteksi zona drag dengan koordinat global
                if (globalX < timeColumnEnd - 10) {
                  // Zona kiri - drag ke area time column atau lebih kiri
                  newDragDirection = 'left';
                  double dragDistance =
                      timeColumnEnd - globalX; // Jarak masuk ke zona kiri
                  newDragOffset =
                      -((dragDistance / 30).ceil().clamp(
                        1,
                        30,
                      )); // Min 1 hari, max 30 hari
                } else if (globalX > eventColumnEnd + 10) {
                  // Zona kanan - drag melewati edge kanan screen
                  newDragDirection = 'right';
                  double dragDistance =
                      globalX - eventColumnEnd; // Jarak melewati edge kanan
                  newDragOffset = ((dragDistance / 30).ceil().clamp(
                    1,
                    30,
                  )); // Min 1 hari, max 30 hari
                } else {
                  // Zona tengah - dalam area event column
                  newDragDirection = '';
                  newDragOffset = 0;
                }

                // Update jika ada perubahan signifikan
                if (newDragDirection != _dragDirection ||
                    (newDragOffset != _dragOffset &&
                        (newDragOffset - _dragOffset).abs() >= 1)) {
                  setState(() {
                    _dragDirection = newDragDirection;
                    _dragOffset = newDragOffset;

                    if (_originalSelectedDate != null) {
                      // Update selectedDate berdasarkan offset
                      selectedDate = _originalSelectedDate!.add(
                        Duration(days: _dragOffset),
                      );
                      _dragTargetTime = null;
                    }
                  });
                }

                // Kalkulasi target time untuk zona tengah
                if (_dragDirection == '') {
                  // Konversi global position ke local position untuk event column
                  RenderBox? renderBox =
                      context.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    Offset localOffset = renderBox.globalToLocal(
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

                    if (targetHour >= 0 &&
                        targetHour < 24 &&
                        targetMinute >= 0 &&
                        targetMinute < 60) {
                      DateTime baseDate = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                      );
                      setState(() {
                        _dragTargetTime = baseDate.copyWith(
                          hour: targetHour,
                          minute: targetMinute,
                        );
                      });
                    }
                  }
                } else {
                  setState(() {
                    _dragTargetTime = null;
                  });
                }
              } catch (e) {
                print('Error in drag calculation: $e');
              }
            },
            onWillAcceptWithDetails: (data) {
              if (data.data != null) {
                setState(() {
                  _draggedEvent = data.data;
                });
              }
              return data.data != null;
            },
            onAcceptWithDetails: (details) {
              try {
                // Simpan state untuk undo
                _lastMovedEvent = details.data;
                _originalStartTime = details.data.startTime;
                _originalEndTime = details.data.endTime;

                if (_dragDirection == 'left' || _dragDirection == 'right') {
                  // Pindah ke tanggal berbeda berdasarkan offset
                  _originalEventDate = _originalSelectedDate ?? selectedDate;
                  _moveEventToDateWithOffset(
                    details.data,
                    _dragOffset,
                    showUndo: true,
                  );
                } else if (_dragTargetTime != null) {
                  // Drop di hari yang sama
                  _originalEventDate = _originalSelectedDate ?? selectedDate;
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
                _dragDirection = '';
                _originalSelectedDate = null;
                _dragOffset = 0;
                _lastUpdateTime = null;
              });
            },
            onLeave: (data) {
              setState(() {
                _isDragging = false;
                _dragTargetTime = null;
                _draggedEvent = null;
                _dragDirection = '';

                // Kembalikan ke tanggal asli jika drag dibatalkan
                if (_originalSelectedDate != null) {
                  selectedDate = _originalSelectedDate!;
                  _originalSelectedDate = null;
                }
                _dragOffset = 0;
                _lastUpdateTime = null;
              });
            },
            builder: (context, candidateData, rejectedData) {
              bool isHighlighted = candidateData.isNotEmpty;
              Color? backgroundColor;

              if (isHighlighted) {
                if (_dragDirection == 'left') {
                  backgroundColor = Colors.blue.withValues(alpha: 0.15);
                } else if (_dragDirection == 'right') {
                  backgroundColor = Colors.green.withValues(alpha: 0.15);
                } else {
                  backgroundColor = Colors.orange.withValues(alpha: 0.08);
                }
              }

              return IgnorePointer(
                ignoring: !isHighlighted,
                child: Container(
                  color: backgroundColor ?? Colors.transparent,
                  child:
                      isHighlighted && _dragDirection == ''
                          ? Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.6),
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
    List<List<CalendarEvent>> eventGroups = [];

    for (CalendarEvent event in sortedEvents) {
      bool addedToGroup = false;

      for (List<CalendarEvent> group in eventGroups) {
        bool hasOverlap = false;
        for (CalendarEvent groupEvent in group) {
          if (_eventsOverlap(event, groupEvent)) {
            hasOverlap = true;
            break;
          }
        }
        if (hasOverlap) {
          group.add(event);
          addedToGroup = true;
          break;
        }
      }

      if (!addedToGroup) {
        eventGroups.add([event]);
      }
    }

    for (List<CalendarEvent> group in eventGroups) {
      if (group.length == 1) {
        layouts.add(
          EventLayout(
            event: group[0],
            left: 0.0,
            width: 1.0,
            column: 0,
            totalColumns: 1,
          ),
        );
      } else {
        List<List<CalendarEvent>> columns = [];

        for (CalendarEvent event in group) {
          int targetColumn = -1;

          for (int i = 0; i < columns.length; i++) {
            bool canPlace = true;
            for (CalendarEvent existingEvent in columns[i]) {
              if (_eventsOverlap(event, existingEvent)) {
                canPlace = false;
                break;
              }
            }
            if (canPlace) {
              targetColumn = i;
              break;
            }
          }

          if (targetColumn == -1) {
            columns.add([]);
            targetColumn = columns.length - 1;
          }

          columns[targetColumn].add(event);
        }

        int totalColumns = columns.length;
        double columnWidth = 1.0 / totalColumns;

        for (int columnIndex = 0; columnIndex < columns.length; columnIndex++) {
          for (CalendarEvent event in columns[columnIndex]) {
            layouts.add(
              EventLayout(
                event: event,
                left: columnIndex * columnWidth,
                width: columnWidth,
                column: columnIndex,
                totalColumns: totalColumns,
              ),
            );
          }
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
    double leftPadding = 8;
    double rightPadding = 8;

    double screenWidth = MediaQuery.of(context).size.width;
    double availableWidth =
        screenWidth - timeColumnWidth - leftPadding - rightPadding;

    double eventWidth = (availableWidth * layout.width).clamp(
      80.0,
      availableWidth,
    );
    double eventLeft = leftPadding + (availableWidth * layout.left);

    if (eventLeft + eventWidth > screenWidth - rightPadding) {
      eventLeft = screenWidth - rightPadding - eventWidth;
    }

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
            _dragDirection = '';
            _originalSelectedDate = null;
            _dragOffset = 0;
            _lastUpdateTime = null;
          });
        },
        onDragEnd: (details) {
          setState(() {
            _isDragging = false;
            _dragTargetTime = null;
            _draggedEvent = null;
            _dragDirection = '';

            // Kembalikan ke tanggal asli jika drag dibatalkan tanpa drop
            if (_originalSelectedDate != null) {
              selectedDate = _originalSelectedDate!;
              _originalSelectedDate = null;
            }
            _dragOffset = 0;
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
              color: event.color.withValues(alpha: 0.9),
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
            color: Colors.grey.withValues(alpha: 0.4),
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
                  color: Colors.black.withValues(alpha: 0.15),
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
    if (_dragTargetTime == null) {
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
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, color: Colors.white, size: 14),
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

  Widget _buildDateChangeIndicators() {
    if (!_isDragging || _draggedEvent == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // Indikator kiri - tanggal sebelumnya
        if (_dragDirection == 'left')
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 80,
              color: Colors.blue.withValues(alpha: 0.4),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatDateShort(selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_dragOffset.abs() > 1)
                            Text(
                              '${_dragOffset} hari',
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Indikator kanan - tanggal selanjutnya
        if (_dragDirection == 'right')
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 80,
              color: Colors.green.withValues(alpha: 0.4),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_forward, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatDateShort(selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_dragOffset > 1)
                            Text(
                              '+${_dragOffset} hari',
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateShort(DateTime dateTime) {
    List<String> days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    String dayName = days[dateTime.weekday % 7];
    return '$dayName\n${dateTime.day}/${dateTime.month}';
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
    // Hitung jam berdasarkan posisi Y yang tepat
    double hours = yPosition / hourHeight;
    int targetHour = hours.floor();
    int targetMinute = ((hours - targetHour) * 60).round();

    // Snap ke interval 5 menit untuk presisi yang baik
    targetMinute = (targetMinute ~/ minuteInterval) * minuteInterval;

    if (targetMinute >= 60) {
      targetHour += 1;
      targetMinute = 0;
    }

    // Pastikan dalam range valid
    if (targetHour < 0) targetHour = 0;
    if (targetHour >= 24) targetHour = 23;
    if (targetMinute < 0) targetMinute = 0;
    if (targetMinute >= 60) targetMinute = 55;

    // Buat event tepat di posisi yang diklik
    DateTime baseDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    DateTime startTime = baseDate.copyWith(
      hour: targetHour,
      minute: targetMinute,
    );
    DateTime endTime = startTime.add(
      const Duration(hours: 1),
    ); // Default durasi 1 jam

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

  void _moveEventToDateWithOffset(
    CalendarEvent event,
    int dayOffset, {
    bool showUndo = false,
  }) {
    DateTime originalDate = _originalSelectedDate ?? selectedDate;
    DateTime newDate = originalDate.add(Duration(days: dayOffset));
    DateTime newBaseDate = DateTime(newDate.year, newDate.month, newDate.day);

    // Pertahankan jam dan menit yang sama
    DateTime newStartTime = newBaseDate.copyWith(
      hour: event.startTime.hour,
      minute: event.startTime.minute,
    );
    DateTime newEndTime = newBaseDate.copyWith(
      hour: event.endTime.hour,
      minute: event.endTime.minute,
    );

    // Handle jika event melewati midnight
    if (event.endTime.day != event.startTime.day) {
      newEndTime = newEndTime.add(const Duration(days: 1));
    }

    CalendarEvent updatedEvent = event.copyWith(
      startTime: newStartTime,
      endTime: newEndTime,
    );

    setState(() {
      // Hapus dari tanggal lama
      String originalDateKey = _getDateKey(originalDate);
      List<CalendarEvent> oldEvents = List.from(
        eventsPerDate[originalDateKey] ?? [],
      );
      oldEvents.removeWhere((e) => e.id == event.id);
      eventsPerDate[originalDateKey] = oldEvents;

      // Tambah ke tanggal baru
      String newDateKey = _getDateKey(newDate);
      List<CalendarEvent> newEvents = List.from(
        eventsPerDate[newDateKey] ?? [],
      );
      newEvents.add(updatedEvent);
      eventsPerDate[newDateKey] = newEvents;

      // Pastikan kita di tanggal yang benar
      selectedDate = newDate;
    });

    String dateString = _formatDate(newDate);
    String offsetText =
        dayOffset == 0
            ? ''
            : dayOffset > 0
            ? ' (+${dayOffset} hari)'
            : ' (${dayOffset} hari)';

    if (showUndo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${event.title} dipindah ke $dateString$offsetText'),
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
          content: Text('${event.title} dipindah ke $dateString$offsetText'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _moveEventToDate(
    CalendarEvent event,
    int dayOffset, {
    bool showUndo = false,
  }) {
    DateTime originalDate =
        _originalSelectedDate ??
        selectedDate.subtract(Duration(days: dayOffset));
    DateTime newDate = originalDate.add(Duration(days: dayOffset));
    DateTime newBaseDate = DateTime(newDate.year, newDate.month, newDate.day);

    // Pertahankan jam dan menit yang sama
    DateTime newStartTime = newBaseDate.copyWith(
      hour: event.startTime.hour,
      minute: event.startTime.minute,
    );
    DateTime newEndTime = newBaseDate.copyWith(
      hour: event.endTime.hour,
      minute: event.endTime.minute,
    );

    // Handle jika event melewati midnight
    if (event.endTime.day != event.startTime.day) {
      newEndTime = newEndTime.add(const Duration(days: 1));
    }

    CalendarEvent updatedEvent = event.copyWith(
      startTime: newStartTime,
      endTime: newEndTime,
    );

    setState(() {
      // Hapus dari tanggal lama
      String originalDateKey = _getDateKey(originalDate);
      List<CalendarEvent> oldEvents = List.from(
        eventsPerDate[originalDateKey] ?? [],
      );
      oldEvents.removeWhere((e) => e.id == event.id);
      eventsPerDate[originalDateKey] = oldEvents;

      // Tambah ke tanggal baru
      String newDateKey = _getDateKey(newDate);
      List<CalendarEvent> newEvents = List.from(
        eventsPerDate[newDateKey] ?? [],
      );
      newEvents.add(updatedEvent);
      eventsPerDate[newDateKey] = newEvents;

      // Pastikan kita di tanggal yang benar
      selectedDate = newDate;
    });

    String dateString = _formatDate(newDate);

    if (showUndo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${event.title} dipindah ke $dateString'),
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
          content: Text('${event.title} dipindah ke $dateString'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _moveEventToTime(
    CalendarEvent event,
    DateTime targetTime, {
    bool showUndo = false,
  }) {
    Duration eventDuration = event.endTime.difference(event.startTime);
    DateTime newEndTime = targetTime.add(eventDuration);

    setState(() {
      List<CalendarEvent> events = currentEvents;
      int index = events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        events[index] = event.copyWith(
          startTime: targetTime,
          endTime: newEndTime,
        );
        eventsPerDate[_getDateKey(selectedDate)] = events;
      }
    });

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
        _originalEventDate == null ||
        _originalStartTime == null ||
        _originalEndTime == null) {
      return;
    }

    CalendarEvent originalEvent = _lastMovedEvent!.copyWith(
      startTime: _originalStartTime!,
      endTime: _originalEndTime!,
    );

    setState(() {
      // Hapus dari tanggal saat ini
      String currentDateKey = _getDateKey(selectedDate);
      List<CalendarEvent> currentEvents = List.from(
        eventsPerDate[currentDateKey] ?? [],
      );
      currentEvents.removeWhere((e) => e.id == _lastMovedEvent!.id);
      eventsPerDate[currentDateKey] = currentEvents;

      // Kembalikan ke tanggal asli
      String originalDateKey = _getDateKey(_originalEventDate!);
      List<CalendarEvent> originalEvents = List.from(
        eventsPerDate[originalDateKey] ?? [],
      );
      originalEvents.add(originalEvent);
      eventsPerDate[originalDateKey] = originalEvents;

      // Pindah ke tanggal asli
      selectedDate = _originalEventDate!;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_lastMovedEvent!.title} dikembalikan ke posisi semula',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Reset undo data
    _lastMovedEvent = null;
    _originalEventDate = null;
    _originalStartTime = null;
    _originalEndTime = null;
  }

  void _addNewEvent() {
    DateTime baseDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    DateTime now = DateTime.now();

    // Jika selectedDate adalah hari ini, gunakan waktu saat ini
    // Jika tidak, gunakan jam 9 pagi
    int defaultHour = 9;
    int defaultMinute = 0;

    if (baseDate.isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
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

  void _createEventAtHour(int hour, [int minute = 0]) {
    if (hour < 0 || hour >= 24) return;

    DateTime baseDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    DateTime startTime = baseDate.copyWith(hour: hour, minute: minute);
    DateTime endTime = baseDate.copyWith(hour: hour + 1, minute: minute);

    if (hour == 23) {
      endTime = baseDate
          .add(const Duration(days: 1))
          .copyWith(hour: 0, minute: minute);
    }

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Event baru dibuat: ${_formatTime(startTime)} - ${_formatTime(endTime)}',
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

  void _showEventDetails(CalendarEvent event) {
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
                const Text('• Drag ke tepi = preview tanggal & pindah 1+ hari'),
                const Text('• Semakin jauh drag, semakin banyak hari'),
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
                Text('• Drag ke kiri time column = mundur 1+ hari'),
                Text('• Drag ke kanan melewati screen = maju 1+ hari'),
                Text(
                  '• Semakin jauh drag, semakin banyak hari (30px = 1 hari)',
                ),
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

    String dayName = days[dateTime.weekday % 7];
    String monthName = months[dateTime.month];

    return '$dayName, ${dateTime.day} $monthName ${dateTime.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }
}

// Widget utama untuk demo
class CalendarApp extends StatelessWidget {
  const CalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Day View Calendar',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: DayViewCalendar(initialDate: DateTime.now()),
    );
  }
}

void main() {
  runApp(const CalendarApp());
}
