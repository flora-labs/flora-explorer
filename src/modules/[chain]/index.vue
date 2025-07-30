<script lang="ts" setup>
import { useBlockchain, useFormatter, useTxDialog, useWalletStore, useStakingStore, useParamStore, useBankStore, useMintStore, useGovStore } from '@/stores';
import { useDistributionStore } from '@/stores/useDistributionStore';
import { onMounted, ref, watchEffect } from 'vue';
import { computed } from '@vue/reactivity';
import { Icon } from '@iconify/vue';
import CardStatisticsVertical from '@/components/CardStatisticsVertical.vue';
import ProposalListItem from '@/components/ProposalListItem.vue';
import ArrayObjectElement from '@/components/dynamic/ArrayObjectElement.vue';
import DiscordBotAvatar from '@/assets/images/flora-bot-avatar-v3.jpg';

const props = defineProps(['chain']);

const blockchain = useBlockchain();
const walletStore = useWalletStore();
const format = useFormatter();
const dialog = useTxDialog();
const stakingStore = useStakingStore();
const paramStore = useParamStore();
const bankStore = useBankStore();
const mintStore = useMintStore();
const govStore = useGovStore();
const distributionStore = useDistributionStore();

// Create a reactive ref for supply
const totalSupply = ref('0');


// Version info
interface VersionInfo {
  version: string;
  gitHash: string;
  gitBranch: string;
  buildTime: string;
  deployTime: string;
}
const versionInfo = ref<VersionInfo | null>(null);

// Fetch version info
fetch('/version.json')
  .then(res => res.json())
  .then(data => versionInfo.value = data)
  .catch(() => console.log('Version info not available'));

// Create reactive ref for community pool
const communityPool = ref<{ amount: string; denom: string }[]>([]);

onMounted(async () => {
  walletStore.loadMyAsset();
  paramStore.handleAbciInfo();
  
  // Initialize bank store to fetch supply after a small delay to ensure blockchain is ready
  setTimeout(() => {
    bankStore?.initial();
  }, 500);
  
  // Also fetch supply directly
  try {
    const res = await blockchain.rpc.getBankSupply();
    if (res.supply) {
      const floraSupply = res.supply.find((s: any) => s.denom === 'uflora');
      if (floraSupply) {
        totalSupply.value = format.formatToken({ amount: floraSupply.amount, denom: 'uflora' });
      }
    }
  } catch (error) {
    console.error('Error fetching supply directly:', error);
  }
  
  // Fetch community pool data
  try {
    const res = await distributionStore.fetchCommunityPool();
    if (res?.pool) {
      communityPool.value = res.pool
        .filter((t: any) => t.denom.length < 10)
        .map((t: any) => ({
          amount: String(parseInt(t.amount)),
          denom: t.denom,
        }));
    }
  } catch (error) {
    console.error('Error fetching community pool:', error);
  }
});

// Watch for bank store changes
watchEffect(() => {
  // Also update totalSupply when bank store changes
  const supply = bankStore?.supply;
  if (supply?.amount && supply?.denom) {
    const formatted = format.formatToken({ amount: supply.amount, denom: supply.denom });
    totalSupply.value = formatted;
  }
});

// Simple stats without CoinGecko dependency
const floraStats = computed(() => {
  const supply = bankStore?.supply;
  const pool = stakingStore.pool;
  const inflation = mintStore?.inflation;
  
  return {
    totalSupply: totalSupply.value || (supply?.amount ? format.formatToken({ amount: supply.amount, denom: supply.denom || 'uflora' }) : '0'),
    bondedTokens: pool?.bonded_tokens ? format.formatToken({ amount: pool.bonded_tokens, denom: 'uflora' }) : '0',
    inflation: inflation ? `${(Number(inflation) * 100).toFixed(2)}%` : '0%',
    communityPool: communityPool.value && communityPool.value[0] ? format.formatToken(communityPool.value[0]) : '0'
  };
});
</script>

<template>
  <div class="min-h-screen">
    <!-- Background Effects -->
    <div class="fixed inset-0 -z-10">
      <!-- Light mode gradient - soft purple/blue gradient like Flora website -->
      <div class="absolute inset-0 bg-gradient-to-br from-purple-100 via-blue-50 to-indigo-100 dark:from-blue-900/10 dark:via-transparent dark:to-blue-900/10"></div>
      <!-- Overlay gradient for depth -->
      <div class="absolute inset-0 bg-gradient-to-t from-white/40 via-transparent to-white/20 dark:from-transparent dark:via-transparent dark:to-transparent"></div>
      <!-- Grid pattern -->
      <div class="absolute inset-0 bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:24px_24px]"></div>
    </div>
    
    <!-- Main Container -->
    <div class="container mx-auto px-4 py-8 relative">
      <!-- Consistent Layout Wrapper -->
      <div class="space-y-8">
        <!-- Header Section - Wrapped in same grid as content -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div v-if="blockchain.current" class="lg:col-span-3 backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-8 shadow-lg dark:shadow-2xl">
            <div class="flex justify-between items-start">
              <div>
                <div class="flex items-center gap-4 mb-3">
                  <img src="/logo.svg" class="w-12 h-12" alt="Flora Logo" />
                  <h1 class="text-5xl font-bold bg-gradient-to-r from-purple-400 via-blue-400 to-indigo-400 bg-clip-text text-transparent">
                    {{ blockchain.current?.prettyName || 'Flora' }}
                  </h1>
                </div>
                <p class="text-gray-600 dark:text-blue-200/70 ml-16">Explore blocks, transactions, and network statistics</p>
              </div>
              
              <!-- Action Icons Panel -->
              <div class="flex gap-4 items-center">
                <!-- Discord Bot Avatar -->
                <a 
                  href="https://discord.flora.network" 
                  target="_blank"
                  class="group relative backdrop-blur-xl bg-gradient-to-br from-indigo-500/20 to-purple-500/20 hover:from-indigo-500/30 hover:to-purple-500/30 rounded-full overflow-hidden border-2 border-indigo-500/30 transition-all duration-300 transform hover:scale-105"
                  title="Join Flora Discord"
                >
                  <img 
                    :src="DiscordBotAvatar" 
                    alt="Flora Discord Bot" 
                    class="w-16 h-16 object-cover"
                  />
                  <div class="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
                </a>
                
                <!-- AI Robot Avatar -->
                <a 
                  href="https://dev.flora.network"
                  target="_blank"
                  class="group relative backdrop-blur-xl bg-gradient-to-br from-blue-500/20 to-indigo-500/20 hover:from-blue-500/30 hover:to-indigo-500/30 rounded-full border-2 border-blue-500/30 transition-all duration-300 transform hover:scale-105 w-16 h-16 flex items-center justify-center"
                  title="Flora Dev Portal"
                >
                  <Icon icon="mdi:robot-excited" class="text-4xl text-blue-400 group-hover:text-blue-300 transition-colors" />
                </a>
              </div>
            </div>
          </div>
        </div>

        <!-- Top Statistics Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- Total Supply -->
        <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
          <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-purple-500/10 to-blue-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
          <div class="relative">
            <div class="flex items-center justify-between mb-2">
              <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Total Supply</div>
              <Icon icon="mdi:cash-multiple" class="text-2xl text-purple-500/70 dark:text-purple-400/70" />
            </div>
            <div class="text-2xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent">{{ floraStats.totalSupply }}</div>
          </div>
        </div>
        
        <!-- Bonded Tokens -->
        <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
          <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-blue-500/10 to-cyan-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
          <div class="relative">
            <div class="flex items-center justify-between mb-2">
              <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Bonded Tokens</div>
              <Icon icon="mdi:lock" class="text-2xl text-blue-500/70 dark:text-blue-400/70" />
            </div>
            <div class="text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 dark:from-blue-400 dark:to-cyan-400 bg-clip-text text-transparent">{{ floraStats.bondedTokens }}</div>
          </div>
        </div>
        
        <!-- Inflation -->
        <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
          <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-amber-500/10 to-orange-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
          <div class="relative">
            <div class="flex items-center justify-between mb-2">
              <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Inflation</div>
              <Icon icon="mdi:chart-line" class="text-2xl text-amber-500/70 dark:text-amber-400/70" />
            </div>
            <div class="text-2xl font-bold bg-gradient-to-r from-amber-600 to-orange-600 dark:from-amber-400 dark:to-orange-400 bg-clip-text text-transparent">{{ floraStats.inflation }}</div>
          </div>
        </div>
        
        <!-- Community Pool -->
        <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
          <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-green-500/10 to-emerald-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
          <div class="relative">
            <div class="flex items-center justify-between mb-2">
              <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Community Pool</div>
              <Icon icon="mdi:bank" class="text-2xl text-green-500/70 dark:text-green-400/70" />
            </div>
            <div class="text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 dark:from-green-400 dark:to-emerald-400 bg-clip-text text-transparent">{{ floraStats.communityPool }}</div>
          </div>
        </div>
        </div>

        <!-- Content Grid -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Main Content Area - 2 columns on large screens -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Stats Cards Section -->
          <div v-if="blockchain.supportModule('staking') || blockchain.supportModule('bank')" 
               class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
            <!-- Background decoration -->
            <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-blue-500/5 to-purple-500/5 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
            
            <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6 flex items-center gap-2">
              <svg class="w-5 h-5 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
              </svg>
              Network Statistics
            </h2>
            
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <CardStatisticsVertical
                v-if="blockchain.supportModule('staking')"
                :stats="format.formatToken({ amount: stakingStore.pool?.bonded_tokens || '0', denom: 'uflora' })"
                :change="Number(stakingStore.pool?.bonded_tokens || 0)"
                title="Bonded Tokens"
                subtitle="Total bonded tokens"
                :icon="'mdi:lock'"
                color="info"
                class="transition-all duration-200"
              />
              
              <CardStatisticsVertical
                v-if="blockchain.supportModule('bank')"
                :stats="totalSupply || '0'"
                title="Total Supply"
                subtitle="Total FLORA supply"
                :icon="'mdi:cash-multiple'"
                color="success"
                class="transition-all duration-200"
              />
              
              <CardStatisticsVertical
                v-if="blockchain.supportModule('mint')"
                :stats="`${(Number(mintStore?.inflation || 0) * 100).toFixed(2)}%`"
                title="Inflation"
                subtitle="Current inflation rate"
                :icon="'mdi:chart-line'"
                color="warning"
                class="transition-all duration-200"
              />
              
              <CardStatisticsVertical
                v-if="blockchain.supportModule('distribution')"
                :stats="format.formatToken((communityPool && communityPool[0]) || {})"
                title="Community Pool"
                subtitle="Available funds"
                :icon="'mdi:bank'"
                color="primary"
                class="transition-all duration-200"
              />
            </div>
          </div>

          <!-- Active Proposals -->
          <div v-if="blockchain.supportModule('governance')" 
               class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 overflow-hidden shadow-lg dark:shadow-none">
            <div class="p-6 border-b border-gray-200 dark:border-white/10">
              <h2 class="text-xl font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <svg class="w-5 h-5 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path>
                </svg>
                {{ $t('index.active_proposals') }}
              </h2>
            </div>
            <div class="p-6">
              <div v-if="govStore?.proposals?.['2'] && Array.isArray(govStore?.proposals?.['2']) && govStore?.proposals?.['2']?.length > 0" class="space-y-4">
                <ProposalListItem
                  v-for="(item, index) in govStore?.proposals?.['2'] || []"
                  :key="index"
                  :proposal="item"
                />
              </div>
              <div v-else class="text-center py-12">
                <svg class="w-16 h-16 text-gray-400 dark:text-gray-600 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"></path>
                </svg>
                <p class="text-gray-600 dark:text-gray-400">{{ $t('index.no_active_proposals') }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Sidebar - 1 column on large screens -->
        <div class="space-y-6">
          <!-- Wallet Section -->
          <div v-if="walletStore.currentAddress" 
               class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 overflow-hidden shadow-lg dark:shadow-none">
            <div class="p-6 border-b border-gray-200 dark:border-white/10">
              <h2 class="text-xl font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"></path>
                </svg>
                {{ $t('index.wallet') }}
              </h2>
            </div>
            <div class="p-6">
              <div class="space-y-4 mb-6">
                <div class="bg-gray-50 dark:bg-white/5 backdrop-blur rounded-xl p-4 border border-gray-200 dark:border-white/10">
                  <p class="text-sm text-gray-600 dark:text-gray-400">{{ format.formatToken(walletStore.balanceOfStakingToken) }}</p>
                  <p class="text-xl font-semibold text-gray-900 dark:text-white">{{ walletStore.balanceOfStakingToken.amount }}</p>
                </div>
              </div>
              
              <div class="grid grid-cols-1 gap-3">
                <button class="w-full backdrop-blur-md bg-blue-500/20 hover:bg-blue-500/30 text-blue-300 font-medium py-3 px-4 rounded-xl border border-blue-500/30 transition-all duration-200"
                        @click="dialog.open('send', {})">
                  {{ $t('account.send') }}
                </button>
                <button class="w-full backdrop-blur-md bg-purple-500/20 hover:bg-purple-500/30 text-purple-300 font-medium py-3 px-4 rounded-xl border border-purple-500/30 transition-all duration-200"
                        @click="dialog.open('delegate', {})">
                  {{ $t('account.delegate') }}
                </button>
                <button class="w-full backdrop-blur-md bg-cyan-500/20 hover:bg-cyan-500/30 text-cyan-300 font-medium py-3 px-4 rounded-xl border border-cyan-500/30 transition-all duration-200"
                        @click="dialog.open('transfer', {})">
                  {{ $t('account.transfer') }}
                </button>
              </div>
            </div>
          </div>

          <!-- Application Version -->
          <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 overflow-hidden shadow-lg dark:shadow-none">
            <div class="p-6 border-b border-gray-200 dark:border-white/10">
              <h2 class="text-xl font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <svg class="w-5 h-5 text-yellow-600 dark:text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                </svg>
                {{ $t('index.app_versions') }}
              </h2>
            </div>
            <div class="p-6">
              <ArrayObjectElement
                :value="paramStore.appVersion?.items"
                :thead="false"
              />
            </div>
          </div>

          <!-- Node Info -->
          <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 overflow-hidden shadow-lg dark:shadow-none">
            <div class="p-6 border-b border-gray-200 dark:border-white/10">
              <h2 class="text-xl font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <svg class="w-5 h-5 text-indigo-600 dark:text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01"></path>
                </svg>
                {{ $t('index.node_info') }}
              </h2>
            </div>
            <div class="p-6">
              <ArrayObjectElement
                :value="paramStore.nodeVersion?.items || {}"
              />
            </div>
          </div>
          
          <!-- Deployment Version -->
          <div v-if="versionInfo" class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 overflow-hidden shadow-lg dark:shadow-none">
            <div class="p-6">
              <h2 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2 flex items-center gap-2">
                <svg class="w-4 h-4 text-gray-600 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"></path>
                </svg>
                Deployment Version
              </h2>
              <div class="text-xs space-y-1 text-gray-600 dark:text-gray-400">
                <div>Build: <span class="font-mono">{{ versionInfo?.gitHash }}</span></div>
                <div>{{ versionInfo?.buildTime ? new Date(versionInfo.buildTime).toLocaleString() : '' }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- End Consistent Layout Wrapper -->
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Minimal custom styles - using Tailwind utilities primarily */
</style>

<route>
{
  "meta": {
    "i18n": "dashboard"
  }
}
</route>