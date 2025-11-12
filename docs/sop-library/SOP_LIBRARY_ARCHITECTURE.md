# SOP Library Architecture

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Frontend (Vue 3 + Vite)                         │
├──────────────────────────────────────┬──────────────────────────────────┤
│                                                                          │
│  SOPLibrary.vue (Main View)                                              │
│  ├── Sidebar: FolderNode.vue (Recursive)                                │
│  ├── Main: Document Grid + Search                                       │
│  ├── Modals:                                                             │
│  │   ├── NewFolderModal.vue                                             │
│  │   ├── NewDocumentModal.vue                                           │
│  │   └── VersionHistoryModal.vue                                        │
│  └── Editor: DocumentEditor.vue (Split-pane)                            │
│      ├── Left: Markdown Editor                                          │
│      └── Right: Live Preview (marked library)                           │
│                                                                          │
└──────────────────────────────────────┬──────────────────────────────────┘
                                       │
                    ┌──────────────────┴──────────────────┐
                    │  Pinia Store: documents.js          │
                    │  ├── State: documents, folders      │
                    │  ├── Computed: folderHierarchy      │
                    │  └── Actions: CRUD operations       │
                    └──────────────────┬──────────────────┘
                                       │
                    ┌──────────────────┴──────────────────┐
                    │  Auth Store Integration              │
                    │  ├── currentUser                    │
                    │  └── currentOrganization            │
                    └──────────────────┬──────────────────┘
                                       │
                ┌──────────────────────┴──────────────────────┐
                │  Supabase Client (supabase.js)             │
                │  ├── RLS-Protected Queries                │
                │  ├── Realtime Subscriptions (future)      │
                │  └── Authentication State                  │
                └──────────────────────┬──────────────────────┘
                                       │
┌──────────────────────────────────────┴──────────────────────────────────┐
│                    Supabase Backend (PostgreSQL)                        │
├──────────────────────────────────────┬───────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │ Tables (with Row Level Security)                               │  │
│  │                                                                 │  │
│  │  folders                          documents                    │  │
│  │  ├── id                           ├── id                       │  │
│  │  ├── organization_id ◄────────┐   ├── organization_id          │  │
│  │  ├── name                      │   ├── folder_id ◄──────────┐  │  │
│  │  ├── parent_folder_id ◄──┐    │   ├── title                  │  │
│  │  └── created_by             │   │   ├── content              │  │
│  │                             │   │   ├── status                │  │
│  │  document_versions          │   │   ├── created_by            │  │
│  │  ├── id                     │   │   ├── updated_by            │  │
│  │  ├── document_id ◄──┐       │   │   └── created_at            │  │
│  │  ├── version_number │       │   └── ◆ updated_at             │  │
│  │  ├── content        │       │                                 │  │
│  │  ├── title          │       │   document_permissions         │  │
│  │  └── created_by     │       │   ├── id                       │  │
│  │                     │       │   ├── document_id ◄─┐          │  │
│  │  document_activity  │       │   ├── organization_role        │  │
│  │  ├── id             │       │   ├── can_view                 │  │
│  │  ├── document_id ◄──┼───┐   │   ├── can_edit                 │  │
│  │  ├── user_id        │   │   │   └── can_delete               │  │
│  │  ├── action         │   │   │                                 │  │
│  │  └── created_at     │   │   └── ◆ organizations             │  │
│  │                     │   │       ├── id                       │  │
│  └─────────────────────┼───┼────────├── organization_id (FK)    │  │
│                        │   └────────├── ...                     │  │
│  RLS Policies:         │            └── auth.users (FK)         │  │
│  ├── Users see         │                                        │  │
│  │   only org docs     │   Performance Indexes:                │  │
│  ├── Admins edit all   │   ├── documents(organization_id)     │  │
│  ├── Members view pub  │   ├── folders(organization_id)       │  │
│  └── RLS enforced      │   ├── document_versions(doc_id)      │  │
│      at DB level       │   ├── quotes(status)                 │  │
│                        │   └── materials(org_id)              │  │
│                        │                                       │  │
│                        │   Triggers:                           │  │
│                        │   ├── create_document_version()       │  │
│                        │   │   Creates version on UPDATE       │  │
│                        │   └── log_document_activity()         │  │
│                        │       Logs all changes                │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

## Data Flow - Creating and Saving a Document

```
User Types in Editor
        ↓
Editor Component Updates editingDocument ref
        ↓
Preview re-renders (marked() processes markdown)
        ↓
User clicks "Save"
        ↓
DocumentEditor.vue emits 'save' event with updates
        ↓
SOPLibrary.vue receives event
        ↓
Calls: documentsStore.updateDocument(docId, { title, content, status })
        ↓
Store calls: supabase.from('documents').update(...).eq('id', docId)
        ↓
Supabase Client:
  ├── Adds auth token to request
  ├── Enforces RLS policies
  └── Sends UPDATE query to PostgreSQL
        ↓
PostgreSQL:
  ├── Checks RLS policy (only user's org documents)
  ├── Updates documents table
  ├── Triggers execute:
  │   ├── create_document_version()
  │   │   Creates new row in document_versions
  │   └── log_document_activity()
  │       Creates new row in document_activity
  └── Returns updated document row
        ↓
Supabase Client receives response
        ↓
Store updates reactive state:
  ├── Updates documents array
  ├── Updates currentDocument
  └── Triggers re-render
        ↓
Vue component re-renders:
  ├── Shows new title
  ├── Shows updated timestamp
  ├── Shows "Last saved: Just now"
  └── Updates document card in list
        ↓
User sees confirmation!
```

## Database Security - RLS Policies

```
When user queries documents:

1. RLS Policy Evaluation:

   Policy: "Users can view documents they have access to"
   
   SELECT * FROM documents
   WHERE (
     organization_id IN (
       SELECT organization_id 
       FROM organization_members 
       WHERE user_id = auth.uid()
     )
   );

2. For UPDATE operations:

   - Must be in user's organization
   - Must be owner/admin
   - OR have explicit document permission
   - With can_edit = true

3. For DELETE operations:

   - Only organization owners/admins
   - Cascading delete of versions and activity logs
   - Audit trail preserved in activity table

Result: ✅ Multi-tenant security guaranteed at DB level
        ✅ No application code can bypass this
        ✅ Scales to thousands of organizations safely
```

## Component Communication Flow

```
┌─────────────────────────────────────────────────────────────┐
│  SOPLibrary (Parent)                                        │
│  ├── State:                                                 │
│  │   ├── searchQuery                                        │
│  │   ├── filterStatus                                       │
│  │   ├── currentDocumentSelected                            │
│  │   ├── showNewDocumentModal                               │
│  │   └── showVersionHistory                                 │
│  │                                                           │
│  ├── Renders:                                               │
│  │   ├── FolderNode.vue (recursive tree)                    │
│  │   │   └─> Emits: @select, @edit, @delete                │
│  │   │   ◄─ Props: folder, selected                         │
│  │   │                                                       │
│  │   ├── DocumentEditor.vue (when selected)                 │
│  │   │   └─> Emits: @save, @publish, @archive, @versions  │
│  │   │   ◄─ Props: document                                 │
│  │   │                                                       │
│  │   ├── NewFolderModal.vue (conditional)                  │
│  │   │   └─> Emits: @create, @close                        │
│  │   │                                                       │
│  │   ├── NewDocumentModal.vue (conditional)                │
│  │   │   └─> Emits: @create, @close                        │
│  │   │                                                       │
│  │   └── VersionHistoryModal.vue (conditional)             │
│  │       └─> Emits: @revert, @close                        │
│  │       ◄─ Props: document, versions                       │
│  │                                                           │
│  └── Stores:                                                │
│      └─> documentsStore (Pinia)                            │
│          ├── State: documents, folders, versions           │
│          └── Actions: CRUD + versioning                    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ DocumentEditor.vue Detail                           │   │
│  │ ├── Props: document                                 │   │
│  │ ├── Data: editingDocument (local copy)             │   │
│  │ │                                                   │   │
│  │ ├── Sections:                                       │   │
│  │ │ ├── Toolbar (title, status, buttons)             │   │
│  │ │ │   └─> Buttons: publish, archive, save, history │   │
│  │ │ │   └─> Emits: @publish, @archive, @versions    │   │
│  │ │ │                                                 │   │
│  │ │ ├── Formatting Bar (15+ buttons)                 │   │
│  │ │ │   └─> Inserts markdown syntax                  │   │
│  │ │ │   └─> Updates editingDocument.content         │   │
│  │ │ │                                                 │   │
│  │ │ ├── Editor (textarea)                            │   │
│  │ │ │   └─> Two-way bound to editingDocument.content │   │
│  │ │ │   └─> Emits: @input, @keydown                 │   │
│  │ │ │                                                 │   │
│  │ │ ├── Preview Panel (HTML)                         │   │
│  │ │ │   └─> Renders: marked(content)               │   │
│  │ │ │   └─> Reactive with content changes           │   │
│  │ │ │                                                 │   │
│  │ │ └── Footer (last saved, char count)              │   │
│  │ │                                                   │   │
│  │ └── Events:                                         │   │
│  │     ├─> @save → emits with updates                │   │
│  │     ├─> @publish → calls documentsStore            │   │
│  │     ├─> @archive → calls documentsStore            │   │
│  │     └─> @versions → shows history modal            │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Version History Workflow

```
Initial Document Creation:
  ├── New document created (no version yet)
  └── First save triggers create_document_version()
      └── Creates version 1

Each Subsequent Save:
  ├── User modifies content
  ├── Clicks "Save"
  ├── UPDATE documents SET content='...'
  ├── Trigger create_document_version() fires
  │   └── Gets last version_number (e.g., 5)
  │   └── Creates version 6 with new content
  └── activity log records 'updated'

Reverting to Version 3:
  ├── User clicks "History"
  ├── Views version 3 preview
  ├── Clicks "Revert to Version 3"
  ├── Action: UPDATE documents with version 3's content
  ├── Trigger creates version 7 (old content becomes new version)
  ├── Activity logs: 'version_reverted'
  └── User sees previous procedure restored!

Result: Complete audit trail, no data loss, easy recovery
```

## State Management (Pinia Store)

```
Documents Store State:

┌─ State (Reactive)
│  ├── documents: Document[]
│  │   └─ All documents for current org
│  ├── folders: Folder[]
│  │   └─ Folder hierarchy
│  ├── currentDocument: Document | null
│  │   └─ Editing document
│  ├── currentFolder: Folder | null
│  │   └─ Selected folder view
│  ├── versions: DocumentVersion[]
│  │   └─ Versions of current doc
│  ├── loading: boolean
│  └─ error: string | null
│
├─ Computed (Derived State)
│  ├── documentsByFolder
│  │   └─ Filter documents by folder
│  └─ folderHierarchy
│      └─ Build tree structure
│
└─ Actions (Methods)
   ├── Fetch Operations
   │  ├── fetchDocuments()
   │  ├── fetchFolders()
   │  ├── fetchDocument(id)
   │  └── fetchVersions(id)
   │
   ├── Folder Operations
   │  ├── createFolder(name, desc, parent)
   │  ├── updateFolder(id, updates)
   │  └── deleteFolder(id)
   │
   ├── Document Operations
   │  ├── createDocument(title, folderId, content)
   │  ├── updateDocument(id, updates)
   │  ├── publishDocument(id)
   │  ├── archiveDocument(id)
   │  └── deleteDocument(id)
   │
   ├── Version Operations
   │  └── revertToVersion(docId, versionNum)
   │
   └── Permission Operations
      ├── setDocumentPermissions(docId, perms)
      └── getDocumentPermissions(docId)
```

## Deployment Architecture

```
Local Development:
  ├── npm run dev
  ├── Vite dev server (hot reload)
  ├── Supabase local (optional)
  └── Browser at localhost:3000

Production (Vercel/Netlify):
  ├── npm run build
  ├── Vite bundles Vue + components
  ├── Supabase cloud (existing)
  ├── CDN for static assets
  └── Accessible globally

Database (Same for Dev/Prod):
  ├── Supabase PostgreSQL
  ├── RLS policies enforced
  ├── Real-time subscriptions ready
  ├── Automated backups
  └── Point-in-time recovery
```

## Security Layers

```
Layer 1: Authentication
├── Supabase Auth (JWT tokens)
└── Protected routes via authStore

Layer 2: Authorization (RLS)
├── Database-level enforcement
├── Per-user data isolation
├── Role-based access checks
└── No bypass possible

Layer 3: Data Validation
├── Type checking (Vue props)
├── Input validation (forms)
└── Server-side (RLS) validation

Layer 4: API Security
├── HTTPS only (Supabase)
├── CORS configured
├── SQL injection prevented (client library)
└── XSS prevention (Vue templating)

Result: ✅ Multi-layer defense
        ✅ Defense in depth
        ✅ No single point of failure
```

---

This architecture ensures:
- ✅ Scalability to thousands of organizations
- ✅ Data isolation and security
- ✅ Efficient queries with proper indexes
- ✅ Responsive UI with Pinia state management
- ✅ Automatic versioning and audit trails
- ✅ Easy testing of individual components
- ✅ Future-proof design for enhancements
