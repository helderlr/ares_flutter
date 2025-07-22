class UserModel {
  final String login;
  final String nome;
  final String? codven;
  final String? token;
  final int? codusu;
  final String? senhaw;
  final String? admsis;
  final DateTime? datcad;

  const UserModel({
    required this.login,
    required this.nome,
    this.codven,
    this.token,
    this.codusu,
    this.senhaw,
    this.admsis,
    this.datcad,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      login: json['login'] ?? '',
      nome: json['nomusu'] ?? json['nome'] ?? '',
      codven: json['codven'],
      token: json['token'] ??
          json['accessToken'] ??
          json['jwt'] ??
          json['access_token'],
      codusu: json['codusu'],
      senhaw: json['senhaw'],
      admsis: json['admsis'],
      datcad: json['datcad'] != null ? DateTime.tryParse(json['datcad']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'login': login,
      'nomusu': nome,
      'codven': codven,
      'token': token,
      'codusu': codusu,
      'senhaw': senhaw,
      'admsis': admsis,
      'datcad': datcad?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? login,
    String? nome,
    String? codven,
    String? token,
    int? codusu,
    String? senhaw,
    String? admsis,
    DateTime? datcad,
  }) {
    return UserModel(
      login: login ?? this.login,
      nome: nome ?? this.nome,
      codven: codven ?? this.codven,
      token: token ?? this.token,
      codusu: codusu ?? this.codusu,
      senhaw: senhaw ?? this.senhaw,
      admsis: admsis ?? this.admsis,
      datcad: datcad ?? this.datcad,
    );
  }

  @override
  String toString() {
    return 'UserModel(login: $login, nome: $nome, codusu: $codusu, admsis: $admsis)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.login == login &&
        other.nome == nome &&
        other.codusu == codusu;
  }

  @override
  int get hashCode {
    return login.hashCode ^ nome.hashCode ^ codusu.hashCode;
  }
}
