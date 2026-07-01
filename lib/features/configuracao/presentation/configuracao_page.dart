import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/google_maps_api_key_service.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../login/services/auth_service.dart';

class ConfiguracaoPage extends StatefulWidget {
  const ConfiguracaoPage({super.key});

  @override
  State<ConfiguracaoPage> createState() => _ConfiguracaoPageState();
}

class _ConfiguracaoPageState extends State<ConfiguracaoPage> {
  final GlobalKey<UserAvatarState> _userAvatarKey = GlobalKey<UserAvatarState>();
  final TextEditingController googleMapsApiKeyController =
      TextEditingController();
  String? googleMapsApiKeyError;
  bool _isAdmin = false;
  bool _obscureGoogleMapsKey = true;
  bool _isSavingMapsKey = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadAdminMapsConfig();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final String? name = await AuthService.getUserName();
    if (!mounted) {
      return;
    }
    setState(() {
      _userName = name?.trim() ?? 'Usuário';
    });
  }

  Future<void> _loadAdminMapsConfig() async {
    final permissions = await AuthService.getUserPermissions();
    final String apiKey =
        await GoogleMapsApiKeyService.instance.getEffectiveApiKey();
    if (!mounted) {
      return;
    }
    setState(() {
      _isAdmin = permissions.isAdmin;
      if (_isAdmin) {
        googleMapsApiKeyController.text = apiKey;
      }
    });
  }

  Future<void> _loadConfig() async {
    await _userAvatarKey.currentState?.reloadAvatar();
  }

  Future<void> pickUserAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_avatar_path', picked.path);
    await _userAvatarKey.currentState?.reloadAvatar();
    if (mounted) {
      setState(() {});
    }
  }

  void validateGoogleMapsApiKey(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        googleMapsApiKeyError = 'Informe a chave API do Google Maps';
      } else if (!value.trim().startsWith('AIza')) {
        googleMapsApiKeyError = 'Chave inválida (deve começar com AIza)';
      } else {
        googleMapsApiKeyError = null;
      }
    });
  }

  Future<void> saveConfig() async {
    if (_isAdmin) {
      validateGoogleMapsApiKey(googleMapsApiKeyController.text);
      if (googleMapsApiKeyError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(googleMapsApiKeyError!)),
        );
        return;
      }
    }
    String mapsSaveMessage = '';
    if (_isAdmin) {
      setState(() => _isSavingMapsKey = true);
      final SaveGoogleMapsApiKeyResult mapsResult =
          await GoogleMapsApiKeyService.instance.saveApiKeyAsAdmin(
        googleMapsApiKeyController.text,
      );
      setState(() => _isSavingMapsKey = false);
      if (mapsResult.isInvalidKey) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chave API do Google Maps inválida.'),
          ),
        );
        return;
      }
      if (mapsResult.savedOnServer) {
        mapsSaveMessage = ' Chave do mapa salva no servidor.';
      } else {
        mapsSaveMessage =
            ' Chave do mapa salva no aparelho (parâmetros do servidor ainda indisponíveis).';
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Parâmetros salvos com sucesso!$mapsSaveMessage'),
      ),
    );
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    googleMapsApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parâmetros'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                UserAvatar(
                  key: _userAvatarKey,
                  radius: 52,
                  showCameraButton: true,
                  onTap: pickUserAvatar,
                ),
                const SizedBox(height: 12),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Foto do usuário',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (_isAdmin) ...<Widget>[
            const SizedBox(height: 28),
            const Text(
              'Chave API Google Maps',
              style: TextStyle(
                color: AppColors.lightBlue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Somente administrador. Sincroniza com parâmetros do projeto AresIA.',
              style: TextStyle(color: AppColors.lightBlue, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: googleMapsApiKeyController,
              obscureText: _obscureGoogleMapsKey,
              decoration: InputDecoration(
                hintText: 'AIza...',
                errorText: googleMapsApiKeyError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureGoogleMapsKey
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureGoogleMapsKey = !_obscureGoogleMapsKey;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.lightBlue),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.lightBlue, width: 2),
                ),
              ),
              style: const TextStyle(
                color: AppColors.lightBlue,
                fontWeight: FontWeight.bold,
              ),
              onChanged: validateGoogleMapsApiKey,
            ),
          ],
          const SizedBox(height: 28),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            onPressed: () async {
              if (_isSavingMapsKey) {
                return;
              }
              final bool? confirmed = await showDialog<bool>(
                context: context,
                builder: (BuildContext ctx) => AlertDialog(
                  title: const Text('Salvar parâmetros'),
                  content:
                      const Text('Deseja realmente salvar os parâmetros?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await saveConfig();
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
