<script lang="ts" setup>
import { formatSeconds } from '@/libs/utils';
import { useBaseStore, useBlockchain, useFormatter } from '@/stores';
import {
  type Connection,
  type ClientState,
  type Channel,
  PageRequest,
  type TxResponse,
  type PaginatedTxs,
} from '@/types';
import { computed, onMounted } from 'vue';
import { ref } from 'vue';
import { useIBCModule } from '../connStore';
import PaginationBar from '@/components/PaginationBar.vue';
import { Icon } from '@iconify/vue';

const props = defineProps(['chain', 'connection_id']);
const chainStore = useBlockchain();
const baseStore = useBaseStore();
const format = useFormatter();
const ibcStore = useIBCModule();
const conn = ref({} as Connection);
const clientState = ref({} as { client_id: string; client_state: ClientState });
const channels = ref([] as Channel[]);

const connId = computed(() => {
  return props.connection_id || 0;
});

const loading = ref(false);
const txs = ref({} as PaginatedTxs);
const direction = ref('');
const channel_id = ref('');
const port_id = ref('');
const page = ref(new PageRequest());
page.value.limit = 5;

onMounted(() => {
  if (connId.value) {
    chainStore.rpc.getIBCConnectionsById(connId.value).then((x) => {
      conn.value = x.connection;
    });
    chainStore.rpc.getIBCConnectionsClientState(connId.value).then((x) => {
      clientState.value = x.identified_client_state;
    });
    chainStore.rpc.getIBCConnectionsChannels(connId.value).then((x) => {
      channels.value = x.channels;
    });
  }
});

function loadChannel(channel: string, port: string) {
  chainStore.rpc.getIBCChannelNextSequence(channel, port).then((x) => {
    console.log(x);
  });
}

function pageload(pageNum: number) {
  if (direction.value === 'In') {
    fetchSendingTxs(channel_id.value, port_id.value, pageNum - 1);
  } else {
    fetchSendingTxs(channel_id.value, port_id.value, pageNum - 1);
  }
}

function fetchSendingTxs(channel: string, port: string, pageNum = 0) {
  page.value.setPage(pageNum);
  loading.value = true;
  direction.value = 'Out';
  channel_id.value = channel;
  port_id.value = port;
  txs.value = {} as PaginatedTxs;
  chainStore.rpc
    .getTxs(
      "?order_by=2&events=send_packet.packet_src_channel='{channel}'&events=send_packet.packet_src_port='{port}'",
      { channel, port },
      page.value
    )
    .then((res) => {
      txs.value = res;
    })
    .finally(() => (loading.value = false));
}
function fetchRecevingTxs(channel: string, port: string, pageNum = 0) {
  page.value.setPage(pageNum);
  loading.value = true;
  direction.value = 'In';
  channel_id.value = channel;
  port_id.value = port;
  txs.value = {} as PaginatedTxs;
  chainStore.rpc
    .getTxs(
      "?order_by=2&events=recv_packet.packet_dst_channel='{channel}'&events=recv_packet.packet_dst_port='{port}'",
      { channel, port },
      page.value
    )
    .then((res) => {
      txs.value = res;
    })
    .finally(() => (loading.value = false));
}

function color(v: string) {
  if (v && v.indexOf('_OPEN') > -1) {
    return 'success';
  }
  return 'warning';
}
</script>
<template>
  <div class="space-y-6">
    <!-- Page Header -->
    <div class="backdrop-blur-sm bg-gradient-to-br from-white via-purple-50/95 to-blue-50/95 dark:from-gray-900/95 dark:via-purple-900/20 dark:to-blue-900/20 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-purple-400/10 via-blue-400/10 to-pink-400/10 rounded-full blur-2xl transform translate-x-48 -translate-y-48"></div>
      <div class="absolute bottom-0 left-0 w-80 h-80 bg-gradient-to-tr from-blue-400/10 via-indigo-400/10 to-purple-400/10 rounded-full blur-2xl transform -translate-x-40 translate-y-40"></div>
      
      <div class="relative p-8">
        <div class="flex items-center gap-4">
          <div class="p-4 rounded-2xl bg-gradient-to-br from-purple-500/20 to-blue-500/20 backdrop-blur-sm">
            <Icon icon="mdi:transit-connection-variant" class="text-4xl text-purple-600 dark:text-purple-400" />
          </div>
          <div>
            <h1 class="text-3xl font-bold bg-gradient-to-r from-purple-600 via-blue-600 to-pink-600 dark:from-purple-400 dark:via-blue-400 dark:to-pink-400 bg-clip-text text-transparent animate-gradient">
              IBC Connection Details
            </h1>
            <p class="text-gray-600 dark:text-gray-400 mt-1">{{ props.connection_id }}</p>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Connection Header -->
    <div class="backdrop-blur-md bg-white/95 dark:bg-gray-800/90 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-8">
      <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-purple-500/5 via-blue-500/5 to-pink-500/5 rounded-full blur-2xl transform translate-x-48 -translate-y-48"></div>
      
      <div class="relative">
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 items-center">
          <!-- Source Chain -->
          <div class="text-center lg:text-left">
            <div class="mb-4">
              <div class="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-purple-500/10 to-blue-500/10 border border-purple-500/20 mb-4">
                <Icon icon="mdi:ethereum" class="text-2xl text-purple-600 dark:text-purple-400" />
              </div>
            </div>
            <h3 class="text-2xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent mb-2">
              {{ baseStore.latest?.block?.header?.chain_id }}
            </h3>
            <div class="space-y-1">
              <div class="text-sm text-gray-600 dark:text-gray-400">
                <span class="font-medium">Client:</span> {{ conn.client_id }}
              </div>
              <div class="text-sm text-gray-600 dark:text-gray-400">
                <span class="font-medium">Connection:</span> {{ props.connection_id }}
              </div>
            </div>
          </div>

          <!-- Connection Status -->
          <div class="text-center">
            <div class="relative inline-block">
              <div class="absolute inset-0 bg-gradient-to-r from-purple-500/10 to-blue-500/10 blur-lg"></div>
              <div class="relative px-6 py-3 rounded-2xl border"
                :class="conn.state?.indexOf('_OPEN') > -1 
                  ? 'bg-green-500/10 border-green-500/30' 
                  : 'bg-gray-500/10 border-gray-500/30'"
              >
                <div class="flex items-center gap-3">
                  <Icon 
                    :icon="conn.state?.indexOf('_OPEN') > -1 ? 'mdi:link-variant' : 'mdi:link-variant-off'"
                    class="text-3xl"
                    :class="conn.state?.indexOf('_OPEN') > -1 
                      ? 'text-green-600 dark:text-green-400' 
                      : 'text-gray-600 dark:text-gray-400'"
                  />
                  <div>
                    <div class="text-xs uppercase tracking-wider font-medium"
                      :class="conn.state?.indexOf('_OPEN') > -1 
                        ? 'text-green-600 dark:text-green-400' 
                        : 'text-gray-600 dark:text-gray-400'"
                    >
                      Connection
                    </div>
                    <div class="text-lg font-bold"
                      :class="conn.state?.indexOf('_OPEN') > -1 
                        ? 'text-green-600 dark:text-green-400' 
                        : 'text-gray-600 dark:text-gray-400'"
                    >
                      {{ conn.state }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Target Chain -->
          <div class="text-center lg:text-right">
            <div class="mb-4">
              <div class="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-green-500/10 to-emerald-500/10 border border-green-500/20 mb-4">
                <Icon icon="mdi:ethereum" class="text-2xl text-green-600 dark:text-green-400" />
              </div>
            </div>
            <h3 class="text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 dark:from-green-400 dark:to-emerald-400 bg-clip-text text-transparent mb-2">
              {{ clientState.client_state?.chain_id }}
            </h3>
            <div class="space-y-1">
              <div class="text-sm text-gray-600 dark:text-gray-400">
                <span class="font-medium">Client:</span> {{ clientState.client_id }}
              </div>
              <div class="text-sm text-gray-600 dark:text-gray-400">
                <span class="font-medium">Connection:</span> {{ conn.counterparty?.connection_id }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Client State Parameters -->
    <div class="backdrop-blur-md bg-white/95 dark:bg-gray-800/90 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-blue-500/5 to-cyan-500/5 rounded-full blur-2xl transform translate-x-32 -translate-y-32"></div>
      
      <div class="relative p-6">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 dark:from-blue-400 dark:to-cyan-400 bg-clip-text text-transparent">
            {{ $t('ibc.title_2') }}
          </h2>
          <span class="px-3 py-1 rounded-xl bg-blue-500/10 text-blue-600 dark:text-blue-400 text-sm font-medium border border-blue-500/30">
            {{ clientState.client_state?.['@type']?.split('.').pop() || 'Unknown' }}
          </span>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Trust Parameters Panel -->
          <div class="backdrop-blur-sm bg-white/80 dark:bg-gray-700/50 rounded-2xl p-6 border border-gray-200 dark:border-white/10">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
              <Icon icon="mdi:shield-check" class="text-blue-500/70" />
              {{ $t('ibc.trust_parameters') }}
            </h3>
            <div class="space-y-4">
              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600 dark:text-gray-400">{{ $t('ibc.trust_level') }}</span>
                <span class="font-mono font-medium text-gray-900 dark:text-white">
                  {{ clientState.client_state?.trust_level?.numerator }}/{{
                    clientState.client_state?.trust_level?.denominator
                  }}
                </span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600 dark:text-gray-400">{{ $t('ibc.trusting_period') }}</span>
                <span class="font-medium text-gray-900 dark:text-white">
                  {{ formatSeconds(clientState.client_state?.trusting_period) }}
                </span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600 dark:text-gray-400">{{ $t('ibc.unbonding_period') }}</span>
                <span class="font-medium text-gray-900 dark:text-white">
                  {{ formatSeconds(clientState.client_state?.unbonding_period) }}
                </span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600 dark:text-gray-400">{{ $t('ibc.max_clock_drift') }}</span>
                <span class="font-medium text-gray-900 dark:text-white">
                  {{ formatSeconds(clientState.client_state?.max_clock_drift) }}
                </span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600 dark:text-gray-400">{{ $t('ibc.frozen_height') }}</span>
                <span class="font-mono font-medium text-gray-900 dark:text-white">
                  {{ clientState.client_state?.frozen_height || 'N/A' }}
                </span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600 dark:text-gray-400">{{ $t('ibc.latest_height') }}</span>
                <span class="font-mono font-medium text-gray-900 dark:text-white">
                  {{ clientState.client_state?.latest_height || 'N/A' }}
                </span>
              </div>
            </div>
          </div>
          <!-- Upgrade Parameters Panel -->
          <div class="backdrop-blur-sm bg-white/80 dark:bg-gray-700/50 rounded-2xl p-6 border border-gray-200 dark:border-white/10">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
              <Icon icon="mdi:update" class="text-green-500/70" />
              {{ $t('ibc.upgrade_parameters') }}
            </h3>
            <div class="space-y-4">
              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600 dark:text-gray-400">{{ $t('ibc.allow_update_after_expiry') }}</span>
                <span class="px-2 py-1 rounded-lg text-xs font-medium"
                  :class="clientState.client_state?.allow_update_after_expiry 
                    ? 'bg-green-500/10 text-green-600 dark:text-green-400 border border-green-500/30' 
                    : 'bg-gray-500/10 text-gray-600 dark:text-gray-400 border border-gray-500/30'"
                >
                  {{ clientState.client_state?.allow_update_after_expiry ? 'Yes' : 'No' }}
                </span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600 dark:text-gray-400">{{ $t('ibc.allow_update_after_misbehaviour') }}</span>
                <span class="px-2 py-1 rounded-lg text-xs font-medium"
                  :class="clientState.client_state?.allow_update_after_misbehaviour 
                    ? 'bg-green-500/10 text-green-600 dark:text-green-400 border border-green-500/30' 
                    : 'bg-gray-500/10 text-gray-600 dark:text-gray-400 border border-gray-500/30'"
                >
                  {{ clientState.client_state?.allow_update_after_misbehaviour ? 'Yes' : 'No' }}
                </span>
              </div>
              <div>
                <div class="text-sm text-gray-600 dark:text-gray-400 mb-2">{{ $t('ibc.upgrade_path') }}</div>
                <div class="bg-gray-100 dark:bg-gray-700/50 rounded-lg p-3 font-mono text-sm text-gray-900 dark:text-white backdrop-blur-sm border border-gray-200 dark:border-white/10">
                  {{ clientState.client_state?.upgrade_path?.join(', ') || 'None' }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <!-- Channels Table -->
    <div class="backdrop-blur-md bg-white/95 dark:bg-gray-800/90 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-72 h-72 bg-gradient-to-br from-purple-500/5 to-pink-500/5 rounded-full blur-2xl transform translate-x-36 -translate-y-36"></div>
      
      <div class="relative p-6">
        <h2 class="text-2xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 dark:from-purple-400 dark:to-pink-400 bg-clip-text text-transparent mb-6">
          {{ $t('ibc.channels') }}
        </h2>
        
        <div class="overflow-x-auto">
          <table class="table w-full">
            <thead>
              <tr class="border-b border-gray-200 dark:border-white/10">
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">{{ $t('ibc.txs') }}</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">
                  {{ $t('ibc.channel_id') }}
                </th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">{{ $t('ibc.port_id') }}</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">{{ $t('ibc.state') }}</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">{{ $t('ibc.counterparty') }}</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">{{ $t('ibc.hops') }}</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">{{ $t('ibc.version') }}</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">{{ $t('ibc.ordering') }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="v in ibcStore.registryChannels" :key="v[ibcStore.sourceField].channel_id"
                class="border-b border-gray-100 dark:border-white/5 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors duration-200"
              >
                <td class="py-4 px-4">
                  <div class="flex gap-2">
                    <button
                      class="relative px-4 py-2 rounded-xl text-xs font-semibold transition-all duration-300 transform group overflow-hidden"
                      :class="loading 
                        ? 'bg-gray-200 dark:bg-gray-700 text-gray-400 cursor-not-allowed' 
                        : 'bg-gradient-to-r from-purple-500/20 to-indigo-500/20 text-purple-600 dark:text-purple-400 border border-purple-500/30 hover:border-purple-500/50 hover:shadow-lg hover:shadow-purple-500/25 hover:-translate-y-0.5 active:translate-y-0 active:shadow-md'"
                      @click="fetchSendingTxs(v[ibcStore.sourceField].channel_id, v[ibcStore.sourceField].port_id)"
                      :disabled="loading"
                    >
                      <div class="absolute inset-0 bg-gradient-to-r from-purple-600 to-indigo-600 opacity-0 group-hover:opacity-10 transition-opacity duration-300" v-if="!loading"></div>
                      <span class="relative flex items-center gap-1.5 justify-center">
                        <span v-if="loading" class="loading loading-spinner loading-sm"></span>
                        <Icon v-else icon="mdi:arrow-up-bold" class="text-base" />
                        {{ $t('ibc.btn_out') }}
                      </span>
                    </button>
                    <button
                      class="relative px-4 py-2 rounded-xl text-xs font-semibold transition-all duration-300 transform group overflow-hidden"
                      :class="loading 
                        ? 'bg-gray-200 dark:bg-gray-700 text-gray-400 cursor-not-allowed' 
                        : 'bg-gradient-to-r from-blue-500/20 to-cyan-500/20 text-blue-600 dark:text-blue-400 border border-blue-500/30 hover:border-blue-500/50 hover:shadow-lg hover:shadow-blue-500/25 hover:-translate-y-0.5 active:translate-y-0 active:shadow-md'"
                      @click="fetchRecevingTxs(v[ibcStore.sourceField].channel_id, v[ibcStore.sourceField].port_id)"
                      :disabled="loading"
                    >
                      <div class="absolute inset-0 bg-gradient-to-r from-blue-600 to-cyan-600 opacity-0 group-hover:opacity-10 transition-opacity duration-300" v-if="!loading"></div>
                      <span class="relative flex items-center gap-1.5 justify-center">
                        <span v-if="loading" class="loading loading-spinner loading-sm"></span>
                        <Icon v-else icon="mdi:arrow-down-bold" class="text-base" />
                        {{ $t('ibc.btn_in') }}
                      </span>
                    </button>
                  </div>
                </td>
                <td class="py-4 px-4">
                  <span class="font-mono text-sm text-gray-900 dark:text-white">{{ v[ibcStore.sourceField].channel_id }}</span>
                </td>
                <td class="py-4 px-4">
                  <span class="text-sm text-gray-600 dark:text-gray-400">{{ v[ibcStore.sourceField].port_id }}</span>
                </td>
              </tr>
              <tr v-for="v in channels" :key="v.channel_id"
                class="border-b border-gray-100 dark:border-white/5 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors duration-200"
              >
                <td class="py-4 px-4">
                  <div class="flex gap-2">
                    <button
                      class="relative px-4 py-2 rounded-xl text-xs font-semibold transition-all duration-300 transform group overflow-hidden"
                      :class="loading 
                        ? 'bg-gray-200 dark:bg-gray-700 text-gray-400 cursor-not-allowed' 
                        : 'bg-gradient-to-r from-purple-500/20 to-indigo-500/20 text-purple-600 dark:text-purple-400 border border-purple-500/30 hover:border-purple-500/50 hover:shadow-lg hover:shadow-purple-500/25 hover:-translate-y-0.5 active:translate-y-0 active:shadow-md'"
                      @click="fetchSendingTxs(v.channel_id, v.port_id)"
                      :disabled="loading"
                    >
                      <div class="absolute inset-0 bg-gradient-to-r from-purple-600 to-indigo-600 opacity-0 group-hover:opacity-10 transition-opacity duration-300" v-if="!loading"></div>
                      <span class="relative flex items-center gap-1.5 justify-center">
                        <span v-if="loading" class="loading loading-spinner loading-sm"></span>
                        <Icon v-else icon="mdi:arrow-up-bold" class="text-base" />
                        {{ $t('ibc.btn_out') }}
                      </span>
                    </button>
                    <button
                      class="relative px-4 py-2 rounded-xl text-xs font-semibold transition-all duration-300 transform group overflow-hidden"
                      :class="loading 
                        ? 'bg-gray-200 dark:bg-gray-700 text-gray-400 cursor-not-allowed' 
                        : 'bg-gradient-to-r from-blue-500/20 to-cyan-500/20 text-blue-600 dark:text-blue-400 border border-blue-500/30 hover:border-blue-500/50 hover:shadow-lg hover:shadow-blue-500/25 hover:-translate-y-0.5 active:translate-y-0 active:shadow-md'"
                      @click="fetchRecevingTxs(v.channel_id, v.port_id)"
                      :disabled="loading"
                    >
                      <div class="absolute inset-0 bg-gradient-to-r from-blue-600 to-cyan-600 opacity-0 group-hover:opacity-10 transition-opacity duration-300" v-if="!loading"></div>
                      <span class="relative flex items-center gap-1.5 justify-center">
                        <span v-if="loading" class="loading loading-spinner loading-sm"></span>
                        <Icon v-else icon="mdi:arrow-down-bold" class="text-base" />
                        {{ $t('ibc.btn_in') }}
                      </span>
                    </button>
                  </div>
                </td>
                <td class="py-4 px-4">
                  <a href="#" @click="loadChannel(v.channel_id, v.port_id)"
                    class="font-mono text-sm text-purple-600 dark:text-purple-400 hover:text-purple-700 dark:hover:text-purple-300 transition-colors"
                  >
                    {{ v.channel_id }}
                  </a>
                </td>
                <td class="py-4 px-4">
                  <span class="text-sm text-gray-600 dark:text-gray-400">{{ v.port_id }}</span>
                </td>
                <td class="py-4 px-4">
                  <span
                    class="px-3 py-1 rounded-lg text-xs font-medium"
                    :class="v.state?.indexOf('_OPEN') > -1
                      ? 'bg-green-500/10 text-green-600 dark:text-green-400 border border-green-500/30'
                      : 'bg-yellow-500/10 text-yellow-600 dark:text-yellow-400 border border-yellow-500/30'"
                  >
                    {{ v.state }}
                  </span>
                </td>
                <td class="py-4 px-4">
                  <span class="text-sm text-gray-600 dark:text-gray-400">
                    {{ v.counterparty?.port_id }}/{{ v.counterparty?.channel_id }}
                  </span>
                </td>
                <td class="py-4 px-4">
                  <span class="font-mono text-sm text-gray-600 dark:text-gray-400">
                    {{ v.connection_hops.join(', ') }}
                  </span>
                </td>
                <td class="py-4 px-4">
                  <span class="text-sm text-gray-600 dark:text-gray-400">{{ v.version }}</span>
                </td>
                <td class="py-4 px-4">
                  <span class="text-sm text-gray-600 dark:text-gray-400">{{ v.ordering }}</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Transactions Section -->
    <div v-if="channel_id" class="backdrop-blur-md bg-white/95 dark:bg-gray-800/90 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-indigo-500/5 to-purple-500/5 rounded-full blur-2xl transform translate-x-32 -translate-y-32"></div>
      
      <div class="relative p-6">
        <div class="flex items-center justify-between mb-6">
          <h3 class="text-2xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 dark:from-indigo-400 dark:to-purple-400 bg-clip-text text-transparent">
            Transactions
          </h3>
          <div class="flex items-center gap-3">
            <span class="px-3 py-1 rounded-lg bg-gray-100 dark:bg-gray-700/50 border border-gray-200 dark:border-white/10 font-mono text-sm">
              {{ channel_id }}
            </span>
            <span class="px-3 py-1 rounded-lg bg-gray-100 dark:bg-gray-700/50 border border-gray-200 dark:border-white/10 text-sm">
              {{ port_id }}
            </span>
            <span class="px-3 py-1 rounded-lg font-medium text-sm"
              :class="direction === 'Out' 
                ? 'bg-purple-500/10 text-purple-600 dark:text-purple-400 border border-purple-500/30' 
                : 'bg-blue-500/10 text-blue-600 dark:text-blue-400 border border-blue-500/30'"
            >
              <Icon :icon="direction === 'Out' ? 'mdi:arrow-up' : 'mdi:arrow-down'" class="inline-block mr-1" />
              {{ direction }}
            </span>
          </div>
        </div>
        
        <div class="overflow-x-auto">
          <table class="table w-full">
            <thead>
              <tr class="border-b border-gray-200 dark:border-white/10">
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">{{ $t('ibc.height') }}</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">{{ $t('ibc.txhash') }}</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">{{ $t('ibc.messages') }}</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-4">{{ $t('ibc.time') }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="resp in txs?.tx_responses" :key="resp.txhash"
                class="border-b border-gray-100 dark:border-white/5 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors duration-200"
              >
                <td class="py-4 px-4">
                  <span class="font-mono text-sm text-gray-900 dark:text-white">#{{ resp.height }}</span>
                </td>
                <td class="py-4 px-4">
                  <RouterLink
                    :to="`/${chainStore.chainName}/tx/${resp.txhash}`"
                    class="font-mono text-sm text-purple-600 dark:text-purple-400 hover:text-purple-700 dark:hover:text-purple-300 transition-colors truncate block max-w-xs"
                  >
                    {{ resp.txhash }}
                  </RouterLink>
                </td>
                <td class="py-4 px-4">
                  <div class="flex items-center gap-2">
                    <span class="text-sm text-gray-900 dark:text-white">
                      {{ format.messages(resp.tx.body.messages) }}
                    </span>
                    <Icon
                      v-if="resp.code === 0"
                      icon="mdi:check-circle"
                      class="text-green-500 text-lg"
                    />
                    <Icon v-else icon="mdi:close-circle" class="text-red-500 text-lg" />
                  </div>
                </td>
                <td class="py-4 px-4">
                  <span class="text-sm text-gray-600 dark:text-gray-400">
                    {{ format.toLocaleDate(resp.timestamp) }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        
        <div class="mt-6">
          <PaginationBar
            :limit="page.limit"
            :total="txs.pagination?.total"
            :callback="pageload"
          />
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
