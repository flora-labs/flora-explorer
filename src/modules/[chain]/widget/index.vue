<script lang="ts" setup>
import { useBaseStore, useBlockchain, useFormatter } from '@/stores';
import type { Connection } from '@/types';
import { computed } from 'vue';
import { onMounted } from 'vue';
import { ref } from 'vue';
import { Icon } from '@iconify/vue';

const props = defineProps(['chain']);
const chainStore = useBlockchain();
const baseStore = useBaseStore();
const endpoint = ref(chainStore.current?.endpoints?.rest?.at(0)?.address);

const chainId = computed(() => baseStore.latest?.block?.header?.chain_id || '');
const chainName = computed(() => chainStore?.current?.prettyName || '');
const hdPath = computed(() => {
  return `m/44'/${chainStore.current?.coinType}/0'/0/0`;
});

const copyToClipboard = (text: string) => {
  navigator.clipboard.writeText(text);
  // You could add a toast notification here
};

// Widget script tag
const widgetScript = `<script type="module" src="https://unpkg.com/ping-widget@latest/dist/ping-widget.js"><\/script>`;

// Connect wallet widget code
const connectWalletCode = computed(() => {
  return `<!-- This widget is optional. -->
<ping-connect-wallet chain-id="${chainId.value}" hd-path="${hdPath.value}"/>`;
});

// Token convert widget code
const tokenConvertCode = computed(() => {
  return `<ping-token-convert chain-name="${chainName.value}" endpoint="${endpoint.value}" hd-path="${hdPath.value}"/>
<label for="PingTokenConvert" class="btn btn-sm">Buy ${chainName.value.toUpperCase()}</label>`;
});
</script>
<template>
  <div class="space-y-6">
    <!-- Header Section -->
    <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-purple-500/5 to-blue-500/5 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
      
      <div class="relative">
        <h2 class="text-3xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent flex items-center gap-3 mb-4">
          <Icon icon="mdi:widgets" class="text-purple-500" />
          {{ $t('widget.title') }}
        </h2>
        
        <!-- Endpoint Selector -->
        <div class="flex flex-col sm:flex-row items-start sm:items-center gap-4">
          <span class="text-gray-600 dark:text-gray-400 font-medium">{{ $t('widget.endpoint') }}:</span>
          <div class="relative">
            <select 
              v-model="endpoint" 
              class="px-4 py-3 pr-10 rounded-xl bg-gray-100 dark:bg-white/5 border border-gray-200 dark:border-white/10 focus:border-purple-500 dark:focus:border-purple-400 focus:ring-2 focus:ring-purple-500/20 dark:focus:ring-purple-400/20 transition-all duration-200 appearance-none cursor-pointer min-w-[300px]"
            >
              <option disabled selected>{{ $t('widget.select_endpoint') }}</option>
              <option v-for="v in chainStore.current?.endpoints.rest" :value="v.address">{{ v.address }}</option>
            </select>
            <Icon icon="mdi:chevron-down" class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
          </div>
        </div>
      </div>
    </div>

    <!-- Widget Info Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <!-- Chain ID -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-green-500/10 to-emerald-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Chain ID</div>
            <Icon icon="mdi:identifier" class="text-2xl text-green-500/70 dark:text-green-400/70" />
          </div>
          <div class="text-xl font-bold text-gray-900 dark:text-white font-mono">
            {{ chainId || 'N/A' }}
          </div>
        </div>
      </div>

      <!-- Chain Name -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-blue-500/10 to-cyan-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Chain Name</div>
            <Icon icon="mdi:web" class="text-2xl text-blue-500/70 dark:text-blue-400/70" />
          </div>
          <div class="text-xl font-bold text-gray-900 dark:text-white">
            {{ chainName || 'N/A' }}
          </div>
        </div>
      </div>

      <!-- HD Path -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-purple-500/10 to-pink-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">HD Path</div>
            <Icon icon="mdi:folder-key" class="text-2xl text-purple-500/70 dark:text-purple-400/70" />
          </div>
          <div class="text-xl font-bold text-gray-900 dark:text-white font-mono">
            {{ hdPath }}
          </div>
        </div>
      </div>
    </div>

    <!-- Script Installation -->
    <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-amber-500/5 to-orange-500/5 rounded-full blur-2xl transform translate-x-24 -translate-y-24"></div>
      
      <div class="relative">
        <h3 class="text-xl font-bold bg-gradient-to-r from-amber-600 to-orange-600 dark:from-amber-400 dark:to-orange-400 bg-clip-text text-transparent mb-4 flex items-center gap-2">
          <Icon icon="mdi:code-tags" />
          Installation
        </h3>
        
        <p class="text-gray-700 dark:text-gray-300 mb-4">
          {{ $t('widget.text_1') }}
        </p>
        
        <!-- Script Code Block -->
        <div class="relative group">
          <div class="absolute right-4 top-4 z-10">
            <button 
              @click="copyToClipboard(widgetScript)"
              class="p-2 rounded-lg bg-gray-100 dark:bg-white/10 hover:bg-gray-200 dark:hover:bg-white/20 transition-colors opacity-0 group-hover:opacity-100"
            >
              <Icon icon="mdi:content-copy" class="text-gray-600 dark:text-gray-400" />
            </button>
          </div>
          <div class="bg-gray-900 dark:bg-black/50 rounded-2xl p-6 overflow-x-auto border border-gray-800 dark:border-white/10">
            <pre class="text-sm"><code class="language-html"><span class="text-gray-400">&lt;</span><span class="text-red-400">script</span> <span class="text-green-400">type</span>=<span class="text-yellow-400">"module"</span> <span class="text-green-400">src</span>=<span class="text-yellow-400">"https://unpkg.com/ping-widget@latest/dist/ping-widget.js"</span><span class="text-gray-400">&gt;&lt;/</span><span class="text-red-400">script</span><span class="text-gray-400">&gt;</span></code></pre>
          </div>
        </div>
      </div>
    </div>

    <!-- Widget Examples -->
    <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-indigo-500/5 to-purple-500/5 rounded-full blur-2xl transform translate-x-24 -translate-y-24"></div>
      
      <div class="relative">
        <h3 class="text-xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 dark:from-indigo-400 dark:to-purple-400 bg-clip-text text-transparent mb-6 flex items-center gap-2">
          <Icon icon="mdi:puzzle" />
          {{ $t('module.widget') }}
        </h3>
        
        <div class="space-y-8">
          <!-- Connect Wallet Widget -->
          <div>
            <div class="flex items-start gap-4 mb-4">
              <div class="flex-shrink-0 w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500/20 to-purple-500/20 flex items-center justify-center">
                <span class="text-lg font-bold text-indigo-600 dark:text-indigo-400">1</span>
              </div>
              <div class="flex-1">
                <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                  {{ $t('widget.text_2') }}
                </h4>
                <p class="text-gray-600 dark:text-gray-400 text-sm mb-4">
                  This widget allows users to connect their wallet directly from your website.
                </p>
                
                <!-- Connect Wallet Code Block -->
                <div class="relative group">
                  <div class="absolute right-4 top-4 z-10">
                    <button 
                      @click="copyToClipboard(connectWalletCode)"
                      class="p-2 rounded-lg bg-gray-100 dark:bg-white/10 hover:bg-gray-200 dark:hover:bg-white/20 transition-colors opacity-0 group-hover:opacity-100"
                    >
                      <Icon icon="mdi:content-copy" class="text-gray-600 dark:text-gray-400" />
                    </button>
                  </div>
                  <div class="bg-gray-900 dark:bg-black/50 rounded-2xl p-6 overflow-x-auto border border-gray-800 dark:border-white/10">
                    <pre class="text-sm"><code class="language-html"><span class="text-gray-500">&lt;!-- This widget is optional. --&gt;</span>
<span class="text-gray-400">&lt;</span><span class="text-red-400">ping-connect-wallet</span> <span class="text-green-400">chain-id</span>=<span class="text-yellow-400">"{{ chainId }}"</span> <span class="text-green-400">hd-path</span>=<span class="text-yellow-400">"{{ hdPath }}"</span><span class="text-gray-400">/&gt;</span></code></pre>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Token Convert Widget -->
          <div>
            <div class="flex items-start gap-4 mb-4">
              <div class="flex-shrink-0 w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500/20 to-purple-500/20 flex items-center justify-center">
                <span class="text-lg font-bold text-indigo-600 dark:text-indigo-400">2</span>
              </div>
              <div class="flex-1">
                <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                  {{ $t('widget.text_3') }}
                </h4>
                <p class="text-gray-600 dark:text-gray-400 text-sm mb-4">
                  Enable token conversion functionality with a customizable buy button for your chain.
                </p>
                
                <!-- Token Convert Code Block -->
                <div class="relative group">
                  <div class="absolute right-4 top-4 z-10">
                    <button 
                      @click="copyToClipboard(tokenConvertCode)"
                      class="p-2 rounded-lg bg-gray-100 dark:bg-white/10 hover:bg-gray-200 dark:hover:bg-white/20 transition-colors opacity-0 group-hover:opacity-100"
                    >
                      <Icon icon="mdi:content-copy" class="text-gray-600 dark:text-gray-400" />
                    </button>
                  </div>
                  <div class="bg-gray-900 dark:bg-black/50 rounded-2xl p-6 overflow-x-auto border border-gray-800 dark:border-white/10">
                    <pre class="text-sm"><code class="language-html"><span class="text-gray-400">&lt;</span><span class="text-red-400">ping-token-convert</span> <span class="text-green-400">chain-name</span>=<span class="text-yellow-400">"{{ chainName }}"</span> <span class="text-green-400">endpoint</span>=<span class="text-yellow-400">"{{endpoint}}"</span> <span class="text-green-400">hd-path</span>=<span class="text-yellow-400">"{{hdPath}}"</span><span class="text-gray-400">/&gt;</span>
<span class="text-gray-400">&lt;</span><span class="text-red-400">label</span> <span class="text-green-400">for</span>=<span class="text-yellow-400">"PingTokenConvert"</span> <span class="text-green-400">class</span>=<span class="text-yellow-400">"btn btn-sm"</span><span class="text-gray-400">&gt;</span>Buy {{chainName.toUpperCase()}}<span class="text-gray-400">&lt;/</span><span class="text-red-400">label</span><span class="text-gray-400">&gt;</span></code></pre>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Usage Tips -->
    <div class="backdrop-blur-xl bg-gradient-to-r from-blue-500/10 to-cyan-500/10 rounded-3xl border border-blue-500/20 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-blue-500/10 to-cyan-500/10 rounded-full blur-2xl transform translate-x-24 -translate-y-24"></div>
      <div class="relative">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500/20 to-cyan-500/20 flex items-center justify-center">
            <Icon icon="mdi:information" class="text-2xl text-blue-600 dark:text-blue-400" />
          </div>
          <h3 class="text-lg font-bold text-blue-600 dark:text-blue-400">Integration Tips</h3>
        </div>
        <ul class="space-y-2 text-sm text-gray-700 dark:text-gray-300">
          <li class="flex items-start gap-2">
            <Icon icon="mdi:check" class="text-blue-600 dark:text-blue-400 mt-0.5" />
            <span>Make sure to include the widget script in the <code class="bg-blue-500/10 px-2 py-0.5 rounded text-xs">&lt;head&gt;</code> section of your HTML</span>
          </li>
          <li class="flex items-start gap-2">
            <Icon icon="mdi:check" class="text-blue-600 dark:text-blue-400 mt-0.5" />
            <span>Widgets are web components and work with any framework (React, Vue, vanilla HTML)</span>
          </li>
          <li class="flex items-start gap-2">
            <Icon icon="mdi:check" class="text-blue-600 dark:text-blue-400 mt-0.5" />
            <span>Customize the button styles to match your website's design system</span>
          </li>
          <li class="flex items-start gap-2">
            <Icon icon="mdi:check" class="text-blue-600 dark:text-blue-400 mt-0.5" />
            <span>Test the widgets with different wallets to ensure compatibility</span>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<route>
  {
    meta: {
      i18n: 'widget',
      order: 300
    }
  }
</route>