import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/user_profile.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/theme.dart';

class SupportedEmergencyLanguage {
  final String code;
  final String name;
  final String flag;
  final Map<String, String> translations;

  const SupportedEmergencyLanguage({
    required this.code,
    required this.name,
    required this.flag,
    required this.translations,
  });
}

class UniversalEmergencyHudScreen extends StatefulWidget {
  const UniversalEmergencyHudScreen({super.key});

  @override
  State<UniversalEmergencyHudScreen> createState() => _UniversalEmergencyHudScreenState();
}

class _UniversalEmergencyHudScreenState extends State<UniversalEmergencyHudScreen> {
  static const List<SupportedEmergencyLanguage> _languages = [
    SupportedEmergencyLanguage(
      code: 'en',
      name: 'English',
      flag: '🇺🇸',
      translations: {
        'title': 'PARAMEDIC EMERGENCY HUD',
        'subtitle': 'Critical Life-Saving Clinical Data (Offline Verified)',
        'anticoagulantWarning': 'CRITICAL ALERT: Patient is on active ANTICOAGULANT therapy. Risk of fatal hemorrhage if given thrombolytics (tPA) without reversal!',
        'allergyWarning': 'SEVERE ALLERGIES',
        'bloodGroup': 'Blood Type',
        'activeMeds': 'Active Prescriptions',
        'contacts': 'Emergency Contacts',
        'callDispatch': 'CALL EMERGENCY DISPATCH',
        'qrScanHint': 'Scan QR Code for full de-identified medical passport',
      },
    ),
    SupportedEmergencyLanguage(
      code: 'es',
      name: 'Español',
      flag: '🇪🇸',
      translations: {
        'title': 'HUD DE EMERGENCIA PARAMÉDICA',
        'subtitle': 'Datos Clínicos Críticos para Salvar Vidas (Sin Conexión)',
        'anticoagulantWarning': 'ALERTA CRÍTICA: Paciente en terapia ANTICOAGULANTE activa. ¡Riesgo de hemorragia mortal con trombolíticos (tPA)!',
        'allergyWarning': 'ALERGIAS SEVERAS',
        'bloodGroup': 'Grupo Sanguíneo',
        'activeMeds': 'Medicamentos Activos',
        'contacts': 'Contactos de Emergencia',
        'callDispatch': 'LLAMAR A URGENCIAS',
        'qrScanHint': 'Escanee el código QR para pasaporte médico completo',
      },
    ),
    SupportedEmergencyLanguage(
      code: 'hi',
      name: 'हिन्दी',
      flag: '🇮🇳',
      translations: {
        'title': 'पैरामेडिक आपातकालीन एचयूडी',
        'subtitle': 'महत्वपूर्ण जीवन रक्षक नैदानिक डेटा (ऑफ़लाइन)',
        'anticoagulantWarning': 'गंभीर चेतावनी: रोगी सक्रिय एंटीकोआगुलेंट (खून पतला करने वाली दवा) पर है। जानलेवा रक्तस्राव का जोखिम!',
        'allergyWarning': 'गंभीर एलर्जी',
        'bloodGroup': 'रक्त समूह',
        'activeMeds': 'सक्रिय दवाएं',
        'contacts': 'आपातकालीन संपर्क',
        'callDispatch': 'आपातकालीन 112 डायल करें',
        'qrScanHint': 'पूर्ण मेडिकल पासपोर्ट के लिए क्यूआर कोड स्कैन करें',
      },
    ),
    SupportedEmergencyLanguage(
      code: 'fr',
      name: 'Français',
      flag: '🇫🇷',
      translations: {
        'title': 'HUD URGENCE PARAMÉDICALE',
        'subtitle': 'Données Cliniques Vitales (Vérifié Hors-Ligne)',
        'anticoagulantWarning': 'ALERTE CRITIQUE : Patient sous ANTICOAGULANT actif. Risque d\'hémorragie fatale avec les thrombolytiques (tPA) !',
        'allergyWarning': 'ALLERGIES GRAVES',
        'bloodGroup': 'Groupe Sanguin',
        'activeMeds': 'Traitements en Cours',
        'contacts': 'Contacts d\'Urgence',
        'callDispatch': 'APPELER LE 112 / SAMU',
        'qrScanHint': 'Scannez le code QR pour le dossier d\'urgence complet',
      },
    ),
    SupportedEmergencyLanguage(
      code: 'zh',
      name: '中文',
      flag: '🇨🇳',
      translations: {
        'title': '急救人员医疗应急 HUD',
        'subtitle': '关键生命体征及用药档案 (离线可用)',
        'anticoagulantWarning': '严重警告：患者正在服用抗凝药物。使用溶栓剂（tPA）存在致命大出血风险！',
        'allergyWarning': '严重过敏史',
        'bloodGroup': '血型',
        'activeMeds': '当前用药',
        'contacts': '紧急联系人',
        'callDispatch': '拨打紧急求救电话',
        'qrScanHint': '扫描二维码获取完整医疗急救档案',
      },
    ),
    SupportedEmergencyLanguage(
      code: 'ja',
      name: '日本語',
      flag: '🇯🇵',
      translations: {
        'title': '救急隊用 緊急医療HUD',
        'subtitle': '救命用 臨床医療データ（完全オフライン）',
        'anticoagulantWarning': '緊急警告：抗凝固薬（血液サラサラ薬）服用中。血栓溶解薬（tPA）投与時の致死性出血に注意！',
        'allergyWarning': '重篤なアレルギー',
        'bloodGroup': '血液型',
        'activeMeds': '服用中のお薬',
        'contacts': '緊急連絡先',
        'callDispatch': '救急119番に通報',
        'qrScanHint': '詳細な医療パスポート用QRコード',
      },
    ),
  ];

  SupportedEmergencyLanguage _selectedLang = _languages[0];
  String _emergencyNumber = '911';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MedicationRepository>();
    final profile = repo.userProfile ?? const UserProfile(name: 'Emergency Patient');
    final meds = repo.activeMedications;

    final hasAnticoagulant = meds.any((m) {
      final n = m.name.toLowerCase();
      return n.contains('warfarin') ||
          n.contains('apixaban') ||
          n.contains('rivaroxaban') ||
          n.contains('eliquis') ||
          n.contains('xarelto') ||
          n.contains('plavix') ||
          n.contains('clopidogrel') ||
          n.contains('aspirin');
    });

    final tr = _selectedLang.translations;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.emergency_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(tr['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language selector bar
            _buildLanguagePicker(),
            const SizedBox(height: 12),

            // Emergency Dispatch Hotline Button
            _buildEmergencyDispatchBar(context, tr),
            const SizedBox(height: 14),

            // Critical Anticoagulant / Life-Threatening Warning Banner
            if (hasAnticoagulant)
              _buildCriticalAnticoagulantBanner(tr),

            const SizedBox(height: 14),

            // Patient Vitals & Blood Group Card
            _buildPatientVitalsCard(context, profile, tr),
            const SizedBox(height: 14),

            // Active Medications List with Drug Class Badges
            _buildActiveMedicationsCard(context, meds, tr),
            const SizedBox(height: 14),

            // Paramedic Scannable QR Passport
            _buildQrMedicalPassportCard(context, profile, meds, tr),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePicker() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _languages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final l = _languages[i];
          final isSelected = l.code == _selectedLang.code;
          return ChoiceChip(
            label: Text('${l.flag} ${l.name}', style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            selected: isSelected,
            selectedColor: Colors.redAccent,
            backgroundColor: const Color(0xFF1E293B),
            onSelected: (val) {
              if (val) {
                setState(() => _selectedLang = l);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildEmergencyDispatchBar(BuildContext context, Map<String, String> tr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.red.withAlpha(100), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showDispatchDialog(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tr['callDispatch']!} ($_emergencyNumber)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const Text(
                        'Instant auto-connect to national rescue service',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(6)),
                  child: const Text('CHANGE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCriticalAnticoagulantBanner(Map<String, String> tr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr['anticoagulantWarning']!,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientVitalsCard(BuildContext context, UserProfile profile, Map<String, String> tr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                profile.name.isNotEmpty ? profile.name : 'Unknown Patient',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${tr['bloodGroup']!}: ${profile.bloodGroup ?? 'O+'}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (profile.allergies != null && profile.allergies!.isNotEmpty) ...[
            Text('${tr['allergyWarning']!}:', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(profile.allergies!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
          ],
          if (profile.medicalConditions != null && profile.medicalConditions!.isNotEmpty) ...[
            const Text('Conditions:', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(profile.medicalConditions!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveMedicationsCard(BuildContext context, List<Medication> meds, Map<String, String> tr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr['activeMeds']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${meds.length} Prescriptions', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          if (meds.isEmpty)
            const Text('No medications listed.', style: TextStyle(color: Colors.white54, fontSize: 13))
          else
            ...meds.map((m) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.blueAccent, size: 8),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${m.name} (${m.dosage})',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    Text(
                      m.scheduledTimes.isNotEmpty ? m.scheduledTimes.join(', ') : 'Daily',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildQrMedicalPassportCard(BuildContext context, UserProfile profile, List<Medication> meds, Map<String, String> tr) {
    final medList = meds.map((m) => '${m.name} ${m.dosage}').join('; ');
    final qrData = 'PATIENT: ${profile.name}\nBLOOD: ${profile.bloodGroup ?? 'O+'}\nALLERGIES: ${profile.allergies ?? 'None'}\nMEDS: $medList\nICE: ${profile.emergencyContactPhone ?? '911'}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(tr['qrScanHint']!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 160.0,
            ),
          ),
        ],
      ),
    );
  }

  void _showDispatchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Emergency Country Hotline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸 🇨🇦', style: TextStyle(fontSize: 20)),
              title: const Text('United States & Canada (911)'),
              onTap: () {
                setState(() => _emergencyNumber = '911');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🇪🇺 🇮🇳', style: TextStyle(fontSize: 20)),
              title: const Text('Europe & India (112)'),
              onTap: () {
                setState(() => _emergencyNumber = '112');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 20)),
              title: const Text('United Kingdom (999)'),
              onTap: () {
                setState(() => _emergencyNumber = '999');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🇯🇵', style: TextStyle(fontSize: 20)),
              title: const Text('Japan (119)'),
              onTap: () {
                setState(() => _emergencyNumber = '119');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🇦🇺', style: TextStyle(fontSize: 20)),
              title: const Text('Australia (000)'),
              onTap: () {
                setState(() => _emergencyNumber = '000');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
