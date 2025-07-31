<script lang="ts" setup>
import { select } from './index';

const props = defineProps(['value']);
</script>
<template>
  <div class="overflow-auto">
    <table class="table w-full">
      <tbody>
        <tr v-for="(v, k) of value" class="border-b border-gray-100/50 dark:border-white/5 hover:bg-gray-50/50 dark:hover:bg-white/5 transition-colors">
          <td class="capitalize whitespace-nowrap py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400 min-w-[120px]">
            {{ String(k).replaceAll('_', ' ') }}
          </td>
          <td class="py-3 px-4">
            <div class="overflow-hidden w-auto whitespace-normal text-sm text-gray-900 dark:text-white">
              <Component v-if="v" :is="select(v, 'horizontal')" :value="v"></Component>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
