import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'VendorJet'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get homeTitle;

  /// No description provided for @ordersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersTitle;

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @subtitle.
  ///
  /// In en, this message translates to:
  /// **'Wholesale order management'**
  String get subtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @korean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get korean;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Edit flow coming soon.'**
  String get editComingSoon;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get invalidCredentials;

  /// No description provided for @ordersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search orders'**
  String get ordersSearchHint;

  /// No description provided for @productsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get productsSearchHint;

  /// No description provided for @ordersDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get ordersDetailTitle;

  /// No description provided for @orderPlacedOn.
  ///
  /// In en, this message translates to:
  /// **'Placed on'**
  String get orderPlacedOn;

  /// No description provided for @orderTotal.
  ///
  /// In en, this message translates to:
  /// **'Order total'**
  String get orderTotal;

  /// No description provided for @orderItems.
  ///
  /// In en, this message translates to:
  /// **'Line items'**
  String get orderItems;

  /// No description provided for @orderMetaTitle.
  ///
  /// In en, this message translates to:
  /// **'Order metadata'**
  String get orderMetaTitle;

  /// No description provided for @orderMetaPlannedShip.
  ///
  /// In en, this message translates to:
  /// **'Planned shipment'**
  String get orderMetaPlannedShip;

  /// No description provided for @orderMetaLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get orderMetaLastUpdated;

  /// No description provided for @orderMetaOwner.
  ///
  /// In en, this message translates to:
  /// **'Account owner'**
  String get orderMetaOwner;

  /// No description provided for @orderMetaNote.
  ///
  /// In en, this message translates to:
  /// **'Internal note'**
  String get orderMetaNote;

  /// No description provided for @orderBuyerSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Buyer information'**
  String get orderBuyerSectionTitle;

  /// No description provided for @orderBuyerName.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get orderBuyerName;

  /// No description provided for @orderBuyerContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get orderBuyerContact;

  /// No description provided for @orderBuyerNote.
  ///
  /// In en, this message translates to:
  /// **'Buyer note'**
  String get orderBuyerNote;

  /// No description provided for @orderBuyerUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get orderBuyerUnknown;

  /// No description provided for @orderEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit order'**
  String get orderEditTitle;

  /// No description provided for @orderEditStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orderEditStatusLabel;

  /// No description provided for @orderEditPlannedShip.
  ///
  /// In en, this message translates to:
  /// **'Planned shipment'**
  String get orderEditPlannedShip;

  /// No description provided for @orderEditNote.
  ///
  /// In en, this message translates to:
  /// **'Internal note'**
  String get orderEditNote;

  /// No description provided for @orderEditNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note for teammates'**
  String get orderEditNoteHint;

  /// No description provided for @orderEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get orderEditSave;

  /// No description provided for @orderEditCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get orderEditCancel;

  /// No description provided for @orderEditSaved.
  ///
  /// In en, this message translates to:
  /// **'Order updated.'**
  String get orderEditSaved;

  /// No description provided for @dashboardTodayOrders.
  ///
  /// In en, this message translates to:
  /// **'Today Orders'**
  String get dashboardTodayOrders;

  /// No description provided for @dashboardOpenOrders.
  ///
  /// In en, this message translates to:
  /// **'Open Orders'**
  String get dashboardOpenOrders;

  /// No description provided for @dashboardLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get dashboardLowStock;

  /// No description provided for @dashboardPreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preview item for layout'**
  String get dashboardPreviewSubtitle;

  /// No description provided for @dashboardRecentOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent Orders'**
  String get dashboardRecentOrders;

  /// No description provided for @dashboardRecentOrdersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent orders to show.'**
  String get dashboardRecentOrdersEmpty;

  /// No description provided for @ordersEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No orders found.'**
  String get ordersEmptyMessage;

  /// No description provided for @ordersEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No {status} orders found.'**
  String ordersEmptyFiltered(String status);

  /// No description provided for @productsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No products found.'**
  String get productsEmptyMessage;

  /// No description provided for @productsEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No products found in {category}.'**
  String productsEmptyFiltered(String category);

  /// No description provided for @stateErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get stateErrorMessage;

  /// No description provided for @stateRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get stateRetry;

  /// No description provided for @ordersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ordersFilterAll;

  /// No description provided for @ordersStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get ordersStatusPending;

  /// No description provided for @ordersStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get ordersStatusConfirmed;

  /// No description provided for @ordersStatusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get ordersStatusShipped;

  /// No description provided for @ordersStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get ordersStatusCompleted;

  /// No description provided for @ordersStatusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get ordersStatusCanceled;

  /// No description provided for @ordersStatusReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get ordersStatusReturned;

  /// No description provided for @ordersStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ordersStatusLabel;

  /// No description provided for @productsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get productsFilterAll;

  /// No description provided for @productsCategoryBeverages.
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get productsCategoryBeverages;

  /// No description provided for @productsCategorySnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get productsCategorySnacks;

  /// No description provided for @productsCategoryHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get productsCategoryHousehold;

  /// No description provided for @productsCategoryFashion.
  ///
  /// In en, this message translates to:
  /// **'Fashion'**
  String get productsCategoryFashion;

  /// No description provided for @productsCategoryElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get productsCategoryElectronics;

  /// No description provided for @productLowStockTag.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get productLowStockTag;

  /// No description provided for @orderListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} items · {total}'**
  String orderListSubtitle(int count, String total);

  /// No description provided for @orderLinePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Sample item {position}'**
  String orderLinePlaceholder(int position);

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Content not found'**
  String get notFound;

  /// No description provided for @productsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Product details'**
  String get productsDetailTitle;

  /// No description provided for @productSku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get productSku;

  /// No description provided for @productPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get productPrice;

  /// No description provided for @productVariants.
  ///
  /// In en, this message translates to:
  /// **'Variants'**
  String get productVariants;

  /// No description provided for @productHighlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get productHighlights;

  /// No description provided for @productMetaTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory & attributes'**
  String get productMetaTitle;

  /// No description provided for @productMetaCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get productMetaCategory;

  /// No description provided for @productMetaStockLow.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get productMetaStockLow;

  /// No description provided for @productMetaStockHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy stock'**
  String get productMetaStockHealthy;

  /// No description provided for @productMetaLastSync.
  ///
  /// In en, this message translates to:
  /// **'Inventory sync'**
  String get productMetaLastSync;

  /// No description provided for @productCardSummary.
  ///
  /// In en, this message translates to:
  /// **'{name} · {count} variants'**
  String productCardSummary(String name, int count);

  /// No description provided for @productAvailabilityInStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get productAvailabilityInStock;

  /// No description provided for @productAvailabilityLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get productAvailabilityLowStock;

  /// No description provided for @productAvailabilityBackordered.
  ///
  /// In en, this message translates to:
  /// **'Backordered'**
  String get productAvailabilityBackordered;

  /// No description provided for @productLeadTimeSameDay.
  ///
  /// In en, this message translates to:
  /// **'Same-day shipping'**
  String get productLeadTimeSameDay;

  /// No description provided for @productLeadTimeTwoDays.
  ///
  /// In en, this message translates to:
  /// **'Ships in 2 days'**
  String get productLeadTimeTwoDays;

  /// No description provided for @productLeadTimeWeek.
  ///
  /// In en, this message translates to:
  /// **'Ships in 1 week'**
  String get productLeadTimeWeek;

  /// No description provided for @productBadgeBestseller.
  ///
  /// In en, this message translates to:
  /// **'Bestseller'**
  String get productBadgeBestseller;

  /// No description provided for @productBadgeNew.
  ///
  /// In en, this message translates to:
  /// **'New arrival'**
  String get productBadgeNew;

  /// No description provided for @productBadgeSeasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal pick'**
  String get productBadgeSeasonal;

  /// No description provided for @productHighlightAvailabilityNote.
  ///
  /// In en, this message translates to:
  /// **'Inventory level synced as of today.'**
  String get productHighlightAvailabilityNote;

  /// No description provided for @productHighlightLeadTimeNote.
  ///
  /// In en, this message translates to:
  /// **'Standard lead time for wholesale orders.'**
  String get productHighlightLeadTimeNote;

  /// No description provided for @productHighlightBadgeNote.
  ///
  /// In en, this message translates to:
  /// **'Visible to top-tier retailers.'**
  String get productHighlightBadgeNote;

  /// No description provided for @productEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get productEditTitle;

  /// No description provided for @productEditName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productEditName;

  /// No description provided for @productEditPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get productEditPrice;

  /// No description provided for @productEditVariants.
  ///
  /// In en, this message translates to:
  /// **'Variants'**
  String get productEditVariants;

  /// No description provided for @productEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get productEditCategory;

  /// No description provided for @productEditLowStock.
  ///
  /// In en, this message translates to:
  /// **'Mark as low stock'**
  String get productEditLowStock;

  /// No description provided for @productEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get productEditSave;

  /// No description provided for @productEditCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get productEditCancel;

  /// No description provided for @productEditSaved.
  ///
  /// In en, this message translates to:
  /// **'Product updated.'**
  String get productEditSaved;

  /// No description provided for @productEditNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a product name.'**
  String get productEditNameRequired;

  /// No description provided for @productEditPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price.'**
  String get productEditPriceInvalid;

  /// No description provided for @productEditVariantsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a variant count of at least 1.'**
  String get productEditVariantsInvalid;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @registerVendor.
  ///
  /// In en, this message translates to:
  /// **'Create vendor account'**
  String get registerVendor;

  /// No description provided for @tenantName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get tenantName;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset instructions sent (mock).'**
  String get passwordResetSent;

  /// No description provided for @registerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created. Sign in to continue.'**
  String get registerSuccess;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create account.'**
  String get registerFailed;

  /// No description provided for @signInHelperCredentials.
  ///
  /// In en, this message translates to:
  /// **'Try alex@vendorjet.com / welcome1 to explore.'**
  String get signInHelperCredentials;

  /// No description provided for @tenantSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get tenantSectionTitle;

  /// No description provided for @tenantRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get tenantRoleLabel;

  /// No description provided for @tenantSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch workspace'**
  String get tenantSwitchTitle;

  /// No description provided for @tenantSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'You cannot access this workspace.'**
  String get tenantSwitchFailed;

  /// No description provided for @tenantInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite teammate'**
  String get tenantInviteTitle;

  /// No description provided for @inviteEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Teammate email'**
  String get inviteEmailPlaceholder;

  /// No description provided for @inviteSend.
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get inviteSend;

  /// No description provided for @inviteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invitation recorded (mock).'**
  String get inviteSuccess;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get roleStaff;

  /// No description provided for @ordersCreate.
  ///
  /// In en, this message translates to:
  /// **'Add order'**
  String get ordersCreate;

  /// No description provided for @ordersEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit order'**
  String get ordersEdit;

  /// No description provided for @ordersDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete order'**
  String get ordersDelete;

  /// No description provided for @ordersDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete order {code}?'**
  String ordersDeleteConfirm(String code);

  /// No description provided for @ordersCreated.
  ///
  /// In en, this message translates to:
  /// **'Order created.'**
  String get ordersCreated;

  /// No description provided for @ordersUpdated.
  ///
  /// In en, this message translates to:
  /// **'Order updated.'**
  String get ordersUpdated;

  /// No description provided for @ordersDeleted.
  ///
  /// In en, this message translates to:
  /// **'Order deleted.'**
  String get ordersDeleted;

  /// No description provided for @ordersFormCode.
  ///
  /// In en, this message translates to:
  /// **'Order code'**
  String get ordersFormCode;

  /// No description provided for @ordersFormItems.
  ///
  /// In en, this message translates to:
  /// **'Line items'**
  String get ordersFormItems;

  /// No description provided for @ordersFormTotal.
  ///
  /// In en, this message translates to:
  /// **'Order total'**
  String get ordersFormTotal;

  /// No description provided for @ordersFormDate.
  ///
  /// In en, this message translates to:
  /// **'Order date'**
  String get ordersFormDate;

  /// No description provided for @ordersFormBuyerName.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get ordersFormBuyerName;

  /// No description provided for @ordersFormBuyerContact.
  ///
  /// In en, this message translates to:
  /// **'Buyer contact'**
  String get ordersFormBuyerContact;

  /// No description provided for @ordersFormBuyerNote.
  ///
  /// In en, this message translates to:
  /// **'Buyer note'**
  String get ordersFormBuyerNote;

  /// No description provided for @ordersFormBuyerNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Notes visible to the seller team.'**
  String get ordersFormBuyerNoteHint;

  /// No description provided for @productsCreate.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get productsCreate;

  /// No description provided for @productsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete product'**
  String get productsDelete;

  /// No description provided for @productsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete product {name}?'**
  String productsDeleteConfirm(String name);

  /// No description provided for @productsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted.'**
  String get productsDeleted;

  /// No description provided for @productsCsvMock.
  ///
  /// In en, this message translates to:
  /// **'Mock CSV upload'**
  String get productsCsvMock;

  /// No description provided for @productsCsvImported.
  ///
  /// In en, this message translates to:
  /// **'Imported {success}/{processed} rows (mock).'**
  String productsCsvImported(int success, int processed);

  /// No description provided for @productEditSku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get productEditSku;

  /// No description provided for @productsCreated.
  ///
  /// In en, this message translates to:
  /// **'Product created.'**
  String get productsCreated;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @customersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers'**
  String get customersSearchHint;

  /// No description provided for @customersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All tiers'**
  String get customersFilterAll;

  /// No description provided for @customersTierPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get customersTierPlatinum;

  /// No description provided for @customersTierGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get customersTierGold;

  /// No description provided for @customersTierSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get customersTierSilver;

  /// No description provided for @customersCreate.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get customersCreate;

  /// No description provided for @customersEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get customersEdit;

  /// No description provided for @customersDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete customer'**
  String get customersDelete;

  /// No description provided for @customersDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete customer {name}?'**
  String customersDeleteConfirm(String name);

  /// No description provided for @customersCreated.
  ///
  /// In en, this message translates to:
  /// **'Customer created.'**
  String get customersCreated;

  /// No description provided for @customersUpdated.
  ///
  /// In en, this message translates to:
  /// **'Customer updated.'**
  String get customersUpdated;

  /// No description provided for @customersDeleted.
  ///
  /// In en, this message translates to:
  /// **'Customer deleted.'**
  String get customersDeleted;

  /// No description provided for @customersFormName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get customersFormName;

  /// No description provided for @customersFormContact.
  ///
  /// In en, this message translates to:
  /// **'Contact name'**
  String get customersFormContact;

  /// No description provided for @customersFormEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get customersFormEmail;

  /// No description provided for @customersFormTier.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get customersFormTier;

  /// No description provided for @customersEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No customers found.'**
  String get customersEmptyMessage;

  /// No description provided for @customersEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No {tier} customers found.'**
  String customersEmptyFiltered(String tier);

  /// No description provided for @ordersFilterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get ordersFilterToday;

  /// No description provided for @ordersFilterOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get ordersFilterOpen;

  /// No description provided for @ordersCodeAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Automatically generated when saved.'**
  String get ordersCodeAutoHint;

  /// No description provided for @productsLowStockFilter.
  ///
  /// In en, this message translates to:
  /// **'Show low stock only'**
  String get productsLowStockFilter;

  /// No description provided for @productsXlsxUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload .xlsx'**
  String get productsXlsxUpload;

  /// No description provided for @productsXlsxNoData.
  ///
  /// In en, this message translates to:
  /// **'.xlsx file contained no data.'**
  String get productsXlsxNoData;

  /// No description provided for @productsXlsxImported.
  ///
  /// In en, this message translates to:
  /// **'Imported {success}/{processed} rows (mock).'**
  String productsXlsxImported(int success, int processed);

  /// No description provided for @productsManageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get productsManageCategories;

  /// No description provided for @productCategoryUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get productCategoryUnassigned;

  /// No description provided for @productCategoryNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get productCategoryNone;

  /// No description provided for @productCategoriesManageHint.
  ///
  /// In en, this message translates to:
  /// **'Need another path? Close this sheet and open “Manage categories”.'**
  String get productCategoriesManageHint;

  /// No description provided for @productTagFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get productTagFeatured;

  /// No description provided for @productTagDiscounted.
  ///
  /// In en, this message translates to:
  /// **'Discounted'**
  String get productTagDiscounted;

  /// No description provided for @productTagNew.
  ///
  /// In en, this message translates to:
  /// **'New arrival'**
  String get productTagNew;

  /// No description provided for @productCategoryLevel.
  ///
  /// In en, this message translates to:
  /// **'Category level {level}'**
  String productCategoryLevel(int level);

  /// No description provided for @productCategoryLevelRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one category level.'**
  String get productCategoryLevelRequired;

  /// No description provided for @productSettingsCategories.
  ///
  /// In en, this message translates to:
  /// **'Category hierarchy'**
  String get productSettingsCategories;

  /// No description provided for @productTagsSection.
  ///
  /// In en, this message translates to:
  /// **'Product flags'**
  String get productTagsSection;

  /// No description provided for @productTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get productTabOverview;

  /// No description provided for @productTabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get productTabSettings;

  /// No description provided for @categoryManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Category library'**
  String get categoryManagerTitle;

  /// No description provided for @categoryManagerDescription.
  ///
  /// In en, this message translates to:
  /// **'Create up to three nested levels to reuse across products.'**
  String get categoryManagerDescription;

  /// No description provided for @categoryManagerAdd.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get categoryManagerAdd;

  /// No description provided for @categoryManagerUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update category'**
  String get categoryManagerUpdate;

  /// No description provided for @categoryManagerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel edit'**
  String get categoryManagerCancel;

  /// No description provided for @categoryManagerDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get categoryManagerDelete;

  /// No description provided for @categoryManagerDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {path}?'**
  String categoryManagerDeleteConfirm(String path);

  /// No description provided for @categoryManagerSaved.
  ///
  /// In en, this message translates to:
  /// **'Category saved.'**
  String get categoryManagerSaved;

  /// No description provided for @categoryManagerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category removed.'**
  String get categoryManagerDeleted;

  /// No description provided for @categoryManagerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories registered yet.'**
  String get categoryManagerEmpty;

  /// No description provided for @categoryManagerPrimaryRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter at least the first level.'**
  String get categoryManagerPrimaryRequired;

  /// No description provided for @buyerPortalTitle.
  ///
  /// In en, this message translates to:
  /// **'Buyer preview'**
  String get buyerPortalTitle;

  /// No description provided for @buyerPortalTabCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get buyerPortalTabCatalog;

  /// No description provided for @buyerPortalTabCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get buyerPortalTabCart;

  /// No description provided for @buyerPortalTabCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get buyerPortalTabCheckout;

  /// No description provided for @buyerPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Buyer preview'**
  String get buyerPreviewTitle;

  /// No description provided for @buyerPreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Simulate the retailer-side ordering flow.'**
  String get buyerPreviewSubtitle;

  /// No description provided for @buyerCatalogSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search catalog'**
  String get buyerCatalogSearchHint;

  /// No description provided for @buyerCatalogEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No products match the current filters.'**
  String get buyerCatalogEmptyHint;

  /// No description provided for @buyerCatalogPrice.
  ///
  /// In en, this message translates to:
  /// **'\$ {price} / unit'**
  String buyerCatalogPrice(String price);

  /// No description provided for @buyerCatalogAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get buyerCatalogAdd;

  /// No description provided for @buyerCatalogAddWithQty.
  ///
  /// In en, this message translates to:
  /// **'{count} Add to cart'**
  String buyerCatalogAddWithQty(String count);

  /// No description provided for @buyerCatalogAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added to cart.'**
  String buyerCatalogAdded(String name);

  /// No description provided for @buyerCartSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String buyerCartSummary(int count);

  /// No description provided for @buyerCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get buyerCartEmpty;

  /// No description provided for @buyerCartEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add products from the catalog tab.'**
  String get buyerCartEmptyHint;

  /// No description provided for @buyerCartLineTotal.
  ///
  /// In en, this message translates to:
  /// **'\$ {amount}'**
  String buyerCartLineTotal(String amount);

  /// No description provided for @buyerCartRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get buyerCartRemove;

  /// No description provided for @buyerCartTotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal: \$ {amount}'**
  String buyerCartTotal(String amount);

  /// No description provided for @buyerCartProceed.
  ///
  /// In en, this message translates to:
  /// **'Go to checkout'**
  String get buyerCartProceed;

  /// No description provided for @buyerCartClear.
  ///
  /// In en, this message translates to:
  /// **'Clear cart'**
  String get buyerCartClear;

  /// No description provided for @buyerCheckoutItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String buyerCheckoutItems(int count);

  /// No description provided for @buyerCheckoutStore.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get buyerCheckoutStore;

  /// No description provided for @buyerCheckoutContact.
  ///
  /// In en, this message translates to:
  /// **'Buyer contact'**
  String get buyerCheckoutContact;

  /// No description provided for @buyerCheckoutNote.
  ///
  /// In en, this message translates to:
  /// **'Buyer note'**
  String get buyerCheckoutNote;

  /// No description provided for @buyerCheckoutNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional message for the seller.'**
  String get buyerCheckoutNoteHint;

  /// No description provided for @buyerCheckoutSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit order'**
  String get buyerCheckoutSubmit;

  /// No description provided for @buyerCheckoutCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add items to the cart first.'**
  String get buyerCheckoutCartEmpty;

  /// No description provided for @buyerCheckoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order submitted. Code {code}'**
  String buyerCheckoutSuccess(String code);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
