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

const changeOpen = (index: Number) => {
  if (index === 0) {
    sidebarOpen.value = !sidebarOpen.value;
  }
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

// Force navigation background on mount
onMounted(() => {
  nextTick(() => {
    // Force navigation background color after all CSS and themes have loaded
    const forceNavBackground = () => {
      const navElements = document.querySelectorAll('.w-64.fixed.z-50.left-0.top-0.bottom-0.overflow-auto, .glass-nav');
      navElements.forEach(el => {
        if (el instanceof HTMLElement) {
          el.style.setProperty('background', '#171d30', 'important');
          el.style.setProperty('background-color', '#171d30', 'important');
          el.style.setProperty('background-image', 'none', 'important');
          el.style.setProperty('backdrop-filter', 'none', 'important');
          el.style.setProperty('-webkit-backdrop-filter', 'none', 'important');
          el.style.setProperty('opacity', '1', 'important');
        }
      });
    };

    // Apply immediately
    forceNavBackground();

    // Also apply after a short delay to override any dynamic theme changes
    setTimeout(forceNavBackground, 100);
    setTimeout(forceNavBackground, 500);
    setTimeout(forceNavBackground, 1000);

    // Watch for theme changes and reapply
    const observer = new MutationObserver(() => {
      forceNavBackground();
    });

    // Observe changes to html data-theme attribute
    const htmlElement = document.documentElement;
    observer.observe(htmlElement, {
      attributes: true,
      attributeFilter: ['data-theme']
    });
  });
});
</script>

<template>
  <div class="bg-gray-100 dark:bg-[#171d30]">
    <!-- sidebar -->
    <div
      class="w-64 fixed z-50 left-0 top-0 bottom-0 overflow-auto glass-nav glass-nav-solid-override"
      :class="{ block: sidebarShow, 'hidden xl:!block': !sidebarShow }"
      :style="{
        background: '#171d30 !important',
        backgroundColor: '#171d30 !important',
        backgroundImage: 'none !important',
        backdropFilter: 'none !important',
        WebkitBackdropFilter: 'none !important',
        opacity: '1 !important'
      }"
    >
      <div class="glass-nav-brand flex justify-between items-center">
        <RouterLink to="/flora-testnet" class="flex items-center">
          <img class="w-10 h-10 glass-nav-logo" src="../../assets/logo.svg" />
          <h1 class="flex-1 ml-3 text-2xl font-semibold glass-nav-title">Flora</h1>
        </RouterLink>
        <div
          class="pr-4 cursor-pointer xl:!hidden"
          @click="sidebarShow = false"
        >
          <Icon icon="mdi-close" class="text-2xl" />
        </div>
      </div>
      <div v-for="(item, index) of blockchain.computedChainMenu" :key="index" class="px-2">
        <div
          v-if="isNavGroup(item)"
          :tabindex="index"
          class="collapse glass-nav-group mb-2 transition-all duration-300"
          :class="{
            'collapse-arrow': index > 0 && item?.children?.length > 0,
            'collapse-open': index === 0 && sidebarOpen,
            'collapse-close': index === 0 && !sidebarOpen,
          }"
        >
          <input v-if="index > 0" type="checkbox" class="cursor-pointer !h-10 block" @click="changeOpen(index)" />
          <div
            class="collapse-title !py-3 px-4 flex items-center cursor-pointer glass-nav-item-hover transition-all duration-300"
          >
            <div class="glass-icon-wrapper mr-2">
              <Icon
                v-if="item?.icon?.icon"
                :icon="item?.icon?.icon"
                class="text-xl transition-all duration-300"
                :class="{
                  'text-yellow-400': item?.title === 'Favorite',
                  'text-gray-400': item?.title !== 'Favorite',
                }"
              />
            </div>
            <div v-if="item?.icon?.image" class="glass-icon-wrapper mr-3">
              <img :src="item?.icon?.image" class="w-6 h-6 rounded-full" />
            </div>
            <div class="text-base capitalize flex-1 font-medium text-gray-300 whitespace-nowrap tracking-wide">
              {{ item?.title }}
            </div>
            <div
              v-if="item?.badgeContent"
              class="mr-6 badge badge-sm text-white glass-badge backdrop-blur-md"
              :class="item?.badgeClass"
            >
              {{ item?.badgeContent }}
            </div>
          </div>
          <div class="collapse-content">
            <div v-for="(el, key) of item?.children" class="menu w-full !p-0">
              <RouterLink
                v-if="isNavLink(el)"
                @click="sidebarShow = false"
                class="glass-nav-item cursor-pointer flex items-center"
                :class="{
                  'active': selected($route, el),
                }"
                :to="el.to"
              >
                <Icon
                  v-if="!el?.icon?.image"
                  icon="mdi:chevron-right"
                  class="mr-2 ml-3 text-gray-500 transition-all duration-300"
                  :class="{
                    '!text-white': selected($route, el),
                  }"
                />
                <div v-if="el?.icon?.image" class="glass-icon-wrapper mr-3 ml-4">
                  <img
                    :src="el?.icon?.image"
                    class="w-6 h-6 rounded-full transition-all duration-300"
                    :class="{
                      'ring-2 ring-cyan-400 ring-offset-2 ring-offset-transparent': selected($route, el),
                    }"
                  />
                </div>
                <div
                  class="text-sm capitalize text-gray-400 font-medium tracking-wide transition-all duration-300"
                  :class="{
                    '!text-gray-100 font-semibold': selected($route, el),
                  }"
                >
                  {{ item?.title === 'Favorite' ? el?.title : $t(el?.title) }}
                </div>
              </RouterLink>
            </div>
            <div
              v-if="index === 0 && dashboard.networkType === NetworkType.Testnet"
              class="menu w-full !p-0"
            >
              <RouterLink
                class="glass-nav-subitem cursor-pointer px-3 py-2 flex items-center transition-all duration-300 group"
                :to="`/${blockchain.chainName}/faucet`"
              >
                <Icon icon="mdi:chevron-right" class="mr-2 ml-3 text-gray-500 transition-all duration-300"></Icon>
                <div class="text-sm capitalize text-gray-400 font-medium tracking-wide">Faucet</div>
                <div class="badge badge-sm text-white glass-badge-pulse ml-auto">New</div>
              </RouterLink>
            </div>
          </div>
        </div>

        <RouterLink
          v-if="isNavLink(item)"
          :to="item?.to"
          @click="sidebarShow = false"
          class="glass-nav-item cursor-pointer flex items-center mb-2 group"
        >
          <div class="glass-icon-wrapper mr-2">
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
          <div v-if="item?.icon?.image" class="glass-icon-wrapper mr-3">
            <img
              :src="item?.icon?.image"
              class="w-6 h-6 rounded-full"
            />
          </div>
          <div class="text-base capitalize flex-1 font-medium text-gray-300 whitespace-nowrap tracking-wide">
            {{ item?.title }}
          </div>
          <div
            v-if="item?.badgeContent"
            class="badge badge-sm text-white"
            :class="item?.badgeClass"
          >
            {{ item?.badgeContent }}
          </div>
        </RouterLink>
        <div
          v-if="isNavTitle(item)"
          class="glass-nav-section"
        >
          {{ item?.heading }}
        </div>
      </div>
      <div class="px-2 mt-4">
        <div class="glass-nav-section">Tools</div>
        <RouterLink
          to="/wallet/suggest"
          class="glass-nav-item flex items-center cursor-pointer mb-2 group"
        >
          <div class="glass-icon-wrapper mr-2">
            <Icon icon="mdi:frequently-asked-questions" class="text-xl text-gray-400" />
          </div>
          <div class="text-base capitalize flex-1 font-medium text-gray-300 tracking-wide">Wallet Helper</div>
        </RouterLink>
        <div
          v-if="showDiscord"
          class="glass-nav-section"
        >
          {{ $t('module.sponsors') }}
        </div>
        <Sponsors v-if="showDiscord" />
        <div class="glass-nav-section">{{ $t('module.links') }}</div>
        <a
          href="https://twitter.com/ping_pub"
          target="_blank"
          class="glass-nav-item flex items-center cursor-pointer mb-2 group"
        >
          <div class="glass-icon-wrapper mr-2">
            <Icon icon="mdi:twitter" class="text-xl text-gray-400" />
          </div>
          <div class="text-base capitalize flex-1 font-medium text-gray-300 tracking-wide">Twitter</div>
        </a>
        <a
          v-if="showDiscord"
          href="https://discord.com/invite/CmjYVSr6GW"
          target="_blank"
          class="glass-nav-item flex items-center cursor-pointer mb-2 group"
        >
          <div class="glass-icon-wrapper mr-2">
            <Icon icon="mdi:discord" class="text-xl text-gray-400" />
          </div>
          <div class="text-base capitalize flex-1 font-medium text-gray-300 tracking-wide">Discord</div>
        </a>
        <a
          href="https://github.com/ping-pub/explorer/discussions"
          target="_blank"
          class="glass-nav-item flex items-center cursor-pointer mb-2 group"
        >
          <div class="glass-icon-wrapper mr-2">
            <Icon icon="mdi:frequently-asked-questions" class="text-xl text-gray-400" />
          </div>
          <div class="text-base capitalize flex-1 font-medium text-gray-300 tracking-wide">FAQ</div>
        </a>
      </div>
    </div>
    <div class="xl:!ml-64 pt-4">
      <!-- header -->
      <div class="container mx-auto px-4 mb-4">
        <div
          class="flex items-center py-3 bg-base-100 rounded-2xl px-4"
        >
          <div
            class="text-2xl pr-3 cursor-pointer xl:!hidden"
            @click="sidebarShow = true"
          >
            <Icon icon="mdi-menu" />
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
        <div v-if="behind" class="container mx-auto px-4 mb-4">
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
            <div>
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
/* CRITICAL: Force solid navigation background for production */
.w-64.fixed.z-50.left-0.top-0.bottom-0.overflow-auto {
  background: #171d30 !important;
  background-color: #171d30 !important;
  background-image: none !important;
  backdrop-filter: none !important;
  -webkit-backdrop-filter: none !important;
  opacity: 1 !important;
}

/* Override glassmorphic theme for navigation */
html[data-theme='glassmorphic'] .w-64.fixed.z-50.left-0.top-0.bottom-0.overflow-auto,
[data-theme='glassmorphic'] .w-64.fixed.z-50.left-0.top-0.bottom-0.overflow-auto {
  background: #171d30 !important;
  background-color: #171d30 !important;
  background-image: none !important;
  backdrop-filter: none !important;
  -webkit-backdrop-filter: none !important;
}

/* Additional override for glass-nav class */
.glass-nav {
  background: #171d30 !important;
  background-color: #171d30 !important;
  backdrop-filter: none !important;
  -webkit-backdrop-filter: none !important;
}
</style>
