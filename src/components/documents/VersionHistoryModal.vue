<template>
  <div class="modal-overlay" @click="closeModal">
    <div class="modal-content" @click.stop>
      <div class="modal-header">
        <h2>Version History</h2>
        <button @click="closeModal" class="btn-close">✕</button>
      </div>

      <div class="versions-container">
        <div v-if="versions.length === 0" class="no-versions">
          <p>No version history available</p>
        </div>

        <div v-for="version in versions" :key="version.id" class="version-item">
          <div class="version-header">
            <span class="version-number">Version {{ version.version_number }}</span>
            <span class="version-status" :class="version.status">{{ version.status }}</span>
            <span class="version-time">{{ formatDate(version.created_at) }}</span>
          </div>
          
          <div class="version-info">
            <p class="version-author">By {{ getAuthorName(version.created_by) }}</p>
            <p class="version-title">{{ version.title }}</p>
            <p class="version-description">{{ version.change_description || 'No description' }}</p>
          </div>

          <div class="version-actions">
            <button @click="previewVersion(version)" class="btn-secondary">👁 Preview</button>
            <button @click="revertToVersion(version.version_number)" class="btn-primary">↶ Revert</button>
          </div>
        </div>
      </div>

      <!-- Preview Section -->
      <div v-if="previewingVersion" class="preview-section">
        <div class="preview-header">
          <h3>Preview - Version {{ previewingVersion.version_number }}</h3>
          <button @click="previewingVersion = null" class="btn-close-small">✕</button>
        </div>
        <div class="preview-content" v-html="renderedPreview"></div>
      </div>

      <div class="modal-footer">
        <button @click="closeModal" class="btn-secondary">Close</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { marked } from 'https://cdn.jsdelivr.net/npm/marked@11.1.1/+esm';

const props = defineProps({
  document: {
    type: Object,
    required: true
  },
  versions: {
    type: Array,
    default: () => []
  }
});

const emit = defineEmits(['revert', 'close']);

const previewingVersion = ref(null);

const renderedPreview = computed(() => {
  if (!previewingVersion.value) return '';
  try {
    return marked(previewingVersion.value.content || '');
  } catch (e) {
    return '<p>Error rendering preview</p>';
  }
});

const formatDate = (date) => {
  return new Date(date).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

const getAuthorName = (userId) => {
  // In a real app, you'd fetch user names from store
  return userId.slice(0, 8) + '...';
};

const previewVersion = (version) => {
  previewingVersion.value = version;
};

const revertToVersion = (versionNumber) => {
  if (confirm(`Restore to version ${versionNumber}? Current version will be saved as new version.`)) {
    emit('revert', versionNumber);
  }
};

const closeModal = () => {
  emit('close');
};
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 8px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
  max-width: 700px;
  width: 90%;
  max-height: 80vh;
  display: flex;
  flex-direction: column;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid #e5e7eb;
}

.modal-header h2 {
  margin: 0;
  font-size: 1.3rem;
  color: #1f2937;
}

.btn-close,
.btn-close-small {
  background: none;
  border: none;
  cursor: pointer;
  color: #6b7280;
  transition: color 0.2s;
}

.btn-close {
  font-size: 1.5rem;
}

.btn-close-small {
  font-size: 1rem;
}

.btn-close:hover,
.btn-close-small:hover {
  color: #1f2937;
}

.versions-container {
  flex: 1;
  overflow-y: auto;
  padding: 1rem;
  border-bottom: 1px solid #e5e7eb;
}

.no-versions {
  text-align: center;
  padding: 2rem;
  color: #6b7280;
}

.version-item {
  padding: 1rem;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  margin-bottom: 1rem;
}

.version-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 0.75rem;
}

.version-number {
  font-weight: 600;
  color: #1f2937;
  font-size: 0.95rem;
}

.version-status {
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 500;
}

.version-status.draft {
  background-color: #fef3c7;
  color: #92400e;
}

.version-status.published {
  background-color: #dcfce7;
  color: #166534;
}

.version-status.archived {
  background-color: #f3f4f6;
  color: #6b7280;
}

.version-time {
  margin-left: auto;
  color: #6b7280;
  font-size: 0.85rem;
}

.version-info {
  margin-bottom: 0.75rem;
}

.version-author,
.version-title,
.version-description {
  margin: 0.25rem 0;
  font-size: 0.9rem;
}

.version-author {
  color: #6b7280;
}

.version-title {
  font-weight: 500;
  color: #1f2937;
}

.version-description {
  color: #6b7280;
  font-style: italic;
}

.version-actions {
  display: flex;
  gap: 0.75rem;
}

.btn-primary,
.btn-secondary {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 4px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 0.85rem;
}

.btn-primary {
  background-color: #22c55e;
  color: white;
}

.btn-primary:hover {
  background-color: #16a34a;
}

.btn-secondary {
  background-color: #e5e7eb;
  color: #374151;
}

.btn-secondary:hover {
  background-color: #d1d5db;
}

.preview-section {
  max-height: 300px;
  display: flex;
  flex-direction: column;
  border-top: 1px solid #e5e7eb;
}

.preview-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: #fafafa;
  border-bottom: 1px solid #e5e7eb;
}

.preview-header h3 {
  margin: 0;
  font-size: 0.95rem;
  font-weight: 600;
}

.preview-content {
  flex: 1;
  overflow-y: auto;
  padding: 1rem;
  font-size: 0.9rem;
  line-height: 1.5;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  padding: 1rem;
  border-top: 1px solid #e5e7eb;
}
</style>
