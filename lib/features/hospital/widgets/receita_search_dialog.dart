import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../services/receita_service.dart';

class ReceitaSearchDialog extends StatefulWidget {
  final String? cnpjInicial;

  const ReceitaSearchDialog({
    super.key,
    this.cnpjInicial,
  });

  @override
  State<ReceitaSearchDialog> createState() => _ReceitaSearchDialogState();
}

class _ReceitaSearchDialogState extends State<ReceitaSearchDialog> {
  final TextEditingController _cnpjController = TextEditingController();
  final ReceitaService _receitaService = ReceitaService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  Map<String, dynamic>? _dadosReceita;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('🔍 Diálogo: Inicializando...');
    print('   CNPJ inicial: ${widget.cnpjInicial}');

    if (widget.cnpjInicial != null) {
      _cnpjController.text = widget.cnpjInicial!;
      print('   ✅ CNPJ inicial definido: ${_cnpjController.text}');
    } else {
      print('   ℹ️  Nenhum CNPJ inicial fornecido');
    }
  }

  @override
  void dispose() {
    _cnpjController.dispose();
    super.dispose();
  }

  Future<void> _buscarCnpj() async {
    print('🔍 Diálogo: Iniciando busca...');

    if (!_formKey.currentState!.validate()) {
      print('   ❌ Validação falhou');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _dadosReceita = null;
    });

    try {
      final cnpj = _cnpjController.text.trim();
      print('   📡 Buscando CNPJ: $cnpj');

      final dados = await _receitaService.buscarPorCnpj(cnpj);
      print('   📥 Dados recebidos: $dados');

      if (mounted) {
        setState(() {
          _dadosReceita = dados;
          _isLoading = false;
        });
        print('   ✅ Estado atualizado com dados');
      }
    } catch (e) {
      print('   ❌ Erro na busca: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        print('   ✅ Estado atualizado com erro');
      }
    }
  }

  void _confirmarSelecao() {
    print('🔍 Diálogo: Confirmando seleção...');
    print('   Dados disponíveis: $_dadosReceita');

    if (_dadosReceita != null) {
      print('   ✅ Retornando dados para o formulário');
      Navigator.of(context).pop(_dadosReceita);
    } else {
      print('   ❌ Nenhum dado disponível para retornar');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 Diálogo: Construindo interface...');

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Buscar Dados da Receita',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Formulário de busca
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _cnpjController,
                            decoration: const InputDecoration(
                              labelText: 'CNPJ',
                              hintText: '00.000.000/0000-00',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              print('   🔍 Validando CNPJ: $value');
                              if (value == null || value.trim().isEmpty) {
                                print('   ❌ CNPJ vazio');
                                return 'CNPJ é obrigatório';
                              }
                              final cnpjLimpo =
                                  value.replaceAll(RegExp(r'[^\d]'), '');
                              print(
                                  '   📝 CNPJ limpo: $cnpjLimpo (${cnpjLimpo.length} dígitos)');
                              if (cnpjLimpo.length != 14) {
                                print('   ❌ CNPJ com tamanho incorreto');
                                return 'CNPJ deve ter 14 dígitos';
                              }
                              print('   ✅ CNPJ válido');
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      print(
                                          '🔍 Botão de busca do diálogo clicado!');
                                      _buscarCnpj();
                                    },
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.search),
                              label:
                                  Text(_isLoading ? 'Buscando...' : 'Buscar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.lightBlue,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Resultado da busca
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_dadosReceita != null) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Dados Encontrados:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildInfoRow(
                                  'Nome', _dadosReceita!['nome'] ?? ''),
                              _buildInfoRow(
                                  'Fantasia', _dadosReceita!['fantasia'] ?? ''),
                              _buildInfoRow('Logradouro',
                                  _dadosReceita!['logradouro'] ?? ''),
                              _buildInfoRow(
                                  'Número', _dadosReceita!['numero'] ?? ''),
                              _buildInfoRow('Complemento',
                                  _dadosReceita!['complemento'] ?? ''),
                              _buildInfoRow(
                                  'Bairro', _dadosReceita!['bairro'] ?? ''),
                              _buildInfoRow('Município',
                                  _dadosReceita!['municipio'] ?? ''),
                              _buildInfoRow('UF', _dadosReceita!['uf'] ?? ''),
                              _buildInfoRow('CEP', _dadosReceita!['cep'] ?? ''),
                              _buildInfoRow(
                                  'Telefone', _dadosReceita!['telefone'] ?? ''),
                              _buildInfoRow(
                                  'Email', _dadosReceita!['email'] ?? ''),
                              _buildInfoRow(
                                  'Situação',
                                  _converterParaString(
                                      _dadosReceita!['situacao'])),
                              _buildInfoRow(
                                  'Data Abertura',
                                  _converterParaString(
                                      _dadosReceita!['abertura'])),
                              _buildInfoRow(
                                  'Porte',
                                  _converterParaString(
                                      _dadosReceita!['porte'])),
                              _buildInfoRow(
                                  'Natureza Jurídica',
                                  _converterParaString(
                                      _dadosReceita!['natureza_juridica'])),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer com botões
            if (_dadosReceita != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirmarSelecao,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Usar Dados'),
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

  /// Converte qualquer valor para String de forma segura
  String _converterParaString(dynamic valor) {
    if (valor == null) return '';
    if (valor is String) return valor;
    if (valor is int) return valor.toString();
    if (valor is double) return valor.toString();
    if (valor is bool) return valor.toString();
    return valor.toString();
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
