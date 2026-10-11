import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout_models.dart';

const _sessionsKey = 'workout_sessions_v1';
const _exercisesKey = 'known_exercises_v1';
const _oneRepMaxKey = 'one_rep_maxes_v1';

const _defaultExercises = [
  // Chest
  'Bench Press',
  'Incline Bench Press',
  'Decline Bench Press',
  'Dumbbell Bench Press',
  'Incline Dumbbell Press',
  'Chest Fly',
  'Dips',
  'Push-up',
  // Back
  'Deadlift',
  'Romanian Deadlift',
  'Barbell Row',
  'Pendlay Row',
  'Seated Cable Row',
  'T-Bar Row',
  'Lat Pulldown',
  'Pull-up',
  'Chin-up',
  // Shoulders
  'Overhead Press',
  'Dumbbell Shoulder Press',
  'Arnold Press',
  'Lateral Raise',
  'Front Raise',
  'Rear Delt Fly',
  'Shrugs',
  'Face Pull',
  // Legs
  'Squat',
  'Front Squat',
  'Leg Press',
  'Lunges',
  'Bulgarian Split Squat',
  'Leg Extension',
  'Leg Curl',
  'Calf Raise',
  'Hip Thrust',
  'Good Morning',
  // Arms
  'Bicep Curl',
  'Hammer Curl',
  'Barbell Curl',
  'Preacher Curl',
  'Tricep Pushdown',
  'Skull Crusher',
  'Overhead Tricep Extension',
  'Close-Grip Bench Press',
  // Core
  'Plank',
  'Hanging Leg Raise',
  'Cable Crunch',
  'Russian Twist',
  'Ab Wheel Rollout',
];

/// Holds all workout data in memory and persists it to local device
/// storage (browser local storage on web) as JSON.
class WorkoutRepository extends ChangeNotifier {
  List<WorkoutSession> _sessions = [];
  List<String> _knownExercises = [..._defaultExercises];
  Map<String, double> _oneRepMaxes = {};
  late SharedPreferences _prefs;
  bool _loaded = false;

  List<WorkoutSession> get sessions =>
      [..._sessions]..sort((a, b) => b.date.compareTo(a.date));

  List<String> get knownExercises => [..._knownExercises];

  Map<String, double> get oneRepMaxes => Map.unmodifiable(_oneRepMaxes);

  bool get isLoaded => _loaded;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    final sessionsRaw = _prefs.getString(_sessionsKey);
    if (sessionsRaw != null) {
      final decoded = jsonDecode(sessionsRaw) as List;
      _sessions = decoded
          .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final exercisesRaw = _prefs.getStringList(_exercisesKey);
    if (exercisesRaw != null && exercisesRaw.isNotEmpty) {
      _knownExercises = exercisesRaw;
    }

    final oneRepMaxRaw = _prefs.getString(_oneRepMaxKey);
    if (oneRepMaxRaw != null) {
      final decoded = jsonDecode(oneRepMaxRaw) as Map<String, dynamic>;
      _oneRepMaxes = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> _persistSessions() async {
    final encoded = jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await _prefs.setString(_sessionsKey, encoded);
  }

  Future<void> _persistExercises() async {
    await _prefs.setStringList(_exercisesKey, _knownExercises);
  }

  Future<void> _persistOneRepMaxes() async {
    await _prefs.setString(_oneRepMaxKey, jsonEncode(_oneRepMaxes));
  }

  Future<void> setOneRepMax(String exerciseName, double value) async {
    _oneRepMaxes[exerciseName] = value;
    await rememberExerciseName(exerciseName);
    await _persistOneRepMaxes();
    notifyListeners();
  }

  Future<void> clearOneRepMax(String exerciseName) async {
    _oneRepMaxes.remove(exerciseName);
    await _persistOneRepMaxes();
    notifyListeners();
  }

  WorkoutSession? sessionById(String id) {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<WorkoutSession> createSession() async {
    final session = WorkoutSession(date: DateTime.now());
    _sessions.add(session);
    await _persistSessions();
    notifyListeners();
    return session;
  }

  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    await _persistSessions();
    notifyListeners();
  }

  Future<void> setSessionDate(String sessionId, DateTime date) async {
    final session = sessionById(sessionId);
    if (session == null) return;
    session.date = date;
    await _persistSessions();
    notifyListeners();
  }

  Future<void> addExerciseToSession(String sessionId, String exerciseName) async {
    final session = sessionById(sessionId);
    if (session == null) return;
    session.exercises.add(SessionExercise(exerciseName: exerciseName));
    await rememberExerciseName(exerciseName);
    await _persistSessions();
    notifyListeners();
  }

  Future<void> removeExerciseFromSession(String sessionId, String sessionExerciseId) async {
    final session = sessionById(sessionId);
    if (session == null) return;
    session.exercises.removeWhere((e) => e.id == sessionExerciseId);
    await _persistSessions();
    notifyListeners();
  }

  Future<void> addSet(String sessionId, String sessionExerciseId, double weight, int reps) async {
    final session = sessionById(sessionId);
    if (session == null) return;
    final exercise = session.exercises.firstWhere((e) => e.id == sessionExerciseId);
    exercise.sets.add(SetEntry(weight: weight, reps: reps));
    await _persistSessions();
    notifyListeners();
  }

  Future<void> updateSet(String sessionId, String sessionExerciseId, String setId, double weight, int reps) async {
    final session = sessionById(sessionId);
    if (session == null) return;
    final exercise = session.exercises.firstWhere((e) => e.id == sessionExerciseId);
    final set = exercise.sets.firstWhere((s) => s.id == setId);
    set.weight = weight;
    set.reps = reps;
    await _persistSessions();
    notifyListeners();
  }

  Future<void> removeSet(String sessionId, String sessionExerciseId, String setId) async {
    final session = sessionById(sessionId);
    if (session == null) return;
    final exercise = session.exercises.firstWhere((e) => e.id == sessionExerciseId);
    exercise.sets.removeWhere((s) => s.id == setId);
    await _persistSessions();
    notifyListeners();
  }

  /// Returns the most recent set logged for [exerciseName] across all
  /// sessions, used to prefill the add-set form with sensible defaults.
  SetEntry? lastSetFor(String exerciseName) {
    for (final session in sessions) {
      for (final exercise in session.exercises) {
        if (exercise.exerciseName == exerciseName && exercise.sets.isNotEmpty) {
          return exercise.sets.last;
        }
      }
    }
    return null;
  }

  Future<void> rememberExerciseName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _knownExercises.contains(trimmed)) return;
    _knownExercises.add(trimmed);
    await _persistExercises();
    notifyListeners();
  }
}
