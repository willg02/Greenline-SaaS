# Deployment Checklist

## 📋 Pre-Deployment

### Code & Build
- [ ] All features tested locally
- [ ] No console errors in browser
- [ ] Run `npm run build` successfully
- [ ] Test production build with `npm run preview`
- [ ] All environment variables documented

### Supabase Setup
- [ ] Database schema deployed and tested
- [ ] Row Level Security (RLS) policies verified
- [ ] All tables have appropriate indexes
- [ ] Test queries perform well
- [ ] Backup strategy in place

### Security
- [ ] `.env` file in `.gitignore` (verified)
- [ ] No sensitive data in code
- [ ] CORS settings configured in Supabase
- [ ] Rate limiting considered
- [ ] SQL injection prevention (using Supabase client ✓)

---

## 🚀 Deployment to Vercel

### 1. Push to GitHub
```bash
git init
git add .
git commit -m "Initial commit - Greenline SaaS platform"
git branch -M main
git remote add origin <your-repo-url>
git push -u origin main
```

### 2. Deploy to Vercel

1. Go to [vercel.com](https://vercel.com) and sign in
2. Click **"Add New..."** → **"Project"**
3. Import your GitHub repository
4. Configure project:
   - **Framework Preset**: Vite
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`
   - **Install Command**: `npm install`

5. Add Environment Variables:
   - `VITE_SUPABASE_URL`: Your Supabase project URL
   - `VITE_SUPABASE_ANON_KEY`: Your Supabase anon key
   - `VITE_APP_URL`: Your Vercel deployment URL (e.g., `https://greenline-saas.vercel.app`)

6. Click **"Deploy"**

### 3. Configure Supabase for Production

1. In Supabase dashboard, go to **Authentication** → **URL Configuration**
2. Add your Vercel URL to:
   - **Site URL**: `https://your-app.vercel.app`
   - **Redirect URLs**: Add `https://your-app.vercel.app/**`
3. Save changes

### 4. Test Production Deployment

- [ ] Landing page loads
- [ ] Sign up flow works
- [ ] Login flow works
- [ ] Google OAuth works (if enabled)
- [ ] Dashboard loads
- [ ] Organization creation works
- [ ] Navigation works
- [ ] No console errors

---

## 🌐 Deployment to Netlify (Alternative)

### 1. Push to GitHub (same as above)

### 2. Deploy to Netlify

1. Go to [netlify.com](https://netlify.com) and sign in
2. Click **"Add new site"** → **"Import an existing project"**
3. Connect to GitHub and select your repository
4. Configure build settings:
   - **Build command**: `npm run build`
   - **Publish directory**: `dist`
   - **Node version**: 18

5. Add Environment Variables (same as Vercel):
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
   - `VITE_APP_URL`

6. Click **"Deploy site"**

### 3. Configure Supabase (same as Vercel step 3)

### 4. Test Production (same as Vercel step 4)

---

## ⚙️ Post-Deployment Configuration

### Custom Domain (Optional)

#### Vercel:
1. Go to project **Settings** → **Domains**
2. Add your custom domain
3. Follow DNS configuration instructions
4. Update `VITE_APP_URL` in environment variables
5. Update Supabase redirect URLs

#### Netlify:
1. Go to **Site settings** → **Domain management**
2. Add custom domain
3. Follow DNS instructions
4. Update environment variables and Supabase URLs

### Enable HTTPS
- Both Vercel and Netlify provide automatic HTTPS (Let's Encrypt)
- No additional configuration needed

### Set Up Analytics (Optional)

#### Vercel Analytics:
- Enable in Vercel dashboard (free tier available)
- No code changes needed

#### Google Analytics:
1. Create GA4 property
2. Add tracking code to `index.html`
3. Consider GDPR compliance

---

## 📊 Monitoring & Maintenance

### Performance Monitoring
- [ ] Set up Vercel/Netlify analytics
- [ ] Monitor Supabase dashboard for query performance
- [ ] Check error logs regularly

### Database Maintenance
- [ ] Set up automated backups (Supabase Pro)
- [ ] Monitor database size
- [ ] Review slow queries in Supabase Dashboard

### Security Updates
- [ ] Enable Dependabot on GitHub
- [ ] Run `npm audit` monthly
- [ ] Update dependencies regularly
- [ ] Review Supabase security advisories

---

## 🎯 Optimization Tips

### Performance
- [ ] Enable Vercel/Netlify CDN caching
- [ ] Optimize images (consider using Supabase Storage)
- [ ] Enable code splitting (Vite does this automatically)
- [ ] Monitor Core Web Vitals

### SEO
- [ ] Add meta tags to landing page
- [ ] Create `robots.txt`
- [ ] Add `sitemap.xml`
- [ ] Configure OpenGraph tags

### Cost Management
- [ ] Monitor Supabase usage (free tier limits)
- [ ] Set up billing alerts
- [ ] Review Vercel/Netlify bandwidth usage

---

## 🐛 Troubleshooting

### Build Fails on Vercel/Netlify
- Check Node version (should be 18+)
- Verify all dependencies are in `package.json`
- Look at build logs for specific errors
- Test `npm run build` locally first

### Environment Variables Not Working
- Verify variable names start with `VITE_`
- Redeploy after changing environment variables
- Check browser console for specific errors

### Authentication Not Working
- Verify Supabase redirect URLs include production domain
- Check CORS settings in Supabase
- Verify environment variables are correct

### Database Connection Issues
- Check Supabase project status
- Verify RLS policies allow access
- Check network tab in browser DevTools

---

## 📝 Pre-Launch Checklist

- [ ] Terms of Service page created
- [ ] Privacy Policy page created
- [ ] Contact/Support information added
- [ ] Error tracking set up (e.g., Sentry)
- [ ] Backup strategy tested
- [ ] Load testing performed
- [ ] Mobile responsiveness verified
- [ ] Cross-browser testing done
- [ ] Accessibility audit completed
- [ ] Documentation up to date

---

## 🎉 Launch!

Once everything is checked off, you're ready to share your app with users!

### Next Steps After Launch:
1. Monitor error logs daily for first week
2. Collect user feedback
3. Plan feature iterations
4. Set up customer support system
5. Consider implementing analytics for user behavior
