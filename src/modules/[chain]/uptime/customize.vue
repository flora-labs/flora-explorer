<script lang="ts" setup>
import { ref, onMounted, computed, watchEffect } from 'vue';
import { fromHex, toBase64 } from '@cosmjs/encoding';
import { Icon } from '@iconify/vue';
import { useFormatter, useStakingStore, useBaseStore, useBlockchain, useDashboard } from '@/stores';
import UptimeBar from '@/components/UptimeBar.vue';
import type { Block, Commit } from '@/types';
import { consensusPubkeyToHexAddress, valconsToBase64 } from '@/libs';
import type { SigningInfo } from '@/types/slashing';
import { CosmosRestClient } from '@/libs/client';

const props = defineProps(['chain']);

const stakingStore = useStakingStore();
const format = useFormatter();
const chainStore = useBlockchain();
const dashboard = useDashboard();
// storage local favorite validator ids
const local = ref(
  JSON.parse(localStorage.getItem('uptime-validators') || '{}') as Record<string, { name: string; address: string }[]>
);
const signingInfo = ref({} as Record<string, SigningInfo[]>);
const selected = ref([] as string[]);
const selectChain = ref(chainStore.chainName);
const validators = ref(stakingStore.validators);
const keyword = ref('');

function loadSigningInfo(chainName: string) {
  const chain = dashboard.chains[chainName];
  if (chain && chain.endpoints.rest) {
    const client = CosmosRestClient.newDefault(chain.endpoints.rest[0].address);
    client.getSlashingSigningInfos().then((resp) => {
      signingInfo.value[chainName] = resp.info;
    });
  }
}
if (local.value)
  Object.keys(local.value).map((chainName) => {
    loadSigningInfo(chainName);
  });

function initial() {
  const vals = local.value[selectChain.value];
  if (vals) {
    selected.value = vals.map((x) => x.address);
  }
}

const filterValidators = computed(() => {
  if (keyword.value) {
    return validators.value.filter((x) => x.description.moniker.indexOf(keyword.value) > -1);
  }
  return validators.value;
});

const list = computed(() => {
  const list = [] as any[];
  if (local.value)
    Object.keys(local.value).map((chainName) => {
      const vals = local.value[chainName];
      const info = signingInfo.value[chainName];
      if (vals && info) {
        vals.forEach((v) => {
          const sigingInfo = info.find((x) => valconsToBase64(x.address) === v.address);
          list.push({
            chainName,
            v,
            sigingInfo,
          });
        });
      }
    });
  return list;
});

function add() {
  if (!signingInfo.value[selectChain.value]) {
    loadSigningInfo(selectChain.value);
  }
  const newList = [] as { name: string; address: string }[];
  selected.value.forEach((x) => {
    const validator = validators.value.find((v) => consensusPubkeyToHexAddress(v.consensus_pubkey) === x);
    if (validator)
      newList.push({
        name: validator.description.moniker || x,
        address: x,
      });
  });
  if (!local.value) local.value = {};
  local.value[selectChain.value] = newList;

  localStorage.setItem('uptime-validators', JSON.stringify(local.value));
  selected.value = [];
}

function removeValidator(chainName: string, address: string) {
  if (local.value[chainName]) {
    local.value[chainName] = local.value[chainName].filter(v => v.address !== address);
    if (local.value[chainName].length === 0) {
      delete local.value[chainName];
    }
    localStorage.setItem('uptime-validators', JSON.stringify(local.value));
  }
}

function changeChain() {
  validators.value = [];
  const endpoint = dashboard.chains[selectChain.value].endpoints.rest?.at(0)?.address;
  if (!endpoint) return;

  const client = CosmosRestClient.newDefault(endpoint);
  client.getStakingValidators('BOND_STATUS_BONDED').then((x) => {
    validators.value = x.validators;
  });

  const vals = local.value[selectChain.value];
  if (vals) {
    selected.value = vals.map((x) => x.address);
  } else {
    selected.value = [];
  }
}

function color(v: string) {
  if (v) {
    const n = Number(v);
    if (n < 10) return ' badge-success';
    if (n > 1000) return ' badge-error';
    if (n > 0) return ' badge-warning';
  }
}
</script>

<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-6">
    <!-- Header Section -->
    <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-purple-500/10 to-blue-500/10 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
      <div class="relative">
        <div class="flex items-start justify-between">
          <div>
            <h2 class="text-3xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent">
              {{ $t('uptime.my_validators') }}
            </h2>
            <div class="mt-2 flex items-center text-sm text-gray-600 dark:text-gray-400">
              <Icon icon="mdi:shield-account" class="mr-2 text-lg" />
              {{ $t('uptime.add_validators_monitor') }}
            </div>
          </div>
          <label for="add-validator" 
            class="px-6 py-3 rounded-xl font-medium bg-gradient-to-r from-purple-500 to-blue-500 text-white hover:from-purple-600 hover:to-blue-600 transition-all duration-200 cursor-pointer shadow-lg"
          >
            <Icon icon="mdi:plus" class="inline-block mr-2" />
            {{ $t('uptime.add_validators') }}
          </label>
        </div>
      </div>
    </div>

    <!-- Validators Table -->
    <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-green-500/5 to-emerald-500/5 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
      
      <div class="relative p-6">
        <div v-if="list.length === 0" class="text-center py-12">
          <Icon icon="mdi:account-group-outline" class="text-6xl text-gray-300 dark:text-gray-600 mb-4" />
          <p class="text-gray-500 dark:text-gray-400">No validators added yet. Click the button above to add validators to monitor.</p>
        </div>
        
        <div v-else class="overflow-x-auto">
          <table class="table w-full">
            <thead>
              <tr class="border-b border-gray-200 dark:border-white/10">
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">#</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">Chain</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">{{ $t('account.validator') }}</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4 text-right">{{ $t('uptime.signed_blocks') }}</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">{{ $t('uptime.last_jailed_time') }}</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">{{ $t('uptime.tombstoned') }}</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4 text-center">{{ $t('uptime.missing_blocks') }}</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4 text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(v, i) in list" :key="i"
                class="border-b border-gray-100 dark:border-white/5 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors duration-200"
              >
                <td class="py-4 px-4">
                  <span class="text-sm text-gray-500 dark:text-gray-400">{{ i + 1 }}</span>
                </td>
                <td class="py-4 px-4">
                  <span class="px-3 py-1 rounded-lg bg-purple-500/10 text-purple-600 dark:text-purple-400 font-medium text-sm capitalize">
                    {{ v.chainName }}
                  </span>
                </td>
                <td class="py-4 px-4">
                  <span class="font-medium text-sm text-gray-900 dark:text-white">{{ v.v.name }}</span>
                </td>
                <td class="py-4 px-4 text-right">
                  <span v-if="v.sigingInfo" class="font-mono text-sm">
                    {{ Number(v.sigingInfo.index_offset) - Number(v.sigingInfo.start_height) }}
                  </span>
                  <span v-else class="text-gray-400">-</span>
                </td>
                <td class="py-4 px-4">
                  <div v-if="v.sigingInfo && !v.sigingInfo?.jailed_until.startsWith('1970')"
                    class="text-sm"
                  >
                    <div class="text-orange-600 dark:text-orange-400">
                      {{ format.toDay(v.sigingInfo.jailed_until, 'long') }}
                    </div>
                    <div class="text-xs text-gray-500 dark:text-gray-400">
                      {{ format.toDay(v.sigingInfo.jailed_until, 'from') }}
                    </div>
                  </div>
                  <span v-else class="text-sm text-gray-400">Never</span>
                </td>
                <td class="py-4 px-4">
                  <span v-if="v.sigingInfo?.tombstoned" 
                    class="px-2 py-1 rounded-lg text-xs font-medium bg-red-500/10 text-red-600 dark:text-red-400"
                  >
                    Yes
                  </span>
                  <span v-else class="text-sm text-gray-400">No</span>
                </td>
                <td class="py-4 px-4 text-center">
                  <span v-if="v.sigingInfo" 
                    class="px-3 py-1 rounded-lg text-sm font-bold"
                    :class="Number(v.sigingInfo?.missed_blocks_counter) < 10 
                      ? 'bg-green-500/10 text-green-600 dark:text-green-400' 
                      : Number(v.sigingInfo?.missed_blocks_counter) > 1000
                      ? 'bg-red-500/10 text-red-600 dark:text-red-400'
                      : 'bg-yellow-500/10 text-yellow-600 dark:text-yellow-400'"
                  >
                    {{ v.sigingInfo?.missed_blocks_counter }}
                  </span>
                  <span v-else class="text-gray-400">-</span>
                </td>
                <td class="py-4 px-4 text-center">
                  <div class="flex items-center justify-center gap-2">
                    <RouterLink :to="`/${v.chainName}/uptime/#blocks`" 
                      class="px-3 py-1 rounded-lg bg-purple-500/10 text-purple-600 dark:text-purple-400 hover:bg-purple-500/20 font-medium text-sm transition-all duration-200"
                    >
                      <Icon icon="mdi:view-grid" class="inline-block mr-1" />
                      View
                    </RouterLink>
                    <button 
                      @click="removeValidator(v.chainName, v.v.address)"
                      class="px-3 py-1 rounded-lg bg-red-500/10 text-red-600 dark:text-red-400 hover:bg-red-500/20 font-medium text-sm transition-all duration-200"
                    >
                      <Icon icon="mdi:delete-outline" class="inline-block mr-1" />
                      Remove
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Modal -->
    <input
      type="checkbox"
      id="add-validator"
      class="modal-toggle"
      @change="initial"
    />
    <div class="modal">
      <div class="modal-box max-w-2xl backdrop-blur-xl bg-white/95 dark:bg-gray-900/95 border border-gray-200 dark:border-white/10 shadow-2xl">
        <label
          for="add-validator"
          class="btn btn-sm btn-circle absolute right-2 top-2 bg-gray-100 dark:bg-white/10 hover:bg-gray-200 dark:hover:bg-white/20 border-0"
        >
          <Icon icon="mdi:close" />
        </label>
        
        <h3 class="text-2xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent mb-6">
          {{ $t('uptime.add_validators') }}
        </h3>
        
        <!-- Chain and Search -->
        <div class="space-y-4 mb-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="text-sm font-medium text-gray-600 dark:text-gray-400 mb-1 block">Select Chain</label>
              <select v-model="selectChain" 
                class="w-full px-4 py-2.5 rounded-xl bg-gray-100 dark:bg-white/5 border border-gray-200 dark:border-white/10 focus:border-purple-500 dark:focus:border-purple-400 focus:ring-2 focus:ring-purple-500/20 dark:focus:ring-purple-400/20 transition-all duration-200 capitalize"
                @change="changeChain"
              >
                <option v-for="v in dashboard.chains" :key="v.chainName" :value="v.chainName">
                  {{ v.chainName }}
                </option>
              </select>
            </div>
            <div>
              <label class="text-sm font-medium text-gray-600 dark:text-gray-400 mb-1 block">Search Validators</label>
              <div class="relative">
                <input v-model="keyword" 
                  type="text" 
                  class="w-full px-4 py-2.5 pl-10 rounded-xl bg-gray-100 dark:bg-white/5 border border-gray-200 dark:border-white/10 focus:border-purple-500 dark:focus:border-purple-400 focus:ring-2 focus:ring-purple-500/20 dark:focus:ring-purple-400/20 transition-all duration-200"
                  placeholder="Search by name..." 
                />
                <Icon icon="mdi:magnify" class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
              </div>
            </div>
          </div>
        </div>
        
        <!-- Validators List -->
        <div class="bg-gray-50 dark:bg-white/5 rounded-2xl p-4 max-h-96 overflow-y-auto">
          <div v-if="filterValidators.length === 0" class="text-center py-8 text-gray-500 dark:text-gray-400">
            No validators found
          </div>
          <div v-else class="space-y-2">
            <label v-for="(v, i) in filterValidators" :key="v.operator_address"
              :for="v.operator_address"
              class="flex items-center justify-between p-3 rounded-xl hover:bg-gray-100 dark:hover:bg-white/10 cursor-pointer transition-all duration-200"
            >
              <div class="flex items-center gap-3">
                <span class="text-sm text-gray-500 dark:text-gray-400">{{ i + 1 }}.</span>
                <span class="font-medium text-gray-900 dark:text-white">{{ v.description.moniker }}</span>
              </div>
              <input
                :id="v.operator_address"
                v-model="selected"
                class="checkbox checkbox-primary rounded-lg"
                type="checkbox"
                :value="consensusPubkeyToHexAddress(v.consensus_pubkey)"
              />
            </label>
          </div>
        </div>
        
        <!-- Actions -->
        <div class="modal-action">
          <label for="add-validator" class="btn btn-ghost">Cancel</label>
          <button class="px-6 py-2.5 rounded-xl font-medium bg-gradient-to-r from-purple-500 to-blue-500 text-white hover:from-purple-600 hover:to-blue-600 transition-all duration-200 shadow-lg"
            @click="add"
          >
            <Icon icon="mdi:check" class="inline-block mr-2" />
            {{ $t('uptime.add') }} ({{ selected.length }})
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
