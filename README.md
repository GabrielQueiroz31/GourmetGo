# GourmetGo — Caderno de Receitas

Aplicativo Flutter desenvolvido para pesquisar receitas e montar um caderno pessoal

## Funcionalidades

- Cadastro e login com e-mail e senha usando Firebase Authentication.
- Recomendações, busca e filtros por categoria através da TheMealDB.
- Tela de detalhes com imagem, ingredientes e modo de preparo.
- Salvar, listar e remover receitas no Cloud Firestore em tempo real.
- Mensagens de confirmação para salvar e remover receitas.

## Dados e segurança

As receitas são salvas em `users/{uid}/recipes/{mealId}`. Cada documento armazena informações básicas da receita e os campos `ingredients` e `instructions` como listas de texto (arrays).

As regras do Firestore garantem que cada usuário autenticado leia e altere somente o próprio caderno.

## Tecnologias

Flutter, Firebase Authentication, Cloud Firestore e [TheMealDB](https://www.themealdb.com/api.php).

## Protótipo

O protótipo das telas foi criado no Google Stitch:

[Visualizar protótipo do GourmetGo](https://stitch.withgoogle.com/projects/16119823713158955091)

## Como executar

1. No Firebase Console, ative **Authentication > E-mail/senha** e crie o **Cloud Firestore**.
2. Publique as regras:

```powershell
firebase deploy --only firestore:rules --project gourmetgogabriel
```

3. Instale os pacotes e rode:

```powershell
flutter pub get
flutter run
```

Após entrar, explore as receitas, abra os detalhes e escolha **Salvar no caderno**. A aba **Meu caderno** exibe as receitas salvas e permite removê-las.
