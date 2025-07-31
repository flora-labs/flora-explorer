<script lang="ts" setup>
import { computed } from '@vue/reactivity';
import DynamicComponent from './DynamicComponent.vue';

const props = defineProps({
  value: { type: null as any },
  thead: {
    type: Boolean,
    default: true,
  },
});

const header = computed(() => {
  if (props.value && props.value.length > 0) {
    return Object.keys(props.value[0]);
  }
  return [];
});
</script>
<template>
  <div class="overflow-x-auto max-h-96">
    <table class="table w-full">
      <thead v-if="thead">
        <tr class="border-b border-gray-200 dark:border-white/10">
          <th v-for="(item, index) in header" :key="index" class="text-left capitalize text-sm font-medium text-gray-500 dark:text-gray-400 py-3 px-4">
            {{ item.replace(/_/g, ' ') }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(item, index) in value" :key="index" class="border-b border-gray-100/50 dark:border-white/5 hover:bg-gray-50/50 dark:hover:bg-white/5 transition-colors">
          <td v-for="(el, key) in header" :key="key" class="py-3 px-4 text-sm" :class="el === 'signature' ? 'max-w-[300px]' : ''">
            <div class="truncate" :title="String(item[el])">
              <DynamicComponent :value="item[el]" />
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
