import 'package:flutter/material.dart';
import '../services/statistics_service.dart';
import '../services/cycle_service.dart';
import '../services/cycle_aggregate_service.dart';
import '../services/exponential_smoothing_service.dart';
import '../services/pareto_service.dart';
import '../services/tcm_service.dart';
import '../services/safety_base_income_service.dart';
import '../services/financial_mode_service.dart';
import '../data/lessons_data.dart';
import '../models/lesson_model.dart';

class RecommendationsController extends ChangeNotifier {
  final StatisticsService _statsService = StatisticsService();
  final CycleService _cycleService = CycleService();
  final CycleAggregateService _aggregateService = CycleAggregateService();
  final ExponentialSmoothingService _smoothingService = ExponentialSmoothingService();
  final ParetoService _paretoService = ParetoService();
  final TcmService _tcmService = TcmService();
  final SafetyBaseIncomeService _safetyBaseIncomeService = SafetyBaseIncomeService();
  final FinancialModeService _financialModeService = FinancialModeService();

  bool isLoading = true;
  bool hasEnoughHistory = false;

  CycleAggregate? currentCycleAggregate;
  List<CategoryWmaResult>? wmaResults;
  List<CategoryCvResult>? cvResults;
  ExponentialSmoothingResult? smoothingResult;
  ParetoResult? paretoResult;
  TcmResult? tcmResult;
  int? safetyBaseIncome;
  FinancialModeResult? financialMode;

  /// Módulo 9: lección sugerida y "reto" en texto plano cuando el
  /// gasto en Deseos supera el 30% (regla 50/30/20). Sin botón de
  /// completar ni seguimiento — no es gamificación, solo un aviso.
  LessonModel? suggestedLesson;
  String? challengeSuggestion;

  RecommendationsController() {
    _load();
  }

  Future<void> _load() async {
    isLoading = true;
    notifyListeners();

    hasEnoughHistory = await _cycleService.hasEnoughHistoricalCycles(StatisticsService.requiredHistoricalCycles);
    financialMode = await _financialModeService.evaluate();

    final currentCycle = await _cycleService.getCurrentCycle();
    if (currentCycle != null) {
      currentCycleAggregate = await _aggregateService.aggregateForCycle(currentCycle);
    }

    smoothingResult = await _smoothingService.computeProjection();
    safetyBaseIncome = await _safetyBaseIncomeService.computeSafetyBaseIncome();

    // RQF: en modo de contingencia se suspenden las comparaciones
    // históricas (WMA, CV, Pareto) y se prioriza la recomendación de
    // reducir gastos esenciales en su lugar.
    if (financialMode!.isContingencyMode) {
      wmaResults = null;
      cvResults = null;
      paretoResult = null;
      tcmResult = null;
    } else {
      wmaResults = await _statsService.computeWmaAnomalies();
      cvResults = await _statsService.computeCoefficientOfVariation();
      paretoResult = await _paretoService.computeParetoForCurrentCycle();
      tcmResult = await _tcmService.computeTcm();
    }

    // RQF: sugiere una lección específica cuando el gasto en Deseos
    // supera el 30% (regla 50/30/20), y agrega un "reto" en texto
    // plano, sin botón de completar ni seguimiento (RQNF: sin
    // gamificación).
    suggestedLesson = null;
    challengeSuggestion = null;
    final aggregate = currentCycleAggregate;
    if (aggregate != null && aggregate.totalSpent > 0) {
      final opcionalRatio = aggregate.cuboB / aggregate.totalSpent;
      if (opcionalRatio > 0.30) {
        suggestedLesson = allLessons.firstWhere((l) => l.id == 'regla-50-30-20');
        final topCategory = paretoResult?.categories.isNotEmpty == true ? paretoResult!.categories.first.category : null;
        challengeSuggestion = topCategory != null
            ? 'Esta semana, intenta reducir un poco tu gasto en $topCategory — es la categoría que más está pesando en tus Deseos.'
            : 'Tu gasto en Deseos superó el 30% recomendado por la regla 50/30/20. Vale la pena revisar en qué se está yendo.';
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => _load();

  List<CategoryWmaResult> get anomalies => (wmaResults ?? []).where((r) => r.isAnomaly).toList();
  List<CategoryCvResult> get impulsiveCategories => (cvResults ?? []).where((r) => r.isImpulsive).toList();
}