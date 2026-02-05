import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Task 3: Extra-large button widget for easy tapping
class LargeButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const LargeButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 70),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppTheme.iconSize),
            const SizedBox(width: 16),
          ],
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible, // Task 6: Prevent text cutoff
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

// Task 4: Organic treatment icon widget
class OrganicBadge extends StatelessWidget {
  final bool isOrganic;

  const OrganicBadge({
    Key? key,
    required this.isOrganic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isOrganic) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.organicGreen.withOpacity(0.15),
        border: Border.all(color: AppTheme.organicGreen, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.eco, // Leaf icon for organic
            color: AppTheme.organicGreen,
            size: 22,
          ),
          const SizedBox(width: 6),
          Text(
            'Organic',
            style: TextStyle(
              color: AppTheme.organicGreen,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Crop icon card for grid layout (Task 8)
class CropIconCard extends StatelessWidget {
  final String cropName;
  final String assetPath;
  final VoidCallback onTap;

  const CropIconCard({
    Key? key,
    required this.cropName,
    required this.assetPath,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                assetPath,
                width: 56,
                height: 56,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.agriculture,
                    size: 56,
                    color: AppTheme.accentGreen,
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                cropName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// History item card (Task 5)
class HistoryItemCard extends StatelessWidget {
  final String imagePath;
  final String date;
  final String cropName;
  final VoidCallback onTap;

  const HistoryItemCard({
    Key? key,
    required this.imagePath,
    required this.date,
    required this.cropName,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image,
                        size: 36,
                        color: AppTheme.accentGreen,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cropName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 28,
                color: AppTheme.lightGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Treatment step item (Task 11)
class TreatmentStepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final bool isOrganic;

  const TreatmentStepCard({
    Key? key,
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    this.isOrganic = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Step number circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, size: 32, color: AppTheme.accentGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryGreen,
              ),
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
            if (isOrganic) ...[
              const SizedBox(height: 12),
              OrganicBadge(isOrganic: true),
            ],
          ],
        ),
      ),
    );
  }
}