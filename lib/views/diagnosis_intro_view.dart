import 'package:flutter/material.dart';
import 'diagnosis_view.dart'; 

class DiagnosisIntroView extends StatelessWidget {
  const DiagnosisIntroView({super.key}); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, 
        title: const Text('FinZen', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: const Color(0xFFF6C97F), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF8B5E34), size: 40),
              ),
              const SizedBox(height: 32),
              
              const Text(
                '¡Te damos la bienvenida!', 
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Antes de empezar, queremos conocer tu situación financiera para darte recomendaciones a tu medida.',
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFF8F6F2), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.assignment_outlined, color: Color(0xFF8B5E34)),
                        SizedBox(width: 12),
                        Text('5 preguntas rápidas', style: TextStyle(fontSize: 16, color: Color(0xFF475569))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Icon(Icons.access_time, color: Color(0xFF8B5E34)),
                        SizedBox(width: 12),
                        Text('Te toma unos 2 minutos', style: TextStyle(fontSize: 16, color: Color(0xFF475569))),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE89A3C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const DiagnosisView()));
                  },
                  child: const Text('Comenzar diagnóstico', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}