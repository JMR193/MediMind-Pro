import 'package:flutter/material.dart';
import '../../../domain/models/medication.dart';
import '../visuals_3d/realistic_3d_medicine_card.dart';

class SmartMedicineReminderDialog extends StatefulWidget {
  final Medication medication;
  final VoidCallback onTaken;
  final VoidCallback onSnooze;

  const SmartMedicineReminderDialog({
    super.key,
    required this.medication,
    required this.onTaken,
    required this.onSnooze,
  });

  static Future<void> show(
    BuildContext context, {
    required Medication medication,
    required VoidCallback onTaken,
    required VoidCallback onSnooze,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SmartMedicineReminderDialog(
        medication: medication,
        onTaken: onTaken,
        onSnooze: onSnooze,
      ),
    );
  }

  @override
  State<SmartMedicineReminderDialog> createState() =>
      _SmartMedicineReminderDialogState();
}

class _SmartMedicineReminderDialogState
    extends State<SmartMedicineReminderDialog> {
  bool _snooze15Min = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4F9F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Glowing Halo Bell Icon (Matching Image 3 Screen 2)
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFD4E09B),
                  const Color(0xFF99D98C).withOpacity(0.6),
                  const Color(0xFFF4F9F5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF99D98C).withOpacity(0.4),
                  blurRadius: 24,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.notifications_active_rounded,
                size: 42,
                color: Color(0xFF22593E),
              ),
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            "It's time for your Medicine",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4332),
            ),
          ),
          const SizedBox(height: 20),

          // White Medicine Card with 3D Thumbnail
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // 3D Visual Preview
                SizedBox(
                  width: 68,
                  height: 68,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Realistic3dMedicineCard(medication: widget.medication),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.medication.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.medication.strength} • 1 dose',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      // Instruction pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restaurant_rounded,
                                size: 12, color: Color(0xFFD97706)),
                            SizedBox(width: 4),
                            Text(
                              'Take with food',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contextual Clinical AI Tip Pill (Matching Image 3 Screen 2)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFD8F3DC).withOpacity(0.7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFB7E4C7)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, size: 16, color: Color(0xFF2D6A4F)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Tip: Taking this after your meal may help reduce stomach discomfort and optimizes gastrointestinal absorption.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2D6A4F),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Snooze Toggle (Matching Image 2 Screen 2)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Remind in 15 minutes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1B4332),
                ),
              ),
              Switch(
                value: _snooze15Min,
                activeColor: const Color(0xFF2D6A4F),
                onChanged: (v) => setState(() => _snooze15Min = v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Primary Button: Mark as Taken
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                if (_snooze15Min) {
                  widget.onSnooze();
                } else {
                  widget.onTaken();
                }
              },
              child: const Text(
                '✓ Mark as Taken',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Snooze Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2D6A4F),
                side: const BorderSide(color: Color(0xFFB7E4C7), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                widget.onSnooze();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.snooze_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('Snooze 15 min',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
