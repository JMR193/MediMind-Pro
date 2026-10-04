import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../data/services/circadian_travel_service.dart';
import '../../../domain/models/medication.dart';
import '../../core/apple_glass_decorations.dart';

class TravelDoseShifterScreen extends StatefulWidget {
  const TravelDoseShifterScreen({super.key});

  @override
  State<TravelDoseShifterScreen> createState() => _TravelDoseShifterScreenState();
}

class _TravelDoseShifterScreenState extends State<TravelDoseShifterScreen> {
  final _travelService = CircadianTravelService();

  GlobalTimeZone _origin = GlobalTimeZone.majorTimeZones[3]; // New York (EST, -5)
  GlobalTimeZone _destination = GlobalTimeZone.majorTimeZones[6]; // Paris (CET, +1)
  Medication? _selectedMedication;
  TimeOfDay _originTime = const TimeOfDay(hour: 8, minute: 0);
  final DateTime _departureDate = DateTime.now().add(const Duration(days: 1));
  CircadianTravelPlan? _activePlan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final meds = context.read<MedicationRepository>().activeMedications;
      if (meds.isNotEmpty) {
        setState(() {
          _selectedMedication = meds.first;
          if (meds.first.scheduledTimes.isNotEmpty) {
            final parts = meds.first.scheduledTimes.first.split(':');
            if (parts.length >= 2) {
              _originTime = TimeOfDay(
                hour: int.tryParse(parts[0]) ?? 8,
                minute: int.tryParse(parts[1]) ?? 0,
              );
            }
          }
        });
      }
      _recalculatePlan();
    });
  }

  void _recalculatePlan() {
    final timeStr = '${_originTime.hour.toString().padLeft(2, '0')}:${_originTime.minute.toString().padLeft(2, '0')}';
    final isNarrow = _selectedMedication != null
        ? CircadianTravelService.isStrictTimingMedication(_selectedMedication!)
        : false;

    setState(() {
      _activePlan = _travelService.calculateTravelPlan(
        origin: _origin,
        destination: _destination,
        originalTime: timeStr,
        departureDate: _departureDate,
        isNarrowTherapeutic: isNarrow,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MedicationRepository>();
    final meds = repo.activeMedications;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.flight_takeoff_rounded, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Travel Dose Shifter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderBanner(context),
            const SizedBox(height: 16),
            _buildItineraryCard(context),
            const SizedBox(height: 16),
            _buildMedicationSelectorCard(context, meds),
            const SizedBox(height: 20),
            if (_activePlan != null) ...[
              _buildCircadianSummaryCard(context, _activePlan!),
              const SizedBox(height: 20),
              _buildDosingStepsTimeline(context, _activePlan!),
              const SizedBox(height: 20),
              _buildTravelPrecautionsCard(context, _activePlan!),
              const SizedBox(height: 28),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.public_rounded, color: Colors.white, size: 36),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Jet-Lag Chrono-Bridge',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Prevents toxic drug accumulation and sub-therapeutic lapses when crossing international timezones.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryCard(BuildContext context) {
    final diff = _destination.utcOffsetHours - _origin.utcOffsetHours;
    final diffSign = diff >= 0 ? '+' : '';

    return AppleGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.airplane_ticket_outlined, color: Colors.blueAccent, size: 20),
                SizedBox(width: 8),
                Text('Flight Itinerary & Timezones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Origin Timezone', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<GlobalTimeZone>(
                        value: _origin,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: GlobalTimeZone.majorTimeZones.map((tz) {
                          return DropdownMenuItem(
                            value: tz,
                            child: Text('${tz.flagEmoji} ${tz.city}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _origin = val);
                            _recalculatePlan();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      const Icon(Icons.arrow_forward_rounded, color: Colors.blueAccent),
                      Text('$diffSign${diff.toStringAsFixed(1)}h', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueAccent)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Destination', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<GlobalTimeZone>(
                        value: _destination,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: GlobalTimeZone.majorTimeZones.map((tz) {
                          return DropdownMenuItem(
                            value: tz,
                            child: Text('${tz.flagEmoji} ${tz.city}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _destination = val);
                            _recalculatePlan();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationSelectorCard(BuildContext context, List<Medication> meds) {
    return AppleGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medication_liquid_outlined, color: Colors.purpleAccent, size: 20),
                SizedBox(width: 8),
                Text('Prescription & Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            if (meds.isNotEmpty) ...[
              DropdownButtonFormField<Medication>(
                value: _selectedMedication,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Select Medication',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: meds.map((m) {
                  final isStrict = CircadianTravelService.isStrictTimingMedication(m);
                  return DropdownMenuItem(
                    value: m,
                    child: Row(
                      children: [
                        Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (isStrict)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                            child: const Text('STRICT TIMING', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedMedication = val);
                    _recalculatePlan();
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time_rounded, color: Colors.blueAccent),
                    title: const Text('Original Dose Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(
                      _originTime.format(context),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _originTime);
                      if (picked != null) {
                        setState(() => _originTime = picked);
                        _recalculatePlan();
                      }
                    },
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final picked = await showTimePicker(context: context, initialTime: _originTime);
                    if (picked != null) {
                      setState(() => _originTime = picked);
                      _recalculatePlan();
                    }
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Change Time'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircadianSummaryCard(BuildContext context, CircadianTravelPlan plan) {
    final diff = plan.netTimeDifferenceHours;
    final isAhead = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: plan.isNarrowTherapeutic ? Colors.amber.withAlpha(25) : Colors.blue.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isNarrowTherapeutic ? Colors.amber : Colors.blueAccent.withAlpha(100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                plan.isNarrowTherapeutic ? Icons.warning_amber_rounded : Icons.sync_alt_rounded,
                color: plan.isNarrowTherapeutic ? Colors.amber[800] : Colors.blueAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${plan.recommendedTransitionDays}-Day Circadian Phase Shift',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: plan.isNarrowTherapeutic ? Colors.amber[900] : Colors.blueAccent,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAhead ? Colors.indigo : Colors.deepOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${isAhead ? '+' : ''}${diff.toStringAsFixed(1)}h Delta',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Traveling from ${plan.origin.city} (${plan.origin.region}) to ${plan.destination.city} (${plan.destination.region}) requires a ${diff.abs().toStringAsFixed(1)} hour circadian shift.',
            style: const TextStyle(fontSize: 13),
          ),
          if (plan.isNarrowTherapeutic) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.red, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Narrow Therapeutic Index: Rapid clock adjustment risks acute organ toxicity or breakthrough events.',
                      style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDosingStepsTimeline(BuildContext context, CircadianTravelPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Circadian Adaptation Regimen',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...plan.dosingSteps.map((step) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: step.isFinalDestination
                  ? Colors.green.withAlpha(25)
                  : step.isFlightDay
                      ? Colors.blue.withAlpha(25)
                      : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: step.isFinalDestination
                    ? Colors.green
                    : step.isFlightDay
                        ? Colors.blueAccent
                        : Colors.grey.withAlpha(50),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: step.isFinalDestination
                        ? Colors.green
                        : step.isFlightDay
                            ? Colors.blueAccent
                            : Colors.purple,
                    child: Text(
                      'D${step.dayNumber}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(step.dateLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                step.scheduledTime,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          step.clinicalInstruction,
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTravelPrecautionsCard(BuildContext context, CircadianTravelPlan plan) {
    return AppleGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_rounded, color: Colors.teal, size: 20),
                SizedBox(width: 8),
                Text('In-Flight & Airport Safety Guidelines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            ...plan.travelPrecautions.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(p, style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
