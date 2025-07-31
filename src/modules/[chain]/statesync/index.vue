<script lang="ts" setup>
import { useBaseStore, useBlockchain, useFormatter } from '@/stores';
import type { NodeInfo } from '@/types';
import { fromBase64, toHex } from '@cosmjs/encoding';
import { onMounted, ref } from 'vue';
import { computed } from 'vue';
import { Icon } from '@iconify/vue';

const props = defineProps(['hash', 'chain']);
const blockchain = useBlockchain();
const base = useBaseStore();
const nodeInfo = ref({} as NodeInfo);

const height = ref(0);
const hash = ref('');

base.$subscribe((m, { latest }) => {
  let h = Number(latest.block?.header?.height);
  h = Math.round((h - 2000) / 1000) * 1000;
  if (h > height.value) {
    height.value = h;
    base.fetchBlock(h).then((res) => {
      hash.value = toHex(fromBase64(res.block_id.hash)).toUpperCase();
    });
  }
});

const rpcs = computed(() => {
  return blockchain.current?.endpoints?.rpc?.map((x) => x.address).join(',');
});

const appName = computed(() => {
  return nodeInfo.value.application_version?.app_name || 'gaiad';
});

const copyToClipboard = (text: string) => {
  navigator.clipboard.writeText(text);
  // You could add a toast notification here
};

const configText = computed(() => {
  return `[state-sync]
enable = true

rpc_servers = "${rpcs.value}"
trust_height = ${height.value}
trust_hash = "${hash.value}"

# 2/3 of unbonding time
trust_period = "168h"`;
});

const snapshotConfig = `# snapshot-interval specifies the block interval at which local state sync snapshots are
# taken (0 to disable). Must be a multiple of pruning-keep-every.
snapshot-interval = 1000

# snapshot-keep-recent specifies the number of recent snapshots to keep and serve (0 to keep all). Each snapshot is about 500MiB
snapshot-keep-recent = 2`;

onMounted(() => {
  blockchain.rpc.getBaseNodeInfo().then((x) => {
    nodeInfo.value = x;
  });
});
</script>
<template>
  <div class="space-y-6">
    <!-- Header Section -->
    <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-purple-500/5 to-blue-500/5 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
      
      <div class="relative">
        <h2 class="text-3xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent flex items-center gap-3 mb-4">
          <Icon icon="mdi:sync" class="text-purple-500" />
          {{ $t('statesync.title') }}
        </h2>
        <p class="text-gray-600 dark:text-gray-400">
          {{ $t('statesync.description') }}
          <a href="https://blog.cosmos.network/cosmos-sdk-state-sync-guide-99e4cf43be2f" 
             target="_blank"
             class="text-purple-600 dark:text-purple-400 hover:text-purple-700 dark:hover:text-purple-300 underline-offset-4 hover:underline transition-colors"
          >
            {{ $t('statesync.here') }}
          </a>
          <span>{{ $t('statesync.for_more_info') }}.</span>
        </p>
      </div>
    </div>

    <!-- Node Info Stats -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <!-- App Name -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-green-500/10 to-emerald-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Application</div>
            <Icon icon="mdi:application" class="text-2xl text-green-500/70 dark:text-green-400/70" />
          </div>
          <div class="text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 dark:from-green-400 dark:to-emerald-400 bg-clip-text text-transparent">
            {{ appName }}
          </div>
        </div>
      </div>

      <!-- Version -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-blue-500/10 to-cyan-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">{{ $t('statesync.version') }}</div>
            <Icon icon="mdi:tag" class="text-2xl text-blue-500/70 dark:text-blue-400/70" />
          </div>
          <div class="text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 dark:from-blue-400 dark:to-cyan-400 bg-clip-text text-transparent">
            {{ nodeInfo.application_version?.version || 'N/A' }}
          </div>
        </div>
      </div>

      <!-- Trust Height -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-purple-500/10 to-pink-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Trust Height</div>
            <Icon icon="mdi:numeric" class="text-2xl text-purple-500/70 dark:text-purple-400/70" />
          </div>
          <div class="text-2xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 dark:from-purple-400 dark:to-pink-400 bg-clip-text text-transparent">
            {{ height.toLocaleString() || '0' }}
          </div>
        </div>
      </div>
    </div>

    <!-- Setup Instructions -->
    <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-indigo-500/5 to-purple-500/5 rounded-full blur-2xl transform translate-x-24 -translate-y-24"></div>
      
      <div class="relative">
        <h3 class="text-xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 dark:from-indigo-400 dark:to-purple-400 bg-clip-text text-transparent mb-6 flex items-center gap-2">
          <Icon icon="mdi:cog" />
          {{ $t('statesync.title_2') }}
        </h3>
        
        <div class="space-y-6">
          <!-- Step 1 -->
          <div class="flex gap-4">
            <div class="flex-shrink-0 w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500/20 to-purple-500/20 flex items-center justify-center">
              <span class="text-lg font-bold text-indigo-600 dark:text-indigo-400">1</span>
            </div>
            <div class="flex-1">
              <p class="text-gray-700 dark:text-gray-300 mb-2">
                {{ $t('statesync.text_1') }} 
                <span class="font-mono bg-gray-100 dark:bg-white/10 px-2 py-1 rounded text-sm">
                  {{ appName }} {{ $t('statesync.version') }}: {{ nodeInfo.application_version?.version || '' }}
                </span>
              </p>
              <p class="text-gray-600 dark:text-gray-400 text-sm">
                {{ $t('statesync.text_1_1') }}.
              </p>
            </div>
          </div>

          <!-- Step 2 -->
          <div class="flex gap-4">
            <div class="flex-shrink-0 w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500/20 to-purple-500/20 flex items-center justify-center">
              <span class="text-lg font-bold text-indigo-600 dark:text-indigo-400">2</span>
            </div>
            <div class="flex-1">
              <p class="text-gray-700 dark:text-gray-300 mb-2">
                {{ $t('statesync.text_2') }}
              </p>
              <p class="text-gray-600 dark:text-gray-400 text-sm mb-4">
                {{ $t('statesync.text_2_1') }}.
              </p>
              
              <!-- Configuration Code Block -->
              <div class="relative group">
                <div class="absolute right-4 top-4 z-10">
                  <button 
                    @click="copyToClipboard(configText)"
                    class="p-2 rounded-lg bg-gray-100 dark:bg-white/10 hover:bg-gray-200 dark:hover:bg-white/20 transition-colors opacity-0 group-hover:opacity-100"
                  >
                    <Icon icon="mdi:content-copy" class="text-gray-600 dark:text-gray-400" />
                  </button>
                </div>
                <div class="bg-gray-900 dark:bg-black/50 rounded-2xl p-6 overflow-x-auto border border-gray-800 dark:border-white/10">
                  <pre class="text-sm"><code class="language-toml"><span class="text-purple-400">[state-sync]</span>
<span class="text-green-400">enable</span> = <span class="text-orange-400">true</span>

<span class="text-green-400">rpc_servers</span> = <span class="text-yellow-400">"{{ rpcs }}"</span>
<span class="text-green-400">trust_height</span> = <span class="text-orange-400">{{ height }}</span>
<span class="text-green-400">trust_hash</span> = <span class="text-yellow-400">"{{ hash }}"</span>

<span class="text-gray-500"># 2/3 of unbonding time</span>
<span class="text-green-400">trust_period</span> = <span class="text-yellow-400">"168h"</span></code></pre>
                </div>
              </div>
            </div>
          </div>

          <!-- Step 3 -->
          <div class="flex gap-4">
            <div class="flex-shrink-0 w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500/20 to-purple-500/20 flex items-center justify-center">
              <span class="text-lg font-bold text-indigo-600 dark:text-indigo-400">3</span>
            </div>
            <div class="flex-1">
              <p class="text-gray-700 dark:text-gray-300 mb-2">
                {{ $t('statesync.text_3') }}:
              </p>
              <div class="space-y-2">
                <code class="block bg-gray-100 dark:bg-white/10 px-4 py-3 rounded-xl text-sm font-mono">
                  {{ appName }} start
                </code>
                <p class="text-gray-600 dark:text-gray-400 text-sm">
                  {{ $t('statesync.text_3_1') }}
                </p>
                <div class="flex flex-col sm:flex-row gap-2">
                  <code class="bg-gray-100 dark:bg-white/10 px-4 py-3 rounded-xl text-sm font-mono">
                    {{ appName }} unsafe-reset-all
                  </code>
                  <span class="text-gray-600 dark:text-gray-400 self-center">or</span>
                  <code class="bg-gray-100 dark:bg-white/10 px-4 py-3 rounded-xl text-sm font-mono">
                    {{ appName }} tendermint unsafe-reset-all --home ~/.HOME
                  </code>
                </div>
                <p class="text-gray-600 dark:text-gray-400 text-sm">
                  {{ $t('statesync.text_3_2') }}.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Snapshot Provider Configuration -->
    <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-amber-500/5 to-orange-500/5 rounded-full blur-2xl transform translate-x-24 -translate-y-24"></div>
      
      <div class="relative">
        <h3 class="text-xl font-bold bg-gradient-to-r from-amber-600 to-orange-600 dark:from-amber-400 dark:to-orange-400 bg-clip-text text-transparent mb-4 flex items-center gap-2">
          <Icon icon="mdi:camera" />
          {{ $t('statesync.title_3') }}
        </h3>
        
        <p class="text-gray-700 dark:text-gray-300 mb-6">
          {{ $t('statesync.text_title_3') }}
        </p>
        
        <!-- Snapshot Configuration Code Block -->
        <div class="relative group">
          <div class="absolute right-4 top-4 z-10">
            <button 
              @click="copyToClipboard(snapshotConfig)"
              class="p-2 rounded-lg bg-gray-100 dark:bg-white/10 hover:bg-gray-200 dark:hover:bg-white/20 transition-colors opacity-0 group-hover:opacity-100"
            >
              <Icon icon="mdi:content-copy" class="text-gray-600 dark:text-gray-400" />
            </button>
          </div>
          <div class="bg-gray-900 dark:bg-black/50 rounded-2xl p-6 overflow-x-auto border border-gray-800 dark:border-white/10">
            <pre class="text-sm"><code class="language-toml"><span class="text-gray-500"># snapshot-interval specifies the block interval at which local state sync snapshots are</span>
<span class="text-gray-500"># taken (0 to disable). Must be a multiple of pruning-keep-every.</span>
<span class="text-green-400">snapshot-interval</span> = <span class="text-orange-400">1000</span>

<span class="text-gray-500"># snapshot-keep-recent specifies the number of recent snapshots to keep and serve (0 to keep all). Each snapshot is about 500MiB</span>
<span class="text-green-400">snapshot-keep-recent</span> = <span class="text-orange-400">2</span></code></pre>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Tips -->
    <div class="backdrop-blur-xl bg-gradient-to-r from-blue-500/10 to-cyan-500/10 rounded-3xl border border-blue-500/20 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-blue-500/10 to-cyan-500/10 rounded-full blur-2xl transform translate-x-24 -translate-y-24"></div>
      <div class="relative">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500/20 to-cyan-500/20 flex items-center justify-center">
            <Icon icon="mdi:lightbulb" class="text-2xl text-blue-600 dark:text-blue-400" />
          </div>
          <h3 class="text-lg font-bold text-blue-600 dark:text-blue-400">Quick Tips</h3>
        </div>
        <ul class="space-y-2 text-sm text-gray-700 dark:text-gray-300">
          <li class="flex items-start gap-2">
            <Icon icon="mdi:check" class="text-blue-600 dark:text-blue-400 mt-0.5" />
            <span>Make sure your node has enough disk space before starting state sync</span>
          </li>
          <li class="flex items-start gap-2">
            <Icon icon="mdi:check" class="text-blue-600 dark:text-blue-400 mt-0.5" />
            <span>State sync requires at least 2 RPC servers for redundancy</span>
          </li>
          <li class="flex items-start gap-2">
            <Icon icon="mdi:check" class="text-blue-600 dark:text-blue-400 mt-0.5" />
            <span>The trust period should be less than the unbonding period</span>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<route>
  {
    meta: {
      i18n: 'state-sync'
    }
  }
</route>