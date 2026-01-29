import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo/models/todo.dart';

class SupabaseRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final String _tableName = 'todosapp'; // Your table name

  // --- AUTHENTICATION ---
  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  // FIX: Ensure signOut is correctly implemented
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  
  // Stream for auth state changes (used in main.dart)
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // --- CRUD OPERATIONS ---
  
  // Realtime Stream of Todos
  Stream<List<Todo>> getTodoStream() {
    return _client
        .from(_tableName)
        .stream(primaryKey: ['id']) 
        .order('created_at', ascending: false)
        .map((maps) => maps.map(Todo.fromMap).toList());
  }

  Future<void> addTodo(Map<String, dynamic> todoMap) async {
    final user = currentUser;
    if (user == null) throw Exception("User not authenticated.");

    await _client.from(_tableName).insert({
      ...todoMap, 
      'user_id': user.id, 
    });
  }

  // Update Todo (used for edit, toggle, and kanban stage change)
  Future<void> updateTodo(Todo todo) async {
    await _client.from(_tableName).update(todo.toMap()).eq('id', todo.id);
  }

  // Delete Todo
  Future<void> deleteTodo(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  // --- SEARCH/FILTER ---
  Future<List<Todo>> searchAndFilterTodos({
    String? query,
    bool? isDone,
    String? stage,
  }) async {
    var queryBuilder = _client.from(_tableName).select();

    if (query != null && query.isNotEmpty) {
      queryBuilder = queryBuilder.or(
        'title.ilike.%$query%,description.ilike.%$query%',
      );
    }

    if (isDone != null) {
      queryBuilder = queryBuilder.eq('is_done', isDone);
    }
    
    if (stage != null) {
       queryBuilder = queryBuilder.eq('stage', stage);
    }

    final List<Map<String, dynamic>> data = await queryBuilder.order('created_at', ascending: false);
    
    return data.map(Todo.fromMap).toList();
  }
}