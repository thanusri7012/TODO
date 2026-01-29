import 'package:flutter/material.dart';
import 'package:todo/controllers/todo_controller.dart';
import 'package:todo/models/todo.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:todo/utils/enums.dart';

class TodoDetailDialog extends StatefulWidget {
  final Todo todo;

  const TodoDetailDialog({super.key, required this.todo});

  @override
  State<TodoDetailDialog> createState() => _TodoDetailDialogState();
}

class _TodoDetailDialogState extends State<TodoDetailDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  // FIX: Helper to format TimeOfDay to 12-hour string
  String formatTimeOfDay(TimeOfDay? timeOfDay) {
    if (timeOfDay == null) return 'N/A';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    return DateFormat('h:mm a').format(dt);
  }
  
  // FIX: Helper to format DateTime to 12-hour string
  String formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController = TextEditingController(text: widget.todo.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String days = duration.inDays > 0 ? "${duration.inDays}d " : "";
    String hours = twoDigits(duration.inHours.remainder(24));
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inDays > 0) {
      return "$days${hours}h ${minutes}m";
    } else if (duration.inHours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    } else if (duration.inMinutes > 0) {
       return "${minutes}m ${seconds}s";
    } else {
       return "${seconds}s";
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Theme.of(context).canvasColor),
      child: Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Task Details (${widget.todo.stage.displayName})', 
                style: Theme.of(context).textTheme.headlineSmall
              ),
              const SizedBox(height: 16),

              // Title and Description (Read-only)
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                enabled: false, // Always read-only in detail view
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Detailed Info)'),
                maxLines: 3,
                enabled: false, // Always read-only in detail view
              ),
              const SizedBox(height: 24),
              
              // -----------------------------------------------------------------
              // SCHEDULED/PROGRESS DETAILS (View-only based on stage)
              // -----------------------------------------------------------------
              Text('Scheduling & Progress', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),

              // Show Scheduled Window (Applicable to Todo and InProgress view)
              if (widget.todo.startDate != null) 
                _buildDetailRow(
                  context, 
                  'Scheduled Start', 
                  '${DateFormat('MMM dd, yyyy').format(widget.todo.startDate!)} ${formatTimeOfDay(widget.todo.startTime)}',
                  color: Theme.of(context).colorScheme.primary,
                ),
              
              if (widget.todo.endDate != null) 
                _buildDetailRow(
                  context, 
                  'Scheduled End', 
                  '${DateFormat('MMM dd, yyyy').format(widget.todo.endDate!)} ${formatTimeOfDay(widget.todo.endTime)}',
                  color: Theme.of(context).colorScheme.primary,
                ),
              
              // In Progress / Done Tracking Times
              if (widget.todo.stage == TodoStage.InProgress || widget.todo.stage == TodoStage.Done) 
                _buildDetailRow(
                  context, 
                  'Actual Start', 
                  '${DateFormat('MMM dd, yyyy').format(widget.todo.inProgressAt ?? widget.todo.createdAt)} ${formatTime(widget.todo.inProgressAt ?? widget.todo.createdAt)}',
                  color: Colors.amber.shade400,
                ),
              
              if (widget.todo.stage == TodoStage.Done && widget.todo.doneAt != null) ...[
                _buildDetailRow(
                  context, 
                  'Completed At', 
                  '${DateFormat('MMM dd, yyyy').format(widget.todo.doneAt!)} ${formatTime(widget.todo.doneAt!)}',
                  color: Colors.green.shade400,
                ),
                if (widget.todo.inProgressAt != null) 
                  _buildDetailRow(
                    context, 
                    'Total Duration', 
                    _formatDuration(widget.todo.doneAt!.difference(widget.todo.inProgressAt!)),
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
              
              const SizedBox(height: 30),
              
              // No action buttons (Save/Delete/Toggle) are required here, as actions
              // are handled via the outside Kanban card menu and drag/drop.
            ],
          ),
        ),
      ),
    );
  }
}