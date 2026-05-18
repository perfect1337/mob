import 'package:flutter/material.dart';

class CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryFilter({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: TextButton(
              onPressed: () => onCategorySelected(category),
              style: TextButton.styleFrom(
                backgroundColor: isSelected ? const Color(0xFF424242) : Colors.grey[100],
                foregroundColor: isSelected ? Colors.white : const Color(0xFF616161),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: Text(category),
            ),
          );
        },
      ),
    );
  }
}