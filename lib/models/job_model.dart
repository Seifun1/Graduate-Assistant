enum JobType { fullTime, partTime, contract, internship, remote }
enum ExperienceLevel { entryLevel, junior, midLevel, senior }
enum ApplicationStatus { draft, submitted, underReview, interviewed, rejected, accepted }

class JobModel {
  final String id;
  final String title;
  final String company;
  final String? companyLogo;
  final String description;
  final String? requirements;
  final String? benefits;
  final String location;
  final JobType jobType;
  final ExperienceLevel experienceLevel;
  final double? salaryMin;
  final double? salaryMax;
  final String? salaryCurrency;
  final List<String>? skills;
  final String? applicationUrl;
  final DateTime? applicationDeadline;
  final DateTime postedDate;
  final bool isActive;
  final String? contactEmail;
  final String? contactPhone;
  final int? applicationsCount;
  final bool isFeatured;
  final List<String>? tags;

  JobModel({
    required this.id,
    required this.title,
    required this.company,
    this.companyLogo,
    required this.description,
    this.requirements,
    this.benefits,
    required this.location,
    required this.jobType,
    required this.experienceLevel,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency = 'USD',
    this.skills,
    this.applicationUrl,
    this.applicationDeadline,
    required this.postedDate,
    this.isActive = true,
    this.contactEmail,
    this.contactPhone,
    this.applicationsCount,
    this.isFeatured = false,
    this.tags,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      company: json['company'] ?? '',
      companyLogo: json['company_logo'],
      description: json['description'] ?? '',
      requirements: json['requirements'],
      benefits: json['benefits'],
      location: json['location'] ?? '',
      jobType: JobType.values.firstWhere(
        (e) => e.name == json['job_type'],
        orElse: () => JobType.fullTime,
      ),
      experienceLevel: ExperienceLevel.values.firstWhere(
        (e) => e.name == json['experience_level'],
        orElse: () => ExperienceLevel.entryLevel,
      ),
      salaryMin: json['salary_min']?.toDouble(),
      salaryMax: json['salary_max']?.toDouble(),
      salaryCurrency: json['salary_currency'] ?? 'USD',
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      applicationUrl: json['application_url'],
      applicationDeadline: json['application_deadline'] != null
          ? DateTime.parse(json['application_deadline'])
          : null,
      postedDate: DateTime.parse(json['posted_date']),
      isActive: json['is_active'] ?? true,
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      applicationsCount: json['applications_count'],
      isFeatured: json['is_featured'] ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'company_logo': companyLogo,
      'description': description,
      'requirements': requirements,
      'benefits': benefits,
      'location': location,
      'job_type': jobType.name,
      'experience_level': experienceLevel.name,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'salary_currency': salaryCurrency,
      'skills': skills,
      'application_url': applicationUrl,
      'application_deadline': applicationDeadline?.toIso8601String(),
      'posted_date': postedDate.toIso8601String(),
      'is_active': isActive,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'applications_count': applicationsCount,
      'is_featured': isFeatured,
      'tags': tags,
    };
  }

  String get salaryRange {
    if (salaryMin != null && salaryMax != null) {
      return '\$${salaryMin!.toStringAsFixed(0)} - \$${salaryMax!.toStringAsFixed(0)}';
    } else if (salaryMin != null) {
      return '\$${salaryMin!.toStringAsFixed(0)}+';
    } else if (salaryMax != null) {
      return 'Up to \$${salaryMax!.toStringAsFixed(0)}';
    }
    return 'Salary not specified';
  }

  String get jobTypeDisplay {
    switch (jobType) {
      case JobType.fullTime:
        return 'Full Time';
      case JobType.partTime:
        return 'Part Time';
      case JobType.contract:
        return 'Contract';
      case JobType.internship:
        return 'Internship';
      case JobType.remote:
        return 'Remote';
    }
  }

  String get experienceLevelDisplay {
    switch (experienceLevel) {
      case ExperienceLevel.entryLevel:
        return 'Entry Level';
      case ExperienceLevel.junior:
        return 'Junior';
      case ExperienceLevel.midLevel:
        return 'Mid Level';
      case ExperienceLevel.senior:
        return 'Senior';
    }
  }

  bool get isDeadlineApproaching {
    if (applicationDeadline == null) return false;
    final daysUntilDeadline = applicationDeadline!.difference(DateTime.now()).inDays;
    return daysUntilDeadline <= 7 && daysUntilDeadline > 0;
  }

  bool get isExpired {
    if (applicationDeadline == null) return false;
    return applicationDeadline!.isBefore(DateTime.now());
  }
}

class JobApplicationModel {
  final String id;
  final String jobId;
  final String userId;
  final ApplicationStatus status;
  final String? coverLetter;
  final String? resumeUrl;
  final DateTime appliedDate;
  final DateTime? lastUpdated;
  final String? notes;
  final JobModel? job; // Populated when needed

  JobApplicationModel({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.status,
    this.coverLetter,
    this.resumeUrl,
    required this.appliedDate,
    this.lastUpdated,
    this.notes,
    this.job,
  });

  factory JobApplicationModel.fromJson(Map<String, dynamic> json) {
    return JobApplicationModel(
      id: json['id'] ?? '',
      jobId: json['job_id'] ?? '',
      userId: json['user_id'] ?? '',
      status: ApplicationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ApplicationStatus.draft,
      ),
      coverLetter: json['cover_letter'],
      resumeUrl: json['resume_url'],
      appliedDate: DateTime.parse(json['applied_date']),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
      notes: json['notes'],
      job: json['job'] != null ? JobModel.fromJson(json['job']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'user_id': userId,
      'status': status.name,
      'cover_letter': coverLetter,
      'resume_url': resumeUrl,
      'applied_date': appliedDate.toIso8601String(),
      'last_updated': lastUpdated?.toIso8601String(),
      'notes': notes,
    };
  }

  String get statusDisplay {
    switch (status) {
      case ApplicationStatus.draft:
        return 'Draft';
      case ApplicationStatus.submitted:
        return 'Submitted';
      case ApplicationStatus.underReview:
        return 'Under Review';
      case ApplicationStatus.interviewed:
        return 'Interviewed';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.accepted:
        return 'Accepted';
    }
  }
}