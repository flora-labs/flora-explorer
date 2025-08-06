<script lang="ts" setup>
import { Icon } from '@iconify/vue';
import { computed, ref, onMounted, onUnmounted, watch } from 'vue';

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

// Mobile-first state management
const sidebarOpen = ref(false);
const sidebarCollapsed = ref(false);
const mobileMenuOpen = ref(false);

// Responsive breakpoint handling
const DESKTOP_BREAKPOINT = 1280;
const isDesktop = ref(window.innerWidth >= DESKTOP_BREAKPOINT);

const handleResize = () => {
  const wasDesktop = isDesktop.value;
  isDesktop.value = window.innerWidth >= DESKTOP_BREAKPOINT;
  
  // Reset states when crossing breakpoints
  if (isDesktop.value && !wasDesktop) {
    sidebarOpen.value = false; // Close mobile sidebar when switching to desktop
    mobileMenuOpen.value = false; // Close mobile menu
  }
};

onMounted(() => {
  window.addEventListener('resize', handleResize);
  handleResize(); // Initial check
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
});

// Computed properties for clean class management
const overlayVisible = computed(() => !isDesktop.value && (sidebarOpen.value || mobileMenuOpen.value));

const sidebarClasses = computed(() => {
  const baseClasses = [
    'fixed', 'xl:relative',
    'top-0', 'left-0', 'h-full', 'xl:h-auto',
    'z-50',
    'w-64',
    'bg-white/10', 'dark:bg-gray-900/8',
    'backdrop-blur-md', 'backdrop-saturate-150',
    'border-r', 'border-white/10', 'dark:border-white/6',
    'transition-transform', 'duration-200', 'ease-out',
    'overflow-y-auto',
    'transform'
  ];
  
  // Mobile: slide in/out
  if (!isDesktop.value) {
    baseClasses.push(sidebarOpen.value ? 'translate-x-0' : '-translate-x-full');
  } else {
    baseClasses.push('xl:translate-x-0');
    // Desktop: collapsed width
    if (sidebarCollapsed.value) {
      baseClasses.push('xl:w-20');
    } else {
      baseClasses.push('xl:w-64');
    }
  }
  
  return baseClasses;
});

// Methods
const toggleSidebar = () => sidebarOpen.value = !sidebarOpen.value;
const closeSidebar = () => sidebarOpen.value = false;
const toggleCollapsed = () => sidebarCollapsed.value = !sidebarCollapsed.value;
const toggleMobileMenu = () => mobileMenuOpen.value = !mobileMenuOpen.value;
const closeMobileMenu = () => mobileMenuOpen.value = false;

// Helper functions for navigation
function isNavGroup(nav: VerticalNavItems | any): nav is NavGroup {
  return (<NavGroup>nav).children !== undefined;
}

function isNavLink(nav: VerticalNavItems | any): nav is NavLink {
  return (<NavLink>nav).to !== undefined;
}

function isNavTitle(nav: VerticalNavItems | any): nav is NavSectionTitle {
  return (<NavSectionTitle>nav).heading !== undefined;
}

function selected(route: any, nav: NavLink) {
  const b = route.path === nav.to?.path || 
    (route.path.startsWith(nav.to?.path) && nav.title.indexOf('dashboard') === -1);
  return b;
}

// Color mapping for navigation groups
function getNavColorClasses(groupTitle: string | undefined, isActive: boolean) {
  // Normalize group title
  const normalizedTitle = groupTitle?.toLowerCase() || '';
  
  // First group (index 0) is dashboard items
  if (!groupTitle || normalizedTitle === 'dashboard' || normalizedTitle === '') {
    return {
      iconClass: isActive 
        ? 'text-purple-700 dark:text-purple-300' 
        : 'text-purple-600 dark:text-purple-400',
      textClass: isActive 
        ? 'text-purple-700 dark:text-purple-300 font-medium' 
        : 'text-purple-600 dark:text-purple-400',
      bgClass: isActive
        ? 'bg-purple-100 dark:bg-purple-900/30'
        : 'hover:bg-purple-100 dark:hover:bg-purple-900/30'
    };
  }
  
  // Map each group to its semantic color
  switch (normalizedTitle) {
    case 'blockchain':
      return {
        iconClass: isActive 
          ? 'text-blue-700 dark:text-blue-300' 
          : 'text-blue-600 dark:text-blue-400',
        textClass: isActive 
          ? 'text-blue-700 dark:text-blue-300 font-medium' 
          : 'text-blue-600 dark:text-blue-400',
        bgClass: isActive
          ? 'bg-blue-100 dark:bg-blue-900/30'
          : 'hover:bg-blue-100 dark:hover:bg-blue-900/30'
      };
      
    case 'staking':
      return {
        iconClass: isActive 
          ? 'text-cyan-700 dark:text-cyan-300' 
          : 'text-cyan-600 dark:text-cyan-400',
        textClass: isActive 
          ? 'text-cyan-700 dark:text-cyan-300 font-medium' 
          : 'text-cyan-600 dark:text-cyan-400',
        bgClass: isActive
          ? 'bg-cyan-100 dark:bg-cyan-900/30'
          : 'hover:bg-cyan-100 dark:hover:bg-cyan-900/30'
      };
      
    case 'governance':
      return {
        iconClass: isActive 
          ? 'text-amber-700 dark:text-amber-300' 
          : 'text-amber-600 dark:text-amber-400',
        textClass: isActive 
          ? 'text-amber-700 dark:text-amber-300 font-medium' 
          : 'text-amber-600 dark:text-amber-400',
        bgClass: isActive
          ? 'bg-amber-100 dark:bg-amber-900/30'
          : 'hover:bg-amber-100 dark:hover:bg-amber-900/30'
      };
      
    case 'assets':
      return {
        iconClass: isActive 
          ? 'text-green-700 dark:text-green-300' 
          : 'text-green-600 dark:text-green-400',
        textClass: isActive 
          ? 'text-green-700 dark:text-green-300 font-medium' 
          : 'text-green-600 dark:text-green-400',
        bgClass: isActive
          ? 'bg-green-100 dark:bg-green-900/30'
          : 'hover:bg-green-100 dark:hover:bg-green-900/30'
      };
      
    case 'tools':
    case 'more':
      return {
        iconClass: isActive 
          ? 'text-indigo-700 dark:text-indigo-300' 
          : 'text-indigo-600 dark:text-indigo-400',
        textClass: isActive 
          ? 'text-indigo-700 dark:text-indigo-300 font-medium' 
          : 'text-indigo-600 dark:text-indigo-400',
        bgClass: isActive
          ? 'bg-indigo-100 dark:bg-indigo-900/30'
          : 'hover:bg-indigo-100 dark:hover:bg-indigo-900/30'
      };
      
    case 'favorite':
      return {
        iconClass: isActive 
          ? 'text-pink-700 dark:text-pink-300' 
          : 'text-pink-600 dark:text-pink-400',
        textClass: isActive 
          ? 'text-pink-700 dark:text-pink-300 font-medium' 
          : 'text-pink-600 dark:text-pink-400',
        bgClass: isActive
          ? 'bg-pink-100 dark:bg-pink-900/30'
          : 'hover:bg-pink-100 dark:hover:bg-pink-900/30'
      };
      
    default:
      return {
        iconClass: isActive 
          ? 'text-gray-700 dark:text-gray-300' 
          : 'text-gray-600 dark:text-gray-400',
        textClass: isActive 
          ? 'text-gray-700 dark:text-gray-300 font-medium' 
          : 'text-gray-600 dark:text-gray-400',
        bgClass: isActive
          ? 'bg-gray-100 dark:bg-gray-900/30'
          : 'hover:bg-gray-100 dark:hover:bg-gray-900/30'
      };
  }
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

const showDiscord = window.location.host.search('ping.pub') > -1;
const show_ad = computed(() => {
  return location.hostname.indexOf('ping.pub') > -1;
});
</script>

<template>
  <!-- Root container - NO HEIGHT CONSTRAINTS ON MOBILE -->
  <div class="bg-gray-100 dark:bg-gray-900 xl:flex xl:min-h-screen overflow-x-hidden">
    
    <!-- Mobile Overlay -->
    <Transition name="fade">
      <div 
        v-if="overlayVisible"
        class="fixed inset-0 bg-black/20 backdrop-blur-sm z-40 xl:hidden transition-opacity duration-300 ease-out"
        @click="() => { closeSidebar(); closeMobileMenu(); }"
      />
    </Transition>
    
    <!-- Sidebar -->
    <aside :class="sidebarClasses">
      <!-- Sidebar Header -->
      <div class="sticky top-0 z-10 bg-white/10 dark:bg-gray-900/8 backdrop-blur-md border-b border-white/10 dark:border-white/6">
        <div class="flex items-center h-14 px-4">
          <RouterLink 
            :to="`/${blockchain.chainName || 'flora-devnet'}`" 
            class="flex items-center flex-1 overflow-hidden"
            @click="closeSidebar"
          >
            <img class="w-8 h-8 flex-shrink-0" src="../../assets/logo.svg" alt="Logo" />
            <span 
              v-if="!isDesktop || !sidebarCollapsed"
              class="ml-3 text-lg font-semibold truncate bg-gradient-to-r from-emerald-400 via-teal-400 to-cyan-400 dark:from-emerald-300 dark:via-teal-300 dark:to-cyan-300 bg-clip-text text-transparent"
            >
              {{ blockchain.current?.prettyName || 'Flora Devnet' }}
            </span>
          </RouterLink>
          
          <!-- Mobile close button -->
          <button
            v-if="!isDesktop"
            @click="closeSidebar"
            class="p-2 rounded-full bg-white/8 dark:bg-gray-900/6 hover:bg-white/12 dark:hover:bg-gray-900/10 transition-all duration-200 ease-out xl:hidden"
            aria-label="Close sidebar"
          >
            <Icon icon="mdi:close" class="text-xl text-gray-600 dark:text-gray-400" />
          </button>
        </div>
      </div>
      
      <!-- Navigation -->
      <nav class="px-2 py-4">
        <!-- Mobile: Flat list -->
        <ul v-if="!isDesktop" class="space-y-1">
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
        
        <!-- Desktop: Grouped with collapse support -->
        <div v-else class="space-y-4">
          <template v-for="(group, index) in blockchain.computedChainMenu" :key="index">
            <!-- First group without wrapper -->
            <template v-if="index === 0 && isNavGroup(group)">
              <ul class="space-y-1">
                <li v-for="item in group.children" :key="item.to?.path">
                  <RouterLink
                    v-if="isNavLink(item)"
                    :to="item.to"
                    class="flex items-center px-3 py-2.5 rounded-lg transition-all duration-200 ease-out"
                    :class="[
                      selected($route, item) ? 'bg-white/10 dark:bg-gray-900/10 shadow-sm' : 'hover:bg-white/8 dark:hover:bg-gray-900/8',
                      sidebarCollapsed ? 'justify-center' : ''
                    ]"
                    :title="sidebarCollapsed ? $t(item.title) : undefined"
                  >
                    <Icon 
                      v-if="item.icon?.icon"
                      :icon="item.icon.icon" 
                      class="text-xl flex-shrink-0 text-current transition-colors duration-200"
                      :class="selected($route, item) ? 'text-emerald-500 dark:text-emerald-400' : 'text-gray-700 dark:text-gray-300'"
                    />
                    <span v-if="!sidebarCollapsed" class="ml-3 text-base font-medium" :class="selected($route, item) ? 'text-emerald-500 dark:text-emerald-400' : 'text-gray-700 dark:text-gray-300'">{{ $t(item.title) }}</span>
                  </RouterLink>
                </li>
              </ul>
            </template>
            
            <!-- Other groups with headers -->
            <div v-else-if="isNavGroup(group) && index > 0">
              <h3 
                v-if="!sidebarCollapsed"
                class="px-3 mb-2 text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 opacity-70"
              >
                {{ group.title }}
              </h3>
              <ul class="space-y-1">
                <li v-for="item in group.children" :key="item.to?.path">
                  <RouterLink
                    v-if="isNavLink(item)"
                    :to="item.to"
                    class="flex items-center px-3 py-2.5 rounded-lg transition-all duration-200 ease-out"
                    :class="[
                      selected($route, item) ? 'bg-white/10 dark:bg-gray-900/10 shadow-sm' : 'hover:bg-white/8 dark:hover:bg-gray-900/8',
                      sidebarCollapsed ? 'justify-center' : ''
                    ]"
                    :title="sidebarCollapsed ? (group.title === 'Favorite' ? item.title : $t(item.title)) : undefined"
                  >
                    <Icon 
                      v-if="item.icon?.icon"
                      :icon="item.icon.icon" 
                      class="text-xl flex-shrink-0 text-current transition-colors duration-200"
                      :class="selected($route, item) ? 'text-emerald-500 dark:text-emerald-400' : 'text-gray-700 dark:text-gray-300'"
                    />
                    <span v-if="!sidebarCollapsed" class="ml-3 text-base font-medium" :class="selected($route, item) ? 'text-emerald-500 dark:text-emerald-400' : 'text-gray-700 dark:text-gray-300'">
                      {{ group.title === 'Favorite' ? item.title : $t(item.title) }}
                    </span>
                  </RouterLink>
                </li>
              </ul>
            </div>
            
            <!-- Single nav links -->
            <RouterLink
              v-else-if="isNavLink(group)"
              :to="group.to"
              class="flex items-center px-3 py-2.5 rounded-lg transition-all duration-200 ease-out hover:bg-white/8 dark:hover:bg-gray-900/8"
              :class="{
                'justify-center': sidebarCollapsed
              }"
              :title="sidebarCollapsed ? group.title : undefined"
            >
              <Icon 
                v-if="group.icon?.icon"
                :icon="group.icon.icon" 
                class="text-xl flex-shrink-0 text-current text-gray-700 dark:text-gray-300 transition-colors duration-200"
              />
              <span v-if="!sidebarCollapsed" class="ml-3 text-base font-medium text-gray-700 dark:text-gray-300">{{ group.title }}</span>
            </RouterLink>
            
            <!-- Section titles -->
            <h3 
              v-else-if="isNavTitle(group) && !sidebarCollapsed"
              class="px-3 mb-2 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider"
            >
              {{ group.heading }}
            </h3>
          </template>
        </div>
      </nav>
      
      <!-- Sidebar Footer Links -->
      <div class="px-2 pb-4 mt-auto border-t border-white/10 dark:border-white/6 pt-4">
        <div v-if="!sidebarCollapsed" class="px-3 mb-2 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider opacity-70">
          Links
        </div>
        <ul class="space-y-1">
          <li>
            <a 
              href="https://twitter.com/flora_network"
              target="_blank"
              class="flex items-center px-3 py-2.5 rounded-lg transition-all duration-200 ease-out hover:bg-white/8 dark:hover:bg-gray-900/8"
              :class="{ 'justify-center': sidebarCollapsed }"
              :title="sidebarCollapsed ? 'X (Twitter)' : undefined"
            >
              <Icon icon="simple-icons:x" class="text-xl flex-shrink-0 text-current text-gray-700 dark:text-gray-300" />
              <span v-if="!sidebarCollapsed" class="ml-3 text-base font-medium text-gray-700 dark:text-gray-300">X (Twitter)</span>
            </a>
          </li>
          <li>
            <a 
              href="https://flora.network"
              target="_blank"
              class="flex items-center px-3 py-2.5 rounded-lg transition-all duration-200 ease-out hover:bg-white/8 dark:hover:bg-gray-900/8"
              :class="{ 'justify-center': sidebarCollapsed }"
              :title="sidebarCollapsed ? 'FAQ' : undefined"
            >
              <Icon icon="mdi:frequently-asked-questions" class="text-xl flex-shrink-0 text-current text-gray-700 dark:text-gray-300" />
              <span v-if="!sidebarCollapsed" class="ml-3 text-base font-medium text-gray-700 dark:text-gray-300">FAQ</span>
            </a>
          </li>
        </ul>
      </div>
    </aside>
    
    <!-- Main Content Area -->
    <div class="w-full xl:flex-1 xl:flex xl:flex-col">
      <!-- Header -->
      <header class="sticky top-0 z-30 bg-white/10 dark:bg-gray-900/8 backdrop-blur-md border-b border-white/10 dark:border-white/6">
        <div class="h-14 px-4 flex items-center justify-between xl:px-6">
          <!-- Left: Mobile menu / Desktop collapse -->
          <div class="flex items-center">
            <button
              v-if="!isDesktop"
              @click="toggleSidebar"
              class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800"
              aria-label="Open navigation"
            >
              <Icon icon="mdi:menu" class="text-xl text-gray-600 dark:text-gray-400" />
            </button>
            
            <button
              v-else
              @click="toggleCollapsed"
              class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800"
              :aria-expanded="!sidebarCollapsed"
              aria-label="Toggle sidebar"
            >
              <Icon 
                :icon="sidebarCollapsed ? 'mdi:chevron-right' : 'mdi:chevron-left'"
                class="text-xl text-gray-600 dark:text-gray-400"
              />
            </button>
            
            <!-- Chain Profile (Desktop) -->
            <ChainProfile v-if="isDesktop" class="ml-4" />
          </div>
          
          <!-- Center: Logo (Mobile) -->
          <div v-if="!isDesktop" class="flex items-center">
            <img class="w-8 h-8" src="../../assets/logo.svg" alt="Logo" />
            <span class="ml-2 text-lg font-semibold text-gray-900 dark:text-white">
              Flora
            </span>
          </div>
          
          <!-- Right: Actions -->
          <div class="flex items-center space-x-2">
            <!-- Desktop controls -->
            <template v-if="isDesktop">
              <NavbarSearch />
              <NavBarI18n />
              <NavbarThemeSwitcher />
              <NavBarWallet />
            </template>
            
            <!-- Mobile menu button -->
            <button
              v-else
              @click="toggleMobileMenu"
              class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800"
              aria-label="Open menu"
            >
              <Icon icon="mdi:dots-vertical" class="text-xl text-gray-600 dark:text-gray-400" />
            </button>
          </div>
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
      
      <!-- Page Content -->
      <main class="w-full xl:flex-1 xl:overflow-auto">
        <div class="p-4 xl:p-6">
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

/* Ensure smooth transitions */
.transition-transform {
  transition-property: transform;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
}

.transition-colors {
  transition-property: background-color, border-color, color, fill, stroke;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 150ms;
}
</style>