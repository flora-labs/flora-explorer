<script lang="ts" setup>
import { useFormatter } from '@/stores';
import type { Tally } from '@/types';
import { computed } from '@vue/reactivity';
import type { PropType } from 'vue';

const props = defineProps({
  tally: { type: Object as PropType<Tally> },
  pool: {
    type: Object as PropType<{
      not_bonded_tokens: string;
      bonded_tokens: string;
    }>,
  },
});
const total = computed(() => props.pool?.bonded_tokens);
const format = useFormatter();
const yes = computed(() => format.calculatePercent(props.tally?.yes, total.value));
const no = computed(() => format.calculatePercent(props.tally?.no, total.value));
const abstain = computed(() => format.calculatePercent(props.tally?.abstain, total.value));
const veto = computed(() => format.calculatePercent(props.tally?.no_with_veto, total.value));
</script>

<template>
  <div class="relative">
    <!-- Progress Bar Container -->
    <div class="relative h-8 bg-gradient-to-r from-gray-100 to-gray-50 dark:from-white/5 dark:to-white/10 rounded-full overflow-hidden border border-gray-200/50 dark:border-white/10 shadow-inner">
      <!-- Yes Vote -->
      <div 
        class="absolute inset-y-0 left-0 bg-gradient-to-r from-emerald-500 to-green-500 flex items-center justify-center text-white text-xs font-semibold transition-all duration-500 ease-out hover:brightness-110"
        :style="`width: ${yes}`" 
        :title="`Yes: ${yes}`"
      >
        <span v-if="parseFloat(yes) > 10" class="drop-shadow-sm">{{ yes }}</span>
      </div>
      
      <!-- No Vote -->
      <div 
        class="absolute inset-y-0 bg-gradient-to-r from-red-500 to-pink-500 flex items-center justify-center text-white text-xs font-semibold transition-all duration-500 ease-out hover:brightness-110"
        :style="`left: ${yes}; width: ${no}`" 
        :title="`No: ${no}`"
      >
        <span v-if="parseFloat(no) > 10" class="drop-shadow-sm">{{ no }}</span>
      </div>
      
      <!-- No With Veto -->
      <div 
        class="absolute inset-y-0 bg-gradient-to-r from-red-700 to-red-900 flex items-center justify-center text-white text-xs font-semibold transition-all duration-500 ease-out hover:brightness-110"
        :style="`left: calc(${yes} + ${no}); width: ${veto}`" 
        :title="`No With Veto: ${veto}`"
      >
        <span v-if="parseFloat(veto) > 10" class="drop-shadow-sm">{{ veto }}</span>
      </div>
      
      <!-- Abstain -->
      <div 
        class="absolute inset-y-0 bg-gradient-to-r from-gray-400 to-gray-500 flex items-center justify-center text-white text-xs font-semibold transition-all duration-500 ease-out hover:brightness-110"
        :style="`left: calc(${yes} + ${no} + ${veto}); width: ${abstain}`" 
        :title="`Abstain: ${abstain}`"
      >
        <span v-if="parseFloat(abstain) > 10" class="drop-shadow-sm">{{ abstain }}</span>
      </div>
      
      <!-- Animated shimmer effect -->
      <div class="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent -skew-x-12 translate-x-[-200%] animate-shimmer"></div>
    </div>
    
    <!-- Vote Labels -->
    <div class="flex justify-between mt-2 text-xs">
      <div class="flex items-center gap-1">
        <div class="w-3 h-3 rounded-full bg-gradient-to-r from-emerald-500 to-green-500"></div>
        <span class="text-gray-600 dark:text-gray-400">Yes</span>
      </div>
      <div class="flex items-center gap-1">
        <div class="w-3 h-3 rounded-full bg-gradient-to-r from-red-500 to-pink-500"></div>
        <span class="text-gray-600 dark:text-gray-400">No</span>
      </div>
      <div class="flex items-center gap-1">
        <div class="w-3 h-3 rounded-full bg-gradient-to-r from-red-700 to-red-900"></div>
        <span class="text-gray-600 dark:text-gray-400">Veto</span>
      </div>
      <div class="flex items-center gap-1">
        <div class="w-3 h-3 rounded-full bg-gradient-to-r from-gray-400 to-gray-500"></div>
        <span class="text-gray-600 dark:text-gray-400">Abstain</span>
      </div>
    </div>
  </div>
</template>
<style scoped>
@keyframes shimmer {
  to {
    transform: translateX(200%) skewX(-12deg);
  }
}

.animate-shimmer {
  animation: shimmer 3s infinite;
}
</style>
