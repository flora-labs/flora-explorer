<script setup lang="ts">
import { computed, ref } from 'vue';
import { suggestChain } from '@leapwallet/cosmos-snap-provider';
import {
  useDashboard,
  useBlockchain,
} from '@/stores';
import type { ChainConfig } from '@/types/chaindata';
import { NetworkType } from '@/types/chaindata';
import { CosmosRestClient } from '@/libs/client';
import { onMounted } from 'vue';
import AdBanner from '@/components/ad/AdBanner.vue';
import { Icon } from '@iconify/vue';

const error = ref('');
const conf = ref('');
const dashboard = useDashboard();
const selected = ref({} as ChainConfig);
const wallet = ref('keplr');
const network = ref(NetworkType.Mainnet);
const mainnet = ref([] as ChainConfig[]);
const testnet = ref([] as ChainConfig[]);
const chains = computed(() => {
  return network.value === NetworkType.Mainnet ? mainnet.value : testnet.value;
});

onMounted(() => {
  const chainStore = useBlockchain();
  selected.value = chainStore.current || Object.values(dashboard.chains)[0];
  initParamsForKeplr();

  dashboard.loadLocalConfig(NetworkType.Mainnet).then((res) => {
    mainnet.value = Object.values<ChainConfig>(res);
  });
  dashboard.loadLocalConfig(NetworkType.Testnet).then((res) => {
    testnet.value = Object.values<ChainConfig>(res);
  });
});

function onchange() {
  wallet.value === 'keplr' ? initParamsForKeplr() : initSnap();
}

async function initParamsForKeplr() {
  const chain = selected.value;
  if (!chain.endpoints?.rest?.at(0)) throw new Error('Endpoint does not set');
  const client = CosmosRestClient.newDefault(chain.endpoints.rest?.at(0)?.address || '');
  const b = await client.getBaseBlockLatest();
  const chainid = b.block.header.chain_id;

  const gasPriceStep = chain.keplrPriceStep || {
    low: 0.01,
    average: 0.025,
    high: 0.03,
  };
  const coinDecimals =
    chain.assets[0].denom_units.find((x) => x.denom === chain.assets[0].symbol.toLowerCase())?.exponent || 6;
  conf.value = JSON.stringify(
    {
      chainId: chainid,
      chainName: chain.chainName,
      rpc: chain.endpoints?.rpc?.at(0)?.address,
      rest: chain.endpoints?.rest?.at(0)?.address,
      bip44: {
        coinType: Number(chain.coinType),
      },
      coinType: Number(chain.coinType),
      bech32Config: {
        bech32PrefixAccAddr: chain.bech32Prefix,
        bech32PrefixAccPub: `${chain.bech32Prefix}pub`,
        bech32PrefixValAddr: `${chain.bech32Prefix}valoper`,
        bech32PrefixValPub: `${chain.bech32Prefix}valoperpub`,
        bech32PrefixConsAddr: `${chain.bech32Prefix}valcons`,
        bech32PrefixConsPub: `${chain.bech32Prefix}valconspub`,
      },
      currencies: [
        {
          coinDenom: chain.assets[0].symbol,
          coinMinimalDenom: chain.assets[0].base,
          coinDecimals,
          coinGeckoId: chain.assets[0].coingecko_id || 'unknown',
        },
      ],
      feeCurrencies: [
        {
          coinDenom: chain.assets[0].symbol,
          coinMinimalDenom: chain.assets[0].base,
          coinDecimals,
          coinGeckoId: chain.assets[0].coingecko_id || 'unknown',
          gasPriceStep,
        },
      ],
      gasPriceStep,
      stakeCurrency: {
        coinDenom: chain.assets[0].symbol,
        coinMinimalDenom: chain.assets[0].base,
        coinDecimals,
        coinGeckoId: chain.assets[0].coingecko_id || 'unknown',
      },
      features: chain.keplrFeatures || [],
    },
    null,
    '\t'
  );
}

async function initSnap() {
  const chain = selected.value;
  const [token] = chain.assets;

  if (!chain.endpoints?.rest?.at(0)) throw new Error('Endpoint does not set');
  const client = CosmosRestClient.newDefault(chain.endpoints.rest?.at(0)?.address || '');
  const b = await client.getBaseBlockLatest();
  const chainId = b.block.header.chain_id;

  conf.value = JSON.stringify(
    {
      chainId,
      chainName: chain.chainName,
      bech32Config: {
        bech32PrefixAccAddr: chain.bech32Prefix,
      },
      bip44: {
        coinType: Number(chain.coinType),
      },
      feeCurrencies: [
        {
          coinDenom: token.display,
          coinMinimalDenom: token.base,
          coinDecimals: token.denom_units.find((x) => x.denom === token.display)?.exponent || 6,
          coinGeckoId: token.coingecko_id,
          gasPriceStep: {
            low: 0.0625,
            average: 0.5,
            high: 62.5,
          },
        },
      ],
    },
    null,
    '\t'
  );
}

function suggest() {
  if (wallet.value === 'keplr') {
    // @ts-ignore
    if (window.keplr) {
      // @ts-ignore
      window.keplr.experimentalSuggestChain(JSON.parse(conf.value)).catch((e) => {
        error.value = e;
      });
    }
  } else {
    // @ts-ignore - suggestChain might need a second parameter
    suggestChain(JSON.parse(conf.value), {});
  }
}
</script>

<template>
  <div class="min-h-screen py-12 relative">
    <!-- Background Effects -->
    <div class="absolute inset-0 -z-10 overflow-hidden">
      <div class="absolute inset-0 bg-gradient-to-br from-purple-100 via-blue-50 to-indigo-100 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900"></div>
      <div class="absolute inset-0 bg-gradient-to-t from-white/40 via-transparent to-white/20 dark:from-black/20 dark:via-transparent dark:to-transparent"></div>
      <div class="absolute inset-0 bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:24px_24px]"></div>
    </div>

    <div class="space-y-8">
      <!-- Page Header -->
      <div class="backdrop-blur-md bg-gradient-to-br from-white/95 via-purple-50/90 to-blue-50/90 dark:from-gray-800/90 dark:via-gray-800/80 dark:to-gray-900/90 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-purple-400/20 via-blue-400/15 to-pink-400/20 rounded-full blur-3xl transform translate-x-48 -translate-y-48 animate-pulse-slow"></div>
        <div class="absolute bottom-0 left-0 w-80 h-80 bg-gradient-to-tr from-blue-400/20 via-indigo-400/15 to-purple-400/20 rounded-full blur-3xl transform -translate-x-40 translate-y-40 animate-pulse-slow" style="animation-delay: 2s"></div>
        
        <div class="relative p-8">
          <div class="flex items-center gap-4">
            <div class="p-4 rounded-2xl bg-gradient-to-br from-purple-500/20 to-blue-500/20 backdrop-blur-sm">
              <Icon icon="mdi:wallet-plus" class="text-4xl text-purple-600 dark:text-purple-400" />
            </div>
            <div>
              <h1 class="text-3xl font-bold bg-gradient-to-r from-purple-600 via-blue-600 to-pink-600 dark:from-purple-400 dark:via-blue-400 dark:to-pink-400 bg-clip-text text-transparent animate-gradient">
                Wallet Integration
              </h1>
              <p class="text-gray-600 dark:text-gray-400 mt-1">Add chains to Keplr or MetaMask wallets</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Configuration Panel -->
      <div class="backdrop-blur-md bg-white/95 dark:bg-gray-800/90 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-purple-500/5 to-blue-500/5 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
        
        <div class="relative p-8">
          <!-- Selection Controls -->
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <!-- Network Selection -->
            <div class="space-y-2">
              <label class="text-sm font-medium text-gray-700 dark:text-gray-300">Network Type</label>
              <select v-model="network" 
                class="w-full px-4 py-3 rounded-xl bg-white/50 dark:bg-gray-700/50 backdrop-blur-sm border border-gray-200 dark:border-white/10 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-purple-500/50 transition-all duration-200"
              >
                <option :value="NetworkType.Mainnet">Mainnet</option>
                <option :value="NetworkType.Testnet">Testnet</option>
              </select>
            </div>

            <!-- Chain Selection -->
            <div class="space-y-2 lg:col-span-2">
              <label class="text-sm font-medium text-gray-700 dark:text-gray-300">Select Chain</label>
              <select v-model="selected" @change="onchange"
                class="w-full px-4 py-3 rounded-xl bg-white/50 dark:bg-gray-700/50 backdrop-blur-sm border border-gray-200 dark:border-white/10 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-purple-500/50 transition-all duration-200"
              >
                <option v-for="c in chains" :key="c.chainName" :value="c">
                  {{ c.chainName }}
                </option>
              </select>
            </div>

            <!-- Wallet Selection -->
            <div class="space-y-2">
              <label class="text-sm font-medium text-gray-700 dark:text-gray-300">Wallet Type</label>
              <div class="flex gap-4">
                <label 
                  :class="[
                    'flex items-center px-4 py-3 rounded-xl cursor-pointer transition-all duration-200 border backdrop-blur-sm',
                    wallet === 'keplr' ? 'bg-purple-500/20 border-purple-500' : 'bg-white/50 dark:bg-gray-700/50 border-gray-200 dark:border-white/10'
                  ]"
                >
                  <input type="radio" v-model="wallet" value="keplr" @change="onchange" class="sr-only" />
                  <Icon icon="mdi:alpha-k-circle" class="text-xl mr-2" 
                    :class="wallet === 'keplr' ? 'text-purple-600 dark:text-purple-400' : 'text-gray-600 dark:text-gray-400'" 
                  />
                  <span :class="wallet === 'keplr' ? 'text-gray-900 dark:text-white font-medium' : 'text-gray-600 dark:text-gray-400'">
                    Keplr
                  </span>
                </label>
                
                <label 
                  :class="[
                    'flex items-center px-4 py-3 rounded-xl cursor-pointer transition-all duration-200 border backdrop-blur-sm',
                    wallet === 'metamask' ? 'bg-orange-500/20 border-orange-500' : 'bg-white/50 dark:bg-gray-700/50 border-gray-200 dark:border-white/10'
                  ]"
                >
                  <input type="radio" v-model="wallet" value="metamask" @change="onchange" class="sr-only" />
                  <Icon icon="simple-icons:metamask" class="text-xl mr-2" 
                    :class="wallet === 'metamask' ? 'text-orange-600 dark:text-orange-400' : 'text-gray-600 dark:text-gray-400'" 
                  />
                  <span :class="wallet === 'metamask' ? 'text-gray-900 dark:text-white font-medium' : 'text-gray-600 dark:text-gray-400'">
                    MetaMask
                  </span>
                </label>
              </div>
            </div>
          </div>

          <!-- Configuration Display -->
          <div class="space-y-4">
            <div class="flex items-center justify-between">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Chain Configuration</h3>
              <button 
                @click="$refs.configTextarea.select(); document.execCommand('copy')"
                class="flex items-center gap-2 px-4 py-2 rounded-lg bg-white/50 dark:bg-gray-700/50 backdrop-blur-sm border border-gray-200 dark:border-white/10 hover:bg-white/70 dark:hover:bg-gray-600/50 transition-all duration-200"
              >
                <Icon icon="mdi:content-copy" class="text-lg text-gray-600 dark:text-gray-400" />
                <span class="text-sm text-gray-600 dark:text-gray-400">Copy</span>
              </button>
            </div>
            
            <textarea 
              ref="configTextarea"
              v-model="conf" 
              class="w-full p-6 rounded-2xl bg-gray-900/5 dark:bg-gray-700/50 backdrop-blur-sm border border-gray-200 dark:border-white/10 text-gray-900 dark:text-gray-100 font-mono text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/50 transition-all duration-200 resize-none"
              rows="20"
              readonly
            ></textarea>
          </div>

          <!-- Action Section -->
          <div class="mt-8 space-y-6">
            <div class="flex flex-col sm:flex-row gap-4 items-center justify-center">
              <button 
                @click="suggest"
                class="group relative px-8 py-4 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white font-semibold rounded-xl shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200 overflow-hidden"
              >
                <span class="relative z-10 flex items-center gap-2">
                  <Icon icon="mdi:rocket-launch" class="text-xl" />
                  Suggest {{ selected.chainName }} to {{ wallet === 'keplr' ? 'Keplr' : 'MetaMask' }}
                </span>
                <div class="absolute inset-0 bg-gradient-to-r from-purple-400 to-blue-400 opacity-0 group-hover:opacity-20 transition-opacity duration-300"></div>
              </button>
            </div>

            <div v-if="error" class="p-4 rounded-xl bg-red-500/10 border border-red-500/20 backdrop-blur-sm">
              <p class="text-red-600 dark:text-red-400 text-sm">{{ error }}</p>
            </div>

            <div class="text-center">
              <p class="text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
                If the chain is not officially supported on {{ wallet === 'keplr' ? 'Keplr' : 'MetaMask Snap' }}, 
                you can submit these parameters to enable wallet integration.
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Ad Banner -->
      <div class="backdrop-blur-md bg-white/95 dark:bg-gray-800/90 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none overflow-hidden">
        <div class="p-6 flex justify-center">
          <AdBanner id="suggest-banner-ad" unit="banner" width="970px" height="90px" />
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

/* Custom select styling */
select {
  background-image: url("data:image/svg+xml;charset=UTF-8,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3e%3cpolyline points='6 9 12 15 18 9'%3e%3c/polyline%3e%3c/svg%3e");
  background-repeat: no-repeat;
  background-position: right 1rem center;
  background-size: 1em;
  padding-right: 2.5rem;
  -webkit-appearance: none;
  -moz-appearance: none;
  appearance: none;
}

/* Hover effects for interactive elements */
button, select, textarea {
  transition: all 0.2s ease;
}

button:active {
  transform: scale(0.98);
}

/* Focus styles */
:focus {
  outline: none;
}
</style>
