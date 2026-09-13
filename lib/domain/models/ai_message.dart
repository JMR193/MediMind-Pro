/// Role for the offline AI assistant message
enum AiRole { user, assistant, system }

class AiMessage {
  final String id;
  final AiRole role;
  final String content;
  final DateTime timestamp;
  final bool isTyping;

  const AiMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isTyping = false,
  });

  AiMessage copyWith({String? content, bool? isTyping}) => AiMessage(
        id: id,
        role: role,
        content: content ?? this.content,
        timestamp: timestamp,
        isTyping: isTyping ?? this.isTyping,
      );
}

/// Streak data for adherence gamification
class StreakData {
  final int currentStreak; // consecutive days with all doses taken
  final int bestStreak;
  final DateTime? lastFullAdherenceDay;
  final int totalDaysWith100Percent;

  const StreakData({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastFullAdherenceDay,
    this.totalDaysWith100Percent = 0,
  });

  String get streakBadge {
    if (currentStreak >= 30) return '🏆 30-Day Champion';
    if (currentStreak >= 14) return '⭐ 2-Week Star';
    if (currentStreak >= 7) return '🔥 Week Warrior';
    if (currentStreak >= 3) return '💪 3-Day Strong';
    if (currentStreak >= 1) return '✅ On Track';
    return '🎯 Start your streak!';
  }

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastFullAdherenceDay': lastFullAdherenceDay?.toIso8601String(),
        'totalDaysWith100Percent': totalDaysWith100Percent,
      };

  factory StreakData.fromJson(Map<String, dynamic> json) => StreakData(
        currentStreak: json['currentStreak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
        lastFullAdherenceDay: json['lastFullAdherenceDay'] != null
            ? DateTime.tryParse(json['lastFullAdherenceDay'] as String)
            : null,
        totalDaysWith100Percent: json['totalDaysWith100Percent'] as int? ?? 0,
      );
}
