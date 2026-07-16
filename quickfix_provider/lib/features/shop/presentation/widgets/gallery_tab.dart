import 'package:flutter/material.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';

class GalleryTab extends StatelessWidget {
  final List<String> portfolioImages;
  final bool portfolioUploading;
  final VoidCallback onPickAndUploadPortfolio;
  final Function(String) onDeletePortfolioImage;

  const GalleryTab({
    super.key,
    required this.portfolioImages,
    required this.portfolioUploading,
    required this.onPickAndUploadPortfolio,
    required this.onDeletePortfolioImage,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        // Refresh handled by main state parent
      },
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: (portfolioImages.length + 1),
        itemBuilder: (context, index) {
          if (index == portfolioImages.length) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white12,
                  style: BorderStyle.values[1],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: portfolioUploading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: onPickAndUploadPortfolio,
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primary,
                      ),
                    ),
            );
          }

          final imageUrl = portfolioImages[index];
          return Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white10,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.white30,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onDeletePortfolioImage(imageUrl),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
