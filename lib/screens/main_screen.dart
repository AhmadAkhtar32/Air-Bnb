import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_navbar.dart';
import '../widgets/custom_footer.dart';
import '../widgets/custom_card.dart';
import '../services/auth_service.dart';
import 'gallery_screen.dart';
import 'wishlist_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isBooking = false;
  String _searchQuery = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Property data with both local and online image URLs
  final List<Map<String, dynamic>> _properties = [
    {
      'localImageUrl': 'assets/images/property1.jpg',
      'onlineImageUrl':
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
      'title': 'Modern Apartment',
      'description':
          'Stylish apartment in the city center with modern amenities',
      'price': '\$120/night',
      'stayDays': 3,
      'rating': 4.8,
      'location': 'Downtown',
      'amenities': ['WiFi', 'Kitchen', 'Parking', 'Pool'],
      'category': 'apartment',
    },
    {
      'localImageUrl': 'assets/images/property2.jpg',
      'onlineImageUrl':
          'https://images.unsplash.com/photo-1475855581690-80accde3ae2b?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
      'title': 'Cozy Cabin',
      'description': 'Perfect for a weekend getaway in nature',
      'price': '\$90/night',
      'stayDays': 2,
      'rating': 4.6,
      'location': 'Mountain View',
      'amenities': ['Fireplace', 'WiFi', 'Kitchen', 'Garden'],
      'category': 'cabin',
    },
    {
      'localImageUrl': 'assets/images/property3.jpg',
      'onlineImageUrl':
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
      'title': 'Luxury Villa',
      'description': 'Private pool and amazing views for luxury stay',
      'price': '\$250/night',
      'stayDays': 5,
      'rating': 4.9,
      'location': 'Beachfront',
      'amenities': ['Private Pool', 'Beach Access', 'WiFi', 'Chef Service'],
      'category': 'villa',
    },
    {
      'localImageUrl': 'assets/images/property4.jpg',
      'onlineImageUrl':
          'https://images.unsplash.com/photo-1484154218962-a197022b5858?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
      'title': 'City Loft',
      'description': 'Trendy loft with great amenities in urban setting',
      'price': '\$150/night',
      'stayDays': 4,
      'rating': 4.7,
      'location': 'Arts District',
      'amenities': ['WiFi', 'Gym', 'Rooftop Access', 'Kitchen'],
      'category': 'loft',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      _currentUser = _authService.currentUser;
      if (_currentUser != null) {
        _userData = await _authService.getUserData(_currentUser!.uid);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      await _authService.signOut();
      if (mounted) _navigateToLogin();
      return;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (mounted) _navigateToLogin();
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Error signing out: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Color(0xFFFD5B61)),
              SizedBox(width: 8),
              Text('Sign Out'),
            ],
          ),
          content: const Text(
            'Are you sure you want to sign out? You\'ll need to log in again to access your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleSignOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFD5B61),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  void _showBookingDialog({
    required Map<String, dynamic> property,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.book_online,
                      color: Color(0xFFFD5B61),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBookingDetailRow(
                  Icons.home,
                  'Property',
                  property['title'],
                ),
                const SizedBox(height: 8),
                _buildBookingDetailRow(
                  Icons.location_on,
                  'Location',
                  property['location'],
                ),
                const SizedBox(height: 8),
                _buildBookingDetailRow(
                  Icons.attach_money,
                  'Price',
                  property['price'],
                ),
                const SizedBox(height: 8),
                _buildBookingDetailRow(
                  Icons.calendar_today,
                  'Duration',
                  '${property['stayDays']} days',
                ),
                const SizedBox(height: 8),
                _buildBookingDetailRow(
                  Icons.star,
                  'Rating',
                  '${property['rating']} ⭐',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFD5B61).withOpacity(0.1),
                        const Color(0xFFFD5B61).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFD5B61).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calculate,
                            color: Color(0xFFFD5B61),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Total Cost:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _calculateTotalCost(
                              property['price'],
                              property['stayDays'],
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFD5B61),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${property['price']} × ${property['stayDays']} days',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFD5B61)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFFFD5B61)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isBooking
                            ? null
                            : () async {
                                Navigator.of(context).pop();
                                await _handleBooking(property: property);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFD5B61),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isBooking
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Confirm Booking'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _calculateTotalCost(String price, int days) {
    String numericPrice = price.replaceAll(RegExp(r'[^\d]'), '');
    int pricePerNight = int.tryParse(numericPrice) ?? 0;
    int totalCost = pricePerNight * days;
    return '\$${totalCost}';
  }

  Future<void> _handleBooking({
    required Map<String, dynamic> property,
  }) async {
    setState(() => _isBooking = true);

    try {
      if (_currentUser != null) {
        await _authService.saveBooking(
          userId: _currentUser!.uid,
          propertyTitle: property['title'],
          price: property['price'],
          stayDays: property['stayDays'],
          imageUrl: property['onlineImageUrl'] ?? property['localImageUrl'],
          description: property['description'],
          totalCost: _calculateTotalCost(
            property['price'],
            property['stayDays'],
          ),
        );

        if (mounted) {
          _showSnackBar(
              'Booking Successful! 🎉 Check your profile for details.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Booking failed: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProperties {
    if (_searchQuery.isEmpty) return _properties;

    return _properties.where((property) {
      final searchLower = _searchQuery.toLowerCase();
      return property['title'].toLowerCase().contains(searchLower) ||
          property['description'].toLowerCase().contains(searchLower) ||
          property['location'].toLowerCase().contains(searchLower) ||
          property['category'].toLowerCase().contains(searchLower);
    }).toList();
  }

  Widget _buildWelcomeSection() {
    if (_userData == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFD5B61).withOpacity(0.1),
              const Color(0xFFFD5B61).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFD5B61).withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFD5B61).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.waving_hand,
                    color: Color(0xFFFD5B61),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hello, ${_userData!['fullName'] ?? 'User'}!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFD5B61),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Find your perfect stay from our amazing collection of properties.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          decoration: InputDecoration(
            hintText: 'Search properties, locations...',
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFFFD5B61),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedProperty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Featured Property',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFD5B61),
                  const Color(0xFFFF8A80),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFD5B61).withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.beach_access,
                        size: 60,
                        color: Colors.white,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Beautiful Beach House',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Luxury oceanfront experience',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      'Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Popular Properties',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_searchQuery.isNotEmpty) ...[
                Text(
                  '${_filteredProperties.length} results',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (_filteredProperties.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No properties found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try searching with different keywords',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...(_filteredProperties.asMap().entries.map((entry) {
              final index = entry.key;
              final property = entry.value;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < _filteredProperties.length - 1 ? 16 : 0,
                ),
                child: CustomCard(
                  imageUrl:
                      property['onlineImageUrl'] ?? property['localImageUrl'],
                  fallbackImageUrl: property['onlineImageUrl'],
                  title: property['title'] ?? 'Property',
                  description:
                      '${property['description'] ?? ''} • ${property['stayDays'] ?? 1} days stay',
                  price: property['price'] ?? '\$0/night',
                  rating: property['rating']?.toDouble(),
                  location: property['location'],
                  amenities: property['amenities'] != null
                      ? List<String>.from(property['amenities'])
                      : null,
                  onBookNow: () => _showBookingDialog(property: property),
                ),
              );
            }).toList()),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFFFD5B61),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your experience...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _userData != null
              ? 'Welcome, ${_userData!['fullName']?.split(' ')[0] ?? 'User'}'
              : 'StayFinder',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _showSignOutDialog,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomNavbar(),
                const SizedBox(height: 20),

                // Welcome Section
                // _buildWelcomeSection(),
                // if (_userData != null) const SizedBox(height: 20),

                // Search Bar
                // _buildSearchBar(),
                // const SizedBox(height: 24),

                // Featured Property
                _buildFeaturedProperty(),
                const SizedBox(height: 32),

                // Popular Properties
                _buildPropertyList(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomFooter(
        onExploreTap: () {
          // Already on main screen
        },
        onGalleryTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const GalleryScreen()),
          );
        },
        onWishlistTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WishlistScreen()),
          );
        },
        onProfileTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
      ),
    );
  }
}
