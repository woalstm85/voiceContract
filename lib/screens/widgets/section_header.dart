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
      borderRadius: BorderRadius.circular(12), // 테두리 둥글게 조정
      splashColor: Colors.indigo.withOpacity(0.1), // 탭 효과 색상
      child: Container(
        padding: const EdgeInsets.all(16), // 패딩 일관되게 조정
        decoration: BoxDecoration(
          color: isExpanded ? Colors.indigo.withOpacity(0.08) : Colors.white,
          border: Border.all(
            color: isExpanded ? Colors.indigo : Colors.grey.shade300,
            width: isExpanded ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12), // 테두리 둥글게 조정
          boxShadow: isExpanded ? [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            // 번호 배지
            Container(
              width: 40, // 크기 약간 증가
              height: 40, // 크기 약간 증가
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isExpanded ? Colors.indigo : Colors.indigo.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20), // 원형으로 만들기
                boxShadow: isExpanded ? [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // 글자 크기 조금 키움
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 17, // 글자 크기 조정
                      fontWeight: isExpanded ? FontWeight.bold : FontWeight.w500,
                      color: isExpanded ? Colors.indigo : Colors.black87,
                      letterSpacing: 0.5, // 자간 추가
                    ),
                  ),
                  if (!isExpanded && section.isCompleted) ...[
                    const SizedBox(height: 4),
                    // 축소 상태에서 완료된 항목의 경우 간략한 내용 미리보기
                    Text(
                      '작성 완료됨',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 완료 표시 아이콘
            if (section.isCompleted)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
              ),
            const SizedBox(width: 8),
            // 확장/축소 아이콘
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isExpanded
                    ? Colors.indigo.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: isExpanded ? Colors.indigo : Colors.grey[700],
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}