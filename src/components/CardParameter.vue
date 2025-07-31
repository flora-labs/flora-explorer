<script lang="ts" setup>
import type { PropType } from 'vue';
import { useFormatter } from '@/stores';
import { formatSeconds } from '@/libs/utils';
const props = defineProps({
  cardItem: {
    type: Object as PropType<{ title: string; items: Array<any> }>,
  },
});

const formatter = useFormatter();
function calculateValue(value: any) {
  if (Array.isArray(value)) {
    return (value[0] && value[0].amount) || '-';
  }
  if (String(value).search(/^\d+s$/g) > -1) {
    return formatSeconds(value);
  }
  const newValue = Number(value);
  if (`${newValue}` === 'NaN' || typeof value === 'boolean') {
    return value;
  }

  if (newValue < 1 && newValue > 0) {
    return formatter.formatDecimalToPercent(value);
  }
  return newValue;
}

function formatTitle(v: string) {
  if (!v) return '';
  return v.replace(/_/g, ' ');
}
</script>
<template>
  <div
    class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6"
    v-if="props.cardItem?.items && props.cardItem?.items?.length > 0"
  >
    <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-purple-500/5 to-pink-500/5 rounded-full blur-2xl transform translate-x-24 -translate-y-24"></div>
    <div class="relative">
      <h3 class="text-xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 dark:from-purple-400 dark:to-pink-400 bg-clip-text text-transparent mb-6">
        {{ props.cardItem?.title }}
      </h3>
      <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 2xl:grid-cols-6 gap-4">
        <div v-for="(item, index) of props.cardItem?.items" :key="index" 
          class="group bg-gradient-to-br from-purple-500/5 to-pink-500/5 hover:from-purple-500/10 hover:to-pink-500/10 rounded-2xl p-4 border border-purple-500/10 hover:border-purple-500/20 transition-all duration-200 hover:shadow-lg hover:shadow-purple-500/10 hover:-translate-y-0.5"
        >
          <div class="text-xs font-medium text-gray-600 dark:text-gray-400 mb-2 uppercase tracking-wider capitalize">
            {{ formatTitle(item?.subtitle) }}
          </div>
          <div class="text-lg font-semibold text-gray-900 dark:text-white group-hover:text-purple-600 dark:group-hover:text-purple-400 transition-colors duration-200">
            {{ calculateValue(item?.value) }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
