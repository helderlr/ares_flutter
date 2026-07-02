import 'package:flutter/material.dart';
import 'protected_ui.dart';

class EntitySearchDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String placeholder,
    required Future<List<T>> Function(String query) searchFunction,
    required String Function(T item) labelOf,
    String Function(T item)? subtitleOf,
  }) async {
    final TextEditingController searchController = TextEditingController();
    List<T> searchResults = <T>[];
    bool isSearching = false;
    return showProtectedDialog<T>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            Future<void> runSearch(String value) async {
              if (value.trim().length < 2) {
                setDialogState(() => searchResults = <T>[]);
                return;
              }
              setDialogState(() => isSearching = true);
              try {
                final List<T> results = await searchFunction(value.trim());
                setDialogState(() {
                  searchResults = results;
                  isSearching = false;
                });
              } catch (_) {
                setDialogState(() {
                  searchResults = <T>[];
                  isSearching = false;
                });
              }
            }
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: searchController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: placeholder,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onChanged: (String value) => runSearch(value),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : searchResults.isEmpty
                              ? Center(
                                  child: Text(
                                    searchController.text.trim().length >= 2
                                        ? 'Nenhum registro encontrado'
                                        : 'Digite pelo menos 2 caracteres para buscar',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: searchResults.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final T item = searchResults[index];
                                    return ListTile(
                                      title: Text(labelOf(item)),
                                      subtitle: subtitleOf == null
                                          ? null
                                          : Text(subtitleOf(item)),
                                      onTap: () =>
                                          Navigator.of(dialogContext).pop(item),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
