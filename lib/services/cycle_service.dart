import '../models/cycle_info.dart';
import 'income_service.dart';

class CycleService {
  final IncomeService _incomeService = IncomeService();

  Future<String?> governingFrequency() async {
    final incomes = await _incomeService.fetchIncomesOnce();
    if (incomes.isEmpty) return null;
    final main = incomes.reduce((a, b) => a.amount >= b.amount ? a : b);
    return main.frequency;
  }

  /// Fecha ancla: la fecha (elegida por el usuario) MÁS ANTIGUA entre
  /// todos sus ingresos.
  Future<DateTime?> anchorDate() async {
    final incomes = await _incomeService.fetchIncomesOnce();
    if (incomes.isEmpty) return null;
    return incomes.map((i) => i.date).reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Suma de los ingresos cuya fecha ya pasó antes de `cutoff`.
  Future<int> totalIncomeAsOf(DateTime cutoff) async {
    final incomes = await _incomeService.fetchIncomesOnce();
    return incomes.where((i) => i.date.isBefore(cutoff)).fold<int>(0, (sum, i) => sum + i.amount);
  }

  int _cycleLengthDays(String frequency) {
    switch (frequency) {
      case 'Semanal':
        return 7;
      case 'Quincenal':
        return 15;
      case 'Mensual':
      default:
        return 30;
    }
  }

  DateTime _addCycles(DateTime date, String frequency, int n) {
    if (frequency == 'Mensual') {
      return DateTime(date.year, date.month + n, date.day);
    }
    return date.add(Duration(days: _cycleLengthDays(frequency) * n));
  }

  int _cyclesElapsed(DateTime anchor, DateTime today, String frequency) {
    var n = 0;
    while (!_addCycles(anchor, frequency, n + 1).isAfter(today)) {
      n++;
    }
    return n;
  }

  Future<CycleInfo?> getCurrentCycle() async {
    final frequency = await governingFrequency();
    final anchor = await anchorDate();
    if (frequency == null || anchor == null) return null;

    final today = DateTime.now();
    final n = _cyclesElapsed(anchor, today, frequency);
    final start = _addCycles(anchor, frequency, n);
    final end = _addCycles(anchor, frequency, n + 1);
    return CycleInfo(index: 0, start: start, end: end);
  }

  Future<List<CycleInfo>> getPreviousCycles(int count) async {
    final frequency = await governingFrequency();
    final anchor = await anchorDate();
    if (frequency == null || anchor == null) return [];

    final today = DateTime.now();
    final n = _cyclesElapsed(anchor, today, frequency);

    final cycles = <CycleInfo>[];
    for (var i = 1; i <= count; i++) {
      final cycleIndex = n - i;
      if (cycleIndex < 0) break;
      final start = _addCycles(anchor, frequency, cycleIndex);
      final end = _addCycles(anchor, frequency, cycleIndex + 1);
      cycles.add(CycleInfo(index: i, start: start, end: end));
    }
    return cycles;
  }

  Future<List<CycleInfo>> getAllPreviousCycles() async {
    final frequency = await governingFrequency();
    final anchor = await anchorDate();
    if (frequency == null || anchor == null) return [];

    final today = DateTime.now();
    final n = _cyclesElapsed(anchor, today, frequency);

    final cycles = <CycleInfo>[];
    for (var i = 1; i <= n; i++) {
      final cycleIndex = n - i;
      final start = _addCycles(anchor, frequency, cycleIndex);
      final end = _addCycles(anchor, frequency, cycleIndex + 1);
      cycles.add(CycleInfo(index: i, start: start, end: end));
    }
    return cycles;
  }

  Future<bool> hasEnoughHistoricalCycles(int required) async {
    final cycles = await getPreviousCycles(required);
    return cycles.length >= required;
  }
}