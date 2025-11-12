# SOP Library & Document Management System - Setup Guide

## Overview

The SOP Library is now fully integrated into your Greenline SaaS platform. It provides a complete document management system for your team to create, organize, and manage Standard Operating Procedures, training documents, and internal policies.

## Features Included

### Core Features ✅
- **Organized Folder Structure** - Create hierarchical folders to organize documents by category
- **Rich Text Editor** - Markdown-based editor with live preview
- **Document Management** - Create, read, update, delete, publish, and archive documents
- **Auto-Versioning** - Every save creates an automatic version for compliance and rollback
- **Version History** - View all versions, compare changes, and revert to any previous version
- **Search & Filter** - Find documents quickly with search across titles and content
- **Status Tracking** - Draft, Published, and Archived states
- **Role-Based Access** - Different permissions for Owner, Admin, and Member roles
- **Activity Logging** - Complete audit trail of who changed what and when

### Database Schema

**New Tables Created:**
- `folders` - Hierarchical folder structure
- `documents` - Main document records
- `document_versions` - Auto-versioned history (created on every save)
- `document_permissions` - Role-based access control
- `document_activity` - Audit log for compliance

## Setup Instructions

### Step 1: Add Database Schema

1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Create a new query
4. Copy the contents of `supabase/documents_schema.sql`
5. Execute the SQL (this will create all tables, indexes, RLS policies, and triggers)

**What This Does:**
- Creates 5 new tables with proper relationships
- Sets up Row Level Security (RLS) policies for multi-tenant isolation
- Creates automatic versioning triggers
- Sets up activity logging
- Creates performance indexes

### Step 2: Install Dependencies

Run this command to install the `marked` library for Markdown rendering:

```bash
npm install marked
```

### Step 3: Verify Setup

1. Start your dev server: `npm run dev`
2. Login to your organization
3. Click **"SOP Library"** in the navigation menu
4. You should see an empty state with options to create folders and documents

## Usage Guide

### Creating a Folder

1. Click the **"+"** button next to "Folders" in the sidebar
2. Enter folder name (e.g., "Installation Procedures")
3. Add optional description
4. Click **"Create Folder"**

**Folder Organization Tips:**
- Use flat or 1-2 level hierarchies for best UX
- Suggested categories:
  - Installation Procedures
  - Safety & Compliance
  - Plant Care Guides
  - Equipment Maintenance
  - Onboarding & Training
  - Customer Service

### Creating a Document

1. Click **"+ New Document"** in the header
2. Enter document title
3. Select folder (or leave as root)
4. Click **"Create Document"**
5. The editor will open with split view:
   - **Left**: Markdown editor
   - **Right**: Live HTML preview

### Writing Documents with Markdown

The editor uses Markdown formatting. Here's a quick guide:

```markdown
# Heading 1
## Heading 2
### Heading 3

**bold text**
*italic text*
_underlined text_

- Bullet point
  - Nested bullet
1. Numbered list
2. Second item

> Blockquote for important notes

[Link text](https://example.com)

`inline code`

```
code block
```
```

**Formatting Tips:**
- Use H1 (#) for titles, H2/H3 for sections
- Use blockquotes (>) for warnings and important info
- Use tables for step-by-step procedures
- Code blocks are great for technical instructions

### Publishing Documents

Documents start as **Draft** status:

1. Make your edits (auto-saves when you click Save)
2. Click **"✓ Publish"** to make it official
3. Published documents show completion status
4. Team members with access can view published docs

### Document Lifecycle

- **Draft** - Document in progress, visible to creators/admins only
- **Published** - Final version, visible according to permissions
- **Archived** - Hidden from main view, but still accessible in history

Click the status in the toolbar to see current state.

### Version History

Every time you save, a new version is automatically created:

1. Click **"📜 History"** in the toolbar
2. View all versions with timestamps and creators
3. Click **"👁 Preview"** to see any version's content
4. Click **"↶ Revert"** to restore an earlier version
   - This creates a new version with the old content
   - Your previous version is preserved

**Why Versioning?**
- Compliance & Auditing - Track all changes
- Safety - Easy rollback if mistakes are made
- Training - See how procedures evolved

### Managing Permissions

**Default Permissions (Pre-configured):**
- **Owner**: Can view, edit, delete all documents
- **Admin**: Can view, edit, delete all documents
- **Member**: Can view published documents, create new docs

To customize document permissions:
1. Click a document to open it
2. Look for permission controls (coming in next enhancement)
3. Set specific access per role

### Searching & Filtering

Use the search bar at the top:
- Search by document title
- Search by content (searches within document body)
- Filter by status (All, Drafts, Published, Archived)
- Results update in real-time

## Best Practices

### Document Organization
✅ **DO:**
- Create 5-10 main folders for main categories
- Use clear, descriptive titles
- Keep procedures to 1-3 pages each
- Include table of contents for longer docs
- Add examples and screenshots (in plain text format)

❌ **DON'T:**
- Create too many nested folders (max 2 levels)
- Store sensitive customer data in SOPs
- Upload large files (use links instead)
- Create duplicate documents (use search first)

### Writing SOPs
✅ **DO:**
- Start with a quick overview
- Number steps in order
- Include safety warnings
- Add troubleshooting section
- Include contact info for questions

❌ **DON'T:**
- Assume prior knowledge
- Skip obvious steps
- Use unclear abbreviations
- Leave documents in draft forever
- Forget to update when procedures change

### Team Usage
✅ **DO:**
- Review SOPs in team meetings
- Update docs quarterly
- Archive outdated procedures
- Use version history to track changes
- Reference procedures in emails/training

❌ **DON'T:**
- Create duplicate versions
- Hide important procedures
- Make documents too long
- Use overly technical language

## Advanced Features

### Future Enhancements (Not Yet Implemented)

The system is designed to support:

1. **Google Drive Integration**
   - Link GDrive docs to SOP Library
   - Auto-sync on changes
   - Embed GDrive content

2. **PDF Export**
   - Export single docs or entire folders
   - Branded templates with logo
   - TOC and bookmarks

3. **Document Templates**
   - Pre-built templates for common SOPs
   - Custom template library
   - Template categories

4. **Collaborative Editing**
   - Real-time collaboration
   - Comments and suggestions
   - @mentions for feedback

5. **Advanced Permissions**
   - Team-based access
   - Time-based access (e.g., temporary access)
   - Document encryption

## Troubleshooting

### Documents Not Showing?
1. Check that you're in the right organization
2. Make sure you have access permissions
3. Try refreshing the page
4. Check browser console for errors

### Versioning Not Working?
1. Ensure `documents_schema.sql` was fully executed
2. Check that triggers exist in Supabase
3. Try saving again

### Search Not Finding Documents?
1. Make sure document is published or you're the creator
2. Try a different search term
3. Check document status

### Permissions Errors?
1. Confirm you're logged in
2. Check your organization role
3. Verify document exists and isn't archived

## Integration with GreenTouch

For your **GreenTouch** landscaping business, suggested document structure:

```
📁 Installation Procedures
  ├─ Planting Trees & Shrubs
  ├─ Bed Preparation
  ├─ Mulching Standards
  └─ Post-Install Care

📁 Safety & Compliance
  ├─ Equipment Safety
  ├─ Chemical Handling
  ├─ Incident Reports
  └─ Insurance Requirements

📁 Plant Care Guides
  ├─ Watering Schedules
  ├─ Fertilization
  ├─ Pest Management
  └─ Seasonal Maintenance

📁 Employee Training
  ├─ Onboarding Checklist
  ├─ Tools & Equipment
  ├─ Customer Service
  └─ Problem Solving

📁 Administrative
  ├─ Schedule Template
  ├─ Pricing Guidelines
  ├─ Contractor Agreements
  └─ Quality Checklist
```

## API Reference (for developers)

The document system is powered by the `useDocumentsStore()` Pinia store:

```javascript
import { useDocumentsStore } from '@/stores/documents'

const docStore = useDocumentsStore()

// Folders
await docStore.fetchFolders()
await docStore.createFolder(name, description, parentFolderId)
await docStore.updateFolder(folderId, updates)
await docStore.deleteFolder(folderId)

// Documents
await docStore.fetchDocuments()
await docStore.createDocument(title, folderId, content)
await docStore.fetchDocument(documentId)
await docStore.updateDocument(documentId, updates)
await docStore.publishDocument(documentId)
await docStore.archiveDocument(documentId)
await docStore.deleteDocument(documentId)

// Versions
await docStore.fetchVersions(documentId)
await docStore.revertToVersion(documentId, versionNumber)

// Permissions
await docStore.setDocumentPermissions(documentId, permissions)
await docStore.getDocumentPermissions(documentId)
```

## Support & Questions

If you encounter issues or need enhancements:
1. Check this guide's troubleshooting section
2. Review the store code in `src/stores/documents.js`
3. Check Supabase logs for database errors
4. Verify RLS policies are enabled

## Summary

Your SOP Library is now **production-ready**! You have:

✅ Complete document management system
✅ Automatic versioning for compliance
✅ Role-based access control
✅ Full-text search capabilities
✅ Rich Markdown editor with preview
✅ Activity logging for audits
✅ Organization-scoped data isolation
✅ Mobile-responsive design

**Next Steps:**
1. Run the database schema setup
2. Create your folder structure
3. Start documenting your procedures
4. Train your team on using it
5. Keep SOPs updated as procedures evolve

Happy documenting! 🚀
