<script lang="ts" setup>
import { useGovStore } from '@/stores';
import ProposalListItem from '@/components/ProposalListItem.vue';
import { ref, onMounted } from 'vue';
import PaginationBar from '@/components/PaginationBar.vue';
import { PageRequest } from '@/types';
import { Icon } from '@iconify/vue';

const tab = ref('2');
const store = useGovStore();
const pageRequest = ref(new PageRequest());

onMounted(() => {
  store.fetchProposals('2').then((x) => {
    if (x?.proposals?.length === 0) {
      tab.value = '3';
      store.fetchProposals('3');
    }
    store.fetchProposals('3');
    store.fetchProposals('4');
  });
});

const changeTab = (val: '2' | '3' | '4') => {
  tab.value = val;
};

function page(p: number) {
  pageRequest.value.setPage(p);
  store.fetchProposals(tab.value, pageRequest.value);
}
</script>
<template>
  <div class="space-y-6">
    <!-- Page Header with Stats -->
    <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-purple-50/90 to-blue-50/90 dark:from-white/5 dark:via-purple-900/10 dark:to-blue-900/10 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-purple-400/20 via-blue-400/15 to-pink-400/20 rounded-full blur-3xl transform translate-x-48 -translate-y-48 animate-pulse-slow"></div>
      <div class="absolute bottom-0 left-0 w-80 h-80 bg-gradient-to-tr from-blue-400/20 via-indigo-400/15 to-purple-400/20 rounded-full blur-3xl transform -translate-x-40 translate-y-40 animate-pulse-slow" style="animation-delay: 2s"></div>
      
      <div class="relative p-8">
        <div class="flex items-center gap-4 mb-6">
          <div class="p-4 rounded-2xl bg-gradient-to-br from-purple-500/20 to-blue-500/20 backdrop-blur-sm">
            <Icon icon="mdi:gavel" class="text-4xl text-purple-600 dark:text-purple-400" />
          </div>
          <div>
            <h1 class="text-3xl font-bold bg-gradient-to-r from-purple-600 via-blue-600 to-pink-600 dark:from-purple-400 dark:via-blue-400 dark:to-pink-400 bg-clip-text text-transparent animate-gradient">
              {{ $t('module.governance') }}
            </h1>
            <p class="text-gray-600 dark:text-gray-400 mt-1">Participate in network governance</p>
          </div>
        </div>
        
        <!-- Stats Grid -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="backdrop-blur-sm bg-gradient-to-br from-white/70 to-purple-50/70 dark:from-white/10 dark:to-purple-900/10 rounded-2xl border border-purple-200/50 dark:border-purple-500/20 p-6 hover:from-white/90 hover:to-purple-100/90 dark:hover:from-white/15 dark:hover:to-purple-900/15 transition-all duration-200 hover:scale-105 hover:shadow-lg">
            <div class="flex items-center justify-between mb-3">
              <div class="p-2 rounded-xl bg-gradient-to-br from-purple-500/20 to-pink-500/20">
                <Icon icon="mdi:vote" class="text-2xl text-purple-600 dark:text-purple-400" />
              </div>
            </div>
            <p class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Active Proposals</p>
            <p class="text-2xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 dark:from-purple-400 dark:to-pink-400 bg-clip-text text-transparent">{{ store?.proposals['2']?.proposals?.length || 0 }}</p>
          </div>
          
          <div class="backdrop-blur-sm bg-gradient-to-br from-white/70 to-emerald-50/70 dark:from-white/10 dark:to-emerald-900/10 rounded-2xl border border-emerald-200/50 dark:border-emerald-500/20 p-6 hover:from-white/90 hover:to-emerald-100/90 dark:hover:from-white/15 dark:hover:to-emerald-900/15 transition-all duration-200 hover:scale-105 hover:shadow-lg">
            <div class="flex items-center justify-between mb-3">
              <div class="p-2 rounded-xl bg-gradient-to-br from-emerald-500/20 to-green-500/20">
                <Icon icon="mdi:check-circle" class="text-2xl text-emerald-600 dark:text-emerald-400" />
              </div>
            </div>
            <p class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Passed Proposals</p>
            <p class="text-2xl font-bold bg-gradient-to-r from-emerald-600 to-green-600 dark:from-emerald-400 dark:to-green-400 bg-clip-text text-transparent">{{ store?.proposals['3']?.proposals?.length || 0 }}</p>
          </div>
          
          <div class="backdrop-blur-sm bg-gradient-to-br from-white/70 to-red-50/70 dark:from-white/10 dark:to-red-900/10 rounded-2xl border border-red-200/50 dark:border-red-500/20 p-6 hover:from-white/90 hover:to-red-100/90 dark:hover:from-white/15 dark:hover:to-red-900/15 transition-all duration-200 hover:scale-105 hover:shadow-lg">
            <div class="flex items-center justify-between mb-3">
              <div class="p-2 rounded-xl bg-gradient-to-br from-red-500/20 to-pink-500/20">
                <Icon icon="mdi:close-circle" class="text-2xl text-red-600 dark:text-red-400" />
              </div>
            </div>
            <p class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Rejected Proposals</p>
            <p class="text-2xl font-bold bg-gradient-to-r from-red-600 to-pink-600 dark:from-red-400 dark:to-pink-400 bg-clip-text text-transparent">{{ store?.proposals['4']?.proposals?.length || 0 }}</p>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Tabs Navigation -->
    <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 to-white/90 dark:from-white/5 dark:to-white/5 rounded-2xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none px-6 py-4">
      <div class="flex gap-3">
        <button
          @click="changeTab('2')"
          class="flex-1 px-6 py-3 rounded-xl font-medium transition-all duration-200"
          :class="tab === '2' 
            ? 'bg-gradient-to-r from-purple-600 to-blue-600 text-white shadow-lg transform scale-105' 
            : 'bg-gray-100 dark:bg-white/5 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-white/10'"
        >
          <Icon icon="mdi:vote" class="inline-block mr-2" />
          {{ $t('gov.voting') }}
        </button>
        <button
          @click="changeTab('3')"
          class="flex-1 px-6 py-3 rounded-xl font-medium transition-all duration-200"
          :class="tab === '3' 
            ? 'bg-gradient-to-r from-emerald-600 to-green-600 text-white shadow-lg transform scale-105' 
            : 'bg-gray-100 dark:bg-white/5 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-white/10'"
        >
          <Icon icon="mdi:check-circle" class="inline-block mr-2" />
          {{ $t('gov.passed') }}
        </button>
        <button
          @click="changeTab('4')"
          class="flex-1 px-6 py-3 rounded-xl font-medium transition-all duration-200"
          :class="tab === '4' 
            ? 'bg-gradient-to-r from-red-600 to-pink-600 text-white shadow-lg transform scale-105' 
            : 'bg-gray-100 dark:bg-white/5 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-white/10'"
        >
          <Icon icon="mdi:close-circle" class="inline-block mr-2" />
          {{ $t('gov.rejected') }}
        </button>
      </div>
    </div>
    
    <!-- Proposals List -->
    <ProposalListItem :proposals="store?.proposals[tab]" />
    
    <!-- Pagination -->
    <PaginationBar :total="store?.proposals[tab]?.pagination?.total" :limit="pageRequest.limit" :callback="page" />
  </div>
</template>
<route>
  {
    meta: {
      i18n: 'governance',
      order: 2
    }
  }
</route>

<style scoped>
/* Gradient animation */
@keyframes gradient {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}

.animate-gradient {
  background-size: 200% 200%;
  animation: gradient 3s ease infinite;
}

/* Slow pulse animation */
@keyframes pulse-slow {
  0%, 100% {
    opacity: 0.3;
    transform: translate(var(--tw-translate-x), var(--tw-translate-y)) scale(1);
  }
  50% {
    opacity: 0.5;
    transform: translate(var(--tw-translate-x), var(--tw-translate-y)) scale(1.1);
  }
}

.animate-pulse-slow {
  animation: pulse-slow 4s ease-in-out infinite;
}
</style>
