class ResumeModel {
  final String id;
  final String userId;
  final String title;
  final PersonalInfoModel personalInfo;
  final String? summary;
  final List<EducationModel> education;
  final List<ExperienceModel> experience;
  final List<String> skills;
  final List<ProjectModel> projects;
  final List<CertificationModel> certifications;
  final List<String> languages;
  final String? additionalInfo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDefault;
  final String? templateId;

  ResumeModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.personalInfo,
    this.summary,
    this.education = const [],
    this.experience = const [],
    this.skills = const [],
    this.projects = const [],
    this.certifications = const [],
    this.languages = const [],
    this.additionalInfo,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
    this.templateId,
  });

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    return ResumeModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      personalInfo: PersonalInfoModel.fromJson(json['personal_info'] ?? {}),
      summary: json['summary'],
      education: json['education'] != null
          ? (json['education'] as List).map((e) => EducationModel.fromJson(e)).toList()
          : [],
      experience: json['experience'] != null
          ? (json['experience'] as List).map((e) => ExperienceModel.fromJson(e)).toList()
          : [],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : [],
      projects: json['projects'] != null
          ? (json['projects'] as List).map((e) => ProjectModel.fromJson(e)).toList()
          : [],
      certifications: json['certifications'] != null
          ? (json['certifications'] as List).map((e) => CertificationModel.fromJson(e)).toList()
          : [],
      languages: json['languages'] != null ? List<String>.from(json['languages']) : [],
      additionalInfo: json['additional_info'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDefault: json['is_default'] ?? false,
      templateId: json['template_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'personal_info': personalInfo.toJson(),
      'summary': summary,
      'education': education.map((e) => e.toJson()).toList(),
      'experience': experience.map((e) => e.toJson()).toList(),
      'skills': skills,
      'projects': projects.map((e) => e.toJson()).toList(),
      'certifications': certifications.map((e) => e.toJson()).toList(),
      'languages': languages,
      'additional_info': additionalInfo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_default': isDefault,
      'template_id': templateId,
    };
  }
}

class PersonalInfoModel {
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? portfolioUrl;

  PersonalInfoModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.linkedinUrl,
    this.githubUrl,
    this.portfolioUrl,
  });

  factory PersonalInfoModel.fromJson(Map<String, dynamic> json) {
    return PersonalInfoModel(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      country: json['country'],
      linkedinUrl: json['linkedin_url'],
      githubUrl: json['github_url'],
      portfolioUrl: json['portfolio_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'linkedin_url': linkedinUrl,
      'github_url': githubUrl,
      'portfolio_url': portfolioUrl,
    };
  }

  String get fullName => '$firstName $lastName';
  String get fullAddress {
    List<String> parts = [];
    if (address?.isNotEmpty == true) parts.add(address!);
    if (city?.isNotEmpty == true) parts.add(city!);
    if (state?.isNotEmpty == true) parts.add(state!);
    if (zipCode?.isNotEmpty == true) parts.add(zipCode!);
    if (country?.isNotEmpty == true) parts.add(country!);
    return parts.join(', ');
  }
}

class EducationModel {
  final String id;
  final String institution;
  final String degree;
  final String? fieldOfStudy;
  final String? startDate;
  final String? endDate;
  final double? gpa;
  final String? description;
  final bool isCurrentlyStudying;

  EducationModel({
    required this.id,
    required this.institution,
    required this.degree,
    this.fieldOfStudy,
    this.startDate,
    this.endDate,
    this.gpa,
    this.description,
    this.isCurrentlyStudying = false,
  });

  factory EducationModel.fromJson(Map<String, dynamic> json) {
    return EducationModel(
      id: json['id'] ?? '',
      institution: json['institution'] ?? '',
      degree: json['degree'] ?? '',
      fieldOfStudy: json['field_of_study'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      gpa: json['gpa']?.toDouble(),
      description: json['description'],
      isCurrentlyStudying: json['is_currently_studying'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'institution': institution,
      'degree': degree,
      'field_of_study': fieldOfStudy,
      'start_date': startDate,
      'end_date': endDate,
      'gpa': gpa,
      'description': description,
      'is_currently_studying': isCurrentlyStudying,
    };
  }
}

class ExperienceModel {
  final String id;
  final String company;
  final String position;
  final String? startDate;
  final String? endDate;
  final String? description;
  final List<String> achievements;
  final bool isCurrentPosition;

  ExperienceModel({
    required this.id,
    required this.company,
    required this.position,
    this.startDate,
    this.endDate,
    this.description,
    this.achievements = const [],
    this.isCurrentPosition = false,
  });

  factory ExperienceModel.fromJson(Map<String, dynamic> json) {
    return ExperienceModel(
      id: json['id'] ?? '',
      company: json['company'] ?? '',
      position: json['position'] ?? '',
      startDate: json['start_date'],
      endDate: json['end_date'],
      description: json['description'],
      achievements: json['achievements'] != null 
          ? List<String>.from(json['achievements']) 
          : [],
      isCurrentPosition: json['is_current_position'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company': company,
      'position': position,
      'start_date': startDate,
      'end_date': endDate,
      'description': description,
      'achievements': achievements,
      'is_current_position': isCurrentPosition,
    };
  }
}

class ProjectModel {
  final String id;
  final String title;
  final String? description;
  final List<String> technologies;
  final String? projectUrl;
  final String? githubUrl;
  final String? startDate;
  final String? endDate;

  ProjectModel({
    required this.id,
    required this.title,
    this.description,
    this.technologies = const [],
    this.projectUrl,
    this.githubUrl,
    this.startDate,
    this.endDate,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      technologies: json['technologies'] != null 
          ? List<String>.from(json['technologies']) 
          : [],
      projectUrl: json['project_url'],
      githubUrl: json['github_url'],
      startDate: json['start_date'],
      endDate: json['end_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'technologies': technologies,
      'project_url': projectUrl,
      'github_url': githubUrl,
      'start_date': startDate,
      'end_date': endDate,
    };
  }
}

class CertificationModel {
  final String id;
  final String name;
  final String? issuer;
  final String? issueDate;
  final String? expiryDate;
  final String? credentialId;
  final String? credentialUrl;

  CertificationModel({
    required this.id,
    required this.name,
    this.issuer,
    this.issueDate,
    this.expiryDate,
    this.credentialId,
    this.credentialUrl,
  });

  factory CertificationModel.fromJson(Map<String, dynamic> json) {
    return CertificationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      issuer: json['issuer'],
      issueDate: json['issue_date'],
      expiryDate: json['expiry_date'],
      credentialId: json['credential_id'],
      credentialUrl: json['credential_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'issuer': issuer,
      'issue_date': issueDate,
      'expiry_date': expiryDate,
      'credential_id': credentialId,
      'credential_url': credentialUrl,
    };
  }
}