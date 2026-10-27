import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Scaffold(
          body: Center(
            child: Text('Falha ao verificar a conta: ${snapshot.error}'),
          ),
        );
      }
      return snapshot.hasData ? const HomeView() : const AuthView();
    },
  );
}

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      if (_register) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      _message(authError(error));
    } on Exception catch (error) {
      _message('Não foi possível conectar: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.restaurant_menu, size: 60),
                  Text(
                    'GourmetGo',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      return email.contains('@')
                          ? null
                          : 'Digite um e-mail válido.';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Senha'),
                    validator: (value) => (value?.length ?? 0) >= 6
                        ? null
                        : 'Use pelo menos 6 caracteres.',
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const CircularProgressIndicator()
                        : Text(_register ? 'Criar conta' : 'Entrar'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _register = !_register),
                    child: Text(
                      _register ? 'Já tenho uma conta' : 'Criar uma conta',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _search = TextEditingController();
  List<Recipe> _results = [];
  bool _loading = false;
  String? _error;
  int _tab = 0;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    if (_search.text.trim().isEmpty) {
      _message('Digite o nome de uma receita.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _results = await searchRecipes(_search.text.trim());
    } on Exception catch (error) {
      _error = 'Busca falhou: $error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Recipe recipe) async {
    try {
      final fullRecipe = await getRecipe(recipe.id);
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailsView(recipe: fullRecipe, uid: _uid),
        ),
      );
    } on Exception catch (error) {
      _message('Não foi possível abrir a receita: $error');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('GourmetGo'),
      actions: [
        IconButton(
          tooltip: 'Sair',
          onPressed: FirebaseAuth.instance.signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: _tab == 0 ? _searchPage() : RecipeBookView(uid: _uid, onOpen: _open),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (index) => setState(() => _tab = index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
        NavigationDestination(
          icon: Icon(Icons.menu_book),
          label: 'Meu caderno',
        ),
      ],
    ),
  );

  Widget _searchPage() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _find(),
          decoration: InputDecoration(
            hintText: 'Busque uma receita',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: _loading ? null : _find,
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : _results.isEmpty
            ? const Center(child: Text('Pesquise para descobrir receitas.'))
            : ListView(
                children: _results
                    .map((recipe) => RecipeTile(recipe: recipe, onOpen: _open))
                    .toList(),
              ),
      ),
    ],
  );
}

class RecipeBookView extends StatelessWidget {
  const RecipeBookView({required this.uid, required this.onOpen, super.key});

  final String uid;
  final ValueChanged<Recipe> onOpen;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Recipe>>(
    stream: watchRecipes(uid),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Text('Falha ao carregar o caderno: ${snapshot.error}'),
        );
      }
      final recipes = snapshot.data ?? [];
      if (recipes.isEmpty) {
        return const Center(child: Text('Seu caderno ainda está vazio.'));
      }
      return ListView(
        children: recipes
            .map(
              (recipe) => RecipeTile(
                recipe: recipe,
                onOpen: onOpen,
                actions: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _edit(context, recipe),
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, recipe),
                  ),
                ],
              ),
            )
            .toList(),
      );
    },
  );

  Future<void> _edit(BuildContext context, Recipe recipe) async {
    final name = TextEditingController(text: recipe.name);
    final category = TextEditingController(text: recipe.category);
    final area = TextEditingController(text: recipe.area);
    final ingredients = TextEditingController(
      text: recipe.ingredients.join('\n'),
    );
    final instructions = TextEditingController(
      text: recipe.instructions.join('\n'),
    );
    final form = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Editar receita'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Obrigatório'
                        : null,
                  ),
                  TextField(
                    controller: category,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                  ),
                  TextField(
                    controller: area,
                    decoration: const InputDecoration(labelText: 'Origem'),
                  ),
                  TextField(
                    controller: ingredients,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Ingredientes (um por linha)',
                    ),
                  ),
                  TextField(
                    controller: instructions,
                    minLines: 3,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: 'Preparo (uma etapa por linha)',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              try {
                await updateRecipe(
                  uid,
                  Recipe(
                    id: recipe.id,
                    name: name.text.trim(),
                    imageUrl: recipe.imageUrl,
                    category: category.text.trim(),
                    area: area.text.trim(),
                    ingredients: _lines(ingredients.text),
                    instructions: _lines(instructions.text),
                    source: recipe.source,
                  ),
                );
                if (dialog.mounted) {
                  Navigator.pop(dialog, true);
                }
              } on FirebaseException catch (error) {
                if (dialog.mounted) {
                  _message(dialog, 'Falha ao salvar: ${error.message}');
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    name.dispose();
    category.dispose();
    area.dispose();
    ingredients.dispose();
    instructions.dispose();
    if (save == true && context.mounted) {
      _message(context, 'Receita atualizada.');
    }
  }

  Future<void> _delete(BuildContext context, Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Excluir receita?'),
        content: Text('Remover "${recipe.name}" do caderno?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await deleteRecipe(uid, recipe.id);
    } on FirebaseException catch (error) {
      if (context.mounted) {
        _message(context, 'Falha ao excluir: ${error.message}');
      }
    }
  }
}

class RecipeDetailsView extends StatefulWidget {
  const RecipeDetailsView({required this.recipe, required this.uid, super.key});

  final Recipe recipe;
  final String uid;

  @override
  State<RecipeDetailsView> createState() => _RecipeDetailsViewState();
}

class _RecipeDetailsViewState extends State<RecipeDetailsView> {
  bool? _saved;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    setState(() => _busy = true);
    try {
      _saved = await hasRecipe(widget.uid, widget.recipe.id);
      _error = null;
    } on FirebaseException catch (error) {
      _error = error.message;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await saveRecipe(widget.uid, widget.recipe);
      _saved = true;
      _error = null;
    } on FirebaseException catch (error) {
      _error = error.message;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return Scaffold(
      appBar: AppBar(title: const Text('Receita')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (recipe.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                recipe.imageUrl,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.restaurant, size: 80),
              ),
            ),
          const SizedBox(height: 16),
          Text(recipe.name, style: Theme.of(context).textTheme.headlineSmall),
          Text('${recipe.category} • ${recipe.area}'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy || _saved == true ? null : _save,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bookmark_add_outlined),
            label: Text(
              _saved == true ? 'Salva no caderno' : 'Salvar no caderno',
            ),
          ),
          if (_error != null) ...[
            Text('Erro do Firestore: $_error'),
            TextButton(
              onPressed: _checkSaved,
              child: const Text('Tentar novamente'),
            ),
          ],
          const SizedBox(height: 20),
          Text('Ingredientes', style: Theme.of(context).textTheme.titleLarge),
          ...recipe.ingredients.map(
            (item) => ListTile(
              dense: true,
              leading: const Icon(Icons.circle, size: 8),
              title: Text(item),
            ),
          ),
          Text(
            'Modo de preparo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ...recipe.instructions.indexed.map(
            (entry) => ListTile(
              leading: CircleAvatar(child: Text('${entry.$1 + 1}')),
              title: Text(entry.$2),
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeTile extends StatelessWidget {
  const RecipeTile({
    required this.recipe,
    required this.onOpen,
    this.actions = const [],
    super.key,
  });

  final Recipe recipe;
  final ValueChanged<Recipe> onOpen;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    child: ListTile(
      onTap: () => onOpen(recipe),
      leading: recipe.imageUrl.isEmpty
          ? const Icon(Icons.restaurant)
          : Image.network(
              recipe.imageUrl,
              width: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(Icons.restaurant),
            ),
      title: Text(recipe.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('${recipe.category} • ${recipe.area}'),
      trailing: actions.isEmpty
          ? const Icon(Icons.chevron_right)
          : Row(mainAxisSize: MainAxisSize.min, children: actions),
    ),
  );
}

List<String> _lines(String text) => text
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList();

void _message(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
