/// Representa un ciclo (unidad de tiempo base del Módulo 8): un rango
/// [start, end) donde `end` es exclusivo (el ciclo termina justo
/// antes de esa fecha).
///
/// index = 0 es el ciclo ACTUAL (el que está en curso ahora mismo).
/// index = 1 es el ciclo completo inmediatamente anterior, index = 2
/// el que le sigue hacia atrás, etc.
class CycleInfo {
  final int index;
  final DateTime start;
  final DateTime end;

  CycleInfo({required this.index, required this.start, required this.end});

  bool contains(DateTime date) {
    return !date.isBefore(start) && date.isBefore(end);
  }

  bool get isCurrent => index == 0;
}