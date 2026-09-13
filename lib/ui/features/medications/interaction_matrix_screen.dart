import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../data/services/interaction_service.dart';
import '../../core/one_ui_widgets.dart';
import '../../core/theme.dart';

class InteractionMatrixScreen extends StatefulWidget {
  const InteractionMatrixScreen({super.key});

  @override
  State<InteractionMatrixScreen> createState() => _InteractionMatrixScreenState();
}

class _InteractionMatrixScreenState extends State<InteractionMatrixScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InteractionService _interactionService = InteractionService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Interaction Matrix'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.compare_arrows_rounded), text: 'Drug-Drug'),
            Tab(icon: Icon(Icons.restaurant_rounded), text: 'Food & Drink'),
            Tab(icon: Icon(Icons.healing_rounded), text: 'Conditions'),
          ],
        ),
      ),
      body: Consumer<MedicationRepository>(
        builder: (context, repo, _) {
          final meds = repo.medications;
          final profile = repo.userProfile;

          final drugWarnings = _interactionService.checkInteractions(
            existingMedications: meds,
            newDrafts: const [],
          );

          final foodWarnings = _interactionService.checkFoodInteractions(meds);

          final conditionWarnings = _interactionService.checkConditionContraindications(
            meds,
            profile?.medicalConditions,
          );

          final totalCritical = drugWarnings.where((w) => w.severity == InteractionSeverity.critical).length +
              foodWarnings.where((w) => w.severity == InteractionSeverity.critical).length +
              conditionWarnings.where((w) => w.severity == InteractionSeverity.critical).length;

          return Column(
            children: [
              // Top Safety Shield Banner
              _buildSafetyShieldBanner(context, totalCritical, drugWarnings.length + foodWarnings.length + conditionWarnings.length),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDrugInteractionsTab(context, drugWarnings),
                    _buildFoodInteractionsTab(context, foodWarnings),
                    _buildConditionContraindicationsTab(context, conditionWarnings, profile?.medicalConditions),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSafetyShieldBanner(BuildContext context, int criticalCount, int totalCount) {
    final isClear = totalCount == 0;
    final color = isClear
        ? MediMindTheme.successGreen
        : criticalCount > 0
            ? MediMindTheme.alertRed
            : MediMindTheme.warningOrange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: color.withAlpha(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
            child: Icon(
              isClear ? Icons.verified_user_rounded : Icons.shield_outlined,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isClear ? 'All Prescriptions Clinically Cleared' : '$totalCount Safety Precautions Detected ($criticalCount Critical)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  isClear
                      ? 'No known drug-drug, dietary, or disease contraindications found.'
                      : 'Review the clinical recommendations below with your physician.',
                  style: TextStyle(fontSize: 11, color: color.withAlpha(220)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrugInteractionsTab(BuildContext context, List<DrugInteractionWarning> warnings) {
    if (warnings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Zero Drug-Drug Conflicts',
        subtitle: 'None of your active medications have dangerous pharmacology conflicts.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: warnings.length,
      itemBuilder: (context, i) {
        final w = warnings[i];
        final color = w.severity == InteractionSeverity.critical
            ? MediMindTheme.alertRed
            : w.severity == InteractionSeverity.moderate
                ? MediMindTheme.warningOrange
                : MediMindTheme.primaryBlue;

        return OneUiWidgets.squircleCard(
          context: context,
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      w.severity.name.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      w.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${w.drugA.toUpperCase()} ↔ ${w.drugB.toUpperCase()}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 6),
              Text(w.description, style: const TextStyle(fontSize: 13, height: 1.35)),
              const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medical_information_outlined, size: 16, color: MediMindTheme.accentTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Clinical Recommendation: ${w.clinicalRecommendation}',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: MediMindTheme.accentTeal),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoodInteractionsTab(BuildContext context, List<FoodInteractionWarning> warnings) {
    if (warnings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.no_food_outlined,
        title: 'No Food Conflicts Detected',
        subtitle: 'Your active prescriptions do not have dietary or beverage restrictions.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: warnings.length,
      itemBuilder: (context, i) {
        final w = warnings[i];
        final color = w.severity == InteractionSeverity.critical
            ? MediMindTheme.alertRed
            : MediMindTheme.warningOrange;

        return OneUiWidgets.squircleCard(
          context: context,
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      w.severity.name.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      w.foodItem,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Affects: ${w.medicationName}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 6),
              Text(w.description, style: const TextStyle(fontSize: 13, height: 1.35)),
              const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.restaurant_menu_rounded, size: 16, color: MediMindTheme.accentTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      w.clinicalRecommendation,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: MediMindTheme.accentTeal),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConditionContraindicationsTab(
    BuildContext context,
    List<ConditionContraindicationWarning> warnings,
    String? patientConditions,
  ) {
    if (patientConditions == null || patientConditions.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_search_outlined, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No Medical Conditions Recorded', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Add your chronic conditions (e.g. Asthma, Glaucoma, Hypertension) in your Patient Profile to enable real-time contraindication guarding.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Profile'),
              ),
            ],
          ),
        ),
      );
    }

    if (warnings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.health_and_safety_outlined,
        title: 'Zero Condition Contraindications',
        subtitle: 'None of your active medications conflict with your recorded health conditions ($patientConditions).',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: warnings.length,
      itemBuilder: (context, i) {
        final w = warnings[i];
        final color = w.severity == InteractionSeverity.critical
            ? MediMindTheme.alertRed
            : MediMindTheme.warningOrange;

        return OneUiWidgets.squircleCard(
          context: context,
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      'CONTRAINDICATION',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      w.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Condition: ${w.condition.toUpperCase()} ↔ Drug: ${w.medicationName}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 6),
              Text(w.description, style: const TextStyle(fontSize: 13, height: 1.35)),
              const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.local_hospital_outlined, size: 16, color: MediMindTheme.alertRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      w.clinicalRecommendation,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: MediMindTheme.alertRed),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: MediMindTheme.successGreen),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
