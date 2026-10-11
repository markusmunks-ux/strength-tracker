import 'package:flutter/material.dart';

/// Shows a bottom sheet letting the user search existing exercises or
/// type a brand new one. Returns the chosen exercise name, or null if
/// dismissed without a selection.
Future<String?> showExercisePickerSheet(BuildContext context, List<String> known) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _ExercisePickerSheet(known: known),
  );
}

class _ExercisePickerSheet extends StatefulWidget {
  final List<String> known;
  const _ExercisePickerSheet({required this.known});

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.known
        .where((name) => name.toLowerCase().contains(_query.toLowerCase()))
        .toList()
      ..sort();

    final exactMatch = widget.known.any((name) => name.toLowerCase() == _query.toLowerCase());
    final canAddNew = _query.trim().isNotEmpty && !exactMatch;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Add exercise', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Search or type a new exercise',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) Navigator.pop(context, v.trim());
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  // Keys keep each row's widget identity stable as the
                  // filtered list grows/shrinks while typing, so a tap
                  // can't land on the wrong exercise mid-reflow.
                  children: [
                    ...filtered.map(
                      (name) => ListTile(
                        key: ValueKey('exercise-$name'),
                        leading: const Icon(Icons.fitness_center),
                        title: Text(name),
                        onTap: () => Navigator.pop(context, name),
                      ),
                    ),
                    if (canAddNew)
                      ListTile(
                        key: const ValueKey('add-new-exercise'),
                        leading: const Icon(Icons.add_circle_outline),
                        title: Text('Add "${_query.trim()}"'),
                        onTap: () => Navigator.pop(context, _query.trim()),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
