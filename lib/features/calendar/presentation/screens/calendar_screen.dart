import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sandboxnotion/utils/constants.dart';
import 'package:table_calendar/table_calendar.dart';

/// Calendar screen that displays a full calendar view with events
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Calendar format (month, 2-week, week)
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Selected day
  DateTime _selectedDay = DateTime.now();
  
  // Focused day (the day that is currently visible)
  DateTime _focusedDay = DateTime.now();
  
  // Dummy events
  final Map<DateTime, List<String>> _dummyEvents = {
    DateTime.now().subtract(const Duration(days: 2)): ['Team Meeting', 'Project Review'],
    DateTime.now(): ['Doctor Appointment', 'Lunch with Alex'],
    DateTime.now().add(const Duration(days: 3)): ['Conference Call', 'Gym'],
    DateTime.now().add(const Duration(days: 7)): ['Birthday Party'],
  };

  // Get events for a given day
  List<String> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _dummyEvents[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calendar',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back to Sandbox',
        ),
        actions: [
          // Today button
          TextButton.icon(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            icon: const Icon(Icons.today),
            label: const Text('Today'),
          ),
          
          // More options
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'month',
                child: Text('Month View'),
              ),
              const PopupMenuItem(
                value: 'week',
                child: Text('Week View'),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Text('Import Events'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Events'),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'month':
                  setState(() {
                    _calendarFormat = CalendarFormat.month;
                  });
                  break;
                case 'week':
                  setState(() {
                    _calendarFormat = CalendarFormat.week;
                  });
                  break;
                // Other options would have real implementations
                default:
                  break;
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Calendar content
          Column(
            children: [
              // Calendar widget
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: _getEventsForDay,
                calendarStyle: CalendarStyle(
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color: AppConstants.seedColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppConstants.seedColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppConstants.seedColor,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const Divider(),
              
              // Events for selected day
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      DateFormat.yMMMMd().format(_selectedDay),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: null, // Disabled in placeholder
                      tooltip: 'Add Event',
                    ),
                  ],
                ),
              ),
              
              // Event list
              Expanded(
                child: ListView.builder(
                  itemCount: _getEventsForDay(_selectedDay).length,
                  itemBuilder: (context, index) {
                    final event = _getEventsForDay(_selectedDay)[index];
                    return ListTile(
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppConstants.seedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(event),
                      subtitle: Text('No time specified'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: null, // Disabled in placeholder
                    );
                  },
                ),
              ),
            ],
          ),
          
          // Under construction overlay
          Positioned.fill(
            child: Container(
              color: isDarkMode 
                  ? Colors.black.withOpacity(0.7) 
                  : Colors.white.withOpacity(0.7),
              child: Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.construction,
                          size: 64,
                          color: AppConstants.seedColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Calendar Module',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This feature is under construction.\nCheck back soon!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Sandbox'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.seedColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: null, // Disabled in placeholder
        backgroundColor: AppConstants.seedColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
