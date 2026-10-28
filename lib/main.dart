import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// App entry point: initialize Flutter plugins before loading local preferences.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskFlowApp());
}

const Color kYellow = Color(0xFFFFD600);
const Color kInk = Color(0xFF151515);
const Color kCanvas = Color(0xFFF7F7F2);
const Color kMuted = Color(0xFF777777);

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kCanvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kYellow,
          primary: kInk,
          secondary: kYellow,
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: kCanvas,
          foregroundColor: kInk,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE9E9E2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kInk, width: 1.4),
          ),
        ),
      ),
      home: const SessionGate(),
    );
  }
}

// SessionGate checks whether the demo user previously logged in.
// If the session is saved, show the main app; otherwise show LoginPage.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _loggedIn = prefs.getBool('isLoggedIn') ?? false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _loggedIn
        ? const MainShell()
        : LoginPage(onLogin: () => setState(() => _loggedIn = true));
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});
  final VoidCallback onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController(text: 'demo');
  final _password = TextEditingController(text: '1234');
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (_username.text.trim() != 'demo' || _password.text != '1234') {
      setState(() => _error = 'Invalid details. Use the demo account below.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    if ((prefs.getString('userName') ?? '').isEmpty) {
      await prefs.setString('userName', 'Demo User');
    }
    if (!mounted) return;
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand logo asset shown on the login screen.
                  Image.asset('assets/images/app_logo.png',
                      height: 88, fit: BoxFit.contain),
                  const SizedBox(height: 32),
                  const Text('MAKE ROOM\nFOR WHAT MATTERS.',
                      style: TextStyle(
                          fontSize: 34,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2)),
                  const SizedBox(height: 12),
                  const Text('Your day, organized. One task at a time.',
                      style: TextStyle(color: kMuted, fontSize: 15)),
                  const SizedBox(height: 34),
                  const Text('Username',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _username,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Enter username'),
                  ),
                  const SizedBox(height: 18),
                  const Text('Password',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      hintText: 'Enter password',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _busy ? null : _login,
                      style: FilledButton.styleFrom(
                        backgroundColor: kYellow,
                        foregroundColor: kInk,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('LOGIN  →',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE9E9E2))),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DEMO ACCOUNT',
                            style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w900,
                                color: kMuted)),
                        SizedBox(height: 8),
                        Text('Username:  demo',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('Password:  1234',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                      child: Text('Local demo • No account server needed',
                          style: TextStyle(color: kMuted, fontSize: 12))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum TaskStatus { pending, completed }

// Model class: one task's data. toJson/fromJson let us save and restore it as JSON.
class TaskItem {
  TaskItem(
      {required this.id,
      required this.title,
      required this.createdAt,
      this.status = TaskStatus.pending});
  final String id;
  String title;
  final DateTime createdAt;
  TaskStatus status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: json['id'] as String,
        title: json['title'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        status: (json['status'] == 'completed')
            ? TaskStatus.completed
            : TaskStatus.pending,
      );
}

// MainShell holds the shared task list and switches between Tasks and Profile tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  bool _loading = true;
  final List<TaskItem> _tasks = [];
  String _userName = 'Demo User';
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tasks') ?? '[]';
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => TaskItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _tasks
        ..clear()
        ..addAll(list);
    } catch (_) {
      _tasks.clear();
    }
    _userName = prefs.getString('userName') ?? 'Demo User';
    _photoPath = prefs.getString('photoPath');
    if (!mounted) return;
    setState(() => _loading = false);
  }

  // Convert tasks to JSON and save them on this device (no server/database).
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'tasks', jsonEncode(_tasks.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveName(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', clean);
    if (!mounted) return;
    setState(() => _userName = clean);
  }

  // Pick an image from the gallery and copy it into app-owned storage so the path persists.
  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
      if (picked == null) return;
      final directory = await getApplicationDocumentsDirectory();
      final extension =
          picked.path.contains('.') ? picked.path.split('.').last : 'jpg';
      final saved = await File(picked.path)
          .copy('${directory.path}/profile_photo.$extension');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('photoPath', saved.path);
      if (!mounted) return;
      setState(() => _photoPath = saved.path);
      _message('Profile photo updated');
    } catch (e) {
      _message('Could not open gallery. Please try again.');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  // Ask for a title, create a task object, update the UI, then persist the list.
  Future<void> _addTask() async {
    final title = await _taskDialog();
    if (title == null || title.trim().isEmpty) return;
    setState(() => _tasks.insert(
        0,
        TaskItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title.trim(),
          createdAt: DateTime.now(),
        )));
    await _saveTasks();
  }

  // Reuse the task dialog with the existing title, then update and save the task.
  Future<void> _editTask(TaskItem task) async {
    final title = await _taskDialog(initial: task.title, heading: 'Edit task');
    if (title == null || title.trim().isEmpty) return;
    setState(() => task.title = title.trim());
    await _saveTasks();
  }

  // Opens the shared Add/Edit dialog. The dialog owns its controller so it is
  // disposed only when the dialog widget itself is removed from the widget tree.
  Future<String?> _taskDialog(
      {String initial = '', String heading = 'Add a new task'}) {
    return showDialog<String>(
      context: context,
      builder: (_) => _TaskEditorDialog(initial: initial, heading: heading),
    );
  }

  // Confirm deletion first so a task is not removed accidentally.
  Future<void> _deleteTask(TaskItem task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('“${task.title}” will be removed from your list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kInk),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _tasks.removeWhere((e) => e.id == task.id));
    await _saveTasks();
    _message('Task deleted');
  }

  // Checkbox updates the task status and immediately saves the new status.
  Future<void> _toggleTask(TaskItem task, bool completed) async {
    setState(() =>
        task.status = completed ? TaskStatus.completed : TaskStatus.pending);
    await _saveTasks();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SessionGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final completed =
        _tasks.where((t) => t.status == TaskStatus.completed).length;
    final pending = _tasks.length - completed;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Reuse the same logo asset in the app header.
            Image.asset('assets/images/app_logo.png',
                height: 36, width: 145, fit: BoxFit.contain),
          ],
        ),
        actions: [
          IconButton(
              tooltip: 'Log out',
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded)),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          TasksPage(
            tasks: _tasks,
            completed: completed,
            pending: pending,
            onAdd: _addTask,
            onEdit: _editTask,
            onDelete: _deleteTask,
            onToggle: _toggleTask,
          ),
          ProfilePage(
            name: _userName,
            photoPath: _photoPath,
            total: _tasks.length,
            completed: completed,
            pending: pending,
            onSaveName: _saveName,
            onPickPhoto: _pickPhoto,
          ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: _addTask,
              backgroundColor: kYellow,
              foregroundColor: kInk,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New task',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        backgroundColor: Colors.white,
        indicatorColor: kYellow.withValues(alpha: 0.45),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.checklist_rounded),
              selectedIcon: Icon(Icons.checklist_rounded),
              label: 'Tasks'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}

// A separate StatefulWidget gives the TextEditingController the same lifecycle
// as the dialog. This avoids disposing the controller while the closing dialog
// may still be finishing its route transition.
class _TaskEditorDialog extends StatefulWidget {
  const _TaskEditorDialog({required this.initial, required this.heading});

  final String initial;
  final String heading;

  @override
  State<_TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<_TaskEditorDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // For Add, initial is empty. For Edit, it contains the current task title.
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    // Always release the controller when Flutter disposes this dialog.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.heading,
          style: const TextStyle(fontWeight: FontWeight.w900)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 120,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => Navigator.pop(context, _controller.text),
        decoration:
            const InputDecoration(hintText: 'e.g. Finish project report'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: kYellow, foregroundColor: kInk),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save task'),
        ),
      ],
    );
  }
}

// TasksPage displays the list, filters, progress summary, and task action buttons.
class TasksPage extends StatefulWidget {
  const TasksPage({
    super.key,
    required this.tasks,
    required this.completed,
    required this.pending,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final List<TaskItem> tasks;
  final int completed;
  final int pending;
  final Future<void> Function() onAdd;
  final Future<void> Function(TaskItem) onEdit;
  final Future<void> Function(TaskItem) onDelete;
  final Future<void> Function(TaskItem, bool) onToggle;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final visible = widget.tasks.where((task) {
      if (_filter == 'Completed') return task.status == TaskStatus.completed;
      if (_filter == 'Pending') return task.status == TaskStatus.pending;
      return true;
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          const Text('YOUR SPACE',
              style: TextStyle(
                  color: kMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text('Get things\ndone.',
              style: TextStyle(
                  fontSize: 36,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: kInk, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('YOUR DAILY PROGRESS',
                    style: TextStyle(
                        color: kYellow,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _ProgressStat(
                            value: '${widget.tasks.length}',
                            label: 'TOTAL TASKS')),
                    Expanded(
                        child: _ProgressStat(
                            value: '${widget.completed}', label: 'COMPLETED')),
                    Expanded(
                        child: _ProgressStat(
                            value: '${widget.pending}', label: 'PENDING')),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: widget.tasks.isEmpty
                        ? 0
                        : widget.completed / widget.tasks.length,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(kYellow),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                    widget.tasks.isEmpty
                        ? 'Add a task to start your progress.'
                        : '${(widget.completed / widget.tasks.length * 100).round()}% of your tasks completed',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              const Expanded(
                  child: Text('My tasks',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5))),
              Text('${visible.length} items',
                  style: const TextStyle(
                      color: kMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Pending', 'Completed'].map((filter) {
                final selected = _filter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = filter),
                    backgroundColor: Colors.white,
                    selectedColor: kYellow,
                    side: BorderSide(
                        color: selected ? kYellow : const Color(0xFFE9E9E2)),
                    labelStyle:
                        TextStyle(fontWeight: FontWeight.w800, color: kInk),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE9E9E2))),
              child: Column(
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: const BoxDecoration(
                        color: kYellow, shape: BoxShape.circle),
                    child: const Icon(Icons.add_task_rounded, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                      widget.tasks.isEmpty
                          ? 'A fresh start.'
                          : 'Nothing in this filter.',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                      widget.tasks.isEmpty
                          ? 'Add your first task and make it happen.'
                          : 'Try another filter to see your tasks.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kMuted)),
                  if (widget.tasks.isEmpty) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: widget.onAdd,
                      style: FilledButton.styleFrom(
                          backgroundColor: kYellow, foregroundColor: kInk),
                      child: const Text('Create a task'),
                    ),
                  ],
                ],
              ),
            )
          else
            ...visible.map((task) => _TaskCard(
                  task: task,
                  onEdit: () => widget.onEdit(task),
                  onDelete: () => widget.onDelete(task),
                  onToggle: (value) => widget.onToggle(task, value),
                )),
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
        ],
      );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard(
      {required this.task,
      required this.onEdit,
      required this.onDelete,
      required this.onToggle});
  final TaskItem task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final done = task.status == TaskStatus.completed;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9E9E2))),
      child: Row(
        children: [
          Checkbox(
            value: done,
            onChanged: (value) => onToggle(value ?? false),
            activeColor: kInk,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          Expanded(
            child: InkWell(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            decoration:
                                done ? TextDecoration.lineThrough : null,
                            color: done ? kMuted : kInk)),
                    const SizedBox(height: 5),
                    Text(done ? 'COMPLETED' : 'NOT COMPLETED',
                        style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w900,
                            color: done ? const Color(0xFF2E7D32) : kMuted)),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
              tooltip: 'Edit task',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 19)),
          IconButton(
              tooltip: 'Delete task',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 20, color: Color(0xFFB3261E))),
        ],
      ),
    );
  }
}

// ProfilePage lets the user edit their display name, change their photo, and view stats.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.name,
    required this.photoPath,
    required this.total,
    required this.completed,
    required this.pending,
    required this.onSaveName,
    required this.onPickPhoto,
  });
  final String name;
  final String? photoPath;
  final int total;
  final int completed;
  final int pending;
  final Future<void> Function(String) onSaveName;
  final Future<void> Function() onPickPhoto;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _nameController;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name && !_editing)
      _nameController.text = widget.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completion =
        widget.total == 0 ? 0.0 : widget.completed / widget.total;
    final photoExists =
        widget.photoPath != null && File(widget.photoPath!).existsSync();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          const Text('YOUR ACCOUNT',
              style: TextStyle(
                  color: kMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text('Profile',
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                color: kYellow, borderRadius: BorderRadius.circular(26)),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 49,
                      backgroundColor: Colors.white,
                      backgroundImage: photoExists
                          ? FileImage(File(widget.photoPath!))
                          : null,
                      child: photoExists
                          ? null
                          : const Icon(Icons.person_rounded,
                              size: 52, color: kInk),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: kInk,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: widget.onPickPhoto,
                          child: const Padding(
                              padding: EdgeInsets.all(9),
                              child: Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 18)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(widget.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                const SizedBox(height: 5),
                const Text('TASKFLOW MEMBER',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8)),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: widget.onPickPhoto,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Change photo'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: kInk,
                      side: const BorderSide(color: kInk),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Personal details',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE9E9E2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DISPLAY NAME',
                    style: TextStyle(
                        fontSize: 10,
                        color: kMuted,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3)),
                const SizedBox(height: 9),
                TextField(
                    controller: _nameController,
                    enabled: _editing,
                    maxLength: 40,
                    decoration: const InputDecoration(
                        hintText: 'Your name', counterText: '')),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (_editing) {
                        if (_nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Name cannot be empty')));
                          return;
                        }
                        await widget.onSaveName(_nameController.text);
                        if (mounted) setState(() => _editing = false);
                      } else {
                        setState(() => _editing = true);
                      }
                    },
                    style: FilledButton.styleFrom(
                        backgroundColor: kInk,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text(_editing ? 'Save changes' : 'Edit name',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                if (_editing)
                  Center(
                      child: TextButton(
                          onPressed: () {
                            setState(() {
                              _editing = false;
                              _nameController.text = widget.name;
                            });
                          },
                          child: const Text('Cancel'))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Task statistics',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _ProfileStat(
                      value: '${widget.total}',
                      label: 'TOTAL',
                      icon: Icons.list_alt_rounded)),
              const SizedBox(width: 10),
              Expanded(
                  child: _ProfileStat(
                      value: '${widget.completed}',
                      label: 'COMPLETED',
                      icon: Icons.check_circle_outline_rounded)),
              const SizedBox(width: 10),
              Expanded(
                  child: _ProfileStat(
                      value: '${widget.pending}',
                      label: 'PENDING',
                      icon: Icons.pending_actions_rounded)),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE9E9E2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(
                      child: Text('Completion rate',
                          style: TextStyle(fontWeight: FontWeight.w800))),
                  Text('${(completion * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                      value: completion,
                      minHeight: 9,
                      backgroundColor: const Color(0xFFEFEFE9),
                      valueColor: const AlwaysStoppedAnimation(kYellow)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat(
      {required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9E9E2))),
        child: Column(
          children: [
            Icon(icon, size: 21, color: kInk),
            const SizedBox(height: 9),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 8,
                    letterSpacing: 0.7,
                    color: kMuted,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );
}
