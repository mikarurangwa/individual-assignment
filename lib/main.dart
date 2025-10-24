// main.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const StudyPlannerApp());
}

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Planner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Task Model
class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final TimeOfDay? reminderTime;
  final bool reminderEnabled;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.reminderTime,
    this.reminderEnabled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'reminderTime': reminderTime != null
          ? '${reminderTime!.hour}:${reminderTime!.minute}'
          : null,
      'reminderEnabled': reminderEnabled,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    TimeOfDay? reminderTime;
    if (json['reminderTime'] != null) {
      final parts = json['reminderTime'].toString().split(':');
      reminderTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate']),
      reminderTime: reminderTime,
      reminderEnabled: json['reminderEnabled'] ?? false,
    );
  }
}

// In-Memory Storage Service (Web + Mobile Compatible)
class TaskStorageService {
  static final TaskStorageService _instance = TaskStorageService._internal();
  static final List<Task> _tasksInMemory = [];
  static bool _remindersEnabledInMemory = true;

  factory TaskStorageService() {
    return _instance;
  }

  TaskStorageService._internal();

  Future<void> saveTasks(List<Task> tasks) async {
    _tasksInMemory.clear();
    _tasksInMemory.addAll(tasks);
    // In a real app, you could add optional native storage here
  }

  Future<List<Task>> loadTasks() async {
    return List.from(_tasksInMemory);
  }

  Future<void> saveRemindersEnabled(bool enabled) async {
    _remindersEnabledInMemory = enabled;
  }

  Future<bool> loadRemindersEnabled() async {
    return _remindersEnabledInMemory;
  }
}

// Main App State
class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  List<Task> _tasks = [];
  bool _remindersEnabled = true;
  final TaskStorageService _storageService = TaskStorageService();

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadSettings();
  }

  Future<void> _loadTasks() async {
    final tasks = await _storageService.loadTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  Future<void> _loadSettings() async {
    final enabled = await _storageService.loadRemindersEnabled();
    setState(() {
      _remindersEnabled = enabled;
    });
  }

  void _checkReminders() {
    if (!_remindersEnabled) return;

    final now = DateTime.now();
    for (final task in _tasks) {
      if (task.reminderEnabled && task.reminderTime != null) {
        final reminderDateTime = DateTime(
          task.dueDate.year,
          task.dueDate.month,
          task.dueDate.day,
          task.reminderTime!.hour,
          task.reminderTime!.minute,
        );

        if (reminderDateTime.isBefore(now) &&
            reminderDateTime.add(Duration(minutes: 5)).isAfter(now)) {
          _showReminderDialog(task);
        }
      }
    }
  }

  void _showReminderDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Task Reminder'),
        content: Text('Remember: ${task.title}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addTask(Task task) {
    setState(() {
      _tasks.add(task);
    });
    _storageService.saveTasks(_tasks);
  }

  void _updateTask(Task updatedTask) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
    });
    _storageService.saveTasks(_tasks);
  }

  void _deleteTask(String taskId) {
    setState(() {
      _tasks.removeWhere((t) => t.id == taskId);
    });
    _storageService.saveTasks(_tasks);
  }

  void _toggleReminders(bool value) {
    setState(() {
      _remindersEnabled = value;
    });
    _storageService.saveRemindersEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner'),
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: _buildScreens(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildScreens() {
    switch (_selectedIndex) {
      case 0:
        return TodayScreen(tasks: _tasks, onAddTask: _addTask, onDeleteTask: _deleteTask);
      case 1:
        return CalendarScreen(tasks: _tasks, onAddTask: _addTask);
      case 2:
        return SettingsScreen(
          remindersEnabled: _remindersEnabled,
          onToggleReminders: _toggleReminders,
        );
      default:
        return Container();
    }
  }
}

// Today Screen
class TodayScreen extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onAddTask;
  final Function(String) onDeleteTask;

  const TodayScreen({
    Key? key,
    required this.tasks,
    required this.onAddTask,
    required this.onDeleteTask,
  }) : super(key: key);

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayTasks = widget.tasks
        .where((task) =>
            task.dueDate.year == today.year &&
            task.dueDate.month == today.month &&
            task.dueDate.day == today.day)
        .toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Tasks',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (todayTasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No tasks for today',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todayTasks.length,
                itemBuilder: (context, index) {
                  final task = todayTasks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(task.title),
                      subtitle: task.description != null
                          ? Text(task.description!)
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => widget.onDeleteTask(task.id),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NewTaskScreen(onAddTask: widget.onAddTask),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('New Task', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Calendar Screen
class CalendarScreen extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onAddTask;

  const CalendarScreen({
    Key? key,
    required this.tasks,
    required this.onAddTask,
  }) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;

    final selectedTasks = widget.tasks.where((task) {
      return task.dueDate.year == _selectedDate.year &&
          task.dueDate.month == _selectedDate.month &&
          task.dueDate.day == _selectedDate.day;
    }).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month - 1,
                      );
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCalendarGrid(daysInMonth, firstWeekday),
            const SizedBox(height: 24),
            Text(
              'Tasks for ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (selectedTasks.isEmpty)
              Text('No tasks for this day',
                  style: Theme.of(context).textTheme.bodyMedium)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedTasks.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(selectedTasks[index].title),
                      subtitle: Text(selectedTasks[index].description ?? ''),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(int daysInMonth, int firstWeekday) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final cells = <Widget>[];

    for (var day in days) {
      cells.add(
        Center(
          child: Text(day,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }

    for (int i = 1; i < firstWeekday; i++) {
      cells.add(Container());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final hasTask =
          widget.tasks.any((task) =>
              task.dueDate.year == date.year &&
              task.dueDate.month == date.month &&
              task.dueDate.day == date.day);

      final isSelected = _selectedDate.year == date.year &&
          _selectedDate.month == date.month &&
          _selectedDate.day == date.day;

      cells.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue
                  : (hasTask ? Colors.amber[100] : null),
              border: Border.all(
                color: hasTask ? Colors.amber : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontWeight: hasTask ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: cells,
    );
  }
}

// New Task Screen
class NewTaskScreen extends StatefulWidget {
  final Function(Task) onAddTask;

  const NewTaskScreen({Key? key, required this.onAddTask}) : super(key: key);

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay? _reminderTime;
  bool _reminderEnabled = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Task'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Title (required)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Due Date: ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                child: const Text('Select Date'),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Set Reminder'),
                value: _reminderEnabled,
                onChanged: (value) {
                  setState(() {
                    _reminderEnabled = value ?? false;
                  });
                },
              ),
              if (_reminderEnabled) ...[
                const SizedBox(height: 8),
                Text(
                  'Reminder Time: ${_reminderTime?.format(context) ?? "Not set"}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _reminderTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _reminderTime = time;
                      });
                    }
                  },
                  child: const Text('Select Time'),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Title is required')),
                      );
                      return;
                    }

                    final task = Task(
                      id: DateTime.now().toString(),
                      title: _titleController.text,
                      description: _descriptionController.text.isEmpty
                          ? null
                          : _descriptionController.text,
                      dueDate: _selectedDate,
                      reminderTime: _reminderTime,
                      reminderEnabled: _reminderEnabled,
                    );

                    widget.onAddTask(task);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Task',
                      style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
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

// Settings Screen
class SettingsScreen extends StatelessWidget {
  final bool remindersEnabled;
  final Function(bool) onToggleReminders;

  const SettingsScreen({
    Key? key,
    required this.remindersEnabled,
    required this.onToggleReminders,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                title: const Text('Reminders'),
                subtitle: const Text('Enable or disable task reminders'),
                trailing: Switch(
                  value: remindersEnabled,
                  onChanged: onToggleReminders,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Storage Method:'),
                        Text(
                          'In-Memory (Web Compatible)',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your tasks are stored in memory during this session. They will persist while the app is running. Refresh the page or close the app to clear data.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Support',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This app runs on Web (Chrome), Android, and iOS. Data is stored in-memory on web and can be enhanced with SharedPreferences on mobile platforms.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Study Planner v1.0',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Organize your tasks, stay on top of your studies, and never miss a deadline.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}