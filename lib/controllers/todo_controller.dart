import 'dart:async';
import 'package:flutter/material.dart';
import 'package:todo/models/todo.dart';
import 'package:todo/repositories/supabase_repository.dart';
import 'package:todo/utils/enums.dart';

class TodoController extends ChangeNotifier {
  final SupabaseRepository _repository;
  StreamSubscription? _todoSubscription;

  List<Todo> _allTodos = [];
  List<Todo> get allTodos => _allTodos;

  String _searchQuery = '';
  TodoStage? _filterStage;
  bool? _filterIsDone;
  
  String get searchQuery => _searchQuery;
  TodoStage? get filterStage => _filterStage;
  bool? get filterIsDone => _filterIsDone;

  // Filtered List based on search and filters (unchanged)
  List<Todo> get filteredTodos {
    return _allTodos.where((todo) {
      final matchesSearch = _searchQuery.isEmpty ||
          todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (todo.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesStage = _filterStage == null || todo.stage == _filterStage;
      
      final matchesIsDone = _filterIsDone == null || todo.isDone == _filterIsDone;
      
      return matchesSearch && matchesStage && matchesIsDone;
    }).toList();
  }

  // Grouped list for Kanban View (unchanged)
  Map<TodoStage, List<Todo>> get groupedTodos {
    final groups = {
      TodoStage.Todo: <Todo>[],
      TodoStage.InProgress: <Todo>[],
      TodoStage.Done: <Todo>[],
    };

    for (final todo in filteredTodos) {
      groups[todo.stage]!.add(todo);
    }

    return groups;
  }

  TodoController(this._repository) {
    _startListening();
  }

  // --- Search/Filter Handlers (unchanged) ---
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterStage(TodoStage? stage) {
    _filterStage = stage;
    notifyListeners();
  }
  
  void setFilterIsDone(bool? isDone) {
    _filterIsDone = isDone;
    notifyListeners();
  }
  
  void clearFilters() {
    _searchQuery = '';
    _filterStage = null;
    _filterIsDone = null;
    notifyListeners();
  }


  // --- Realtime Setup (unchanged) ---
  void _startListening() {
    _todoSubscription?.cancel();
    
    _todoSubscription = _repository.getTodoStream().listen((newTodos) {
      _allTodos = newTodos;
      notifyListeners(); 
    }, onError: (error) {
      debugPrint("Realtime Stream Error: $error");
    });
  }

  @override
  void dispose() {
    _todoSubscription?.cancel();
    super.dispose();
  }


  // --- CRUD Methods ---

  // FIX: Added notifyListeners() as a safeguard to ensure immediate UI update
  Future<void> addTodo(Map<String, dynamic> todoMap) async {
    try {
      await _repository.addTodo(todoMap);
      // Fallback notifyListeners to update the UI instantly (in case the stream is slow)
      notifyListeners(); 
    } catch (e) {
      debugPrint('Add Todo Error: $e');
      rethrow; 
    }
  }
  
  Future<void> toggleTodoStatus(Todo todo, {VoidCallback? onError}) async {
    final newTodo = todo.copyWith(
      isDone: !todo.isDone,
      stage: !todo.isDone ? TodoStage.Done : TodoStage.Todo, 
      doneAt: !todo.isDone ? DateTime.now() : null,
    );
    
    _allTodos = _allTodos.map((t) => t.id == todo.id ? newTodo : t).toList();
    notifyListeners();

    try {
      await _repository.updateTodo(newTodo);
    } catch (e) {
      _allTodos = _allTodos.map((t) => t.id == todo.id ? todo : t).toList();
      notifyListeners();
      onError?.call();
      debugPrint('Toggle Todo Error: $e');
    }
  }

  // Kanban Stage Update Logic (unchanged)
  Future<void> updateTodoStage(Todo todo, TodoStage newStage, {VoidCallback? onError}) async {
    DateTime? newInProgressAt = todo.inProgressAt;
    DateTime? newDoneAt = todo.doneAt;
    bool newIsDone = false;
    
    if (newStage == TodoStage.InProgress && todo.stage == TodoStage.Todo) {
      newInProgressAt = DateTime.now();
      newDoneAt = null; 
    } else if (newStage == TodoStage.Done) {
      newIsDone = true;
      newDoneAt = DateTime.now();
      if (todo.stage == TodoStage.Todo) {
        newInProgressAt = DateTime.now(); 
      }
    } else if (newStage == TodoStage.Todo) {
      newInProgressAt = null;
      newDoneAt = null;
    }


    final newTodo = todo.copyWith(
      stage: newStage,
      isDone: newIsDone, 
      inProgressAt: newInProgressAt,
      doneAt: newDoneAt,
    );
    
    _allTodos = _allTodos.map((t) => t.id == todo.id ? newTodo : t).toList();
    notifyListeners();

    try {
      await _repository.updateTodo(newTodo);
    } catch (e) {
      _allTodos = _allTodos.map((t) => t.id == todo.id ? todo : t).toList();
      notifyListeners();
      onError?.call();
      debugPrint('Update Stage Error: $e');
    }
  }

  // Edit Todo (unchanged)
  Future<void> editTodo(Todo todo, String title, String description, {DateTime? startDate, DateTime? endDate, TimeOfDay? startTime, TimeOfDay? endTime, VoidCallback? onError}) async {
    final updatedTodo = todo.copyWith(
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      startTime: startTime,
      endTime: endTime,
    );
    
    _allTodos = _allTodos.map((t) => t.id == todo.id ? updatedTodo : t).toList();
    notifyListeners();

    try {
      await _repository.updateTodo(updatedTodo);
    } catch (e) {
      _allTodos = _allTodos.map((t) => t.id == todo.id ? todo : t).toList();
      notifyListeners();
      onError?.call();
      debugPrint('Edit Todo Error: $e');
    }
  }

  // Delete Todo (unchanged)
  Future<void> deleteTodo(Todo todo, {VoidCallback? onError}) async {
    final originalTodos = List<Todo>.from(_allTodos);

    _allTodos.removeWhere((t) => t.id == todo.id);
    notifyListeners();

    try {
      await _repository.deleteTodo(todo.id);
    } catch (e) {
      _allTodos = originalTodos;
      notifyListeners();
      onError?.call();
      debugPrint('Delete Todo Error: $e');
    }
  }
}