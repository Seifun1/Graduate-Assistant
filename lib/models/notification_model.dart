enum NotificationType { 
  jobAlert, 
  applicationUpdate, 
  profileUpdate, 
  systemMessage, 
  reminder, 
  networking 
}

enum NotificationPriority { low, medium, high, urgent }

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;
  final String? actionUrl;
  final String? imageUrl;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.medium,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.metadata,
    this.actionUrl,
    this.imageUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.systemMessage,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      metadata: json['metadata'],
      actionUrl: json['action_url'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'metadata': metadata,
      'action_url': actionUrl,
      'image_url': imageUrl,
    };
  }

  NotificationModel copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      priority: priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata,
      actionUrl: actionUrl,
      imageUrl: imageUrl,
    );
  }

  String get typeDisplay {
    switch (type) {
      case NotificationType.jobAlert:
        return 'Job Alert';
      case NotificationType.applicationUpdate:
        return 'Application Update';
      case NotificationType.profileUpdate:
        return 'Profile Update';
      case NotificationType.systemMessage:
        return 'System Message';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.networking:
        return 'Networking';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}