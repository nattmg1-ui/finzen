import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

enum DiagnosisQuestionType { singleSelect, multiSelect, numeric }

class DiagnosisController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  int currentIndex = 0;
  bool isSaving = false;
  String? errorMessage;

  static const int maxIncomeSourceSelections = 2;

  final TextEditingController monthlyIncomeController = TextEditingController();
  final TextEditingController monthlyExpensesController = TextEditingController();

  // key -> respuesta. Para 'numeric' se guarda un int. Para
  // 'singleSelect' un String. Para 'multiSelect' una List<String>.
  final Map<String, dynamic> answers = {};

  final List<Map<String, dynamic>> questions = [
    {
      'key': 'incomeSourceType',
      'question': '¿Cuál es tu tipo de fuente de ingresos? (elige hasta 2)',
      'type': DiagnosisQuestionType.multiSelect,
      'options': ['Empleado', 'Freelance', 'Negocio propio', 'Mixto', 'Mesada'],
    },
    {
      'key': 'monthlyIncome',
      'question': '¿Cuál es tu ingreso mensual promedio? (MXN)',
      'type': DiagnosisQuestionType.numeric,
    },
    {
      'key': 'monthlyBasicExpenses',
      'question': '¿Cuáles son tus gastos básicos mensuales? (MXN)',
      'type': DiagnosisQuestionType.numeric,
    },
    {
      'key': 'savingHabit',
      'question': '¿Cuál es tu hábito de ahorro?',
      'type': DiagnosisQuestionType.singleSelect,
      'options': ['Nunca', 'Ocasionalmente', 'Frecuentemente', 'Siempre'],
    },
    {
      'key': 'financialGoal',
      'question': '¿Cuál es tu objetivo financiero principal?',
      'type': DiagnosisQuestionType.singleSelect,
      'options': ['Ahorrar', 'Reducir gastos', 'Liquidar deudas', 'Cumplir objetivos'],
    },
  ];

  void setIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }

  void selectOption(String key, String option) {
    answers[key] = option;
    notifyListeners();
  }

  /// Marca/desmarca una opción en una pregunta de selección múltiple.
  /// Devuelve false si ya se alcanzó el máximo y se intentó agregar
  /// una nueva (para que la vista pueda avisar al usuario).
  bool toggleMultiSelectOption(String key, String option, {int maxSelections = maxIncomeSourceSelections}) {
    final current = (answers[key] as List<String>?) ?? <String>[];
    if (current.contains(option)) {
      current.remove(option);
      answers[key] = current;
      notifyListeners();
      return true;
    }
    if (current.length >= maxSelections) {
      return false; // límite alcanzado, la vista debe avisar
    }
    current.add(option);
    answers[key] = current;
    notifyListeners();
    return true;
  }

  bool validateCurrentQuestion() {
    final question = questions[currentIndex];
    final key = question['key'] as String;
    final type = question['type'] as DiagnosisQuestionType;

    switch (type) {
      case DiagnosisQuestionType.numeric:
        final controller = key == 'monthlyIncome' ? monthlyIncomeController : monthlyExpensesController;
        final text = controller.text.trim();
        final value = int.tryParse(text);
        if (value == null || value < 0) return false;
        answers[key] = value;
        return true;

      case DiagnosisQuestionType.multiSelect:
        final selected = answers[key] as List<String>?;
        return selected != null && selected.isNotEmpty;

      case DiagnosisQuestionType.singleSelect:
        return answers[key] != null;
    }
  }

  bool get isLastQuestion => currentIndex == questions.length - 1;

  Future<bool> saveDiagnosis() async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.saveDiagnosis(answers);
      isSaving = false;
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'No se pudo guardar tu diagnóstico. Revisa tu conexión e intenta de nuevo.';
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    monthlyIncomeController.dispose();
    monthlyExpensesController.dispose();
    super.dispose();
  }
}