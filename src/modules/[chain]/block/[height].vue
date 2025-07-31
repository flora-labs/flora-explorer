<script lang="ts" setup>
import { onMounted, ref, watchEffect } from 'vue';
import { Icon } from '@iconify/vue';
import TxsElement from '@/components/dynamic/TxsElement.vue';
import DynamicComponent from '@/components/dynamic/DynamicComponent.vue';
import { computed } from '@vue/reactivity';
import { onBeforeRouteUpdate } from 'vue-router';
import { useBaseStore, useFormatter } from '@/stores';
import type { Block } from '@/types';
import Countdown from '@/components/Countdown.vue';

const props = defineProps(['height', 'chain']);

const store = useBaseStore();
const format = useFormatter();
const current = ref({} as Block);
const target = ref(Number(props.height || 0));

const height = computed(() => {
  return Number(current.value.block?.header?.height || props.height || 0);
});

const isFutureBlock = computed({
  get: () => {
    const latest = store.latest?.block?.header.height;
    const isFuture = latest ? target.value > Number(latest) : true;
    if (!isFuture && !current.value.block_id) store.fetchBlock(target.value).then((x) => (current.value = x));
    return isFuture;
  },
  set: (val) => {
    console.log(val);
  },
});

const remainingBlocks = computed(() => {
  const latest = store.latest?.block?.header.height;
  return latest ? Number(target.value) - Number(latest) : 0;
});

const estimateTime = computed(() => {
  const seconds = Number((remainingBlocks.value * store.blocktime).toFixed(2));
  return seconds;
});

const estimateDate = computed(() => {
  return new Date(new Date().getTime() + estimateTime.value);
});

const edit = ref(false);
const newHeight = ref(props.height);
function updateTarget() {
  target.value = Number(newHeight.value);
  console.log(target.value);
}

onBeforeRouteUpdate(async (to, from, next) => {
  if (from.path !== to.path) {
    store.fetchBlock(String(to.params.height)).then((x) => (current.value = x));
    next();
  }
});
</script>
<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-6">
    <!-- Future Block Countdown -->
    <div v-if="isFutureBlock" class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-purple-50/90 to-blue-50/90 dark:from-white/5 dark:via-purple-900/10 dark:to-blue-900/10 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-purple-400/20 via-blue-400/15 to-pink-400/20 rounded-full blur-3xl transform translate-x-48 -translate-y-48 animate-pulse-slow"></div>
      <div class="absolute bottom-0 left-0 w-80 h-80 bg-gradient-to-tr from-blue-400/20 via-indigo-400/15 to-purple-400/20 rounded-full blur-3xl transform -translate-x-40 translate-y-40 animate-pulse-slow" style="animation-delay: 2s"></div>
      
      <div v-if="remainingBlocks > 0" class="relative p-8 text-center">
        <div class="mb-8">
          <Icon icon="mdi:timer-sand" class="text-6xl text-purple-500/30 dark:text-purple-400/30 mb-4 animate-pulse" />
          <h1 class="text-5xl font-bold bg-gradient-to-r from-purple-600 via-blue-600 to-pink-600 dark:from-purple-400 dark:via-blue-400 dark:to-pink-400 bg-clip-text text-transparent animate-gradient">
            Block #{{ target }}
          </h1>
        </div>
        
        <div class="mb-8">
          <Countdown :time="estimateTime" css="md:!text-5xl font-sans md:mx-5 bg-gradient-to-r from-indigo-600 to-purple-600 dark:from-indigo-400 dark:to-purple-400 bg-clip-text !text-transparent font-bold" />
        </div>
        
        <div class="mb-12">
          <p class="text-gray-600 dark:text-gray-400 mb-2 font-medium">{{ $t('block.estimated_time') }}</p>
          <p class="text-2xl font-semibold bg-gradient-to-r from-blue-600 to-indigo-600 dark:from-blue-400 dark:to-indigo-400 bg-clip-text text-transparent">
            {{ format.toLocaleDate(estimateDate) }}
          </p>
        </div>
        
        <!-- Stats Grid -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 max-w-3xl mx-auto">
          <div class="backdrop-blur-sm bg-gradient-to-br from-white/70 to-purple-50/70 dark:from-white/10 dark:to-purple-900/10 rounded-2xl border border-purple-200/50 dark:border-purple-500/20 p-6 cursor-pointer hover:from-white/90 hover:to-purple-100/90 dark:hover:from-white/15 dark:hover:to-purple-900/15 transition-all duration-200 group hover:scale-105 hover:shadow-lg" @click="edit = !edit">
            <div class="flex items-center justify-between mb-3">
              <div class="p-2 rounded-xl bg-gradient-to-br from-purple-500/20 to-pink-500/20">
                <Icon icon="mdi:target" class="text-2xl text-purple-600 dark:text-purple-400" />
              </div>
              <Icon icon="mdi:pencil" class="text-sm text-gray-400 group-hover:text-purple-600 dark:group-hover:text-purple-400 transition-colors" />
            </div>
            <p class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{{ $t('block.countdown_for_block') }}</p>
            <p class="text-xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 dark:from-purple-400 dark:to-pink-400 bg-clip-text text-transparent">#{{ target }}</p>
          </div>
          
          <div class="backdrop-blur-sm bg-gradient-to-br from-white/70 to-blue-50/70 dark:from-white/10 dark:to-blue-900/10 rounded-2xl border border-blue-200/50 dark:border-blue-500/20 p-6 hover:from-white/90 hover:to-blue-100/90 dark:hover:from-white/15 dark:hover:to-blue-900/15 transition-all duration-200 hover:scale-105 hover:shadow-lg">
            <div class="p-2 rounded-xl bg-gradient-to-br from-blue-500/20 to-cyan-500/20 mb-3">
              <Icon icon="mdi:cube-outline" class="text-2xl text-blue-600 dark:text-blue-400" />
            </div>
            <p class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{{ $t('block.current_height') }}</p>
            <p class="text-xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 dark:from-blue-400 dark:to-cyan-400 bg-clip-text text-transparent">#{{ store.latest?.block?.header.height }}</p>
          </div>
          
          <div class="backdrop-blur-sm bg-gradient-to-br from-white/70 to-emerald-50/70 dark:from-white/10 dark:to-emerald-900/10 rounded-2xl border border-emerald-200/50 dark:border-emerald-500/20 p-6 hover:from-white/90 hover:to-emerald-100/90 dark:hover:from-white/15 dark:hover:to-emerald-900/15 transition-all duration-200 hover:scale-105 hover:shadow-lg">
            <div class="p-2 rounded-xl bg-gradient-to-br from-emerald-500/20 to-green-500/20 mb-3">
              <Icon icon="mdi:timer-sand" class="text-2xl text-emerald-600 dark:text-emerald-400" />
            </div>
            <p class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{{ $t('block.average_block_time') }}</p>
            <p class="text-xl font-bold bg-gradient-to-r from-emerald-600 to-green-600 dark:from-emerald-400 dark:to-green-400 bg-clip-text text-transparent">{{ (store.blocktime / 1000).toFixed(1) }}s</p>
          </div>
        </div>
        
        <!-- Edit Input -->
        <Transition name="slide-fade">
          <div v-if="edit" class="mt-6 max-w-md mx-auto">
            <div class="backdrop-blur-sm bg-white/50 dark:bg-white/5 rounded-2xl border border-purple-500/30 p-6">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                {{ $t('block.countdown_for_block_input') }}
              </h3>
              <div class="flex gap-2">
                <input 
                  v-model="newHeight" 
                  type="number" 
                  class="flex-1 px-4 py-3 rounded-xl bg-gray-50 dark:bg-white/5 border border-gray-200 dark:border-white/10 focus:border-purple-500 dark:focus:border-purple-400 focus:ring-4 focus:ring-purple-500/20 dark:focus:ring-purple-400/20 transition-all duration-200 text-gray-900 dark:text-white"
                  placeholder="Enter block height"
                />
                <button 
                  @click="updateTarget()"
                  class="px-6 py-3 rounded-xl bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white font-medium transition-all duration-200 transform hover:scale-105"
                >
                  {{ $t('block.btn_update') }}
                </button>
              </div>
            </div>
          </div>
        </Transition>
        
        <div class="mt-6 text-sm text-gray-500 dark:text-gray-400">
          {{ remainingBlocks }} {{ $t('block.remaining_blocks') }}
        </div>
      </div>
    </div>
    
    <!-- Block Details -->
    <div v-else class="space-y-6">
      <!-- Block Header Card -->
      <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-white/90 to-purple-50/90 dark:from-white/5 dark:via-white/5 dark:to-purple-900/10 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-purple-500/10 via-blue-500/10 to-pink-500/10 rounded-full blur-3xl transform translate-x-48 -translate-y-48 animate-pulse-slow"></div>
        <div class="absolute bottom-0 left-0 w-64 h-64 bg-gradient-to-tr from-blue-500/10 to-cyan-500/10 rounded-full blur-3xl transform -translate-x-32 translate-y-32"></div>
        
        <div class="relative p-6 border-b border-gray-200/50 dark:border-white/10 bg-gradient-to-r from-transparent via-purple-500/5 to-transparent">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4">
              <div class="p-3 rounded-2xl bg-gradient-to-br from-purple-500/20 to-blue-500/20 backdrop-blur-sm">
                <Icon icon="mdi:cube" class="text-3xl text-purple-600 dark:text-purple-400" />
              </div>
              <h1 class="text-3xl font-bold bg-gradient-to-r from-purple-600 via-blue-600 to-pink-600 dark:from-purple-400 dark:via-blue-400 dark:to-pink-400 bg-clip-text text-transparent animate-gradient">
                Block #{{ current.block?.header?.height }}
              </h1>
            </div>
            <div class="flex gap-2" v-if="props.height">
              <RouterLink
                :to="`/${store.blockchain.chainName}/block/${height - 1}`"
                class="group p-3 rounded-xl bg-gradient-to-br from-gray-100 to-gray-50 dark:from-white/10 dark:to-white/5 hover:from-purple-100 hover:to-blue-50 dark:hover:from-purple-900/20 dark:hover:to-blue-900/10 transition-all duration-200 border border-gray-200/50 dark:border-white/10"
              >
                <Icon icon="mdi:arrow-left" class="text-xl text-gray-600 dark:text-gray-400 group-hover:text-purple-600 dark:group-hover:text-purple-400 transition-colors" />
              </RouterLink>
              <RouterLink
                :to="`/${store.blockchain.chainName}/block/${height + 1}`"
                class="group p-3 rounded-xl bg-gradient-to-br from-gray-100 to-gray-50 dark:from-white/10 dark:to-white/5 hover:from-purple-100 hover:to-blue-50 dark:hover:from-purple-900/20 dark:hover:to-blue-900/10 transition-all duration-200 border border-gray-200/50 dark:border-white/10"
              >
                <Icon icon="mdi:arrow-right" class="text-xl text-gray-600 dark:text-gray-400 group-hover:text-purple-600 dark:group-hover:text-purple-400 transition-colors" />
              </RouterLink>
            </div>
          </div>
        </div>
        <div class="relative p-6">
          <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-4 flex items-center gap-2">
            <div class="p-1.5 rounded-lg bg-gradient-to-br from-indigo-500/20 to-purple-500/20">
              <Icon icon="mdi:identifier" class="text-base text-indigo-600 dark:text-indigo-400" />
            </div>
            Block ID
          </h3>
          <DynamicComponent :value="current.block_id" />
        </div>
      </div>

      <!-- Block Header Info -->
      <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-white/90 to-blue-50/90 dark:from-white/5 dark:via-white/5 dark:to-blue-900/10 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden group hover:shadow-xl transition-all duration-300">
        <div class="absolute top-0 right-0 w-80 h-80 bg-gradient-to-br from-blue-400/10 via-cyan-400/10 to-teal-400/10 rounded-full blur-3xl transform translate-x-40 -translate-y-40 group-hover:scale-110 transition-transform duration-500"></div>
        <div class="absolute bottom-0 left-0 w-64 h-64 bg-gradient-to-tr from-indigo-400/10 to-blue-400/10 rounded-full blur-3xl transform -translate-x-32 translate-y-32"></div>
        
        <div class="relative p-6">
          <div class="flex items-center gap-3 mb-6">
            <div class="p-3 rounded-2xl bg-gradient-to-br from-blue-500/20 to-cyan-500/20 backdrop-blur-sm shadow-lg">
              <Icon icon="mdi:information-outline" class="text-2xl text-blue-600 dark:text-blue-400" />
            </div>
            <h2 class="text-xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 dark:from-blue-400 dark:to-cyan-400 bg-clip-text text-transparent">
              {{ $t('block.block_header') }}
            </h2>
          </div>
          <div class="bg-gradient-to-br from-gray-50/50 to-blue-50/30 dark:from-white/5 dark:to-blue-900/5 rounded-2xl p-4 border border-gray-200/30 dark:border-white/5">
            <DynamicComponent :value="current.block?.header" />
          </div>
        </div>
      </div>

      <!-- Transactions -->
      <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-white/90 to-emerald-50/90 dark:from-white/5 dark:via-white/5 dark:to-emerald-900/10 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden group hover:shadow-xl transition-all duration-300">
        <div class="absolute top-0 right-0 w-80 h-80 bg-gradient-to-br from-emerald-400/10 via-green-400/10 to-teal-400/10 rounded-full blur-3xl transform translate-x-40 -translate-y-40 group-hover:scale-110 transition-transform duration-500"></div>
        <div class="absolute bottom-0 left-0 w-64 h-64 bg-gradient-to-tr from-green-400/10 to-emerald-400/10 rounded-full blur-3xl transform -translate-x-32 translate-y-32"></div>
        
        <div class="relative p-6">
          <div class="flex items-center gap-3 mb-6">
            <div class="p-3 rounded-2xl bg-gradient-to-br from-emerald-500/20 to-green-500/20 backdrop-blur-sm shadow-lg">
              <Icon icon="mdi:swap-horizontal" class="text-2xl text-emerald-600 dark:text-emerald-400" />
            </div>
            <h2 class="text-xl font-bold bg-gradient-to-r from-emerald-600 to-green-600 dark:from-emerald-400 dark:to-green-400 bg-clip-text text-transparent">
              {{ $t('account.transactions') }}
            </h2>
            <div v-if="current.block?.data?.txs?.length" class="ml-auto">
              <span class="px-3 py-1 rounded-xl bg-gradient-to-r from-emerald-500/20 to-green-500/20 text-sm font-semibold text-emerald-700 dark:text-emerald-300 border border-emerald-500/30">
                {{ current.block.data.txs.length }} txs
              </span>
            </div>
          </div>
          <div class="bg-gradient-to-br from-gray-50/50 to-emerald-50/30 dark:from-white/5 dark:to-emerald-900/5 rounded-2xl p-4 border border-gray-200/30 dark:border-white/5">
            <TxsElement :value="current.block?.data?.txs" />
          </div>
        </div>
      </div>

      <!-- Last Commit -->
      <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-white/90 to-amber-50/90 dark:from-white/5 dark:via-white/5 dark:to-amber-900/10 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden group hover:shadow-xl transition-all duration-300">
        <div class="absolute top-0 right-0 w-80 h-80 bg-gradient-to-br from-amber-400/10 via-orange-400/10 to-yellow-400/10 rounded-full blur-3xl transform translate-x-40 -translate-y-40 group-hover:scale-110 transition-transform duration-500"></div>
        <div class="absolute bottom-0 left-0 w-64 h-64 bg-gradient-to-tr from-orange-400/10 to-amber-400/10 rounded-full blur-3xl transform -translate-x-32 translate-y-32"></div>
        
        <div class="relative p-6">
          <div class="flex items-center gap-3 mb-6">
            <div class="p-3 rounded-2xl bg-gradient-to-br from-amber-500/20 to-orange-500/20 backdrop-blur-sm shadow-lg">
              <Icon icon="mdi:check-decagram" class="text-2xl text-amber-600 dark:text-amber-400" />
            </div>
            <h2 class="text-xl font-bold bg-gradient-to-r from-amber-600 to-orange-600 dark:from-amber-400 dark:to-orange-400 bg-clip-text text-transparent">
              {{ $t('block.last_commit') }}
            </h2>
          </div>
          <div class="bg-gradient-to-br from-gray-50/50 to-amber-50/30 dark:from-white/5 dark:to-amber-900/5 rounded-2xl p-4 border border-gray-200/30 dark:border-white/5">
            <DynamicComponent :value="current.block?.last_commit" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Slide fade transition */
.slide-fade-enter-active,
.slide-fade-leave-active {
  transition: all 0.3s ease;
}

.slide-fade-enter-from {
  transform: translateY(-10px);
  opacity: 0;
}

.slide-fade-leave-to {
  transform: translateY(10px);
  opacity: 0;
}

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
