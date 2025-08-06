<script lang="ts" setup>
import { Icon } from '@iconify/vue';
import NavbarThemeSwitcher from '@/layouts/components/NavbarThemeSwitcher.vue';
import NavBarWallet from './components/NavBarWallet.vue';
import { useBlockchain } from '@/stores';

const blockchain = useBlockchain();
</script>

<template>
  <!-- ULTRA SIMPLE LAYOUT - NO BULLSHIT -->
  <div class="bg-gray-100 dark:bg-gray-900">
    <!-- Simple Header -->
    <header class="bg-white/10 dark:bg-gray-900/8 backdrop-blur-md border-b border-white/10 dark:border-white/6">
      <div class="h-14 px-4 flex items-center justify-between">
        <RouterLink :to="`/${blockchain.chainName || 'flora-devnet'}`" class="flex items-center">
          <img class="w-8 h-8" src="../assets/logo.svg" alt="Logo" />
          <span class="ml-2 text-lg font-semibold text-gray-900 dark:text-white">Flora</span>
        </RouterLink>
        <div class="flex items-center space-x-2">
          <NavbarThemeSwitcher />
          <NavBarWallet />
        </div>
      </div>
    </header>
    
    <!-- Main Content - NO CONSTRAINTS -->
    <main>
      <RouterView />
    </main>
  </div>
</template>