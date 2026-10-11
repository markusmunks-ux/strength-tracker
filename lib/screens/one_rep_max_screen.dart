import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/workout_repository.dart';
import '../util/one_rep_max.dart';

class OneRepMaxScreen extends StatelessWidget {
  const OneRepMaxScreen({super.key});

  Future<void> _editOneRepMax(BuildContext context, String exerciseName, double? current) async {
    final controller = TextEditingController(
      text: current != null ? _formatWeight(current) : '',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$exerciseName — one rep max'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'One rep max (kg)'),
        ),
        actions: [
          if (current != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, -1.0),
              child: const Text('Clear'),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.replaceAll(',', '.'));
              if (value == null || value <= 0) return;
              Navigator.pop(ctx, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || !context.mounted) return;
    final repo = context.read<WorkoutRepository>();
    if (result == -1.0) {
      await repo.clearOneRepMax(exerciseName);
    } else {
      await repo.setOneRepMax(exerciseName, result);
    }
  }

  String _formatWeight(double w) => w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toString();

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<WorkoutRepository>();
    final exercises = [...repo.knownExercises]..sort();
    final maxes = repo.oneRepMaxes;

    return Scaffold(
      appBar: AppBar(title: const Text('One Rep Max')),
      body: exercises.isEmpty
          ? const Center(child: Text('Log an exercise first, then set its one rep max here.'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final name = exercises[index];
                final oneRm = maxes[name];
                return ExpansionTile(
                  key: ValueKey(name),
                  title: Text(name),
                  subtitle: Text(oneRm != null ? '1RM: ${_formatWeight(oneRm)} kg' : 'No 1RM set'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Set one rep max',
                    onPressed: () => _editOneRepMax(context, name, oneRm),
                  ),
                  children: [
                    if (oneRm == null)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Set a one rep max to see suggested weights per rep count.'),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: suggestedRepRanges.map((reps) {
                            final weight = estimateWeightForReps(oneRm, reps);
                            return Chip(
                              label: Text('$reps rep${reps == 1 ? '' : 's'}: ${_formatWeight(weight)} kg'),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
