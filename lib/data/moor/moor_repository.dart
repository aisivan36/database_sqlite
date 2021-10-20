import 'dart:async';
import '../models/models.dart';

import '../repository.dart';
import 'moor_db.dart';

class MoorRepository extends Repository {
// 1
  late RecipeDatabase recipeDatabase;
// 2
  late RecipeDao _recipeDao;
// 3
  late IngredientDao _ingredientDao;
// 3
  Stream<List<Ingredient>>? ingredientStream;
// 4
  Stream<List<Recipe>>? recipeStream;

  @override
  Future<List<Recipe>> findAllRecipes() {
    return _recipeDao.findAllRecipes().then<List<Recipe>>(
      (List<MoorRecipeData> moorRecipes) {
        final recipes = <Recipe>[];

        moorRecipes.forEach(
          (moorRecipe) async {
            final recipe = moorRecipeToRecipe(moorRecipe);

            if (recipe.id != null) {
              recipe.ingredients = await findRecipeIngredients(recipe.id!);
            }
            recipes.add(recipe);
          },
        );
        return recipes;
      },
    );
  }

  @override
  Stream<List<Recipe>> watchAllRecipes() {
    if (recipeStream == null) {
      recipeStream = _recipeDao.watchAllRecipes();
    }
    return recipeStream!;
  }

  @override
  Stream<List<Ingredient>> watchAllIngredients() {
    if (ingredientStream == null) {
      final stream = _ingredientDao.watchAllIngredients();

      ingredientStream = stream.map(
        (moorIngredients) {
          final ingredients = <Ingredient>[];

          moorIngredients.forEach(
            (moorIngredient) {
              ingredients.add(moorIngredientToIngredient(moorIngredient));
            },
          );
          return ingredients;
        },
      );
    }
    return ingredientStream!;
  }

  @override
  Future<Recipe> findRecipeById(int id) {
    return _recipeDao
        .findRecipeById(id)
        .then((listOfRecipes) => moorRecipeToRecipe(listOfRecipes.first));
  }

// TODO: Add findAllIngredients()
// TODO: Add findRecipeIngredients()
// TODO: Add insertRecipe()
// TODO: Add insertIngredients()
// TODO: Add Delete methods
  @override
  Future init() async {
// 6
    recipeDatabase = RecipeDatabase();
// 7
    _recipeDao = recipeDatabase.recipeDao;
    _ingredientDao = recipeDatabase.ingredientDao;
  }

  @override
  void close() {
// 8
    recipeDatabase.close();
  }
}
