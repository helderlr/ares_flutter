import 'package:flutter/material.dart';

class SimpleSearchDelegate extends SearchDelegate<dynamic> {
  final String title;
  final Future<List<dynamic>> Function(String query) loadItems;
  final String Function(dynamic item) labelOf;
  List<dynamic> _items = <dynamic>[];
  bool _loaded = false;

  SimpleSearchDelegate({
    required this.title,
    required this.loadItems,
    required this.labelOf,
  });

  @override
  String get searchFieldLabel => title;

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }
    _items = await loadItems(query);
    _loaded = true;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<void>(
      future: _ensureLoaded(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: _items.length,
          itemBuilder: (BuildContext context, int index) {
            final dynamic item = _items[index];
            return ListTile(
              title: Text(labelOf(item)),
              onTap: () => close(context, item),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          _loaded = false;
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }
}
