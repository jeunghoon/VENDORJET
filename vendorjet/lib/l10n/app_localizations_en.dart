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
  String get orderUpdateNote => 'Update note';

  @override
  String get orderBuyerSectionTitle => 'Buyer information';

  @override
  String get orderBuyerName => 'Store';

  @override
  String get orderBuyerContact => 'Contact';

  @override
  String get orderBuyerNote => 'Buyer note';

  @override
  String get orderBuyerUnknown => 'Not provided';

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
  String get ordersChangeStatus => 'Change status';

  @override
  String get ordersStatusUpdated => 'Status updated.';

  @override
  String get ordersFormCode => 'Order code';

  @override
  String get ordersFormItems => 'Line items';

  @override
  String get ordersFormTotal => 'Order total';

  @override
  String get ordersFormDate => 'Order date';

  @override
  String get ordersFormBuyerName => 'Store name';

  @override
  String get ordersFormBuyerContact => 'Buyer contact';

  @override
  String get ordersFormBuyerNote => 'Buyer note';

  @override
  String get ordersFormBuyerNoteHint => 'Notes visible to the seller team.';

  @override
  String get ordersFormBuyerLockedHint =>
      'Buyer provided during checkout; seller cannot edit.';

  @override
  String get ordersFormQuantityLockedHint =>
      'Calculated from items; not editable.';

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

  @override
  String get customersTitle => 'Customers';

  @override
  String get customersSearchHint => 'Search customers';

  @override
  String get customersFilterAll => 'All tiers';

  @override
  String get customersTierPlatinum => 'Platinum';

  @override
  String get customersTierGold => 'Gold';

  @override
  String get customersTierSilver => 'Silver';

  @override
  String get customersCreate => 'Add customer';

  @override
  String get customersEdit => 'Edit customer';

  @override
  String get customersDelete => 'Delete customer';

  @override
  String customersDeleteConfirm(String name) {
    return 'Delete customer $name?';
  }

  @override
  String get customersCreated => 'Customer created.';

  @override
  String get customersUpdated => 'Customer updated.';

  @override
  String get customersDeleted => 'Customer deleted.';

  @override
  String get customersFormName => 'Business name';

  @override
  String get customersFormContact => 'Contact name';

  @override
  String get customersFormEmail => 'Email';

  @override
  String get customersFormTier => 'Tier';

  @override
  String get customersFormSegment => 'Customer segment';

  @override
  String get customersEmptyMessage => 'No customers found.';

  @override
  String customersEmptyFiltered(String tier) {
    return 'No $tier customers found.';
  }

  @override
  String get customersManageSegments => 'Manage segments';

  @override
  String get customersSegmentFilterAll => 'All segments';

  @override
  String get customersSegmentNone => 'Unclassified';

  @override
  String get customersNoSegmentsHint =>
      'Create segments to group customers (Restaurant, Hotel, Mart...).';

  @override
  String get customersSegmentManagerTitle => 'Customer segments';

  @override
  String get customersSegmentManagerDescription =>
      'Add or update the retailer types you work with.';

  @override
  String get ordersFilterToday => 'Today';

  @override
  String get ordersFilterOpen => 'Open';

  @override
  String get ordersCodeAutoHint => 'Automatically generated when saved.';

  @override
  String get productsLowStockFilter => 'Show low stock only';

  @override
  String get productsXlsxUpload => 'Upload .xlsx';

  @override
  String get productsXlsxNoData => '.xlsx file contained no data.';

  @override
  String productsXlsxImported(int success, int processed) {
    return 'Imported $success/$processed rows (mock).';
  }

  @override
  String get productsManageCategories => 'Manage categories';

  @override
  String get productCategoryUnassigned => 'Uncategorized';

  @override
  String get productCategoryNone => 'None';

  @override
  String get productCategoriesManageHint =>
      'Need another path? Close this sheet and open “Manage categories”.';

  @override
  String get productTagFeatured => 'Featured';

  @override
  String get productTagDiscounted => 'Discounted';

  @override
  String get productTagNew => 'New arrival';

  @override
  String productCategoryLevel(int level) {
    return 'Category level $level';
  }

  @override
  String get productCategoryLevelRequired =>
      'Enter at least one category level.';

  @override
  String get productSettingsCategories => 'Category hierarchy';

  @override
  String get productTagsSection => 'Product flags';

  @override
  String get productTabOverview => 'Overview';

  @override
  String get productTabSettings => 'Settings';

  @override
  String get categoryManagerTitle => 'Category library';

  @override
  String get categoryManagerDescription =>
      'Create up to three nested levels to reuse across products.';

  @override
  String get categoryManagerAdd => 'Add category';

  @override
  String get categoryManagerUpdate => 'Update category';

  @override
  String get categoryManagerCancel => 'Cancel edit';

  @override
  String get categoryManagerDelete => 'Delete';

  @override
  String categoryManagerDeleteConfirm(String path) {
    return 'Delete $path?';
  }

  @override
  String get categoryManagerSaved => 'Category saved.';

  @override
  String get categoryManagerDeleted => 'Category removed.';

  @override
  String get categoryManagerEmpty => 'No categories registered yet.';

  @override
  String get categoryManagerPrimaryRequired =>
      'Enter at least the first level.';

  @override
  String get buyerPortalTitle => 'Buyer preview';

  @override
  String get buyerPortalTabDashboard => 'Dashboard';

  @override
  String get buyerPortalTabCatalog => 'Catalog';

  @override
  String get buyerPortalTabOrder => 'Order sheet';

  @override
  String get buyerPreviewTitle => 'Buyer preview';

  @override
  String get buyerPreviewSubtitle =>
      'Simulate the retailer-side ordering flow.';

  @override
  String get buyerCatalogSearchHint => 'Search catalog';

  @override
  String get buyerCatalogEmptyHint => 'No products match the current filters.';

  @override
  String buyerCatalogPrice(String price) {
    return '\$ $price / unit';
  }

  @override
  String get buyerCatalogAdd => 'Add to cart';

  @override
  String buyerCatalogAddWithQty(String count) {
    return '$count Add to cart';
  }

  @override
  String buyerCatalogAdded(String name) {
    return '$name added to cart.';
  }

  @override
  String buyerCartSummary(int count) {
    return '$count items';
  }

  @override
  String get buyerCartEmpty => 'Cart is empty';

  @override
  String get buyerCartEmptyHint => 'Add products from the catalog tab.';

  @override
  String buyerCartLineTotal(String amount) {
    return '\$ $amount';
  }

  @override
  String get buyerCartRemove => 'Remove';

  @override
  String buyerCartTotal(String amount) {
    return 'Subtotal: \$ $amount';
  }

  @override
  String get buyerCartClear => 'Clear cart';

  @override
  String get buyerDeliveryDateLabel => 'Delivery date';

  @override
  String get buyerDeliveryDatePick => 'Select delivery date';

  @override
  String get buyerDeliveryDateEdit => 'Change';

  @override
  String buyerOrderSummary(int uniqueCount, int totalCount) {
    return '$uniqueCount items : total qty $totalCount';
  }

  @override
  String get buyerDashboardGreeting =>
      'Plan your next purchase using your recent activity.';

  @override
  String get buyerDashboardMetricTotalOrdersLabel => 'Total orders';

  @override
  String get buyerDashboardMetricMonthlySpendLabel => 'Spend this month';

  @override
  String get buyerDashboardMetricLastOrderLabel => 'Last order';

  @override
  String get buyerDashboardMetricTopStoreLabel => 'Most active store';

  @override
  String get buyerDashboardMetricEmptyValue => 'None';

  @override
  String get buyerDashboardHistoryTitle => 'Past orders';

  @override
  String get buyerDashboardHistoryEmpty => 'No past orders yet';

  @override
  String get buyerDashboardHistoryEmptyHint =>
      'Submit your first order to see it here.';

  @override
  String get buyerDashboardHistoryLoad => 'Load into order';

  @override
  String buyerDashboardLoaded(String label) {
    return '$label copied to the order sheet.';
  }

  @override
  String buyerCheckoutItems(int count) {
    return '$count items';
  }

  @override
  String get buyerCheckoutStore => 'Store name';

  @override
  String get buyerCheckoutContact => 'Buyer contact';

  @override
  String get buyerCheckoutNote => 'Buyer note';

  @override
  String get buyerCheckoutNoteHint => 'Optional message for the seller.';

  @override
  String get buyerCheckoutSubmit => 'Submit order';

  @override
  String get buyerCheckoutCartEmpty => 'Add items to the cart first.';

  @override
  String buyerCheckoutSuccess(String code) {
    return 'Order submitted. Code $code';
  }

  @override
  String get buyerOrderEmptyHint =>
      'Use the catalog to add items before filling out the form.';

  @override
  String get buyerOrderBrowseCatalog => 'Browse catalog';

  @override
  String get buyerOrderPrefillMissing =>
      'This order has no item snapshot, so it cannot be copied.';

  @override
  String get buyerOrderStoreEmptyHint => 'Select a store you have registered.';

  @override
  String buyerOrderStoreLoadError(String error) {
    return 'Store list failed to load: $error';
  }
}
