<script lang="ts" setup>
import { Icon } from '@iconify/vue';
import { computed, ref } from 'vue';
import NavbarThemeSwitcher from '@/layouts/components/NavbarThemeSwitcher.vue';
import NavBarWallet from './components/NavBarWallet.vue';
import { useDashboard } from '@/stores/useDashboard';
import { useBaseStore, useBlockchain } from '@/stores';
import type { NavGroup, NavLink } from './types';

// Initialize stores
const dashboard = useDashboard();
dashboard.initial();
const blockchain = useBlockchain();
blockchain.randomSetupEndpoint();
const baseStore = useBaseStore();

// Track current chain
const current = ref('');
const temp = ref('');
blockchain.$subscribe((m, s) => {
  if (current.value === s.chainName && temp.value != s.endpoint.address) {
    temp.value = s.endpoint.address;
    blockchain.initial();
  }
  if (current.value != s.chainName) {
    current.value = s.chainName;
    blockchain.randomSetupEndpoint();
  }
});

// Mobile menu state
const mobileMenuOpen = ref(false);

// Helper functions
function isNavGroup(nav: any): nav is NavGroup {
  return nav?.children !== undefined;
}

function isNavLink(nav: any): nav is NavLink {
  return nav?.to !== undefined;
}

function selected(route: any, nav: NavLink) {
  if (!nav?.to?.path) return false;
  return route.path === nav.to.path || 
    (route.path.startsWith(nav.to.path) && nav.title.indexOf('dashboard') === -1);
}

// Get all menu items flattened
const allMenuItems = computed(() => {
  const items: NavLink[] = [];
  blockchain.computedChainMenu?.forEach((item: any) => {
    if (isNavGroup(item)) {
      items.push(...item.children.filter(isNavLink));
    } else if (isNavLink(item)) {
      items.push(item);
    }
  });
  return items;
});
</script>

<template>
  <!-- WORKING MOBILE-FIRST LAYOUT -->
  <div class="bg-gray-100 dark:bg-gray-900">
    <!-- Fixed Header -->
    <header class="fixed top-0 left-0 right-0 z-50 bg-white/95 dark:bg-gray-900/95 backdrop-blur-md border-b border-gray-200 dark:border-gray-700">
      <div class="h-14 px-4 flex items-center justify-between">
        <!-- Logo -->
        <RouterLink :to="`/${blockchain.chainName || 'flora-devnet'}`" class="flex items-center">
          <img class="w-8 h-8" src="../assets/logo.svg" alt="Logo" />
          <span class="ml-2 text-lg font-semibold text-gray-900 dark:text-white">
            {{ blockchain.current?.prettyName || 'Flora' }}
          </span>
        </RouterLink>
        
        <!-- Right side controls -->
        <div class="flex items-center space-x-2">
          <NavbarThemeSwitcher />
          <NavBarWallet class="hidden sm:block" />
          <button
            @click="mobileMenuOpen = !mobileMenuOpen"
            class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800"
          >
            <Icon icon="mdi:menu" class="text-xl text-gray-600 dark:text-gray-400" />
          </button>
        </div>
      </div>
    </header>
    
    <!-- Spacer for fixed header -->
    <div class="h-14"></div>
    
    <!-- Mobile Menu Dropdown -->
    <div 
      v-if="mobileMenuOpen"
      class="fixed inset-0 top-14 z-40 bg-gray-100 dark:bg-gray-900 overflow-y-auto"
    >
      <nav class="p-4">
        <div class="space-y-1">
          <RouterLink
            v-for="item in allMenuItems"
            :key="item.to?.path"
            :to="item.to"
            @click="mobileMenuOpen = false"
            class="flex items-center px-4 py-3 rounded-lg transition-colors"
            :class="selected($route, item) 
              ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300' 
              : 'hover:bg-gray-200 dark:hover:bg-gray-800 text-gray-700 dark:text-gray-300'"
          >
            <Icon 
              v-if="item.icon?.icon"
              :icon="item.icon.icon" 
              class="text-xl mr-3"
            />
            <span>{{ $t(item.title) }}</span>
          </RouterLink>
        </div>
        
        <!-- Links section -->
        <div class="mt-8 pt-8 border-t border-gray-200 dark:border-gray-700">
          <h3 class="px-4 mb-4 text-sm font-semibold text-gray-500 dark:text-gray-400 uppercase">
            Links
          </h3>
          <div class="space-y-1">
            <a 
              href="https://twitter.com/flora_network"
              target="_blank"
              class="flex items-center px-4 py-3 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-800"
            >
              <Icon icon="simple-icons:x" class="text-xl mr-3 text-gray-700 dark:text-gray-300" />
              <span class="text-gray-700 dark:text-gray-300">X (Twitter)</span>
            </a>
            <a 
              href="https://flora.network"
              target="_blank"
              class="flex items-center px-4 py-3 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-800"
            >
              <Icon icon="mdi:frequently-asked-questions" class="text-xl mr-3 text-gray-700 dark:text-gray-300" />
              <span class="text-gray-700 dark:text-gray-300">FAQ</span>
            </a>
          </div>
        </div>
        
        <!-- Mobile Wallet button -->
        <div class="mt-8 px-4 sm:hidden">
          <NavBarWallet class="w-full" />
        </div>
      </nav>
    </div>
    
    <!-- Main Content -->
    <main class="min-h-screen">
      <div class="p-4 sm:p-6 lg:p-8">
        <RouterView />
      </div>
    </main>
    
    <!-- Footer -->
    <footer class="border-t border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900">
      <div class="px-4 py-6 text-center text-sm text-gray-600 dark:text-gray-400">
        © 2024 Flora Network Explorer
      </div>
    </footer>
  </div>
</template>