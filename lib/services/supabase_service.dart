import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _supabase;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL', // Replace with your Supabase URL
      anonKey: 'YOUR_SUPABASE_ANON_KEY', // Replace with your Supabase anon key
    );

    _supabase = Supabase.instance.client;
    _initialized = true;
  }

  SupabaseClient get client => _supabase;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    final auth = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (auth.user != null) {
      // Insert additional user data into the profiles table
      await _supabase.from('profiles').insert({
        'id': auth.user!.id,
        'email': email,
        ...userData,
      });
    }

    return auth;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return response;
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _supabase
        .from('profiles')
        .update(data)
        .eq('id', userId);
  }

  // Enhanced profile management methods
  Future<void> updateProfileCompleteness(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile != null) {
        // Calculate completion percentage based on filled fields
        int filledFields = 0;
        int totalFields = 15;
        
        if (profile['first_name']?.isNotEmpty == true) filledFields++;
        if (profile['last_name']?.isNotEmpty == true) filledFields++;
        if (profile['phone_number']?.isNotEmpty == true) filledFields++;
        if (profile['bio']?.isNotEmpty == true) filledFields++;
        if (profile['location']?.isNotEmpty == true) filledFields++;
        if (profile['university']?.isNotEmpty == true) filledFields++;
        if (profile['degree']?.isNotEmpty == true) filledFields++;
        if (profile['graduation_year']?.isNotEmpty == true) filledFields++;
        if (profile['field_of_study']?.isNotEmpty == true) filledFields++;
        if (profile['gpa'] != null) filledFields++;
        if (profile['skills']?.isNotEmpty == true) filledFields++;
        if (profile['interests']?.isNotEmpty == true) filledFields++;
        if (profile['linkedin_url']?.isNotEmpty == true) filledFields++;
        if (profile['resume_url']?.isNotEmpty == true) filledFields++;
        if (profile['profile_image_url']?.isNotEmpty == true) filledFields++;
        
        final completionPercentage = (filledFields / totalFields) * 100;
        final isComplete = completionPercentage >= 80; // 80% threshold
        
        await _supabase
            .from('profiles')
            .update({
              'is_profile_complete': isComplete,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
      }
    } catch (e) {
      // Ignore errors in this helper method
    }
  }

  // Add skill to user profile
  Future<void> addSkill(String userId, String skill) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile != null) {
        final currentSkills = profile['skills'] != null 
            ? List<String>.from(profile['skills']) 
            : <String>[];
        
        if (!currentSkills.contains(skill)) {
          currentSkills.add(skill);
          await updateUserProfile(userId, {'skills': currentSkills});
          await updateProfileCompleteness(userId);
        }
      }
    } catch (e) {
      throw Exception('Failed to add skill: ${e.toString()}');
    }
  }

  // Remove skill from user profile
  Future<void> removeSkill(String userId, String skill) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile != null) {
        final currentSkills = profile['skills'] != null 
            ? List<String>.from(profile['skills']) 
            : <String>[];
        
        currentSkills.remove(skill);
        await updateUserProfile(userId, {'skills': currentSkills});
        await updateProfileCompleteness(userId);
      }
    } catch (e) {
      throw Exception('Failed to remove skill: ${e.toString()}');
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(String userId, String filePath) async {
    try {
      final file = File(filePath);
      final fileName = 'profile_$userId.${filePath.split('.').last}';
      
      await _supabase.storage
          .from('profiles')
          .upload(fileName, file);
      
      final imageUrl = _supabase.storage
          .from('profiles')
          .getPublicUrl(fileName);
      
      await updateUserProfile(userId, {'profile_image_url': imageUrl});
      await updateProfileCompleteness(userId);
      
      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  // Upload resume file
  Future<String> uploadResume(String userId, String filePath) async {
    try {
      final file = File(filePath);
      final fileName = 'resume_$userId.${filePath.split('.').last}';
      
      await _supabase.storage
          .from('resumes')
          .upload(fileName, file);
      
      final resumeUrl = _supabase.storage
          .from('resumes')
          .getPublicUrl(fileName);
      
      await updateUserProfile(userId, {'resume_url': resumeUrl});
      await updateProfileCompleteness(userId);
      
      return resumeUrl;
    } catch (e) {
      throw Exception('Failed to upload resume: ${e.toString()}');
    }
  }

  // Check if user is logged in
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;
} 