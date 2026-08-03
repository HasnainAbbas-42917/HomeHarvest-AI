import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:convert';
import 'main.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userPhone;

  const ProfilePage({
    super.key,
    this.userName = '',
    this.userEmail = '',
    this.userPhone = '',
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();
  late String _currentName;
  late String _currentPhone;

  static const String _baseUrl = 'http://localhost:5000';

  @override
  void initState() {
    super.initState();
    _currentName = widget.userName;
    _currentPhone = widget.userPhone;
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'profile_image_${widget.userEmail}';
    final base64String = prefs.getString(key);
    if (base64String != null && mounted) {
      setState(() => _profileImageBytes = base64Decode(base64String));
    }
  }

  Future<void> _saveProfileImage(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'profile_image_${widget.userEmail}';
    await prefs.setString(key, base64Encode(bytes));
  }

  Future<void> _removeProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'profile_image_${widget.userEmail}';
    await prefs.remove(key);
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              const Text('Change Profile Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(color: Color(0xFFE8F5E8), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF4A7C4A)),
                ),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Use your camera'),
                onTap: () async {
                  Navigator.pop(context);
                  await _selectImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(color: Color(0xFFE8F5E8), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library, color: Color(0xFF4A7C4A)),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pick from your photos'),
                onTap: () async {
                  Navigator.pop(context);
                  await _selectImage(ImageSource.gallery);
                },
              ),
              if (_profileImageBytes != null)
                ListTile(
                  leading: Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline, color: Color(0xFFE74C3C)),
                  ),
                  title: const Text('Remove Photo',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFE74C3C))),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                    setState(() => _profileImageBytes = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      await _saveProfileImage(bytes);
      setState(() => _profileImageBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showChangePassword() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isLoading = false;
    bool currentVerified = false;
    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Change Password',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
                const SizedBox(height: 8),
                Text(
                  currentVerified ? 'Enter your new password below.' : 'Enter your current password to continue.',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),

                // Step 1: Current Password
                _buildPasswordField(
                  controller: currentPassController,
                  label: 'Current Password',
                  show: showCurrent,
                  readOnly: currentVerified,
                  onToggle: () => setModalState(() => showCurrent = !showCurrent),
                ),

                if (!currentVerified) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        if (currentPassController.text.trim().isEmpty) {
                          _showSnackbar(context, 'Please enter your current password.', isError: true);
                          return;
                        }
                        setModalState(() => isLoading = true);
                        try {
                          final res = await http.post(
                            Uri.parse('$_baseUrl/verify-password'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({'email': widget.userEmail, 'password': currentPassController.text.trim()}),
                          ).timeout(const Duration(seconds: 15));
                          setModalState(() => isLoading = false);
                          final data = jsonDecode(res.body);
                          if (res.statusCode == 200 && data['match'] == true) {
                            setModalState(() => currentVerified = true);
                          } else {
                            _showSnackbar(context, data['message'] ?? 'Incorrect password.', isError: true);
                          }
                        } catch (e) {
                          setModalState(() => isLoading = false);
                          _showSnackbar(context, 'Cannot connect to server.', isError: true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5233),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Verify Password',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],

                // Step 2: New Password fields (shown after verification)
                if (currentVerified) ...[
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: newPassController,
                    label: 'New Password',
                    show: showNew,
                    onToggle: () => setModalState(() => showNew = !showNew),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: confirmPassController,
                    label: 'Confirm New Password',
                    show: showConfirm,
                    onToggle: () => setModalState(() => showConfirm = !showConfirm),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        final newPass = newPassController.text.trim();
                        final confirmPass = confirmPassController.text.trim();
                        if (newPass.length < 8) {
                          _showSnackbar(context, 'Password must be at least 8 characters.', isError: true);
                          return;
                        }
                        if (newPass != confirmPass) {
                          _showSnackbar(context, 'Passwords do not match.', isError: true);
                          return;
                        }
                        setModalState(() => isLoading = true);
                        try {
                          final res = await http.post(
                            Uri.parse('$_baseUrl/change-password'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({'email': widget.userEmail, 'new_password': newPass}),
                          ).timeout(const Duration(seconds: 15));
                          setModalState(() => isLoading = false);
                          if (res.statusCode == 200) {
                            if (mounted) Navigator.pop(context);
                            _showSnackbar(context, 'Password changed successfully!', isError: false);
                          } else {
                            final msg = jsonDecode(res.body)['message'] ?? 'Update failed.';
                            _showSnackbar(context, msg, isError: true);
                          }
                        } catch (e) {
                          setModalState(() => isLoading = false);
                          _showSnackbar(context, 'Cannot connect to server.', isError: true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5233),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Update Password',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback onToggle,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? const Color(0xFFF0F7F0) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: readOnly ? const Color(0xFF4A7C4A) : const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: controller,
            obscureText: !show,
            readOnly: readOnly,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock_outline,
                  color: readOnly ? const Color(0xFF4A7C4A) : const Color(0xFF4A7C4A), size: 20),
              suffixIcon: readOnly
                  ? const Icon(Icons.check_circle, color: Color(0xFF4A7C4A), size: 20)
                  : IconButton(
                      icon: Icon(show ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: const Color(0xFF9CA3AF), size: 20),
                      onPressed: onToggle,
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: TextStyle(
                color: readOnly ? const Color(0xFF4A7C4A) : const Color(0xFF1A2E1A), fontSize: 15),
          ),
        ),
      ],
    );
  }

  void _showSnackbar(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(message,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF4A7C4A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showEditProfile() {
    final nameController = TextEditingController(text: _currentName);
    final phoneController = TextEditingController(text: _currentPhone);
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Edit Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
                const SizedBox(height: 24),
                _buildEditField(
                  controller: nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 16),
                _buildEditField(
                  controller: TextEditingController(text: widget.userEmail),
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  readOnly: true,
                  hint: 'Email cannot be changed',
                ),
                const SizedBox(height: 16),
                _buildEditField(
                  controller: phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Row(children: [
                            Icon(Icons.error_outline, color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Expanded(child: Text('Name cannot be empty.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                          ]),
                          backgroundColor: const Color(0xFFD32F2F),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 3),
                        ));
                        return;
                      }
                      setModalState(() => isLoading = true);
                      try {
                        final response = await http.post(
                          Uri.parse('$_baseUrl/update-profile'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({'email': widget.userEmail, 'name': name, 'phone': phone}),
                        ).timeout(const Duration(seconds: 15));
                        if (!mounted) return;
                        setModalState(() => isLoading = false);
                        if (response.statusCode == 200) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('user_name', name);
                          await prefs.setString('user_phone', phone);
                          setState(() {
                            _currentName = name;
                            _currentPhone = phone;
                          });
                          if (mounted) Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Row(children: [
                              Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
                              SizedBox(width: 12),
                              Expanded(child: Text('Profile updated successfully!',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                            ]),
                            backgroundColor: const Color(0xFF4A7C4A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 3),
                          ));
                        } else {
                          final msg = jsonDecode(response.body)['message'] ?? 'Update failed.';
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Row(children: [
                              const Icon(Icons.error_outline, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Expanded(child: Text(msg,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                            ]),
                            backgroundColor: const Color(0xFFD32F2F),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 3),
                          ));
                        }
                      } catch (e) {
                        setModalState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Row(children: [
                            Icon(Icons.error_outline, color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Expanded(child: Text('Cannot connect to server.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                          ]),
                          backgroundColor: const Color(0xFFD32F2F),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 3),
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5233),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? const Color(0xFFF5F5F5) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            decoration: InputDecoration(
              prefixIcon: Icon(icon,
                  color: readOnly ? const Color(0xFFB5BAC1) : const Color(0xFF4A7C4A), size: 20),
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFB5BAC1), fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: TextStyle(
                color: readOnly ? const Color(0xFF9CA3AF) : const Color(0xFF1A2E1A), fontSize: 15),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = _currentName.isNotEmpty
        ? _currentName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2E1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
                    ],
                  ),
                  child: ClipOval(
                    child: _profileImageBytes != null
                        ? Image.memory(_profileImageBytes!, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFF2D5233),
                            child: Center(
                              child: Text(initials,
                                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D5233),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_currentName.isNotEmpty ? _currentName : 'User',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
            const SizedBox(height: 4),
            Text(widget.userEmail.isNotEmpty ? widget.userEmail : '',
                style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickProfileImage,
              child: const Text('Tap camera icon to change photo',
                  style: TextStyle(fontSize: 12, color: Color(0xFF4A7C4A), fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildMenuItem(context,
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF4A7C4A),
                    iconBgColor: const Color(0xFFE8F5E8),
                    title: 'Edit Profile',
                    onTap: _showEditProfile,
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(context,
                    icon: Icons.lock_outline,
                    iconColor: const Color(0xFF4A7C4A),
                    iconBgColor: const Color(0xFFE8F5E8),
                    title: 'Change Password',
                    onTap: _showChangePassword,
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(context,
                    icon: Icons.settings_outlined,
                    iconColor: const Color(0xFF4A7C4A),
                    iconBgColor: const Color(0xFFE8F5E8),
                    title: 'Settings',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings coming soon!'), backgroundColor: Color(0xFF4A7C4A))),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(context,
                    icon: Icons.headset_mic_outlined,
                    iconColor: const Color(0xFF4A7C4A),
                    iconBgColor: const Color(0xFFE8F5E8),
                    title: 'Help & Support',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help & Support coming soon!'), backgroundColor: Color(0xFF4A7C4A))),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(context,
                    icon: Icons.logout,
                    iconColor: const Color(0xFFE74C3C),
                    iconBgColor: const Color(0xFFFFEBEE),
                    title: 'Logout',
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A2E1A)))),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 24),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Logout',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
          content: const Text('Are you sure you want to logout?',
              style: TextStyle(color: Color(0xFF6B7280))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text('Logged out successfully'), backgroundColor: Color(0xFF4A7C4A)),
                );
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}
