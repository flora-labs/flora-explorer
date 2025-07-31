<script lang="ts" setup>
import fetch from 'cross-fetch';
import { onMounted, ref, computed, onUnmounted } from 'vue';
import { useBlockchain, useFormatter, useStakingStore } from '@/stores';
import { consensusPubkeyToHexAddress } from '@/libs';

const format = useFormatter();
const chainStore = useBlockchain();
const stakingStore = useStakingStore();
const rpcList = ref(chainStore.current?.endpoints?.rpc || [{ address: '', provider: '' }]);
let rpc = ref('');
const validators = ref(stakingStore.validators);

let httpstatus = ref(200);
let httpStatusText = ref('');
let roundState = ref({} as any);
let rate = ref('');
let height = ref('');
let round = ref('');
let step = ref('');
let timer = null as any;
let updatetime = ref(new Date());
let positions = ref([]);
let validatorsData = ref([] as any);
onMounted(async () => {
  // stakingStore.init();
  validatorsData.value = await stakingStore.fetchAcitveValdiators();
  rpc.value = rpcList.value[0].address + '/consensus_state';
  await fetchPosition();
  update();
  clearTime();
  timer = setInterval(() => {
    update();
  }, 6000);
});
onUnmounted(() => {
  clearTime();
});

function clearTime() {
  clearInterval(timer);
  timer = null;
}
const newTime = computed(() => {
  return format.toDay(updatetime.value, 'time');
});

const vals = computed(() => {
  return validatorsData.value.map((x: any) => {
    const x2 = x;
    // @ts-ignore
    x2.hex = consensusPubkeyToHexAddress(x.consensus_pubkey);
    return x2;
  });
});

function showName(i: number, text: string) {
  if (text === 'nil-Vote') {
    // @ts-ignore
    if (positions.value?.[i]?.address) {
      const val = vals.value.find(
        // @ts-ignore
        (x) => x.hex === positions.value?.[i]?.address
      );
      return val?.description?.moniker || i;
    }
    return i;
  }
  // const txt = text.substring(text.indexOf(':') + 1, text.indexOf(' '));
  // const sig = text.split(' ');
  // // @ts-ignore
  // const val = validators.value.find((x) => x?.hex?.startsWith(txt));
  // return `${val?.description?.moniker || txt} - ${sig[2]}`;
}
function color(i: number, txt: string) {
  if (i === roundState.value?.proposer?.index) {
    return txt === 'nil-Vote' ? 'warning' : 'primary';
  }
  return txt === 'nil-Vote' ? 'gray-700' : 'success';
}
async function onChange() {
  httpstatus.value = 200;
  httpStatusText.value = '';
  roundState.value = {};
  clearTime();
  await fetchPosition();
  update();
  timer = setInterval(() => {
    update();
  }, 6000);
}

async function fetchPosition() {
  let dumpurl = rpc.value.replace('consensus_state', 'dump_consensus_state');
  try {
    const response = await fetch(dumpurl);
    if (!response.ok) {
      throw new Error(`HTTP error: ${response.status}`);
    }

    httpstatus.value = response.status;
    httpStatusText.value = response.statusText;

    const data = await response.json();
    positions.value = data.result.round_state.validators.validators;
  } catch (error) {
    // @ts-ignore
    httpstatus.value = error?.status || 500;
    // @ts-ignore
    httpStatusText.value = error?.message || 'Error';
  }
}

async function update() {
  rate.value = '0%';
  updatetime.value = new Date();
  if (httpstatus.value === 200) {
    fetch(rpc.value)
      .then((data) => {
        httpstatus.value = data.status;
        httpStatusText.value = data.statusText;
        return data.json();
      })
      .then((res) => {
        roundState.value = res.result.round_state;
        const raw = roundState?.value?.['height/round/step']?.split('/');
        // eslint-disable-next-line prefer-destructuring
        height.value = raw[0];
        // eslint-disable-next-line prefer-destructuring
        round.value = raw[1];
        // eslint-disable-next-line prefer-destructuring
        step.value = raw[2];

        // find the highest onboard rate
        roundState.value?.height_vote_set?.forEach((element: any) => {
          const rates = Number(element.prevotes_bit_array.substring(element.prevotes_bit_array.length - 4));
          if (rates > 0) {
            rate.value = `${(rates * 100).toFixed()}%`;
          }
        });
      })
      .catch((err) => {
        httpstatus.value = 500;
        httpStatusText.value = err;
      });
  }
}
</script>

<template>
  <div class="space-y-6">
    <!-- RPC Selector -->
    <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-purple-500/5 to-blue-500/5 rounded-full blur-2xl transform translate-x-24 -translate-y-24"></div>
      <div class="relative">
        <h2 class="text-xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent mb-4">
          Consensus Monitor
        </h2>
        <div class="flex gap-2">
          <select v-model="rpc" class="flex-1 px-4 py-3 rounded-xl bg-gray-100 dark:bg-white/5 border border-gray-200 dark:border-white/10 focus:border-purple-500 dark:focus:border-purple-400 focus:ring-2 focus:ring-purple-500/20 dark:focus:ring-purple-400/20 transition-all duration-200">
            <option v-for="(item, index) in rpcList" :key="index">{{ item?.address }}/consensus_state</option>
          </select>
          <button 
            class="px-6 py-3 rounded-xl font-semibold bg-gradient-to-r from-purple-500 to-blue-500 text-white shadow-lg hover:shadow-xl hover:from-purple-600 hover:to-blue-600 transition-all duration-300 transform hover:-translate-y-0.5 active:translate-y-0 active:shadow-md"
            @click="onChange"
          >
            {{ $t('consensus.monitor') }}
          </button>
        </div>
        <div v-if="httpstatus !== 200" class="mt-3 px-4 py-2 rounded-lg bg-red-500/10 text-red-600 dark:text-red-400 border border-red-500/20">
          {{ httpstatus }}: {{ httpStatusText }}
        </div>
      </div>
    </div>
    <!-- Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4" v-if="roundState['height/round/step']">
      <!-- Onboard Rate -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-rose-500/10 to-pink-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative flex items-center justify-between">
          <div>
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium mb-1">{{ $t('consensus.onboard_rate') }}</div>
            <div class="text-2xl font-bold bg-gradient-to-r from-rose-600 to-pink-600 dark:from-rose-400 dark:to-pink-400 bg-clip-text text-transparent">
              {{ rate }}
            </div>
          </div>
          <div class="w-12 h-12 rounded-2xl bg-gradient-to-br from-rose-500/20 to-pink-500/20 flex items-center justify-center">
            <span class="text-xl font-bold text-rose-600 dark:text-rose-400">{{ $t('consensus.o') }}</span>
          </div>
        </div>
      </div>

      <!-- Height -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-green-500/10 to-emerald-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative flex items-center justify-between">
          <div>
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium mb-1">{{ $t('account.height') }}</div>
            <div class="text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 dark:from-green-400 dark:to-emerald-400 bg-clip-text text-transparent">
              {{ height }}
            </div>
          </div>
          <div class="w-12 h-12 rounded-2xl bg-gradient-to-br from-green-500/20 to-emerald-500/20 flex items-center justify-center">
            <span class="text-xl font-bold text-green-600 dark:text-green-400">{{ $t('consensus.h') }}</span>
          </div>
        </div>
      </div>

      <!-- Round -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-purple-500/10 to-violet-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative flex items-center justify-between">
          <div>
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium mb-1">{{ $t('consensus.round') }}</div>
            <div class="text-2xl font-bold bg-gradient-to-r from-purple-600 to-violet-600 dark:from-purple-400 dark:to-violet-400 bg-clip-text text-transparent">
              {{ round }}
            </div>
          </div>
          <div class="w-12 h-12 rounded-2xl bg-gradient-to-br from-purple-500/20 to-violet-500/20 flex items-center justify-center">
            <span class="text-xl font-bold text-purple-600 dark:text-purple-400">{{ $t('consensus.r') }}</span>
          </div>
        </div>
      </div>

      <!-- Step -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-blue-500/10 to-cyan-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative flex items-center justify-between">
          <div>
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium mb-1">{{ $t('consensus.step') }}</div>
            <div class="text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 dark:from-blue-400 dark:to-cyan-400 bg-clip-text text-transparent">
              {{ step }}
            </div>
          </div>
          <div class="w-12 h-12 rounded-2xl bg-gradient-to-br from-blue-500/20 to-cyan-500/20 flex items-center justify-center">
            <span class="text-xl font-bold text-blue-600 dark:text-blue-400">{{ $t('consensus.s') }}</span>
          </div>
        </div>
      </div>
    </div>
    <!-- Voting Visualization -->
    <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6" v-if="roundState['height/round/step']">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-indigo-500/5 to-purple-500/5 rounded-full blur-2xl transform translate-x-32 -translate-y-32"></div>
      <div class="relative">
        <div class="flex items-center justify-between mb-6">
          <h3 class="text-xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 dark:from-indigo-400 dark:to-purple-400 bg-clip-text text-transparent">
            Validator Votes
          </h3>
          <div class="text-sm text-gray-600 dark:text-gray-400">
            {{ $t('consensus.updated_at') }} <span class="font-medium text-gray-900 dark:text-white">{{ newTime || '' }}</span>
          </div>
        </div>
        
        <div v-for="item in roundState.height_vote_set" :key="item.round" class="mb-6">
          <div class="mb-3">
            <div class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              {{ $t('consensus.round') }} {{ item.round }}
            </div>
            <div class="text-xs font-mono text-gray-500 dark:text-gray-400 break-all bg-gray-100 dark:bg-black/20 rounded-lg p-2">
              {{ item.prevotes_bit_array }}
            </div>
          </div>

          <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-2">
            <div
              v-for="(pre, i) in item.prevotes"
              :key="i"
              class="bg-gradient-to-r from-gray-100 to-gray-50 dark:from-white/5 dark:to-white/10 rounded-xl p-3 border border-gray-200 dark:border-white/10 hover:shadow-md transition-all duration-200"
            >
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm font-medium text-gray-900 dark:text-white truncate flex-1">
                  {{ showName(i, 'nil-Vote') }}
                </span>
              </div>
              <div class="flex gap-1">
                <div class="relative group">
                  <div
                    class="w-12 h-2 rounded-full transition-all duration-200"
                    :class="{
                      'bg-gradient-to-r from-green-500 to-emerald-500': String(pre).toLowerCase() !== 'nil-vote',
                      'bg-gradient-to-r from-red-500 to-pink-500': String(pre).toLowerCase() === 'nil-vote',
                    }"
                  ></div>
                  <div class="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-2 py-1 bg-gray-900 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none whitespace-nowrap">
                    Prevote: {{ pre }}
                  </div>
                </div>
                <div class="relative group">
                  <div
                    class="w-12 h-2 rounded-full transition-all duration-200"
                    :class="{
                      'bg-gradient-to-r from-green-500 to-emerald-500': String(item.precommits[i]).toLowerCase() !== 'nil-vote',
                      'bg-gradient-to-r from-red-500 to-pink-500': String(item.precommits[i]).toLowerCase() === 'nil-vote',
                    }"
                  ></div>
                  <div class="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-2 py-1 bg-gray-900 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none whitespace-nowrap">
                    Precommit: {{ item.precommits[i] }}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Tips Section -->
    <div class="backdrop-blur-xl bg-gradient-to-r from-blue-500/10 to-cyan-500/10 rounded-3xl border border-blue-500/20 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-blue-500/10 to-cyan-500/10 rounded-full blur-2xl transform translate-x-24 -translate-y-24"></div>
      <div class="relative">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500/20 to-cyan-500/20 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-blue-600 dark:text-blue-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h3 class="text-lg font-bold text-blue-600 dark:text-blue-400">{{ $t('consensus.tips') }}</h3>
        </div>
        <ul class="space-y-2 text-sm text-gray-700 dark:text-gray-300">
          <li class="flex items-start gap-2">
            <span class="text-blue-600 dark:text-blue-400 mt-1">•</span>
            <span>{{ $t('consensus.tips_description_1') }}</span>
          </li>
          <li class="flex items-start gap-2">
            <span class="text-blue-600 dark:text-blue-400 mt-1">•</span>
            <span>{{ $t('consensus.tips_description_2') }}</span>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<route>
  {
    meta: {
      i18n: 'consensus',
    }
  }
</route>
