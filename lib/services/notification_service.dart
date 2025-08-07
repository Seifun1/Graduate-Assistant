import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'supabase_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _supabase = SupabaseService();

  // Create a new notification
  Future<NotificationModel> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? metadata,
    String? actionUrl,
    String? imageUrl,
  }) async {
    try {
      final notificationData = {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type.name,
        'priority': priority.name,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'metadata': metadata,
        'action_url': actionUrl,
        'image_url': imageUrl,
      };

      final response = await _supabase.client
          .from('notifications')
          .insert(notificationData)
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create notification: ${e.toString()}');
    }
  }

  // Get user notifications
  Future<List<NotificationModel>> getUserNotifications(
    String userId, {
    bool? isRead,
    NotificationType? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      var query = _supabase.client
          .from('notifications')
          .select()
          .eq('user_id', userId);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      if (type != null) {
        query = query.eq('type', type.name);
      }

      // Apply pagination
      final offset = (page - 1) * limit;
      query = query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await query;
      return response.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: ${e.toString()}');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase.client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: ${e.toString()}');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase.client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: ${e.toString()}');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase.client
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: ${e.toString()}');
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase.client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      throw Exception('Failed to get unread count: ${e.toString()}');
    }
  }

  // Create job alert notification
  Future<void> createJobAlert({
    required String userId,
    required String jobTitle,
    required String company,
    required String jobId,
  }) async {
    try {
      await createNotification(
        userId: userId,
        title: 'New Job Alert',
        message: 'New job opportunity: $jobTitle at $company',
        type: NotificationType.jobAlert,
        priority: NotificationPriority.medium,
        metadata: {'job_id': jobId},
        actionUrl: '/job/$jobId',
      );
    } catch (e) {
      throw Exception('Failed to create job alert: ${e.toString()}');
    }
  }

  // Create application update notification
  Future<void> createApplicationUpdate({
    required String userId,
    required String jobTitle,
    required String company,
    required String status,
    required String applicationId,
  }) async {
    try {
      String message;
      NotificationPriority priority;

      switch (status.toLowerCase()) {
        case 'accepted':
          message = 'Congratulations! Your application for $jobTitle at $company has been accepted.';
          priority = NotificationPriority.high;
          break;
        case 'rejected':
          message = 'Your application for $jobTitle at $company was not successful this time.';
          priority = NotificationPriority.medium;
          break;
        case 'interviewed':
          message = 'Great news! You have been selected for an interview for $jobTitle at $company.';
          priority = NotificationPriority.high;
          break;
        case 'underreview':
          message = 'Your application for $jobTitle at $company is now under review.';
          priority = NotificationPriority.low;
          break;
        default:
          message = 'Your application status for $jobTitle at $company has been updated.';
          priority = NotificationPriority.medium;
      }

      await createNotification(
        userId: userId,
        title: 'Application Update',
        message: message,
        type: NotificationType.applicationUpdate,
        priority: priority,
        metadata: {
          'application_id': applicationId,
          'status': status,
        },
        actionUrl: '/applications/$applicationId',
      );
    } catch (e) {
      throw Exception('Failed to create application update: ${e.toString()}');
    }
  }

  // Create profile completion reminder
  Future<void> createProfileReminder(String userId, double completionPercentage) async {
    try {
      if (completionPercentage < 80) {
        await createNotification(
          userId: userId,
          title: 'Complete Your Profile',
          message: 'Your profile is ${completionPercentage.toInt()}% complete. Complete it to get better job recommendations!',
          type: NotificationType.reminder,
          priority: NotificationPriority.low,
          actionUrl: '/profile',
        );
      }
    } catch (e) {
      throw Exception('Failed to create profile reminder: ${e.toString()}');
    }
  }

  // Create deadline reminder
  Future<void> createDeadlineReminder({
    required String userId,
    required String jobTitle,
    required String company,
    required DateTime deadline,
    required String jobId,
  }) async {
    try {
      final daysLeft = deadline.difference(DateTime.now()).inDays;
      
      if (daysLeft <= 3 && daysLeft > 0) {
        await createNotification(
          userId: userId,
          title: 'Application Deadline Approaching',
          message: 'Only $daysLeft day${daysLeft > 1 ? 's' : ''} left to apply for $jobTitle at $company',
          type: NotificationType.reminder,
          priority: NotificationPriority.high,
          metadata: {'job_id': jobId},
          actionUrl: '/job/$jobId',
        );
      }
    } catch (e) {
      throw Exception('Failed to create deadline reminder: ${e.toString()}');
    }
  }

  // Subscribe to real-time notifications
  RealtimeChannel subscribeToNotifications(String userId, Function(NotificationModel) onNotification) {
    return _supabase.client
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final notification = NotificationModel.fromJson(payload.newRecord);
            onNotification(notification);
          },
        )
        .subscribe();
  }

  // Get notification statistics
  Future<Map<String, int>> getNotificationStats(String userId) async {
    try {
      final response = await _supabase.client
          .from('notifications')
          .select('type, is_read')
          .eq('user_id', userId);

      final stats = <String, int>{
        'total': response.length,
        'unread': 0,
        'jobAlerts': 0,
        'applicationUpdates': 0,
        'reminders': 0,
        'systemMessages': 0,
      };

      for (final notification in response) {
        if (!(notification['is_read'] as bool)) {
          stats['unread'] = (stats['unread'] ?? 0) + 1;
        }

        final type = notification['type'] as String;
        switch (type) {
          case 'jobAlert':
            stats['jobAlerts'] = (stats['jobAlerts'] ?? 0) + 1;
            break;
          case 'applicationUpdate':
            stats['applicationUpdates'] = (stats['applicationUpdates'] ?? 0) + 1;
            break;
          case 'reminder':
            stats['reminders'] = (stats['reminders'] ?? 0) + 1;
            break;
          case 'systemMessage':
            stats['systemMessages'] = (stats['systemMessages'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get notification stats: ${e.toString()}');
    }
  }

  // Clean up old notifications (older than 30 days)
  Future<void> cleanupOldNotifications(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      await _supabase.client
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .lt('created_at', thirtyDaysAgo.toIso8601String());
    } catch (e) {
      throw Exception('Failed to cleanup old notifications: ${e.toString()}');
    }
  }
}