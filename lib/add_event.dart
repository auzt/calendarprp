// main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(CalendarApp());
}

class CalendarApp extends StatelessWidget {
  const CalendarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: CalendarHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalendarHomePage extends StatelessWidget {
  const CalendarHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Calendar'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 100, color: Colors.blue),
            SizedBox(height: 24),
            Text(
              'Calendar App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kelola jadwal Anda dengan mudah',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddEventPage()),
                );
              },
              icon: Icon(Icons.add),
              label: Text('Tambah Event Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddEventPage extends StatefulWidget {
  const AddEventPage({Key? key}) : super(key: key);

  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // State variables
  String selectedEventType = 'Event';
  bool isAllDay = false;
  DateTime startDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  DateTime endDate = DateTime.now();
  TimeOfDay endTime = TimeOfDay(
    hour: TimeOfDay.now().hour + 1,
    minute: TimeOfDay.now().minute,
  );
  String selectedTimezone = 'Western Indonesian Time (WIB)';
  String repeatOption = 'Does not repeat';
  List<String> notifications = ['30 minutes before'];
  Color selectedColor = Colors.red;
  List<String> invitedPeople = [];
  bool hasVideoConference = false;

  // Task specific
  String taskPriority = 'Medium';
  String taskStatus = 'To Do';
  bool showTaskDetails = false;

  // Options
  final List<String> eventTypes = ['Event', 'Task', 'Birthday'];
  final List<String> repeatOptions = [
    'Does not repeat',
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];
  final List<String> notificationOptions = [
    '5 minutes before',
    '10 minutes before',
    '15 minutes before',
    '30 minutes before',
    '1 hour before',
    '1 day before',
    'Custom...',
  ];
  final List<Map<String, dynamic>> colorOptions = [
    {'name': 'Tomato', 'color': Colors.red},
    {'name': 'Tangerine', 'color': Colors.deepOrange},
    {'name': 'Banana', 'color': Colors.amber},
    {'name': 'Basil', 'color': Colors.green},
    {'name': 'Sage', 'color': Colors.teal},
    {'name': 'Peacock', 'color': Colors.cyan},
    {'name': 'Blueberry', 'color': Colors.blue},
    {'name': 'Lavender', 'color': Colors.purple[300]!},
    {'name': 'Grape', 'color': Colors.deepPurple},
  ];

  final List<Map<String, dynamic>> timezoneOptions = [
    // Asia
    {
      'name': 'Western Indonesian Time (WIB)',
      'offset': 'GMT+7',
      'location': 'Jakarta, Sumatra, Java',
    },
    {
      'name': 'Central Indonesian Time (WITA)',
      'offset': 'GMT+8',
      'location': 'Bali, Lombok, Sulawesi',
    },
    {
      'name': 'Eastern Indonesian Time (WIT)',
      'offset': 'GMT+9',
      'location': 'Papua, Maluku',
    },
    {'name': 'Singapore Time', 'offset': 'GMT+8', 'location': 'Singapore'},
    {
      'name': 'Malaysia Time',
      'offset': 'GMT+8',
      'location': 'Malaysia, Brunei',
    },
    {'name': 'Philippines Time', 'offset': 'GMT+8', 'location': 'Philippines'},
    {
      'name': 'Indochina Time',
      'offset': 'GMT+7',
      'location': 'Thailand, Vietnam, Cambodia',
    },
    {
      'name': 'China Standard Time',
      'offset': 'GMT+8',
      'location': 'China, Taiwan, Hong Kong',
    },
    {'name': 'Japan Standard Time', 'offset': 'GMT+9', 'location': 'Japan'},
    {
      'name': 'Korea Standard Time',
      'offset': 'GMT+9',
      'location': 'South Korea',
    },
    {
      'name': 'India Standard Time',
      'offset': 'GMT+5:30',
      'location': 'India, Sri Lanka',
    },
    {
      'name': 'Arabian Standard Time',
      'offset': 'GMT+4',
      'location': 'UAE, Oman',
    },

    // Europe
    {
      'name': 'Greenwich Mean Time',
      'offset': 'GMT+0',
      'location': 'London, Dublin',
    },
    {
      'name': 'Central European Time',
      'offset': 'GMT+1',
      'location': 'Paris, Berlin, Rome',
    },
    {
      'name': 'Eastern European Time',
      'offset': 'GMT+2',
      'location': 'Helsinki, Athens, Cairo',
    },
    {
      'name': 'Moscow Standard Time',
      'offset': 'GMT+3',
      'location': 'Moscow, Istanbul',
    },

    // Americas
    {
      'name': 'Eastern Standard Time',
      'offset': 'GMT-5',
      'location': 'New York, Miami, Toronto',
    },
    {
      'name': 'Central Standard Time',
      'offset': 'GMT-6',
      'location': 'Chicago, Dallas, Mexico City',
    },
    {
      'name': 'Mountain Standard Time',
      'offset': 'GMT-7',
      'location': 'Denver, Phoenix',
    },
    {
      'name': 'Pacific Standard Time',
      'offset': 'GMT-8',
      'location': 'Los Angeles, Vancouver',
    },
    {
      'name': 'Atlantic Standard Time',
      'offset': 'GMT-4',
      'location': 'Halifax, Caracas',
    },
    {
      'name': 'Brazil Standard Time',
      'offset': 'GMT-3',
      'location': 'São Paulo, Rio de Janeiro',
    },
    {
      'name': 'Argentina Standard Time',
      'offset': 'GMT-3',
      'location': 'Buenos Aires',
    },

    // Oceania
    {
      'name': 'Australian Eastern Time',
      'offset': 'GMT+10',
      'location': 'Sydney, Melbourne, Brisbane',
    },
    {
      'name': 'Australian Central Time',
      'offset': 'GMT+9:30',
      'location': 'Adelaide, Darwin',
    },
    {'name': 'Australian Western Time', 'offset': 'GMT+8', 'location': 'Perth'},
    {
      'name': 'New Zealand Standard Time',
      'offset': 'GMT+12',
      'location': 'Auckland, Wellington',
    },

    // Africa
    {
      'name': 'South Africa Standard Time',
      'offset': 'GMT+2',
      'location': 'Cape Town, Johannesburg',
    },
    {
      'name': 'West Africa Time',
      'offset': 'GMT+1',
      'location': 'Lagos, Casablanca',
    },
    {
      'name': 'East Africa Time',
      'offset': 'GMT+3',
      'location': 'Nairobi, Addis Ababa',
    },

    // Pacific
    {
      'name': 'Hawaii Standard Time',
      'offset': 'GMT-10',
      'location': 'Honolulu',
    },
    {
      'name': 'Alaska Standard Time',
      'offset': 'GMT-9',
      'location': 'Anchorage',
    },
    {
      'name': 'Fiji Standard Time',
      'offset': 'GMT+12',
      'location': 'Suva, Fiji',
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _saveEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text('Save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Input with Icon
            Row(
              children: [
                if (selectedEventType == 'Birthday')
                  Icon(Icons.cake, color: Colors.grey[600], size: 24)
                else if (selectedEventType == 'Task')
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.grey[600],
                    size: 24,
                  )
                else
                  Icon(Icons.event, color: Colors.grey[600], size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
                    decoration: InputDecoration(
                      hintText:
                          selectedEventType == 'Birthday'
                              ? 'Add name'
                              : selectedEventType == 'Task'
                              ? 'Add title'
                              : 'Add title',
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 24,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Event Type Selection
            Row(
              children:
                  eventTypes.map((type) {
                    bool isSelected = selectedEventType == type;
                    return Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selectedEventType = type;
                            if (type == 'Birthday') {
                              isAllDay = true;
                              repeatOption = 'Yearly';
                              selectedColor = Colors.green;
                              notifications = [
                                '1 week before at 9 AM',
                                'On the day at 9 AM',
                              ];
                            } else if (type == 'Task') {
                              repeatOption = 'Does not repeat';
                              selectedColor = Colors.blue;
                              isAllDay = false;
                              notifications = ['30 minutes before'];
                            } else {
                              selectedColor = Colors.red;
                              notifications = ['30 minutes before'];
                            }
                          });
                        },
                        selectedColor: Colors.blue[100],
                        backgroundColor: Colors.grey[100],
                        labelStyle: TextStyle(
                          color:
                              isSelected ? Colors.blue[800] : Colors.grey[700],
                        ),
                      ),
                    );
                  }).toList(),
            ),

            SizedBox(height: 30),

            // Show different content based on event type
            if (selectedEventType == 'Birthday')
              _buildBirthdayContent()
            else if (selectedEventType == 'Task')
              _buildTaskContent()
            else
              _buildEventContent(),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthdayContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date only (no time for birthday)
        _buildOptionRow(
          icon: Icons.calendar_today,
          title: DateFormat('MMM d').format(startDate), // "May 1" format
          onTap: () => _selectDate(true),
        ),

        SizedBox(height: 20),

        // Multiple Notifications
        _buildMultipleNotifications(),

        SizedBox(height: 20),

        // Color Selection (Default Green for Birthday)
        _buildOptionRow(
          icon: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: selectedColor,
              shape: BoxShape.circle,
            ),
          ),
          title: 'Default color',
          onTap: _selectColor,
        ),
      ],
    );
  }

  Widget _buildTaskContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // All-day Toggle
        _buildOptionRow(
          icon: Icons.access_time,
          title: 'All-day',
          trailing: Switch(
            value: isAllDay,
            onChanged: (value) {
              setState(() {
                isAllDay = value;
              });
            },
            activeColor: Colors.blue,
          ),
        ),

        SizedBox(height: 20),

        // Date and Time
        _buildDateTimeRow('', endDate, endTime, false),

        SizedBox(height: 20),

        // Repeat
        _buildOptionRow(
          icon: Icons.repeat,
          title: repeatOption,
          onTap: () {
            // Show repeat options
          },
        ),

        SizedBox(height: 20),

        // Add details toggle
        _buildOptionRow(
          icon: Icons.subject,
          title: 'Add details',
          onTap: () {
            setState(() {
              showTaskDetails = !showTaskDetails;
            });
          },
        ),

        // Show additional details if expanded
        if (showTaskDetails) ...[
          SizedBox(height: 20),

          // Multiple Notifications
          _buildMultipleNotifications(),

          SizedBox(height: 20),

          // Priority
          _buildOptionRow(
            icon: Icons.flag,
            title: 'Priority: $taskPriority',
            onTap: () {
              // Show priority selector
            },
          ),

          SizedBox(height: 20),

          // Status
          _buildOptionRow(
            icon: Icons.check_circle_outline,
            title: 'Status: $taskStatus',
            onTap: () {
              // Show status selector
            },
          ),
        ],
      ],
    );
  }

  Widget _buildEventContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // All-day Toggle
        _buildOptionRow(
          icon: Icons.access_time,
          title: 'All-day',
          trailing: Switch(
            value: isAllDay,
            onChanged: (value) {
              setState(() {
                isAllDay = value;
              });
            },
            activeColor: Colors.blue,
          ),
        ),

        SizedBox(height: 20),

        // Start Date/Time
        _buildDateTimeRow('Start', startDate, startTime, true),

        SizedBox(height: 10),

        // End Date/Time
        _buildDateTimeRow('End', endDate, endTime, false),

        SizedBox(height: 20),

        // Timezone
        _buildOptionRow(
          icon: Icons.public,
          title: selectedTimezone,
          onTap: _selectTimezone,
        ),

        SizedBox(height: 20),

        // Repeat
        _buildOptionRow(
          icon: Icons.repeat,
          title: repeatOption,
          onTap: () {
            // Show repeat options
          },
        ),

        Divider(height: 40, color: Colors.grey[300]),

        // Add People
        _buildOptionRow(
          icon: Icons.person_add,
          title: 'Add people',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Add people feature coming soon!')),
            );
          },
        ),

        SizedBox(height: 10),

        // View Schedules Button
        Center(
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('View schedules feature coming soon!')),
              );
            },
            child: Text('View schedules'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),

        Divider(height: 40, color: Colors.grey[300]),

        // Add Video Conferencing
        _buildOptionRow(
          icon: Icons.videocam,
          title: 'Add video conferencing',
          trailing:
              hasVideoConference ? Icon(Icons.check, color: Colors.blue) : null,
          onTap: () {
            setState(() {
              hasVideoConference = !hasVideoConference;
            });
          },
        ),

        SizedBox(height: 20),

        // Add Location
        _buildOptionRow(
          icon: Icons.location_on,
          title:
              _locationController.text.isEmpty
                  ? 'Add location'
                  : _locationController.text,
          onTap: _addLocation,
        ),

        SizedBox(height: 20),

        // Multiple Notifications
        _buildMultipleNotifications(),

        SizedBox(height: 20),

        // Color Selection
        _buildOptionRow(
          icon: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: selectedColor,
              shape: BoxShape.circle,
            ),
          ),
          title: _getColorName(selectedColor),
          onTap: _selectColor,
        ),

        Divider(height: 40, color: Colors.grey[300]),

        // Add Description
        _buildOptionRow(
          icon: Icons.subject,
          title:
              _descriptionController.text.isEmpty
                  ? 'Add description'
                  : _descriptionController.text,
          onTap: _addDescription,
        ),

        Divider(height: 40, color: Colors.grey[300]),

        // Add Google Drive Attachment
        _buildOptionRow(
          icon: Icons.attach_file,
          title: 'Add Google Drive attachment',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Google Drive integration coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMultipleNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current notifications
        ...notifications.map(
          (notification) => Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.notifications, color: Colors.grey[700]),
                SizedBox(width: 16),
                Expanded(
                  child: Text(notification, style: TextStyle(fontSize: 16)),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      notifications.remove(notification);
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close, color: Colors.grey[700], size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 8),

        // Add notification button
        InkWell(
          onTap: _showNotificationPicker,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(width: 40),
                Text(
                  'Add notification',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionRow({
    required dynamic icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child:
                  icon is IconData ? Icon(icon, color: Colors.grey[700]) : icon,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeRow(
    String label,
    DateTime date,
    TimeOfDay time,
    bool isStart,
  ) {
    String dateFormat = '';
    if (selectedEventType == 'Birthday') {
      dateFormat = DateFormat('MMM d').format(date); // "May 1"
    } else {
      dateFormat = DateFormat(
        'EEE, MMM d, y',
      ).format(date); // "Thu, May 1, 2025"
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (label.isNotEmpty) SizedBox(width: 40),
          // Date Section
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _selectDate(isStart),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text(dateFormat, style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
          // Time Section (only if not all-day and not birthday)
          if (!isAllDay && selectedEventType != 'Birthday')
            Expanded(
              flex: 1,
              child: InkWell(
                onTap: () => _selectTime(isStart),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Text(
                    time.format(context),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          startDate = pickedDate;
          // If start date is after end date, update end date to match start date
          if (startDate.isAfter(endDate)) {
            endDate = startDate;
          }
        } else {
          endDate = pickedDate;
          // If end date is before start date, update start date to match end date
          if (endDate.isBefore(startDate)) {
            startDate = endDate;
          }
        }
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );

    if (pickedTime != null) {
      setState(() {
        if (isStart) {
          startTime = pickedTime;
          // Automatically set end time to 1 hour later
          int newHour = pickedTime.hour + 1;
          int newMinute = pickedTime.minute;

          // Handle day overflow
          if (newHour >= 24) {
            newHour = newHour - 24;
            endDate = startDate.add(Duration(days: 1));
          }

          endTime = TimeOfDay(hour: newHour, minute: newMinute);
        } else {
          endTime = pickedTime;
        }
      });
    }
  }

  void _selectTimezone() {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> filteredTimezones = List.from(timezoneOptions);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'Enter a region or time zone',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Search Field
                        TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search time zones...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              filteredTimezones =
                                  timezoneOptions.where((timezone) {
                                    return timezone['name']
                                            .toLowerCase()
                                            .contains(value.toLowerCase()) ||
                                        timezone['location']
                                            .toLowerCase()
                                            .contains(value.toLowerCase()) ||
                                        timezone['offset']
                                            .toLowerCase()
                                            .contains(value.toLowerCase());
                                  }).toList();
                            });
                          },
                        ),
                        SizedBox(height: 16),

                        // Current timezone info
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.blue[600]),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current: ${DateTime.now().timeZoneName}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                    Text(
                                      'Local time: ${DateFormat('HH:mm').format(DateTime.now())}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Timezone List
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredTimezones.length,
                            itemBuilder: (context, index) {
                              final timezone = filteredTimezones[index];
                              final isSelected =
                                  selectedTimezone == timezone['name'];

                              final now = DateTime.now();
                              final timeStr = DateFormat('HH:mm').format(now);

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedTimezone = timezone['name'];
                                  });
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue[50] : null,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.public,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              timezone['name'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    isSelected
                                                        ? FontWeight.w500
                                                        : FontWeight.normal,
                                              ),
                                            ),
                                            Text(
                                              '$timeStr ${timezone['offset']}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              timezone['location'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(Icons.check, color: Colors.blue),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _showNotificationPicker() {
    String? selectedNotification =
        selectedEventType == 'Birthday'
            ? '1 day before at 9 AM'
            : '30 minutes before';

    // Different options for Birthday vs others
    List<String> options =
        selectedEventType == 'Birthday'
            ? [
              '1 week before at 9 AM',
              '3 days before at 9 AM',
              '1 day before at 9 AM',
              'On the day at 9 AM',
              'Custom...',
            ]
            : notificationOptions;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    constraints: BoxConstraints(maxHeight: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: ListView(
                            children:
                                options.map((option) {
                                  return RadioListTile<String>(
                                    title: Text(option),
                                    value: option,
                                    groupValue: selectedNotification,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedNotification = value;
                                      });
                                    },
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  );
                                }).toList(),
                          ),
                        ),

                        SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (selectedNotification != null &&
                                    !notifications.contains(
                                      selectedNotification,
                                    )) {
                                  setState(() {
                                    notifications.add(selectedNotification!);
                                  });
                                }
                                Navigator.pop(context);
                              },
                              child: Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _selectColor() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Choose color',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: colorOptions.length,
                      itemBuilder: (context, index) {
                        final colorOption = colorOptions[index];
                        final isSelected =
                            selectedColor == colorOption['color'];

                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedColor = colorOption['color'];
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            margin: EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.grey[100] : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: colorOption['color'],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    colorOption['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check, color: Colors.blue),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _getColorName(Color color) {
    for (var colorOption in colorOptions) {
      if (colorOption['color'] == color) {
        return colorOption['name'];
      }
    }
    return 'Custom color';
  }

  void _addLocation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Location'),
            content: TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Enter location',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {});
                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  void _addDescription() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Description'),
            content: TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter description',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {});
                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  void _saveEvent() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mohon masukkan judul ${selectedEventType.toLowerCase()}!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create event object based on type
    Map<String, dynamic> event = {
      'title': _titleController.text,
      'type': selectedEventType,
      'notifications': notifications,
      'color': _getColorName(selectedColor),
      'createdAt': DateTime.now().toIso8601String(),
    };

    if (selectedEventType == 'Birthday') {
      event.addAll({
        'birthdayDate': startDate.toIso8601String(),
        'dateDisplay': DateFormat('MMM d').format(startDate),
        'isAllDay': true,
        'repeat': 'Yearly',
        'description': _descriptionController.text,
      });
    } else if (selectedEventType == 'Task') {
      event.addAll({
        'dueDate': endDate.toIso8601String(),
        'dueTime': isAllDay ? null : '${endTime.hour}:${endTime.minute}',
        'isAllDay': isAllDay,
        'priority': taskPriority,
        'status': taskStatus,
        'repeat': repeatOption,
        'description': _descriptionController.text,
        'showDetails': showTaskDetails,
      });
    } else {
      // Event type
      event.addAll({
        'isAllDay': isAllDay,
        'startDate': startDate.toIso8601String(),
        'startTime': isAllDay ? null : '${startTime.hour}:${startTime.minute}',
        'endDate': endDate.toIso8601String(),
        'endTime': isAllDay ? null : '${endTime.hour}:${endTime.minute}',
        'timezone': selectedTimezone,
        'repeat': repeatOption,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'hasVideoConference': hasVideoConference,
        'invitedPeople': invitedPeople,
      });
    }

    // Print event data (in real app, save to database or API)
    print('${selectedEventType} saved: $event');

    String message = '';
    if (selectedEventType == 'Birthday') {
      message = 'Birthday "${_titleController.text}" berhasil disimpan!';
    } else if (selectedEventType == 'Task') {
      message = 'Task "${_titleController.text}" berhasil dibuat!';
    } else {
      message = 'Event "${_titleController.text}" berhasil disimpan!';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Clear form and navigate back
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    Navigator.pop(context);
  }
}
