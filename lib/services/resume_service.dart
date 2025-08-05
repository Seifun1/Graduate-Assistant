import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resume_model.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

class ResumeService {
  static final ResumeService _instance = ResumeService._internal();
  factory ResumeService() => _instance;
  ResumeService._internal();

  final _supabase = SupabaseService();

  // Create a new resume
  Future<ResumeModel> createResume({
    required String userId,
    required String title,
    required PersonalInfoModel personalInfo,
    String? summary,
    List<EducationModel>? education,
    List<ExperienceModel>? experience,
    List<String>? skills,
    List<ProjectModel>? projects,
    List<CertificationModel>? certifications,
    List<String>? languages,
    String? additionalInfo,
    String? templateId,
    bool isDefault = false,
  }) async {
    try {
      final resumeData = {
        'user_id': userId,
        'title': title,
        'personal_info': personalInfo.toJson(),
        'summary': summary,
        'education': education?.map((e) => e.toJson()).toList() ?? [],
        'experience': experience?.map((e) => e.toJson()).toList() ?? [],
        'skills': skills ?? [],
        'projects': projects?.map((e) => e.toJson()).toList() ?? [],
        'certifications': certifications?.map((e) => e.toJson()).toList() ?? [],
        'languages': languages ?? [],
        'additional_info': additionalInfo,
        'template_id': templateId,
        'is_default': isDefault,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // If this is set as default, unset other default resumes
      if (isDefault) {
        await _unsetDefaultResumes(userId);
      }

      final response = await _supabase.client
          .from('resumes')
          .insert(resumeData)
          .select()
          .single();

      return ResumeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create resume: ${e.toString()}');
    }
  }

  // Get user's resumes
  Future<List<ResumeModel>> getUserResumes(String userId) async {
    try {
      final response = await _supabase.client
          .from('resumes')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      return response.map((json) => ResumeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch resumes: ${e.toString()}');
    }
  }

  // Get resume by ID
  Future<ResumeModel?> getResumeById(String resumeId) async {
    try {
      final response = await _supabase.client
          .from('resumes')
          .select()
          .eq('id', resumeId)
          .single();

      return ResumeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch resume: ${e.toString()}');
    }
  }

  // Get default resume for user
  Future<ResumeModel?> getDefaultResume(String userId) async {
    try {
      final response = await _supabase.client
          .from('resumes')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      return response != null ? ResumeModel.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch default resume: ${e.toString()}');
    }
  }

  // Update resume
  Future<ResumeModel> updateResume(String resumeId, {
    String? title,
    PersonalInfoModel? personalInfo,
    String? summary,
    List<EducationModel>? education,
    List<ExperienceModel>? experience,
    List<String>? skills,
    List<ProjectModel>? projects,
    List<CertificationModel>? certifications,
    List<String>? languages,
    String? additionalInfo,
    String? templateId,
    bool? isDefault,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (personalInfo != null) updateData['personal_info'] = personalInfo.toJson();
      if (summary != null) updateData['summary'] = summary;
      if (education != null) updateData['education'] = education.map((e) => e.toJson()).toList();
      if (experience != null) updateData['experience'] = experience.map((e) => e.toJson()).toList();
      if (skills != null) updateData['skills'] = skills;
      if (projects != null) updateData['projects'] = projects.map((e) => e.toJson()).toList();
      if (certifications != null) updateData['certifications'] = certifications.map((e) => e.toJson()).toList();
      if (languages != null) updateData['languages'] = languages;
      if (additionalInfo != null) updateData['additional_info'] = additionalInfo;
      if (templateId != null) updateData['template_id'] = templateId;
      if (isDefault != null) updateData['is_default'] = isDefault;

      // If this is set as default, unset other default resumes
      if (isDefault == true) {
        final resume = await getResumeById(resumeId);
        if (resume != null) {
          await _unsetDefaultResumes(resume.userId);
        }
      }

      final response = await _supabase.client
          .from('resumes')
          .update(updateData)
          .eq('id', resumeId)
          .select()
          .single();

      return ResumeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update resume: ${e.toString()}');
    }
  }

  // Delete resume
  Future<void> deleteResume(String resumeId) async {
    try {
      await _supabase.client
          .from('resumes')
          .delete()
          .eq('id', resumeId);
    } catch (e) {
      throw Exception('Failed to delete resume: ${e.toString()}');
    }
  }

  // Duplicate resume
  Future<ResumeModel> duplicateResume(String resumeId, String newTitle) async {
    try {
      final originalResume = await getResumeById(resumeId);
      if (originalResume == null) {
        throw Exception('Resume not found');
      }

      return await createResume(
        userId: originalResume.userId,
        title: newTitle,
        personalInfo: originalResume.personalInfo,
        summary: originalResume.summary,
        education: originalResume.education,
        experience: originalResume.experience,
        skills: originalResume.skills,
        projects: originalResume.projects,
        certifications: originalResume.certifications,
        languages: originalResume.languages,
        additionalInfo: originalResume.additionalInfo,
        templateId: originalResume.templateId,
        isDefault: false,
      );
    } catch (e) {
      throw Exception('Failed to duplicate resume: ${e.toString()}');
    }
  }

  // Create resume from user profile
  Future<ResumeModel> createResumeFromProfile(String userId, String title) async {
    try {
      final userProfile = await _supabase.getUserProfile(userId);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final user = UserModel.fromJson(userProfile);
      
      final personalInfo = PersonalInfoModel(
        firstName: user.firstName ?? '',
        lastName: user.lastName ?? '',
        email: user.email,
        phone: user.phoneNumber,
        linkedinUrl: user.linkedinUrl,
        githubUrl: user.githubUrl,
        portfolioUrl: user.portfolioUrl,
      );

      final education = user.university != null ? [
        EducationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          institution: user.university!,
          degree: user.degree ?? '',
          fieldOfStudy: user.fieldOfStudy,
          graduationYear: user.graduationYear,
          gpa: user.gpa,
        )
      ] : <EducationModel>[];

      return await createResume(
        userId: userId,
        title: title,
        personalInfo: personalInfo,
        summary: user.bio,
        education: education,
        skills: user.skills,
        isDefault: true,
      );
    } catch (e) {
      throw Exception('Failed to create resume from profile: ${e.toString()}');
    }
  }

  // Add education to resume
  Future<void> addEducation(String resumeId, EducationModel education) async {
    try {
      final resume = await getResumeById(resumeId);
      if (resume == null) throw Exception('Resume not found');

      final updatedEducation = [...resume.education, education];
      
      await updateResume(resumeId, education: updatedEducation);
    } catch (e) {
      throw Exception('Failed to add education: ${e.toString()}');
    }
  }

  // Add experience to resume
  Future<void> addExperience(String resumeId, ExperienceModel experience) async {
    try {
      final resume = await getResumeById(resumeId);
      if (resume == null) throw Exception('Resume not found');

      final updatedExperience = [...resume.experience, experience];
      
      await updateResume(resumeId, experience: updatedExperience);
    } catch (e) {
      throw Exception('Failed to add experience: ${e.toString()}');
    }
  }

  // Add project to resume
  Future<void> addProject(String resumeId, ProjectModel project) async {
    try {
      final resume = await getResumeById(resumeId);
      if (resume == null) throw Exception('Resume not found');

      final updatedProjects = [...resume.projects, project];
      
      await updateResume(resumeId, projects: updatedProjects);
    } catch (e) {
      throw Exception('Failed to add project: ${e.toString()}');
    }
  }

  // Add certification to resume
  Future<void> addCertification(String resumeId, CertificationModel certification) async {
    try {
      final resume = await getResumeById(resumeId);
      if (resume == null) throw Exception('Resume not found');

      final updatedCertifications = [...resume.certifications, certification];
      
      await updateResume(resumeId, certifications: updatedCertifications);
    } catch (e) {
      throw Exception('Failed to add certification: ${e.toString()}');
    }
  }

  // Remove education from resume
  Future<void> removeEducation(String resumeId, String educationId) async {
    try {
      final resume = await getResumeById(resumeId);
      if (resume == null) throw Exception('Resume not found');

      final updatedEducation = resume.education.where((e) => e.id != educationId).toList();
      
      await updateResume(resumeId, education: updatedEducation);
    } catch (e) {
      throw Exception('Failed to remove education: ${e.toString()}');
    }
  }

  // Remove experience from resume
  Future<void> removeExperience(String resumeId, String experienceId) async {
    try {
      final resume = await getResumeById(resumeId);
      if (resume == null) throw Exception('Resume not found');

      final updatedExperience = resume.experience.where((e) => e.id != experienceId).toList();
      
      await updateResume(resumeId, experience: updatedExperience);
    } catch (e) {
      throw Exception('Failed to remove experience: ${e.toString()}');
    }
  }

  // Get resume templates
  Future<List<Map<String, dynamic>>> getResumeTemplates() async {
    try {
      final response = await _supabase.client
          .from('resume_templates')
          .select()
          .eq('is_active', true)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch resume templates: ${e.toString()}');
    }
  }

  // Generate resume PDF (placeholder - would integrate with PDF generation service)
  Future<String> generateResumePDF(String resumeId) async {
    try {
      // This would integrate with a PDF generation service
      // For now, return a placeholder URL
      return 'https://example.com/resume_$resumeId.pdf';
    } catch (e) {
      throw Exception('Failed to generate resume PDF: ${e.toString()}');
    }
  }

  // Export resume data
  Future<Map<String, dynamic>> exportResumeData(String resumeId) async {
    try {
      final resume = await getResumeById(resumeId);
      if (resume == null) throw Exception('Resume not found');

      return resume.toJson();
    } catch (e) {
      throw Exception('Failed to export resume data: ${e.toString()}');
    }
  }

  // Import resume data
  Future<ResumeModel> importResumeData(String userId, Map<String, dynamic> resumeData) async {
    try {
      resumeData['user_id'] = userId;
      resumeData['created_at'] = DateTime.now().toIso8601String();
      resumeData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase.client
          .from('resumes')
          .insert(resumeData)
          .select()
          .single();

      return ResumeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to import resume data: ${e.toString()}');
    }
  }

  // Private helper method to unset default resumes
  Future<void> _unsetDefaultResumes(String userId) async {
    try {
      await _supabase.client
          .from('resumes')
          .update({'is_default': false})
          .eq('user_id', userId)
          .eq('is_default', true);
    } catch (e) {
      // Ignore errors in this helper method
    }
  }

  // Get resume statistics
  Future<Map<String, dynamic>> getResumeStats(String userId) async {
    try {
      final resumes = await getUserResumes(userId);
      
      int totalResumes = resumes.length;
      int completeResumes = 0;
      int incompleteResumes = 0;
      
      for (final resume in resumes) {
        bool isComplete = resume.personalInfo.firstName.isNotEmpty &&
                         resume.personalInfo.lastName.isNotEmpty &&
                         resume.personalInfo.email.isNotEmpty &&
                         resume.education.isNotEmpty &&
                         resume.skills.isNotEmpty;
        
        if (isComplete) {
          completeResumes++;
        } else {
          incompleteResumes++;
        }
      }

      return {
        'total': totalResumes,
        'complete': completeResumes,
        'incomplete': incompleteResumes,
        'hasDefault': resumes.any((r) => r.isDefault),
      };
    } catch (e) {
      throw Exception('Failed to get resume stats: ${e.toString()}');
    }
  }
}