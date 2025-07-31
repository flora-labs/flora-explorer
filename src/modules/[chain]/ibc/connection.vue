<script lang="ts" setup>
import PaginationBar from '@/components/PaginationBar.vue';
import { useBlockchain, useFormatter } from '@/stores';
import { PageRequest, type Connection, type Pagination } from '@/types';
import { computed, onMounted } from 'vue';
import { ref } from 'vue';

import ChainRegistryClient from '@ping-pub/chain-registry-client';
import type { IBCPath } from '@ping-pub/chain-registry-client/dist/types';
import router from '@/router';
import { useIBCModule } from './connStore';

const props = defineProps(['chain']);
const chainStore = useBlockchain();
const ibcStore = useIBCModule();
const list = ref([] as Connection[]);
const pageRequest = ref(new PageRequest());
const pageResponse = ref({} as Pagination);
const tab = ref('registry');

onMounted(() => {
  pageload(1);
  ibcStore.load();
});

function pageload(p: number) {
  pageRequest.value.setPage(p);
  chainStore.rpc.getIBCConnections(pageRequest.value).then((x) => {
    list.value = x.connections;
    pageResponse.value = x.pagination;
    if (x.pagination.total && Number(x.pagination.total) > 0) {
      ibcStore.showConnection(0);
    }
  });
}
</script>
<template>
  <div class="space-y-6">
    <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-purple-500/5 to-blue-500/5 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
      
      <div class="relative">
        <div class="flex flex-wrap gap-4 items-center justify-between">
          <h2 class="text-2xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent">{{ $t('ibc.title') }}</h2>
          <div class="flex gap-2">
            <button 
              class="px-4 py-2 rounded-xl font-medium transition-all duration-200"
              :class="tab === 'registry' 
                ? 'bg-gradient-to-r from-purple-500/20 to-blue-500/20 text-purple-600 dark:text-purple-400 border border-purple-500/30' 
                : 'bg-gray-100 dark:bg-white/5 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-white/10'"
              @click="tab = 'registry'"
            >
              {{ $t('ibc.registry') }}
            </button>
            <button 
              class="px-4 py-2 rounded-xl font-medium transition-all duration-200"
              :class="tab === 'favorite' 
                ? 'bg-gradient-to-r from-purple-500/20 to-blue-500/20 text-purple-600 dark:text-purple-400 border border-purple-500/30' 
                : 'bg-gray-100 dark:bg-white/5 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-white/10'"
              @click="tab = 'favorite'"
            >
              {{ $t('module.favorite') }}
            </button>
          </div>
        </div>
        <div>
        <div v-show="tab === 'registry'" class="flex flex-wrap gap-2 mt-4">
          <button
            v-for="s in ibcStore.commonIBCs"
            class="relative px-4 py-2 rounded-xl text-sm font-semibold bg-gradient-to-r from-purple-500/10 to-indigo-500/10 text-purple-600 dark:text-purple-400 border border-purple-500/30 transition-all duration-300 transform hover:border-purple-500/50 hover:shadow-lg hover:shadow-purple-500/20 hover:-translate-y-0.5 active:translate-y-0 active:shadow-md group overflow-hidden"
            @click="ibcStore.fetchConnection(s.path)"
          >
            <div class="absolute inset-0 bg-gradient-to-r from-purple-600 to-indigo-600 opacity-0 group-hover:opacity-10 transition-opacity duration-300"></div>
            <span class="relative">{{ s.from }} &#x21cc; {{ s.to }}</span>
          </button>
        </div>
        <div v-show="tab === 'favorite'" class="flex flex-wrap gap-2 mt-4">
          <div class="flex items-center gap-2">
            <span class="text-sm text-gray-600 dark:text-gray-400 font-medium">{{ $t('ibc.connection_id') }}:</span>
            <input
              v-model="ibcStore.connectionId"
              type="number"
              class="px-3 py-2 rounded-lg bg-gray-100 dark:bg-white/5 border border-gray-200 dark:border-white/10 focus:border-purple-500 dark:focus:border-purple-400 focus:ring-2 focus:ring-purple-500/20 dark:focus:ring-purple-400/20 transition-all duration-200 w-32"
              min="0"
              :max="pageResponse.total || 0"
              :placeholder="`0~${pageResponse.total}`"
            />
            <button 
              class="relative px-5 py-2.5 rounded-xl font-semibold bg-gradient-to-r from-purple-500 to-blue-500 text-white shadow-lg hover:shadow-xl hover:from-purple-600 hover:to-blue-600 transition-all duration-300 transform hover:-translate-y-0.5 active:translate-y-0 active:shadow-md overflow-hidden group"
              @click="ibcStore.showConnection()"
            >
              <div class="absolute inset-0 bg-white opacity-0 group-hover:opacity-20 transition-opacity duration-300"></div>
              <span class="relative">{{ $t('ibc.btn_apply') }}</span>
            </button>
          </div>
        </div>
        </div>
        <div class="overflow-auto mt-5">
          <router-view :key="$route.fullPath"></router-view>
        </div>
      </div>
    </div>
  </div>
</template>
