<script lang="ts" setup>
import { fromBase64, toBase64 } from '@cosmjs/encoding';
import { decodeTxRaw } from '@cosmjs/proto-signing';
import { computed } from '@vue/reactivity';
import { hashTx } from '@/libs';
import { useBlockchain, useFormatter } from '@/stores';
import { Icon } from '@iconify/vue';
const props = defineProps({
  value: { type: Array<string> },
});

const txs = computed(() => {
  return (
    props.value?.map((x) => {
      const tx_bytes = fromBase64(x);
      let tx = null;
      let injected = 'Standard';
      try {
        tx = decodeTxRaw(fromBase64(x));
      } catch (e) {
        injected = 'Injected';
      }
      return {
        hash: hashTx(tx_bytes),
        tx,
        injected,
      };
    }) || []
  );
});

const format = useFormatter();
const chain = useBlockchain();
</script>
<template>
  <div class="overflow-x-auto mt-4">
    <table class="table w-full" density="compact" v-if="txs.length > 0">
      <thead>
        <tr>
          <th>Type</th>
          <th style="position: relative; z-index: 2">Hash</th>
          <th>Msgs</th>
          <th>Memo</th>
        </tr>
      </thead>
      <tbody class="text-sm">
        <tr v-for="item in txs">
          <td>{{ item.injected }}</td>
          <td>
            <span v-if="item.injected === 'Injected'">{{ item.hash }}</span>
            <RouterLink v-else :to="`/${chain.chainName}/tx/${item.hash}`" class="text-primary dark:invert">{{
              item.hash
            }}</RouterLink>
          </td>
          <td>
            <span v-if="item.tx">
              {{ format.messages(item.tx.body.messages.map((x) => ({ '@type': x.typeUrl }))) }}
            </span>
          </td>
          <td>
            <span v-if="item.tx">{{ item.tx.body.memo }}</span>
          </td>
        </tr>
      </tbody>
    </table>
    <div v-else class="flex items-center justify-center min-h-[100px] text-gray-500 dark:text-gray-400">
      <div class="flex items-center gap-2">
        <Icon icon="mdi:swap-horizontal-circle-outline" class="text-xl opacity-50" />
        <p class="text-base">No Transactions</p>
      </div>
    </div>
  </div>
</template>
