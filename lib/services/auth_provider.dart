import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  MiseUser? _currentUser;
  Subscription? _activeSubscription;

  MiseUser? get currentUser => _currentUser;
  Subscription? get activeSubscription => _activeSubscription;

  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.phoneNumber?.contains('9666350033') ?? false;

  AuthProvider() {
    _init();
  }

  void _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('bypass_phone');
    
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.session?.user != null) {
        _syncProfile();
      } else if (savedPhone != null && _currentUser == null) {
        // Auto-restore dev bypass if no real session exists
        devBypassLogin(savedPhone);
      } else {
        if (_currentUser == null || _supabase.auth.currentUser == null) {
          _currentUser = null;
          _activeSubscription = null;
          notifyListeners();
        }
      }
    });

    if (savedPhone != null && _currentUser == null) {
      await devBypassLogin(savedPhone);
    }
  }

  Future<void> devBypassLogin(String phone) async {
    debugPrint("DEV: Bypassing authentication for $phone...");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bypass_phone', phone);

    // Try to sync real profile if it exists in Supabase for this dummy ID
    // or create a mock if the database is fresh.
    _currentUser = MiseUser(
      id: '00000000-0000-0000-0000-000000000000',
      fullName: 'Dev User',
      phoneNumber: phone,
    );
    
    // Attempt to sync real data from DB for this user
    await _syncProfileForDev();

    _activeSubscription = Subscription(
      id: 'mock-sub',
      userId: _currentUser!.id,
      status: SubscriptionStatus.active,
      mealsRemaining: 24,
      startDate: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> _syncProfileForDev() async {
    try {
      final profileData = await _supabase.from('users').select().eq('id', '00000000-0000-0000-0000-000000000000').maybeSingle();
      if (profileData != null) {
        _currentUser = MiseUser.fromJson(profileData);
      }
    } catch (e) {
      debugPrint("Error sync profile for dev: $e");
    }
  }

  Future<void> sendOTP(String phone) async {
    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
    await _supabase.auth.signInWithOtp(phone: formattedPhone, shouldCreateUser: true);
  }

  Future<void> verifyOTP(String phone, String token) async {
    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
    await _supabase.auth.verifyOTP(phone: formattedPhone, token: token, type: OtpType.sms);
    await _syncProfile();
  }

  Future<void> _syncProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final profileData = await _supabase.from('users').select().eq('id', user.id).maybeSingle();
      if (profileData != null) _currentUser = MiseUser.fromJson(profileData);
      final subData = await _supabase.from('subscriptions').select().eq('user_id', user.id).eq('status', 'active').maybeSingle();
      if (subData != null) _activeSubscription = Subscription.fromJson(subData);
      notifyListeners();
    } catch (e) {
      debugPrint("Error sync profile: $e");
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bypass_phone');
    await _supabase.auth.signOut();
    _currentUser = null;
    _activeSubscription = null;
    notifyListeners();
  }

  void updateLocalPreference(String pref) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(defaultPreference: pref);
      notifyListeners();
    }
  }

  void setCurrentUser(MiseUser user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> addOrUpdateAddress(UserAddress address) async {
    if (_currentUser != null) {
      final updatedAddresses = List<UserAddress>.from(_currentUser!.addresses);
      final index = updatedAddresses.indexWhere((a) => a.tag == address.tag);
      if (index >= 0) {
        updatedAddresses[index] = address;
      } else {
        updatedAddresses.add(address);
      }
      
      await _supabase.from('users').update({
        'addresses': updatedAddresses.map((a) => a.toJson()).toList(),
      }).eq('id', _currentUser!.id);
      
      _currentUser = _currentUser!.copyWith(addresses: updatedAddresses);
      notifyListeners();
    }
  }

  Future<void> removeAddress(String tag) async {
    if (_currentUser != null) {
      final updatedAddresses = _currentUser!.addresses.where((a) => a.tag != tag).toList();
      await _supabase.from('users').update({
        'addresses': updatedAddresses.map((a) => a.toJson()).toList(),
      }).eq('id', _currentUser!.id);
      
      _currentUser = _currentUser!.copyWith(addresses: updatedAddresses);
      notifyListeners();
    }
  }

  Future<void> updateAddressTag(String tag) async {
    if (_currentUser != null) {
      await _supabase.from('users').update({'selected_address_tag': tag}).eq('id', _currentUser!.id);
      _currentUser = _currentUser!.copyWith(selectedAddressTag: tag);
      notifyListeners();
    }
  }

  // Deprecated: used for legacy office_address column
  Future<void> updateUserAddress(String address) async {
    if (_currentUser != null) {
      await addOrUpdateAddress(UserAddress(tag: _currentUser!.selectedAddressTag, address: address));
    }
  }
}
