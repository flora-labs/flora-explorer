<script lang="ts" setup>
import { Icon } from '@iconify/vue';
import { computed, ref, onMounted, onUnmounted } from 'vue';

// Components
import newFooter from '@/layouts/components/NavFooter.vue';
import NavbarThemeSwitcher from '@/layouts/components/NavbarThemeSwitcher.vue';
import NavbarSearch from '@/layouts/components/NavbarSearch.vue';
import ChainProfile from '@/layouts/components/ChainProfile.vue';
import NavBarI18n from './components/NavBarI18n.vue';
import NavBarWallet from './components/NavBarWallet.vue';

import { useDashboard } from '@/stores/useDashboard';
import { useBaseStore, useBlockchain } from '@/stores';
import type { NavGroup, NavLink, NavSectionTitle, VerticalNavItems } from './types';
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

// Mobile state
const sidebarOpen = ref(false);
const sidebarCollapsed = ref(false);
const mobileMenuOpen = ref(false);

// Check if desktop
const isDesktop = ref(window.innerWidth >= 1280);
const handleResize = () => {
  isDesktop.value = window.innerWidth >= 1280;
  if (isDesktop.value) {
    sidebarOpen.value = false;
    mobileMenuOpen.value = false;
  }
};

onMounted(() => {
  window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
});

// Helper functions
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

// Flatten menu for mobile
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
  <!-- Mobile Layout -->
  <div v-if="!isDesktop" class="min-h-screen bg-gray-100 dark:bg-gray-900">
    <!-- Mobile Overlay -->
    <div 
      v-if="sidebarOpen || mobileMenuOpen"
      class="fixed inset-0 bg-black/20 backdrop-blur-sm z-40"
      @click="sidebarOpen = false; mobileMenuOpen = false"
    />
    
    <!-- Mobile Sidebar -->
    <aside 
      :class="[
        'fixed inset-y-0 left-0 z-50 w-64',
        'bg-white/10 dark:bg-gray-900/8',
        'backdrop-blur-md backdrop-saturate-150',
        'border-r border-white/10 dark:border-white/6',
        'transition-transform duration-200',
        'overflow-y-auto',
        sidebarOpen ? 'translate-x-0' : '-translate-x-full'
      ]"
    >
      <!-- Sidebar Header -->
      <div class="sticky top-0 z-10 bg-white/10 dark:bg-gray-900/8 backdrop-blur-md border-b border-white/10 dark:border-white/6">
        <div class="flex items-center h-14 px-4">
          <RouterLink 
            :to="`/${blockchain.chainName || 'flora-devnet'}`" 
            class="flex items-center flex-1"
            @click="sidebarOpen = false"
          >
            <img class="w-8 h-8" src="../assets/logo.svg" alt="Logo" />
            <span class="ml-3 text-lg font-semibold bg-gradient-to-r from-emerald-400 to-cyan-400 bg-clip-text text-transparent">
              {{ blockchain.current?.prettyName || 'Flora Devnet' }}
            </span>
          </RouterLink>
          <button
            @click="sidebarOpen = false"
            class="p-2 rounded-full hover:bg-white/10"
          >
            <Icon icon="mdi:close" class="text-xl text-gray-600 dark:text-gray-400" />
          </button>
        </div>
      </div>
      
      <!-- Mobile Navigation -->
      <nav class="px-2 py-4">
        <ul class="space-y-1">
          <li v-for="item in flatMenuItems" :key="item.to?.path">
            <RouterLink
              :to="item.to"
              @click="sidebarOpen = false"
              class="flex items-center px-3 py-2.5 rounded-lg transition-colors"
              :class="selected($route, item) ? 'bg-white/10 text-emerald-500' : 'hover:bg-white/8'"
            >
              <Icon 
                v-if="item.icon?.icon"
                :icon="item.icon.icon" 
                class="text-xl"
              />
              <span class="ml-3">{{ $t(item.title) }}</span>
            </RouterLink>
          </li>
        </ul>
      </nav>
    </aside>
    
    <!-- Mobile Header -->
    <header class="sticky top-0 z-30 bg-white/10 dark:bg-gray-900/8 backdrop-blur-md border-b border-white/10 dark:border-white/6">
      <div class="h-14 px-4 flex items-center justify-between">
        <button
          @click="sidebarOpen = true"
          class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800"
        >
          <Icon icon="mdi:menu" class="text-xl text-gray-600 dark:text-gray-400" />
        </button>
        
        <div class="flex items-center">
          <img class="w-8 h-8" src="../assets/logo.svg" alt="Logo" />
          <span class="ml-2 text-lg font-semibold">Flora</span>
        </div>
        
        <button
          @click="mobileMenuOpen = true"
          class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800"
        >
          <Icon icon="mdi:dots-vertical" class="text-xl text-gray-600 dark:text-gray-400" />
        </button>
      </div>
    </header>
    
    <!-- Mobile Alert -->
    <div v-if="behind" class="bg-red-50 dark:bg-red-900/20 border-b border-red-200 dark:border-red-800">
      <div class="px-4 py-2 text-sm">
        <Icon icon="mdi:alert-circle" class="text-red-500 mr-1" />
        Out of sync: {{ blocktime.fromNow() }}
      </div>
    </div>
    
    <!-- Mobile Content -->
    <main class="pb-16">
      <div class="p-4">
        <RouterView />
      </div>
    </main>
    
    <!-- Mobile Menu Sheet -->
    <div
      v-if="mobileMenuOpen"
      class="fixed inset-x-0 bottom-0 z-50 bg-white dark:bg-gray-900 rounded-t-2xl shadow-2xl"
    >
      <div class="h-14 px-4 flex items-center justify-between border-b">
        <h2 class="text-lg font-semibold">Menu</h2>
        <button @click="mobileMenuOpen = false">
          <Icon icon="mdi:close" class="text-xl" />
        </button>
      </div>
      <div class="p-4 space-y-4">
        <ChainProfile class="w-full" />
        <NavbarSearch class="w-full" />
        <NavbarThemeSwitcher />
        <NavBarWallet class="w-full" />
      </div>
    </div>
  </div>
  
  <!-- Desktop Layout -->
  <div v-else class="flex min-h-screen bg-gray-100 dark:bg-gray-900">
    <!-- Desktop Sidebar -->
    <aside 
      :class="[
        'relative bg-white/10 dark:bg-gray-900/8',
        'backdrop-blur-md backdrop-saturate-150',
        'border-r border-white/10 dark:border-white/6',
        'transition-all duration-200',
        'overflow-y-auto',
        sidebarCollapsed ? 'w-20' : 'w-64'
      ]"
    >
      <!-- Desktop Sidebar Header -->
      <div class="sticky top-0 z-10 bg-white/10 dark:bg-gray-900/8 backdrop-blur-md border-b border-white/10 dark:border-white/6">
        <div class="flex items-center h-14 px-4">
          <RouterLink 
            :to="`/${blockchain.chainName || 'flora-devnet'}`" 
            class="flex items-center"
          >
            <img class="w-8 h-8" src="../assets/logo.svg" alt="Logo" />
            <span 
              v-if="!sidebarCollapsed"
              class="ml-3 text-lg font-semibold bg-gradient-to-r from-emerald-400 to-cyan-400 bg-clip-text text-transparent"
            >
              {{ blockchain.current?.prettyName || 'Flora Devnet' }}
            </span>
          </RouterLink>
        </div>
      </div>
      
      <!-- Desktop Navigation -->
      <nav class="px-2 py-4">
        <div class="space-y-4">
          <template v-for="(group, index) in blockchain.computedChainMenu" :key="index">
            <!-- First group without header -->
            <template v-if="index === 0 && isNavGroup(group)">
              <ul class="space-y-1">
                <li v-for="item in group.children" :key="item.to?.path">
                  <RouterLink
                    v-if="isNavLink(item)"
                    :to="item.to"
                    class="flex items-center px-3 py-2.5 rounded-lg transition-colors"
                    :class="[
                      selected($route, item) ? 'bg-white/10 text-emerald-500' : 'hover:bg-white/8',
                      sidebarCollapsed ? 'justify-center' : ''
                    ]"
                    :title="sidebarCollapsed ? $t(item.title) : undefined"
                  >
                    <Icon 
                      v-if="item.icon?.icon"
                      :icon="item.icon.icon" 
                      class="text-xl"
                    />
                    <span v-if="!sidebarCollapsed" class="ml-3">{{ $t(item.title) }}</span>
                  </RouterLink>
                </li>
              </ul>
            </template>
            
            <!-- Other groups with headers -->
            <div v-else-if="isNavGroup(group) && index > 0">
              <h3 
                v-if="!sidebarCollapsed"
                class="px-3 mb-2 text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400"
              >
                {{ group.title }}
              </h3>
              <ul class="space-y-1">
                <li v-for="item in group.children" :key="item.to?.path">
                  <RouterLink
                    v-if="isNavLink(item)"
                    :to="item.to"
                    class="flex items-center px-3 py-2.5 rounded-lg transition-colors"
                    :class="[
                      selected($route, item) ? 'bg-white/10 text-emerald-500' : 'hover:bg-white/8',
                      sidebarCollapsed ? 'justify-center' : ''
                    ]"
                    :title="sidebarCollapsed ? $t(item.title) : undefined"
                  >
                    <Icon 
                      v-if="item.icon?.icon"
                      :icon="item.icon.icon" 
                      class="text-xl"
                    />
                    <span v-if="!sidebarCollapsed" class="ml-3">
                      {{ group.title === 'Favorite' ? item.title : $t(item.title) }}
                    </span>
                  </RouterLink>
                </li>
              </ul>
            </div>
          </template>
        </div>
      </nav>
    </aside>
    
    <!-- Desktop Main Content -->
    <div class="flex-1 flex flex-col">
      <!-- Desktop Header -->
      <header class="sticky top-0 z-30 bg-white/10 dark:bg-gray-900/8 backdrop-blur-md border-b border-white/10 dark:border-white/6">
        <div class="h-14 px-6 flex items-center justify-between">
          <div class="flex items-center">
            <button
              @click="sidebarCollapsed = !sidebarCollapsed"
              class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800"
            >
              <Icon 
                :icon="sidebarCollapsed ? 'mdi:chevron-right' : 'mdi:chevron-left'"
                class="text-xl text-gray-600 dark:text-gray-400"
              />
            </button>
            <ChainProfile class="ml-4" />
          </div>
          
          <div class="flex items-center space-x-2">
            <NavbarSearch />
            <NavBarI18n />
            <NavbarThemeSwitcher />
            <NavBarWallet />
          </div>
        </div>
      </header>
      
      <!-- Desktop Alert -->
      <div v-if="behind" class="bg-red-50 dark:bg-red-900/20 border-b border-red-200 dark:border-red-800">
        <div class="px-6 py-3 flex items-center">
          <Icon icon="mdi:alert-circle" class="text-red-500 mr-2" />
          <span class="text-sm text-red-700 dark:text-red-400">
            {{ $t('pages.out_of_sync') }} {{ blocktime.format() }} ({{ blocktime.fromNow() }})
          </span>
        </div>
      </div>
      
      <!-- Desktop Content -->
      <main class="flex-1 overflow-auto">
        <div class="p-6">
          <RouterView />
        </div>
      </main>
      
      <!-- Desktop Footer -->
      <newFooter />
    </div>
  </div>
</template>