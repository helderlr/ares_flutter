import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/terms_model.dart';

class TermsService {
  static const String _termsKey = 'terms_status';
  final SharedPreferences _prefs;

  TermsService(this._prefs);

  Future<TermsModel> getTermsStatus() async {
    final String? termsJson = _prefs.getString(_termsKey);
    if (termsJson == null) {
      return TermsModel.initial();
    }

    try {
      final Map<String, dynamic> json = jsonDecode(termsJson);
      return TermsModel.fromJson(json);
    } catch (e) {
      print('❌ Erro ao carregar status dos termos: $e');
      return TermsModel.initial();
    }
  }

  Future<void> acceptTerms() async {
    final terms = TermsModel(
      accepted: true,
      acceptedAt: DateTime.now(),
      version: '1.0.0',
    );

    try {
      await _prefs.setString(_termsKey, jsonEncode(terms.toJson()));
      print('✅ Termos aceitos e salvos com sucesso');
    } catch (e) {
      print('❌ Erro ao salvar aceite dos termos: $e');
      throw Exception('Erro ao salvar aceite dos termos');
    }
  }

  Future<void> resetTerms() async {
    try {
      await _prefs.remove(_termsKey);
      print('✅ Status dos termos resetado com sucesso');
    } catch (e) {
      print('❌ Erro ao resetar status dos termos: $e');
      throw Exception('Erro ao resetar status dos termos');
    }
  }
}
