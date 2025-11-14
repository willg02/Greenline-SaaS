# Greenline SaaS - Quick Start Guide

## 🚀 Get Up and Running in 15 Minutes

### Step 1: Install Dependencies (2 min)

```powershell
cd "c:\Users\jendg\OneDrive\Documents\greenline SaaS"
npm install
```

### Step 2: Create Supabase Project (5 min)

1. **Go to [supabase.com](https://supabase.com)** and sign in/sign up
2. Click **"New Project"**
3. Fill in:
   - **Name**: `greenline-saas`
   - **Database Password**: (generate a strong password and save it)
   - **Region**: Choose closest to you
   - **Pricing Plan**: Free
4. Click **"Create new project"**
5. Wait ~2 minutes for database initialization

### Step 3: Set Up Database Schema (3 min)

1. In your Supabase dashboard, go to **SQL Editor** (left sidebar)
2. Click **"New Query"**
3. Open `supabase/schema.sql` from this project
4. Copy ALL the contents and paste into the SQL Editor
5. Click **"Run"** (or press `Ctrl+Enter`)
6. You should see "Success. No rows returned"

### Step 3.5: Populate Seed Data (1 min)

1. Stay in the **SQL Editor**
2. Click **"New Query"** again
3. Open `supabase/seed.sql` from this project
4. Copy ALL the contents and paste into the SQL Editor
5. Click **"Run"**
6. You should see "Success" with plant and material counts
7. This adds 32+ plants and 10 materials to your database

### Step 4: Get API Credentials (1 min)

1. In Supabase dashboard, go to **Settings** (gear icon) → **API**
2. Find these two values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGc...` (long string)
3. Keep this tab open for the next step

### Step 5: Configure Environment (2 min)

1. In VS Code, open the `.env.example` file
2. Create a new file named `.env` (without the `.example`)
3. Copy the contents from `.env.example` to `.env`
4. Replace the placeholder values:

```env
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGc... (paste your anon key here)
VITE_APP_URL=http://localhost:3000
```

### Step 6: Start Development Server (1 min)

```powershell
npm run dev
```

The app will automatically open at `http://localhost:3000`

### Step 7: Create Your First Account (1 min)

1. Click **"Get Started"** or **"Sign Up"**
2. Fill in:
   - **Full Name**: Your name
   - **Email**: Your email
   - **Organization Name**: Your company name (e.g., "Greenline Landscaping")
   - **Password**: At least 8 characters
3. Click **"Create Account"**

### 🎉 You're Done!

You should now see the dashboard. You're ready to start building!

---

## ⚙️ Optional: Enable Google Sign-In

### Step 1: Create Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project (or select existing)
3. Go to **APIs & Services** → **Credentials**
4. Click **"Create Credentials"** → **"OAuth client ID"**
5. If prompted, configure the consent screen first
6. Choose **"Web application"**
7. Add authorized redirect URIs:
   - `http://localhost:3000`
   - `https://your-supabase-project.supabase.co/auth/v1/callback`
8. Copy your **Client ID** and **Client Secret**

### Step 2: Configure Supabase

1. In Supabase dashboard, go to **Authentication** → **Providers**
2. Find **Google** and toggle it on
3. Paste your Client ID and Client Secret
4. Click **"Save"**

---

## 🐛 Troubleshooting

### "Missing Supabase environment variables" error

- Make sure your `.env` file exists (not `.env.example`)
- Check that the file has the correct values (no quotes needed)
- Restart the dev server: Stop it (`Ctrl+C`) and run `npm run dev` again

### Can't sign up or login

- Check that you ran the database schema SQL successfully
- Look at the browser console (F12) for error messages
- Check Supabase dashboard → Authentication → Users to see if user was created

### Database tables don't exist

- Re-run the `supabase/schema.sql` in the SQL Editor
- Make sure you selected the correct project in Supabase

### Port 3000 already in use

- Change the port in `vite.config.js`:
  ```js
  server: {
    port: 3001, // or any other port
    open: true
  }
  ```

---

## 📚 Next Steps

1. **Explore the Dashboard**: Check out the UI and navigation
2. **Review the Database**: Open Supabase → Table Editor to see your schema
3. **Start Building Features**: Begin with Plant Compendium or Quote Estimator
4. **Read the README**: Full documentation in `README.md`

---

## 🆘 Need Help?

- Check the main `README.md` for detailed documentation
- Review the [Supabase documentation](https://supabase.com/docs)
- Check the [Vue 3 documentation](https://vuejs.org)
- Review the original static version for feature reference
