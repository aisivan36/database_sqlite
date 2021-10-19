// ignore_for_file: lines_longer_than_80_chars

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlbrite/sqlbrite.dart';
import 'package:synchronized/synchronized.dart';
import '../models/models.dart';

class DatabaseHelper {
  /// make it constant
  static const _databaseName = 'MyRecipes.db';
  static const _databaseVersion = 1;
////  Database table's name
  static const recipeTable = 'Recipe';
  static const ingredientTable = 'Ingredient';
  static const recipeId = 'recipeId';
  static const ingredientId = 'ingredientId';

  /// late indicates the variable is non-nullable and that
  /// it will be initialized after it has been declared
  static late BriteDatabase _streamDatabase;

  /// Private constructor and provide a public static instance
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  /// Define lock, which you will use to prevent concurrent access
  static var lock = Lock();

  /// Private sqflite database instance
  static Database? _database;

  /// SQL code to create the database table
  /// [Note] When we run the app a second time, it won't call [_onCreate]
  /// because the database already exist
  Future _onCreate(Database db, int version) async {
    /// Create [recipeTable] with the same columns as the model using
    /// [CREATE TABLE]
    await db.execute('''
    CREATE TABLE $recipeTable (
      $recipeId INTERGER PRIMARY KEY,
      label TEXT,
      image TEXT,
      url TEXT,
      calories REAL,
      totalWeght Real,
      totalTime Real,
    )
    ''');

    /// Create [ingredientTable]
    await db.execute(''' 
    CREATE TABLE $ingredientTable (
      $ingredientId INTERGER PRIMARY KEY,
      $recipeId INTERGER,
      name TEXT,
      weight Real,
    )
    ''');
  }

  /// Opens the database and creates it if it does not exist
  Future<Database> _initDatabase() async {
    /// Get the app document's directory name, where we will store the database
    final documentsDirectory = await getApplicationDocumentsDirectory();

    /// Create a path to the database by appending the database name to the
    /// directory path
    final path = join(documentsDirectory.path, _databaseName);

    /// Turn on debugging. Remember to turn this off when we're ready to deploy
    /// our app on to the app store
    /// TODO Remember to turn off debugging before deploying app to store
    Sqflite.setDebugModeOn(true);

    /// Use sqflite's openDatabase to create and store
    ///  the database file in the path
    return openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  /// Other methods and classes can use this getter
  /// to access [(get)] the database
  Future<Database> get database async {
    //if the database is not null, it has already been created,
    // so we return the existing one
    if (_database != null) return _database!;
    //Use lock to ensure that only one process can be in this section
    //of code at a time
    await lock.synchronized(() async {
      /// Lazily instantiate the db the first time it is accessed
      //Check to make sure the database is null
      if (_database == null) {
        //call teh _initDatabse()
        _database = await _initDatabase();

//Create a BriteDatabase instance, wrapping the database
        _streamDatabase = BriteDatabase(_database!);
      }
    });
    return _database!;
  }

  /// getter with async
  Future<BriteDatabase> get streamDatabase async {
    // await the result because it also creates _streamDatabase
    await database;
    return _streamDatabase;
  }

  List<Recipe> parseRecipes(List<Map<String, dynamic>> recipeList) {
    final recipes = <Recipe>[];

    /// iterate over a list of recipes in JSON format
    recipeList.forEach((recipeMap) {
      // Convert each recipe into a Recipe instance
      final recipe = Recipe.fromJson(recipeMap);
// Add the recipe to the recipe list
      recipes.add(recipe);
    });
    // return the list of recipes
    return recipes;
  }

  List<Ingredient> parseIngredients(List<Map<String, dynamic>> ingredientList) {
    final ingredients = <Ingredient>[];

    ingredientList.forEach((ingredientMap) {
      // Converts each ingredient in JSON format into a list of Ingredients
      final ingredient = Ingredient.fromJson(ingredientMap);
      ingredients.add(ingredient);
    });
    return ingredients;
  }

  Future<List<Recipe>> findAllRecipes() async {
    /// Get your database instance
    final db = await instance.streamDatabase;
    // Use the database query() to get all the recipes.
    // query() has other parameters but we don't need them here
    final recipeList = await db.query(recipeTable);
    //Use parseRecipes() to get a list of recipes
    final recipes = parseRecipes(recipeList);
    return recipes;
  }

  Stream<List<Recipe>> watchAllRecipes() async* {
    final db = await instance.streamDatabase;

    /// [yield] adds a value to the output stream of the surrounding async* function.
    ///  It's like return, but doesn't terminate the function.
    /// [yield*] creates [Stream] using the query
    yield* db
        //Create a query using recipeTable
        .createQuery(recipeTable)
        //for each row convert the row to a list of recipes
        .mapToList((row) => Recipe.fromJson(row));
  }

  /// TODO add watchallingredients
}
