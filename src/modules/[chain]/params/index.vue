<script lang="ts" setup>
import { useParamStore } from '@/stores';
import { ref, onMounted } from 'vue';
import CardParameter from '@/components/CardParameter.vue';
import ArrayObjectElement from '@/components/dynamic/ArrayObjectElement.vue';
const store = useParamStore();
const chain = ref(store.chain);
onMounted(() => {
  // fetch the data
  store.initial();
});
</script>
<template>
  <div class="space-y-6">
    <!-- Chain Parameters Header -->
    <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-purple-500/5 to-blue-500/5 rounded-full blur-2xl transform translate-x-32 -translate-y-32"></div>
      <div class="relative">
        <h2 class="text-2xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent mb-6">
          {{ chain.title }}
        </h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 2xl:grid-cols-6 gap-4">
          <div v-for="(item, index) of chain.items" :key="index" 
            class="bg-gradient-to-br from-purple-500/10 to-blue-500/10 rounded-2xl p-4 border border-purple-500/20 hover:border-purple-500/30 transition-all duration-200 hover:shadow-lg hover:shadow-purple-500/10"
          >
            <div class="text-xs font-medium text-gray-600 dark:text-gray-400 mb-2 uppercase tracking-wider">{{ item.subtitle }}</div>
            <div class="text-lg font-semibold text-gray-900 dark:text-white">{{ item.value }}</div>
          </div>
        </div>
      </div>
    </div>
    <!-- minting Parameters  -->
    <CardParameter :cardItem="store.mint" />
    <!-- Staking Parameters  -->
    <CardParameter :cardItem="store.staking" />
    <!-- Governance Parameters -->
    <CardParameter :cardItem="store.gov" />
    <!-- Distribution Parameters -->
    <CardParameter :cardItem="store.distribution" />
    <!-- Slashing Parameters -->
    <CardParameter :cardItem="store.slashing" />
    <!-- Application Version -->
    <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-green-500/5 to-emerald-500/5 rounded-full blur-2xl transform translate-x-24 -translate-y-24"></div>
      <div class="relative">
        <h3 class="text-xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 dark:from-green-400 dark:to-emerald-400 bg-clip-text text-transparent mb-4">
          {{ store.appVersion?.title }}
        </h3>
        <div class="bg-black/5 dark:bg-black/20 rounded-2xl p-4">
          <ArrayObjectElement :value="store.appVersion?.items" :thead="false" />
        </div>
      </div>
    </div>

    <!-- Node Information -->
    <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-blue-500/5 to-cyan-500/5 rounded-full blur-2xl transform translate-x-24 -translate-y-24"></div>
      <div class="relative">
        <h3 class="text-xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 dark:from-blue-400 dark:to-cyan-400 bg-clip-text text-transparent mb-4">
          {{ store.nodeVersion?.title }}
        </h3>
        <div class="bg-black/5 dark:bg-black/20 rounded-2xl p-4">
          <ArrayObjectElement :value="store.nodeVersion?.items" :thead="false" />
        </div>
      </div>
    </div>
  </div>
</template>

<route>
{
  meta: {
    i18n: 'parameters',
    order: 50
  }
}
</route>
