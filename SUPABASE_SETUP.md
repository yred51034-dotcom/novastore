# Configuration Supabase — Nova Store 1.4.5

Cette version utilise le SDK `@supabase/supabase-js` intégré dans `www/supabase.min.js` pendant `npm run build`. Elle ne dépend plus d'un CDN pour charger le client.

## 1. Exécuter le SQL

1. Ouvrir le tableau de bord du projet Supabase configuré dans `supabase-config.js`.
2. Aller dans **SQL Editor → New query**.
3. Copier l'intégralité du fichier `supabase-setup.sql` et cliquer sur **Run**.
4. Vérifier qu'aucune erreur SQL n'est signalée.

Le script est réexécutable : il crée les tables `profiles` et `nova_messages`, les politiques RLS, le bucket privé `nova-chat`, les politiques Storage, le trigger des nouveaux comptes et les profils manquants des comptes déjà inscrits. Il active également Realtime pour `nova_messages`.

## 2. Authentification

Dans **Authentication → Providers → Email**, activer le fournisseur Email. Pour un usage réel, garder la confirmation d'adresse activée et configurer les URL de redirection et le service SMTP du projet. Les utilisateurs peuvent ensuite créer un compte depuis **Plus → Profil → Compte Nova en ligne**.

## 3. Tester le chat

1. Ouvrir l'application avec Internet.
2. Créer un compte et confirmer l'adresse si Supabase le demande.
3. Se connecter puis ouvrir **Chat**.
4. Envoyer un texte, une image et une note vocale.
5. Se connecter avec un deuxième compte sur un autre appareil pour vérifier la synchronisation en temps réel.

Les médias sont dans le bucket privé et sont affichés au moyen d'URL signées temporaires.

## Sécurité

- `supabase-config.js` contient une clé `sb_publishable_`, destinée à être utilisée dans une application cliente. Ne jamais y mettre une clé `sb_secret_`, `service_role`, un mot de passe de base de données ou un jeton privé.
- Les tables et fichiers sont protégés par RLS et les politiques Storage du script SQL.
- Le salon est commun à tous les utilisateurs authentifiés. Chaque utilisateur ne peut publier qu'en son propre nom.
- Les mots de passe Xtream ne sont pas enregistrés par Nova Store 1.4.5.

## Limites fonctionnelles actuelles

Le catalogue, les favoris, les téléchargements, les playlists et l'administration sont encore locaux à chaque appareil. Il n'existe pas encore de rôle administrateur sécurisé côté serveur ni de synchronisation du catalogue. L'interface Xtream enregistre le nom, le serveur et l'identifiant, mais le lecteur Xtream complet n'est pas implémenté. Les flux M3U ne sont pas lus par un lecteur intégré.

## Compilation web / Android

Depuis la racine du projet :

```bash
npm install
npm run build
```

Le build copie `index.html` et `supabase-config.js` dans `www/`, puis génère `www/supabase.min.js` à partir du SDK installé localement.

Pour Android :

```bash
npx cap add android   # uniquement si android/ n'existe pas
npx cap sync android
```

Le workflow GitHub Actions du dépôt construit automatiquement l'APK après un push sur `main`, ou peut être lancé depuis **Actions → Construire Nova Store APK → Run workflow**. Le fichier APK apparaît dans les artefacts de l'exécution réussie.
