<script lang="ts" setup>
import { ref, onMounted, computed, onUnmounted } from 'vue';
import { fromHex, toBase64, fromBase64, toHex } from '@cosmjs/encoding';
import { useStakingStore, useBaseStore, useBlockchain, useFormatter } from '@/stores';
import UptimeBar from '@/components/UptimeBar.vue';
import type { SlashingParam, SigningInfo, Block } from '@/types';
import { consensusPubkeyToHexAddress, valconsToBase64 } from '@/libs';
import { Icon } from '@iconify/vue';

const props = defineProps(['chain']);

const stakingStore = useStakingStore();
const format = useFormatter();
const baseStore = useBaseStore();
const chainStore = useBlockchain();
const latest = ref(0);
const keyword = ref('');
const live = ref(true);
const slashingParam = ref({} as SlashingParam);
const signingInfo = ref({} as Record<string, SigningInfo>);
const consumerValidators = ref([] as { moniker: string; base64: string }[]);

interface BlockColor {
  height: string;
  color: string;
}
interface ValidatorUnit {
  moniker: string;
  blocks: BlockColor[];
  hex: string;
  base64: string;
  missed_blocks_counter: number | string;
  uptime: number;
  signing: SigningInfo;
}

function padding(blocks: BlockColor[] = []) {
  const raw = Array(50)
    .fill({ height: '0', color: 'bg-secondary' } as BlockColor)
    .concat(blocks);
  return raw.slice(raw.length - 50);
}

const validatorSet = computed(() => {
  if (chainStore.isConsumerChain) {
    return consumerValidators.value.map((v) => {
      const b64 = valconsToBase64(v.moniker);
      const moniker = stakingStore.validators.find(
        (x) => toBase64(fromHex(consensusPubkeyToHexAddress(x.consensus_pubkey))) === b64
      )?.description.moniker;
      return {
        moniker: moniker || v.moniker,
        base64: v.base64,
      };
    });
  }
  return stakingStore.validators.map((v) => {
    const hex = consensusPubkeyToHexAddress(v.consensus_pubkey);
    return {
      moniker: v.description.moniker,
      base64: toBase64(fromHex(hex)),
    };
  });
});

const blockColors = ref({} as Record<string, BlockColor[]>);

const grid = computed(() => {
  const validators =
    keyword.value.length === 0
      ? validatorSet.value
      : validatorSet.value.filter((v) => v.moniker.toLowerCase().includes(keyword.value.toLowerCase()));

  const window = Number(slashingParam.value.signed_blocks_window || 0);
  return validators.map((v) => {
    const signing = signingInfo.value[v.base64];
    const uptime = signing && window > 0 ? (window - Number(signing.missed_blocks_counter)) / window : undefined;
    return {
      moniker: v.moniker,
      base64: v.base64,
      blocks: padding(blockColors.value[v.base64] || []),
      uptime,
      missed_blocks_counter: signing?.missed_blocks_counter,
      signing,
    } as ValidatorUnit;
  });
});

const preload = ref(false);
baseStore.$subscribe((_, state) => {
  const newHeight = Number(state.latest?.block?.header?.height || 0);
  if (newHeight > latest.value) {
    latest.value = newHeight;
    // initialize if it's the first time
    if (!preload.value) {
      preFill();
      preload.value = true;
    }

    // reset the consumer validators
    if (newHeight > 0 && consumerValidators.value.length === 0) {
      const chain_id = state.latest.block.header.chain_id;
      Promise.resolve().then(async () => {
        await stakingStore.getConsumerValidators(chain_id).then((x) => {
          x.validators
            .sort((a, b) => Number(b.power) - Number(a.power))
            .forEach((v) => {
              const base64 = toBase64(
                fromHex(
                  consensusPubkeyToHexAddress({ '@type': '/cosmos.crypto.ed25519.PubKey', key: v.consumer_key.ed25519 })
                )
              );
              const moniker = v.provider_address;
              consumerValidators.value.push({ moniker, base64 });
            });
        });
      });
    }

    if (Number(state.latest.block.header.height) % 7 === 0) updateTotalSigningInfo();
    fillblock(state.latest);
  }
});

onMounted(() => {
  live.value = true;

  // fill the recent blocks
  baseStore.recents?.forEach((b) => {
    fillblock(b, 'start');
  });

  updateTotalSigningInfo();

  chainStore.rpc.getSlashingParams().then((x) => {
    slashingParam.value = x.params;
  });
});

function preFill() {
  if (latest.value > 50 && baseStore.recents.length >= 49) return;
  // preload 50 blocks if recent blocks are not enough
  let promise = Promise.resolve();
  for (let i = latest.value - baseStore.recents.length; i > latest.value - 50 && i > 1; i -= 1) {
    promise = promise.then(
      () =>
        new Promise((resolve) => {
          if (live.value) {
            // continue only if the page is living
            if (i > latest.value - 50)
              baseStore.fetchBlock(i).then((x) => {
                fillblock(x, 'start');
                resolve();
              });
          }
        })
    );
  }
}
function fillblock(b: Block, direction: string = 'end') {
  validatorSet.value.forEach((v) => {
    const sig = b.block.last_commit?.signatures.find((s) => s.validator_address === v.base64);
    const block = blockColors.value[v.base64] || [];
    let color = {
      height: b.block.header.height,
      color: 'bg-red-500',
    };
    if (sig) {
      color = {
        height: b.block.header.height,
        color: sig.block_id_flag === 'BLOCK_ID_FLAG_COMMIT' ? 'bg-green-500' : 'bg-yellow-500',
      };
    }
    if (direction === 'end') {
      block.push(color);
    } else {
      block.unshift(color);
    }
    if (block.length > 50) block.shift();
    blockColors.value[v.base64] = block;
  });
}

function updateTotalSigningInfo() {
  chainStore.rpc.getSlashingSigningInfos().then((x) => {
    x.info?.forEach((i) => {
      signingInfo.value[valconsToBase64(i.address)] = i;
    });
  });
}

onUnmounted(() => {
  live.value = false;
});

//const tab = ref(window.location.hash.search("block")>-1?"2":"3")
const tab = ref('2');
function changeTab(v: string) {
  tab.value = v;
}
</script>

<template>
  <div class="space-y-6">
    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      <!-- Total Validators -->
      <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-purple-500/10 to-indigo-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Total Validators</div>
            <Icon icon="mdi:shield-check" class="text-2xl text-purple-500/70 dark:text-purple-400/70" />
          </div>
          <div class="text-2xl font-bold bg-gradient-to-r from-purple-600 to-indigo-600 dark:from-purple-400 dark:to-indigo-400 bg-clip-text text-transparent">
            {{ validatorSet.length }}
          </div>
        </div>
      </div>

      <!-- Window Size -->
      <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-blue-500/10 to-cyan-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Window Size</div>
            <Icon icon="mdi:timer-outline" class="text-2xl text-blue-500/70 dark:text-blue-400/70" />
          </div>
          <div class="text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 dark:from-blue-400 dark:to-cyan-400 bg-clip-text text-transparent">
            {{ slashingParam.signed_blocks_window || 0 }}
          </div>
        </div>
      </div>

      <!-- Min Signed Per Window -->
      <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-green-500/10 to-emerald-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Min Required</div>
            <Icon icon="mdi:check-decagram" class="text-2xl text-green-500/70 dark:text-green-400/70" />
          </div>
          <div class="text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 dark:from-green-400 dark:to-emerald-400 bg-clip-text text-transparent">
            {{ format.percent(slashingParam.min_signed_per_window) }}
          </div>
        </div>
      </div>

      <!-- Latest Block -->
      <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-orange-500/10 to-red-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Latest Block</div>
            <Icon icon="mdi:cube-outline" class="text-2xl text-orange-500/70 dark:text-orange-400/70" />
          </div>
          <div class="text-2xl font-bold bg-gradient-to-r from-orange-600 to-red-600 dark:from-orange-400 dark:to-red-400 bg-clip-text text-transparent">
            #{{ latest.toLocaleString() }}
          </div>
        </div>
      </div>
    </div>

    <!-- Main Content Card -->
    <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-purple-500/5 to-blue-500/5 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
      
      <!-- Header with tabs -->
      <div class="relative p-6 border-b border-gray-200 dark:border-white/10">
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <!-- Tab Navigation -->
          <div class="flex gap-2">
            <button 
              class="px-4 py-2 rounded-xl font-medium transition-all duration-200"
              :class="tab === '2' 
                ? 'bg-gradient-to-r from-purple-500/20 to-blue-500/20 text-purple-600 dark:text-purple-400 border border-purple-500/30' 
                : 'bg-gray-100 dark:bg-white/5 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-white/10'"
              @click="changeTab('2')"
            >
              <Icon icon="mdi:view-grid" class="inline-block mr-2" />
              {{ $t('module.blocks') }}
            </button>
            <button 
              class="px-4 py-2 rounded-xl font-medium transition-all duration-200"
              :class="tab === '3' 
                ? 'bg-gradient-to-r from-purple-500/20 to-blue-500/20 text-purple-600 dark:text-purple-400 border border-purple-500/30' 
                : 'bg-gray-100 dark:bg-white/5 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-white/10'"
              @click="changeTab('3')"
            >
              <Icon icon="mdi:chart-line" class="inline-block mr-2" />
              {{ $t('uptime.overall') }}
            </button>
            <RouterLink :to="`/${chain}/uptime/customize`">
              <button class="px-4 py-2 rounded-xl font-medium bg-gray-100 dark:bg-white/5 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-white/10 transition-all duration-200">
                <Icon icon="mdi:cog-outline" class="inline-block mr-2" />
                {{ $t('uptime.customize') }}
              </button>
            </RouterLink>
          </div>

          <!-- Search Input -->
          <div class="relative w-full sm:w-auto">
            <input
              type="text"
              v-model="keyword"
              placeholder="Search validators..."
              class="w-full sm:w-64 px-4 py-2 pl-10 rounded-xl bg-gray-100 dark:bg-white/5 border border-gray-200 dark:border-white/10 focus:border-purple-500 dark:focus:border-purple-400 focus:ring-2 focus:ring-purple-500/20 dark:focus:ring-purple-400/20 transition-all duration-200 text-sm"
            />
            <Icon icon="mdi:magnify" class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
          </div>
        </div>
      </div>

      <!-- Blocks View -->
      <div :class="tab === '2' ? '' : 'hidden'" class="p-6">
        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4 gap-4">
          <div v-for="(unit, i) in grid" :key="i" 
            class="bg-gray-50 dark:bg-white/5 rounded-2xl p-4 hover:bg-gray-100 dark:hover:bg-white/10 transition-all duration-200"
          >
            <div class="flex justify-between items-center mb-3">
              <div class="flex items-center gap-2 min-w-0">
                <span class="text-xs text-gray-500 dark:text-gray-400">{{ i + 1 }}.</span>
                <span class="font-medium text-sm text-gray-900 dark:text-white truncate">
                  {{ unit.moniker }}
                </span>
              </div>
              <div class="flex items-center gap-2">
                <div v-if="unit.uptime" 
                  class="text-xs font-medium"
                  :class="unit.uptime > 0.95 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'"
                >
                  {{ format.percent(unit.uptime) }}
                </div>
                <div
                  class="px-2 py-1 rounded-lg text-xs font-bold"
                  :class="Number(unit?.missed_blocks_counter || 0) > 10 
                    ? 'bg-red-500/10 text-red-600 dark:text-red-400' 
                    : 'bg-green-500/10 text-green-600 dark:text-green-400'"
                >
                  {{ unit?.missed_blocks_counter || 0 }}
                </div>
              </div>
            </div>
            <div class="p-2 bg-white dark:bg-black/20 rounded-xl">
              <UptimeBar :blocks="unit.blocks" />
            </div>
          </div>
        </div>
        
        <!-- Legend -->
        <div class="mt-8 flex flex-wrap items-center justify-center gap-6 text-sm">
          <div class="flex items-center gap-2">
            <div class="w-3 h-3 bg-green-500 rounded"></div>
            <span class="text-gray-600 dark:text-gray-400">{{ $t('uptime.committed') }}</span>
          </div>
          <div class="flex items-center gap-2">
            <div class="w-3 h-3 bg-yellow-500 rounded"></div>
            <span class="text-gray-600 dark:text-gray-400">{{ $t('uptime.precommitted') }}</span>
          </div>
          <div class="flex items-center gap-2">
            <div class="w-3 h-3 bg-red-500 rounded"></div>
            <span class="text-gray-600 dark:text-gray-400">{{ $t('uptime.missed') }}</span>
          </div>
        </div>
      </div>

      <!-- Overall Statistics View -->
      <div :class="tab === '3' ? '' : 'hidden'" class="p-6">
        <div class="overflow-x-auto">
          <table class="table w-full">
            <thead>
              <tr class="border-b border-gray-200 dark:border-white/10">
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4 text-left">
                  {{ $t('account.validator') }}
                </th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4 text-right">
                  {{ $t('module.uptime') }}
                </th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">
                  {{ $t('uptime.last_jailed_time') }}
                </th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4 text-right">
                  {{ $t('uptime.signed_precommits') }}
                </th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4 text-right">
                  {{ $t('uptime.start_height') }}
                </th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">
                  {{ $t('uptime.tombstoned') }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(v, i) in grid" :key="i"
                class="border-b border-gray-100 dark:border-white/5 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors duration-200"
              >
                <td class="py-4 px-4">
                  <div class="flex items-center gap-2">
                    <span class="text-xs text-gray-500 dark:text-gray-400">{{ i + 1 }}.</span>
                    <span class="font-medium text-sm text-gray-900 dark:text-white truncate max-w-xs">
                      {{ v.moniker }}
                    </span>
                  </div>
                </td>
                <td class="py-4 px-4 text-right">
                  <div class="flex items-center justify-end gap-2">
                    <span 
                      class="font-semibold text-sm"
                      :class="v.uptime && v.uptime > 0.95 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'"
                    >
                      {{ format.percent(v.uptime) }}
                    </span>
                    <div
                      class="px-2 py-0.5 rounded-md text-xs font-medium"
                      :class="Number(v?.missed_blocks_counter || 0) > 10 
                        ? 'bg-red-500/10 text-red-600 dark:text-red-400' 
                        : 'bg-green-500/10 text-green-600 dark:text-green-400'"
                    >
                      {{ v.missed_blocks_counter || 0 }} missed
                    </div>
                  </div>
                </td>
                <td class="py-4 px-4">
                  <span v-if="v.signing && !v.signing.jailed_until.startsWith('1970')"
                    class="text-sm text-orange-600 dark:text-orange-400"
                  >
                    <div class="tooltip" :data-tip="format.toDay(v.signing.jailed_until, 'long')">
                      {{ format.toDay(v.signing.jailed_until, 'from') }}
                    </div>
                  </span>
                  <span v-else class="text-sm text-gray-400">-</span>
                </td>
                <td class="py-4 px-4 text-right">
                  <div class="text-sm">
                    <div v-if="v.signing && v.signing.jailed_until.startsWith('1970')" 
                      class="text-xs text-gray-500 dark:text-gray-400"
                    >
                      {{ format.percent(Number(v.signing.index_offset) / (latest - Number(v.signing.start_height))) }}
                    </div>
                    <div class="font-mono text-gray-900 dark:text-white">
                      {{ v.signing?.index_offset || '-' }}
                    </div>
                  </div>
                </td>
                <td class="py-4 px-4 text-right">
                  <span class="text-sm font-mono text-gray-900 dark:text-white">
                    {{ v.signing?.start_height || '-' }}
                  </span>
                </td>
                <td class="py-4 px-4">
                  <span v-if="v.signing?.tombstoned" 
                    class="px-2 py-1 rounded-lg text-xs font-medium bg-red-500/10 text-red-600 dark:text-red-400"
                  >
                    Yes
                  </span>
                  <span v-else class="text-sm text-gray-400">No</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        
        <!-- Footer Info -->
        <div class="mt-6 flex items-center justify-between">
          <div class="text-sm text-gray-600 dark:text-gray-400">
            Showing {{ grid.length }} validators
          </div>
          <div class="flex items-center gap-2">
            <span class="text-sm text-gray-600 dark:text-gray-400">{{ $t('uptime.minimum_uptime') }}:</span>
            <span class="px-3 py-1 rounded-lg bg-red-500/10 text-red-600 dark:text-red-400 font-semibold text-sm">
              {{ format.percent(slashingParam.min_signed_per_window) }}
            </span>
            <span class="text-xs text-gray-500 dark:text-gray-400">
              (Window: {{ slashingParam.signed_blocks_window }} blocks)
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<route>
  {
    meta: {
      i18n: 'uptime',
      order: 8
    }
  }
</route>

