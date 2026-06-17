class TermsModel {
  final bool accepted;
  final DateTime? acceptedAt;
  final String version;

  const TermsModel({
    required this.accepted,
    this.acceptedAt,
    required this.version,
  });

  factory TermsModel.initial() {
    return const TermsModel(
      accepted: false,
      acceptedAt: null,
      version: '1.0.0',
    );
  }

  factory TermsModel.fromJson(Map<String, dynamic> json) {
    return TermsModel(
      accepted: json['accepted'] ?? false,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      version: json['version'] ?? '1.0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accepted': accepted,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'version': version,
    };
  }

  TermsModel copyWith({
    bool? accepted,
    DateTime? acceptedAt,
    String? version,
  }) {
    return TermsModel(
      accepted: accepted ?? this.accepted,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      version: version ?? this.version,
    );
  }
}
