<script lang="ts" setup>
import { computed } from '@vue/reactivity';
import MdEditor from 'md-editor-v3';
import ObjectElement from '@/components/dynamic/ObjectElement.vue';
import { useBaseStore, useBlockchain, useFormatter, useGovStore, useStakingStore, useTxDialog } from '@/stores';
import { PageRequest, type GovProposal, type GovVote, type PaginatedProposalDeposit, type Pagination } from '@/types';
import { ref, reactive } from 'vue';
import Countdown from '@/components/Countdown.vue';
import PaginationBar from '@/components/PaginationBar.vue';
import { fromBech32, toHex } from '@cosmjs/encoding';
import { Icon } from '@iconify/vue';

const props = defineProps(['proposal_id', 'chain']);
const proposal = ref({} as GovProposal);
const format = useFormatter();
const store = useGovStore();
const dialog = useTxDialog();
const stakingStore = useStakingStore();
const chainStore = useBlockchain();

store.fetchProposal(props.proposal_id).then((res) => {
  let proposalDetail = reactive(res.proposal);
  // when status under the voting, final_tally_result are no data, should request fetchTally
  if (res.proposal?.status === 'PROPOSAL_STATUS_VOTING_PERIOD') {
    store.fetchTally(props.proposal_id).then((tallRes) => {
      proposalDetail.final_tally_result = tallRes?.tally;
    });
  }
  proposal.value = proposalDetail;
  // load origin params if the proposal is param change
  if (proposalDetail.content?.changes) {
    proposalDetail.content?.changes.forEach((item) => {
      chainStore.rpc.getParams(item.subspace, item.key).then((res) => {
        if (proposal.value.content && res.param) {
          if (proposal.value.content.current) {
            proposal.value.content.current.push(res.param);
          } else {
            proposal.value.content.current = [res.param];
          }
        }
      });
    });
  }

  const msgType = proposalDetail.content?.['@type'] || '';
  if (msgType.endsWith('MsgUpdateParams')) {
    if (msgType.indexOf('staking') > -1) {
      chainStore.rpc.getStakingParams().then((res) => {
        addCurrentParams(res);
      });
    } else if (msgType.indexOf('gov') > -1) {
      chainStore.rpc.getGovParamsVoting().then((res) => {
        addCurrentParams(res);
      });
    } else if (msgType.indexOf('distribution') > -1) {
      chainStore.rpc.getDistributionParams().then((res) => {
        addCurrentParams(res);
      });
    } else if (msgType.indexOf('slashing') > -1) {
      chainStore.rpc.getSlashingParams().then((res) => {
        addCurrentParams(res);
      });
    }
  }
});

function addCurrentParams(res: any) {
  if (proposal.value.content && res.params) {
    proposal.value.content.params = [proposal.value.content?.params];
    proposal.value.content.current = [res.params];
  }
}
const color = computed(() => {
  if (proposal.value.status === 'PROPOSAL_STATUS_PASSED') {
    return 'success';
  } else if (proposal.value.status === 'PROPOSAL_STATUS_REJECTED') {
    return 'error';
  }
  return '';
});
const status = computed(() => {
  if (proposal.value.status) {
    return proposal.value.status.replace('PROPOSAL_STATUS_', '');
  }
  return '';
});

const deposit = ref({} as PaginatedProposalDeposit);
store.fetchProposalDeposits(props.proposal_id).then((x) => (deposit.value = x));

const votes = ref({} as GovVote[]);
const pageRequest = ref(new PageRequest());
const pageResponse = ref({} as Pagination);

store.fetchProposalVotes(props.proposal_id).then((x) => {
  votes.value = x.votes;
  pageResponse.value = x.pagination;
});

function shortTime(v: string) {
  if (v) {
    return format.toDay(v, 'from');
  }
  return '';
}

const votingCountdown = computed((): number => {
  const now = new Date();
  const end = new Date(proposal.value.voting_end_time);
  return end.getTime() - now.getTime();
});

const upgradeCountdown = computed((): number => {
  const height = Number(proposal.value.content?.plan?.height || 0);
  if (height > 0) {
    const base = useBaseStore();
    const current = Number(base.latest?.block?.header?.height || 0);
    return (
      (height - current) * Number((base.blocktime / 1000).toFixed()) * 1000
    );
  }
  const now = new Date();
  const end = new Date(proposal.value.content?.plan?.time || '');
  return end.getTime() - now.getTime();
});

const total = computed(() => {
  const tally = proposal.value.final_tally_result;
  let sum = 0;
  if (tally) {
    sum += Number(tally.abstain || 0);
    sum += Number(tally.yes || 0);
    sum += Number(tally.no || 0);
    sum += Number(tally.no_with_veto || 0);
  }
  return sum;
});

const turnout = computed(() => {
  if (total.value > 0) {
    const bonded = stakingStore.pool?.bonded_tokens || '1';
    return format.percent(total.value / Number(bonded));
  }
  return 0;
});

const yes = computed(() => {
  if (total.value > 0) {
    const yes = proposal.value?.final_tally_result?.yes || 0;
    return format.percent(Number(yes) / total.value);
  }
  return 0;
});

const no = computed(() => {
  if (total.value > 0) {
    const value = proposal.value?.final_tally_result?.no || 0;
    return format.percent(Number(value) / total.value);
  }
  return 0;
});

const veto = computed(() => {
  if (total.value > 0) {
    const value = proposal.value?.final_tally_result?.no_with_veto || 0;
    return format.percent(Number(value) / total.value);
  }
  return 0;
});

const abstain = computed(() => {
  if (total.value > 0) {
    const value = proposal.value?.final_tally_result?.abstain || 0;
    return format.percent(Number(value) / total.value);
  }
  return 0;
});
const processList = computed(() => {
  return [
    { name: 'Turnout', value: turnout.value, class: 'bg-info' },
    { name: 'Yes', value: yes.value, class: 'bg-success' },
    { name: 'No', value: no.value, class: 'bg-error' },
    { name: 'No With Veto', value: veto.value, class: 'bg-red-800' },
    { name: 'Abstain', value: abstain.value, class: 'bg-warning' },
  ];
});

function showValidatorName(voter: string) {
  try {
    const { data } = fromBech32(voter);
    const hex = toHex(data);
    const v = stakingStore.validators.find((x) => toHex(fromBech32(x.operator_address).data) === hex);
    return v ? v.description.moniker : voter;
  } catch (e) {
    return voter;
  }
}

function pageload(p: number) {
  pageRequest.value.setPage(p);
  store.fetchProposalVotes(props.proposal_id, pageRequest.value).then((x) => {
    votes.value = x.votes;
    pageResponse.value = x.pagination;
  });
}

function metaItem(metadata: string | undefined): { title: string; summary: string } {
  if (!metadata) {
    return { title: '', summary: '' };
  } else if (metadata.startsWith('{') && metadata.endsWith('}')) {
    return JSON.parse(metadata);
  }
  return { title: metadata, summary: '' };
}
</script>

<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-6">
    <!-- Proposal Header Card -->
    <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-purple-50/90 to-blue-50/90 dark:from-white/5 dark:via-purple-900/10 dark:to-blue-900/10 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-purple-400/20 via-blue-400/15 to-pink-400/20 rounded-full blur-3xl transform translate-x-48 -translate-y-48 animate-pulse-slow"></div>
      <div class="absolute bottom-0 left-0 w-80 h-80 bg-gradient-to-tr from-blue-400/20 via-indigo-400/15 to-purple-400/20 rounded-full blur-3xl transform -translate-x-40 translate-y-40 animate-pulse-slow" style="animation-delay: 2s"></div>
      
      <div class="relative p-8">
        <div class="flex items-start justify-between gap-4 mb-6">
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-4 mb-4">
              <div class="p-4 rounded-2xl bg-gradient-to-br from-purple-500/20 to-blue-500/20 backdrop-blur-sm">
                <Icon icon="mdi:gavel" class="text-3xl text-purple-600 dark:text-purple-400" />
              </div>
              <h1 class="text-3xl font-bold bg-gradient-to-r from-purple-600 via-blue-600 to-pink-600 dark:from-purple-400 dark:via-blue-400 dark:to-pink-400 bg-clip-text text-transparent animate-gradient">
                Proposal #{{ proposal_id }}
              </h1>
            </div>
            <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              {{ proposal.title || proposal.content?.title || metaItem(proposal?.metadata)?.title }}
            </h2>
          </div>
          <div
            class="inline-flex items-center px-4 py-2 rounded-full text-sm font-medium shadow-lg"
            :class="
              color === 'success'
                ? 'bg-gradient-to-r from-emerald-500/20 to-green-500/20 text-emerald-700 dark:text-emerald-300 border border-emerald-500/30'
                : color === 'error'
                ? 'bg-gradient-to-r from-red-500/20 to-pink-500/20 text-red-700 dark:text-red-300 border border-red-500/30'
                : 'bg-gradient-to-r from-blue-500/20 to-indigo-500/20 text-blue-700 dark:text-blue-300 border border-blue-500/30'
            "
          >
            <div
              class="w-2 h-2 rounded-full mr-2"
              :class="
                color === 'success'
                  ? 'bg-emerald-500'
                  : color === 'error'
                  ? 'bg-red-500'
                  : 'bg-blue-500'
              "
            ></div>
            {{ status }}
          </div>
        </div>
        
        <!-- Proposal Content -->
        <div class="bg-gradient-to-br from-white/50 to-purple-50/30 dark:from-white/5 dark:to-purple-900/5 rounded-2xl p-6 border border-gray-200/30 dark:border-white/5">
          <ObjectElement :value="proposal.content" />
        </div>
        
        <!-- Summary/Description -->
        <div v-if="(proposal.summary && !proposal.content?.description) || metaItem(proposal?.metadata)?.summary" class="mt-6">
          <div class="bg-gradient-to-br from-white/50 to-blue-50/30 dark:from-white/5 dark:to-blue-900/5 rounded-2xl p-6 border border-gray-200/30 dark:border-white/5">
            <MdEditor
              :model-value="format.multiLine(proposal.summary || metaItem(proposal?.metadata)?.summary)"
              previewOnly
              class="md-editor-recover"
            />
          </div>
        </div>
      </div>
    </div>
    <!-- Tally and Timeline Grid -->
    <div class="grid lg:grid-cols-3 gap-6">
      <!-- Tally Section -->
      <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-white/90 to-indigo-50/90 dark:from-white/5 dark:via-white/5 dark:to-indigo-900/10 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-indigo-400/10 via-purple-400/10 to-blue-400/10 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
        
        <div class="relative p-6">
          <div class="flex items-center gap-3 mb-6">
            <div class="p-3 rounded-2xl bg-gradient-to-br from-indigo-500/20 to-purple-500/20 backdrop-blur-sm">
              <Icon icon="mdi:chart-donut" class="text-2xl text-indigo-600 dark:text-indigo-400" />
            </div>
            <h2 class="text-xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 dark:from-indigo-400 dark:to-purple-400 bg-clip-text text-transparent">
              {{ $t('gov.tally') }}
            </h2>
          </div>
          
          <div class="space-y-4">
            <div v-for="(item, index) of processList" :key="index">
              <div class="flex justify-between items-center mb-2">
                <label class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ item.name }}</label>
                <span class="text-sm font-semibold text-gray-900 dark:text-white">{{ item.value }}</span>
              </div>
              <div class="h-3 bg-gradient-to-r from-gray-100 to-gray-50 dark:from-white/5 dark:to-white/10 rounded-full overflow-hidden">
                <div
                  class="h-full transition-all duration-500 ease-out rounded-full"
                  :class="
                    item.name === 'Turnout' ? 'bg-gradient-to-r from-blue-500 to-indigo-500' :
                    item.name === 'Yes' ? 'bg-gradient-to-r from-emerald-500 to-green-500' :
                    item.name === 'No' ? 'bg-gradient-to-r from-red-500 to-pink-500' :
                    item.name === 'No With Veto' ? 'bg-gradient-to-r from-red-700 to-red-900' :
                    'bg-gradient-to-r from-gray-400 to-gray-500'
                  "
                  :style="`width: ${item.value === '-' || item.value === 'NaN%' ? '0%' : item.value}`"
                ></div>
              </div>
            </div>
          </div>
          
          <div class="mt-6 grid grid-cols-2 gap-3">
            <button
              @click="dialog.open('vote', { proposal_id })"
              class="px-4 py-3 rounded-xl bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white font-medium transition-all duration-200 transform hover:scale-105 shadow-lg hover:shadow-xl"
            >
              <Icon icon="mdi:vote" class="inline-block mr-2" />
              {{ $t('gov.btn_vote') }}
            </button>
            <button
              @click="dialog.open('deposit', { proposal_id })"
              class="px-4 py-3 rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 text-white font-medium transition-all duration-200 transform hover:scale-105 shadow-lg hover:shadow-xl"
            >
              <Icon icon="mdi:cash-plus" class="inline-block mr-2" />
              {{ $t('gov.btn_deposit') }}
            </button>
          </div>
        </div>
      </div>

      <!-- Timeline Section -->
      <div class="lg:col-span-2 backdrop-blur-xl bg-gradient-to-br from-white/95 via-white/90 to-emerald-50/90 dark:from-white/5 dark:via-white/5 dark:to-emerald-900/10 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-80 h-80 bg-gradient-to-br from-emerald-400/10 via-green-400/10 to-teal-400/10 rounded-full blur-3xl transform translate-x-40 -translate-y-40"></div>
        <div class="absolute bottom-0 left-0 w-64 h-64 bg-gradient-to-tr from-green-400/10 to-emerald-400/10 rounded-full blur-3xl transform -translate-x-32 translate-y-32"></div>
        
        <div class="relative p-6">
          <div class="flex items-center gap-3 mb-6">
            <div class="p-3 rounded-2xl bg-gradient-to-br from-emerald-500/20 to-green-500/20 backdrop-blur-sm">
              <Icon icon="mdi:timeline-clock" class="text-2xl text-emerald-600 dark:text-emerald-400" />
            </div>
            <h2 class="text-xl font-bold bg-gradient-to-r from-emerald-600 to-green-600 dark:from-emerald-400 dark:to-green-400 bg-clip-text text-transparent">
              {{ $t('gov.timeline') }}
            </h2>
          </div>
          
          <div class="space-y-4">
            <!-- Submit Time -->
            <div class="flex items-center p-4 rounded-2xl bg-gradient-to-br from-white/50 to-red-50/30 dark:from-white/5 dark:to-red-900/5 border border-gray-200/30 dark:border-white/5 hover:from-white/70 hover:to-red-50/50 dark:hover:from-white/10 dark:hover:to-red-900/10 transition-all duration-200">
              <div class="p-2 rounded-xl bg-gradient-to-br from-red-500/20 to-pink-500/20 mr-4">
                <Icon icon="mdi:file-document-plus" class="text-xl text-red-600 dark:text-red-400" />
              </div>
              <div class="flex-1">
                <p class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ $t('gov.submit_at') }}</p>
                <p class="text-base font-semibold text-gray-900 dark:text-white">{{ format.toDay(proposal.submit_time) }}</p>
              </div>
              <p class="text-sm text-gray-500 dark:text-gray-400">{{ shortTime(proposal.submit_time) }}</p>
            </div>
            
            <!-- Deposit Time -->
            <div class="flex items-center p-4 rounded-2xl bg-gradient-to-br from-white/50 to-blue-50/30 dark:from-white/5 dark:to-blue-900/5 border border-gray-200/30 dark:border-white/5 hover:from-white/70 hover:to-blue-50/50 dark:hover:from-white/10 dark:hover:to-blue-900/10 transition-all duration-200">
              <div class="p-2 rounded-xl bg-gradient-to-br from-blue-500/20 to-indigo-500/20 mr-4">
                <Icon icon="mdi:cash-check" class="text-xl text-blue-600 dark:text-blue-400" />
              </div>
              <div class="flex-1">
                <p class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ $t('gov.deposited_at') }}</p>
                <p class="text-base font-semibold text-gray-900 dark:text-white">
                  {{ format.toDay(proposal.status === 'PROPOSAL_STATUS_DEPOSIT_PERIOD' ? proposal.deposit_end_time : proposal.voting_start_time) }}
                </p>
              </div>
              <p class="text-sm text-gray-500 dark:text-gray-400">
                {{ shortTime(proposal.status === 'PROPOSAL_STATUS_DEPOSIT_PERIOD' ? proposal.deposit_end_time : proposal.voting_start_time) }}
              </p>
            </div>
            
            <!-- Voting Start -->
            <div class="flex items-center p-4 rounded-2xl bg-gradient-to-br from-white/50 to-purple-50/30 dark:from-white/5 dark:to-purple-900/5 border border-gray-200/30 dark:border-white/5 hover:from-white/70 hover:to-purple-50/50 dark:hover:from-white/10 dark:hover:to-purple-900/10 transition-all duration-200">
              <div class="p-2 rounded-xl bg-gradient-to-br from-purple-500/20 to-indigo-500/20 mr-4">
                <Icon icon="mdi:vote" class="text-xl text-purple-600 dark:text-purple-400" />
              </div>
              <div class="flex-1">
                <p class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ $t('gov.vote_start_from') }}</p>
                <p class="text-base font-semibold text-gray-900 dark:text-white">{{ format.toDay(proposal.voting_start_time) }}</p>
                <div class="mt-1">
                  <Countdown :time="votingCountdown" />
                </div>
              </div>
              <p class="text-sm text-gray-500 dark:text-gray-400">{{ shortTime(proposal.voting_start_time) }}</p>
            </div>
            
            <!-- Voting End -->
            <div class="flex items-center p-4 rounded-2xl bg-gradient-to-br from-white/50 to-emerald-50/30 dark:from-white/5 dark:to-emerald-900/5 border border-gray-200/30 dark:border-white/5 hover:from-white/70 hover:to-emerald-50/50 dark:hover:from-white/10 dark:hover:to-emerald-900/10 transition-all duration-200">
              <div class="p-2 rounded-xl bg-gradient-to-br from-emerald-500/20 to-green-500/20 mr-4">
                <Icon icon="mdi:check-circle" class="text-xl text-emerald-600 dark:text-emerald-400" />
              </div>
              <div class="flex-1">
                <p class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ $t('gov.vote_end') }}</p>
                <p class="text-base font-semibold text-gray-900 dark:text-white">{{ format.toDay(proposal.voting_end_time) }}</p>
                <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                  {{ $t('gov.current_status') }}: 
                  <span class="font-medium">{{ $t(`gov.proposal_statuses.${proposal.status}`) }}</span>
                </p>
              </div>
              <p class="text-sm text-gray-500 dark:text-gray-400">{{ shortTime(proposal.voting_end_time) }}</p>
            </div>
            
            <!-- Upgrade Plan (if applicable) -->
            <div v-if="proposal?.content?.['@type']?.endsWith('SoftwareUpgradeProposal')" class="flex items-center p-4 rounded-2xl bg-gradient-to-br from-white/50 to-amber-50/30 dark:from-white/5 dark:to-amber-900/5 border border-gray-200/30 dark:border-white/5 hover:from-white/70 hover:to-amber-50/50 dark:hover:from-white/10 dark:hover:to-amber-900/10 transition-all duration-200">
              <div class="p-2 rounded-xl bg-gradient-to-br from-amber-500/20 to-orange-500/20 mr-4">
                <Icon icon="mdi:rocket-launch" class="text-xl text-amber-600 dark:text-amber-400" />
              </div>
              <div class="flex-1">
                <p class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ $t('gov.upgrade_plan') }}</p>
                <p class="text-base font-semibold text-gray-900 dark:text-white">
                  <span v-if="Number(proposal.content?.plan?.height || '0') > 0">(EST)</span>
                  <span v-else>{{ format.toDay(proposal.content?.plan?.time) }}</span>
                </p>
                <div class="mt-1">
                  <Countdown :time="upgradeCountdown" />
                </div>
              </div>
              <p class="text-sm text-gray-500 dark:text-gray-400">{{ shortTime(proposal.voting_end_time) }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Votes Section -->
    <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-white/90 to-amber-50/90 dark:from-white/5 dark:via-white/5 dark:to-amber-900/10 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-80 h-80 bg-gradient-to-br from-amber-400/10 via-orange-400/10 to-yellow-400/10 rounded-full blur-3xl transform translate-x-40 -translate-y-40"></div>
      <div class="absolute bottom-0 left-0 w-64 h-64 bg-gradient-to-tr from-orange-400/10 to-amber-400/10 rounded-full blur-3xl transform -translate-x-32 translate-y-32"></div>
      
      <div class="relative p-6">
        <div class="flex items-center gap-3 mb-6">
          <div class="p-3 rounded-2xl bg-gradient-to-br from-amber-500/20 to-orange-500/20 backdrop-blur-sm">
            <Icon icon="mdi:account-check" class="text-2xl text-amber-600 dark:text-amber-400" />
          </div>
          <h2 class="text-xl font-bold bg-gradient-to-r from-amber-600 to-orange-600 dark:from-amber-400 dark:to-orange-400 bg-clip-text text-transparent">
            {{ $t('gov.votes') }}
          </h2>
        </div>
        
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="border-b border-gray-200/50 dark:border-white/10">
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-700 dark:text-gray-300">Validator</th>
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-700 dark:text-gray-300">Vote</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, index) of votes" :key="index" class="border-b border-gray-200/30 dark:border-white/5 hover:bg-gradient-to-r hover:from-transparent hover:via-amber-500/5 hover:to-transparent transition-all duration-200">
                <td class="px-4 py-3">
                  <p class="font-medium text-gray-900 dark:text-white">{{ showValidatorName(item.voter) }}</p>
                </td>
                <td v-if="item.option && item.option !== 'VOTE_OPTION_UNSPECIFIED'" class="px-4 py-3">
                  <div
                    class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium"
                    :class="
                      item.option === 'VOTE_OPTION_YES'
                        ? 'bg-gradient-to-r from-emerald-500/20 to-green-500/20 text-emerald-700 dark:text-emerald-300 border border-emerald-500/30'
                        : item.option === 'VOTE_OPTION_NO'
                        ? 'bg-gradient-to-r from-red-500/20 to-pink-500/20 text-red-700 dark:text-red-300 border border-red-500/30'
                        : item.option === 'VOTE_OPTION_NO_WITH_VETO'
                        ? 'bg-gradient-to-r from-red-700/20 to-red-900/20 text-red-800 dark:text-red-300 border border-red-700/30'
                        : 'bg-gradient-to-r from-gray-500/20 to-gray-600/20 text-gray-700 dark:text-gray-300 border border-gray-500/30'
                    "
                  >
                    <div
                      class="w-2 h-2 rounded-full mr-2"
                      :class="
                        item.option === 'VOTE_OPTION_YES'
                          ? 'bg-emerald-500'
                          : item.option === 'VOTE_OPTION_NO'
                          ? 'bg-red-500'
                          : item.option === 'VOTE_OPTION_NO_WITH_VETO'
                          ? 'bg-red-800'
                          : 'bg-gray-500'
                      "
                    ></div>
                    {{ String(item.option).replace('VOTE_OPTION_', '') }}
                  </div>
                </td>
                <td v-if="item.options" class="px-4 py-3">
                  <div class="flex flex-wrap gap-2">
                    <span
                      v-for="(opt, idx) in item.options"
                      :key="idx"
                      class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gradient-to-r from-gray-500/20 to-gray-600/20 text-gray-700 dark:text-gray-300 border border-gray-500/30"
                    >
                      {{ opt.option.replace('VOTE_OPTION_', '') }}: {{ format.percent(opt.weight) }}
                    </span>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        
        <div class="mt-4">
          <PaginationBar :limit="pageRequest.limit" :total="pageResponse.total" :callback="pageload" />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
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
