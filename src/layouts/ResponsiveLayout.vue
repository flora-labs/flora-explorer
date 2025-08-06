<script lang="ts" setup>
import { Icon } from '@iconify/vue';
import { computed, ref, onMounted, onUnmounted } from 'vue';
import NavbarThemeSwitcher from '@/layouts/components/NavbarThemeSwitcher.vue';
import NavBarWallet from './components/NavBarWallet.vue';
import NavBarI18n from './components/NavBarI18n.vue';
import NavbarSearch from './components/NavbarSearch.vue';
import ChainProfile from './components/ChainProfile.vue';
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
const sidebarCollapsed = ref(false);

// Check if desktop
const isDesktop = ref(window.innerWidth >= 1280);
const handleResize = () => {
  isDesktop.value = window.innerWidth >= 1280;
  if (isDesktop.value) {
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

// Get grouped menu items for desktop
const groupedMenuItems = computed(() => {
  return blockchain.computedChainMenu || [];
});
</script>

<template>
  <!-- RESPONSIVE LAYOUT: Desktop sidebar, Mobile burger -->
  <div class="bg-gray-100 dark:bg-gray-900">
    
    <!-- DESKTOP LAYOUT (xl:1280px and up) -->
    <div v-if="isDesktop" class="flex h-screen">
      <!-- Desktop Left Sidebar -->
      <aside 
        :class="[
          'bg-white dark:bg-gray-900',
          'border-r border-gray-200 dark:border-gray-800',
          'transition-all duration-200',
          'overflow-y-auto shadow-lg',
          sidebarCollapsed ? 'w-20' : 'w-72 xl:w-80'
        ]"
      >
        <!-- Sidebar Header -->
        <div class="sticky top-0 z-10 bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-800">
          <div class="flex items-center h-14 px-4">
            <RouterLink 
              :to="`/${blockchain.chainName || 'flora-devnet'}`" 
              class="flex items-center flex-1"
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
        <nav class="px-4 py-4">
          <div class="space-y-4">
            <template v-for="(group, index) in groupedMenuItems" :key="index">
              <!-- First group without header -->
              <template v-if="index === 0 && isNavGroup(group)">
                <ul class="space-y-1">
                  <li v-for="item in group.children" :key="item.to?.path">
                    <RouterLink
                      v-if="isNavLink(item)"
                      :to="item.to"
                      class="flex items-center px-3 py-2.5 rounded-lg transition-colors"
                      :class="[
                        selected($route, item) 
                          ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300' 
                          : 'hover:bg-white/8 dark:hover:bg-gray-900/8 text-gray-700 dark:text-gray-300',
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
                        selected($route, item) 
                          ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300' 
                          : 'hover:bg-white/8 dark:hover:bg-gray-900/8 text-gray-700 dark:text-gray-300',
                        sidebarCollapsed ? 'justify-center' : ''
                      ]"
                      :title="sidebarCollapsed ? (group.title === 'Favorite' ? item.title : $t(item.title)) : undefined"
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
        
        <!-- Sidebar Footer Links -->
        <div class="mt-auto px-4 pb-4 border-t border-gray-200 dark:border-gray-800 pt-4">
          <div v-if="!sidebarCollapsed" class="px-3 mb-2 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
            Links
          </div>
          <ul class="space-y-1">
            <li>
              <a 
                href="https://twitter.com/flora_network"
                target="_blank"
                class="flex items-center px-3 py-2.5 rounded-lg hover:bg-white/8 dark:hover:bg-gray-900/8"
                :class="{ 'justify-center': sidebarCollapsed }"
                :title="sidebarCollapsed ? 'X (Twitter)' : undefined"
              >
                <Icon icon="simple-icons:x" class="text-xl text-gray-700 dark:text-gray-300" />
                <span v-if="!sidebarCollapsed" class="ml-3 text-gray-700 dark:text-gray-300">X (Twitter)</span>
              </a>
            </li>
            <li>
              <a 
                href="https://flora.network"
                target="_blank"
                class="flex items-center px-3 py-2.5 rounded-lg hover:bg-white/8 dark:hover:bg-gray-900/8"
                :class="{ 'justify-center': sidebarCollapsed }"
                :title="sidebarCollapsed ? 'FAQ' : undefined"
              >
                <Icon icon="mdi:frequently-asked-questions" class="text-xl text-gray-700 dark:text-gray-300" />
                <span v-if="!sidebarCollapsed" class="ml-3 text-gray-700 dark:text-gray-300">FAQ</span>
              </a>
            </li>
          </ul>
        </div>
      </aside>
      
      <!-- Desktop Main Content -->
      <div class="flex-1 flex flex-col overflow-hidden">
        <!-- Desktop Header -->
        <header class="bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-800 shadow-sm">
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
              
              <!-- Network Status Indicator -->
              <div class="ml-6 flex items-center gap-2 px-3 py-1.5 rounded-full bg-green-100 dark:bg-green-900/30">
                <div class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
                <span class="text-xs font-medium text-green-700 dark:text-green-300">Connected</span>
              </div>
            </div>
            
            <div class="flex items-center space-x-2">
              <NavbarSearch />
              <NavBarI18n />
              <NavbarThemeSwitcher />
              <NavBarWallet />
            </div>
          </div>
        </header>
        
        <!-- Desktop Content -->
        <main class="flex-1 overflow-auto bg-gray-50 dark:bg-gray-900/50">
          <div class="p-6 lg:p-8 xl:p-10 2xl:p-12">
            <div class="max-w-[1920px] mx-auto">
              <RouterView />
            </div>
          </div>
        </main>
      </div>
    </div>
    
    <!-- MOBILE LAYOUT (below 1280px) -->
    <div v-else>
      <!-- Mobile Sticky Header -->
      <header class="sticky top-0 z-50 bg-white/95 dark:bg-gray-900/95 backdrop-blur-md border-b border-gray-200 dark:border-gray-700">
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
            <button
              @click="mobileMenuOpen = !mobileMenuOpen"
              class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800"
            >
              <Icon icon="mdi:menu" class="text-xl text-gray-600 dark:text-gray-400" />
            </button>
          </div>
        </div>
      </header>
      
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
          <div class="mt-8 px-4">
            <NavBarWallet class="w-full" />
          </div>
        </nav>
      </div>
      
      <!-- Mobile Main Content -->
      <main class="min-h-screen">
        <div class="p-4">
          <RouterView />
        </div>
      </main>
    </div>
  </div>
</template>