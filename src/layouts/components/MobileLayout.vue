<script lang="ts" setup>
import { Icon } from '@iconify/vue';
import { computed, ref, onMounted, onUnmounted } from 'vue';

// Components
import newFooter from '@/layouts/components/NavFooter.vue';
import NavbarThemeSwitcher from '@/layouts/components/NavbarThemeSwitcher.vue';
import NavbarSearch from '@/layouts/components/NavbarSearch.vue';
import ChainProfile from '@/layouts/components/ChainProfile.vue';
import NavBarI18n from './NavBarI18n.vue';
import NavBarWallet from './NavBarWallet.vue';

import { useDashboard } from '@/stores/useDashboard';
import { NetworkType } from '@/types/chaindata';
import { useBaseStore, useBlockchain } from '@/stores';
import type { NavGroup, NavLink, NavSectionTitle, VerticalNavItems } from '../types';
import dayjs from 'dayjs';

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

// Mobile state management
const sidebarOpen = ref(false);
const mobileMenuOpen = ref(false);

// Methods
const toggleSidebar = () => sidebarOpen.value = !sidebarOpen.value;
const closeSidebar = () => sidebarOpen.value = false;
const toggleMobileMenu = () => mobileMenuOpen.value = !mobileMenuOpen.value;
const closeMobileMenu = () => mobileMenuOpen.value = false;

// Helper functions for navigation
function isNavGroup(nav: VerticalNavItems | any): nav is NavGroup {
  return (<NavGroup>nav).children !== undefined;
}

function isNavLink(nav: VerticalNavItems | any): nav is NavLink {
  return (<NavLink>nav).to !== undefined;
}

function selected(route: any, nav: NavLink) {
  const b = route.path === nav.to?.path || 
    (route.path.startsWith(nav.to?.path) && nav.title.indexOf('dashboard') === -1);
  return b;
}

// Flatten menu items for mobile
const flatMenuItems = computed(() => {
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

// Time tracking
const blocktime = computed(() => {
  return dayjs(baseStore.latest?.block?.header?.time);
});

const behind = computed(() => {
  const current = dayjs().subtract(10, 'minute');
  return blocktime.value.isBefore(current);
});
</script>

<template>
  <!-- Mobile-optimized root container - NO min-height constraints -->
  <div class="relative w-full bg-gray-100 dark:bg-gray-900">
    
    <!-- Mobile Overlay -->
    <Transition name="fade">
      <div 
        v-if="sidebarOpen || mobileMenuOpen"
        class="fixed inset-0 bg-black/20 backdrop-blur-sm z-40 transition-opacity duration-300 ease-out"
        @click="() => { closeSidebar(); closeMobileMenu(); }"
      />
    </Transition>
    
    <!-- Sidebar (Mobile only) -->
    <aside 
      :class="[
        'fixed top-0 left-0 w-64 h-full z-50',
        'bg-white/10 dark:bg-gray-900/8',
        'backdrop-blur-md backdrop-saturate-150',
        'border-r border-white/10 dark:border-white/6',
        'transition-transform duration-200 ease-out',
        'overflow-y-auto transform',
        sidebarOpen ? 'translate-x-0' : '-translate-x-full'
      ]"
    >
      <!-- Sidebar Header -->
      <div class="sticky top-0 z-10 bg-white/10 dark:bg-gray-900/8 backdrop-blur-md border-b border-white/10 dark:border-white/6">
        <div class="flex items-center h-14 px-4">
          <RouterLink 
            :to="`/${blockchain.chainName || 'flora-devnet'}`" 
            class="flex items-center flex-1 overflow-hidden"
            @click="closeSidebar"
          >
            <img class="w-8 h-8 flex-shrink-0" src="../../assets/logo.svg" alt="Logo" />
            <span class="ml-3 text-lg font-semibold truncate bg-gradient-to-r from-emerald-400 via-teal-400 to-cyan-400 dark:from-emerald-300 dark:via-teal-300 dark:to-cyan-300 bg-clip-text text-transparent">
              {{ blockchain.current?.prettyName || 'Flora Devnet' }}
            </span>
          </RouterLink>
          
          <!-- Mobile close button -->
          <button
            @click="closeSidebar"
            class="p-2 rounded-full bg-white/8 dark:bg-gray-900/6 hover:bg-white/12 dark:hover:bg-gray-900/10 transition-all duration-200 ease-out"
            aria-label="Close sidebar"
          >
            <Icon icon="mdi:close" class="text-xl text-gray-600 dark:text-gray-400" />
          </button>
        </div>
      </div>
      
      <!-- Navigation -->
      <nav class="px-2 py-4">
        <ul class="space-y-1">
          <li v-for="item in flatMenuItems" :key="item.to?.path">
            <RouterLink
              :to="item.to"
              @click="closeSidebar"
              class="flex items-center px-3 py-2.5 rounded-lg transition-all duration-200 ease-out"
              :class="selected($route, item) ? 'bg-white/10 dark:bg-gray-900/10 shadow-sm' : 'hover:bg-white/8 dark:hover:bg-gray-900/8'"
            >
              <Icon 
                v-if="item.icon?.icon"
                :icon="item.icon.icon" 
                class="text-xl flex-shrink-0 text-current transition-colors duration-200"
                :class="selected($route, item) ? 'text-emerald-500 dark:text-emerald-400' : 'text-gray-700 dark:text-gray-300'"
              />
              <span class="ml-3 text-base font-medium" :class="selected($route, item) ? 'text-emerald-500 dark:text-emerald-400' : 'text-gray-700 dark:text-gray-300'">{{ $t(item.title) }}</span>
            </RouterLink>
          </li>
        </ul>
      </nav>
      
      <!-- Sidebar Footer Links -->
      <div class="px-2 pb-4 mt-auto border-t border-white/10 dark:border-white/6 pt-4">
        <div class="px-3 mb-2 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider opacity-70">
          Links
        </div>
        <ul class="space-y-1">
          <li>
            <a 
              href="https://twitter.com/flora_network"
              target="_blank"
              class="flex items-center px-3 py-2.5 rounded-lg transition-all duration-200 ease-out hover:bg-white/8 dark:hover:bg-gray-900/8"
            >
              <Icon icon="simple-icons:x" class="text-xl flex-shrink-0 text-current text-gray-700 dark:text-gray-300" />
              <span class="ml-3 text-base font-medium text-gray-700 dark:text-gray-300">X (Twitter)</span>
            </a>
          </li>
          <li>
            <a 
              href="https://flora.network"
              target="_blank"
              class="flex items-center px-3 py-2.5 rounded-lg transition-all duration-200 ease-out hover:bg-white/8 dark:hover:bg-gray-900/8"
            >
              <Icon icon="mdi:frequently-asked-questions" class="text-xl flex-shrink-0 text-current text-gray-700 dark:text-gray-300" />
              <span class="ml-3 text-base font-medium text-gray-700 dark:text-gray-300">FAQ</span>
            </a>
          </li>
        </ul>
      </div>
    </aside>
    
    <!-- Main Content Container - NO flex, just normal flow -->
    <div class="w-full">
      <!-- Header -->
      <header class="sticky top-0 z-30 bg-white/10 dark:bg-gray-900/8 backdrop-blur-md border-b border-white/10 dark:border-white/6">
        <div class="h-14 px-4 flex items-center justify-between">
          <!-- Left: Mobile menu -->
          <button
            @click="toggleSidebar"
            class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800"
            aria-label="Open navigation"
          >
            <Icon icon="mdi:menu" class="text-xl text-gray-600 dark:text-gray-400" />
          </button>
          
          <!-- Center: Logo -->
          <div class="flex items-center">
            <img class="w-8 h-8" src="../../assets/logo.svg" alt="Logo" />
            <span class="ml-2 text-lg font-semibold text-gray-900 dark:text-white">
              Flora
            </span>
          </div>
          
          <!-- Right: Actions -->
          <button
            @click="toggleMobileMenu"
            class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800"
            aria-label="Open menu"
          >
            <Icon icon="mdi:dots-vertical" class="text-xl text-gray-600 dark:text-gray-400" />
          </button>
        </div>
      </header>
      
      <!-- Alert Banner -->
      <div v-if="behind" class="bg-red-50 dark:bg-red-900/20 border-b border-red-200 dark:border-red-800">
        <div class="px-4 py-3 flex items-center">
          <Icon icon="mdi:alert-circle" class="text-red-500 mr-2" />
          <span class="text-sm text-red-700 dark:text-red-400">
            {{ $t('pages.out_of_sync') }} {{ blocktime.format() }} ({{ blocktime.fromNow() }})
          </span>
        </div>
      </div>
      
      <!-- Page Content - normal document flow, no height constraints -->
      <main class="w-full">
        <div class="p-4">
          <RouterView v-slot="{ Component }">
            <Transition mode="out-in">
              <Component :is="Component" />
            </Transition>
          </RouterView>
        </div>
      </main>
      
      <!-- Footer -->
      <newFooter />
    </div>
    
    <!-- Mobile Menu Sheet -->
    <Transition name="slide-up">
      <div
        v-if="mobileMenuOpen"
        class="fixed inset-x-0 bottom-0 z-50 bg-white dark:bg-gray-900 rounded-t-2xl shadow-2xl max-h-[70vh] overflow-auto"
      >
        <div class="sticky top-0 bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700">
          <div class="flex items-center justify-between h-14 px-4">
            <h2 class="text-lg font-semibold text-gray-900 dark:text-white">Menu</h2>
            <button
              @click="closeMobileMenu"
              class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800"
              aria-label="Close menu"
            >
              <Icon icon="mdi:close" class="text-xl text-gray-600 dark:text-gray-400" />
            </button>
          </div>
        </div>
        
        <div class="p-4 space-y-4">
          <ChainProfile class="w-full" />
          <NavbarSearch class="w-full" />
          <div class="flex items-center justify-between">
            <span class="text-sm text-gray-600 dark:text-gray-400">Theme</span>
            <NavbarThemeSwitcher />
          </div>
          <div class="flex items-center justify-between">
            <span class="text-sm text-gray-600 dark:text-gray-400">Language</span>
            <NavBarI18n />
          </div>
          <NavBarWallet class="w-full" />
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
/* Transition animations */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.slide-up-enter-active,
.slide-up-leave-active {
  transition: transform 0.3s ease;
}

.slide-up-enter-from,
.slide-up-leave-to {
  transform: translateY(100%);
}
</style>