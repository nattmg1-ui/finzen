import '../models/goal_contribution_model.dart';
import 'savings_goal_service.dart';

/// Lee el historial de aportes a metas (Cubo C), usando la
/// colección expuesta por SavingsGoalService.
class GoalContributionService {
  final SavingsGoalService _goalService = SavingsGoalService();

  Stream<List<GoalContributionModel>> watchAll() {
    return _goalService.contributionsRef.snapshots().map(
          (snapshot) => snapshot.docs.map(GoalContributionModel.fromDoc).toList(),
        );
  }
}