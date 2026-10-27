import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.area,
    required this.ingredients,
    required this.instructions,
    required this.source,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final String area;
  final List<String> ingredients;
  final List<String> instructions;
  final String source;

  factory Recipe.fromMeal(Map<String, dynamic> meal) {
    final ingredients = <String>[];
    for (var index = 1; index <= 20; index++) {
      final ingredient = (meal['strIngredient$index'] ?? '').toString().trim();
      final measure = (meal['strMeasure$index'] ?? '').toString().trim();
      if (ingredient.isNotEmpty) {
        ingredients.add(measure.isEmpty ? ingredient : '$measure $ingredient');
      }
    }

    final instructions = (meal['strInstructions'] ?? '')
        .toString()
        .trim()
        .split(RegExp(r'\r?\n|(?<=[.!?])\s+(?=[A-ZÀ-Ú0-9])'))
        .map((step) => step.trim())
        .where((step) => step.isNotEmpty)
        .toList();

    return Recipe(
      id: (meal['idMeal'] ?? '').toString(),
      name: (meal['strMeal'] ?? 'Receita sem nome').toString(),
      imageUrl: (meal['strMealThumb'] ?? '').toString(),
      category: (meal['strCategory'] ?? '').toString(),
      area: (meal['strArea'] ?? '').toString(),
      ingredients: ingredients,
      instructions: instructions,
      source: (meal['strSource'] ?? '').toString(),
    );
  }

  factory Recipe.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return Recipe(
      id: (data['mealId'] ?? snapshot.id).toString(),
      name: (data['name'] ?? 'Receita sem nome').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      area: (data['area'] ?? '').toString(),
      ingredients: List<String>.from(data['ingredients'] ?? const []),
      instructions: List<String>.from(data['instructions'] ?? const []),
      source: (data['source'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'mealId': id,
    'name': name,
    'imageUrl': imageUrl,
    'category': category,
    'area': area,
    'ingredients': ingredients,
    'instructions': instructions,
    'source': source,
    'savedAt': FieldValue.serverTimestamp(),
  };
}
