import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/controllers/todo_controller.dart'; 
import 'package:todo/models/todo.dart';
import 'package:todo/utils/enums.dart';
import 'package:todo/widgets/todo_card.dart';
import 'package:todo/views/todo_detail_dialog.dart'; 
import 'package:intl/intl.dart'; 

class TodoView extends StatelessWidget {
  const TodoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TODO LIST'), // Changed to Kanban Board
        // Theme is inherited from main.dart
      ),
      body: Consumer<TodoController>(
        builder: (context, controller, child) {
          final groupedTodos = controller.groupedTodos;

          // Search and Filter Bar
          final searchBar = Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                TextField(
                  onChanged: controller.setSearchQuery,
                  decoration: const InputDecoration(
                    hintText: 'Search tasks by title or description...',
                    prefixIcon: Icon(Icons.search),
                    // Input theme inherited
                  ),
                ),
                const SizedBox(height: 8),
                _FilterRow(),
              ],
            ),
          );


          if (controller.allTodos.isEmpty && controller.searchQuery.isEmpty) { 
            return Column(
              children: [
                searchBar,
                const Expanded(
                  child: Center(
                    child: Text('Add your first task!', style: TextStyle(fontSize: 16, color: Colors.white70)),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              searchBar,
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8.0),
                  children: TodoStage.values.map((stage) {
                    return KanbanColumn(
                      stage: stage,
                      todos: groupedTodos[stage]!,
                      controller: controller,
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value( 
        value: context.read<TodoController>(), 
        child: _AddTodoDialog(),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TodoController>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ActionChip(
            label: const Text('Clear Filters', style: TextStyle(color: Colors.black)),
            onPressed: controller.clearFilters,
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          
          // Filter by Stage
          DropdownButton<TodoStage?>(
            hint: const Text('Filter by Stage'),
            value: controller.filterStage, 
            dropdownColor: Theme.of(context).canvasColor,
            onChanged: (TodoStage? newValue) {
              controller.setFilterStage(newValue);
            },
            items: [
              const DropdownMenuItem(value: null, child: Text('All Stages')),
              ...TodoStage.values.map<DropdownMenuItem<TodoStage>>((TodoStage stage) {
                return DropdownMenuItem<TodoStage>(
                  value: stage,
                  child: Text(stage.displayName),
                );
              }).toList(),
            ],
          ),
          const SizedBox(width: 8),

          // Filter by Completion
          DropdownButton<bool?>(
            hint: const Text('Filter by Status'),
            value: controller.filterIsDone, 
            dropdownColor: Theme.of(context).canvasColor,
            onChanged: (bool? newValue) {
              controller.setFilterIsDone(newValue);
            },
            items: const [
              DropdownMenuItem<bool?>(value: null, child: Text('All Status')),
              DropdownMenuItem<bool>(value: true, child: Text('Completed')),
              DropdownMenuItem<bool>(value: false, child: Text('Active')),
            ],
          ),
        ],
      ),
    );
  }
}


// --- Kanban Widgets ---

class KanbanColumn extends StatelessWidget {
  final TodoStage stage;
  final List<Todo> todos;
  final TodoController controller;

  const KanbanColumn({
    super.key,
    required this.stage,
    required this.todos,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    const double columnWidth = 300.0; 
    
    // Set column header color based on stage (unchanged)
    Color headerColor;
    switch (stage) {
      case TodoStage.Todo:
        headerColor = Colors.blue.shade800.withOpacity(0.7);
        break;
      case TodoStage.InProgress:
        headerColor = Colors.amber.shade800.withOpacity(0.7);
        break;
      case TodoStage.Done:
        headerColor = Colors.green.shade800.withOpacity(0.7);
        break;
    }

    return DragTarget<Todo>(
      onAccept: (Todo todo) {
        controller.updateTodoStage(todo, stage);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: columnWidth,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor, // Dark canvas background
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: candidateData.isNotEmpty ? Theme.of(context).colorScheme.primary : Theme.of(context).canvasColor,
              width: candidateData.isNotEmpty ? 3.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Column Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11.0)),
                ),
                child: Text(
                  '${stage.displayName} (${todos.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Task List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return Draggable<Todo>(
                        data: todo,
                        feedback: SizedBox(
                          width: columnWidth, 
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(8),
                            child: Opacity(opacity: 0.8, child: TodoCard(todo: todo)),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: TodoCard(todo: todo),
                        ),
                        child: TodoCard(todo: todo),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddTodoDialog extends StatefulWidget {
  @override
  __AddTodoDialogState createState() => __AddTodoDialogState();
}

class __AddTodoDialogState extends State<_AddTodoDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Helper to display formatted date (unchanged)
  String get _startDateText => _startDate == null ? 'Select Start Date' : DateFormat('MMM dd, yyyy').format(_startDate!);
  String get _endDateText => _endDate == null ? 'Select End Date' : DateFormat('MMM dd, yyyy').format(_endDate!);
  String get _startTimeText => _startTime == null ? 'Select Start Time' : _startTime!.format(context);
  String get _endTimeText => _endTime == null ? 'Select End Time' : _endTime!.format(context);

  // Date picker logic (unchanged)
  Future<void> _pickDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: Theme.of(context).colorScheme.primary),
          dialogBackgroundColor: Theme.of(context).canvasColor,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Time picker logic (unchanged)
  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: Theme.of(context).colorScheme.primary),
          dialogBackgroundColor: Theme.of(context).canvasColor,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _addTodo() async {
    if (_formKey.currentState!.validate()) {
      final controller = context.read<TodoController>();
      
      // CRITICAL FIX: Get the root ScaffoldMessenger context before popping the dialog
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      if(mounted) Navigator.of(context).pop(); 

      final tempTodo = Todo(
        id: 'temp', 
        userId: 'temp', 
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        isDone: false,
        createdAt: DateTime.now(),
        startDate: _startDate,
        endDate: _endDate,
        startTime: _startTime,
        endTime: _endTime,
      );
      
      try {
        await controller.addTodo(tempTodo.toMap()); 

        // SUCCESS MESSAGE (Now guaranteed to be displayed via the retrieved context)
        if(mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('✅ Task added successfully!'),
              duration: const Duration(seconds: 2),
              backgroundColor: Theme.of(context).colorScheme.primary, // Teal accent
            ),
          );
        }
      } catch (e) {
        // ERROR MESSAGE
        if(mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('❌ Failed to add task. Error: ${e.toString()}'),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Override bottom sheet color for better UX
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Theme.of(context).canvasColor,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create New Task', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                  validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description (Detailed Info)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                
                // Date/Time Pickers
                Row(
                  children: [
                    Expanded(child: _buildDateTimePicker(Icons.calendar_today, _startDateText, () => _pickDate(true))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDateTimePicker(Icons.access_time, _startTimeText, () => _pickTime(true))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildDateTimePicker(Icons.event, _endDateText, () => _pickDate(false))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDateTimePicker(Icons.schedule, _endTimeText, () => _pickTime(false))),
                  ],
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _addTodo,
                  child: const Text('Create Task'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: text.contains('Date') ? 'Date' : 'Time',
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          filled: true,
          fillColor: Colors.grey.shade700,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}