import '../../../core/permissions/user_permissions.dart';

class UserModel {
  final String id;
  final String nome;
  final String email;
  final String? token;
  final String? login;
  final String? codven;
  final int? codusu;
  final int? codins;
  final String? admsis;
  final String? ativo;

  const UserModel({
    required this.id,
    required this.nome,
    required this.email,
    this.token,
    this.login,
    this.codven,
    this.codusu,
    this.codins,
    this.admsis,
    this.ativo,
  });

  bool get isAdmin => UserPermissions.parseAdminFlag(admsis);

  bool get isActive => UserPermissions.parseActiveFlag(ativo);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? json['nomusu']?.toString() ?? '',
      email: json['email']?.toString() ?? json['login']?.toString() ?? '',
      token: json['token']?.toString() ??
          json['accessToken']?.toString() ??
          json['jwt']?.toString(),
      login: json['login']?.toString(),
      codven: json['codven']?.toString(),
      codusu: json['codusu'] is int
          ? json['codusu'] as int
          : int.tryParse(json['codusu']?.toString() ?? ''),
      codins: json['codins'] is int
          ? json['codins'] as int
          : int.tryParse(json['codins']?.toString() ?? ''),
      admsis: json['admsis']?.toString(),
      ativo: json['ativo']?.toString(),
    );
  }

  static String? extractEmpresaIdFromRef(String userRef) {
    final int separatorIndex = userRef.lastIndexOf('~');
    if (separatorIndex <= 0) {
      return null;
    }
    return userRef.substring(0, separatorIndex);
  }

  static int? extractCodusuFromRef(String userRef) {
    final int separatorIndex = userRef.lastIndexOf('~');
    if (separatorIndex < 0 || separatorIndex >= userRef.length - 1) {
      return null;
    }
    return int.tryParse(userRef.substring(separatorIndex + 1));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      if (token != null) 'token': token,
      if (login != null) 'login': login,
      if (codven != null) 'codven': codven,
      if (codusu != null) 'codusu': codusu,
      if (codins != null) 'codins': codins,
      if (admsis != null) 'admsis': admsis,
      if (ativo != null) 'ativo': ativo,
    };
  }

  UserModel copyWith({
    String? id,
    String? nome,
    String? email,
    String? token,
    String? login,
    String? codven,
    int? codusu,
    int? codins,
    String? admsis,
    String? ativo,
  }) {
    return UserModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      token: token ?? this.token,
      login: login ?? this.login,
      codven: codven ?? this.codven,
      codusu: codusu ?? this.codusu,
      codins: codins ?? this.codins,
      admsis: admsis ?? this.admsis,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nome: $nome, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id && other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
