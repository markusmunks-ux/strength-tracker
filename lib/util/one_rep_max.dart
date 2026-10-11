/// Estimates the weight you could lift for a given number of reps,
/// based on a known one-rep max, using the Epley formula:
/// 1RM = weight * (1 + reps / 30)  =>  weight = 1RM / (1 + reps / 30)
double estimateWeightForReps(double oneRepMax, int reps) {
  if (reps <= 1) return oneRepMax;
  final raw = oneRepMax / (1 + reps / 30.0);
  // Round to the nearest 0.5kg, which is practical for loadable plates.
  return (raw * 2).round() / 2;
}

const suggestedRepRanges = [1, 2, 3, 5, 8, 10, 12, 15];
