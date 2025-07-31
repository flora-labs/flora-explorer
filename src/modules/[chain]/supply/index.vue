<script lang="ts" setup>
import { ref } from '@vue/reactivity';
import { useBlockchain, useFormatter } from '@/stores';
import {
  PageRequest,
  type Pagination,
  type Coin,
  type DenomMetadata,
} from '@/types';
import { onMounted } from 'vue';
import type { Asset } from '@/types/chaindata';
import PaginationBar from '@/components/PaginationBar.vue';
import { Icon } from '@iconify/vue';
const props = defineProps(['chain']);

const format = useFormatter();
const chainStore = useBlockchain();

const list = ref([] as { denom: string; amount: string; base: string; info: string; logo: string | undefined }[]);

const pageRequest = ref(new PageRequest());
pageRequest.value.limit = 100; // Show more tokens per page
const pageResponse = ref({} as Pagination);

interface SupplyAsset extends Asset {
  logo: string | undefined;
}

onMounted(() => {
  pageload(1);
});

function findGlobalAssetConfig(denom: string) {
  const assets = chainStore.current?.assets;
  if (assets) {
    const conf = assets.find((a) => a.base === denom);
    if (conf) {
      return conf;
    }
  }
  return undefined;
}

async function mergeDenomMetadata(denom: string, denomsMetadatas: DenomMetadata[]): Promise<SupplyAsset> {
  const denomMetadata = denomsMetadatas.find((d) => d.base === denom || d.base.endsWith(denom));
  let asset = findGlobalAssetConfig(denom) as SupplyAsset;
  if (asset && denomMetadata) {
    asset = { ...denomMetadata, ...asset };
    asset.display = denomMetadata.display;
    asset.logo = asset.logo_URIs?.svg || asset.logo_URIs?.png || undefined;
  } else if (denomMetadata) {
    return denomMetadata as SupplyAsset;
  }
  // Handle tokenfactory tokens
  if (!asset && denom.includes('factory/')) {
    const parts = denom.split('/');
    const tokenName = parts[parts.length - 1];
    return {
      base: denom,
      display: tokenName,
      symbol: tokenName,
      logo: undefined,
      logo_URIs: {}
    } as SupplyAsset;
  }
  return asset || { base: denom, display: denom, symbol: denom, logo: undefined } as SupplyAsset;
}

function pageload(p: number) {
  pageRequest.value.setPage(p);
  chainStore.rpc.getBankDenomMetadata().then(async (denomsMetaResponse) => {
    const bankSupplyResponse = await chainStore.rpc.getBankSupply(pageRequest.value);
    list.value = await Promise.all(
      bankSupplyResponse.supply.map(async (coin: Coin) => {
        const asset = await mergeDenomMetadata(coin.denom, denomsMetaResponse.metadatas);
        let displayDenom = asset?.symbol || coin.denom;
        
        // Special handling for tokenfactory tokens
        if (coin.denom.includes('factory/')) {
          const parts = coin.denom.split('/');
          displayDenom = parts[parts.length - 1].toUpperCase();
        } else if (displayDenom === 'FLORA' || coin.denom === 'uflora') {
          displayDenom = 'FLORA';
        } else {
          displayDenom = displayDenom.split('/')[displayDenom.split('/').length - 1].toUpperCase();
        }
        
        // Special formatting for FLORA to show proper decimal places
        let formattedAmount = '';
        if (coin.denom === 'uflora' || displayDenom === 'FLORA') {
          // For FLORA, divide by 10^18 and format with proper decimals
          const rawAmount = BigInt(coin.amount);
          const divisor = BigInt(10 ** 18);
          const wholePart = rawAmount / divisor;
          const fractionalPart = rawAmount % divisor;
          
          // Format the fractional part to always show 18 digits
          const fractionalStr = fractionalPart.toString().padStart(18, '0');
          
          // Remove trailing zeros but keep at least 2 decimal places
          let trimmedFractional = fractionalStr.replace(/0+$/, '');
          if (trimmedFractional.length < 2) {
            trimmedFractional = fractionalStr.substring(0, 2);
          }
          
          formattedAmount = `${wholePart.toLocaleString()}.${trimmedFractional}`;
        } else {
          formattedAmount = format.tokenAmountNumber({ amount: coin.amount, denom: asset?.symbol || coin.denom }).toString();
        }
        
        return {
          denom: displayDenom,
          amount: formattedAmount,
          base: asset.base || coin.denom,
          info: asset.display || coin.denom,
          logo: asset?.logo_URIs?.svg || asset?.logo_URIs?.png || (coin.denom === 'uflora' ? '/logo.svg' : undefined),
        };
      })
    );
    pageResponse.value = bankSupplyResponse.pagination;
  });
}
</script>
<template>
  <div class="space-y-2">
    <!-- Page Header -->
    <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-purple-50/90 to-blue-50/90 dark:from-white/5 dark:via-purple-900/10 dark:to-blue-900/10 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-purple-400/20 via-blue-400/15 to-pink-400/20 rounded-full blur-3xl transform translate-x-48 -translate-y-48 animate-pulse-slow"></div>
      <div class="absolute bottom-0 left-0 w-80 h-80 bg-gradient-to-tr from-blue-400/20 via-indigo-400/15 to-purple-400/20 rounded-full blur-3xl transform -translate-x-40 translate-y-40 animate-pulse-slow" style="animation-delay: 2s"></div>
      
      <div class="relative p-8">
        <div class="flex items-center gap-4">
          <div class="p-4 rounded-2xl bg-gradient-to-br from-purple-500/20 to-blue-500/20 backdrop-blur-sm">
            <Icon icon="mdi:cash-multiple" class="text-4xl text-purple-600 dark:text-purple-400" />
          </div>
          <div>
            <h1 class="text-3xl font-bold bg-gradient-to-r from-purple-600 via-blue-600 to-pink-600 dark:from-purple-400 dark:via-blue-400 dark:to-pink-400 bg-clip-text text-transparent animate-gradient">
              Token Supply
            </h1>
            <p class="text-gray-600 dark:text-gray-400 mt-1">Total supply of all tokens including base coin and tokenfactory tokens</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Supply Table -->
    <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-purple-500/5 to-blue-500/5 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
      
      <div class="relative">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="border-b border-gray-200 dark:border-white/10">
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-4 px-6 text-left">Logo</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-4 px-6 text-left">Token</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-4 px-6 text-right">Amount</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-4 px-6 text-left">Display Name</th>
                <th class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-4 px-6 text-left">Base Denom</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in list" :key="item.base" 
                class="border-b border-gray-100 dark:border-white/5 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors duration-200"
              >
                <td class="py-4 px-6">
                  <div class="w-10 h-10 rounded-full overflow-hidden bg-gradient-to-br from-purple-500/10 to-blue-500/10 flex items-center justify-center">
                    <img v-if="item.logo" :src="item.logo" class="w-8 h-8" />
                    <Icon v-else icon="mdi:currency-usd" class="text-xl text-purple-600 dark:text-purple-400" />
                  </div>
                </td>
                <td class="py-4 px-6">
                  <span class="font-semibold text-gray-900 dark:text-white">{{ item.denom }}</span>
                </td>
                <td class="py-4 px-6 text-right">
                  <span class="text-sm font-mono text-gray-900 dark:text-white">{{ item.amount }}</span>
                </td>
                <td class="py-4 px-6">
                  <span class="text-sm text-gray-600 dark:text-gray-400">{{ item.info }}</span>
                </td>
                <td class="py-4 px-6">
                  <span class="text-xs font-mono text-gray-500 dark:text-gray-500 break-all">{{ item.base }}</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        
        <div v-if="list.length === 0" class="p-12 text-center">
          <div class="inline-flex items-center justify-center w-20 h-20 rounded-full bg-gradient-to-br from-purple-500/10 to-blue-500/10 mb-4">
            <Icon icon="mdi:database-search-outline" class="text-4xl text-purple-500/50 dark:text-purple-400/50" />
          </div>
          <p class="text-gray-500 dark:text-gray-400 font-medium">Loading token supply...</p>
        </div>
        
        <div class="p-6">
          <PaginationBar
            :limit="pageRequest.limit"
            :total="pageResponse.total"
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

<route>
    {
      meta: {
        i18n: 'supply',
        order: 17
      }
    }
  </route>
