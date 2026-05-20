class AppConstants {
  // Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String commentsCollection = 'comments';
  static const String likesCollection = 'likes';
  static const String ratingsCollection = 'ratings';
  static const String notificationsCollection = 'notifications';
  static const String analyticsCollection = 'analytics';
  static const String predictionsCollection = 'predictions';
  
  // Product Categories
  static const List<String> categories = [
    'Electronics',
    'Fashion & Clothing',
    'Food & Beverages',
    'Automobile & Transport',
    'Beauty & Cosmetics',
    'Health & Pharmacy',
    'Agriculture & Farming',
    'Home & Furniture',
    'Education & Books',
    'Construction & Hardware',
  ];
  
  // Engagement Thresholds
  static const double highPerformanceThreshold = 1000;
  static const double mediumPerformanceThreshold = 500;
  
  // Notification Types
  static const String notificationTypeTrending = 'trending';
  static const String notificationTypeNewReview = 'new_review';
  static const String notificationTypeHighEngagement = 'high_engagement';
  static const String notificationTypeAIPrediction = 'ai_prediction';
}