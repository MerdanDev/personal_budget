import 'package:flutter/material.dart';

/// A curated list of Material icons related to money, finance, income and
/// expenses.
///
/// Using a fixed list of `const` [IconData] references (instead of building
/// [IconData] dynamically from an arbitrary code point) is what allows Flutter
/// to tree-shake the icon font at build time. As long as every rendered icon
/// is looked up from [categoryIcons] via [iconDataForCode], no non-const
/// `IconData` is ever constructed and `--no-tree-shake-icons` is not required.
const List<IconData> categoryIcons = <IconData>[
  // Money & finance
  Icons.account_balance_wallet,
  Icons.savings,
  Icons.payments,
  Icons.credit_card,
  Icons.account_balance,
  Icons.attach_money,
  Icons.money,
  Icons.currency_exchange,
  Icons.paid,
  Icons.monetization_on,
  Icons.request_quote,
  Icons.receipt_long,
  Icons.receipt,
  Icons.trending_up,
  Icons.trending_down,
  Icons.price_change,
  Icons.wallet,
  Icons.atm,

  // Food & drinks
  Icons.restaurant,
  Icons.fastfood,
  Icons.local_cafe,
  Icons.local_bar,
  Icons.local_pizza,
  Icons.lunch_dining,
  Icons.bakery_dining,
  Icons.coffee,
  Icons.liquor,
  Icons.local_grocery_store,
  Icons.shopping_cart,

  // Shopping
  Icons.shopping_bag,
  Icons.store,
  Icons.storefront,
  Icons.checkroom,
  Icons.card_giftcard,
  Icons.redeem,
  Icons.diamond,
  Icons.watch,

  // Transport
  Icons.directions_car,
  Icons.local_gas_station,
  Icons.ev_station,
  Icons.directions_bus,
  Icons.train,
  Icons.flight,
  Icons.local_taxi,
  Icons.two_wheeler,
  Icons.directions_bike,
  Icons.local_parking,

  // Home & utilities
  Icons.home,
  Icons.apartment,
  Icons.bolt,
  Icons.water_drop,
  Icons.local_fire_department,
  Icons.wifi,
  Icons.lightbulb,
  Icons.cleaning_services,
  Icons.plumbing,

  // Health
  Icons.local_hospital,
  Icons.medical_services,
  Icons.medication,
  Icons.fitness_center,
  Icons.spa,

  // Entertainment & leisure
  Icons.movie,
  Icons.sports_esports,
  Icons.music_note,
  Icons.theaters,
  Icons.sports_soccer,
  Icons.beach_access,
  Icons.celebration,
  Icons.nightlife,
  Icons.hotel,
  Icons.luggage,

  // Education
  Icons.school,
  Icons.menu_book,
  Icons.science,

  // Work & income
  Icons.work,
  Icons.business_center,
  Icons.badge,
  Icons.handshake,
  Icons.computer,
  Icons.engineering,

  // Personal & family
  Icons.pets,
  Icons.child_care,
  Icons.family_restroom,
  Icons.content_cut,
  Icons.volunteer_activism,
  Icons.subscriptions,
  Icons.phone_android,
  Icons.card_membership,
];

/// Fallback icon used when a stored code point is not part of [categoryIcons]
/// (for example data created before the curated list existed).
const IconData fallbackCategoryIcon = Icons.category;

/// Lookup of code point -> curated [IconData], built once and cached.
final Map<int, IconData> _iconByCode = <int, IconData>{
  for (final icon in categoryIcons) icon.codePoint: icon,
};

/// Returns the curated [IconData] matching [code], or [fallbackCategoryIcon]
/// when the code point is unknown. Never constructs a dynamic [IconData], so
/// icon font tree-shaking keeps working.
IconData iconDataForCode(int? code) {
  if (code == null) return fallbackCategoryIcon;
  return _iconByCode[code] ?? fallbackCategoryIcon;
}
