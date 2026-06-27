import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    required this.onChanged,
    this.initialValue,
    this.hintText = 'Search',
    super.key,
  });

  final String? initialValue;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hintText,
      ),
    );
  }
}
