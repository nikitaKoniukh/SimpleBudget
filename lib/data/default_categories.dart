/// Default expense/savings categories with EN + RU names.
/// Applied when creating an empty month, or via "Add defaults" in the UI.
class DefaultCategories {
  static const List<DefaultCategory> all = [
    DefaultCategory(
      nameEn: 'Housing',
      nameRu: 'Жильё',
      type: 'expense',
      colorValue: 0xFF81C784,
    ),
    DefaultCategory(
      nameEn: 'Food',
      nameRu: 'Еда',
      type: 'expense',
      colorValue: 0xFFFFF176,
    ),
    DefaultCategory(
      nameEn: 'Transport',
      nameRu: 'Транспорт',
      type: 'expense',
      colorValue: 0xFF80CBC4,
    ),
    DefaultCategory(
      nameEn: 'Health',
      nameRu: 'Здоровье',
      type: 'expense',
      colorValue: 0xFFD7CCC8,
    ),
    DefaultCategory(
      nameEn: 'Personal',
      nameRu: 'Личное',
      type: 'expense',
      colorValue: 0xFFCE93D8,
    ),
    DefaultCategory(
      nameEn: 'Family & kids',
      nameRu: 'Семья и дети',
      type: 'expense',
      colorValue: 0xFF9CCC65,
    ),
    DefaultCategory(
      nameEn: 'Communications',
      nameRu: 'Связь',
      type: 'expense',
      colorValue: 0xFF90CAF9,
    ),
    DefaultCategory(
      nameEn: 'Debt & payments',
      nameRu: 'Долги и платежи',
      type: 'debt',
      colorValue: 0xFFE57373,
    ),
    DefaultCategory(
      nameEn: 'Savings',
      nameRu: 'Накопления',
      type: 'savings',
      colorValue: 0xFFFFB74D,
    ),
    DefaultCategory(
      nameEn: 'Other',
      nameRu: 'Другое',
      type: 'expense',
      colorValue: 0xFFFFF59D,
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
}
