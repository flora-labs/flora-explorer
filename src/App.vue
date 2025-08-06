<script setup lang="ts">
import { themeChange } from 'theme-change';
import { onMounted } from 'vue';
import TxDialog from './components/TxDialog.vue';

onMounted(() => {
  // Set dark mode as default if no theme is saved
  if (!window.localStorage.getItem('theme')) {
    window.localStorage.setItem('theme', 'dark');
    document.documentElement.setAttribute('data-theme', 'dark');
  }
  themeChange(false);
});
</script>

<template>
  <div>
    <RouterView />
    <TxDialog />
  </div>
</template>
