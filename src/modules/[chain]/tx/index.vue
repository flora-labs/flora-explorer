<script lang="ts" setup>
import { computed, ref } from '@vue/reactivity';
import { useBaseStore, useBlockchain, useFormatter } from '@/stores';
import type { PaginatedTxs } from '@/types';
import { useRouter } from 'vue-router';
import { onMounted } from 'vue';
import { Icon } from '@iconify/vue';

const props = defineProps(['chain']);
const vueRouters = useRouter();
const tab = ref('recent');

const base = useBaseStore();
const chainStore = useBlockchain();

const format = useFormatter();
const hashReg = /^[A-Z\d]{64}$/;
const hash = ref('');
const current = chainStore?.current?.chainName || '';
onMounted(() => {
  tab.value = String(vueRouters.currentRoute.value.query.tab || 'recent');
});
function search() {
  if (hashReg.test(hash.value)) {
    vueRouters.push({ path: `/${current}/tx/${hash.value}` });
  }
}

function handleKeyPress(event: KeyboardEvent) {
  if (event.key === 'Enter') {
    search();
  }
}
</script>
<template>
  <div class="space-y-6">
    <!-- Tab Navigation -->
    <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-2 shadow-lg dark:shadow-none inline-flex gap-2">
      <button 
        class="px-6 py-3 rounded-2xl font-medium transition-all duration-200"
        :class="tab === 'recent' 
          ? 'bg-gradient-to-r from-purple-500/20 to-blue-500/20 text-purple-600 dark:text-purple-400 border border-purple-500/30' 
          : 'bg-transparent text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-white/10'"
        @click="tab = 'recent'"
      >
        {{ $t('block.recent') }}
      </button>
      <button 
        class="px-6 py-3 rounded-2xl font-medium transition-all duration-200"
        :class="tab === 'search' 
          ? 'bg-gradient-to-r from-purple-500/20 to-blue-500/20 text-purple-600 dark:text-purple-400 border border-purple-500/30' 
          : 'bg-transparent text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-white/10'"
        @click="tab = 'search'"
      >
        Search
      </button>
    </div>

    <!-- Recent Transactions -->
    <div v-show="tab === 'recent'" class="space-y-6">
      <!-- Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
          <div class="absolute top-0 right-0 w-24 h-24 bg-gradient-to-br from-green-500/10 to-emerald-500/10 rounded-full blur-2xl transform translate-x-8 -translate-y-8"></div>
          <div class="relative">
            <div class="flex items-center justify-between mb-2">
              <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Total Transactions</div>
              <Icon icon="mdi:swap-horizontal" class="text-2xl text-green-500/70 dark:text-green-400/70" />
            </div>
            <div class="text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 dark:from-green-400 dark:to-emerald-400 bg-clip-text text-transparent">
              {{ base.txsInRecents.length || 0 }}
            </div>
          </div>
        </div>

        <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
          <div class="absolute top-0 right-0 w-24 h-24 bg-gradient-to-br from-blue-500/10 to-cyan-500/10 rounded-full blur-2xl transform translate-x-8 -translate-y-8"></div>
          <div class="relative">
            <div class="flex items-center justify-between mb-2">
              <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Latest Block</div>
              <Icon icon="mdi:cube-outline" class="text-2xl text-blue-500/70 dark:text-blue-400/70" />
            </div>
            <div class="text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 dark:from-blue-400 dark:to-cyan-400 bg-clip-text text-transparent">
              #{{ base.txsInRecents[0]?.height || '0' }}
            </div>
          </div>
        </div>

        <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
          <div class="absolute top-0 right-0 w-24 h-24 bg-gradient-to-br from-purple-500/10 to-pink-500/10 rounded-full blur-2xl transform translate-x-8 -translate-y-8"></div>
          <div class="relative">
            <div class="flex items-center justify-between mb-2">
              <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Avg Fee</div>
              <Icon icon="mdi:cash" class="text-2xl text-purple-500/70 dark:text-purple-400/70" />
            </div>
            <div class="text-2xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 dark:from-purple-400 dark:to-pink-400 bg-clip-text text-transparent">
              0 FLORA
            </div>
          </div>
        </div>
      </div>

      <!-- Transactions List -->
      <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-purple-500/5 via-blue-500/5 to-pink-500/5 rounded-full blur-3xl transform translate-x-48 -translate-y-48"></div>
        
        <div class="relative">
          <!-- Header -->
          <div class="p-6 border-b border-gray-200 dark:border-white/10">
            <div class="flex items-center justify-between">
              <h2 class="text-xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent flex items-center gap-2">
                <Icon icon="mdi:swap-horizontal" class="text-2xl text-purple-500" />
                Recent Transactions
              </h2>
              <span class="text-sm text-gray-500 dark:text-gray-400">
                Last 50 transactions
              </span>
            </div>
          </div>

          <!-- Transactions -->
          <div class="divide-y divide-gray-200 dark:divide-white/10">
            <div
              v-for="(item, index) in base.txsInRecents"
              :key="index"
              class="p-6 hover:bg-gray-50 dark:hover:bg-white/5 transition-all duration-200 group"
            >
              <div class="flex items-start justify-between gap-4">
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-4 mb-3">
                    <div class="flex items-center gap-2">
                      <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-purple-500/20 to-blue-500/20 flex items-center justify-center">
                        <Icon icon="mdi:swap-horizontal" class="text-purple-600 dark:text-purple-400" />
                      </div>
                      <div>
                        <RouterLink
                          :to="`/${props.chain}/block/${item.height}`"
                          class="text-sm font-semibold text-purple-600 dark:text-purple-400 hover:text-purple-700 dark:hover:text-purple-300 transition-colors"
                        >
                          Block #{{ item.height }}
                        </RouterLink>
                        <div class="text-xs text-gray-500 dark:text-gray-400">
                          {{ format.messages(item.tx.body.messages) }}
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <RouterLink
                    :to="`/${props.chain}/tx/${item.hash}`"
                    class="group/link flex items-center gap-2 mb-2"
                  >
                    <span class="text-sm font-mono text-gray-600 dark:text-gray-400 group-hover/link:text-purple-600 dark:group-hover/link:text-purple-400 transition-colors break-all">
                      {{ item.hash }}
                    </span>
                    <Icon icon="mdi:arrow-right" class="text-gray-400 group-hover/link:text-purple-600 dark:group-hover/link:text-purple-400 opacity-0 group-hover/link:opacity-100 transition-all duration-200 transform group-hover/link:translate-x-1 flex-shrink-0" />
                  </RouterLink>
                </div>
                
                <div class="text-right flex-shrink-0">
                  <div class="text-sm font-semibold text-gray-900 dark:text-white">
                    {{ format.formatTokens(item.tx.authInfo.fee?.amount) || '0 FLORA' }}
                  </div>
                  <div class="text-xs text-gray-500 dark:text-gray-400">
                    Fee
                  </div>
                </div>
              </div>
            </div>
            
            <div v-if="base.txsInRecents.length === 0" class="p-12 text-center">
              <div class="inline-flex items-center justify-center w-20 h-20 rounded-full bg-gradient-to-br from-purple-500/10 to-blue-500/10 mb-4">
                <Icon icon="mdi:swap-horizontal-circle-outline" class="text-4xl text-purple-500/50 dark:text-purple-400/50" />
              </div>
              <p class="text-gray-500 dark:text-gray-400 font-medium">No recent transactions found</p>
              <p class="text-sm text-gray-400 dark:text-gray-500 mt-1">Transactions will appear here once they're processed</p>
            </div>
          </div>
          
          <!-- Footer Info -->
          <div class="p-6 border-t border-gray-200 dark:border-white/10">
            <div class="flex items-center gap-3">
              <Icon icon="mdi:information" class="text-blue-600 dark:text-blue-400 text-xl flex-shrink-0" />
              <p class="text-sm text-gray-600 dark:text-gray-400">
                {{ $t('block.only_tx') }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Search Tab -->
    <div v-show="tab === 'search'" class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-purple-500/5 to-blue-500/5 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
      
      <div class="relative p-8">
        <h2 class="text-xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent flex items-center gap-2 mb-6">
          <Icon icon="mdi:magnify" class="text-2xl text-purple-500" />
          Search Transaction
        </h2>
        
        <div class="max-w-2xl">
          <div class="relative">
            <input
              v-model="hash"
              type="text"
              class="w-full pl-12 pr-4 py-4 rounded-2xl bg-gray-50 dark:bg-white/5 border border-gray-200 dark:border-white/10 focus:border-purple-500 dark:focus:border-purple-400 focus:ring-4 focus:ring-purple-500/20 dark:focus:ring-purple-400/20 transition-all duration-200 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400"
              placeholder="Enter transaction hash (64 characters)"
              @keypress="handleKeyPress"
            />
            <Icon icon="mdi:magnify" class="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400 text-xl" />
          </div>
          
          <button
            @click="search"
            class="mt-4 px-6 py-3 rounded-xl bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white font-medium transition-all duration-200 transform hover:scale-105 hover:shadow-lg flex items-center gap-2"
          >
            <Icon icon="mdi:magnify" class="text-xl" />
            Search Transaction
          </button>
          
          <div class="mt-6 text-sm text-gray-500 dark:text-gray-400">
            <p class="flex items-center gap-2">
              <Icon icon="mdi:information-outline" class="text-base" />
              Transaction hash must be 64 characters long and contain only uppercase letters and numbers
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<route>
    {
      meta: {
        i18n: 'tx',
        order: 5
      }
    }
  </route>
