# Nova Store 2.0 — version 1.4.5 (Supabase)

Application HTML/CSS/JavaScript + Capacitor 6.

## Intégration Supabase incluse
- Client Supabase JS v2 initialisé avec le Project URL et la clé publique `sb_publishable_`.
- Inscription par e-mail/mot de passe, connexion et déconnexion via Supabase Auth.
- Profils publics limités au nom affiché (aucun e-mail dans la table de profils).
- Nova Chat en temps réel via Postgres Changes.
- Envoi de messages texte, photos compressées et notes vocales.
- Médias conservés dans le bucket privé `nova-chat` et affichés avec des URL signées temporaires.
- RLS sur les tables et le stockage : les utilisateurs ne peuvent écrire que leurs propres messages et fichiers.

## Étape obligatoire dans Supabase
1. Ouvrir le projet Supabase.
2. Aller dans **SQL Editor → New query**.
3. Ouvrir le fichier `supabase-setup.sql`, copier tout son contenu et l'exécuter.
4. Dans **Authentication → URL Configuration**, définir l'URL de ton site/app de test comme Site URL et ajouter les URL de redirection utilisées par ton hébergement si nécessaire.
5. Dans **Authentication → Providers → Email**, vérifier les réglages de confirmation e-mail. Si la confirmation est activée, l'utilisateur doit confirmer son adresse avant de se connecter.
6. Tester avec deux comptes différents pour confirmer que les messages, photos et vocaux se synchronisent entre appareils.

Le script SQL crée les tables `profiles` et `nova_messages`, les politiques RLS, le bucket privé `nova-chat`, les règles d'accès aux fichiers et active Realtime pour les messages.

## Clés et sécurité
- `supabase-config.js` contient uniquement la clé publique `sb_publishable_`, prévue pour le navigateur et les applications mobiles.
- Ne jamais ajouter une clé `sb_secret_`, `service_role`, un mot de passe de base de données ou un jeton privé au projet client.
- Le client ne peut accéder qu'aux opérations permises par les politiques RLS. Vérifier régulièrement **Supabase → Security Advisor**.
- Le bucket `nova-chat` est privé. Les médias sont consultés via des URL signées de courte durée.
- Le compte admin et la synchronisation du catalogue ne sont pas encore activés : le panneau d'administration et les catalogues restent locaux dans cette version.

## Build Web
```bash
npm install
npm run build
```
Le dossier `www/` reçoit `index.html` et `supabase-config.js`. Le client Supabase JS v2 est intégré localement dans `www/supabase.min.js` pendant le build. Les appels réseau à Supabase nécessitent toujours Internet.

## Build Android
```bash
npx cap sync android
npx cap open android
```
Si le dossier `android/` n'existe pas encore :
```bash
npx cap add android
npx cap sync android
```

## Vérification
L'intégration n'est réellement opérationnelle qu'après exécution de `supabase-setup.sql` dans le bon projet, puis test de l'inscription et du chat avec deux comptes distincts.


## Correctif 1.4.2 — chargement Supabase

Le chargement de la bibliothèque Supabase utilise maintenant un repli parser-bloquant : si jsDelivr échoue, le navigateur attend le chargement depuis unpkg avant d'exécuter le code Nova Store. Cela évite que l'application vérifie `window.supabase` trop tôt pendant le chargement du second CDN. Une connexion Internet reste nécessaire au premier chargement de cette bibliothèque et aux appels Supabase.

Si le message persiste, vérifier que le téléphone peut ouvrir `https://cdn.jsdelivr.net` et `https://unpkg.com`, désactiver temporairement VPN/filtrage DNS, puis fermer complètement et relancer l'application.


## Version 1.4.5 — corrections de stabilité

- Le reset local conserve désormais la structure complète des paramètres.
- Les événements d'authentification ne créent plus volontairement plusieurs abonnements Realtime concurrents.
- Les chargements du chat ignorent les réponses devenues obsolètes après un changement de compte.
- Le mot de passe Xtream n'est plus conservé dans le stockage local ni dans les sauvegardes. Les fonctions de lecture Xtream restent à intégrer.
- Le script SQL crée aussi les profils des comptes Supabase déjà existants avant l'installation.
- Le build vérifie que le bundle Supabase local a bien été généré avant la compilation Android.

**Limites à connaître :** le catalogue, les favoris, les téléchargements et l'administration restent stockés sur l'appareil. L'administration n'a pas encore de rôle serveur ni de synchronisation multi-utilisateur. Le lecteur IPTV/Xtream n'est pas implémenté.
