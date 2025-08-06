<script lang="ts" setup>
import { Icon } from '@iconify/vue';
import { computed, ref, onMounted, nextTick } from 'vue';

// Components
import newFooter from '@/layouts/components/NavFooter.vue';
import NavbarThemeSwitcher from '@/layouts/components/NavbarThemeSwitcher.vue';
import NavbarSearch from '@/layouts/components/NavbarSearch.vue';
import ChainProfile from '@/layouts/components/ChainProfile.vue';
import Sponsors from '@/layouts/components/Sponsors.vue';

import { useDashboard } from '@/stores/useDashboard';
import { NetworkType } from '@/types/chaindata';
import { useBaseStore, useBlockchain } from '@/stores';

import NavBarI18n from './NavBarI18n.vue';
import NavBarWallet from './NavBarWallet.vue';
import type {
  NavGroup,
  NavLink,
  NavSectionTitle,
  VerticalNavItems,
} from '../types';
import dayjs from 'dayjs';
import AdBanner from '@/components/ad/AdBanner.vue';

const dashboard = useDashboard();
dashboard.initial();
const blockchain = useBlockchain();
blockchain.randomSetupEndpoint();
const baseStore = useBaseStore();

const current = ref(''); // the current chain
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

const sidebarShow = ref(false);
const sidebarOpen = ref(true);
const sidebarCollapsed = ref(false);

const changeOpen = (index: Number) => {
  if (index === 0) {
    sidebarOpen.value = !sidebarOpen.value;
  }
};

const toggleSidebar = () => {
  sidebarCollapsed.value = !sidebarCollapsed.value;
};
const showDiscord = window.location.host.search('ping.pub') > -1;

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
  const b =
    route.path === nav.to?.path || (route.path.startsWith(nav.to?.path) && nav.title.indexOf('dashboard') === -1);
  return b;
}
const blocktime = computed(() => {
  return dayjs(baseStore.latest?.block?.header?.time);
});

const behind = computed(() => {
  const current = dayjs().subtract(10, 'minute');
  return blocktime.value.isBefore(current);
});

dayjs();

const show_ad = computed(() => {
  return location.hostname.indexOf('ping.pub') > -1;
});

// Removed forced dark background to allow proper theme switching
</script>

<template>
  <div class="bg-gray-100 dark:bg-[#0f1218]">
    <!-- sidebar -->
    <div
      class="fixed z-50 left-0 top-0 bottom-0 overflow-y-auto overflow-x-visible transition-all duration-300 bg-gradient-to-b from-white/95 to-gray-50/95 dark:from-[#171d30] dark:to-[#0f1218] backdrop-blur-sm border-r border-gray-200/50 dark:border-gray-700/50"
      :class="[
        sidebarCollapsed ? 'w-20' : 'w-64',
        { block: sidebarShow, 'hidden xl:!block': !sidebarShow }
      ]"
    >
      <div class="nav-brand flex items-center relative overflow-visible px-4 py-3 border-b border-gray-200/50 dark:border-gray-700/50">
        <RouterLink :to="`/${blockchain.chainName || 'flora-devnet'}`" class="flex items-center flex-1 overflow-hidden hover:opacity-80 transition-opacity"
          :class="sidebarCollapsed ? 'justify-center' : ''"
        >
          <img class="w-10 h-10 nav-logo flex-shrink-0" src="../../assets/logo.svg" />
          <h1 
            class="ml-3 text-xl lg:text-2xl font-semibold text-gray-800 dark:text-gray-100 transition-all duration-300 truncate"
            :class="sidebarCollapsed ? 'opacity-0 w-0' : 'block'"
          >
            {{ blockchain.current?.prettyName || 'Flora Devnet' }}
          </h1>
        </RouterLink>
        
        <button
          class="ml-2 p-1.5 rounded-lg hover:bg-gray-200/50 dark:hover:bg-white/10 cursor-pointer xl:!hidden transition-all duration-200"
          @click="sidebarShow = false"
          aria-label="Close sidebar"
        >
          <Icon icon="mdi:close" class="text-xl text-gray-600 dark:text-gray-400" />
        </button>
      </div>
      <!-- Separator line in collapsed mode -->
      <div v-if="sidebarCollapsed" class="w-12 h-px bg-gray-300 dark:bg-gray-700 mx-auto mb-4"></div>
      <div v-for="(item, index) of blockchain.computedChainMenu" :key="index" class="px-2">
        <!-- For first group (index 0), render children directly without collapse wrapper -->
        <template v-if="index === 0 && isNavGroup(item)">
          <div v-if="!sidebarCollapsed">
            <div v-for="(el, key) of item?.children" :key="key" class="menu w-full !p-0">
              <RouterLink
                v-if="isNavLink(el)"
                @click="sidebarShow = false"
                class="cursor-pointer flex items-center group relative transition-all duration-200 hover:bg-gray-100/70 dark:hover:bg-white/10 rounded-lg px-2 py-2"
                :class="{
                  'bg-purple-500/15 dark:bg-purple-500/20 border-l-2 border-purple-500': selected($route, el),
                  'justify-center': sidebarCollapsed
                }"
                :to="el.to"
              >
                <div class="icon-wrapper transition-all duration-300"
                  :class="[
                    sidebarCollapsed ? 'mr-0 ml-0' : 'mr-3 ml-3',
                    selected($route, el) ? 'text-purple-500 dark:text-purple-400' : (el.iconColor || 'text-gray-600 dark:text-gray-400')
                  ]"
                >
                  <Icon
                    v-if="el?.icon?.icon"
                    :icon="el.icon.icon"
                    class="text-lg transition-all duration-300"
                  />
                  <img
                    v-else-if="el?.icon?.image"
                    :src="el.icon.image"
                    class="w-5 h-5 rounded-full"
                  />
                  <Icon
                    v-else
                    icon="mdi:circle-outline"
                    class="text-lg"
                  />
                </div>
                <div
                  v-if="!sidebarCollapsed"
                  class="text-sm capitalize text-gray-700 dark:text-gray-300 font-medium tracking-wide transition-all duration-300"
                  :class="{
                    '!text-purple-600 dark:!text-purple-300 font-semibold': selected($route, el),
                  }"
                >
                  {{ $t(el?.title) }}
                </div>
              </RouterLink>
            </div>
            <div
              v-if="dashboard.networkType === NetworkType.Testnet"
              class="menu w-full !p-0"
            >
              <RouterLink
                class="nav-item cursor-pointer flex items-center group relative hover:bg-gray-100/50 dark:hover:bg-white/10 rounded-lg px-2 py-2 transition-all duration-200"
                :class="{
                  'justify-center': sidebarCollapsed
                }"
                :to="`/${blockchain.chainName}/faucet`"
              >
                <div class="glass-icon-wrapper transition-all duration-300 text-blue-300"
                  :class="sidebarCollapsed ? 'mr-0 ml-0' : 'mr-3 ml-3'"
                >
                  <Icon icon="mdi:water" class="text-lg" />
                </div>
                <div v-if="!sidebarCollapsed" class="text-sm capitalize text-gray-400 font-medium tracking-wide">
                  Faucet
                </div>
                <div v-if="!sidebarCollapsed" class="badge badge-sm text-white glass-badge-pulse ml-auto">New</div>
              </RouterLink>
            </div>
          </div>
        </template>
        
        <!-- For other groups (index > 0), use collapse wrapper -->
        <div
          v-else-if="isNavGroup(item) && index > 0"
          :tabindex="index"
          class="collapse nav-group mb-2 transition-all duration-300"
          :class="{
            'collapse-arrow': item?.children?.length > 0,
          }"
        >
          <input type="checkbox" class="cursor-pointer !h-10 block" @click="changeOpen(index)" />
          <div
            class="collapse-title !py-3 px-4 flex items-center cursor-pointer hover:bg-gray-100/50 dark:hover:bg-white/10 transition-all duration-300"
            :class="sidebarCollapsed ? 'justify-center' : ''"
          >
            <div class="icon-wrapper" :class="sidebarCollapsed ? 'mr-0' : 'mr-2'">
              <Icon
                v-if="item?.icon?.icon"
                :icon="item?.icon?.icon"
                class="text-xl transition-all duration-300"
                :class="{
                  'text-yellow-500 dark:text-yellow-400': item?.title === 'Favorite',
                  'text-gray-600 dark:text-gray-400': item?.title !== 'Favorite',
                }"
              />
            </div>
            <div v-if="item?.icon?.image" class="icon-wrapper" :class="sidebarCollapsed ? 'mr-0' : 'mr-3'">
              <img :src="item?.icon?.image" class="w-6 h-6 rounded-full" />
            </div>
            <div 
              class="text-base capitalize flex-1 font-medium text-gray-700 dark:text-gray-200 whitespace-nowrap tracking-wide transition-all duration-300"
              :class="sidebarCollapsed ? 'hidden' : 'block'"
            >
              {{ item?.title }}
            </div>
            <div
              v-if="item?.badgeContent && !sidebarCollapsed"
              class="mr-6 badge badge-sm text-white glass-badge backdrop-blur-md"
              :class="item?.badgeClass"
            >
              {{ item?.badgeContent }}
            </div>
          </div>
          <div class="collapse-content" v-if="!sidebarCollapsed">
            <div v-for="(el, key) of item?.children" class="menu w-full !p-0">
              <RouterLink
                v-if="isNavLink(el)"
                @click="sidebarShow = false"
                class="cursor-pointer flex items-center group relative transition-all duration-200 hover:bg-gray-100/70 dark:hover:bg-white/10 rounded-lg px-2 py-2"
                :class="{
                  'bg-purple-500/15 dark:bg-purple-500/20 border-l-2 border-purple-500': selected($route, el),
                  'justify-center': sidebarCollapsed
                }"
                :to="el.to"
              >
                <div class="icon-wrapper transition-all duration-300"
                  :class="[
                    sidebarCollapsed ? 'mr-0 ml-0' : 'mr-3 ml-3',
                    selected($route, el) ? 'text-purple-500 dark:text-purple-400' : (el.iconColor || 'text-gray-600 dark:text-gray-400')
                  ]"
                >
                  <Icon
                    v-if="el?.icon?.icon"
                    :icon="el.icon.icon"
                    class="text-lg transition-all duration-300"
                  />
                  <img
                    v-else-if="el?.icon?.image"
                    :src="el.icon.image"
                    class="w-5 h-5 rounded-full"
                  />
                  <Icon
                    v-else
                    icon="mdi:circle-outline"
                    class="text-lg"
                  />
                </div>
                <div
                  v-if="!sidebarCollapsed"
                  class="text-sm capitalize text-gray-700 dark:text-gray-300 font-medium tracking-wide transition-all duration-300"
                  :class="{
                    '!text-purple-600 dark:!text-purple-300 font-semibold': selected($route, el),
                  }"
                >
                  {{ item?.title === 'Favorite' ? el?.title : $t(el?.title) }}
                </div>
                <!-- Tooltip for collapsed state -->
                <div 
                  v-if="sidebarCollapsed"
                  class="absolute left-full ml-2 px-3 py-1.5 bg-gray-800 text-white text-sm rounded-lg opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity duration-200 whitespace-nowrap z-50 shadow-lg"
                >
                  {{ item?.title === 'Favorite' ? el?.title : $t(el?.title) }}
                </div>
              </RouterLink>
            </div>
            <div
              v-if="index === 0 && dashboard.networkType === NetworkType.Testnet && !sidebarCollapsed"
              class="menu w-full !p-0"
            >
              <RouterLink
                class="nav-item cursor-pointer flex items-center group relative hover:bg-gray-100/50 dark:hover:bg-white/10 rounded-lg px-2 py-2 transition-all duration-200"
                :class="{
                  'justify-center': sidebarCollapsed
                }"
                :to="`/${blockchain.chainName}/faucet`"
              >
                <div class="glass-icon-wrapper transition-all duration-300 text-blue-300"
                  :class="sidebarCollapsed ? 'mr-0 ml-0' : 'mr-3 ml-3'"
                >
                  <Icon icon="mdi:water" class="text-lg" />
                </div>
                <div v-if="!sidebarCollapsed" class="text-sm capitalize text-gray-400 font-medium tracking-wide">
                  Faucet
                </div>
                <div v-if="!sidebarCollapsed" class="badge badge-sm text-white glass-badge-pulse ml-auto">New</div>
                <!-- Tooltip for collapsed state -->
                <div 
                  v-if="sidebarCollapsed"
                  class="absolute left-full ml-2 px-3 py-1.5 bg-gray-800 text-white text-sm rounded-lg opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity duration-200 whitespace-nowrap z-50 shadow-lg"
                >
                  Faucet
                </div>
              </RouterLink>
            </div>
          </div>
        </div>
        
        <!-- Render nav items directly when collapsed -->
        <template v-if="isNavGroup(item) && sidebarCollapsed && index === 0">
          <template v-for="(el, key) of item?.children" :key="key">
            <RouterLink
              v-if="isNavLink(el)"
              @click="sidebarShow = false"
              class="nav-item cursor-pointer flex items-center group relative justify-center mb-2 transition-all duration-200 hover:bg-gray-100/50 dark:hover:bg-white/10 rounded-lg px-2 py-2"
              :class="{
                'bg-purple-500/10 border-2 border-purple-500/50 rounded-xl': selected($route, el)
              }"
              :to="el.to"
            >
            <div class="icon-wrapper transition-all duration-300"
              :class="selected($route, el) ? 'text-purple-500 dark:text-purple-400' : (el.iconColor || 'text-gray-600 dark:text-gray-400')"
            >
              <Icon
                v-if="el?.icon?.icon"
                :icon="el.icon.icon"
                class="text-lg transition-all duration-300"
              />
              <img
                v-else-if="el?.icon?.image"
                :src="el.icon.image"
                class="w-5 h-5 rounded-full"
              />
              <Icon
                v-else
                icon="mdi:circle-outline"
                class="text-lg"
              />
            </div>
            <!-- Tooltip for collapsed state -->
            <div 
              class="absolute left-full ml-2 px-3 py-1.5 bg-gray-800 text-white text-sm rounded-lg opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity duration-200 whitespace-nowrap z-50 shadow-lg"
            >
              {{ $t(el?.title) }}
            </div>
          </RouterLink>
          </template>
          
          <!-- Faucet item when collapsed -->
          <RouterLink
            v-if="dashboard.networkType === NetworkType.Testnet"
            class="nav-item cursor-pointer flex items-center group relative justify-center mb-2 hover:bg-gray-100/50 dark:hover:bg-white/10 rounded-lg px-2 py-2"
            :to="`/${blockchain.chainName}/faucet`"
          >
            <div class="glass-icon-wrapper transition-all duration-300 text-blue-300">
              <Icon icon="mdi:water" class="text-lg" />
            </div>
            <!-- Tooltip for collapsed state -->
            <div 
              class="absolute left-full ml-2 px-3 py-1.5 bg-gray-800 text-white text-sm rounded-lg opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity duration-200 whitespace-nowrap z-50 shadow-lg"
            >
              Faucet
            </div>
          </RouterLink>
        </template>

        <RouterLink
          v-if="isNavLink(item)"
          :to="item?.to"
          @click="sidebarShow = false"
          class="nav-item cursor-pointer flex items-center mb-2 group relative hover:bg-gray-100/50 dark:hover:bg-white/10 rounded-lg px-2 py-2 transition-all duration-200"
          :class="sidebarCollapsed ? 'justify-center' : ''"
        >
          <div class="icon-wrapper" :class="sidebarCollapsed ? 'mr-0' : 'mr-2'">
            <Icon
              v-if="item?.icon?.icon"
              :icon="item?.icon?.icon"
              class="text-xl transition-all duration-300 group-hover:scale-110"
              :class="{
                'text-yellow-400': item?.title === 'Favorite',
                'text-gray-400': item?.title !== 'Favorite',
              }"
            />
          </div>
          <div v-if="item?.icon?.image" class="icon-wrapper" :class="sidebarCollapsed ? 'mr-0' : 'mr-3'">
            <img
              :src="item?.icon?.image"
              class="w-6 h-6 rounded-full"
            />
          </div>
          <div 
            class="text-base capitalize flex-1 font-medium text-gray-700 dark:text-gray-200 whitespace-nowrap tracking-wide transition-all duration-300"
            :class="sidebarCollapsed ? 'hidden' : 'block'"
          >
            {{ item?.title }}
          </div>
          <div
            v-if="item?.badgeContent && !sidebarCollapsed"
            class="badge badge-sm text-white"
            :class="item?.badgeClass"
          >
            {{ item?.badgeContent }}
          </div>
          <!-- Tooltip when collapsed -->
          <div 
            v-if="sidebarCollapsed"
            class="absolute left-full ml-2 px-2 py-1 bg-gray-800 text-white text-sm rounded-lg opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity duration-200 whitespace-nowrap z-50"
          >
            {{ item?.title }}
          </div>
        </RouterLink>
        <div
          v-if="isNavTitle(item)"
          class="nav-section text-gray-500 dark:text-gray-500 font-semibold text-xs uppercase tracking-wider px-2 mb-2"
        >
          {{ item?.heading }}
        </div>
      </div>
      <div class="px-2 mt-4">
        <div class="nav-section text-gray-500 dark:text-gray-500 font-semibold text-xs uppercase tracking-wider px-2 mb-2" v-if="!sidebarCollapsed">Tools</div>
        <RouterLink
          to="/wallet/suggest"
          class="nav-item flex items-center cursor-pointer mb-2 group relative hover:bg-gray-100/50 dark:hover:bg-white/5 rounded-lg px-2 py-2 transition-all duration-200"
          :class="sidebarCollapsed ? 'justify-center' : ''"
        >
          <div class="icon-wrapper" :class="sidebarCollapsed ? 'mr-0' : 'mr-2'">
            <Icon icon="mdi:wallet-plus" class="text-xl text-purple-600 dark:text-purple-400" />
          </div>
          <div 
            class="text-base capitalize flex-1 font-medium text-gray-300 tracking-wide transition-all duration-300"
            :class="sidebarCollapsed ? 'hidden' : 'block'"
          >
            Wallet Helper
          </div>
          <!-- Tooltip when collapsed -->
          <div 
            v-if="sidebarCollapsed"
            class="absolute left-full ml-2 px-2 py-1 bg-gray-800 text-white text-sm rounded-lg opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity duration-200 whitespace-nowrap z-50"
          >
            Wallet Helper
          </div>
        </RouterLink>
        <div
          v-if="showDiscord"
          class="nav-section text-gray-500 dark:text-gray-500 font-semibold text-xs uppercase tracking-wider px-2 mb-2"
        >
          {{ $t('module.sponsors') }}
        </div>
        <Sponsors v-if="showDiscord && !sidebarCollapsed" />
        <div class="nav-section text-gray-500 dark:text-gray-500 font-semibold text-xs uppercase tracking-wider px-2 mb-2" v-if="!sidebarCollapsed">{{ $t('module.links') }}</div>
        <a
          href="https://twitter.com/flora_network"
          target="_blank"
          class="nav-item flex items-center cursor-pointer mb-2 group relative hover:bg-gray-100/50 dark:hover:bg-white/5 rounded-lg px-2 py-2 transition-all duration-200"
          :class="sidebarCollapsed ? 'justify-center' : ''"
        >
          <div class="icon-wrapper" :class="sidebarCollapsed ? 'mr-0' : 'mr-2'">
            <Icon icon="simple-icons:x" class="text-xl text-sky-600 dark:text-sky-400" />
          </div>
          <div 
            class="text-base capitalize flex-1 font-medium text-gray-300 tracking-wide transition-all duration-300"
            :class="sidebarCollapsed ? 'hidden' : 'block'"
          >
            X (Twitter)
          </div>
          <!-- Tooltip when collapsed -->
          <div 
            v-if="sidebarCollapsed"
            class="absolute left-full ml-2 px-2 py-1 bg-gray-800 text-white text-sm rounded-lg opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity duration-200 whitespace-nowrap z-50"
          >
            X (Twitter)
          </div>
        </a>
        <a
          v-if="showDiscord"
          href="https://discord.com/invite/CmjYVSr6GW"
          target="_blank"
          class="nav-item flex items-center cursor-pointer mb-2 group relative hover:bg-gray-100/50 dark:hover:bg-white/5 rounded-lg px-2 py-2 transition-all duration-200"
          :class="sidebarCollapsed ? 'justify-center' : ''"
        >
          <div class="icon-wrapper" :class="sidebarCollapsed ? 'mr-0' : 'mr-2'">
            <Icon icon="mdi:discord" class="text-xl text-gray-600 dark:text-gray-400" />
          </div>
          <div 
            class="text-base capitalize flex-1 font-medium text-gray-300 tracking-wide transition-all duration-300"
            :class="sidebarCollapsed ? 'hidden' : 'block'"
          >
            Discord
          </div>
          <!-- Tooltip when collapsed -->
          <div 
            v-if="sidebarCollapsed"
            class="absolute left-full ml-2 px-2 py-1 bg-gray-800 text-white text-sm rounded-lg opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity duration-200 whitespace-nowrap z-50"
          >
            Discord
          </div>
        </a>
        <a
          href="https://flora.network"
          target="_blank"
          class="nav-item flex items-center cursor-pointer mb-2 group relative hover:bg-gray-100/50 dark:hover:bg-white/5 rounded-lg px-2 py-2 transition-all duration-200"
          :class="sidebarCollapsed ? 'justify-center' : ''"
        >
          <div class="icon-wrapper" :class="sidebarCollapsed ? 'mr-0' : 'mr-2'">
            <Icon icon="mdi:frequently-asked-questions" class="text-xl text-amber-600 dark:text-amber-400" />
          </div>
          <div 
            class="text-base capitalize flex-1 font-medium text-gray-300 tracking-wide transition-all duration-300"
            :class="sidebarCollapsed ? 'hidden' : 'block'"
          >
            FAQ
          </div>
          <!-- Tooltip when collapsed -->
          <div 
            v-if="sidebarCollapsed"
            class="absolute left-full ml-2 px-2 py-1 bg-gray-800 text-white text-sm rounded-lg opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity duration-200 whitespace-nowrap z-50"
          >
            FAQ
          </div>
        </a>
      </div>
    </div>
    
    <!-- Collapse Toggle Button -->
    <button
      @click="toggleSidebar"
      class="fixed w-10 h-10 rounded-full bg-white/90 dark:bg-[#171d30]/90 hover:bg-white/95 dark:hover:bg-[#1e2437]/90 backdrop-blur-sm border border-purple-500/30 dark:border-purple-500/40 hover:border-purple-500/50 dark:hover:border-purple-500/60 items-center justify-center transition-all duration-300 hidden xl:flex hover:scale-105 group shadow-lg dark:shadow-purple-500/20"
      :style="{ 
        top: '30px',
        left: sidebarCollapsed ? '80px' : '256px',
        zIndex: 2001,
        transform: 'translateX(-50%)',
        boxShadow: '0 2px 8px rgba(0, 0, 0, 0.3), 0 0 12px rgba(147, 51, 234, 0.15)'
      }"
    >
      <Icon 
        :icon="sidebarCollapsed ? 'mdi:chevron-right' : 'mdi:chevron-left'" 
        class="text-lg text-purple-400 group-hover:text-purple-300 transition-colors"
      />
    </button>
    
    <div 
      class="pt-4 transition-all duration-300 ml-0"
      :class="sidebarCollapsed ? 'xl:!ml-20' : 'xl:!ml-64'"
      style="overflow: visible !important"
    >
      <!-- header -->
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mb-4" style="overflow: visible !important; position: relative; z-index: 100;">
        <div
          class="flex items-center py-3 backdrop-blur-sm bg-gradient-to-r from-white/90 via-white/85 to-white/80 dark:from-gray-900/80 dark:via-gray-800/75 dark:to-gray-900/70 rounded-2xl border border-gray-200/50 dark:border-gray-700/50 shadow-lg dark:shadow-[0_4px_20px_0_rgba(0,0,0,0.5)] px-6 relative z-[100]"
          style="overflow: visible !important"
        >
          <div
            class="text-2xl pr-3 cursor-pointer xl:!hidden group"
            @click="sidebarShow = true"
          >
            <Icon icon="mdi-menu" class="text-gray-600 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-gray-200 transition-colors" />
          </div>

          <ChainProfile />

          <div class="flex-1 w-0"></div>

          <!-- <NavSearchBar />-->
          <NavBarI18n class="hidden md:!inline-block" />
          <NavbarThemeSwitcher class="!inline-block" />
          <NavbarSearch class="!inline-block" />
          <NavBarWallet />
        </div>
      </div>

      <!-- 👉 Pages -->
      <div style="min-height: calc(100vh - 180px)">
        <div v-if="behind" class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mb-4">
          <div class="alert alert-error">
            <div class="flex gap-2">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="stroke-current flex-shrink-0 w-6 h-6"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                ></path>
              </svg>
              <span
                >{{ $t('pages.out_of_sync') }} {{ blocktime.format() }} ({{
                  blocktime.fromNow()
                }})</span
              >
            </div>
          </div>
        </div>
        <RouterView v-slot="{ Component }">
          <Transition mode="out-in">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
              <AdBanner v-if="show_ad" />
              <Component :is="Component" />
            </div>
          </Transition>
        </RouterView>
      </div>

      <newFooter />
    </div>
  </div>
</template>

<style>
/* Ensure width transitions work properly */
.w-20, .w-64 {
  transition: width 0.3s ease !important;
}

/* Allow overflow for collapse button */
.nav-brand {
  overflow: visible !important;
}

/* Collapsed nav adjustments */
.w-20 .nav-section {
  display: none;
}

.w-20 .collapse-content {
  display: none !important;
}

/* Smooth transitions for all nav elements */
.nav * {
  transition: all 0.3s ease;
}

/* Active nav item styling */
.nav-item {
  transition: all 0.2s ease;
}

/* Light theme active states - more subtle */
html:not(.dark) .nav-item-active {
  background: rgba(147, 51, 234, 0.1) !important;
  border-color: rgba(147, 51, 234, 0.4) !important;
}

html:not(.dark) .nav-item:hover {
  background: rgba(0, 0, 0, 0.05) !important;
}

/* Dark theme active states */
html.dark .nav-item-active {
  background: rgba(147, 51, 234, 0.1) !important;
}

html.dark .nav-item-active:hover {
  background: rgba(147, 51, 234, 0.15) !important;
}
</style>
