/// Suggested spend / monthly / debt / savings categories with EN + RU names.
/// Used when creating a month, "Add defaults", and the add-category picker.
class DefaultCategories {
  static const savingsNameEn = 'Savings';
  static const savingsNameRu = 'Накопления';
  static const savingsColorValue = 0xFFFFB74D;

  static const List<DefaultCategory> all = [
    // —— Monthly (same amount each month) ——
    DefaultCategory(
      nameEn: 'Housing',
      nameRu: 'Жильё',
      type: 'monthly',
      colorValue: 0xFF81C784,
    ),
    DefaultCategory(
      nameEn: 'Utilities',
      nameRu: 'Коммунальные',
      type: 'monthly',
      colorValue: 0xFF4DB6AC,
    ),
    DefaultCategory(
      nameEn: 'Insurance',
      nameRu: 'Страховка',
      type: 'monthly',
      colorValue: 0xFFB0BEC5,
    ),
    DefaultCategory(
      nameEn: 'Subscriptions',
      nameRu: 'Подписки',
      type: 'monthly',
      colorValue: 0xFF7986CB,
    ),
    // —— Everyday spend ——
    DefaultCategory(
      nameEn: 'Groceries',
      nameRu: 'Продукты',
      type: 'spend',
      colorValue: 0xFFFFF176,
    ),
    DefaultCategory(
      nameEn: 'Dining out',
      nameRu: 'Кафе и рестораны',
      type: 'spend',
      colorValue: 0xFFFFAB91,
    ),
    DefaultCategory(
      nameEn: 'Transport',
      nameRu: 'Транспорт',
      type: 'spend',
      colorValue: 0xFF80CBC4,
    ),
    DefaultCategory(
      nameEn: 'Car',
      nameRu: 'Автомобиль',
      type: 'spend',
      colorValue: 0xFF90A4AE,
    ),
    DefaultCategory(
      nameEn: 'Health',
      nameRu: 'Здоровье',
      type: 'spend',
      colorValue: 0xFFD7CCC8,
    ),
    DefaultCategory(
      nameEn: 'Family & kids',
      nameRu: 'Семья и дети',
      type: 'spend',
      colorValue: 0xFF9CCC65,
    ),
    DefaultCategory(
      nameEn: 'Education',
      nameRu: 'Образование',
      type: 'spend',
      colorValue: 0xFF64B5F6,
    ),
    DefaultCategory(
      nameEn: 'Pets',
      nameRu: 'Питомцы',
      type: 'spend',
      colorValue: 0xFFA1887F,
    ),
    DefaultCategory(
      nameEn: 'Personal',
      nameRu: 'Личное',
      type: 'spend',
      colorValue: 0xFFCE93D8,
    ),
    DefaultCategory(
      nameEn: 'Shopping',
      nameRu: 'Покупки',
      type: 'spend',
      colorValue: 0xFFF48FB1,
    ),
    DefaultCategory(
      nameEn: 'Entertainment',
      nameRu: 'Развлечения',
      type: 'spend',
      colorValue: 0xFFBA68C8,
    ),
    DefaultCategory(
      nameEn: 'Communications',
      nameRu: 'Связь',
      type: 'spend',
      colorValue: 0xFF90CAF9,
    ),
    DefaultCategory(
      nameEn: 'Travel',
      nameRu: 'Путешествия',
      type: 'spend',
      colorValue: 0xFF4FC3F7,
    ),
    DefaultCategory(
      nameEn: 'Gifts & donations',
      nameRu: 'Подарки и благотворительность',
      type: 'spend',
      colorValue: 0xFFFF8A65,
    ),
    DefaultCategory(
      nameEn: 'Home maintenance',
      nameRu: 'Ремонт и дом',
      type: 'spend',
      colorValue: 0xFFAED581,
    ),
    DefaultCategory(
      nameEn: 'Other',
      nameRu: 'Другое',
      type: 'spend',
      colorValue: 0xFFFFF59D,
    ),
    // —— Debt / payments ——
    DefaultCategory(
      nameEn: 'Loans & debt',
      nameRu: 'Кредиты и долги',
      type: 'debt',
      colorValue: 0xFFE57373,
    ),
    // —— Savings ——
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
