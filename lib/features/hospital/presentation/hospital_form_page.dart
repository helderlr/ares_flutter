import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../services/hospital_service.dart';
import '../models/hospital_model.dart';
import '../widgets/receita_search_dialog.dart';

class HospitalFormPage extends StatefulWidget {
  final Hospital? hospital; // null = novo, não-null = edição

  const HospitalFormPage({
    super.key,
    this.hospital,
  });

  @override
  State<HospitalFormPage> createState() => _HospitalFormPageState();
}

class _HospitalFormPageState extends State<HospitalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _nomeFantasiaController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _telefoneController = TextEditingController();
  // Novos campos
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _cepController = TextEditingController();
  final _complementoController = TextEditingController();
  final _estadoController = TextEditingController();
  final _cnpjController = TextEditingController();

  final _hospitalService = HospitalService();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.hospital != null;

    if (_isEditing) {
      // Converter nome para caixa alta ao carregar
      _nomeController.text = widget.hospital!.nomcli.toUpperCase();
      _nomeFantasiaController.text = widget.hospital!.nomfan ?? '';
      _enderecoController.text = widget.hospital!.endcli ?? '';
      _telefoneController.text = widget.hospital!.f01cli ?? '';
      // Carregar novos campos
      _bairroController.text = widget.hospital!.baicli ?? '';
      _cidadeController.text = widget.hospital!.cidcli ?? '';
      _cepController.text = widget.hospital!.cepcli ?? '';
      _complementoController.text = widget.hospital!.comple ?? '';
      _estadoController.text = widget.hospital!.estcli ?? '';
      _cnpjController.text = widget.hospital!.cgccli ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _nomeFantasiaController.dispose();
    _enderecoController.dispose();
    _telefoneController.dispose();
    // Dispose dos novos controllers
    _bairroController.dispose();
    _cidadeController.dispose();
    _cepController.dispose();
    _complementoController.dispose();
    _estadoController.dispose();
    _cnpjController.dispose();
    super.dispose();
  }

  Future<void> _buscarReceita() async {
    print('🔍 Iniciando busca da Receita...');
    print('   CNPJ atual: ${_cnpjController.text.trim()}');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ReceitaSearchDialog(
        cnpjInicial: _cnpjController.text.trim(),
      ),
    );

    print('   Resultado do diálogo: $result');

    if (result != null && mounted) {
      print('   ✅ Dados recebidos, preenchendo campos...');

      // Preencher os campos com os dados da Receita
      setState(() {
        _nomeController.text = _converterParaString(result['nome']);
        _nomeFantasiaController.text = _converterParaString(result['fantasia']);
        _enderecoController.text = _converterParaString(result['logradouro']);
        // Campo número não existe na API
        _bairroController.text = _converterParaString(result['bairro']);
        _cidadeController.text = _converterParaString(result['municipio']);
        _estadoController.text = _converterParaString(result['uf']);
        _cepController.text = _converterParaString(result['cep']);
        _complementoController.text =
            _converterParaString(result['complemento']);
        _telefoneController.text = _converterParaString(result['telefone']);
      });

      print('   ✅ Campos preenchidos com sucesso!');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Dados da Receita Federal preenchidos automaticamente!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      print('   ❌ Nenhum dado recebido do diálogo');
    }
  }

  Future<void> _saveHospital() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final nome = _nomeController.text.trim();
      final nomeFantasia = _nomeFantasiaController.text.trim();
      final endereco = _enderecoController.text.trim();
      final telefone = _telefoneController.text.trim();
      final bairro = _bairroController.text.trim();
      final cidade = _cidadeController.text.trim();
      final cep = _cepController.text.trim();
      final complemento = _complementoController.text.trim();
      final estado = _estadoController.text.trim();
      final cnpj = _cnpjController.text.trim();

      print('💾 Salvando hospital:');
      print('   Nome: $nome');
      print('   Nome Fantasia: $nomeFantasia');
      print('   Endereço: $endereco');
      print('   Telefone: $telefone');
      print('   Bairro: $bairro');
      print('   Cidade: $cidade');
      print('   CEP: $cep');
      print('   Complemento: $complemento');
      print('   Estado: $estado');
      print('   CNPJ: $cnpj');

      // Validações adicionais antes de enviar
      if (nome.isEmpty) {
        throw Exception('Nome é obrigatório');
      }

      if (nome.length < 3) {
        throw Exception('Nome deve ter pelo menos 3 caracteres');
      }

      if (widget.hospital != null) {
        // Atualizando hospital existente
        await _hospitalService.updateHospital(
          codcli: widget.hospital!.codcli,
          nome: nome,
          nomeFantasia: nomeFantasia.isNotEmpty ? nomeFantasia : null,
          endereco: endereco.isNotEmpty ? endereco : null,
          telefone: telefone.isNotEmpty ? telefone : null,
          bairro: bairro.isNotEmpty ? bairro : null,
          cidade: cidade.isNotEmpty ? cidade : null,
          cep: cep.isNotEmpty ? cep : null,
          complemento: complemento.isNotEmpty ? complemento : null,
          estado: estado.isNotEmpty ? estado : null,
          cnpj: cnpj.isNotEmpty ? cnpj : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hospital atualizado com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Criando novo hospital
        final result = await _hospitalService.createHospital(
          nome: nome,
          nomeFantasia: nomeFantasia.isNotEmpty ? nomeFantasia : null,
          endereco: endereco.isNotEmpty ? endereco : null,
          telefone: telefone.isNotEmpty ? telefone : null,
          bairro: bairro.isNotEmpty ? bairro : null,
          cidade: cidade.isNotEmpty ? cidade : null,
          cep: cep.isNotEmpty ? cep : null,
          complemento: complemento.isNotEmpty ? complemento : null,
          estado: estado.isNotEmpty ? estado : null,
          cnpj: cnpj.isNotEmpty ? cnpj : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Hospital criado com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      print('❌ Erro ao salvar hospital: $e');

      if (mounted) {
        String errorMessage = 'Erro ao salvar hospital';

        if (e.toString().contains('Token')) {
          errorMessage = 'Sessão expirada. Faça login novamente.';
        } else if (e.toString().contains('Dados inválidos')) {
          errorMessage = 'Dados inválidos. Verifique as informações.';
        } else if (e.toString().contains('não encontrado')) {
          errorMessage = 'Hospital não encontrado.';
        } else if (e.toString().contains('conexão')) {
          errorMessage = 'Erro de conexão. Verifique sua internet.';
        } else if (e.toString().contains('servidor')) {
          errorMessage = 'Erro do servidor. Tente novamente mais tarde.';
        } else if (e.toString().contains('Nome')) {
          errorMessage =
              'Erro no nome: ${e.toString().replaceAll('Exception: ', '')}';
        } else {
          errorMessage = 'Erro: ${e.toString().replaceAll('Exception: ', '')}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Hospital' : 'Novo Hospital'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Lista de campos (sem título)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildInputField('Nome', _nomeController, true, null),
                  _buildInputField('Nome Fantasia (opcional)',
                      _nomeFantasiaController, false, null),
                  _buildCnpjField(),
                  _buildInputField(
                      'Endereço (opcional)', _enderecoController, false, null),
                  // Campo número removido - não existe na API
                  _buildInputField(
                      'Bairro (opcional)', _bairroController, false, null),
                  _buildInputField(
                      'Cidade (opcional)', _cidadeController, false, null),
                  _buildInputField(
                      'CEP (opcional)', _cepController, false, null),
                  _buildInputField('Complemento (opcional)',
                      _complementoController, false, null),
                  _buildEstadoField(),
                  _buildInputField(
                      'Telefone (opcional)', _telefoneController, false, null),
                ],
              ),
            ),
            // Rodapé igual à tela de consulta
            Container(
              width: double.infinity,
              height: 60,
              color: AppColors.lightBlue,
              child: Row(
                children: [
                  // Botão CANCELAR
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading ? null : () => Navigator.pop(context),
                      child: Container(
                        color: Colors.transparent,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cancel,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Linha divisória
                  Container(
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  // Botão SALVAR
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading ? null : _saveHospital,
                      child: Container(
                        color: Colors.transparent,
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Salvando...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isEditing ? Icons.save : Icons.add,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Salvar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCnpjField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label (título em negrito)
          const Text(
            'CNPJ (opcional)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Campo de entrada com botão de busca
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cnpjController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: '00.000.000/0000-00',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(14),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length != 14) {
                        return 'CNPJ deve ter 14 dígitos';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  print('🔍 Botão de busca clicado!');
                  _buscarReceita();
                },
                icon: const Icon(Icons.search, color: AppColors.lightBlue),
                tooltip: 'Buscar dados da Receita Federal',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Linha divisória
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoField() {
    // Lista de todas as UFs do Brasil
    final List<Map<String, String>> estados = [
      {'sigla': 'AC', 'nome': 'Acre'},
      {'sigla': 'AL', 'nome': 'Alagoas'},
      {'sigla': 'AP', 'nome': 'Amapá'},
      {'sigla': 'AM', 'nome': 'Amazonas'},
      {'sigla': 'BA', 'nome': 'Bahia'},
      {'sigla': 'CE', 'nome': 'Ceará'},
      {'sigla': 'DF', 'nome': 'Distrito Federal'},
      {'sigla': 'ES', 'nome': 'Espírito Santo'},
      {'sigla': 'GO', 'nome': 'Goiás'},
      {'sigla': 'MA', 'nome': 'Maranhão'},
      {'sigla': 'MT', 'nome': 'Mato Grosso'},
      {'sigla': 'MS', 'nome': 'Mato Grosso do Sul'},
      {'sigla': 'MG', 'nome': 'Minas Gerais'},
      {'sigla': 'PA', 'nome': 'Pará'},
      {'sigla': 'PB', 'nome': 'Paraíba'},
      {'sigla': 'PR', 'nome': 'Paraná'},
      {'sigla': 'PE', 'nome': 'Pernambuco'},
      {'sigla': 'PI', 'nome': 'Piauí'},
      {'sigla': 'RJ', 'nome': 'Rio de Janeiro'},
      {'sigla': 'RN', 'nome': 'Rio Grande do Norte'},
      {'sigla': 'RS', 'nome': 'Rio Grande do Sul'},
      {'sigla': 'RO', 'nome': 'Rondônia'},
      {'sigla': 'RR', 'nome': 'Roraima'},
      {'sigla': 'SC', 'nome': 'Santa Catarina'},
      {'sigla': 'SP', 'nome': 'São Paulo'},
      {'sigla': 'SE', 'nome': 'Sergipe'},
      {'sigla': 'TO', 'nome': 'Tocantins'},
    ];

    // Encontrar o estado selecionado
    String? estadoSelecionado;
    if (_estadoController.text.isNotEmpty) {
      estadoSelecionado = estados.firstWhere(
        (estado) => estado['sigla'] == _estadoController.text,
        orElse: () => {'sigla': '', 'nome': ''},
      )['sigla'];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label (título em negrito)
          const Text(
            'Estado (opcional)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Dropdown de seleção
          DropdownButtonFormField<String>(
            value: estadoSelecionado,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Selecione o estado',
            ),
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('Selecione o estado'),
              ),
              ...estados.map((estado) {
                return DropdownMenuItem<String>(
                  value: estado['sigla'],
                  child: Text('${estado['sigla']} - ${estado['nome']}'),
                );
              }).toList(),
            ],
            onChanged: (String? newValue) {
              setState(() {
                _estadoController.text = newValue ?? '';
              });
            },
            validator: (value) {
              // Campo é opcional, então não precisa de validação
              return null;
            },
          ),
          const SizedBox(height: 12),
          // Linha divisória
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      bool isRequired, IconData? icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label (título em negrito)
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Campo de entrada
          TextFormField(
            controller: controller,
            // Configurar caixa alta apenas para o campo nome
            textCapitalization: label.contains('Nome')
                ? TextCapitalization.characters
                : TextCapitalization.none,
            // Converter para caixa alta em tempo real para o campo nome
            onChanged: label.contains('Nome')
                ? (value) {
                    // Manter cursor na posição correta
                    final cursorPosition = controller.selection.start;
                    final upperValue = value.toUpperCase();
                    if (value != upperValue) {
                      controller.value = TextEditingValue(
                        text: upperValue,
                        selection: TextSelection.collapsed(
                          offset: cursorPosition,
                        ),
                      );
                    }
                  }
                : null,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: _getHintText(label),
              prefixIcon: icon != null ? Icon(icon) : null,
            ),
            validator: isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo obrigatório';
                    }
                    if (label.contains('Nome') && value.trim().length < 3) {
                      return 'Nome deve ter pelo menos 3 caracteres';
                    }
                    return null;
                  }
                : null,
          ),
          const SizedBox(height: 12),
          // Linha divisória
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  /// Converte qualquer valor para String de forma segura
  String _converterParaString(dynamic valor) {
    if (valor == null) return '';
    if (valor is String) return valor;
    if (valor is int) return valor.toString();
    if (valor is double) return valor.toString();
    if (valor is bool) return valor.toString();
    return valor.toString();
  }

  String _getHintText(String label) {
    if (label.contains('Nome') && !label.contains('Fantasia')) {
      return 'Digite o nome completo do cliente/hospital (será convertido para MAIÚSCULAS)';
    } else if (label.contains('Nome Fantasia')) {
      return 'Nome fantasia ou nome comercial';
    } else if (label.contains('Endereço')) {
      return 'Logradouro (Rua, Avenida, etc.)';
    } else if (label.contains('Número')) {
      return 'Número do endereço';
    } else if (label.contains('Bairro')) {
      return 'Nome do bairro';
    } else if (label.contains('Cidade')) {
      return 'Nome da cidade';
    } else if (label.contains('CEP')) {
      return '00000-000';
    } else if (label.contains('Complemento')) {
      return 'Apartamento, sala, etc.';
    } else if (label.contains('Estado')) {
      return 'UF (SP, RJ, etc.)';
    } else if (label.contains('Telefone')) {
      return 'Telefone de contato';
    }
    return '';
  }
}
