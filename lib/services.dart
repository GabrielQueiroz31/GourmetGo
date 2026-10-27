import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'models/recipe.dart';

final _firestore = FirebaseFirestore.instance;
const _mealDb = 'https://www.themealdb.com/api/json/v1/1';

CollectionReference<Map<String, dynamic>> _recipes(String uid) =>
    _firestore.collection('users').doc(uid).collection('recipes');

Stream<List<Recipe>> watchRecipes(String uid) => _recipes(uid)
    .orderBy('name')
    .snapshots()
    .map((snapshot) => snapshot.docs.map(Recipe.fromFirestore).toList());

Future<bool> hasRecipe(String uid, String id) async =>
    (await _recipes(uid).doc(id).get()).exists;

Future<void> saveRecipe(String uid, Recipe recipe) =>
    _recipes(uid).doc(recipe.id).set(recipe.toFirestore());

Future<void> updateRecipe(String uid, Recipe recipe) =>
    _recipes(uid).doc(recipe.id).update({
      'name': recipe.name,
      'category': recipe.category,
      'area': recipe.area,
      'ingredients': recipe.ingredients,
      'instructions': recipe.instructions,
    });

Future<void> deleteRecipe(String uid, String id) =>
    _recipes(uid).doc(id).delete();

Future<List<Recipe>> searchRecipes(String query) async {
  final meals = await _request('search.php', {'s': query});
  return meals
      .map(Recipe.fromMeal)
      .where((recipe) => recipe.id.isNotEmpty)
      .toList();
}

Future<Recipe> getRecipe(String id) async {
  final meals = await _request('lookup.php', {'i': id});
  if (meals.isEmpty) throw Exception('Receita não encontrada.');
  return Recipe.fromMeal(meals.first);
}

Future<List<Map<String, dynamic>>> _request(
  String endpoint,
  Map<String, String> parameters,
) async {
  final uri = Uri.parse(
    '$_mealDb/$endpoint',
  ).replace(queryParameters: parameters);
  final response = await http.get(uri).timeout(const Duration(seconds: 20));
  if (response.statusCode != 200) {
    throw Exception('Erro da TheMealDB (${response.statusCode}).');
  }
  final data = jsonDecode(response.body);
  if (data is! Map<String, dynamic>) {
    throw const FormatException('Resposta inválida da TheMealDB.');
  }
  final meals = data['meals'];
  if (meals == null) return [];
  if (meals is! List) {
    throw const FormatException('Lista de receitas inválida.');
  }
  return meals.whereType<Map<String, dynamic>>().toList();
}

String authError(FirebaseAuthException error) => switch (error.code) {
  'email-already-in-use' => 'Este e-mail já possui uma conta.',
  'invalid-email' => 'Digite um e-mail válido.',
  'weak-password' => 'A senha deve ter pelo menos 6 caracteres.',
  'user-not-found' ||
  'wrong-password' ||
  'invalid-credential' => 'E-mail ou senha incorretos.',
  'too-many-requests' => 'Muitas tentativas. Tente novamente mais tarde.',
  'network-request-failed' => 'Sem conexão com a internet.',
  _ => error.message ?? 'Não foi possível autenticar sua conta.',
};
