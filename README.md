# GourmetGo — Caderno de Receitas Digital

Aplicativo Flutter para descobrir receitas na TheMealDB e manter um caderno pessoal na nuvem. Cada pessoa entra com sua conta, pesquisa receitas, consulta os ingredientes e o preparo e salva ou remove receitas do próprio caderno.

## Escopo

- Cadastro, login e saída com Firebase Authentication (e-mail e senha).
- Pesquisa e detalhes de receitas fornecidos pela TheMealDB.
- Caderno individual salvo no Cloud Firestore, com leitura em tempo real.
- Criar, consultar, editar e excluir receitas salvas; os documentos guardam ingredientes como array e instruções como array de etapas.
- Regras do Firestore limitam o acesso ao proprietário autenticado.

## Arquitetura e modelo de dados

```text
Flutter UI
  ├─ Firebase Auth ── estado de sessão
  ├─ TheMealDB API ── busca e detalhes de receitas públicas
  └─ Cloud Firestore ─ users/{uid}/recipes/{mealId}
```

Uma receita salva é um documento em `users/{uid}/recipes/{mealId}`:

```json
{
  "mealId": "52772",
  "name": "Teriyaki Chicken Casserole",
  "imageUrl": "https://...",
  "category": "Chicken",
  "area": "Japanese",
  "ingredients": ["soy sauce", "brown sugar"],
  "instructions": ["Preaqueça o forno...", "Misture os ingredientes..."],
  "source": "https://...",
  "savedAt": "(timestamp do servidor)"
}
```

O ID da receita da API também é o ID do documento, evitando duplicatas ao salvar a mesma receita. A subcoleção sob o UID torna natural consultar apenas o caderno da sessão atual. `instructions` é dividido em etapas para facilitar a exibição; `ingredients` contém apenas itens realmente presentes na resposta da API.

## Começando pela documentação: configurar Firebase

### 1. Conferir o projeto e registrar o app

1. Abra o [Firebase Console](https://console.firebase.google.com/) e confirme o projeto `gourmetgogabriel`, já vinculado a este app Android.
2. O identificador Android está em `android/app/build.gradle.kts` (`applicationId`: `com.example.gourmetgo`). Se registrar outro app, use exatamente esse identificador.
3. As opções para Android já estão em `lib/firebase_options.dart`. Para reconfigurar o projeto ou adicionar plataformas, instale Firebase CLI e FlutterFire CLI, faça login e execute na pasta `gourmetgo`:

```powershell
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Selecione o projeto Firebase e somente as plataformas que serão executadas. O comando regenera `lib/firebase_options.dart`; não edite esse arquivo manualmente. A configuração contém identificadores públicos do app, não credenciais de servidor.

### 2. Ativar Authentication

No Console: **Authentication → Começar → Método de login → E-mail/senha → Ativar → Salvar**. O app usa esse provedor para cadastro e login. Não armazene senhas no Firestore.

### 3. Criar o banco Firestore

No Console: **Firestore Database → Criar banco de dados**. Escolha uma localização próxima aos usuários e mantenha a localização consistente com os demais serviços. O app usa o projeto Firebase já configurado para Android; confirme que Authentication e Firestore estão ativos nesse mesmo projeto. Não deixe regras abertas de teste em produção.

Estrutura: `users/{uid}/recipes/{mealId}`. O documento pai `users/{uid}` não precisa ser criado para a subcoleção existir. A tela do caderno consulta `users/{uid}/recipes` da sessão atual.

### 4. Publicar regras de segurança

As regras restritivas já estão em `firestore.rules` e configuradas no `firebase.json`. Elas negam acesso por padrão, limitam cada caderno ao UID autenticado e validam os campos, tipos e tamanhos antes de gravar. Publique pelo Console em **Firestore → Regras → Publicar**, ou selecione explicitamente o projeto correto e use:

```powershell
firebase deploy --only firestore:rules --project gourmetgogabriel
```

O app usa o mesmo ID da API para salvar cada receita, então salvar novamente uma receita atualiza seu documento e o horário `savedAt`. As regras permitem create e update após validar o documento inteiro; os usuários só podem ler ou modificar as receitas sob seu UID. As regras do Firestore não são filtros: consultas apontam diretamente à subcoleção da sessão atual. Valide as regras no Emulator Suite antes da publicação de uma versão final.

### 5. API de receitas

```powershell
flutter pub get
```

O ponto de entrada `lib/main.dart` inicializa Firebase com as opções do FlutterFire e mostra um erro caso a inicialização falhe. A TheMealDB usa a chave gratuita de teste `1` nos endpoints V1 durante o desenvolvimento. Pesquisa: `https://www.themealdb.com/api/json/v1/1/search.php?s=chicken`; detalhe: `https://www.themealdb.com/api/json/v1/1/lookup.php?i=52772`. Verifique os termos e obtenha uma chave de produção se publicar amplamente.

## Rodar o aplicativo

```powershell
flutter pub get
flutter run
```

O primeiro acesso cria a conta; depois, use a busca para encontrar uma receita, abra seus detalhes e escolha **Salvar no caderno**. A aba **Meu caderno** mostra as receitas da sessão e permite editar ou remover cada uma.

## Estrutura do código

```text
lib/
  main.dart              # inicialização, tema e entrada
  firebase_options.dart  # configuração gerada pelo FlutterFire
  services.dart          # Firebase, Firestore e TheMealDB
  models/recipe.dart     # dados da receita
  views/app_view.dart    # login, busca, caderno e detalhes
```

As telas e serviços relacionados foram agrupados para deixar o projeto mais
fácil de navegar, mantendo as operações de autenticação, busca e CRUD.

## Referências oficiais

- [Configurar Firebase em Flutter](https://firebase.google.com/docs/flutter/setup)
- [Firebase Authentication para Flutter](https://firebase.google.com/docs/auth/flutter/start)
- [Autenticação por e-mail e senha](https://firebase.google.com/docs/auth/flutter/password-auth)
- [Condições das regras de segurança do Firestore](https://firebase.google.com/docs/firestore/security/rules-conditions)
- [TheMealDB API Guide](https://www.themealdb.com/docs_api_guide.php)

## Antes de entregar

- Configure `flutterfire configure` na máquina de build e não comite credenciais privadas ou arquivos de conta de serviço.
- Revise o projeto Firebase ativo e publique regras restritivas.
- Confirme que cadastro/login, busca, detalhes, salvar, leitura, edição e exclusão funcionam com duas contas distintas.
- Execute `dart format .` e `flutter analyze`; registre no README as plataformas testadas e eventuais limitações.
