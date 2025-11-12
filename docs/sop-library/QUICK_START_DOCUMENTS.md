# SOP Library - Quick Start (5 Minutes)

## What You Need to Do RIGHT NOW

### 1. Add Database Tables (3 minutes)

1. Open [Supabase Dashboard](https://supabase.com)
2. Go to your project → **SQL Editor**
3. Click **"New Query"**
4. Copy this entire file: `supabase/documents_schema.sql`
5. Paste into the editor
6. Click **"Run"** (it will take a few seconds)
7. You should see "Success" messages for each table

**That's it!** Your database is ready.

### 2. Install Dependencies (1 minute)

Open your terminal and run:

```bash
npm install marked
```

### 3. Start the App (1 minute)

```bash
npm run dev
```

Then:
1. Go to http://localhost:3000
2. Login to your organization
3. Click **"SOP Library"** in the navigation menu
4. You should see an empty folder structure

✅ **You're Done!** Start creating documents!

---

## First Steps (After Setup)

### Create a Folder
1. Click the **"+"** next to "Folders"
2. Enter name: `Getting Started`
3. Click **"Create Folder"**

### Create a Document
1. Click **"+ New Document"**
2. Enter title: `First SOP Document`
3. Select your folder
4. Click **"Create Document"**

### Edit the Document
1. Write some text using Markdown:
```
# My First SOP

This is a **test** document.

- Item 1
- Item 2
```

2. See the preview on the right
3. Click **"Save"** (you'll see a new version created)

### Publish It
1. Click **"✓ Publish"** button
2. Status changes to "Published"
3. Done! Others can now see it

---

## Common Issues

**"Table doesn't exist" error?**
- Re-run the SQL from `documents_schema.sql`
- Make sure you didn't get any errors

**"Import not found: marked"?**
- Run `npm install marked` again
- Restart dev server

**Documents not showing?**
- Refresh the page
- Make sure you're logged in
- Check your organization

---

## What's Next?

1. ✅ Read `DOCUMENTS_SETUP.md` for full feature guide
2. ✅ Create your folder structure
3. ✅ Start writing SOPs
4. ✅ Train your team
5. ✅ Keep docs updated

---

## File Reference

If you want to understand what was built:

- **Database**: `supabase/documents_schema.sql`
- **Store**: `src/stores/documents.js`
- **Main View**: `src/views/SOPLibrary.vue`
- **Editor**: `src/components/documents/DocumentEditor.vue`
- **Setup Guide**: `DOCUMENTS_SETUP.md`
- **Full Details**: `SOP_LIBRARY_IMPLEMENTATION.md`

---

## Questions?

Check the troubleshooting section in `DOCUMENTS_SETUP.md` for answers to common issues.

**Enjoy your new Document Management System!** 🚀
