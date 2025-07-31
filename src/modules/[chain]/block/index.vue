<script lang="ts" setup>
import { computed, ref } from '@vue/reactivity';
import { useBaseStore, useFormatter } from '@/stores';
import TxsInBlocksChart from '@/components/charts/TxsInBlocksChart.vue';
import { Icon } from '@iconify/vue';

const props = defineProps(['chain']);

const tab = ref('blocks');
const viewMode = ref('grid'); // 'grid' or 'table'

const base = useBaseStore();

const format = useFormatter();

const list = computed(() => {
  // Sort blocks by height in descending order (latest first)
  const recents = [...base.recents];
  return recents.sort((a, b) => Number(b.block.header.height) - Number(a.block.header.height));
});

const copyHash = (hash: string) => {
  navigator.clipboard.writeText(hash);
  // You could add a toast notification here
};
</script>
<template>
  <div class="space-y-6">
    <!-- Navigation Row -->
    <div class="flex items-center justify-between flex-wrap gap-4">
      <!-- Tab Navigation -->
      <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-2 shadow-lg dark:shadow-none inline-flex gap-2">
        <button 
          class="px-6 py-3 rounded-2xl font-medium transition-all duration-200"
          :class="tab === 'blocks' 
            ? 'bg-gradient-to-r from-purple-500/20 to-blue-500/20 text-purple-600 dark:text-purple-400 border border-purple-500/30' 
            : 'bg-transparent text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-white/10'"
          @click="tab = 'blocks'"
        >
          {{ $t('block.recent') }}
        </button>
        <RouterLink
          class="px-6 py-3 rounded-2xl font-medium transition-all duration-200 bg-transparent text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-white/10"
          :to="`/${chain}/block/${Number(base.latest?.block?.header.height || 0) + 10000}`"
        >
          {{ $t('block.future') }}
        </RouterLink>
      </div>

      <!-- View Mode Toggle -->
      <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-2 shadow-lg dark:shadow-none inline-flex gap-2">
        <button
          class="px-4 py-2 rounded-xl font-medium transition-all duration-200 flex items-center gap-2"
          :class="viewMode === 'grid' 
            ? 'bg-gradient-to-r from-purple-500/20 to-blue-500/20 text-purple-600 dark:text-purple-400 border border-purple-500/30' 
            : 'bg-transparent text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-white/10'"
          @click="viewMode = 'grid'"
        >
          <Icon icon="mdi:view-grid" class="text-xl" />
          Grid
        </button>
        <button
          class="px-4 py-2 rounded-xl font-medium transition-all duration-200 flex items-center gap-2"
          :class="viewMode === 'table' 
            ? 'bg-gradient-to-r from-purple-500/20 to-blue-500/20 text-purple-600 dark:text-purple-400 border border-purple-500/30' 
            : 'bg-transparent text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-white/10'"
          @click="viewMode = 'table'"
        >
          <Icon icon="mdi:table" class="text-xl" />
          Table
        </button>
      </div>
    </div>

    <div v-show="tab === 'blocks'" class="space-y-6">
      <!-- Chart Container -->
      <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-purple-500/5 to-blue-500/5 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
        <div class="relative">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
            <Icon icon="mdi:chart-bar" class="text-purple-500" />
            Transactions per Block
          </h3>
          <TxsInBlocksChart />
        </div>
      </div>

      <!-- Blocks Grid View -->
      <TransitionGroup 
        v-show="viewMode === 'grid'"
        name="block-list" 
        tag="div"
        class="grid xl:!grid-cols-6 lg:!grid-cols-4 md:!grid-cols-3 sm:!grid-cols-2 grid-cols-1 gap-4"
      >
        <RouterLink
          v-for="(item, index) in list"
          :key="item.block.header.height"
          class="group backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-2xl border border-gray-200 dark:border-white/10 p-5 shadow-lg dark:shadow-none hover:shadow-xl transition-all duration-200 hover:scale-105 hover:border-purple-500/30 relative overflow-hidden"
          :class="{ 'animate-pulse-once': index === 0 }"
          :to="`/${chain}/block/${item.block.header.height}`"
        >
          <!-- Background decoration -->
          <div class="absolute top-0 right-0 w-24 h-24 bg-gradient-to-br from-blue-500/10 to-purple-500/10 rounded-full blur-2xl transform translate-x-8 -translate-y-8 group-hover:scale-150 transition-transform duration-500"></div>
          
          <div class="relative">
            <div class="flex justify-between items-start mb-3">
              <h3 class="text-xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent">
                #{{ item.block.header.height }}
              </h3>
              <div class="flex items-center gap-2">
                <span v-if="index === 0" class="text-xs font-bold text-purple-600 dark:text-purple-400 bg-purple-100 dark:bg-purple-900/20 px-2 py-1 rounded-lg animate-pulse">
                  NEW
                </span>
                <span class="text-xs font-medium text-green-600 dark:text-green-400 bg-green-100 dark:bg-green-900/20 px-2 py-1 rounded-lg">
                  {{ format.toDay(item.block?.header?.time, 'from') }}
                </span>
              </div>
            </div>
            
            <div class="space-y-2">
              <div class="text-sm text-gray-600 dark:text-gray-400 truncate">
                <span class="font-medium">Proposer:</span>
                <span class="ml-1">{{ format.validator(item.block?.header?.proposer_address) || 'Unknown' }}</span>
              </div>
              <div class="flex items-center justify-between">
                <span class="text-xs text-gray-500 dark:text-gray-500">Transactions</span>
                <span class="text-sm font-semibold text-gray-900 dark:text-white bg-gray-100 dark:bg-white/10 px-2 py-0.5 rounded">
                  {{ item.block?.data?.txs.length || 0 }}
                </span>
              </div>
            </div>
          </div>
        </RouterLink>
      </TransitionGroup>

      <!-- Blocks Table View -->
      <div v-show="viewMode === 'table'" class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-purple-500/5 via-blue-500/5 to-pink-500/5 rounded-full blur-3xl transform translate-x-48 -translate-y-48"></div>
        
        <div class="relative">
          <!-- Table Header -->
          <div class="p-6 border-b border-gray-200 dark:border-white/10">
            <h2 class="text-xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent flex items-center gap-2">
              <Icon icon="mdi:table" class="text-2xl text-purple-500" />
              Block Details
            </h2>
          </div>

          <!-- Table Content -->
          <div class="overflow-x-auto">
            <table class="w-full">
              <thead>
                <tr class="border-b border-gray-200 dark:border-white/10">
                  <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-4 px-6 text-left">Height</th>
                  <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-4 px-6 text-left">Block Hash</th>
                  <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-4 px-6 text-left">Proposer</th>
                  <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-4 px-6 text-center">Txs</th>
                  <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-4 px-6 text-right">Time</th>
                </tr>
              </thead>
              <tbody>
                <tr 
                  v-for="(item, index) in list" 
                  :key="item.block.header.height"
                  class="border-b border-gray-100 dark:border-white/5 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors duration-200"
                >
                  <td class="py-4 px-6">
                    <RouterLink 
                      :to="`/${chain}/block/${item.block.header.height}`"
                      class="flex items-center gap-2"
                    >
                      <span class="text-sm font-semibold text-purple-600 dark:text-purple-400 hover:text-purple-700 dark:hover:text-purple-300 transition-colors">
                        #{{ item.block.header.height }}
                      </span>
                      <span v-if="index === 0" class="text-xs font-bold text-purple-600 dark:text-purple-400 bg-purple-100 dark:bg-purple-900/20 px-2 py-0.5 rounded-lg animate-pulse">
                        NEW
                      </span>
                    </RouterLink>
                  </td>
                  <td class="py-4 px-6">
                    <div class="flex items-center gap-2 group">
                      <span class="text-sm font-mono text-gray-600 dark:text-gray-400 truncate max-w-[200px] lg:max-w-[300px]">
                        {{ item.block_id?.hash || 'Pending...' }}
                      </span>
                      <button 
                        v-if="item.block_id?.hash"
                        @click.prevent="copyHash(item.block_id.hash)"
                        class="opacity-0 group-hover:opacity-100 transition-opacity duration-200"
                        title="Copy hash"
                      >
                        <Icon icon="mdi:content-copy" class="text-gray-400 hover:text-purple-600 dark:hover:text-purple-400 transition-colors" />
                      </button>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <span class="text-sm text-gray-700 dark:text-gray-300">
                      {{ format.validator(item.block?.header?.proposer_address) || 'Unknown' }}
                    </span>
                  </td>
                  <td class="py-4 px-6 text-center">
                    <span class="inline-flex items-center justify-center text-sm font-semibold text-gray-900 dark:text-white bg-gray-100 dark:bg-white/10 px-3 py-1 rounded-lg min-w-[3rem]">
                      {{ item.block?.data?.txs.length || 0 }}
                    </span>
                  </td>
                  <td class="py-4 px-6 text-right">
                    <span class="text-sm text-gray-600 dark:text-gray-400">
                      {{ format.toDay(item.block?.header?.time, 'from') }}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<route>
    {
      meta: {
        i18n: 'blocks',
        order: 5
      }
    }
  </route>

<style scoped>
/* Block list transitions */
.block-list-enter-active,
.block-list-leave-active {
  transition: all 0.5s ease;
}

.block-list-enter-from {
  opacity: 0;
  transform: translateY(-30px);
}

.block-list-leave-to {
  opacity: 0;
  transform: translateY(30px);
}

.block-list-move {
  transition: transform 0.5s ease;
}

/* Pulse animation for new blocks */
@keyframes pulse-once {
  0% {
    box-shadow: 0 0 0 0 rgba(139, 92, 246, 0.4);
  }
  70% {
    box-shadow: 0 0 0 10px rgba(139, 92, 246, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(139, 92, 246, 0);
  }
}

.animate-pulse-once {
  animation: pulse-once 1s ease-out;
}
</style>
