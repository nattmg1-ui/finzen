import 'cycle_service.dart';

/// Ingreso Base de Seguridad (IBS) = mín(I t-1, I t-2, I t-3), donde
/// cada I es el ingreso registrado DENTRO de cada uno de los 3 ciclos
/// completos anteriores. Solo aplica a perfiles Freelance o Mixto.
class SafetyBaseIncomeService {
  final CycleService _cycleService = CycleService();

  static const int requiredCycles = 3;

  /// Devuelve null si el perfil no es Freelance/Mixto, o si no hay 3
  /// ciclos completos con ingreso registrado (RQNF).
  Future<int?> computeSafetyBaseIncome() async {
    final profile = await _cycleService.effectiveProfile();
    if (profile != 'Freelance' && profile != 'Mixto') return null;

    final cycles = await _cycleService.getPreviousCycles(requiredCycles);
    if (cycles.length < requiredCycles) return null;

    final incomes = <int>[];
    for (final cycle in cycles) {
      incomes.add(await _cycleService.incomeInCycle(cycle));
    }

    // RQNF: los 3 ciclos deben tener ingreso registrado.
    if (incomes.any((income) => income <= 0)) return null;

    return incomes.reduce((a, b) => a < b ? a : b);
  }
}