import 'package:flutter/material.dart';
import '../services/statistics_service.dart';
import '../services/cycle_service.dart';
import '../services/cycle_aggregate_service.dart';
import '../services/exponential_smoothing_service.dart';
import '../services/pareto_service.dart';
import '../services/tcm_service.dart';
import '../services/safety_base_income_service.dart';
import '../services/financial_mode_service.dart';
import '../services/reference_income_service.dart';
import '../services/firestore_service.dart';
import '../data/lessons_data.dart';
import '../data/onboarding_recommendations.dart';
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
  final ReferenceIncomeService _referenceIncomeService = ReferenceIncomeService();
  final FirestoreService _firestoreService = FirestoreService();

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
  ReferenceIncome? referenceIncome;

  /// Módulo 1: recomendación general de los primeros 14 días.
  OnboardingRecommendation? onboarding;
  int? onboardingDay;

  /// Módulo 9: lección y reto en texto plano cuando el gasto en Deseos
  /// supera el 30% del gasto total del ciclo.
  LessonModel? suggestedLesson;
  String? challengeSuggestion;

  RecommendationsController() {
    _load();
  }

  /// RQF: alerta cuando la proyección supera el ingreso disponible.
  bool get projectionExceedsIncome {
    final projection = smoothingResult?.projection;
    final income = referenceIncome?.amount;
    if (projection == null || income == null || income <= 0) return false;
    return projection > income;
  }

  Future<void> _loadOnboarding() async {
    onboarding = null;
    onboardingDay = null;

    final user = await _firestoreService.fetchCurrentUserProfile();
    final createdAt = user?.createdAt;
    if (createdAt == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final signupDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final daysSinceSignup = today.difference(signupDay).inDays;

    if (daysSinceSignup < 0 || daysSinceSignup >= onboardingDays) return;

    onboarding = buildOnboardingRecommendation(
      financialGoal: user?.diagnosis?['financialGoal'] as String?,
      savingHabit: user?.diagnosis?['savingHabit'] as String?,
    );
    if (onboarding != null) onboardingDay = daysSinceSignup + 1;
  }

  Future<void> _load() async {
    isLoading = true;
    notifyListeners();

    await _loadOnboarding();

    hasEnoughHistory = await _cycleService.hasEnoughHistoricalCycles(StatisticsService.requiredHistoricalCycles);
    financialMode = await _financialModeService.evaluate();
    referenceIncome = await _referenceIncomeService.compute();

    final currentCycle = await _cycleService.getCurrentCycle();
    currentCycleAggregate = currentCycle != null ? await _aggregateService.aggregateForCycle(currentCycle) : null;

    smoothingResult = await _smoothingService.computeProjection();
    safetyBaseIncome = await _safetyBaseIncomeService.computeSafetyBaseIncome();

    // RQF: en Contingencia se suspenden las comparaciones históricas.
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

    // RQF: lección 50/30/20 + reto cuando Deseos > 30% del gasto total.
    // RQF: en Modo de Estabilidad las alertas de la regla 50/30/20 se pausan.
    suggestedLesson = null;
    challengeSuggestion = null;
    final aggregate = currentCycleAggregate;
    final stabilityActive = financialMode!.isStabilityMode;
    if (!stabilityActive && aggregate != null && aggregate.totalSpent > 0) {
      final opcionalRatio = aggregate.cuboB / aggregate.totalSpent;
      if (opcionalRatio > 0.30) {
        suggestedLesson = allLessons.firstWhere((l) => l.id == 'regla-50-30-20');
        final topCategory = paretoResult?.priorityCategories.isNotEmpty == true
            ? paretoResult!.priorityCategories.first.category
            : null;
        challengeSuggestion = topCategory != null
            ? 'Esta semana, intenta reducir un poco tu gasto en $topCategory: es la categoría que más está pesando en tus Deseos.'
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