import 'package:flutter/material.dart';
import '../models/contract_section.dart';

/// 계약서 섹션의 헤더 위젯 (아코디언 UI)
class SectionHeader extends StatelessWidget {
  final ContractSection section;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggle;

  const SectionHeader({
    Key? key,
    required this.section,
    required this.index,
    required this.isExpanded,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isExpanded ? Colors.indigo.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isExpanded ? Colors.indigo : Colors.grey.shade300,
            width: isExpanded ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 번호와 제목
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              section.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isExpanded ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            // 완료 표시 아이콘
            if (section.isCompleted)
              const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            // 확장/축소 아이콘
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}