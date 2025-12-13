import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Add this for kIsWeb
// Remove dart:io import for web compatibility
import '../services/auth_service.dart';
import '../widgets/custom_footer.dart';
import 'main_screen.dart';
import 'gallery_screen.dart';
import 'wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final data = await _authService.getUserData(user.uid);
        setState(() {
          userData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          isUpdating = true;
        });

        final user = _authService.currentUser;
        if (user != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('${user.uid}.jpg');

          // Use different upload methods for web vs mobile
          if (kIsWeb) {
            // For web: use bytes
            final bytes = await image.readAsBytes();
            await storageRef.putData(bytes);
          } else {
            // For mobile: use file path (you'll need to import dart:io conditionally)
            // This requires conditional imports which we'll handle below
            throw UnsupportedError(
                'Mobile file upload needs conditional import');
          }

          final downloadUrl = await storageRef.getDownloadURL();

          await _authService.updateUserProfile(
            uid: user.uid,
            profileImageUrl: downloadUrl,
          );

          await _loadUserData();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: $e')),
      );
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

  void _showEditDialog(String field, String currentValue) {
    final TextEditingController controller =
        TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${field.capitalize()}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.capitalize(),
            border: const OutlineInputBorder(),
          ),
          keyboardType: field == 'email'
              ? TextInputType.emailAddress
              : TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = controller.text.trim();
              if (newValue.isNotEmpty && newValue != currentValue) {
                Navigator.pop(context);
                await _updateUserField(field, newValue);
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserField(String field, String value) async {
    try {
      setState(() {
        isUpdating = true;
      });

      final user = _authService.currentUser;
      if (user != null) {
        await _authService.updateUserProfile(
          uid: user.uid,
          fullName: field == 'fullName' ? value : null,
          email: field == 'email' ? value : null,
          phoneNumber: field == 'phoneNumber' ? value : null,
        );

        if (field == 'email') {
          await user.updateEmail(value);
        }

        await _loadUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${field.capitalize()} updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating ${field}: $e')),
      );
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (isUpdating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text('Failed to load profile data'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Picture
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: userData!['profileImageUrl'] !=
                                          null &&
                                      userData!['profileImageUrl'].isNotEmpty
                                  ? NetworkImage(userData!['profileImageUrl'])
                                  : null,
                              child: userData!['profileImageUrl'] == null ||
                                      userData!['profileImageUrl'].isEmpty
                                  ? const Icon(Icons.person, size: 60)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickAndUploadImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        _buildEditableCard(
                          'Full Name',
                          userData!['fullName'] ?? 'Not set',
                          Icons.person,
                          'fullName',
                        ),
                        const SizedBox(height: 12),

                        _buildEditableCard(
                          'Email',
                          userData!['email'] ?? 'Not set',
                          Icons.email,
                          'email',
                        ),
                        const SizedBox(height: 12),

                        _buildEditableCard(
                          'Phone Number',
                          userData!['phoneNumber'] ?? 'Not set',
                          Icons.phone,
                          'phoneNumber',
                        ),
                        const SizedBox(height: 24),

                        // Account Information
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Member Since',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          userData!['createdAt'] != null
                                              ? _formatDate(
                                                  userData!['createdAt']
                                                      .toDate())
                                              : 'Unknown',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.home),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Account Type',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          userData!['isHost'] == true
                                              ? 'Host'
                                              : 'Guest',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text('Settings'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Navigate to settings screen
                          },
                        ),
                        const Divider(),

                        ListTile(
                          leading: const Icon(Icons.help),
                          title: const Text('Help Center'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Navigate to help center
                          },
                        ),
                        const Divider(),

                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Logout',
                              style: TextStyle(color: Colors.red)),
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: CustomFooter(
        onExploreTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
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
          // Already on profile screen
        },
      ),
    );
  }

  Widget _buildEditableCard(
      String title, String value, IconData icon, String field) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
        trailing: const Icon(Icons.edit),
        onTap: () => _showEditDialog(field, value),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

extension StringCapitalization on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
