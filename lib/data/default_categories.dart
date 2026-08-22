/// Suggested expense and savings categories with EN + RU names.
/// Used when creating a month, "Add defaults", and the add-category picker.
class DefaultCategories {
  static const savingsNameEn = 'Savings';
  static const savingsNameRu = 'Накопления';
  static const savingsColorValue = 0xFFFFB74D;

  static const List<DefaultCategory> all = [
    // —— Everyday living ——
    DefaultCategory(
      nameEn: 'Housing',
      nameRu: 'Жильё',
      type: 'expense',
      colorValue: 0xFF81C784,
    ),
    DefaultCategory(
      nameEn: 'Utilities',
      nameRu: 'Коммунальные',
      type: 'expense',
      colorValue: 0xFF4DB6AC,
    ),
    DefaultCategory(
      nameEn: 'Groceries',
      nameRu: 'Продукты',
      type: 'expense',
      colorValue: 0xFFFFF176,
    ),
    DefaultCategory(
      nameEn: 'Dining out',
      nameRu: 'Кафе и рестораны',
      type: 'expense',
      colorValue: 0xFFFFAB91,
    ),
    DefaultCategory(
      nameEn: 'Transport',
      nameRu: 'Транспорт',
      type: 'expense',
      colorValue: 0xFF80CBC4,
    ),
    DefaultCategory(
      nameEn: 'Car',
      nameRu: 'Автомобиль',
      type: 'expense',
      colorValue: 0xFF90A4AE,
    ),
    // —— Life & family ——
    DefaultCategory(
      nameEn: 'Health',
      nameRu: 'Здоровье',
      type: 'expense',
      colorValue: 0xFFD7CCC8,
    ),
    DefaultCategory(
      nameEn: 'Insurance',
      nameRu: 'Страховка',
      type: 'expense',
      colorValue: 0xFFB0BEC5,
    ),
    DefaultCategory(
      nameEn: 'Family & kids',
      nameRu: 'Семья и дети',
      type: 'expense',
      colorValue: 0xFF9CCC65,
    ),
    DefaultCategory(
      nameEn: 'Education',
      nameRu: 'Образование',
      type: 'expense',
      colorValue: 0xFF64B5F6,
    ),
    DefaultCategory(
      nameEn: 'Pets',
      nameRu: 'Питомцы',
      type: 'expense',
      colorValue: 0xFFA1887F,
    ),
    // —— Lifestyle ——
    DefaultCategory(
      nameEn: 'Personal',
      nameRu: 'Личное',
      type: 'expense',
      colorValue: 0xFFCE93D8,
    ),
    DefaultCategory(
      nameEn: 'Shopping',
      nameRu: 'Покупки',
      type: 'expense',
      colorValue: 0xFFF48FB1,
    ),
    DefaultCategory(
      nameEn: 'Entertainment',
      nameRu: 'Развлечения',
      type: 'expense',
      colorValue: 0xFFBA68C8,
    ),
    DefaultCategory(
      nameEn: 'Subscriptions',
      nameRu: 'Подписки',
      type: 'expense',
      colorValue: 0xFF7986CB,
    ),
    DefaultCategory(
      nameEn: 'Communications',
      nameRu: 'Связь',
      type: 'expense',
      colorValue: 0xFF90CAF9,
    ),
    DefaultCategory(
      nameEn: 'Travel',
      nameRu: 'Путешествия',
      type: 'expense',
      colorValue: 0xFF4FC3F7,
    ),
    DefaultCategory(
      nameEn: 'Gifts & donations',
      nameRu: 'Подарки и благотворительность',
      type: 'expense',
      colorValue: 0xFFFF8A65,
    ),
    DefaultCategory(
      nameEn: 'Home maintenance',
      nameRu: 'Ремонт и дом',
      type: 'expense',
      colorValue: 0xFFAED581,
    ),
    DefaultCategory(
      nameEn: 'Other',
      nameRu: 'Другое',
      type: 'expense',
      colorValue: 0xFFFFF59D,
    ),
    DefaultCategory(
      nameEn: 'Loans & debt',
      nameRu: 'Кредиты и долги',
      type: 'expense',
      colorValue: 0xFFE57373,
    ),
    // Savings parent (pots live on Savings tab — not shown on Home).
    DefaultCategory(
      nameEn: savingsNameEn,
      nameRu: savingsNameRu,
      type: 'savings',
      colorValue: savingsColorValue,
    ),
  ];
}

class DefaultCategory {
  const DefaultCategory({
    required this.nameEn,
    required this.nameRu,
    required this.type,
    required this.colorValue,
  });

  final String nameEn;
  final String nameRu;
  final String type;
  final int colorValue;

  String localizedName(String localeCode) =>
      localeCode == 'ru' ? nameRu : nameEn;
}

/// Suggested savings pots installed as subcategories of the Savings parent.
class DefaultPots {
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
