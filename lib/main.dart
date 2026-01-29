import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo/controllers/todo_controller.dart';
import 'package:todo/repositories/supabase_repository.dart';
import 'package:todo/views/login_view.dart';
import 'package:todo/views/todo_view.dart';
import 'package:todo/views/calendar_view.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  
  if (supabaseUrl == null || supabaseAnonKey == null) {
     throw Exception("SUPABASE_URL or SUPABASE_ANON_KEY not found in .env file.");
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: kDebugMode,
  );

  final repository = SupabaseRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<SupabaseRepository>.value(value: repository),
        ChangeNotifierProvider<TodoController>(
          create: (context) => TodoController(repository),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Custom Color Scheme using Teal 300 and Grey 900
    const Color primaryTeal = Color(0xFF4DB6AC); // Colors.teal.shade300
    const Color darkGrey = Color(0xFF212121);   // Colors.grey.shade900
    const Color canvasGrey = Color(0xFF303030); // Colors.grey.shade800

    return MaterialApp(
      title: 'Supabase Kanban Todo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryTeal,
        scaffoldBackgroundColor: darkGrey,
        canvasColor: canvasGrey, // Used for Drawer/Bottom sheets
        // Define a custom color scheme based on the desired colors
        colorScheme: const ColorScheme.dark(
          primary: primaryTeal,
          secondary: primaryTeal,
          background: darkGrey,
          surface: canvasGrey, // Used for Cards/Sheets
          onPrimary: Colors.black,
          onSecondary: Colors.black,
        ),
        useMaterial3: true,
        
        // AppBar Styling
        appBarTheme: const AppBarTheme(
          backgroundColor: darkGrey,
          foregroundColor: primaryTeal,
          elevation: 1,
        ),

        // Global styling for text fields
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade700, // Dark input background
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: TextStyle(color: Colors.white54),
        ),

        // Global styling for buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryTeal,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
        ),
      ),
      home: StreamBuilder<AuthState>(
        stream: context.read<SupabaseRepository>().authStateChanges,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;
          if (session == null) {
            return const LoginView();
          } else {
            return const AppDashboard(); 
          }
        },
      ),
    );
  }
}

// NEW: A simple stateful widget for navigation
class AppDashboard extends StatefulWidget {
  const AppDashboard({super.key});

  @override
  State<AppDashboard> createState() => _AppDashboardState();
}

class _AppDashboardState extends State<AppDashboard> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    TodoView(),
    CalendarView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Kanban',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
        currentIndex: _selectedIndex,
        // Theme colors will be automatically applied here
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey.shade500,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        onTap: _onItemTapped,
      ),
    );
  }
}