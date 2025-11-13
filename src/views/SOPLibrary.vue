<template>
  <div class="sop-library">
    <!-- Debug Info -->
    <div v-if="!orgStore.currentOrganization" style="padding: 2rem; background: #fef3c7; border: 2px solid #f59e0b; margin: 1rem;">
      <h3>⚠️ No Organization Selected</h3>
      <p>Please select or create an organization first.</p>
      <p>User: {{ authStore.user?.email || 'Not logged in' }}</p>
    </div>

    <!-- Header -->
    <div class="header">
      <div class="header-content">
        <h1>SOP Library</h1>
        <p class="subtitle">Standard Operating Procedures & Internal Documents</p>
      </div>
      <div class="header-actions">
        <router-link class="btn-secondary slim" :to="{ name: 'Dashboard' }">← Dashboard</router-link>
        <button class="btn-primary" @click="showNewDocumentModal = true">
          <span>+ New Document</span>
        </button>
      </div>
    </div>

    <!-- Main Content -->
    <div class="container">
      <!-- Sidebar with Folders -->
      <aside class="sidebar">
        <div class="sidebar-header">
          <h3>Folders</h3>
          <button @click="showNewFolderModal = true" class="btn-icon" title="New Folder">
            <span>+</span>
          </button>
        </div>

        <nav class="folder-tree">
          <div class="folder-item root" @click="selectFolder(null)">
            <span class="folder-icon">📄</span>
            <span>All Documents</span>
          </div>

          <div v-for="folder in folderHierarchy" :key="folder.id" class="folder-group">
            <FolderNode :folder="folder" :selected="currentFolder?.id === folder.id" @select="selectFolder" @edit="editFolder" @delete="deleteFolder" />
          </div>
        </nav>
      </aside>

      <!-- Main Content Area -->
      <main class="content">
        <div v-if="!hasAnyContent && !currentDocumentSelected" class="empty-onboarding">
          <h2>Welcome to your SOP Library</h2>
          <p class="onboarding-sub">Organize procedures, policies, and internal docs by folders. Get started in seconds.</p>
          <div class="onboarding-actions">
            <button class="btn-primary" @click="createStarterContent">Create Starter Content</button>
            <button class="btn-secondary" @click="showNewFolderModal = true">Add First Folder</button>
            <button class="btn-secondary" @click="showNewDocumentModal = true">Add First Document</button>
          </div>
          <ul class="onboarding-steps">
            <li>Create folders for areas like Operations, HR, Sales.</li>
            <li>Add documents, write in Markdown, preview live.</li>
            <li>Publish finalized SOPs, keep history with versions.</li>
          </ul>
        </div>

        <div v-if="!currentDocumentSelected" class="documents-list">
          <!-- Search Bar -->
          <div class="search-bar">
            <input 
              v-model="searchQuery" 
              type="text" 
              placeholder="Search documents..."
              class="search-input"
            >
            <select v-model="filterStatus" class="filter-select">
              <option value="">All Documents</option>
              <option value="draft">Drafts</option>
              <option value="published">Published</option>
              <option value="archived">Archived</option>
            </select>
          </div>

          <!-- Documents Grid -->
          <div class="documents-grid">
            <div v-if="filteredDocuments.length === 0" class="empty-state">
              <p v-if="documentsByFolder.length === 0">No documents in this folder yet.</p>
              <p v-else>No documents matching your search.</p>
            </div>

            <div v-for="doc in filteredDocuments" :key="doc.id" class="document-card">
              <div class="document-header">
                <h3 @click="viewDocument(doc.id)" class="document-title">{{ doc.title }}</h3>
                <div class="document-actions">
                  <button @click="editDocument(doc)" class="btn-icon" title="Edit">✏️</button>
                  <button @click="deleteDocument(doc.id)" class="btn-icon" title="Delete">🗑️</button>
                </div>
              </div>
              <p class="document-meta">
                <span class="status-badge" :class="doc.status">{{ doc.status }}</span>
                <span class="meta-info">Updated {{ formatDate(doc.updated_at) }}</span>
              </p>
              <div class="document-preview">
                {{ getPreview(doc.content) }}
              </div>
            </div>
          </div>
        </div>

        <!-- Document Viewer/Editor -->
        <div v-else class="document-viewer">
          <DocumentEditor 
            :document="currentDocument" 
            @save="saveDocument"
            @close="currentDocumentSelected = false"
            @publish="publishDocument"
            @archive="archiveDocument"
            @versions="viewVersions"
          />
        </div>
      </main>
    </div>

    <!-- Modals -->
    <NewFolderModal 
      v-if="showNewFolderModal"
      :parent-folder-id="currentFolder?.id"
      @create="handleCreateFolder"
      @close="showNewFolderModal = false"
    />

    <NewDocumentModal 
      v-if="showNewDocumentModal"
      :folder-id="currentFolder?.id"
      @create="handleCreateDocument"
      @close="showNewDocumentModal = false"
    />

    <VersionHistoryModal 
      v-if="showVersionHistory"
      :document="currentDocument"
      :versions="versions"
      @revert="handleRevertVersion"
      @close="showVersionHistory = false"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { storeToRefs } from 'pinia';
import { useDocumentsStore } from '../stores/documents';
import { useOrganizationStore } from '../stores/organization';
import { useAuthStore } from '../stores/auth';
import { usePermissionsStore } from '../stores/permissions';
import FolderNode from '../components/documents/FolderNode.vue';
import DocumentEditor from '../components/documents/DocumentEditor.vue';
import NewFolderModal from '../components/documents/NewFolderModal.vue';
import NewDocumentModal from '../components/documents/NewDocumentModal.vue';
import VersionHistoryModal from '../components/documents/VersionHistoryModal.vue';

const documentsStore = useDocumentsStore();
const orgStore = useOrganizationStore();
const authStore = useAuthStore();
const permissionsStore = usePermissionsStore();

// Local state
const searchQuery = ref('');
const filterStatus = ref('');
const showNewFolderModal = ref(false);
const showNewDocumentModal = ref(false);
const showVersionHistory = ref(false);
const currentDocumentSelected = ref(false);

// Extract reactive state via storeToRefs to preserve reactivity
const {
  documents,
  folders,
  currentDocument,
  currentFolder,
  versions,
  documentsByFolder,
  folderHierarchy,
} = storeToRefs(documentsStore);

// Methods (non-reactive) pulled directly from the store
const {
  fetchDocuments,
  fetchFolders,
  fetchVersions,
  revertToVersion,
  publishDocument: storePublish,
  archiveDocument: storeArchive,
  deleteDocument: storeDelete,
  updateDocument: storeUpdate
} = documentsStore;

// Computed
const hasAnyContent = computed(() => (documents.value?.length || 0) > 0 || (folders.value?.length || 0) > 0);
const filteredDocuments = computed(() => {
  return (documentsByFolder.value || []).filter(doc => {
    const matchesSearch = doc.title.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
                         (doc.content && doc.content.toLowerCase().includes(searchQuery.value.toLowerCase()));
    const matchesFilter = !filterStatus.value || doc.status === filterStatus.value;
    return matchesSearch && matchesFilter;
  });
});

// Permission-based helpers
const canCreateDocument = computed(() => permissionsStore.can('documents','create'));
const canCreateFolder = computed(() => permissionsStore.can('documents','create'));
const canEditAny = computed(() => permissionsStore.can('documents','update_any'));
const canPublish = computed(() => permissionsStore.can('documents','publish'));
const canDeleteAny = computed(() => permissionsStore.can('documents','delete_any'));
const canEditOwn = (doc) => doc.created_by === authStore.user?.id && permissionsStore.can('documents','update_own');
const canDeleteOwn = (doc) => doc.created_by === authStore.user?.id && permissionsStore.can('documents','delete_own');

// Methods
const selectFolder = (folder) => {
  currentFolder.value = folder;
};

const viewDocument = async (docId) => {
  await documentsStore.fetchDocument(docId);
  currentDocumentSelected.value = true;
};

const editDocument = async (doc) => {
  if (!(canEditAny.value || canEditOwn(doc))) return;
  await documentsStore.fetchDocument(doc.id);
  currentDocumentSelected.value = true;
};

const saveDocument = async (updates) => {
  await storeUpdate(currentDocument.value.id, updates);
};

const publishDocument = async () => {
  if (!canPublish.value) return;
  await storePublish(currentDocument.value.id);
};

const archiveDocument = async () => {
  await storeArchive(currentDocument.value.id);
};

const deleteDocument = async (docId) => {
  const target = documents.value.find(d => d.id === docId);
  if (!target) return;
  if (!(canDeleteAny.value || canDeleteOwn(target))) return;
  if (confirm('Are you sure you want to delete this document?')) {
    await storeDelete(docId);
  }
};

const handleCreateFolder = async (data) => {
  if (!canCreateFolder.value) return;
  await documentsStore.createFolder(data.name, data.description, data.parentFolderId);
  showNewFolderModal.value = false;
};

const handleCreateDocument = async (data) => {
  if (!canCreateDocument.value) return;
  await documentsStore.createDocument(data.title, data.folderId);
  showNewDocumentModal.value = false;
};

const editFolder = (folder) => {
  // Implementation for editing folder
  console.log('Edit folder:', folder);
};

const deleteFolder = async (folderId) => {
  if (confirm('Delete this folder? Documents will remain but be moved to parent.')) {
    await documentsStore.deleteFolder(folderId);
  }
};

const viewVersions = async () => {
  if (currentDocument.value) {
    await fetchVersions(currentDocument.value.id);
    showVersionHistory.value = true;
  }
};

const handleRevertVersion = async (versionNumber) => {
  await revertToVersion(currentDocument.value.id, versionNumber);
  showVersionHistory.value = false;
};

const formatDate = (date) => {
  return new Date(date).toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric' 
  });
};

const getPreview = (content) => {
  if (!content) return 'No content yet...';
  const text = content.replace(/<[^>]*>/g, '').slice(0, 150);
  return text + (text.length === 150 ? '...' : '');
};

const createStarterContent = async () => {
  const folder = await documentsStore.createFolder('Getting Started', 'Starter SOPs and examples');
  const sample = `# Welcome to Your SOP Library\n\nThis is your space for Standard Operating Procedures and internal documents.\n\n## Tips\n- Use folders to group documents by team or process.\n- Write in Markdown; preview updates live.\n- Publish when ready; every save keeps a version.\n\n## Next\nEdit this document to try the editor, or create your first real SOP.`;
  await documentsStore.createDocument('Welcome to SOP Library', folder?.id || null, sample);
  await fetchDocuments();
  await fetchFolders();
  currentDocumentSelected.value = true;
};

// Lifecycle
onMounted(async () => {
  console.log('SOPLibrary mounted');
  console.log('Current org:', orgStore.currentOrganization);
  await permissionsStore.load();
  
  if (orgStore.currentOrganization?.id) {
    console.log('Fetching documents and folders...');
    await fetchDocuments();
    await fetchFolders();
    console.log('Documents:', (documents.value || []).length);
    console.log('Folders:', (folders.value || []).length);
  } else {
    console.warn('No organization ID found');
  }
});
</script>

<style scoped>
.sop-library {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background-color: #f8f9fa;
}

.header {
  background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
  color: white;
  padding: 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.header-content h1 {
  margin: 0;
  font-size: 2rem;
  font-weight: 600;
}

.subtitle {
  margin: 0.5rem 0 0 0;
  font-size: 0.95rem;
  opacity: 0.9;
}

.container {
  display: flex;
  flex: 1;
  overflow: hidden;
}

.sidebar {
  width: 280px;
  background: white;
  border-right: 1px solid #e5e7eb;
  overflow-y: auto;
  padding: 1.5rem 1rem;
}

.sidebar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.sidebar-header h3 {
  margin: 0;
  font-size: 0.95rem;
  font-weight: 600;
  color: #1f2937;
}

.folder-tree {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.folder-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.95rem;
  transition: background-color 0.2s;
}

.folder-item:hover {
  background-color: #f3f4f6;
}

.folder-item.root {
  font-weight: 500;
  color: #1f2937;
}

.content {
  flex: 1;
  overflow-y: auto;
  padding: 2rem;
}

.documents-list {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.search-bar {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
}

.search-input,
.filter-select {
  padding: 0.75rem 1rem;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  font-size: 0.95rem;
}

.search-input {
  flex: 1;
  min-width: 250px;
}

.documents-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 1.5rem;
}

.empty-state {
  grid-column: 1 / -1;
  text-align: center;
  padding: 3rem;
  color: #6b7280;
}

.document-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 1.5rem;
  transition: box-shadow 0.2s, transform 0.2s;
  cursor: pointer;
}

.document-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

.document-header {
  display: flex;
  justify-content: space-between;
  align-items: start;
  margin-bottom: 1rem;
}

.document-title {
  margin: 0;
  font-size: 1.1rem;
  font-weight: 600;
  color: #1f2937;
  cursor: pointer;
  flex: 1;
}

.document-title:hover {
  color: #22c55e;
}

.document-actions {
  display: flex;
  gap: 0.5rem;
}

.document-meta {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin: 0.5rem 0;
  font-size: 0.85rem;
  color: #6b7280;
}

.status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: 500;
}

.status-badge.draft {
  background-color: #fef3c7;
  color: #92400e;
}

.status-badge.published {
  background-color: #dcfce7;
  color: #166534;
}

.status-badge.archived {
  background-color: #f3f4f6;
  color: #6b7280;
}

.document-preview {
  color: #6b7280;
  font-size: 0.95rem;
  line-height: 1.5;
  max-height: 100px;
  overflow: hidden;
}

.btn-primary {
  background-color: white;
  color: #22c55e;
  border: 2px solid white;
  padding: 0.75rem 1.5rem;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.2s;
}

.btn-primary:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.btn-icon {
  background: none;
  border: none;
  font-size: 1.2rem;
  cursor: pointer;
  padding: 0.25rem;
  transition: opacity 0.2s;
}

.btn-icon:hover {
  opacity: 0.7;
}

.document-viewer {
  height: 100%;
}

.empty-onboarding {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 2rem;
  margin-bottom: 2rem;
}

.empty-onboarding h2 {
  margin: 0 0 0.5rem 0;
}

.onboarding-sub {
  color: #6b7280;
  margin: 0 0 1rem 0;
}

.onboarding-actions {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.onboarding-steps {
  margin: 0;
  padding-left: 1.25rem;
  color: #4b5563;
}

.btn-secondary {
  background-color: #e5e7eb;
  color: #374151;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
}

.btn-secondary:hover { background-color: #d1d5db; }

.header-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.btn-secondary.slim {
  padding: 0.5rem 0.9rem;
  text-decoration: none;
}
</style>
