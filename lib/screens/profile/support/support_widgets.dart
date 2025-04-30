// 이 코드를 support_widgets.dart 파일에 추가하거나 수정하세요.
import 'package:flutter/material.dart';

class SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isDestructive;
  final Color? color;

  const SettingsMenuItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.isDestructive = false,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemColor = isDestructive ? Colors.red : (color ?? Colors.indigo);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // 아이콘 컨테이너
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: itemColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: itemColor,
              ),
            ),
            const SizedBox(width: 16),
            // 텍스트 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red[700] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // 화살표 아이콘
            Icon(
              Icons.chevron_right,
              color: itemColor.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}