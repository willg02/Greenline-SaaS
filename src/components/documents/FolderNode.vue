<template>
  <div class="folder-node">
    <div 
      class="folder-item" 
      :class="{ selected }"
      @click="selectFolder"
    >
      <span class="expand-icon" @click.stop="toggleExpand" v-if="folder.children?.length">
        {{ expanded ? '▼' : '▶' }}
      </span>
      <span v-else class="expand-icon-placeholder"></span>
      <span class="folder-icon">📁</span>
      <span class="folder-name">{{ folder.name }}</span>
      <div class="folder-actions" @click.stop>
        <button @click="editFolder" class="btn-icon" title="Edit">✏️</button>
        <button @click="deleteFolder" class="btn-icon" title="Delete">🗑️</button>
      </div>
    </div>

    <div v-if="expanded && folder.children?.length" class="folder-children">
      <FolderNode 
        v-for="child in folder.children" 
        :key="child.id"
        :folder="child"
        :selected="selected && child.id === selected.id"
        @select="selectChild"
        @edit="editChild"
        @delete="deleteChild"
      />
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';

const props = defineProps({
  folder: {
    type: Object,
    required: true
  },
  selected: Boolean
});

const emit = defineEmits(['select', 'edit', 'delete']);

const expanded = ref(true);

const toggleExpand = () => {
  expanded.value = !expanded.value;
};

const selectFolder = () => {
  emit('select', props.folder);
};

const editFolder = () => {
  emit('edit', props.folder);
};

const deleteFolder = () => {
  emit('delete', props.folder.id);
};

const selectChild = (folder) => {
  emit('select', folder);
};

const editChild = (folder) => {
  emit('edit', folder);
};

const deleteChild = (folderId) => {
  emit('delete', folderId);
};
</script>

<style scoped>
.folder-node {
  display: flex;
  flex-direction: column;
}

.folder-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.95rem;
  transition: background-color 0.2s;
  position: relative;
}

.folder-item:hover {
  background-color: #f3f4f6;
}

.folder-item.selected {
  background-color: #dcfce7;
  font-weight: 500;
  color: #166534;
}

.expand-icon,
.expand-icon-placeholder {
  width: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.8rem;
  color: #6b7280;
}

.expand-icon-placeholder {
  cursor: default;
}

.folder-icon {
  font-size: 1rem;
}

.folder-name {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.folder-actions {
  display: none;
  gap: 0.25rem;
}

.folder-item:hover .folder-actions {
  display: flex;
}

.btn-icon {
  background: none;
  border: none;
  font-size: 0.9rem;
  cursor: pointer;
  padding: 0.25rem;
  opacity: 0.7;
  transition: opacity 0.2s;
}

.btn-icon:hover {
  opacity: 1;
}

.folder-children {
  margin-left: 1rem;
  display: flex;
  flex-direction: column;
}
</style>
