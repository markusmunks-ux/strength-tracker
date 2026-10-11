import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/workout_repository.dart';
import '../models/workout_models.dart';
import 'exercise_picker_sheet.dart';

class SessionScreen extends StatelessWidget {
  final String sessionId;

  const SessionScreen({super.key, required this.sessionId});

  Future<void> _pickDate(BuildContext context, WorkoutSession session) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: session.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && context.mounted) {
      await context.read<WorkoutRepository>().setSessionDate(sessionId, picked);
    }
  }

  Future<void> _addExercise(BuildContext context) async {
    final repo = context.read<WorkoutRepository>();
    final name = await showExercisePickerSheet(context, repo.knownExercises);
    if (name != null && name.trim().isNotEmpty) {
      await repo.addExerciseToSession(sessionId, name.trim());
    }
  }

  Future<void> _addOrEditSet(
    BuildContext context,
    SessionExercise exercise, {
    SetEntry? existing,
  }) async {
    final repo = context.read<WorkoutRepository>();
    var prefillSource = existing == null ? repo.lastSetFor(exercise.exerciseName) : null;
    double? prefillWeight = existing?.weight ?? prefillSource?.weight;
    int? prefillReps = existing?.reps ?? prefillSource?.reps;

    // Loop so "Save & add another" can keep logging consecutive sets for
    // the same exercise without reopening the dialog from scratch.
    while (true) {
      final weightController = TextEditingController(
        text: prefillWeight != null ? _formatWeight(prefillWeight) : '',
      );
      final repsController = TextEditingController(
        text: prefillReps != null ? prefillReps.toString() : '',
      );

      if (!context.mounted) return;
      final result = await showDialog<_SetFormResult>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(existing == null ? 'Add set — ${exercise.exerciseName}' : 'Edit set'),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: weightController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reps'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            if (existing == null)
              OutlinedButton(
                onPressed: () {
                  final weight = double.tryParse(weightController.text.replaceAll(',', '.'));
                  final reps = int.tryParse(repsController.text);
                  if (weight == null || reps == null) return;
                  Navigator.pop(ctx, _SetFormResult(weight, reps, continueAdding: true));
                },
                child: const Text('Save & add another'),
              ),
            FilledButton(
              onPressed: () {
                final weight = double.tryParse(weightController.text.replaceAll(',', '.'));
                final reps = int.tryParse(repsController.text);
                if (weight == null || reps == null) return;
                Navigator.pop(ctx, _SetFormResult(weight, reps));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (result == null || !context.mounted) return;

      if (existing != null) {
        await repo.updateSet(sessionId, exercise.id, existing.id, result.weight, result.reps);
        return;
      }

      await repo.addSet(sessionId, exercise.id, result.weight, result.reps);
      if (!result.continueAdding) return;

      prefillWeight = result.weight;
      prefillReps = result.reps;
    }
  }

  String _formatWeight(double w) => w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toString();

  Future<void> _confirmRemoveExercise(BuildContext context, SessionExercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove exercise?'),
        content: Text(
          '${exercise.exerciseName} and its ${exercise.sets.length} logged set(s) will be removed from this session.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<WorkoutRepository>().removeExerciseFromSession(sessionId, exercise.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<WorkoutRepository>();
    final session = repo.sessionById(sessionId);

    if (session == null) {
      return const Scaffold(body: Center(child: Text('Session not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => _pickDate(context, session),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(DateFormat.yMMMEd().format(session.date)),
              const SizedBox(width: 6),
              const Icon(Icons.edit_calendar, size: 18),
            ],
          ),
        ),
      ),
      body: session.exercises.isEmpty
          ? const Center(child: Text('Tap "Add Exercise" to start logging sets.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              itemCount: session.exercises.length,
              itemBuilder: (context, index) {
                final exercise = session.exercises[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                exercise.exerciseName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Remove exercise',
                              onPressed: () => _confirmRemoveExercise(context, exercise),
                            ),
                          ],
                        ),
                        if (exercise.sets.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text('No sets yet'),
                          )
                        else
                          ...exercise.sets.asMap().entries.map((entry) {
                            final setIndex = entry.key;
                            final set = entry.value;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Text('Set ${setIndex + 1}'),
                              title: Text('${_formatWeight(set.weight)} kg × ${set.reps} reps'),
                              onTap: () => _addOrEditSet(context, exercise, existing: set),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => context
                                    .read<WorkoutRepository>()
                                    .removeSet(sessionId, exercise.id, set.id),
                              ),
                            );
                          }),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _addOrEditSet(context, exercise),
                            icon: const Icon(Icons.add),
                            label: const Text('Add set'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExercise(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Exercise'),
      ),
    );
  }
}

class _SetFormResult {
  final double weight;
  final int reps;
  final bool continueAdding;
  _SetFormResult(this.weight, this.reps, {this.continueAdding = false});
}
