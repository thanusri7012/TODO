import 'package:flutter/material.dart';
import 'package:todo/controllers/todo_controller.dart';
import 'package:todo/models/todo.dart';
import 'package:todo/utils/enums.dart';
import 'package:provider/provider.dart';
import 'package:todo/views/todo_detail_dialog.dart';
import 'package:intl/intl.dart'; 

class TodoCard extends StatelessWidget {
  final Todo todo;

  const TodoCard({super.key, required this.todo});

  void _showDetailDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TodoController>(), 
        child: TodoDetailDialog(todo: todo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TodoController>();
    
    final Color cardColor = Colors.grey.shade800;
    
    // Edit only in Todo
    final bool canEdit = todo.stage == TodoStage.Todo;
    // FIX: Delete allowed in ALL stages (Todo, InProgress, Done)
    final bool canDelete = true; 

    // Helper to format TimeOfDay to 12-hour string
    String formatTimeOfDay(TimeOfDay? timeOfDay) {
      if (timeOfDay == null) return '';
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
      return DateFormat('h:mm a').format(dt);
    }
    
    // Helper to format DateTime to 12-hour string
    String formatTime(DateTime? dateTime) {
      if (dateTime == null) return '';
      return DateFormat('h:mm a').format(dateTime);
    }


    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _showDetailDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      todo.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                        decoration: todo.isDone ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.white70,
                      ),
                    ),
                  ),
                  // Popup Menu (More Options: Edit/Delete)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    color: Theme.of(context).canvasColor,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showDetailDialog(context);
                      } else if (value == 'delete') {
                        controller.deleteTodo(todo);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      List<PopupMenuEntry<String>> items = [];
                      if (canEdit) {
                        items.add(
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Edit', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          ),
                        );
                      }
                      if (canDelete) {
                        items.add(
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
                          ),
                        );
                      }
                      return items;
                    },
                  ),
                ],
              ),
              if (todo.description != null && todo.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    todo.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              
              // Display Start/Progress Time Info
              if (todo.stage == TodoStage.InProgress && todo.inProgressAt != null) 
                Text('Started: ${formatTime(todo.inProgressAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade400)),
              
              if (todo.startDate != null && todo.stage != TodoStage.InProgress && todo.stage != TodoStage.Done) 
                Text('Scheduled: ${DateFormat('M/d').format(todo.startDate!)}' 
                    '${todo.startTime != null ? ' @ ${formatTimeOfDay(todo.startTime)}' : ''}',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),

              Row(
                children: [
                  Icon(
                    todo.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: todo.isDone ? Colors.green.shade400 : Colors.red.shade400,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    todo.isDone ? 'Completed' : 'Pending',
                    style: TextStyle(
                      color: todo.isDone ? Colors.green.shade400 : Colors.red.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}