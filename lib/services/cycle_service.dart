import '../models/cycle_info.dart';
import '../models/income_model.dart';
import 'income_service.dart';

/// Línea de tiempo de ciclos de un usuario: el ciclo actual y todos los
/// ciclos completos anteriores (del más reciente al más antiguo).
class _CycleTimeline {
  final CycleInfo current;
  final List<CycleInfo> previous;

  _CycleTimeline(this.current, this.previous);
}

/// Calcula los ciclos del Módulo 8 según el perfil del usuario:
/// - RQF3: Empleado o Mesada -> ciclo por la frecuencia declarada
///   (semanal, quincenal o mensual), anclado a la fecha del primer ingreso.
/// - RQF4: Freelance, Negocio propio o Mixto -> mes calendario
///   (del día 1 al último día de cada mes).
class CycleService {
  final IncomeService _incomeService = IncomeService();

  static const Set<String> _frequencyBasedProfiles = {'Empleado', 'Mesada'};

  Future<List<IncomeModel>> _loadIncomes() => _incomeService.fetchIncomesOnce();

  /// Perfil efectivo según los ingresos REGISTRADOS: si hay más de un
  /// tipo distinto, el perfil es Mixto.
  String? _profileFrom(List<IncomeModel> incomes) {
    final types = incomes.map((i) => i.type).toSet();
    if (types.isEmpty) return null;
    return types.length > 1 ? 'Mixto' : types.first;
  }

  Future<String?> effectiveProfile() async => _profileFrom(await _loadIncomes());

  bool usesCalendarMonth(String profile) => !_frequencyBasedProfiles.contains(profile);

  /// Frecuencia de la fuente de ingreso principal (la de mayor monto).
  String _governingFrequency(List<IncomeModel> incomes) {
    final main = incomes.reduce((a, b) => a.amount >= b.amount ? a : b);
    return main.frequency;
  }

  /// Fecha ancla: la fecha más antigua entre todos los ingresos.
  DateTime _anchorDate(List<IncomeModel> incomes) {
    return incomes.map((i) => i.date).reduce((a, b) => a.isBefore(b) ? a : b);
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

  _CycleTimeline? _buildTimeline(List<IncomeModel> incomes) {
    if (incomes.isEmpty) return null;

    final profile = _profileFrom(incomes)!;
    final anchor = _anchorDate(incomes);
    final today = DateTime.now();

    // RQF4: mes calendario.
    if (usesCalendarMonth(profile)) {
      final firstMonth = DateTime(anchor.year, anchor.month, 1);
      final elapsed = (today.year - firstMonth.year) * 12 + (today.month - firstMonth.month);
      DateTime monthStart(int offset) => DateTime(firstMonth.year, firstMonth.month + offset, 1);

      final current = CycleInfo(index: 0, start: monthStart(elapsed), end: monthStart(elapsed + 1));
      final previous = <CycleInfo>[
        for (var i = 1; i <= elapsed; i++)
          CycleInfo(index: i, start: monthStart(elapsed - i), end: monthStart(elapsed - i + 1)),
      ];
      return _CycleTimeline(current, previous);
    }

    // RQF3: frecuencia declarada.
    final frequency = _governingFrequency(incomes);
    final n = _cyclesElapsed(anchor, today, frequency);

    final current = CycleInfo(
      index: 0,
      start: _addCycles(anchor, frequency, n),
      end: _addCycles(anchor, frequency, n + 1),
    );
    final previous = <CycleInfo>[
      for (var i = 1; i <= n; i++)
        CycleInfo(
          index: i,
          start: _addCycles(anchor, frequency, n - i),
          end: _addCycles(anchor, frequency, n - i + 1),
        ),
    ];
    return _CycleTimeline(current, previous);
  }

  Future<CycleInfo?> getCurrentCycle() async {
    return _buildTimeline(await _loadIncomes())?.current;
  }

  /// Hasta `count` ciclos completos anteriores, del más reciente al más antiguo.
  Future<List<CycleInfo>> getPreviousCycles(int count) async {
    final timeline = _buildTimeline(await _loadIncomes());
    if (timeline == null) return [];
    return timeline.previous.take(count).toList();
  }

  /// Todos los ciclos completos anteriores (lo usa el Suavizamiento Exponencial).
  Future<List<CycleInfo>> getAllPreviousCycles() async {
    return _buildTimeline(await _loadIncomes())?.previous ?? [];
  }

  Future<bool> hasEnoughHistoricalCycles(int required) async {
    final cycles = await getPreviousCycles(required);
    return cycles.length >= required;
  }

  /// Ingreso registrado DENTRO del ciclo (suma de los ingresos cuya
  /// fecha cae en ese ciclo). Lo usan TCM, Ingreso Base de Seguridad y
  /// los modos de Contingencia y Estabilidad.
  Future<int> incomeInCycle(CycleInfo cycle) async {
    final incomes = await _loadIncomes();
    return incomes.where((i) => cycle.contains(i.date)).fold<int>(0, (sum, i) => sum + i.amount);
  }
}