# Mettre QIRAT en ligne

Temps total : environ 30 minutes. Coût : 0 €.
À faire depuis un ordinateur.

Tu obtiendras une vraie adresse (par exemple `qirat-test.netlify.app`) que n'importe qui ouvre en un clic sur iPhone ou Android, sans compte, et peut installer comme une appli.

---

## Étape 1 : créer la base de données (Supabase)

1. Va sur **supabase.com** et crée un compte gratuit.
2. Clique sur **New project**.
   - Nom : `qirat`
   - Mot de passe de la base : génère-le et garde-le de côté
   - Région : **Paris** (ou la plus proche de la France)
3. Attends 1 à 2 minutes que le projet soit prêt.

## Étape 2 : installer la base et relier l'appli

1. Dans Supabase, ouvre **SQL Editor**, puis **New query**.
2. Ouvre le fichier `supabase.sql` de ce dossier, copie **tout** son contenu, colle-le, puis clique sur **Run**. Fais ensuite de même avec `supabase-v2.sql` (blocage des faux déclarants et suppression automatique).
3. Va dans **Authentication**, rubrique des fournisseurs de connexion (**Sign In / Providers**), et active **Allow anonymous sign-ins** (connexion anonyme). C'est ce qui permet d'utiliser l'appli sans créer de compte.
4. Va dans **Project Settings**, puis **API Keys** (ou **Data API**). Note deux choses :
   - **Project URL** : ressemble à `https://abcdefgh.supabase.co`
   - la clé **publishable** (commence par `sb_publishable_`) ou, à défaut, la clé **anon public**
5. Ouvre le fichier `config.js` de ce dossier avec un éditeur de texte (Bloc-notes sur Windows, TextEdit sur Mac en mode texte brut) et remplace les deux valeurs :

```js
window.QIRAT_CONFIG = {
  url: "https://abcdefgh.supabase.co",
  key: "sb_publishable_xxxxxxxxxxxxxxxx"
};
```

Garde bien les guillemets. Enregistre.

Ne mets jamais dans ce fichier la clé **secret** ni la clé **service_role** : elles donnent tous les droits sur la base.

## Étape 3 : mettre le site en ligne (Netlify)

1. Va sur **app.netlify.com/drop**.
2. Glisse **tout le dossier `qirat`** dans la zone de dépôt.
3. Netlify te donne une adresse en `.netlify.app`. Crée un compte gratuit quand il te le propose, sinon le site est supprimé au bout de quelques temps.
4. Dans Netlify, **Site configuration**, puis **Change site name** : choisis par exemple `qirat-test`. Ton adresse devient `https://qirat-test.netlify.app`.
5. Retourne dans Supabase, **Authentication**, puis **URL Configuration** :
   - **Site URL** : colle ton adresse Netlify
   - **Redirect URLs** : ajoute la même adresse

Pour mettre à jour l'appli plus tard : dans Netlify, onglet **Deploys**, glisse à nouveau le dossier.

## Étape 4 : devenir modérateur (toi et ton associé)

1. Ouvre ton adresse Netlify sur ton téléphone.
2. Onglet **Moi**, puis **Espace modérateur** : entre ton e-mail et touche **Recevoir le lien de connexion**.
3. Ouvre l'e-mail **sur le même téléphone** et touche le lien. Tu reviens dans l'appli, connecté.
4. Ton associé fait la même chose de son côté.
5. Dans Supabase, **SQL Editor**, **New query**, colle ceci en mettant vos deux e-mails, puis **Run** :

```sql
insert into public.admins (user_id, email)
select id, email from auth.users where email in ('ton.email@exemple.fr', 'email.associe@exemple.fr')
on conflict (user_id) do nothing;
```

6. Rouvre l'appli : le bouton **Modération** apparaît dans l'onglet Moi.

## Étape 5 : installer l'appli sur le téléphone

**iPhone** : ouvre l'adresse dans **Safari**, bouton **Partager** (carré avec une flèche), puis **Sur l'écran d'accueil**.

**Android** : ouvre l'adresse dans **Chrome**, menu **⋮**, puis **Installer l'application** (ou **Ajouter à l'écran d'accueil**).

L'icône QIRAT apparaît sur l'écran d'accueil et s'ouvre en plein écran, comme une appli.

## Étape 6 : envoyer le lien aux testeurs

Envoie simplement ton adresse `https://qirat-test.netlify.app`. Rien à installer, aucun compte à créer.

## Le test à faire

1. Les 3 annonces marquées **TEST** apparaissent sur l'accueil (onglet **Toute l'IDF** pour toutes les voir).
2. Un testeur déclare une janaza depuis l'onglet **Déclarer**.
3. Toi ou ton associé, dans **Moi > Modération**, cochez les deux vérifications et publiez.
4. L'annonce apparaît chez tout le monde en quelques secondes.
5. Chacun touche **J'y serai** et réserve un juz de la khatma.

Pour retirer les annonces TEST : **Moi > Modération > Annonces publiées > Retirer l'annonce**.

---

## Bon à savoir

- **Gratuit** : Supabase et Netlify sont gratuits à ce niveau d'utilisation. Un projet Supabase gratuit se met en pause après une semaine sans aucune visite : il suffit de le réactiver depuis le tableau de bord Supabase.
- **Sécurité** : les règles de la base sont dans `supabase.sql`. Seuls les modérateurs peuvent publier une annonce. Les téléphones des déclarants ne sont visibles que par les modérateurs.
- **Mosquées suivies, thèmes de rappels, ville** : enregistrés sur le téléphone de chaque personne.
- **Notifications push** : pas encore dans cette version de test.

## Contenu du dossier

| Fichier | Rôle |
|---|---|
| `index.html` | L'appli |
| `config.js` | Le lien vers ta base Supabase (à remplir) |
| `supabase.sql` | La base de données et ses règles de sécurité |
| `manifest.webmanifest`, `sw.js`, `icons/` | L'installation sur téléphone et le fonctionnement hors connexion |
| `vendor/supabase.js` | La bibliothèque de connexion à Supabase |
