# Greenline SaaS - Plant Business Suite

Multi-tenant SaaS platform for landscaping professionals, installers, and garden centers. Manage quotes, track clients, and access a curated plant database—all in one cloud-based platform.

## 🚀 Features

- **Multi-Tenant Architecture**: Secure, isolated data for each organization
- **Authentication**: Email/password + Google OAuth
- **Plant Compendium**: Browse 30+ curated plants with detailed information
- **Quote Estimator**: Generate professional landscaping quotes with itemized pricing
- **Client Management**: Track clients and project history
- **Material Calculator**: Quick cubic yard calculations
- **Team Collaboration**: Invite team members with role-based permissions
- **Subscription Tiers**: Solo ($29/mo) and Team ($79/mo) plans

## 🛠️ Tech Stack

- **Frontend**: Vue 3, Vue Router, Pinia
- **Build Tool**: Vite
- **Backend**: Supabase (PostgreSQL + Auth + Realtime)
- **Payments**: Stripe (coming soon)
- **Hosting**: Vercel/Netlify (recommended)

## 📋 Prerequisites

- Node.js 18+ and npm
- Supabase account (free tier available)
- Git

## 🏗️ Setup Instructions

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd "greenline SaaS"
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Set Up Supabase

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Wait for the database to initialize (~2 minutes)
3. Go to **SQL Editor** in your Supabase dashboard
4. Copy the contents of `supabase/schema.sql` and run it (creates tables and RLS policies)
5. Copy the contents of `supabase/seed.sql` and run it (populates with 32+ plants and materials)
6. Get your project credentials:
   - Go to **Settings** → **API**
   - Copy the **Project URL** and **anon public** key

### 4. Configure Environment Variables

```bash
cp .env.example .env
```

Edit `.env` and add your Supabase credentials:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_APP_URL=http://localhost:3000
```

### 5. (Optional) Enable Google OAuth

1. In Supabase dashboard, go to **Authentication** → **Providers**
2. Enable **Google** provider
3. Follow the setup instructions to create Google OAuth credentials
4. Add authorized redirect URIs

### 6. Run Development Server

```bash
npm run dev
```

The app will open at `http://localhost:3000`

Note:
- Use the Vite dev server URL above. Opening `index.html` directly or using a generic "Live Preview" of the HTML file will not work with Vite (you'll see a blank page) because module resolution and HMR are handled by the dev server.
- If the page is blank, check the browser console for errors and verify your `.env` values are set.

## 🗄️ Database Schema

The database includes the following main tables:

- **organizations**: Multi-tenant companies/businesses
- **organization_members**: Users with roles (owner, admin, member)
- **clients**: Customer records per organization
- **plants**: Global and custom plant database
- **quotes**: Quote records with pricing breakdowns
- **quote_items**: Line items in quotes
- **materials**: Materials for calculator and estimates

All tables have Row Level Security (RLS) enabled for multi-tenant isolation.

## 📦 Build for Production

```bash
npm run build
```

The build output will be in the `dist/` directory.

## 🚀 Deployment

### Deploy to Vercel

1. Push your code to GitHub
2. Import project in [Vercel](https://vercel.com)
3. Add environment variables in Vercel dashboard
4. Deploy!

### Deploy to Netlify

1. Push your code to GitHub
2. Import project in [Netlify](https://netlify.com)
3. Build command: `npm run build`
4. Publish directory: `dist`
5. Add environment variables
6. Deploy!

### Update Supabase Auth Settings

After deployment, update your Supabase project:

1. Go to **Authentication** → **URL Configuration**
2. Add your production URL to **Site URL**
3. Add redirect URLs to **Redirect URLs**

## 🔑 First User Setup

1. Sign up at `/signup`
2. Enter your organization name (e.g., "Greenline Landscaping")
3. You'll be the owner with full permissions
4. Invite team members from Settings → Organization

## 📁 Project Structure

```
greenline-saas/
├── src/
│   ├── assets/
│   │   └── css/
│   │       └── global.css          # Global styles and design system
│   ├── components/
│   │   └── NavigationBar.vue       # Main navigation component
│   ├── lib/
│   │   └── supabase.js             # Supabase client config
│   ├── router/
│   │   └── index.js                # Vue Router configuration
│   ├── stores/
│   │   ├── auth.js                 # Authentication state
│   │   └── organization.js         # Organization/tenant state
│   ├── views/
│   │   ├── auth/
│   │   │   ├── LoginPage.vue
│   │   │   └── SignupPage.vue
│   │   ├── DashboardPage.vue       # Main dashboard
│   │   ├── LandingPage.vue         # Marketing landing page
│   │   ├── PlantCompendium.vue     # Plant database (to build)
│   │   ├── QuoteEstimator.vue      # Quote creator (to build)
│   │   ├── ClientManagement.vue    # Client list (to build)
│   │   └── MaterialCalculator.vue  # Calculator (to build)
│   ├── App.vue                     # Root component
│   └── main.js                     # App entry point
├── supabase/
│   └── schema.sql                  # Database schema
├── index.html
├── vite.config.js
├── package.json
└── README.md
```

## 🎯 Roadmap

### ✅ Phase 1: Foundation (Current)
- [x] Project setup with Vite + Vue 3
- [x] Supabase integration
- [x] Authentication (email + OAuth)
- [x] Multi-tenancy infrastructure
- [x] Database schema with RLS
- [x] Landing page
- [x] Dashboard layout

### 🚧 Phase 2: Core Features (Next)
- [ ] Plant Compendium UI
- [ ] Quote Estimator with PDF export
- [ ] Client Management CRUD
- [ ] Material Calculator
- [ ] Settings pages
- [ ] Migrate plant data from original repo

### 📅 Phase 3: Advanced Features
- [ ] Stripe integration for subscriptions
- [ ] Team member invitations
- [ ] Email notifications
- [ ] Quote templates
- [ ] Project tracking
- [ ] Mobile responsive optimization

### 🎨 Phase 4: Polish
- [ ] Advanced reporting & analytics
- [ ] Plant combination designer
- [ ] Seasonal calendar
- [ ] Mobile app (React Native/Capacitor)

## 🔐 Security

- Row Level Security (RLS) on all tables
- Organization-scoped data access
- Secure authentication with Supabase Auth
- Environment variables for sensitive data
- HTTPS enforced in production

## 🐛 Known Issues

- Plant database needs seeding with initial data
- Material calculator not yet implemented
- Stripe integration pending
- Email invitations require Edge Function

## 🤝 Contributing

This is currently a private project. If you'd like to contribute, please reach out.

## 📄 License

© 2025 Greenline. Professional plant installation & design services.

## 🆘 Support

For issues or questions:
- Check the [original repo](https://github.com/willg02/plant-business-suite)
- Review Supabase documentation
- Check Vue 3 documentation

## 🔗 Links

- **Original Static Version**: https://willg02.github.io/plant-business-suite/
- **GitHub Repo**: https://github.com/willg02/plant-business-suite
- **Supabase**: https://supabase.com
- **Vue 3**: https://vuejs.org
- **Vite**: https://vitejs.dev
