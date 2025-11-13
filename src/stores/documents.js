import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { supabase } from '../lib/supabase';
import { useAuthStore } from './auth';
import { useOrganizationStore } from './organization';

export const useDocumentsStore = defineStore('documents', () => {
  const authStore = useAuthStore();
  const orgStore = useOrganizationStore();

  // State
  const documents = ref([]);
  const folders = ref([]);
  const currentDocument = ref(null);
  const currentFolder = ref(null);
  const versions = ref([]);
  const loading = ref(false);
  const error = ref(null);

  // Computed
  const documentsByFolder = computed(() => {
    if (!currentFolder.value) {
      return documents.value.filter(doc => !doc.folder_id);
    }
    return documents.value.filter(doc => doc.folder_id === currentFolder.value.id);
  });

  const folderHierarchy = computed(() => {
    // Build tree structure of folders
    const roots = folders.value.filter(f => !f.parent_folder_id);
    
    const buildTree = (parentId) => {
      return folders.value
        .filter(f => f.parent_folder_id === parentId)
        .map(f => ({
          ...f,
          children: buildTree(f.id)
        }));
    };

    return roots.map(f => ({
      ...f,
      children: buildTree(f.id)
    }));
  });

  // Actions
  const fetchDocuments = async () => {
    if (!orgStore.currentOrganization?.id) return;

    loading.value = true;
    error.value = null;

    try {
      const { data, error: err } = await supabase
        .from('documents')
        .select('*')
        .eq('organization_id', orgStore.currentOrganization.id)
        .order('updated_at', { ascending: false });

      if (err) throw err;
      documents.value = data || [];
    } catch (err) {
      error.value = err.message;
      console.error('Error fetching documents:', err);
    } finally {
      loading.value = false;
    }
  };

  const fetchFolders = async () => {
    if (!orgStore.currentOrganization?.id) return;

    loading.value = true;
    error.value = null;

    try {
      const { data, error: err } = await supabase
        .from('folders')
        .select('*')
        .eq('organization_id', orgStore.currentOrganization.id)
        .order('name', { ascending: true });

      if (err) throw err;
      folders.value = data || [];
    } catch (err) {
      error.value = err.message;
      console.error('Error fetching folders:', err);
    } finally {
      loading.value = false;
    }
  };

  const createFolder = async (name, description = '', parentFolderId = null) => {
    if (!orgStore.currentOrganization?.id || !authStore.user?.id) return null;

    loading.value = true;
    error.value = null;

    try {
      const { data, error: err } = await supabase
        .from('folders')
        .insert({
          organization_id: orgStore.currentOrganization.id,
          name,
          description,
          parent_folder_id: parentFolderId,
          created_by: authStore.user.id
        })
        .select()
        .single();

      if (err) throw err;
      folders.value.push(data);
      return data;
    } catch (err) {
      error.value = err.message;
      console.error('Error creating folder:', err);
      return null;
    } finally {
      loading.value = false;
    }
  };

  const updateFolder = async (folderId, updates) => {
    loading.value = true;
    error.value = null;

    try {
      const { data, error: err } = await supabase
        .from('folders')
        .update(updates)
        .eq('id', folderId)
        .select()
        .single();

      if (err) throw err;
      const index = folders.value.findIndex(f => f.id === folderId);
      if (index >= 0) folders.value[index] = data;
      return data;
    } catch (err) {
      error.value = err.message;
      console.error('Error updating folder:', err);
      return null;
    } finally {
      loading.value = false;
    }
  };

  const deleteFolder = async (folderId) => {
    loading.value = true;
    error.value = null;

    try {
      const { error: err } = await supabase
        .from('folders')
        .delete()
        .eq('id', folderId);

      if (err) throw err;
      folders.value = folders.value.filter(f => f.id !== folderId);
      return true;
    } catch (err) {
      error.value = err.message;
      console.error('Error deleting folder:', err);
      return false;
    } finally {
      loading.value = false;
    }
  };

  const createDocument = async (title, folderId = null, content = '') => {
    if (!orgStore.currentOrganization?.id || !authStore.user?.id) return null;

    loading.value = true;
    error.value = null;

    try {
      const { data, error: err } = await supabase
        .from('documents')
        .insert({
          organization_id: orgStore.currentOrganization.id,
          folder_id: folderId,
          title,
          content,
          status: 'draft',
          created_by: authStore.user.id,
          updated_by: authStore.user.id
        })
        .select()
        .single();

      if (err) throw err;
      documents.value.push(data);
      currentDocument.value = data;
      return data;
    } catch (err) {
      error.value = err.message;
      console.error('Error creating document:', err);
      return null;
    } finally {
      loading.value = false;
    }
  };

  const fetchDocument = async (documentId) => {
    loading.value = true;
    error.value = null;

    try {
      const { data, error: err } = await supabase
        .from('documents')
        .select('*')
        .eq('id', documentId)
        .single();

      if (err) throw err;
      currentDocument.value = data;
      return data;
    } catch (err) {
      error.value = err.message;
      console.error('Error fetching document:', err);
      return null;
    } finally {
      loading.value = false;
    }
  };

  const updateDocument = async (documentId, updates) => {
    if (!authStore.user?.id) return null;

    loading.value = true;
    error.value = null;

    try {
      const { data, error: err } = await supabase
        .from('documents')
        .update({
          ...updates,
          updated_by: authStore.user.id
        })
        .eq('id', documentId)
        .select()
        .single();

      if (err) throw err;
      
      const index = documents.value.findIndex(d => d.id === documentId);
      if (index >= 0) documents.value[index] = data;
      
      if (currentDocument.value?.id === documentId) {
        currentDocument.value = data;
      }
      
      return data;
    } catch (err) {
      error.value = err.message;
      console.error('Error updating document:', err);
      return null;
    } finally {
      loading.value = false;
    }
  };

  const publishDocument = async (documentId) => {
    return updateDocument(documentId, { status: 'published' });
  };

  const archiveDocument = async (documentId) => {
    return updateDocument(documentId, { status: 'archived' });
  };

  const deleteDocument = async (documentId) => {
    loading.value = true;
    error.value = null;

    try {
      const { error: err } = await supabase
        .from('documents')
        .delete()
        .eq('id', documentId);

      if (err) throw err;
      documents.value = documents.value.filter(d => d.id !== documentId);
      if (currentDocument.value?.id === documentId) {
        currentDocument.value = null;
      }
      return true;
    } catch (err) {
      error.value = err.message;
      console.error('Error deleting document:', err);
      return false;
    } finally {
      loading.value = false;
    }
  };

  const fetchVersions = async (documentId) => {
    loading.value = true;
    error.value = null;

    try {
      const { data, error: err } = await supabase
        .from('document_versions')
        .select('*')
        .eq('document_id', documentId)
        .order('version_number', { ascending: false });

      if (err) throw err;
      versions.value = data || [];
      return data;
    } catch (err) {
      error.value = err.message;
      console.error('Error fetching versions:', err);
      return null;
    } finally {
      loading.value = false;
    }
  };

  const revertToVersion = async (documentId, versionNumber) => {
    if (!authStore.user?.id) return null;

    loading.value = true;
    error.value = null;

    try {
      // Get the version data
      const { data: versionData, error: fetchErr } = await supabase
        .from('document_versions')
        .select('*')
        .eq('document_id', documentId)
        .eq('version_number', versionNumber)
        .single();

      if (fetchErr) throw fetchErr;

      // Update document with version content
      const { data, error: updateErr } = await supabase
        .from('documents')
        .update({
          content: versionData.content,
          title: versionData.title,
          status: versionData.status,
          updated_by: authStore.user.id
        })
        .eq('id', documentId)
        .select()
        .single();

      if (updateErr) throw updateErr;

      const index = documents.value.findIndex(d => d.id === documentId);
      if (index >= 0) documents.value[index] = data;
      
      if (currentDocument.value?.id === documentId) {
        currentDocument.value = data;
      }

      // Log activity
      await supabase.from('document_activity').insert({
        document_id: documentId,
        user_id: authStore.user.id,
        action: 'version_reverted',
        changes: JSON.stringify({ reverted_to_version: versionNumber })
      });

      return data;
    } catch (err) {
      error.value = err.message;
      console.error('Error reverting version:', err);
      return null;
    } finally {
      loading.value = false;
    }
  };

  const setDocumentPermissions = async (documentId, permissions) => {
    loading.value = true;
    error.value = null;

    try {
      // Delete existing permissions
      const { error: deleteErr } = await supabase
        .from('document_permissions')
        .delete()
        .eq('document_id', documentId);

      if (deleteErr) throw deleteErr;

      // Insert new permissions
      const { error: insertErr } = await supabase
        .from('document_permissions')
        .insert(
          permissions.map(p => ({
            document_id: documentId,
            ...p
          }))
        );

      if (insertErr) throw insertErr;
      return true;
    } catch (err) {
      error.value = err.message;
      console.error('Error setting permissions:', err);
      return false;
    } finally {
      loading.value = false;
    }
  };

  const getDocumentPermissions = async (documentId) => {
    loading.value = true;
    error.value = null;

    try {
      const { data, error: err } = await supabase
        .from('document_permissions')
        .select('*')
        .eq('document_id', documentId);

      if (err) throw err;
      return data || [];
    } catch (err) {
      error.value = err.message;
      console.error('Error fetching permissions:', err);
      return [];
    } finally {
      loading.value = false;
    }
  };

  return {
    // State
    documents,
    folders,
    currentDocument,
    currentFolder,
    versions,
    loading,
    error,

    // Computed
    documentsByFolder,
    folderHierarchy,

    // Actions
    fetchDocuments,
    fetchFolders,
    createFolder,
    updateFolder,
    deleteFolder,
    createDocument,
    fetchDocument,
    updateDocument,
    publishDocument,
    archiveDocument,
    deleteDocument,
    fetchVersions,
    revertToVersion,
    setDocumentPermissions,
    getDocumentPermissions
  };
});
