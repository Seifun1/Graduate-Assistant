import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_model.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

class AnalyticsData {
  final String metric;
  final dynamic value;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AnalyticsData({
    required this.metric,
    required this.value,
    required this.timestamp,
    this.metadata,
  });
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final _supabase = SupabaseService();

  // Track user activity
  Future<void> trackEvent({
    required String userId,
    required String eventName,
    Map<String, dynamic>? properties,
  }) async {
    try {
      await _supabase.client.from('analytics_events').insert({
        'user_id': userId,
        'event_name': eventName,
        'properties': properties,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail analytics to not impact user experience
    }
  }

  // Get application success rate
  Future<Map<String, dynamic>> getApplicationSuccessRate(String userId) async {
    try {
      final applications = await _supabase.client
          .from('job_applications')
          .select('status')
          .eq('user_id', userId);

      final total = applications.length;
      if (total == 0) {
        return {
          'total': 0,
          'success_rate': 0.0,
          'accepted': 0,
          'rejected': 0,
          'pending': 0,
        };
      }

      int accepted = 0;
      int rejected = 0;
      int pending = 0;

      for (final app in applications) {
        final status = app['status'] as String;
        switch (status) {
          case 'accepted':
            accepted++;
            break;
          case 'rejected':
            rejected++;
            break;
          default:
            pending++;
            break;
        }
      }

      final successRate = total > 0 ? (accepted / total) * 100 : 0.0;

      return {
        'total': total,
        'success_rate': successRate,
        'accepted': accepted,
        'rejected': rejected,
        'pending': pending,
      };
    } catch (e) {
      throw Exception('Failed to get application success rate: ${e.toString()}');
    }
  }

  // Get job search analytics
  Future<Map<String, dynamic>> getJobSearchAnalytics(String userId) async {
    try {
      // Get search history from analytics events
      final searchEvents = await _supabase.client
          .from('analytics_events')
          .select('properties, timestamp')
          .eq('user_id', userId)
          .eq('event_name', 'job_search')
          .order('timestamp', ascending: false)
          .limit(100);

      final searchTerms = <String, int>{};
      final searchLocations = <String, int>{};
      final searchTypes = <String, int>{};

      for (final event in searchEvents) {
        final props = event['properties'] as Map<String, dynamic>?;
        if (props != null) {
          // Track search terms
          final term = props['search_term'] as String?;
          if (term != null && term.isNotEmpty) {
            searchTerms[term] = (searchTerms[term] ?? 0) + 1;
          }

          // Track search locations
          final location = props['location'] as String?;
          if (location != null && location.isNotEmpty) {
            searchLocations[location] = (searchLocations[location] ?? 0) + 1;
          }

          // Track job types
          final jobType = props['job_type'] as String?;
          if (jobType != null && jobType.isNotEmpty) {
            searchTypes[jobType] = (searchTypes[jobType] ?? 0) + 1;
          }
        }
      }

      return {
        'total_searches': searchEvents.length,
        'top_search_terms': _getTopEntries(searchTerms, 5),
        'top_locations': _getTopEntries(searchLocations, 5),
        'top_job_types': _getTopEntries(searchTypes, 5),
      };
    } catch (e) {
      throw Exception('Failed to get job search analytics: ${e.toString()}');
    }
  }

  // Get profile completion analytics
  Future<Map<String, dynamic>> getProfileAnalytics(String userId) async {
    try {
      final profile = await _supabase.getUserProfile(userId);
      if (profile == null) {
        return {'completion_percentage': 0.0, 'missing_fields': []};
      }

      final user = UserModel.fromJson(profile);
      final completionPercentage = user.profileCompletionPercentage;
      
      final missingFields = <String>[];
      if (user.firstName?.isEmpty != false) missingFields.add('First Name');
      if (user.lastName?.isEmpty != false) missingFields.add('Last Name');
      if (user.phoneNumber?.isEmpty != false) missingFields.add('Phone Number');
      if (user.bio?.isEmpty != false) missingFields.add('Bio');
      if (user.location?.isEmpty != false) missingFields.add('Location');
      if (user.university?.isEmpty != false) missingFields.add('University');
      if (user.degree?.isEmpty != false) missingFields.add('Degree');
      if (user.skills?.isEmpty != false) missingFields.add('Skills');
      if (user.resumeUrl?.isEmpty != false) missingFields.add('Resume');

      return {
        'completion_percentage': completionPercentage,
        'missing_fields': missingFields,
        'is_complete': completionPercentage >= 80,
      };
    } catch (e) {
      throw Exception('Failed to get profile analytics: ${e.toString()}');
    }
  }

  // Get time-based application analytics
  Future<Map<String, dynamic>> getApplicationTrends(String userId, {int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      
      final applications = await _supabase.client
          .from('job_applications')
          .select('applied_date, status')
          .eq('user_id', userId)
          .gte('applied_date', startDate.toIso8601String())
          .order('applied_date');

      final dailyApplications = <String, int>{};
      final statusTrends = <String, Map<String, int>>{};

      for (final app in applications) {
        final appliedDate = DateTime.parse(app['applied_date']);
        final dateKey = '${appliedDate.year}-${appliedDate.month.toString().padLeft(2, '0')}-${appliedDate.day.toString().padLeft(2, '0')}';
        final status = app['status'] as String;

        // Count daily applications
        dailyApplications[dateKey] = (dailyApplications[dateKey] ?? 0) + 1;

        // Track status trends
        if (!statusTrends.containsKey(dateKey)) {
          statusTrends[dateKey] = {};
        }
        statusTrends[dateKey]![status] = (statusTrends[dateKey]![status] ?? 0) + 1;
      }

      return {
        'daily_applications': dailyApplications,
        'status_trends': statusTrends,
        'total_applications': applications.length,
        'average_per_day': applications.length / days,
      };
    } catch (e) {
      throw Exception('Failed to get application trends: ${e.toString()}');
    }
  }

  // Get skill-based job matching analytics
  Future<Map<String, dynamic>> getSkillMatchingAnalytics(String userId) async {
    try {
      final profile = await _supabase.getUserProfile(userId);
      if (profile == null) {
        return {'user_skills': [], 'skill_demand': {}, 'recommendations': []};
      }

      final userSkills = profile['skills'] != null 
          ? List<String>.from(profile['skills']) 
          : <String>[];

      // Get job skill requirements from recent jobs
      final recentJobs = await _supabase.client
          .from('jobs')
          .select('skills')
          .eq('is_active', true)
          .order('posted_date', ascending: false)
          .limit(1000);

      final skillDemand = <String, int>{};
      for (final job in recentJobs) {
        final jobSkills = job['skills'] != null 
            ? List<String>.from(job['skills']) 
            : <String>[];
        
        for (final skill in jobSkills) {
          skillDemand[skill] = (skillDemand[skill] ?? 0) + 1;
        }
      }

      // Find skill gaps and recommendations
      final topDemandSkills = _getTopEntries(skillDemand, 20);
      final recommendations = topDemandSkills
          .where((entry) => !userSkills.contains(entry['skill']))
          .take(10)
          .toList();

      return {
        'user_skills': userSkills,
        'skill_demand': topDemandSkills,
        'recommendations': recommendations,
        'skill_match_percentage': _calculateSkillMatchPercentage(userSkills, skillDemand),
      };
    } catch (e) {
      throw Exception('Failed to get skill matching analytics: ${e.toString()}');
    }
  }

  // Get response time analytics
  Future<Map<String, dynamic>> getResponseTimeAnalytics(String userId) async {
    try {
      final applications = await _supabase.client
          .from('job_applications')
          .select('applied_date, last_updated, status')
          .eq('user_id', userId)
          .neq('status', 'draft')
          .order('applied_date', ascending: false);

      final responseTimes = <int>[];
      int totalResponses = 0;

      for (final app in applications) {
        final appliedDate = DateTime.parse(app['applied_date']);
        final lastUpdated = app['last_updated'] != null 
            ? DateTime.parse(app['last_updated'])
            : null;
        
        if (lastUpdated != null && app['status'] != 'submitted') {
          final responseTime = lastUpdated.difference(appliedDate).inDays;
          responseTimes.add(responseTime);
          totalResponses++;
        }
      }

      if (responseTimes.isEmpty) {
        return {
          'average_response_time': 0,
          'fastest_response': 0,
          'slowest_response': 0,
          'total_responses': 0,
        };
      }

      responseTimes.sort();
      
      return {
        'average_response_time': responseTimes.reduce((a, b) => a + b) / responseTimes.length,
        'fastest_response': responseTimes.first,
        'slowest_response': responseTimes.last,
        'total_responses': totalResponses,
        'median_response_time': responseTimes[responseTimes.length ~/ 2],
      };
    } catch (e) {
      throw Exception('Failed to get response time analytics: ${e.toString()}');
    }
  }

  // Get comprehensive dashboard data
  Future<Map<String, dynamic>> getDashboardAnalytics(String userId) async {
    try {
      final results = await Future.wait([
        getApplicationSuccessRate(userId),
        getJobSearchAnalytics(userId),
        getProfileAnalytics(userId),
        getApplicationTrends(userId),
        getSkillMatchingAnalytics(userId),
        getResponseTimeAnalytics(userId),
      ]);

      return {
        'application_success': results[0],
        'job_search': results[1],
        'profile': results[2],
        'application_trends': results[3],
        'skill_matching': results[4],
        'response_times': results[5],
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get dashboard analytics: ${e.toString()}');
    }
  }

  // Helper method to get top entries from a map
  List<Map<String, dynamic>> _getTopEntries(Map<String, int> data, int limit) {
    final entries = data.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    
    return entries
        .take(limit)
        .map((entry) => {
          'skill': entry.key,
          'count': entry.value,
        })
        .toList();
  }

  // Calculate skill match percentage
  double _calculateSkillMatchPercentage(List<String> userSkills, Map<String, int> skillDemand) {
    if (userSkills.isEmpty || skillDemand.isEmpty) return 0.0;

    int matchingSkills = 0;
    int totalDemandedSkills = skillDemand.keys.length;

    for (final skill in userSkills) {
      if (skillDemand.containsKey(skill)) {
        matchingSkills++;
      }
    }

    return (matchingSkills / totalDemandedSkills) * 100;
  }

  // Track specific events
  Future<void> trackJobView(String userId, String jobId) async {
    await trackEvent(
      userId: userId,
      eventName: 'job_view',
      properties: {'job_id': jobId},
    );
  }

  Future<void> trackJobApplication(String userId, String jobId) async {
    await trackEvent(
      userId: userId,
      eventName: 'job_application',
      properties: {'job_id': jobId},
    );
  }

  Future<void> trackJobSearch(String userId, {
    String? searchTerm,
    String? location,
    String? jobType,
  }) async {
    await trackEvent(
      userId: userId,
      eventName: 'job_search',
      properties: {
        'search_term': searchTerm,
        'location': location,
        'job_type': jobType,
      },
    );
  }

  Future<void> trackProfileUpdate(String userId, String section) async {
    await trackEvent(
      userId: userId,
      eventName: 'profile_update',
      properties: {'section': section},
    );
  }

  Future<void> trackResumeGeneration(String userId, String resumeId) async {
    await trackEvent(
      userId: userId,
      eventName: 'resume_generation',
      properties: {'resume_id': resumeId},
    );
  }
}