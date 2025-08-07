import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_model.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

class JobService {
  static final JobService _instance = JobService._internal();
  factory JobService() => _instance;
  JobService._internal();

  final _supabase = SupabaseService();

  // Get all jobs with filtering and pagination
  Future<List<JobModel>> getJobs({
    int page = 1,
    int limit = 20,
    String? search,
    List<JobType>? jobTypes,
    List<ExperienceLevel>? experienceLevels,
    String? location,
    double? minSalary,
    double? maxSalary,
    List<String>? skills,
    bool? isFeatured,
    String? sortBy = 'posted_date',
    bool ascending = false,
  }) async {
    try {
      var query = _supabase.client
          .from('jobs')
          .select()
          .eq('is_active', true);

      // Apply filters
      if (search != null && search.isNotEmpty) {
        query = query.or('title.ilike.%$search%,company.ilike.%$search%,description.ilike.%$search%');
      }

      if (jobTypes != null && jobTypes.isNotEmpty) {
        final typeNames = jobTypes.map((t) => t.name).toList();
        query = query.in_('job_type', typeNames);
      }

      if (experienceLevels != null && experienceLevels.isNotEmpty) {
        final levelNames = experienceLevels.map((l) => l.name).toList();
        query = query.in_('experience_level', levelNames);
      }

      if (location != null && location.isNotEmpty) {
        query = query.ilike('location', '%$location%');
      }

      if (minSalary != null) {
        query = query.gte('salary_min', minSalary);
      }

      if (maxSalary != null) {
        query = query.lte('salary_max', maxSalary);
      }

      if (skills != null && skills.isNotEmpty) {
        query = query.overlaps('skills', skills);
      }

      if (isFeatured != null) {
        query = query.eq('is_featured', isFeatured);
      }

      // Apply sorting
      query = query.order(sortBy, ascending: ascending);

      // Apply pagination
      final offset = (page - 1) * limit;
      query = query.range(offset, offset + limit - 1);

      final response = await query;
      return response.map((json) => JobModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch jobs: ${e.toString()}');
    }
  }

  // Get job by ID
  Future<JobModel?> getJobById(String jobId) async {
    try {
      final response = await _supabase.client
          .from('jobs')
          .select()
          .eq('id', jobId)
          .single();

      return JobModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch job: ${e.toString()}');
    }
  }

  // Get featured jobs
  Future<List<JobModel>> getFeaturedJobs({int limit = 10}) async {
    try {
      final response = await _supabase.client
          .from('jobs')
          .select()
          .eq('is_active', true)
          .eq('is_featured', true)
          .order('posted_date', ascending: false)
          .limit(limit);

      return response.map((json) => JobModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch featured jobs: ${e.toString()}');
    }
  }

  // Get recent jobs
  Future<List<JobModel>> getRecentJobs({int limit = 10}) async {
    try {
      final response = await _supabase.client
          .from('jobs')
          .select()
          .eq('is_active', true)
          .order('posted_date', ascending: false)
          .limit(limit);

      return response.map((json) => JobModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recent jobs: ${e.toString()}');
    }
  }

  // Get recommended jobs based on user profile
  Future<List<JobModel>> getRecommendedJobs(String userId, {int limit = 20}) async {
    try {
      // Get user profile to understand preferences
      final userProfile = await _supabase.getUserProfile(userId);
      if (userProfile == null) {
        return await getRecentJobs(limit: limit);
      }

      var query = _supabase.client
          .from('jobs')
          .select()
          .eq('is_active', true);

      // Filter by user's skills if available
      if (userProfile['skills'] != null) {
        final userSkills = List<String>.from(userProfile['skills']);
        query = query.overlaps('skills', userSkills);
      }

      // Filter by user's field of study
      if (userProfile['field_of_study'] != null) {
        query = query.or('title.ilike.%${userProfile['field_of_study']}%,description.ilike.%${userProfile['field_of_study']}%');
      }

      // Filter by user's location preference
      if (userProfile['location'] != null) {
        query = query.ilike('location', '%${userProfile['location']}%');
      }

      query = query
          .order('posted_date', ascending: false)
          .limit(limit);

      final response = await query;
      return response.map((json) => JobModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recommended jobs: ${e.toString()}');
    }
  }

  // Apply for a job
  Future<JobApplicationModel> applyForJob({
    required String jobId,
    required String userId,
    String? coverLetter,
    String? resumeUrl,
    String? notes,
  }) async {
    try {
      final applicationData = {
        'job_id': jobId,
        'user_id': userId,
        'status': ApplicationStatus.submitted.name,
        'cover_letter': coverLetter,
        'resume_url': resumeUrl,
        'notes': notes,
        'applied_date': DateTime.now().toIso8601String(),
      };

      final response = await _supabase.client
          .from('job_applications')
          .insert(applicationData)
          .select()
          .single();

      // Update job applications count
      await _supabase.client.rpc('increment_application_count', params: {
        'job_id': jobId,
      });

      return JobApplicationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to apply for job: ${e.toString()}');
    }
  }

  // Get user's job applications
  Future<List<JobApplicationModel>> getUserApplications(
    String userId, {
    ApplicationStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      var query = _supabase.client
          .from('job_applications')
          .select('''
            *,
            job:jobs(*)
          ''')
          .eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status.name);
      }

      // Apply pagination
      final offset = (page - 1) * limit;
      query = query
          .order('applied_date', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await query;
      return response.map((json) => JobApplicationModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch applications: ${e.toString()}');
    }
  }

  // Update application status
  Future<void> updateApplicationStatus(
    String applicationId,
    ApplicationStatus status, {
    String? notes,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'last_updated': DateTime.now().toIso8601String(),
      };

      if (notes != null) {
        updateData['notes'] = notes;
      }

      await _supabase.client
          .from('job_applications')
          .update(updateData)
          .eq('id', applicationId);
    } catch (e) {
      throw Exception('Failed to update application status: ${e.toString()}');
    }
  }

  // Save job for later
  Future<void> saveJob(String userId, String jobId) async {
    try {
      await _supabase.client.from('saved_jobs').insert({
        'user_id': userId,
        'job_id': jobId,
        'saved_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save job: ${e.toString()}');
    }
  }

  // Remove saved job
  Future<void> removeSavedJob(String userId, String jobId) async {
    try {
      await _supabase.client
          .from('saved_jobs')
          .delete()
          .eq('user_id', userId)
          .eq('job_id', jobId);
    } catch (e) {
      throw Exception('Failed to remove saved job: ${e.toString()}');
    }
  }

  // Get saved jobs
  Future<List<JobModel>> getSavedJobs(String userId) async {
    try {
      final response = await _supabase.client
          .from('saved_jobs')
          .select('''
            job:jobs(*)
          ''')
          .eq('user_id', userId)
          .order('saved_at', ascending: false);

      return response
          .map((item) => JobModel.fromJson(item['job']))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch saved jobs: ${e.toString()}');
    }
  }

  // Check if job is saved
  Future<bool> isJobSaved(String userId, String jobId) async {
    try {
      final response = await _supabase.client
          .from('saved_jobs')
          .select('id')
          .eq('user_id', userId)
          .eq('job_id', jobId);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get application statistics
  Future<Map<String, int>> getApplicationStats(String userId) async {
    try {
      final response = await _supabase.client
          .from('job_applications')
          .select('status')
          .eq('user_id', userId);

      final stats = <String, int>{
        'total': response.length,
        'submitted': 0,
        'underReview': 0,
        'interviewed': 0,
        'accepted': 0,
        'rejected': 0,
      };

      for (final app in response) {
        final status = app['status'] as String;
        switch (status) {
          case 'submitted':
            stats['submitted'] = (stats['submitted'] ?? 0) + 1;
            break;
          case 'underReview':
            stats['underReview'] = (stats['underReview'] ?? 0) + 1;
            break;
          case 'interviewed':
            stats['interviewed'] = (stats['interviewed'] ?? 0) + 1;
            break;
          case 'accepted':
            stats['accepted'] = (stats['accepted'] ?? 0) + 1;
            break;
          case 'rejected':
            stats['rejected'] = (stats['rejected'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to fetch application stats: ${e.toString()}');
    }
  }

  // Search jobs by skills
  Future<List<JobModel>> searchJobsBySkills(List<String> skills, {int limit = 20}) async {
    try {
      final response = await _supabase.client
          .from('jobs')
          .select()
          .eq('is_active', true)
          .overlaps('skills', skills)
          .order('posted_date', ascending: false)
          .limit(limit);

      return response.map((json) => JobModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search jobs by skills: ${e.toString()}');
    }
  }
}