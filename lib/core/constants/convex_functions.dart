/// Contract for Convex function names matching the deployed Convex backend.
class ConvexFunctions {
  ConvexFunctions._();

  // --- Location Tracking (Queries) ---
  static const String getLatestLocation = 'location:getLatestLocation';
  static const String getLocationHistory = 'location:getLocationHistory';
  static const String isTrackingActive = 'location:isTrackingActive';

  // --- Location Tracking (Mutations) ---
  static const String updateLocation = 'location:updateLocation';
  static const String startTracking = 'location:startTracking';
  static const String stopTracking = 'location:stopTracking';

  // --- Chat (Queries) ---
  static const String getUserConversations = 'chat:getUserConversations';
  static const String getConversationMessages = 'chat:getConversationMessages';
  static const String getConversationByBooking = 'chat:getConversationByBooking';

  // --- Chat (Mutations) ---
  static const String createConversation = 'chat:createConversation';
  static const String sendMessage = 'chat:sendMessage';
  static const String markMessagesAsRead = 'chat:markMessagesAsRead';

  // --- Notifications (Queries) ---
  static const String getUserNotifications = 'notification:getUserNotifications';
  static const String getUnreadCount = 'notification:getUnreadCount';

  // --- Notifications (Mutations) ---
  static const String markNotificationRead = 'notification:markNotificationRead';
  static const String markAllNotificationsRead =
      'notification:markAllNotificationsRead';

  // --- Emergency (Queries) ---
  static const String getActiveAlerts = 'emergency:getActiveAlerts';
  static const String getAlertsByTrip = 'emergency:getAlertsByTrip';

  // --- Emergency (Mutations) ---
  static const String triggerSOS = 'emergency:triggerSOS';
  static const String cancelSOS = 'emergency:cancelSOS';

  // --- Presence (Queries) ---
  static const String getUserPresence = 'presense:getUserPresence';

  // --- Presence (Mutations) ---
  static const String updatePresence = 'presense:updatePresence';
}
