import 'package:flutter/material.dart';

class CustomFooter extends StatelessWidget {
  final VoidCallback onExploreTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onWishlistTap;
  final VoidCallback onProfileTap;

  const CustomFooter({
    super.key,
    required this.onExploreTap,
    required this.onGalleryTap,
    required this.onWishlistTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
        BottomNavigationBarItem(
          icon: Icon(Icons.photo_library),
          label: 'Gallery',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Wishlist'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            onExploreTap();
            break;
          case 1:
            onGalleryTap();
            break;
          case 2:
            onWishlistTap();
            break;
          case 3:
            onProfileTap();
            break;
        }
      },
    );
  }
}
