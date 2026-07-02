import 'package:flutter/material.dart';

class FormSectionField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback? onSearch;
  final IconData? actionIcon;
  final String? subtitle;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hintText;
  final bool readOnly;

  const FormSectionField({
    super.key,
    required this.label,
    required this.controller,
    this.onSearch,
    this.actionIcon,
    this.subtitle,
    this.keyboardType,
    this.maxLines = 1,
    this.hintText,
    this.readOnly = false,
  });

  static InputDecoration _plainDecoration({String? hintText}) {
    return InputDecoration(
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            readOnly: readOnly,
            decoration: _plainDecoration(hintText: hintText).copyWith(
              suffixIcon: onSearch == null || readOnly
                  ? null
                  : IconButton(
                      icon: Icon(
                        actionIcon ?? Icons.search,
                        color: Colors.blue[700],
                      ),
                      onPressed: onSearch,
                      tooltip: 'Buscar $label',
                    ),
            ),
          ),
          if ((subtitle ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, height: 1),
        ],
      ),
    );
  }
}

class FormSectionLookup extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback? onSearch;
  final bool readOnly;

  const FormSectionLookup({
    super.key,
    required this.label,
    this.value,
    this.placeholder = 'Toque para buscar',
    this.onSearch,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && value!.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: readOnly ? null : onSearch,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    hasValue ? value! : placeholder,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: hasValue ? Colors.black87 : Colors.grey.shade600,
                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                if (!readOnly && onSearch != null)
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.blue[700]),
                    onPressed: onSearch,
                    tooltip: 'Buscar $label',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, height: 1),
        ],
      ),
    );
  }
}

class FormSectionDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool readOnly;

  const FormSectionDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            value: value,
            decoration: FormSectionField._plainDecoration(),
            items: items,
            onChanged: readOnly ? null : onChanged,
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, height: 1),
        ],
      ),
    );
  }
}
