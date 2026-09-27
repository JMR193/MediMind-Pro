import 'package:flutter/material.dart';
import '../../../data/services/drug_food_interaction_ai.dart';
import '../../core/apple_glass_decorations.dart';

/// Interactive Drug-Food-Nutrient Interaction AI Radar.
///
/// Scans the patient's active cabinet for food/diet conflicts and provides
/// an interactive query console for evaluating any food or beverage.
class FoodInteractionRadarCard extends StatefulWidget {
  final List<String> activeMedicationNames;

  const FoodInteractionRadarCard({
    super.key,
    required this.activeMedicationNames,
  });

  @override
  State<FoodInteractionRadarCard> createState() => _FoodInteractionRadarCardState();
}

class _FoodInteractionRadarCardState extends State<FoodInteractionRadarCard> {
  final TextEditingController _queryController = TextEditingController();
  List<FoodInteractionAlert> _cabinetAlerts = [];
  List<FoodInteractionAlert> _queryAlerts = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _scanCabinet();
  }

  @override
  void didUpdateWidget(covariant FoodInteractionRadarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeMedicationNames != widget.activeMedicationNames) {
      _scanCabinet();
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _scanCabinet() {
    setState(() {
      _cabinetAlerts = DrugFoodInteractionAiService.scanCabinetForFoodInteractions(
        widget.activeMedicationNames,
      );
    });
  }

  void _runFoodQuery(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _hasSearched = false;
        _queryAlerts = [];
      });
      return;
    }

    AppleGlassDecorations.mediumHaptic();
    final results = DrugFoodInteractionAiService.checkFoodItemAgainstCabinet(
      queryFood: query,
      activeMedications: widget.activeMedicationNames,
    );

    setState(() {
      _hasSearched = true;
      _queryAlerts = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppleGlassDecorations.frostedGlassBox(
        color: Colors.white,
        opacity: 0.85,
        borderRadius: 20,
        borderColor: const Color(0xFFEA580C).withAlpha(50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Drug-Food-Nutrient AI Radar',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'CYP3A4, Chelation & Dietary Synergy Screening',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _cabinetAlerts.isEmpty
                      ? const Color(0xFF10B981).withAlpha(25)
                      : const Color(0xFFEA580C).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _cabinetAlerts.isEmpty
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEA580C),
                  ),
                ),
                child: Text(
                  _cabinetAlerts.isEmpty
                      ? 'ALL CLEAR'
                      : '${_cabinetAlerts.length} ADVISORIES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _cabinetAlerts.isEmpty
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEA580C),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Interactive Search Bar
          TextField(
            controller: _queryController,
            onSubmitted: _runFoodQuery,
            decoration: InputDecoration(
              hintText: 'Check a food, juice, or supplement (e.g. Milk, Grapefruit)...',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _queryController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _queryController.clear();
                        _runFoodQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Quick Query Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DrugFoodInteractionAiService.commonFoodQueryChips.map((chipText) {
                // Strip emoji for query
                final queryKey = chipText.replaceAll(RegExp(r'[^\w\s]'), '').trim();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(chipText, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    onPressed: () {
                      _queryController.text = queryKey;
                      _runFoodQuery(queryKey);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Query Search Results (if searched)
          if (_hasSearched) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _queryAlerts.isEmpty
                    ? const Color(0xFF10B981).withAlpha(15)
                    : const Color(0xFFEA580C).withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _queryAlerts.isEmpty
                      ? const Color(0xFF10B981).withAlpha(80)
                      : const Color(0xFFEA580C).withAlpha(80),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _queryAlerts.isEmpty
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        size: 18,
                        color: _queryAlerts.isEmpty
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEA580C),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _queryAlerts.isEmpty
                            ? 'No known interactions detected for "${_queryController.text}"'
                            : 'Potential Conflict Detected!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _queryAlerts.isEmpty
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                  if (_queryAlerts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._queryAlerts.map((a) => _buildAlertCard(a)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Active Cabinet Ongoing Alerts
          Text(
            'Active Cabinet Dietary Rules (${_cabinetAlerts.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),

          if (_cabinetAlerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No high-risk food-drug interactions detected across your active prescriptions.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF065F46)),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._cabinetAlerts.map((alert) => _buildAlertCard(alert)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(FoodInteractionAlert alert) {
    final severityColor = _getSeverityColor(alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: severityColor.withAlpha(70)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getSeverityLabel(alert.severity),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              if (alert.rule.requiredSpacingHours > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${alert.rule.requiredSpacingHours}h buffer',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Mechanism text
          Text(
            alert.mechanismText,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
          ),

          const SizedBox(height: 6),

          // Instruction Callout
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: severityColor.withAlpha(12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.directions_run_rounded, size: 14, color: severityColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alert.instructions,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: severityColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return const Color(0xFFDC2626); // Strong Red
      case InteractionSeverity.major:
        return const Color(0xFFEA580C); // Vibrant Orange
      case InteractionSeverity.moderate:
        return const Color(0xFFD97706); // Amber
      case InteractionSeverity.minor:
        return const Color(0xFF0284C7); // Blue
    }
  }

  String _getSeverityLabel(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return 'CONTRAINDICATED';
      case InteractionSeverity.major:
        return 'MAJOR RISK';
      case InteractionSeverity.moderate:
        return 'MODERATE';
      case InteractionSeverity.minor:
        return 'INFORMATIONAL';
    }
  }
}
