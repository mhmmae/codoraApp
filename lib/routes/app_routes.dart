class AppRoutes {
  // Authentication routes
  static const String welcome = '/welcome';
  static const String signin = '/signin';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  // Test routes
  static const String phoneAuthTest = '/phone-auth-test';

  // Main app routes
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // Customer app routes
  static const String customerHome = '/customer-home';
  static const String orderDetails = '/order-details';
  static const String favorites = '/favorites';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderHistory = '/order-history';

  // Vendor app routes
  static const String vendorDashboard = '/vendor-dashboard';
  static const String addProduct = '/add-product';
  static const String manageProducts = '/manage-products';
  static const String vendorOrders = '/vendor-orders';
  static const String categoryManagement = '/category-management';

  // Retail vendor routes (بائعي التجزئة)
  static const String retailCart = '/retail-cart';
  static const String locationPicker = '/location-picker';
  static const String orderConfirmation = '/order-confirmation';
  static const String sellerMain = '/seller-main';
  static const String enhancedOrders = '/enhanced-orders';
  static const String storeMap = '/store-map';

  // Delivery app routes
  static const String driverDashboard = '/driver-dashboard';
  static const String DRIVER_DASHBOARD = '/driver-dashboard';
  static const String DRIVER_DELIVERY_NAVIGATION =
      '/driver-delivery-navigation/:taskId';
  static const String availableTasks = '/available-tasks';
  static const String myTasks = '/my-tasks';
  static const String navigation = '/navigation';
  static const String deliveryDetails = '/delivery-details';
  static const String taskHistory = '/task-history';
  static const String BARCODE_SCANNER_PAGE = '/barcode-scanner';
  static const String DRIVER_PROFILE_EDIT = '/driver-profile-edit';
  static const String DRIVER_AVAILABLE_TASKS = '/driver-available-tasks';
  static const String DRIVER_MY_TASKS = '/driver-my-tasks';
  static const String DRIVER_EARNINGS = '/driver-earnings';

  // Admin routes
  static const String adminDashboard = '/admin-dashboard';
  static const String manageDrivers = '/manage-drivers';
  static const String manageCompanies = '/manage-companies';
  static const String reports = '/reports';
  static const String pendingRequests = '/pending-requests';
  static const String driverApplicationReview = '/driver-application-review';
  static const String ADMIN_DRIVER_PROFILE = '/admin-driver-profile';
  static const String ADMIN_TASK_DETAILS = '/admin-task-details';
  static const String ADMIN_ASSIGN_TASK = '/admin-assign-task';

  // Hub supervisor routes
  static const String hubSupervisor = '/hub-supervisor';
  static const String scanPackages = '/scan-packages';
  static const String printLabels = '/print-labels';

  // Chat routes
  static const String chatList = '/chat-list';
  static const String chatScreen = '/chat-screen';
  static const String viewMedia = '/view-media';

  // Common utility routes
  static const String imageViewer = '/image-viewer';
  static const String videoPlayer = '/video-player';
  static const String map = '/map';
  static const String scanner = '/scanner';
  static const String notifications = '/notifications';

  // New routes
  static const String TASKS_NEEDING_INTERVENTION =
      '/tasks-needing-intervention';
  static const String COMPANY_DRIVERS_LIST = '/company-drivers-list';
  static const String DRIVER_APPLICATION_REVIEW = '/driver-application-review';
  static const String COMPANY_TASKS_PENDING_DRIVER =
      '/company-tasks-pending-driver';
}
