import 'package:flutter/material.dart';

/// Default icon key for custom / unknown categories.
const defaultCategoryIconKey = 'category';

class CategoryIconEntry {
  const CategoryIconEntry(this.key, this.icon);

  final String key;
  final IconData icon;
}

/// Curated Material icons for budget categories.
const categoryIconCatalog = <CategoryIconEntry>[
  CategoryIconEntry('category', Icons.category_outlined),
  CategoryIconEntry('home', Icons.home_outlined),
  CategoryIconEntry('groceries', Icons.shopping_cart_outlined),
  CategoryIconEntry('restaurant', Icons.restaurant_outlined),
  CategoryIconEntry('directions_bus', Icons.directions_bus_outlined),
  CategoryIconEntry('directions_car', Icons.directions_car_outlined),
  CategoryIconEntry('local_hospital', Icons.local_hospital_outlined),
  CategoryIconEntry('family', Icons.people_outline),
  CategoryIconEntry('school', Icons.school_outlined),
  CategoryIconEntry('pets', Icons.pets_outlined),
  CategoryIconEntry('person', Icons.person_outline),
  CategoryIconEntry('shopping_bag', Icons.shopping_bag_outlined),
  CategoryIconEntry('movie', Icons.movie_outlined),
  CategoryIconEntry('phone', Icons.phone_outlined),
  CategoryIconEntry('flight', Icons.flight_outlined),
  CategoryIconEntry('card_giftcard', Icons.card_giftcard_outlined),
  CategoryIconEntry('handyman', Icons.handyman_outlined),
  CategoryIconEntry('more', Icons.more_horiz),
  CategoryIconEntry('account_balance', Icons.account_balance_outlined),
  CategoryIconEntry('savings', Icons.savings_outlined),
  CategoryIconEntry('subscriptions', Icons.subscriptions_outlined),
  CategoryIconEntry('shield', Icons.shield_outlined),
  CategoryIconEntry('fitness', Icons.fitness_center_outlined),
  CategoryIconEntry('coffee', Icons.local_cafe_outlined),
  CategoryIconEntry('wifi', Icons.wifi),
  CategoryIconEntry('bolt', Icons.bolt_outlined),
  CategoryIconEntry('work', Icons.work_outline),
  CategoryIconEntry('child_care', Icons.child_care_outlined),
];

final Map<String, IconData> _iconByKey = {
  for (final e in categoryIconCatalog) e.key: e.icon,
};

IconData iconDataForKey(String key) {
  if (key.isEmpty) return _iconByKey[defaultCategoryIconKey]!;
  return _iconByKey[key] ?? _iconByKey[defaultCategoryIconKey]!;
}
