import 'package:flutter/material.dart';
import '../models/item.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;

  const ItemCard({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFF424242)),
                  ),
                ),
                Text(
                  item.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: item.status == ItemStatus.available ? Colors.grey[600] : Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.category != null) ...[
              const SizedBox(height: 8),
              Text(item.category!, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ],
            if (item.price != null) ...[
              const SizedBox(height: 4),
              Text(
                '\$${item.price!.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}