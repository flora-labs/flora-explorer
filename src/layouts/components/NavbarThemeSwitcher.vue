<script setup lang="ts">
import { Icon } from '@iconify/vue';
import { onMounted, computed } from 'vue';
import { useBaseStore } from '@/stores';

const themeMap: Record<string, string> = {
  system: 'mdi-laptop',
  light: 'mdi-weather-sunny',
  dark: 'mdi-weather-night',
  glassmorphic: 'mdi-snowflake',
};
const baseStore = useBaseStore();
const theme = computed(() => {
  return baseStore.theme;
});

const changeMode = (val?: 'dark' | 'light' | 'glassmorphic') => {
  let value: 'dark' | 'light' | 'glassmorphic' = 'dark';
  const currentValue: 'dark' | 'light' | 'glassmorphic' = val || theme.value;
  
  // Cycle through themes: dark -> light -> glassmorphic -> dark
  if (currentValue === 'dark') {
    value = 'light';
  } else if (currentValue === 'light') {
    value = 'glassmorphic';
  } else {
    value = 'dark';
  }
  
  // Update classes based on theme
  document.documentElement.classList.remove('light', 'dark');
  if (value === 'light') {
    document.documentElement.classList.add('light');
  } else {
    document.documentElement.classList.add('dark');
  }
  
  document.documentElement.setAttribute('data-theme', value);
  window.localStorage.setItem('theme', value);
  baseStore.theme = value;
};

onMounted(() => {
  const savedTheme = window.localStorage.getItem('theme') as 'dark' | 'light' | 'glassmorphic' || 'dark';
  
  // Apply saved theme
  document.documentElement.classList.remove('light', 'dark');
  if (savedTheme === 'light') {
    document.documentElement.classList.add('light');
  } else {
    document.documentElement.classList.add('dark');
  }
  
  document.documentElement.setAttribute('data-theme', savedTheme);
  baseStore.theme = savedTheme;
});
</script>

<template>
  <div class="tooltip tooltip-bottom delay-1000">
    <button class="btn btn-ghost btn-circle btn-sm mx-1" @click="changeMode()">
      <Icon :icon="themeMap?.[theme]" class="text-2xl text-gray-500 dark:text-gray-400" />
    </button>
  </div>
</template>
