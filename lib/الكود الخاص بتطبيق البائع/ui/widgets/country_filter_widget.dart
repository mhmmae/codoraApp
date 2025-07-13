import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/store_products_controller.dart';
import '../../addItem/editProducts/controllers/edit_product_controller.dart';

class CountryFilterWidget extends StatefulWidget {
  final StoreProductsController controller;
  const CountryFilterWidget({super.key, required this.controller});

  @override
  State<CountryFilterWidget> createState() => CountryFilterWidgetState();
}

class CountryFilterWidgetState extends State<CountryFilterWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<MapEntry<String, Map<String, String>>> _suggestions = [];
  String _input = '';

  // Use the full country list from EditProductController
  List<MapEntry<String, Map<String, String>>> get _allCountries =>
      EditProductController.countryOfOriginOptions.entries.toList();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _input = widget.controller.selectedCountry.value;
    _searchController.text = _input;
    _updateSuggestions(_input);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _input = _searchController.text;
      _updateSuggestions(_input);
    });
  }

  void _updateSuggestions(String input) {
    if (input.isEmpty) {
      _suggestions = _allCountries;
    } else {
      _suggestions =
          _allCountries
              .where(
                (entry) =>
                    entry.value['ar']!.contains(input) ||
                    entry.value['ar']!.toLowerCase().contains(
                      input.toLowerCase(),
                    ) ||
                    entry.value['en']!.toLowerCase().contains(
                      input.toLowerCase(),
                    ) ||
                    entry.key.toLowerCase().contains(input.toLowerCase()),
              )
              .toList();
    }
  }

  void _selectCountry(MapEntry<String, Map<String, String>> entry) {
    widget.controller.setCountry(entry.value['ar']!);
    setState(() {
      _input = entry.value['ar']!;
      _searchController.text = entry.value['ar']!;
      _updateSuggestions(entry.value['ar']!);
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.controller.selectedCountry.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ابحث عن بلد الصنع أو اختر من القائمة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Get.theme.primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Icon(Icons.search, color: Get.theme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'اكتب اسم البلد أو الرمز أو الإنجليزية...',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              if (_input.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _input = '';
                      _updateSuggestions('');
                    });
                  },
                ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 320),
            child: Material(
              color: Colors.transparent,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder:
                    (context, idx) =>
                        Divider(height: 1, color: Colors.grey[300]),
                itemBuilder: (context, idx) {
                  final entry = _suggestions[idx];
                  final isSelected = entry.value['ar'] == selected;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isSelected
                              ? Get.theme.primaryColor.withOpacity(0.15)
                              : Colors.grey[200],
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected
                                  ? Get.theme.primaryColor
                                  : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(
                      entry.value['ar']!,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected
                                ? Get.theme.primaryColor
                                : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      entry.value['en']!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing:
                        isSelected
                            ? Icon(
                              Icons.check_circle,
                              color: Get.theme.primaryColor,
                            )
                            : null,
                    onTap: () => _selectCountry(entry),
                  );
                },
              ),
            ),
          ),
        if (_suggestions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'لا توجد نتائج مطابقة',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }
}
