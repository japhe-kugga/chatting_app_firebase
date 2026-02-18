import 'package:chatting_app_firebase/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String _prefKey = 'chatBackgroundColor';
  Color? _selectedColor;

  final List<Color> _colors = const [
    // Soft neutral / pastel options
    Color(0xFFF5F7FA), //
    Color(0xFFE8F0FF), //
    Color(0xFFF0FFF4), //
    Color(0xFFFDF6E8), //

    // soft colors
    Color(0xFF2B4C7E), // Soft Deep Blue
    Color(0xFF8B9A5B), // Calm Olive Green
    Color(0xFF2F3437), // Charcoal Grey
    Color(0xFFFFB07C), // Warm Sunset Orange
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedColor();
  }

  Future<void> _loadSelectedColor() async {
    // 1. Load from SharedPreferences first (fastest)
    final prefs = await SharedPreferences.getInstance();
    final int? localColorValue = prefs.getInt(_prefKey);
    if (localColorValue != null && mounted) {
      setState(() {
        _selectedColor = Color(localColorValue);
      });
    }

    // 2. Then load from Firestore (source of truth) and update if necessary
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final snapshot =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (snapshot.exists &&
            snapshot.data()!.containsKey('chatBackgroundColor')) {
          final int cloudColorValue = snapshot.data()!['chatBackgroundColor'];

          // Update local state if different
          if (mounted && cloudColorValue != localColorValue) {
            setState(() {
              _selectedColor = Color(cloudColorValue);
            });
            // Update local prefs to match cloud
            await prefs.setInt(_prefKey, cloudColorValue);
          }
        }
      } catch (e) {
        debugPrint('Error loading color from Firestore: $e');
      }
    }
  }

  Future<void> _saveColor(int colorValue) async {
    // Save to Firestore
    await ChatService().saveChatBackgroundColor(colorValue);

    // Also save to local prefs as fallback/cache if desired, but Firestore is source of truth
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, colorValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.grey,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Chat Background',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._colors.map((color) {
            final bool selected = _selectedColor == color;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: selected
                    ? BorderSide(
                        color: Theme.of(context).colorScheme.primary, width: 2)
                    : BorderSide.none,
              ),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: color),
                title: Text(
                  selected ? 'Selected' : 'Choose background',
                  style: TextStyle(
                    color:
                        selected ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                  _saveColor(color.toARGB32());
                },
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text(
            'Preview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: _selectedColor ?? Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(child: Text('Chat preview')),
          ),
        ],
      ),
    );
  }
}
