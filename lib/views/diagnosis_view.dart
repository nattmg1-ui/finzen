import 'package:flutter/material.dart';
import '../controllers/diagnosis_controller.dart';
import 'dashboard_view.dart';

class DiagnosisView extends StatefulWidget {
  const DiagnosisView({super.key});

  @override
  State<DiagnosisView> createState() => _DiagnosisViewState();
}

class _DiagnosisViewState extends State<DiagnosisView> {
  final DiagnosisController _controller = DiagnosisController();
  final PageController _pageController = PageController();

  Future<void> _handleNext() async {
    if (!_controller.validateCurrentQuestion()) {
      final question = _controller.questions[_controller.currentIndex];
      final type = question['type'] as DiagnosisQuestionType;
      String message = 'Por favor, selecciona una opción para continuar';
      if (type == DiagnosisQuestionType.numeric) {
        message = 'Ingresa un monto numérico válido (0 o mayor)';
      } else if (type == DiagnosisQuestionType.multiSelect) {
        message = 'Selecciona al menos una opción para continuar';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    if (!_controller.isLastQuestion) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      return;
    }

    final success = await _controller.saveDiagnosis();
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.errorMessage ?? 'Error al guardar')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardView()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSingleSelectQuestion(Map<String, dynamic> question) {
    final key = question['key'] as String;
    final options = question['options'] as List<String>;

    return ListView.builder(
      itemCount: options.length,
      itemBuilder: (context, optionIndex) {
        final option = options[optionIndex];
        final isSelected = _controller.answers[key] == option;

        return GestureDetector(
          onTap: () => _controller.selectOption(key, option),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE89A3C).withOpacity(0.1) : Colors.white,
              border: Border.all(color: isSelected ? const Color(0xFFE89A3C) : Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFFE89A3C) : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFE89A3C)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMultiSelectQuestion(Map<String, dynamic> question) {
    final key = question['key'] as String;
    final options = question['options'] as List<String>;
    final selected = (_controller.answers[key] as List<String>?) ?? <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${selected.length}/${DiagnosisController.maxIncomeSourceSelections} seleccionadas',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, optionIndex) {
              final option = options[optionIndex];
              final isSelected = selected.contains(option);

              return GestureDetector(
                onTap: () {
                  final ok = _controller.toggleMultiSelectOption(key, option);
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Solo puedes elegir hasta ${DiagnosisController.maxIncomeSourceSelections} opciones. Desmarca una para elegir otra.')),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE89A3C).withOpacity(0.1) : Colors.white,
                    border: Border.all(color: isSelected ? const Color(0xFFE89A3C) : Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFFE89A3C) : Colors.black87,
                          ),
                        ),
                      ),
                      if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFE89A3C)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNumericQuestion(Map<String, dynamic> question) {
    final key = question['key'] as String;
    final controller = key == 'monthlyIncome'
        ? _controller.monthlyIncomeController
        : _controller.monthlyExpensesController;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          prefixText: '\$ ',
          prefixStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
          hintText: '0',
          suffixText: 'MXN',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () {
                if (_controller.currentIndex > 0) {
                  _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: Text(
              'Pregunta ${_controller.currentIndex + 1} de ${_controller.questions.length}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: LinearProgressIndicator(
                    value: (_controller.currentIndex + 1) / _controller.questions.length,
                    backgroundColor: Colors.grey.shade300,
                    color: const Color(0xFFE89A3C),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: _controller.setIndex,
                    itemCount: _controller.questions.length,
                    itemBuilder: (context, index) {
                      final question = _controller.questions[index];
                      final type = question['type'] as DiagnosisQuestionType;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              question['question'] as String,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 24),
                            if (type == DiagnosisQuestionType.numeric)
                              _buildNumericQuestion(question)
                            else if (type == DiagnosisQuestionType.multiSelect)
                              Expanded(child: _buildMultiSelectQuestion(question))
                            else
                              Expanded(child: _buildSingleSelectQuestion(question)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE89A3C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _controller.isSaving ? null : _handleNext,
                      child: _controller.isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _controller.isLastQuestion ? 'Finalizar' : 'Continuar',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}