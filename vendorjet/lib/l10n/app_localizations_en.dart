// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VendorJet';

  @override
  String get homeTitle => 'Dashboard';

  @override
  String get ordersTitle => 'Orders';

  @override
  String get productsTitle => 'Products';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get welcome => 'Welcome';

  @override
  String get subtitle => 'Wholesale order management';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get english => 'English';

  @override
  String get korean => 'Korean';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get continueLabel => 'Continue';

  @override
  String get or => 'or';

  @override
  String get signOut => 'Sign out';

  @override
  String get edit => 'Edit';

  @override
  String get editComingSoon => 'Edit flow coming soon.';

  @override
  String get invalidCredentials => 'Invalid credentials';

  @override
  String get ordersSearchHint => 'Search orders';

  @override
  String get productsSearchHint => 'Search products';

  @override
  String get ordersDetailTitle => 'Order details';

  @override
  String get orderPlacedOn => 'Placed on';

  @override
  String get orderTotal => 'Order total';

  @override
  String get orderItems => 'Line items';

  @override
  String get orderMetaTitle => 'Order metadata';

  @override
  String get orderMetaPlannedShip => 'Planned shipment';

  @override
  String get orderMetaLastUpdated => 'Last updated';

  @override
  String get orderMetaOwner => 'Account owner';

  @override
  String get orderMetaNote => 'Internal note';

  @override
  String get orderEditTitle => 'Edit order';

  @override
  String get orderEditStatusLabel => 'Status';

  @override
  String get orderEditPlannedShip => 'Planned shipment';

  @override
  String get orderEditNote => 'Internal note';

  @override
  String get orderEditNoteHint => 'Add a note for teammates';

  @override
  String get orderEditSave => 'Save';

  @override
  String get orderEditCancel => 'Cancel';

  @override
  String get orderEditSaved => 'Order updated.';

  @override
  String get dashboardTodayOrders => 'Today Orders';

  @override
  String get dashboardOpenOrders => 'Open Orders';

  @override
  String get dashboardLowStock => 'Low Stock';

  @override
  String get dashboardPreviewSubtitle => 'Preview item for layout';

  @override
  String get dashboardRecentOrders => 'Recent Orders';

  @override
  String get dashboardRecentOrdersEmpty => 'No recent orders to show.';

  @override
  String get ordersEmptyMessage => 'No orders found.';

  @override
  String ordersEmptyFiltered(String status) {
    return 'No $status orders found.';
  }

  @override
  String get productsEmptyMessage => 'No products found.';

  @override
  String productsEmptyFiltered(String category) {
    return 'No products found in $category.';
  }

  @override
  String get stateErrorMessage => 'Something went wrong.';

  @override
  String get stateRetry => 'Retry';

  @override
  String get ordersFilterAll => 'All';

  @override
  String get ordersStatusPending => 'Pending';

  @override
  String get ordersStatusConfirmed => 'Confirmed';

  @override
  String get ordersStatusShipped => 'Shipped';

  @override
  String get ordersStatusCompleted => 'Completed';

  @override
  String get ordersStatusCanceled => 'Canceled';

  @override
  String get ordersStatusReturned => 'Returned';

  @override
  String get ordersStatusLabel => 'Status';

  @override
  String get productsFilterAll => 'All';

  @override
  String get productsCategoryBeverages => 'Beverages';

  @override
  String get productsCategorySnacks => 'Snacks';

  @override
  String get productsCategoryHousehold => 'Household';

  @override
  String get productsCategoryFashion => 'Fashion';

  @override
  String get productsCategoryElectronics => 'Electronics';

  @override
  String get productLowStockTag => 'Low stock';

  @override
  String orderListSubtitle(int count, String total) {
    return '$count items · $total';
  }

  @override
  String orderLinePlaceholder(int position) {
    return 'Sample item $position';
  }

  @override
  String get notFound => 'Content not found';

  @override
  String get productsDetailTitle => 'Product details';

  @override
  String get productSku => 'SKU';

  @override
  String get productPrice => 'Unit price';

  @override
  String get productVariants => 'Variants';

  @override
  String get productHighlights => 'Highlights';

  @override
  String get productMetaTitle => 'Inventory & attributes';

  @override
  String get productMetaCategory => 'Category';

  @override
  String get productMetaStockLow => 'Low stock';

  @override
  String get productMetaStockHealthy => 'Healthy stock';

  @override
  String get productMetaLastSync => 'Inventory sync';

  @override
  String productCardSummary(String name, int count) {
    return '$name · $count variants';
  }

  @override
  String get productAvailabilityInStock => 'In stock';

  @override
  String get productAvailabilityLowStock => 'Low stock';

  @override
  String get productAvailabilityBackordered => 'Backordered';

  @override
  String get productLeadTimeSameDay => 'Same-day shipping';

  @override
  String get productLeadTimeTwoDays => 'Ships in 2 days';

  @override
  String get productLeadTimeWeek => 'Ships in 1 week';

  @override
  String get productBadgeBestseller => 'Bestseller';

  @override
  String get productBadgeNew => 'New arrival';

  @override
  String get productBadgeSeasonal => 'Seasonal pick';

  @override
  String get productHighlightAvailabilityNote =>
      'Inventory level synced as of today.';

  @override
  String get productHighlightLeadTimeNote =>
      'Standard lead time for wholesale orders.';

  @override
  String get productHighlightBadgeNote => 'Visible to top-tier retailers.';

  @override
  String get productEditTitle => 'Edit product';

  @override
  String get productEditName => 'Product name';

  @override
  String get productEditPrice => 'Unit price';

  @override
  String get productEditVariants => 'Variants';

  @override
  String get productEditCategory => 'Category';

  @override
  String get productEditLowStock => 'Mark as low stock';

  @override
  String get productEditSave => 'Save';

  @override
  String get productEditCancel => 'Cancel';

  @override
  String get productEditSaved => 'Product updated.';

  @override
  String get productEditNameRequired => 'Enter a product name.';

  @override
  String get productEditPriceInvalid => 'Enter a valid price.';

  @override
  String get productEditVariantsInvalid =>
      'Enter a variant count of at least 1.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get registerVendor => 'Create vendor account';

  @override
  String get tenantName => 'Business name';

  @override
  String get passwordResetSent => 'Password reset instructions sent (mock).';

  @override
  String get registerSuccess => 'Account created. Sign in to continue.';

  @override
  String get registerFailed => 'Could not create account.';

  @override
  String get signInHelperCredentials =>
      'Try alex@vendorjet.com / welcome1 to explore.';

  @override
  String get tenantSectionTitle => 'Organization';

  @override
  String get tenantRoleLabel => 'Role';

  @override
  String get tenantSwitchTitle => 'Switch workspace';

  @override
  String get tenantSwitchFailed => 'You cannot access this workspace.';

  @override
  String get tenantInviteTitle => 'Invite teammate';

  @override
  String get inviteEmailPlaceholder => 'Teammate email';

  @override
  String get inviteSend => 'Send invite';

  @override
  String get inviteSuccess => 'Invitation recorded (mock).';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleStaff => 'Staff';

  @override
  String get ordersCreate => 'Add order';

  @override
  String get ordersEdit => 'Edit order';

  @override
  String get ordersDelete => 'Delete order';

  @override
  String ordersDeleteConfirm(String code) {
    return 'Delete order $code?';
  }

  @override
  String get ordersCreated => 'Order created.';

  @override
  String get ordersUpdated => 'Order updated.';

  @override
  String get ordersDeleted => 'Order deleted.';

  @override
  String get ordersFormCode => 'Order code';

  @override
  String get ordersFormItems => 'Line items';

  @override
  String get ordersFormTotal => 'Order total';

  @override
  String get ordersFormDate => 'Order date';

  @override
  String get productsCreate => 'Add product';

  @override
  String get productsDelete => 'Delete product';

  @override
  String productsDeleteConfirm(String name) {
    return 'Delete product $name?';
  }

  @override
  String get productsDeleted => 'Product deleted.';

  @override
  String get productsCsvMock => 'Mock CSV upload';

  @override
  String productsCsvImported(int success, int processed) {
    return 'Imported $success/$processed rows (mock).';
  }

  @override
  String get productEditSku => 'SKU';

  @override
  String get productsCreated => 'Product created.';
}
