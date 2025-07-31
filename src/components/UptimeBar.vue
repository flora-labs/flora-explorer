<script lang="ts" setup>
import type { PropType } from 'vue';

const props = defineProps({
  blocks: { type: Array as PropType<{ height: string; color: string }[]> },
});
</script>
<template>
  <div class="flex gap-[1px] items-center justify-center">
    <div 
      v-for="(item, index) in blocks" 
      :key="index"
      class="group relative cursor-pointer transition-all duration-200 hover:scale-y-125"
    >
      <div 
        class="rounded-sm transition-all duration-200"
        :class="[
          item.color === 'bg-green-500' ? 'bg-green-500 hover:bg-green-400' :
          item.color === 'bg-yellow-500' ? 'bg-yellow-500 hover:bg-yellow-400' :
          item.color === 'bg-red-500' ? 'bg-red-500 hover:bg-red-400' :
          'bg-gray-400 hover:bg-gray-300'
        ]"
        style="width: 4px; height: 20px"
      >
        &nbsp;
      </div>
      <!-- Enhanced Tooltip -->
      <div class="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none z-10">
        <div class="bg-gray-900 dark:bg-gray-800 text-white text-xs rounded-lg px-2 py-1 whitespace-nowrap">
          <div class="font-mono">Block #{{ item.height }}</div>
          <div class="text-[10px] opacity-75">
            {{ item.color === 'bg-green-500' ? 'Committed' :
               item.color === 'bg-yellow-500' ? 'Precommitted' :
               item.color === 'bg-red-500' ? 'Missed' : 'Unknown' }}
          </div>
        </div>
        <div class="absolute top-full left-1/2 transform -translate-x-1/2 w-0 h-0 border-l-4 border-r-4 border-t-4 border-transparent border-t-gray-900 dark:border-t-gray-800"></div>
      </div>
    </div>
  </div>
</template>

<style></style>
