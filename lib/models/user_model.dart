class UserModel {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? bio;
  final String? location;
  final String? university;
  final String? degree;
  final String? graduationYear;
  final String? fieldOfStudy;
  final double? gpa;
  final List<String>? skills;
  final List<String>? interests;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? portfolioUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isProfileComplete;
  final String? resumeUrl;
  final String? coverLetterUrl;

  UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profileImageUrl,
    this.bio,
    this.location,
    this.university,
    this.degree,
    this.graduationYear,
    this.fieldOfStudy,
    this.gpa,
    this.skills,
    this.interests,
    this.linkedinUrl,
    this.githubUrl,
    this.portfolioUrl,
    this.createdAt,
    this.updatedAt,
    this.isProfileComplete = false,
    this.resumeUrl,
    this.coverLetterUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      profileImageUrl: json['profile_image_url'],
      bio: json['bio'],
      location: json['location'],
      university: json['university'],
      degree: json['degree'],
      graduationYear: json['graduation_year'],
      fieldOfStudy: json['field_of_study'],
      gpa: json['gpa']?.toDouble(),
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      interests: json['interests'] != null ? List<String>.from(json['interests']) : null,
      linkedinUrl: json['linkedin_url'],
      githubUrl: json['github_url'],
      portfolioUrl: json['portfolio_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isProfileComplete: json['is_profile_complete'] ?? false,
      resumeUrl: json['resume_url'],
      coverLetterUrl: json['cover_letter_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'bio': bio,
      'location': location,
      'university': university,
      'degree': degree,
      'graduation_year': graduationYear,
      'field_of_study': fieldOfStudy,
      'gpa': gpa,
      'skills': skills,
      'interests': interests,
      'linkedin_url': linkedinUrl,
      'github_url': githubUrl,
      'portfolio_url': portfolioUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_profile_complete': isProfileComplete,
      'resume_url': resumeUrl,
      'cover_letter_url': coverLetterUrl,
    };
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    String? bio,
    String? location,
    String? university,
    String? degree,
    String? graduationYear,
    String? fieldOfStudy,
    double? gpa,
    List<String>? skills,
    List<String>? interests,
    String? linkedinUrl,
    String? githubUrl,
    String? portfolioUrl,
    bool? isProfileComplete,
    String? resumeUrl,
    String? coverLetterUrl,
  }) {
    return UserModel(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      university: university ?? this.university,
      degree: degree ?? this.degree,
      graduationYear: graduationYear ?? this.graduationYear,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      gpa: gpa ?? this.gpa,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      coverLetterUrl: coverLetterUrl ?? this.coverLetterUrl,
    );
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  
  double get profileCompletionPercentage {
    int filledFields = 0;
    int totalFields = 15; // Key profile fields
    
    if (firstName?.isNotEmpty == true) filledFields++;
    if (lastName?.isNotEmpty == true) filledFields++;
    if (phoneNumber?.isNotEmpty == true) filledFields++;
    if (bio?.isNotEmpty == true) filledFields++;
    if (location?.isNotEmpty == true) filledFields++;
    if (university?.isNotEmpty == true) filledFields++;
    if (degree?.isNotEmpty == true) filledFields++;
    if (graduationYear?.isNotEmpty == true) filledFields++;
    if (fieldOfStudy?.isNotEmpty == true) filledFields++;
    if (gpa != null) filledFields++;
    if (skills?.isNotEmpty == true) filledFields++;
    if (interests?.isNotEmpty == true) filledFields++;
    if (linkedinUrl?.isNotEmpty == true) filledFields++;
    if (resumeUrl?.isNotEmpty == true) filledFields++;
    if (profileImageUrl?.isNotEmpty == true) filledFields++;
    
    return (filledFields / totalFields) * 100;
  }
}