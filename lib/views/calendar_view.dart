import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todo/controllers/todo_controller.dart';
import 'package:todo/models/todo.dart';
import 'package:todo/utils/enums.dart';
import 'package:intl/intl.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Helper to get the list of Todos for a specific day (unchanged)
  List<Todo> _getEventsForDay(DateTime day, TodoController controller) {
    return controller.allTodos.where((todo) {
      final start = todo.startDate;
      final end = todo.endDate;

      if (start == null) return false;

      if (isSameDay(start, day)) return true;
      if (end != null && day.isAfter(start) && day.isBefore(end)) return true;
      if (end != null && isSameDay(end, day)) return true;

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TodoController>();
    final selectedDayEvents = _getEventsForDay(_selectedDay ?? _focusedDay, controller);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) => _getEventsForDay(day, controller),
            
            // CRITICAL FIX: Only mark current date with the primary color, remove all markers
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final isCurrentDay = isSameDay(day, DateTime.now());
                final isSelected = isSameDay(_selectedDay, day);
                final hasEvents = _getEventsForDay(day, controller).isNotEmpty;
                
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      // Only mark Today if it's not the selected day
                      color: isCurrentDay && !isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.5) : null,
                      shape: BoxShape.circle,
                      // Show a teal border if there are events
                      border: hasEvents ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.7), width: 1.5) : null,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isSelected ? Theme.of(context).colorScheme.onPrimary : Colors.white70,
                        fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
              markerBuilder: (context, day, events) => const SizedBox.shrink(), // HIDE ALL MARKERS
            ),
            
            // Calendar UI/UX Styling (Dark Theme)
            calendarStyle: CalendarStyle(
              todayDecoration: const BoxDecoration(shape: BoxShape.circle), 
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary, // Teal selected
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(color: Colors.white70),
              weekendTextStyle: const TextStyle(color: Colors.white70),
              outsideTextStyle: TextStyle(color: Colors.grey.shade600),
            ),
            headerStyle: HeaderStyle(
              formatButtonDecoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(8.0),
              ),
              formatButtonTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
              titleCentered: true,
              titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
              leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(8.0),
              child: selectedDayEvents.isEmpty
                  ? Center(
                      child: Text(
                        'No tasks scheduled for ${DateFormat('MMM dd').format(_selectedDay ?? _focusedDay)}.',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: selectedDayEvents.length,
                      itemBuilder: (context, index) {
                        final todo = selectedDayEvents[index];
                        return Card(
                          color: Theme.of(context).canvasColor,
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: Icon(
                              todo.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: todo.isDone ? Colors.green.shade400 : Colors.red.shade400,
                            ),
                            title: Text(
                              todo.title,
                              style: TextStyle(
                                decoration: todo.isDone ? TextDecoration.lineThrough : null,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              todo.description ?? 'No description.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Text(
                              todo.stage.displayName,
                              style: TextStyle(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}