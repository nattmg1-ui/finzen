import 'cycle_service.dart';
import 'income_service.dart';

/// Ingreso Base de Seguridad (IBS): solo aplica a perfiles Freelance
/// o Mixto. Usa el mínimo de los últimos 3 ciclos completos como
/// referencia presupuestal conservadora (en vez del ingreso promedio
/// o del ingreso más reciente, que pueden ser engañosos si el ingreso
/// es irregular).
class SafetyBaseIncomeService {
  final CycleService _cycleService = CycleService();
  final IncomeService _incomeService = IncomeService();

  Future<String?> _effectiveIncomeType() async {
    final incomes = await _incomeService.watchIncomes().first;
    final types = incomes.map((i) => i.type).toSet();
    if (types.isEmpty) return null;
    return types.length > 1 ? 'Mixto' : types.first;
  }

  /// Devuelve null si el perfil no es Freelance/Mixto, o si aún no
  /// hay 3 ciclos completos de historial (RQNF).
  Future<int?> computeSafetyBaseIncome() async {
    final profile = await _effectiveIncomeType();
    if (profile != 'Freelance' && profile != 'Mixto') return null;

    final hasEnough = await _cycleService.hasEnoughHistoricalCycles(3);
    if (!hasEnough) return null;

    final cycles = await _cycleService.getPreviousCycles(3);
    if (cycles.length < 3) return null;

    final incomes = <int>[];
    for (final cycle in cycles) {
      incomes.add(await _cycleService.totalIncomeAsOf(cycle.end));
    }

    return incomes.reduce((a, b) => a < b ? a : b);
  }
}