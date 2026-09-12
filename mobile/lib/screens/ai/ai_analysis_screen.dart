import 'package:flutter/material.dart';

class AIAnalysisScreen extends StatelessWidget {
  const AIAnalysisScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14), // Dark tactical navy
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Analysis',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Simulated pulsing sensor indicator
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4), // Cyan active
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Multi-Modal Hazard Verification in Progress',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            
            // Checklist
            _buildChecklistItem('Image detected', 'Completed • Computer Vision Model v4.2', true),
            _buildChecklistItem('Hazard classified', 'Completed • Flood detected', true),
            _buildChecklistItem('Severity calculated', 'Completed • Severity: HIGH', true),
            _buildChecklistItem('Hydrological Sensor Cross-Check', 'Active scanning • River Gauge Ward 03', false, isActive: true),
            
            const Spacer(),
            
            // Telemetry Output Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                border: Border.all(color: const Color(0xFF1E293B)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'LIVE TELEMETRY STREAM',
                    style: TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  SizedBox(height: 12),
                  Text('[09:41:02] Image uploaded: 3.2MB JPG', style: TextStyle(color: Colors.white60, fontFamily: 'monospace')),
                  Text('[09:41:04] Water surface segment detected (Area: 68.4%)', style: TextStyle(color: Colors.white60, fontFamily: 'monospace')),
                  Text('[09:41:06] Incident classified as FLOOD (Confidence: 94.2%)', style: TextStyle(color: Colors.white60, fontFamily: 'monospace')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4), // Cyan primary
                ),
                onPressed: () {
                  // Navigate to result screen in real app
                },
                child: const Text('VIEW RESULT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String title, String subtitle, bool isCompleted, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : (isActive ? Icons.sync : Icons.radio_button_unchecked),
            color: isCompleted ? const Color(0xFF10B981) : (isActive ? const Color(0xFF06B6D4) : Colors.white30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isCompleted || isActive ? Colors.white : Colors.white60,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
