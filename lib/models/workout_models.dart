import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A single set performed for an exercise: a weight/reps pair.
class SetEntry {
  final String id;
  double weight;
  int reps;

  SetEntry({String? id, required this.weight, required this.reps})
      : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'weight': weight,
        'reps': reps,
      };

  factory SetEntry.fromJson(Map<String, dynamic> json) => SetEntry(
        id: json['id'] as String,
        weight: (json['weight'] as num).toDouble(),
        reps: json['reps'] as int,
      );
}

/// One exercise performed within a session, with all its sets.
class SessionExercise {
  final String id;
  String exerciseName;
  List<SetEntry> sets;

  SessionExercise({String? id, required this.exerciseName, List<SetEntry>? sets})
      : id = id ?? _uuid.v4(),
        sets = sets ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseName': exerciseName,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory SessionExercise.fromJson(Map<String, dynamic> json) => SessionExercise(
        id: json['id'] as String,
        exerciseName: json['exerciseName'] as String,
        sets: (json['sets'] as List)
            .map((e) => SetEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// A single workout session (a visit to the gym), containing the
/// exercises performed and their sets.
class WorkoutSession {
  final String id;
  DateTime date;
  List<SessionExercise> exercises;

  WorkoutSession({String? id, required this.date, List<SessionExercise>? exercises})
      : id = id ?? _uuid.v4(),
        exercises = exercises ?? [];

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        exercises: (json['exercises'] as List)
            .map((e) => SessionExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
