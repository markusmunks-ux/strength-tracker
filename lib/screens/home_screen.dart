import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/workout_repository.dart';
import '../models/workout_models.dart';
import 'one_rep_max_screen.dart';
import 'session_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _startNewSession(BuildContext context) async {
    final repo = context.read<WorkoutRepository>();
    final session = await repo.createSession();
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SessionScreen(sessionId: session.id)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WorkoutSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete session?'),
        content: Text(
          'This will remove the session from ${DateFormat.yMMMd().format(session.date)} and all its logged sets.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<WorkoutRepository>().deleteSession(session.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<WorkoutRepository>();

    if (!repo.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final sessions = repo.sessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Strength Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'One Rep Max',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OneRepMaxScreen()),
            ),
          ),
        ],
      ),
      body: sessions.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final exerciseNames = session.exercises.map((e) => e.exerciseName).join(', ');
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(DateFormat.yMMMEd().format(session.date)),
                    subtitle: Text(
                      session.exercises.isEmpty
                          ? 'No exercises logged yet'
                          : '${session.exercises.length} exercise(s) · ${session.totalSets} set(s)\n$exerciseNames',
                    ),
                    isThreeLine: session.exercises.isNotEmpty,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, session),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SessionScreen(sessionId: session.id)),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewSession(context),
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No sessions yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "New Session" to start logging exercises, weight, reps and sets.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
