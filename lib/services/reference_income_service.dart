import 'cycle_service.dart';
import 'firestore_service.dart';
import 'safety_base_income_service.dart';

/// De dónde salió el ingreso de referencia.
enum ReferenceIncomeSource { cycle, safetyBase, diagnosis }

class ReferenceIncome {
  final int amount;
  final ReferenceIncomeSource source;

  ReferenceIncome({required this.amount, required this.source});
}

/// Ingreso de referencia del ciclo actual, usado para la alerta de
/// proyección de gasto (Módulo 8):
/// - Modo de Contingencia (Freelance sin ingreso en el ciclo actual):
///   usa el Ingreso Base de Seguridad; si todavía no hay 3 ciclos para
///   calcularlo, usa el ingreso mensual declarado en el diagnóstico.
/// - Cualquier otro caso: usa el ingreso registrado en el ciclo actual.
class ReferenceIncomeService {
  final CycleService _cycleService = CycleService();
  final SafetyBaseIncomeService _safetyBaseIncomeService = SafetyBaseIncomeService();
  final FirestoreService _firestoreService = FirestoreService();

  Future<ReferenceIncome> compute() async {
    final currentCycle = await _cycleService.getCurrentCycle();
    if (currentCycle == null) {
      return ReferenceIncome(amount: 0, source: ReferenceIncomeSource.cycle);
    }

    final profile = await _cycleService.effectiveProfile();
    final currentIncome = await _cycleService.incomeInCycle(currentCycle);

    if (profile == 'Freelance' && currentIncome <= 0) {
      final safetyBase = await _safetyBaseIncomeService.computeSafetyBaseIncome();
      if (safetyBase != null) {
        return ReferenceIncome(amount: safetyBase, source: ReferenceIncomeSource.safetyBase);
      }
      final user = await _firestoreService.fetchCurrentUserProfile();
      final declared = (user?.diagnosis?['monthlyIncome'] as num?)?.toInt() ?? 0;
      return ReferenceIncome(amount: declared, source: ReferenceIncomeSource.diagnosis);
    }

    return ReferenceIncome(amount: currentIncome, source: ReferenceIncomeSource.cycle);
  }
}
