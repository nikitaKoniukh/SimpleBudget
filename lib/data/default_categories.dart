/// Suggested spend / monthly / debt / savings categories with EN + RU names.
/// Used when creating a month, "Add defaults", and the add-category picker.
class DefaultCategories {
  static const savingsNameEn = 'Savings';
  static const savingsNameRu = 'Накопления';
  static const savingsColorValue = 0xFFFFB74D;
  static const savingsIconKey = 'savings';

  static const List<DefaultCategory> all = [
    // —— Monthly (same amount each month) ——
    DefaultCategory(
      nameEn: 'Housing & utilities',
      nameRu: 'Жильё и коммунальные',
      type: 'monthly',
      colorValue: 0xFF81C784,
      iconKey: 'home',
    ),
    DefaultCategory(
      nameEn: 'Insurance',
      nameRu: 'Страховка',
      type: 'monthly',
      colorValue: 0xFFB0BEC5,
      iconKey: 'shield',
    ),
    DefaultCategory(
      nameEn: 'Subscriptions',
      nameRu: 'Подписки',
      type: 'monthly',
      colorValue: 0xFF7986CB,
      iconKey: 'subscriptions',
    ),
    // —— Everyday spend ——
    DefaultCategory(
      nameEn: 'Groceries',
      nameRu: 'Продукты',
      type: 'spend',
      colorValue: 0xFFFFF176,
      iconKey: 'groceries',
    ),
    DefaultCategory(
      nameEn: 'Dining out',
      nameRu: 'Кафе и рестораны',
      type: 'spend',
      colorValue: 0xFFFFAB91,
      iconKey: 'restaurant',
    ),
    DefaultCategory(
      nameEn: 'Transport',
      nameRu: 'Транспорт',
      type: 'spend',
      colorValue: 0xFF80CBC4,
      iconKey: 'directions_bus',
    ),
    DefaultCategory(
      nameEn: 'Car',
      nameRu: 'Автомобиль',
      type: 'spend',
      colorValue: 0xFF90A4AE,
      iconKey: 'directions_car',
    ),
    DefaultCategory(
      nameEn: 'Health',
      nameRu: 'Здоровье',
      type: 'spend',
      colorValue: 0xFFD7CCC8,
      iconKey: 'local_hospital',
    ),
    DefaultCategory(
      nameEn: 'Family & kids',
      nameRu: 'Семья и дети',
      type: 'spend',
      colorValue: 0xFF9CCC65,
      iconKey: 'family',
    ),
    DefaultCategory(
      nameEn: 'Education',
      nameRu: 'Образование',
      type: 'spend',
      colorValue: 0xFF64B5F6,
      iconKey: 'school',
    ),
    DefaultCategory(
      nameEn: 'Pets',
      nameRu: 'Питомцы',
      type: 'spend',
      colorValue: 0xFFA1887F,
      iconKey: 'pets',
    ),
    DefaultCategory(
      nameEn: 'Personal',
      nameRu: 'Личное',
      type: 'spend',
      colorValue: 0xFFCE93D8,
      iconKey: 'person',
    ),
    DefaultCategory(
      nameEn: 'Shopping',
      nameRu: 'Покупки',
      type: 'spend',
      colorValue: 0xFFF48FB1,
      iconKey: 'shopping_bag',
    ),
    DefaultCategory(
      nameEn: 'Entertainment',
      nameRu: 'Развлечения',
      type: 'spend',
      colorValue: 0xFFBA68C8,
      iconKey: 'movie',
    ),
    DefaultCategory(
      nameEn: 'Communications',
      nameRu: 'Связь',
      type: 'spend',
      colorValue: 0xFF90CAF9,
      iconKey: 'phone',
    ),
    DefaultCategory(
      nameEn: 'Travel',
      nameRu: 'Путешествия',
      type: 'spend',
      colorValue: 0xFF4FC3F7,
      iconKey: 'flight',
    ),
    DefaultCategory(
      nameEn: 'Gifts & donations',
      nameRu: 'Подарки и благотворительность',
      type: 'spend',
      colorValue: 0xFFFF8A65,
      iconKey: 'card_giftcard',
    ),
    DefaultCategory(
      nameEn: 'Home maintenance',
      nameRu: 'Ремонт и дом',
      type: 'spend',
      colorValue: 0xFFAED581,
      iconKey: 'handyman',
    ),
    DefaultCategory(
      nameEn: 'Other',
      nameRu: 'Другое',
      type: 'spend',
      colorValue: 0xFFFFF59D,
      iconKey: 'more',
    ),
    // —— Debt / payments ——
    DefaultCategory(
      nameEn: 'Loans & debt',
      nameRu: 'Кредиты и долги',
      type: 'debt',
      colorValue: 0xFFE57373,
      iconKey: 'account_balance',
    ),
    // —— Savings ——
    DefaultCategory(
      nameEn: savingsNameEn,
      nameRu: savingsNameRu,
      type: 'savings',
      colorValue: savingsColorValue,
      iconKey: savingsIconKey,
    ),
  ];
}

class DefaultCategory {
  const DefaultCategory({
    required this.nameEn,
    required this.nameRu,
    required this.type,
    required this.colorValue,
    required this.iconKey,
  });

  final String nameEn;
  final String nameRu;
  final String type;
  final int colorValue;
  final String iconKey;

  String localizedName(String localeCode) =>
      localeCode == 'ru' ? nameRu : nameEn;
}

/// Suggested savings pots installed as subcategories of the Savings parent.
class DefaultPots {
  static const leftoverNameEn = 'Leftover';
  static const leftoverNameRu = 'Остаток';

  static const List<DefaultPot> all = [
    DefaultPot(nameEn: 'Emergency fund', nameRu: 'Резервный фонд'),
    DefaultPot(nameEn: 'Investments', nameRu: 'Инвестиции'),
  ];
}

class DefaultPot {
  const DefaultPot({required this.nameEn, required this.nameRu});

  final String nameEn;
  final String nameRu;

  String localizedName(String localeCode) =>
      localeCode == 'ru' ? nameRu : nameEn;
}
