import 'package:flutter/material.dart';

/// 이 파일은 여러 지원 화면에서 공통으로 사용되는 위젯과 유틸리티를 포함합니다.

// 기본 색상 상수
class AppColors {
  static const Color primary = Colors.indigo;
  static const Color background = Colors.white;
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color success = Colors.green;
  static const Color error = Colors.red;
}

// 확장 가능한 카드 아이템 (공지사항, FAQ, 이용약관 등에서 사용)
class ExpandableCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String content;
  final IconData icon;
  final bool initiallyExpanded;

  const ExpandableCard({
    Key? key,
    required this.title,
    this.subtitle,
    required this.content,
    required this.icon,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          )
              : null,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(16),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 설정 화면에서 사용되는 메뉴 아이템
class SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final VoidCallback onTap;
  final bool isDestructive;
  final Color? backgroundColor;

  const SettingsMenuItem({
    Key? key,
    required this.icon,
    required this.title,
    this.description,
    required this.onTap,
    this.isDestructive = false,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = isDestructive ? AppColors.error : AppColors.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: backgroundColor ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDestructive ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 안내 메시지 카드
class InfoCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const InfoCard({
    Key? key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color = AppColors.primary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 문의 방법 아이템 (문의하기 화면에서 사용)
class ContactMethodItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const ContactMethodItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.detail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              detail,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}