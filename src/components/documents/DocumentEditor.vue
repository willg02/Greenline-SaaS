<template>
  <div class="document-editor">
    <!-- Toolbar -->
    <div class="editor-toolbar">
      <div class="toolbar-left">
        <button @click="close" class="btn-back">← Back</button>
        <input 
          v-model="editingDocument.title" 
          type="text" 
          class="title-input"
          placeholder="Document title..."
        >
      </div>

      <div class="toolbar-right">
        <div class="status-display">
          <span class="status-label">Status:</span>
          <span class="status-value" :class="editingDocument.status">{{ editingDocument.status }}</span>
        </div>

        <button @click="versions" class="btn-secondary" title="Version History">📜 History</button>
        
        <button 
          v-if="editingDocument.status === 'draft'" 
          @click="publish" 
          class="btn-success"
          title="Publish document"
        >
          ✓ Publish
        </button>
        
        <button 
          v-if="editingDocument.status !== 'archived'" 
          @click="archive" 
          class="btn-secondary"
          title="Archive document"
        >
          📦 Archive
        </button>

        <button @click="saveChanges" class="btn-primary">💾 Save</button>
      </div>
    </div>

    <!-- Rich Text Editor -->
    <div class="editor-container">
      <div class="editor-formatting-bar">
        <button @click="formatBold" class="format-btn" :class="{ active: isFormatActive('bold') }" title="Bold (Ctrl+B)">
          <strong>B</strong>
        </button>
        <button @click="formatItalic" class="format-btn" :class="{ active: isFormatActive('italic') }" title="Italic (Ctrl+I)">
          <em>I</em>
        </button>
        <button @click="formatUnderline" class="format-btn" :class="{ active: isFormatActive('underline') }" title="Underline (Ctrl+U)">
          <u>U</u>
        </button>

        <div class="format-separator"></div>

        <button @click="formatHeading1" class="format-btn" title="Heading 1">H1</button>
        <button @click="formatHeading2" class="format-btn" title="Heading 2">H2</button>
        <button @click="formatHeading3" class="format-btn" title="Heading 3">H3</button>

        <div class="format-separator"></div>

        <button @click="formatUnorderedList" class="format-btn" title="Bullet List">• List</button>
        <button @click="formatOrderedList" class="format-btn" title="Numbered List">1. List</button>

        <div class="format-separator"></div>

        <button @click="formatQuote" class="format-btn" title="Block Quote">" Quote</button>
        <button @click="formatCode" class="format-btn" title="Code Block">< ></button>

        <div class="format-separator"></div>

        <button @click="insertLink" class="format-btn" title="Insert Link">🔗 Link</button>
      </div>

      <textarea
        ref="editorRef"
        v-model="editingDocument.content"
        class="content-editor"
        placeholder="Start typing your SOP or procedure here...

Use Markdown formatting:
# Heading 1
## Heading 2

**bold text**
*italic text*

- Bullet point
1. Numbered list

[Link text](https://example.com)

\`\`\`
Code block
\`\`\`
"
        @input="onContentChange"
        @keydown="handleKeydown"
      ></textarea>

      <!-- Preview Panel -->
      <div class="preview-panel">
        <div class="preview-header">
          <h3>Preview</h3>
        </div>
        <div class="preview-content" v-html="renderedPreview"></div>
      </div>
    </div>

    <!-- Footer -->
    <div class="editor-footer">
      <p class="last-saved">Last saved: {{ lastSavedTime }}</p>
      <div class="character-count">{{ editingDocument.content?.length || 0 }} characters</div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { marked } from 'https://cdn.jsdelivr.net/npm/marked@11.1.1/+esm';

const props = defineProps({
  document: {
    type: Object,
    required: true
  }
});

const emit = defineEmits(['save', 'close', 'publish', 'archive', 'versions']);

const editingDocument = ref({ ...props.document });
const editorRef = ref(null);
const lastSavedTime = ref('Just now');
const hasChanges = ref(false);

const renderedPreview = computed(() => {
  try {
    return marked(editingDocument.value.content || '');
  } catch (e) {
    return '<p>Error rendering preview</p>';
  }
});

const isFormatActive = (format) => {
  // This would need document.queryCommandState() in real implementation
  return false;
};

const onContentChange = () => {
  hasChanges.value = true;
};

const handleKeydown = (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key === 's') {
    e.preventDefault();
    saveChanges();
  } else if ((e.ctrlKey || e.metaKey) && e.key === 'b') {
    e.preventDefault();
    formatBold();
  } else if ((e.ctrlKey || e.metaKey) && e.key === 'i') {
    e.preventDefault();
    formatItalic();
  }
};

const formatBold = () => insertMarkdown('**', '**', 'bold text');
const formatItalic = () => insertMarkdown('*', '*', 'italic text');
const formatUnderline = () => insertMarkdown('<u>', '</u>', 'underlined text');
const formatHeading1 = () => insertMarkdown('# ', '', 'Heading 1');
const formatHeading2 = () => insertMarkdown('## ', '', 'Heading 2');
const formatHeading3 = () => insertMarkdown('### ', '', 'Heading 3');
const formatUnorderedList = () => insertMarkdown('- ', '', 'item');
const formatOrderedList = () => insertMarkdown('1. ', '', 'item');
const formatQuote = () => insertMarkdown('> ', '', 'quote');
const formatCode = () => insertMarkdown('```\n', '\n```', 'code');

const insertLink = () => {
  const url = prompt('Enter URL:', 'https://');
  if (url) {
    insertMarkdown('[', `](${url})`, 'Link text');
  }
};

const insertMarkdown = (before, after, placeholder) => {
  const textarea = editorRef.value;
  const start = textarea.selectionStart;
  const end = textarea.selectionEnd;
  const selectedText = editingDocument.value.content.substring(start, end) || placeholder;
  const newText = editingDocument.value.content.substring(0, start) + 
                  before + selectedText + after + 
                  editingDocument.value.content.substring(end);
  
  editingDocument.value.content = newText;
  hasChanges.value = true;

  // Restore cursor position
  setTimeout(() => {
    textarea.focus();
    textarea.setSelectionRange(start + before.length, start + before.length + selectedText.length);
  }, 0);
};

const saveChanges = async () => {
  if (!hasChanges.value) return;

  emit('save', {
    title: editingDocument.value.title,
    content: editingDocument.value.content,
    status: editingDocument.value.status
  });

  hasChanges.value = false;
  lastSavedTime.value = 'Just now';
  
  setTimeout(() => {
    lastSavedTime.value = new Date().toLocaleTimeString();
  }, 5000);
};

const publish = () => emit('publish');
const archive = () => emit('archive');
const versions = () => emit('versions');
const close = () => emit('close');

watch(() => props.document, (newDoc) => {
  editingDocument.value = { ...newDoc };
  hasChanges.value = false;
}, { deep: true });
</script>

<style scoped>
.document-editor {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
}

.editor-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border-bottom: 1px solid #e5e7eb;
  background: #fafafa;
  flex-wrap: wrap;
  gap: 1rem;
}

.toolbar-left,
.toolbar-right {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.toolbar-right {
  flex-wrap: wrap;
}

.btn-back {
  background: none;
  border: 1px solid #e5e7eb;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9rem;
  transition: background-color 0.2s;
}

.btn-back:hover {
  background-color: #f3f4f6;
}

.title-input {
  font-size: 1.3rem;
  font-weight: 600;
  border: none;
  outline: none;
  min-width: 300px;
  padding: 0.5rem;
  border-bottom: 2px solid transparent;
  transition: border-color 0.2s;
}

.title-input:focus {
  border-bottom-color: #22c55e;
}

.status-display {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.9rem;
}

.status-label {
  color: #6b7280;
}

.status-value {
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: 500;
}

.status-value.draft {
  background-color: #fef3c7;
  color: #92400e;
}

.status-value.published {
  background-color: #dcfce7;
  color: #166534;
}

.status-value.archived {
  background-color: #f3f4f6;
  color: #6b7280;
}

.btn-primary,
.btn-secondary,
.btn-success {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 4px;
  font-size: 0.9rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
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

.btn-success {
  background-color: #10b981;
  color: white;
}

.btn-success:hover {
  background-color: #059669;
}

.editor-container {
  display: flex;
  flex: 1;
  overflow: hidden;
}

.editor-formatting-bar {
  display: flex;
  align-items: center;
  padding: 0.75rem;
  border-right: 1px solid #e5e7eb;
  background: #fafafa;
  flex-direction: column;
  gap: 0.25rem;
  width: 60px;
  overflow-y: auto;
}

.format-btn {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #e5e7eb;
  background: white;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8rem;
  font-weight: 600;
  transition: all 0.2s;
}

.format-btn:hover {
  background-color: #f3f4f6;
  border-color: #22c55e;
}

.format-btn.active {
  background-color: #22c55e;
  color: white;
  border-color: #22c55e;
}

.format-separator {
  width: 100%;
  height: 1px;
  background-color: #e5e7eb;
  margin: 0.25rem 0;
}

.content-editor {
  flex: 1;
  padding: 1.5rem;
  border: none;
  outline: none;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 0.95rem;
  line-height: 1.6;
  resize: none;
  background-color: white;
}

.preview-panel {
  width: 40%;
  border-left: 1px solid #e5e7eb;
  display: flex;
  flex-direction: column;
  background: #fafafa;
}

.preview-header {
  padding: 1rem;
  border-bottom: 1px solid #e5e7eb;
  background: white;
}

.preview-header h3 {
  margin: 0;
  font-size: 0.95rem;
  font-weight: 600;
  color: #1f2937;
}

.preview-content {
  flex: 1;
  padding: 1.5rem;
  overflow-y: auto;
  font-size: 0.95rem;
  line-height: 1.6;
}

.preview-content :deep(h1),
.preview-content :deep(h2),
.preview-content :deep(h3),
.preview-content :deep(h4) {
  margin: 1rem 0 0.5rem 0;
  font-weight: 600;
  color: #1f2937;
}

.preview-content :deep(h1) {
  font-size: 1.8rem;
}

.preview-content :deep(h2) {
  font-size: 1.5rem;
}

.preview-content :deep(h3) {
  font-size: 1.2rem;
}

.preview-content :deep(h4) {
  font-size: 1rem;
}

.preview-content :deep(p) {
  margin: 0.5rem 0;
  color: #374151;
}

.preview-content :deep(ul),
.preview-content :deep(ol) {
  margin: 0.5rem 0 0.5rem 1.5rem;
  color: #374151;
}

.preview-content :deep(li) {
  margin: 0.25rem 0;
}

.preview-content :deep(blockquote) {
  margin: 0.5rem 0;
  padding-left: 1rem;
  border-left: 4px solid #22c55e;
  color: #6b7280;
  font-style: italic;
}

.preview-content :deep(code) {
  background-color: #f3f4f6;
  padding: 0.2rem 0.4rem;
  border-radius: 3px;
  font-family: 'Monaco', 'Menlo', monospace;
  font-size: 0.9rem;
}

.preview-content :deep(pre) {
  background-color: #1f2937;
  color: #f3f4f6;
  padding: 1rem;
  border-radius: 6px;
  overflow-x: auto;
  margin: 0.5rem 0;
}

.editor-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1rem;
  border-top: 1px solid #e5e7eb;
  background: #fafafa;
  font-size: 0.85rem;
  color: #6b7280;
}

.last-saved,
.character-count {
  margin: 0;
}

@media (max-width: 1200px) {
  .preview-panel {
    display: none;
  }

  .editor-formatting-bar {
    flex-direction: row;
    width: auto;
    border-right: none;
    border-bottom: 1px solid #e5e7eb;
    flex-wrap: wrap;
  }

  .format-btn {
    flex: 1;
  }

  .format-separator {
    width: 1px;
    height: 24px;
    margin: 0 0.25rem;
  }
}
</style>
