import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<Map<String, TextEditingController>> _addressControllers = [];
  String _preference = 'Veg';
  String _selectedTag = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start with one default address entry
    _addAddressField(tag: 'Home');
  }

  void _addAddressField({String tag = '', String address = ''}) {
    setState(() {
      _addressControllers.add({
        'tag': TextEditingController(text: tag),
        'address': TextEditingController(text: address),
      });
      if (_selectedTag.isEmpty) _selectedTag = tag;
    });
  }

  void _removeAddressField(int index) {
    if (_addressControllers.length > 1) {
      setState(() {
        if (_selectedTag == _addressControllers[index]['tag']!.text) {
          _selectedTag = _addressControllers[index == 0 ? 1 : 0]['tag']!.text;
        }
        _addressControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Complete Profile", style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tell us more about yourself to personalize your experience.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              _buildSectionTitle("Personal Info"),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration("Full Name", Icons.person_outline),
                validator: (v) => v!.isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle("Addresses"),
                  TextButton.icon(
                    onPressed: () => _addAddressField(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add Another"),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text("Add tags like 'Home', 'Office', or even 'Friend's Place'", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _addressControllers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _addressControllers[index]['tag'],
                                decoration: _inputDecoration("Tag (e.g. Home, Office)", Icons.tag),
                                validator: (v) => v!.isEmpty ? "Required" : null,
                                onChanged: (val) {
                                  if (index == 0 && _selectedTag.isEmpty) {
                                     setState(() => _selectedTag = val);
                                  }
                                },
                              ),
                            ),
                            if (_addressControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _removeAddressField(index),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressControllers[index]['address'],
                          decoration: _inputDecoration("Full Address", Icons.location_on_outlined),
                          maxLines: 2,
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() => _selectedTag = _addressControllers[index]['tag']!.text),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: _addressControllers[index]['tag']!.text,
                                groupValue: _selectedTag,
                                onChanged: (val) => setState(() => _selectedTag = val!),
                                activeColor: AppTheme.primaryColor,
                              ),
                              const Text("Set as primary", style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              _buildSectionTitle("Food Preference"),
              const SizedBox(height: 16),
              _buildPreferenceToggle(),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Finish Setup"),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildPreferenceToggle() {
    return Row(
      children: [
        Expanded(child: _buildPrefButton('Veg')),
        const SizedBox(width: 16),
        Expanded(child: _buildPrefButton('Non-Veg')),
      ],
    );
  }

  Widget _buildPrefButton(String pref) {
    final isSelected = _preference == pref;
    return GestureDetector(
      onTap: () => setState(() => _preference = pref),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? (pref == 'Veg' ? Colors.green : Colors.red) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            pref,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        final List<UserAddress> addresses = _addressControllers.map((c) {
          return UserAddress(tag: c['tag']!.text, address: c['address']!.text);
        }).toList();

        // Update user in Supabase
        await Supabase.instance.client.from('users').update({
          'full_name': _nameController.text,
          'addresses': addresses.map((a) => a.toJson()).toList(),
          'selected_address_tag': _selectedTag.isEmpty ? (addresses.isNotEmpty ? addresses[0].tag : 'Home') : _selectedTag,
          'default_preference': _preference,
          'onboarding_completed': true,
        }).eq('id', auth.currentUser!.id);

        // Update local user state
        final updatedUser = auth.currentUser!.copyWith(
          fullName: _nameController.text,
          addresses: addresses,
          selectedAddressTag: _selectedTag.isEmpty ? (addresses.isNotEmpty ? addresses[0].tag : 'Home') : _selectedTag,
          defaultPreference: _preference,
          onboardingCompleted: true,
        );
        auth.setCurrentUser(updatedUser);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
