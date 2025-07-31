<script lang="ts" setup>
import { useBlockchain, useFormatter, useStakingStore, useTxDialog } from '@/stores';
import { select } from '@/components/dynamic/index';
import type { PaginatedProposals } from '@/types';
import ProposalProcess from './ProposalProcess.vue';
import type { PropType } from 'vue';
import { computed, ref } from 'vue';
import { Icon } from '@iconify/vue';
const dialog = useTxDialog();
defineProps({
  proposals: { type: Object as PropType<PaginatedProposals> },
});

const format = useFormatter();
const staking = useStakingStore();
const chain = useBlockchain();
function showType(v: string) {
  if (v) {
    return v.substring(v.lastIndexOf('.') + 1);
  }
  return v;
}

const statusMap: Record<string, string> = {
  PROPOSAL_STATUS_VOTING_PERIOD: 'VOTING',
  PROPOSAL_STATUS_PASSED: 'PASSED',
  PROPOSAL_STATUS_REJECTED: 'REJECTED',
};
const voterStatusMap: Record<string, string> = {
  VOTE_OPTION_NO_WITH_VETO: '',
  VOTE_OPTION_YES: 'success',
  VOTE_OPTION_NO: 'error',
  VOTE_OPTION_ABSTAIN: 'warning',
};

const proposalInfo = ref();

function metaItem(metadata: string | undefined): { title: string; summary: string } {
  return metadata ? JSON.parse(metadata) : {};
}
</script>
<template>
  <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-white/90 to-purple-50/90 dark:from-white/5 dark:via-white/5 dark:to-purple-900/10 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
    <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-purple-400/10 via-blue-400/10 to-pink-400/10 rounded-full blur-3xl transform translate-x-48 -translate-y-48"></div>
    <div class="absolute bottom-0 left-0 w-80 h-80 bg-gradient-to-tr from-blue-400/10 via-indigo-400/10 to-purple-400/10 rounded-full blur-3xl transform -translate-x-40 translate-y-40"></div>
    
    <div class="relative overflow-x-auto p-6">
      <table class="w-full">
        <thead>
          <tr class="border-b border-gray-200/50 dark:border-white/10">
            <th class="px-4 py-3 text-left text-sm font-semibold text-gray-700 dark:text-gray-300">ID</th>
            <th class="px-4 py-3 text-left text-sm font-semibold text-gray-700 dark:text-gray-300">Proposal</th>
            <th class="px-4 py-3 text-left text-sm font-semibold text-gray-700 dark:text-gray-300">Voting Progress</th>
            <th class="px-4 py-3 text-left text-sm font-semibold text-gray-700 dark:text-gray-300">Status</th>
            <th class="px-4 py-3 text-left text-sm font-semibold text-gray-700 dark:text-gray-300">Action</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(item, index) in proposals?.proposals" :key="index" class="border-b border-gray-200/30 dark:border-white/5 hover:bg-gradient-to-r hover:from-transparent hover:via-purple-500/5 hover:to-transparent transition-all duration-200">
            <td class="px-4 py-4">
              <span class="text-lg font-semibold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent">
                #{{ item?.proposal_id }}
              </span>
            </td>
            <td class="px-4 py-4">
              <RouterLink
                :to="`/${chain.chainName}/gov/${item?.proposal_id}`"
                class="text-base font-medium text-gray-900 dark:text-white hover:text-purple-600 dark:hover:text-purple-400 transition-colors block"
              >
                {{ item?.content?.title || item?.title || metaItem(item?.metadata)?.title }}
              </RouterLink>
              <div
                v-if="item.content"
                class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-gradient-to-r from-purple-500/20 to-blue-500/20 text-purple-700 dark:text-purple-300 border border-purple-500/30 mt-2"
              >
                <Icon icon="mdi:file-document" class="mr-1" />
                {{ showType(item.content['@type']) }}
              </div>
            </td>
            <td class="px-4 py-4">
              <div class="max-w-xs">
                <ProposalProcess :pool="staking.pool" :tally="item.final_tally_result"></ProposalProcess>
              </div>
            </td>
            <td class="px-4 py-4">
              <div
                class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium"
                :class="
                  statusMap?.[item?.status] === 'PASSED'
                    ? 'bg-gradient-to-r from-emerald-500/20 to-green-500/20 text-emerald-700 dark:text-emerald-300 border border-emerald-500/30'
                    : statusMap?.[item?.status] === 'REJECTED'
                    ? 'bg-gradient-to-r from-red-500/20 to-pink-500/20 text-red-700 dark:text-red-300 border border-red-500/30'
                    : 'bg-gradient-to-r from-blue-500/20 to-indigo-500/20 text-blue-700 dark:text-blue-300 border border-blue-500/30'
                "
              >
                <div
                  class="w-2 h-2 rounded-full mr-2"
                  :class="
                    statusMap?.[item?.status] === 'PASSED'
                      ? 'bg-emerald-500'
                      : statusMap?.[item?.status] === 'REJECTED'
                      ? 'bg-red-500'
                      : 'bg-blue-500'
                  "
                ></div>
                {{ statusMap?.[item?.status] || item?.status }}
              </div>
              <div class="text-xs text-gray-500 dark:text-gray-400 flex items-center mt-1">
                <Icon icon="mdi:clock-outline" class="mr-1" />
                {{ format.toDay(item.voting_end_time, 'from') }}
              </div>
            </td>
            <td class="px-4 py-4">
              <button
                v-if="statusMap?.[item?.status] === 'VOTING'"
                @click="dialog.open('vote', { proposal_id: item?.proposal_id })"
                class="px-4 py-2 rounded-xl bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white font-medium transition-all duration-200 transform hover:scale-105 shadow-lg hover:shadow-xl flex items-center gap-2"
              >
                <Icon icon="mdi:vote" class="text-lg" />
                Vote
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>