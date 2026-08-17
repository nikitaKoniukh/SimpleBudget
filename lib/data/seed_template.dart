import 'package:flutter/material.dart';

/// Seed categories matching the family Google Sheet template.
class SeedTemplate {
  static const List<SeedCategory> categories = [
    SeedCategory(
      nameEn: 'Home',
      nameRu: 'Дом',
      colorValue: 0xFF81C784,
      type: 'expense',
      items: [
        SeedLineItem(nameEn: 'Rent', nameRu: 'Аренда', planned: 4650),
        SeedLineItem(nameEn: 'Utilities', nameRu: 'Коммуналка', planned: 1100),
      ],
    ),
    SeedCategory(
      nameEn: 'Car',
      nameRu: 'Авто',
      colorValue: 0xFF4DB6AC,
      type: 'expense',
      items: [
        SeedLineItem(
          nameEn: 'Parking & wash',
          nameRu: 'Стоянка и мойка',
          planned: 50,
        ),
        SeedLineItem(nameEn: 'Gas', nameRu: 'Бензин', planned: 500),
        SeedLineItem(
          nameEn: 'Maintenance',
          nameRu: 'Обслуживание',
          planned: 400,
        ),
      ],
    ),
    SeedCategory(
      nameEn: 'Shopping',
      nameRu: 'Покупки',
      colorValue: 0xFFFFF176,
      type: 'expense',
      items: [
        SeedLineItem(nameEn: 'Food', nameRu: 'Еда', planned: 2500),
        SeedLineItem(
          nameEn: 'Household goods',
          nameRu: 'Хозтовары',
          planned: 300,
        ),
        SeedLineItem(
          nameEn: 'Vitamins & cosmetics',
          nameRu: 'Витамины и косметика',
          planned: 250,
        ),
        SeedLineItem(
          nameEn: 'Entertainment',
          nameRu: 'Развлечение',
          planned: 400,
        ),
        SeedLineItem(nameEn: 'Misc', nameRu: 'Разное', planned: 250),
        SeedLineItem(nameEn: 'Clothing', nameRu: 'Одежда', planned: 200),
      ],
    ),
    SeedCategory(
      nameEn: 'Haircut',
      nameRu: 'Стрижка',
      colorValue: 0xFFAED581,
      type: 'expense',
      items: [
        SeedLineItem(nameEn: 'Haircut', nameRu: 'Стрижка', planned: 250),
      ],
    ),
    SeedCategory(
      nameEn: 'Transport',
      nameRu: 'Транспорт',
      colorValue: 0xFF80CBC4,
      type: 'expense',
      items: [
        SeedLineItem(nameEn: 'Bus', nameRu: 'Автобус', planned: 350),
      ],
    ),
    SeedCategory(
      nameEn: 'Set aside',
      nameRu: 'Отложить',
      colorValue: 0xFFFFB74D,
      type: 'savings',
      items: [
        SeedLineItem(nameEn: 'Travel', nameRu: 'Путешествие', planned: 2500),
        SeedLineItem(
          nameEn: 'Stocks & emergency',
          nameRu: 'Акции и НЗ',
          planned: 2000,
        ),
        SeedLineItem(nameEn: 'Dentist', nameRu: 'Зубной', planned: 300),
        SeedLineItem(
          nameEn: 'Anya savings fund',
          nameRu: 'Иштальмут Аня',
          planned: 1712,
        ),
        SeedLineItem(
          nameEn: 'Nikita pension fund',
          nameRu: 'Купат гемель Никита',
          planned: 1500,
        ),
        SeedLineItem(
          nameEn: 'Kids pension fund',
          nameRu: 'Купат гемель дети',
          planned: 1000,
        ),
      ],
    ),
    SeedCategory(
      nameEn: 'Communications',
      nameRu: 'Связь',
      colorValue: 0xFFCE93D8,
      type: 'expense',
      items: [
        SeedLineItem(nameEn: 'Phone', nameRu: 'Телефон', planned: 150),
        SeedLineItem(nameEn: 'Internet', nameRu: 'Интернет', planned: 130),
      ],
    ),
    SeedCategory(
      nameEn: 'Visa',
      nameRu: 'Виза',
      colorValue: 0xFFE57373,
      type: 'debt',
      items: [
        SeedLineItem(
          nameEn: 'Card commission',
          nameRu: 'Комиссия по карте',
          planned: 51,
        ),
        SeedLineItem(nameEn: 'Tami 4', nameRu: 'Тами 4', planned: 69),
        SeedLineItem(nameEn: 'iTunes', nameRu: 'iTunes', planned: 250),
        SeedLineItem(nameEn: 'Pais', nameRu: 'Паис', planned: 180),
        SeedLineItem(nameEn: 'Ituran', nameRu: 'Итуран', planned: 27),
        SeedLineItem(nameEn: 'PlayStation', nameRu: 'PlayStation', planned: 70),
        SeedLineItem(
          nameEn: 'Bike loan',
          nameRu: 'Кредит на вел',
          planned: 1000,
          installmentCurrent: 3,
          installmentTotal: 14,
        ),
        SeedLineItem(nameEn: 'Grandmother', nameRu: 'Бабушка', planned: 100),
        SeedLineItem(
          nameEn: 'Sports nutrition',
          nameRu: 'Спортпит',
          planned: 150,
        ),
        SeedLineItem(
          nameEn: 'IKEA',
          nameRu: 'Икеа',
          planned: 1175,
          installmentCurrent: 2,
          installmentTotal: 2,
        ),
        SeedLineItem(nameEn: 'Gym', nameRu: 'Спортзал', planned: 180),
      ],
    ),
    SeedCategory(
      nameEn: 'Education',
      nameRu: 'Образование',
      colorValue: 0xFF9CCC65,
      type: 'expense',
      items: [
        SeedLineItem(nameEn: 'Clubs', nameRu: 'Кружки', planned: 1000),
        SeedLineItem(nameEn: 'School', nameRu: 'Школа', planned: 300),
      ],
    ),
    SeedCategory(
      nameEn: 'Insurance',
      nameRu: 'Страховка',
      colorValue: 0xFFD7CCC8,
      type: 'expense',
      items: [
        SeedLineItem(nameEn: 'Medicines', nameRu: 'Лекарства', planned: 150),
        SeedLineItem(
          nameEn: 'Harel nursing',
          nameRu: 'Сэуд арэль',
          planned: 100,
        ),
        SeedLineItem(
          nameEn: 'Clal health',
          nameRu: 'Клаль бриют',
          planned: 430,
        ),
        SeedLineItem(
          nameEn: 'Menorah life',
          nameRu: 'Менора хаим',
          planned: 120,
        ),
        SeedLineItem(
          nameEn: 'Kupat Holim',
          nameRu: 'Купат Холим',
          planned: 270,
        ),
      ],
    ),
    SeedCategory(
      nameEn: 'Gifts',
      nameRu: 'Подарки',
      colorValue: 0xFFBA68C8,
      type: 'expense',
      items: [
        SeedLineItem(nameEn: 'Gifts', nameRu: 'Подарки', planned: 400),
      ],
    ),
    SeedCategory(
      nameEn: 'Other',
      nameRu: 'Иное',
      colorValue: 0xFFFFF59D,
      type: 'expense',
      items: [
        SeedLineItem(nameEn: 'Tithe', nameRu: 'Десятина', planned: 300),
      ],
    ),
  ];

  static const List<SeedIncomeSource> incomeSources = [
    SeedIncomeSource(nameEn: 'Nikita salary', nameRu: 'Зарплата Никита'),
    SeedIncomeSource(nameEn: 'Anya salary', nameRu: 'Зарплата Аня'),
    SeedIncomeSource(nameEn: 'Child benefit', nameRu: 'На ребенка'),
    SeedIncomeSource(nameEn: 'Filming', nameRu: 'Съемки'),
    SeedIncomeSource(nameEn: 'Cleaning', nameRu: 'Уборка'),
    SeedIncomeSource(nameEn: 'Anya side job', nameRu: 'Подработка Аня'),
    SeedIncomeSource(
      nameEn: 'Personal training',
      nameRu: 'Личные тренировки',
    ),
    SeedIncomeSource(nameEn: 'Nikita side job', nameRu: 'Подработка Никита'),
  ];
}

class SeedCategory {
  const SeedCategory({
    required this.nameEn,
    required this.nameRu,
    required this.colorValue,
    required this.type,
    required this.items,
  });

  final String nameEn;
  final String nameRu;
  final int colorValue;
  final String type;
  final List<SeedLineItem> items;

  Color get color => Color(colorValue);
}

class SeedLineItem {
  const SeedLineItem({
    required this.nameEn,
    required this.nameRu,
    required this.planned,
    this.installmentCurrent,
    this.installmentTotal,
  });

  final String nameEn;
  final String nameRu;
  final double planned;
  final int? installmentCurrent;
  final int? installmentTotal;
}

class SeedIncomeSource {
  const SeedIncomeSource({required this.nameEn, required this.nameRu});

  final String nameEn;
  final String nameRu;
}
