# 🐾 SAV MonRendezVousVeto — Guide d'installation complet

## Ce que tu vas avoir à la fin
- Un site de ticketing en ligne
- Les emails envoyés à sav@monrendezvousveto.fr créent automatiquement des tickets
- Si l'expéditeur est une clinique connue, le ticket lui est lié automatiquement
- Mises à jour en temps réel (pas besoin de rafraîchir)

---

## ÉTAPE 1 — Supabase (base de données)

1. Va sur **supabase.com** → "Start for free" → connecte-toi avec GitHub
2. Clique **"New project"**
   - Nom : `mrvv-sav`
   - Mot de passe : choisis-en un fort (note-le)
   - Région : `West EU (Paris)`
3. Attends 2 min que le projet se crée
4. Va dans **SQL Editor** (menu gauche) → **"New query"**
5. Copie-colle tout le contenu de `schema.sql` → clique **"Run"**
6. Tu dois voir "Success" et 3 tables dans "Table Editor"

### Récupérer tes clés Supabase
- Menu gauche → **Settings** → **API**
- Note ces 2 valeurs :
  - **Project URL** → ressemble à `https://xxxx.supabase.co`
  - **anon public key** → longue chaîne de caractères

---

## ÉTAPE 2 — GitHub (mettre le code en ligne)

1. Va sur **github.com** → "New repository"
   - Nom : `mrvv-sav`
   - Laisse tout par défaut → "Create repository"
2. Sur la page du repo → "uploading an existing file"
3. **Dézippe** le fichier `mrvv-sav.zip`
4. Glisse-dépose **tous les fichiers et dossiers** du dossier dézippé
5. Clique **"Commit changes"**

---

## ÉTAPE 3 — Vercel (hébergement + fonction email)

1. Va sur **vercel.com** → "Sign up" → "Continue with GitHub"
2. Clique **"Add New Project"** → importe `mrvv-sav`
3. Avant de cliquer Deploy, clique sur **"Environment Variables"** et ajoute :

| Nom | Valeur |
|-----|--------|
| `SUPABASE_URL` | ton Project URL de l'étape 1 |
| `SUPABASE_SERVICE_KEY` | la clé **service_role** (dans Settings → API) |

4. Clique **"Deploy"**
5. Ton site est en ligne ! Note l'URL (ex: `mrvv-sav.vercel.app`)

### Mettre tes clés Supabase dans l'interface
Dans le fichier `public/index.html`, remplace ces 2 lignes :
```
const SUPABASE_URL  = "REMPLACE_PAR_TON_URL_SUPABASE";
const SUPABASE_ANON = "REMPLACE_PAR_TON_ANON_KEY";
```
Par tes vraies valeurs, puis re-upload le fichier sur GitHub.

---

## ÉTAPE 4 — Sendgrid (réception des emails)

1. Va sur **sendgrid.com** → "Start for free" → crée un compte
2. Menu gauche → **Settings** → **Inbound Parse**
3. Clique **"Add Host & URL"**
   - **Receiving Domain** : `sav.monrendezvousveto.fr`
   - **Destination URL** : `https://mrvv-sav.vercel.app/api/inbound-email`
   - Coche "Post the raw, full MIME message"
   - Clique **"Add"**

4. Chez ton registrar (où tu as acheté monrendezvousveto.fr), ajoute un enregistrement DNS :
   ```
   Type : MX
   Nom  : sav
   Valeur: mx.sendgrid.net
   Priorité: 10
   ```
   (Attends 10-30 min pour la propagation DNS)

---

## TEST FINAL

Envoie un email à **sav@monrendezvousveto.fr** depuis n'importe quelle adresse.

Dans ton interface, tu dois voir apparaître un nouveau ticket automatiquement avec :
- ✅ Le sujet de l'email comme titre du ticket
- ✅ Le corps de l'email comme premier message
- ✅ La clinique liée si l'email de l'expéditeur correspond

Si la clinique n'est pas reconnue, tu verras une alerte jaune dans le ticket → va dans la fiche clinique et ajoute l'email pour les prochains emails.

---

## Problèmes fréquents

**Le ticket n'apparaît pas après l'email**
→ Vérifie les logs Vercel : Functions → `inbound-email` → View logs

**Erreur "permission denied" dans Supabase**
→ Dans Supabase → Authentication → Policies : désactive RLS sur les 3 tables (pour un prototype)

**Le site affiche "REMPLACE_PAR..."**
→ Tu n'as pas encore mis tes clés Supabase dans index.html

---

## Structure du projet

```
mrvv-sav/
  public/
    index.html        ← Interface complète (React + Supabase)
  api/
    inbound-email.js  ← Reçoit les emails Sendgrid → crée tickets
  schema.sql          ← Structure de la base de données
  package.json
  vercel.json
  README.md
```
