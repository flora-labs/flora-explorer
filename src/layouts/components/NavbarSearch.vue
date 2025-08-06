<script lang="ts" setup>
import { Icon } from '@iconify/vue';
import { onMounted, ref, computed } from 'vue';
import { useRouter } from 'vue-router';

import { useBlockchain } from '@/stores';
const vueRouters = useRouter();
const blockStore = useBlockchain();
let searchModalShow = ref(false);
let searchQuery = ref('');
let errorMessage = ref('');
let isSearchFocused = ref(false);
let searchInput = ref<HTMLInputElement | null>(null);
let recentSearches = ref<string[]>([]);

onMounted(() => {
  // Load recent searches from localStorage
  const saved = localStorage.getItem('recentSearches');
  if (saved) {
    recentSearches.value = JSON.parse(saved);
  }
  
  // Add keyboard shortcut for search (Cmd/Ctrl + K)
  document.addEventListener('keydown', (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
      e.preventDefault();
      openSearchModal();
    }
  });
});

// Computed property to determine what type of input we have
const searchType = computed(() => {
  const key = searchQuery.value;
  if (!key) return '';
  
  const height = /^\d+$/;
  const txhash = /^[A-Z\d]{64}$/;
  const addr = /^[a-z\d]+1[a-z\d]{38,58}$/;
  
  if (height.test(key)) return 'block';
  if (txhash.test(key)) return 'transaction';
  if (addr.test(key)) return 'address';
  return 'invalid';
});

const searchPlaceholder = computed(() => {
  if (isSearchFocused.value) {
    return 'Enter block height, tx hash, or address...';
  }
  return 'Search...';
});

function closeSearchModal() {
  searchModalShow.value = false;
  searchQuery.value = '';
  errorMessage.value = '';
  isSearchFocused.value = false;
}

function openSearchModal() {
  searchModalShow.value = true;
  setTimeout(() => {
    searchInput.value?.focus();
  }, 100);
}

function preventClick(event: any) {
  event.preventDefault();
  event.stopPropagation();
}

function saveRecentSearch(query: string) {
  // Add to recent searches
  recentSearches.value = [query, ...recentSearches.value.filter(s => s !== query)].slice(0, 5);
  localStorage.setItem('recentSearches', JSON.stringify(recentSearches.value));
}

function confirm() {
  errorMessage.value = '';
  const key = searchQuery.value.trim();
  if (!key) {
    errorMessage.value = 'Please enter a value!';
    return;
  }
  
  const height = /^\d+$/;
  const txhash = /^[A-Z\d]{64}$/i; // Made case insensitive
  const addr = /^[a-z\d]+1[a-z\d]{38,58}$/;

  const current = blockStore?.current?.chainName || '';
  const routeParams = vueRouters?.currentRoute?.value;

  if (!Object.values(routeParams?.params).includes(key)) {
    if (height.test(key)) {
      saveRecentSearch(key);
      vueRouters.push({ path: `/${current}/block/${key}` });
      closeSearchModal();
    } else if (txhash.test(key.toUpperCase())) {
      saveRecentSearch(key);
      vueRouters.push({ path: `/${current}/tx/${key.toUpperCase()}` });
      closeSearchModal();
    } else if (addr.test(key)) {
      saveRecentSearch(key);
      vueRouters.push({ path: `/${current}/account/${key}` });
      closeSearchModal();
    } else {
      errorMessage.value = 'The input not recognized';
    }
  }
}

function handleKeyUp(event: KeyboardEvent) {
  if (event.key === 'Enter') {
    confirm();
  } else if (event.key === 'Escape') {
    closeSearchModal();
  }
}

function selectRecentSearch(search: string) {
  searchQuery.value = search;
  confirm();
}

function clearRecentSearches() {
  recentSearches.value = [];
  localStorage.removeItem('recentSearches');
}
</script>

<template>
  <div>
    <!-- Compact Search Button for Mobile -->
    <button 
      class="btn btn-ghost btn-circle btn-sm mx-1 lg:hidden relative group"
      @click="openSearchModal"
      title="Search (Ctrl+K)"
    >
      <Icon icon="mdi:magnify" class="text-2xl text-gray-600 dark:text-gray-400 group-hover:text-purple-500 transition-colors" />
      <span class="absolute -top-1 -right-1 w-2 h-2 bg-purple-500 rounded-full animate-pulse"></span>
    </button>

    <!-- Enhanced Search Bar for Desktop -->
    <div class="hidden lg:flex items-center relative group">
      <button
        @click="openSearchModal"
        class="flex items-center gap-3 px-4 py-2 bg-gradient-to-r from-white/80 via-white/70 to-white/60 dark:from-gray-800/80 dark:via-gray-800/70 dark:to-gray-800/60 backdrop-blur-sm rounded-xl border border-white/60 dark:border-white/10 hover:border-purple-500/50 dark:hover:border-purple-400/50 transition-all duration-300 hover:shadow-lg hover:scale-105 min-w-[200px]"
      >
        <Icon icon="mdi:magnify" class="text-lg text-gray-500 dark:text-gray-400" />
        <span class="text-sm text-gray-500 dark:text-gray-400">Search...</span>
        <kbd class="ml-auto text-xs bg-gray-100 dark:bg-gray-800 px-1.5 py-0.5 rounded border border-gray-300 dark:border-gray-600">⌘K</kbd>
      </button>
    </div>

    <!-- Enhanced Search Modal -->
    <Teleport to="body">
      <Transition
        enter-active-class="transition-all duration-300 ease-out"
        enter-from-class="opacity-0"
        enter-to-class="opacity-100"
        leave-active-class="transition-all duration-200 ease-in"
        leave-from-class="opacity-100"
        leave-to-class="opacity-0"
      >
        <div
          v-if="searchModalShow"
          class="fixed inset-0 z-[9999] flex items-start justify-center pt-20 px-4"
        >
          <!-- Backdrop -->
          <div 
            class="absolute inset-0 bg-black/60"
            @click="closeSearchModal"
          ></div>
          
          <!-- Search Container -->
          <div 
            class="relative w-full max-w-2xl animate-slide-down"
            @click.stop
          >
            <!-- Main Search Box -->
            <div class="bg-gradient-to-br from-white/98 via-white/95 to-white/92 dark:from-gray-900/98 dark:via-gray-900/95 dark:to-gray-900/92 backdrop-blur-sm rounded-2xl border border-white/50 dark:border-white/10 shadow-2xl overflow-hidden">
              <!-- Search Input Area -->
              <div class="p-6 pb-4">
                <div class="relative">
                  <Icon 
                    icon="mdi:magnify" 
                    class="absolute left-4 top-1/2 -translate-y-1/2 text-2xl text-purple-500 dark:text-purple-400"
                  />
                  <input
                    ref="searchInput"
                    v-model="searchQuery"
                    @keyup="handleKeyUp"
                    @focus="isSearchFocused = true"
                    @blur="isSearchFocused = false"
                    class="w-full pl-14 pr-4 py-4 bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm rounded-xl border-2 border-transparent focus:border-purple-500/50 dark:focus:border-purple-400/50 outline-none text-lg text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 transition-all duration-300"
                    :placeholder="searchPlaceholder"
                    autocomplete="off"
                    autocorrect="off"
                    autocapitalize="off"
                    spellcheck="false"
                  />
                  
                  <!-- Search Type Indicator -->
                  <div v-if="searchQuery && searchType !== 'invalid'" class="absolute right-4 top-1/2 -translate-y-1/2">
                    <span 
                      class="px-3 py-1 text-xs font-medium rounded-full"
                      :class="{
                        'bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400': searchType === 'block',
                        'bg-purple-100 dark:bg-purple-900/50 text-purple-600 dark:text-purple-400': searchType === 'transaction',
                        'bg-green-100 dark:bg-green-900/50 text-green-600 dark:text-green-400': searchType === 'address'
                      }"
                    >
                      <Icon 
                        :icon="searchType === 'block' ? 'mdi:cube-outline' : 
                               searchType === 'transaction' ? 'mdi:swap-horizontal' : 
                               'mdi:wallet'"
                        class="inline mr-1"
                      />
                      {{ searchType }}
                    </span>
                  </div>
                </div>
                
                <!-- Error Message -->
                <Transition
                  enter-active-class="transition-all duration-300"
                  enter-from-class="opacity-0 -translate-y-2"
                  enter-to-class="opacity-100 translate-y-0"
                  leave-active-class="transition-all duration-200"
                  leave-from-class="opacity-100 translate-y-0"
                  leave-to-class="opacity-0 -translate-y-2"
                >
                  <div v-if="errorMessage" class="mt-3 px-4 py-2 bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 rounded-lg text-sm flex items-center gap-2">
                    <Icon icon="mdi:alert-circle" class="text-lg" />
                    {{ errorMessage }}
                  </div>
                </Transition>
              </div>
              
              <!-- Search Hints -->
              <div class="px-6 pb-4">
                <div class="flex flex-wrap gap-2 text-xs text-gray-500 dark:text-gray-400">
                  <span class="px-2 py-1 bg-gray-100 dark:bg-gray-800 rounded">Block: 12345</span>
                  <span class="px-2 py-1 bg-gray-100 dark:bg-gray-800 rounded">Tx: A1B2C3...</span>
                  <span class="px-2 py-1 bg-gray-100 dark:bg-gray-800 rounded">Address: flora1...</span>
                </div>
              </div>
              
              <!-- Recent Searches -->
              <div v-if="recentSearches.length > 0" class="border-t border-gray-200 dark:border-gray-700 p-4">
                <div class="flex items-center justify-between mb-3">
                  <h3 class="text-sm font-medium text-gray-600 dark:text-gray-400">Recent Searches</h3>
                  <button
                    @click="clearRecentSearches"
                    class="text-xs text-gray-500 hover:text-red-500 transition-colors"
                  >
                    Clear
                  </button>
                </div>
                <div class="space-y-1">
                  <button
                    v-for="search in recentSearches"
                    :key="search"
                    @click="selectRecentSearch(search)"
                    class="w-full text-left px-3 py-2 bg-gray-50 dark:bg-white/5 hover:bg-purple-50 dark:hover:bg-purple-900/20 rounded-lg text-sm text-gray-700 dark:text-gray-300 transition-all duration-200 flex items-center gap-2 group"
                  >
                    <Icon icon="mdi:history" class="text-gray-400 group-hover:text-purple-500" />
                    <span class="font-mono">{{ search }}</span>
                  </button>
                </div>
              </div>
              
              <!-- Action Buttons -->
              <div class="p-4 bg-gray-50 dark:bg-white/5 border-t border-gray-200 dark:border-gray-700 flex items-center justify-between">
                <div class="text-xs text-gray-500 dark:text-gray-400">
                  Press <kbd class="px-1.5 py-0.5 bg-gray-200 dark:bg-gray-700 rounded">Enter</kbd> to search or <kbd class="px-1.5 py-0.5 bg-gray-200 dark:bg-gray-700 rounded">Esc</kbd> to close
                </div>
                <div class="flex gap-2">
                  <button
                    @click="closeSearchModal"
                    class="px-4 py-2 text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    @click="confirm"
                    class="px-6 py-2 bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 text-white rounded-lg text-sm font-medium transition-all duration-200 hover:shadow-lg hover:scale-105"
                    :disabled="!searchQuery || searchType === 'invalid'"
                    :class="{ 'opacity-50 cursor-not-allowed': !searchQuery || searchType === 'invalid' }"
                  >
                    Search
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<style scoped>
@keyframes slide-down {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-slide-down {
  animation: slide-down 0.3s ease-out;
}

/* Pulse animation for the dot */
@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
</style>