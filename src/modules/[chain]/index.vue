<script lang="ts" setup>
import { useBlockchain, useFormatter, useTxDialog, useWalletStore, useStakingStore, useParamStore, useBankStore, useMintStore, useGovStore, useBaseStore } from '@/stores';
import { useDistributionStore } from '@/stores/useDistributionStore';
import { onMounted, ref, watchEffect, watch } from 'vue';
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
const baseStore = useBaseStore();

// Create a reactive ref for supply
const totalSupply = ref('0');

// Animation states
const animatedHeight = ref(0);
const animatedSupply = ref(0);
const animatedBonded = ref(0);
const animatedPool = ref(0);
const isLoading = ref(true);

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

// Animate number counting
function animateValue(start: number, end: number, duration: number, callback: (value: number) => void) {
  const range = end - start;
  const startTime = performance.now();
  
  function updateValue(currentTime: number) {
    const elapsed = currentTime - startTime;
    const progress = Math.min(elapsed / duration, 1);
    
    // Easing function for smooth animation
    const easeOutQuart = 1 - Math.pow(1 - progress, 4);
    const value = start + (range * easeOutQuart);
    
    callback(value);
    
    if (progress < 1) {
      requestAnimationFrame(updateValue);
    }
  }
  
  requestAnimationFrame(updateValue);
}

// Watch for block height changes and animate
watch(() => baseStore.latest?.block?.header?.height, (newVal) => {
  if (newVal) {
    const target = parseInt(newVal);
    animateValue(animatedHeight.value || target - 100, target, 1500, (v) => {
      animatedHeight.value = Math.floor(v);
    });
  }
});

onMounted(async () => {
  walletStore.loadMyAsset();
  paramStore.handleAbciInfo();
  
  // Remove loading state after delay
  setTimeout(() => {
    isLoading.value = false;
  }, 1000);
  
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
  <div class="min-h-screen py-4 sm:py-8 lg:py-12">
    <!-- Background Effects -->
    <div class="fixed inset-0 -z-10">
      <!-- Light mode gradient - soft purple/blue gradient like Flora website -->
      <div class="absolute inset-0 bg-gradient-to-br from-purple-100 via-blue-50 to-indigo-100 dark:from-blue-900/10 dark:via-transparent dark:to-blue-900/10"></div>
      <!-- Overlay gradient for depth -->
      <div class="absolute inset-0 bg-gradient-to-t from-white/40 via-transparent to-white/20 dark:from-transparent dark:via-transparent dark:to-transparent"></div>
      <!-- Grid pattern -->
      <div class="absolute inset-0 bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:24px_24px]"></div>
      <!-- Floating orbs for animation -->
      <div class="absolute top-20 left-20 w-72 h-72 bg-purple-300/20 dark:bg-purple-600/10 rounded-full blur-3xl animate-float-slow"></div>
      <div class="absolute bottom-20 right-20 w-96 h-96 bg-blue-300/20 dark:bg-blue-600/10 rounded-full blur-3xl animate-float-slower"></div>
    </div>
    
    <!-- Content - Mobile Optimized -->
    <div class="space-y-4 sm:space-y-6 lg:space-y-8">
        <!-- Header Section - Modern Glassmorphic Design -->
        <div v-if="blockchain.current" class="relative overflow-hidden rounded-2xl sm:rounded-3xl p-4 sm:p-6 lg:p-8 bg-gradient-to-br from-white/70 via-white/60 to-white/50 dark:from-gray-900/80 dark:via-gray-900/70 dark:to-gray-900/60 backdrop-blur-sm border border-white/50 dark:border-white/10 shadow-[0_8px_32px_0_rgba(31,38,135,0.37)] dark:shadow-2xl before:absolute before:inset-0 before:bg-gradient-to-br before:from-blue-50/30 before:via-transparent before:to-purple-50/30 dark:before:from-blue-900/10 dark:before:to-purple-900/10 before:-z-10 animate-slide-down">
            <!-- Animated gradient orb -->
            <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-blue-400/20 via-purple-400/20 to-pink-400/20 dark:from-blue-600/10 dark:via-purple-600/10 dark:to-pink-600/10 rounded-full blur-3xl transform translate-x-48 -translate-y-48 animate-pulse-slow"></div>
            <div class="flex flex-col sm:flex-row sm:justify-between sm:items-start gap-4 relative z-10">
              <!-- Main Content -->
              <div class="flex-1">
                <div class="flex items-center gap-3 sm:gap-4 mb-3 sm:mb-4">
                  <img src="/logo.svg" class="w-8 h-8 sm:w-10 sm:h-10 lg:w-12 lg:h-12 hover:scale-110 transition-transform duration-300" alt="Flora Logo" />
                  <h1 class="text-2xl sm:text-3xl lg:text-5xl font-bold bg-gradient-to-r from-purple-400 via-blue-400 to-indigo-400 bg-clip-text text-transparent animate-gradient">
                    {{ blockchain.current?.prettyName || 'Flora' }}
                  </h1>
                </div>
              </div>
              
              <!-- Action Icons Panel - Responsive -->
              <div class="flex gap-3 sm:gap-4 items-center justify-end sm:justify-start">
                <!-- Discord Bot Avatar -->
                <a 
                  href="https://discord.flora.network" 
                  target="_blank"
                  class="group relative backdrop-blur-sm bg-gradient-to-br from-indigo-500/30 to-purple-500/30 hover:from-indigo-500/40 hover:to-purple-500/40 rounded-full overflow-hidden border-2 border-indigo-500/30 transition-all duration-300 transform hover:scale-110 hover:rotate-3"
                  title="Join Flora Discord"
                >
                  <img 
                    :src="DiscordBotAvatar" 
                    alt="Flora Discord Bot" 
                    class="w-10 h-10 sm:w-12 sm:h-12 lg:w-16 lg:h-16 object-cover"
                  />
                  <div class="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
                </a>
                
                <!-- AI Robot Avatar -->
                <a 
                  href="https://dev.flora.network"
                  target="_blank"
                  class="group relative backdrop-blur-sm bg-gradient-to-br from-blue-500/30 to-indigo-500/30 hover:from-blue-500/40 hover:to-indigo-500/40 rounded-full border-2 border-blue-500/30 transition-all duration-300 transform hover:scale-110 hover:-rotate-3 w-10 h-10 sm:w-12 sm:h-12 lg:w-16 lg:h-16 flex items-center justify-center"
                  title="Flora Dev Portal"
                >
                  <Icon icon="mdi:robot-excited" class="text-2xl sm:text-3xl lg:text-4xl text-blue-400 group-hover:text-blue-300 transition-colors" />
                </a>
              </div>
            </div>
        </div>

        <!-- Top Statistics Grid - Icy Glassmorphic with animations -->
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 lg:gap-5">
        <!-- Block Height -->
        <div class="stat-card relative overflow-hidden rounded-2xl sm:rounded-3xl p-3 sm:p-4 lg:p-6 bg-gradient-to-br from-white/80 via-white/70 to-white/60 dark:from-gray-900/70 dark:via-gray-900/60 dark:to-gray-900/50 backdrop-blur-sm border border-white/60 dark:border-white/10 shadow-[0_8px_32px_0_rgba(31,38,135,0.15)] dark:shadow-none before:absolute before:inset-0 before:bg-gradient-to-br before:from-amber-50/20 before:to-orange-50/20 dark:before:from-amber-900/5 dark:before:to-orange-900/5 before:-z-10 hover:shadow-[0_8px_32px_0_rgba(31,38,135,0.25)] hover:scale-[1.02] hover:-translate-y-1 transition-all duration-500 group animate-slide-up" style="animation-delay: 100ms;">
          <!-- Shimmer effect -->
          <div class="absolute inset-0 -translate-x-full group-hover:translate-x-full transition-transform duration-1000 bg-gradient-to-r from-transparent via-white/30 to-transparent"></div>
          <div class="absolute top-0 right-0 w-20 sm:w-24 lg:w-32 h-20 sm:h-24 lg:h-32 bg-gradient-to-br from-amber-400/20 to-orange-400/20 dark:from-amber-500/10 dark:to-orange-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8 animate-pulse-slow"></div>
          <div class="relative z-10">
            <div class="flex items-center justify-between mb-1 sm:mb-2">
              <div class="text-xs sm:text-sm text-gray-600 dark:text-gray-400 font-medium">Block Height</div>
              <Icon icon="mdi:cube-outline" class="text-lg sm:text-xl lg:text-2xl text-amber-500/70 dark:text-amber-400/70" />
            </div>
            <div class="text-base sm:text-xl lg:text-2xl font-bold bg-gradient-to-r from-amber-600 to-orange-600 dark:from-amber-400 dark:to-orange-400 bg-clip-text text-transparent truncate">
              <span v-if="isLoading" class="inline-block w-20 h-6 bg-gradient-to-r from-gray-200 to-gray-300 dark:from-gray-700 dark:to-gray-600 rounded animate-pulse"></span>
              <span v-else class="transition-all duration-300 inline-block group-hover:scale-110">
                #{{ animatedHeight || baseStore.latest?.block?.header?.height || '0' }}
              </span>
            </div>
          </div>
        </div>
        
        <!-- Total Supply -->
        <div class="stat-card relative overflow-hidden rounded-2xl sm:rounded-3xl p-3 sm:p-4 lg:p-6 bg-gradient-to-br from-white/80 via-white/70 to-white/60 dark:from-gray-900/70 dark:via-gray-900/60 dark:to-gray-900/50 backdrop-blur-sm border border-white/60 dark:border-white/10 shadow-[0_8px_32px_0_rgba(31,38,135,0.15)] dark:shadow-none before:absolute before:inset-0 before:bg-gradient-to-br before:from-purple-50/20 before:to-blue-50/20 dark:before:from-purple-900/5 dark:before:to-blue-900/5 before:-z-10 hover:shadow-[0_8px_32px_0_rgba(31,38,135,0.25)] hover:scale-[1.02] hover:-translate-y-1 transition-all duration-500 group animate-slide-up" style="animation-delay: 200ms;">
          <!-- Shimmer effect -->
          <div class="absolute inset-0 -translate-x-full group-hover:translate-x-full transition-transform duration-1000 bg-gradient-to-r from-transparent via-white/30 to-transparent"></div>
          <div class="absolute top-0 right-0 w-20 sm:w-24 lg:w-32 h-20 sm:h-24 lg:h-32 bg-gradient-to-br from-purple-400/20 to-blue-400/20 dark:from-purple-500/10 dark:to-blue-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8 animate-pulse-slow"></div>
          <div class="relative z-10">
            <div class="flex items-center justify-between mb-1 sm:mb-2">
              <div class="text-xs sm:text-sm text-gray-600 dark:text-gray-400 font-medium">Total Supply</div>
              <Icon icon="mdi:cash-multiple" class="text-lg sm:text-xl lg:text-2xl text-purple-500/70 dark:text-purple-400/70" />
            </div>
            <div class="text-base sm:text-xl lg:text-2xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent truncate">
              <span v-if="isLoading" class="inline-block w-24 h-6 bg-gradient-to-r from-gray-200 to-gray-300 dark:from-gray-700 dark:to-gray-600 rounded animate-pulse"></span>
              <span v-else class="transition-all duration-300 inline-block group-hover:scale-110">
                {{ floraStats.totalSupply }}
              </span>
            </div>
          </div>
        </div>
        
        <!-- Bonded Tokens -->
        <div class="stat-card relative overflow-hidden rounded-2xl sm:rounded-3xl p-3 sm:p-4 lg:p-6 bg-gradient-to-br from-white/80 via-white/70 to-white/60 dark:from-gray-900/70 dark:via-gray-900/60 dark:to-gray-900/50 backdrop-blur-sm border border-white/60 dark:border-white/10 shadow-[0_8px_32px_0_rgba(31,38,135,0.15)] dark:shadow-none before:absolute before:inset-0 before:bg-gradient-to-br before:from-blue-50/20 before:to-cyan-50/20 dark:before:from-blue-900/5 dark:before:to-cyan-900/5 before:-z-10 hover:shadow-[0_8px_32px_0_rgba(31,38,135,0.25)] hover:scale-[1.02] hover:-translate-y-1 transition-all duration-500 group animate-slide-up" style="animation-delay: 300ms;">
          <!-- Shimmer effect -->
          <div class="absolute inset-0 -translate-x-full group-hover:translate-x-full transition-transform duration-1000 bg-gradient-to-r from-transparent via-white/30 to-transparent"></div>
          <div class="absolute top-0 right-0 w-20 sm:w-24 lg:w-32 h-20 sm:h-24 lg:h-32 bg-gradient-to-br from-blue-400/20 to-cyan-400/20 dark:from-blue-500/10 dark:to-cyan-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8 animate-pulse-slow"></div>
          <div class="relative z-10">
            <div class="flex items-center justify-between mb-1 sm:mb-2">
              <div class="text-xs sm:text-sm text-gray-600 dark:text-gray-400 font-medium">Bonded Tokens</div>
              <Icon icon="mdi:lock" class="text-lg sm:text-xl lg:text-2xl text-blue-500/70 dark:text-blue-400/70" />
            </div>
            <div class="text-base sm:text-xl lg:text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 dark:from-blue-400 dark:to-cyan-400 bg-clip-text text-transparent truncate">
              <span v-if="isLoading" class="inline-block w-24 h-6 bg-gradient-to-r from-gray-200 to-gray-300 dark:from-gray-700 dark:to-gray-600 rounded animate-pulse"></span>
              <span v-else class="transition-all duration-300 inline-block group-hover:scale-110">
                {{ floraStats.bondedTokens }}
              </span>
            </div>
          </div>
        </div>
        
        <!-- Community Pool -->
        <div class="stat-card relative overflow-hidden rounded-2xl sm:rounded-3xl p-3 sm:p-4 lg:p-6 bg-gradient-to-br from-white/80 via-white/70 to-white/60 dark:from-gray-900/70 dark:via-gray-900/60 dark:to-gray-900/50 backdrop-blur-sm border border-white/60 dark:border-white/10 shadow-[0_8px_32px_0_rgba(31,38,135,0.15)] dark:shadow-none before:absolute before:inset-0 before:bg-gradient-to-br before:from-green-50/20 before:to-emerald-50/20 dark:before:from-green-900/5 dark:before:to-emerald-900/5 before:-z-10 hover:shadow-[0_8px_32px_0_rgba(31,38,135,0.25)] hover:scale-[1.02] hover:-translate-y-1 transition-all duration-500 group animate-slide-up" style="animation-delay: 400ms;">
          <!-- Shimmer effect -->
          <div class="absolute inset-0 -translate-x-full group-hover:translate-x-full transition-transform duration-1000 bg-gradient-to-r from-transparent via-white/30 to-transparent"></div>
          <div class="absolute top-0 right-0 w-20 sm:w-24 lg:w-32 h-20 sm:h-24 lg:h-32 bg-gradient-to-br from-green-400/20 to-emerald-400/20 dark:from-green-500/10 dark:to-emerald-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8 animate-pulse-slow"></div>
          <div class="relative z-10">
            <div class="flex items-center justify-between mb-1 sm:mb-2">
              <div class="text-xs sm:text-sm text-gray-600 dark:text-gray-400 font-medium">Community Pool</div>
              <Icon icon="mdi:bank" class="text-lg sm:text-xl lg:text-2xl text-green-500/70 dark:text-green-400/70" />
            </div>
            <div class="text-base sm:text-xl lg:text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 dark:from-green-400 dark:to-emerald-400 bg-clip-text text-transparent truncate">
              <span v-if="isLoading" class="inline-block w-24 h-6 bg-gradient-to-r from-gray-200 to-gray-300 dark:from-gray-700 dark:to-gray-600 rounded animate-pulse"></span>
              <span v-else class="transition-all duration-300 inline-block group-hover:scale-110">
                {{ floraStats.communityPool }}
              </span>
            </div>
          </div>
        </div>
        </div>

        <!-- Content Grid - Mobile Optimized -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 sm:gap-5 lg:gap-6">
        <!-- Main Content Area - Mobile Optimized -->
        <div class="lg:col-span-2 space-y-4 sm:space-y-5 lg:space-y-6">
          <!-- Stats Cards Section - Icy Glassmorphic -->
          <div v-if="blockchain.supportModule('staking') || blockchain.supportModule('bank')" 
               class="relative overflow-hidden rounded-2xl sm:rounded-3xl p-4 sm:p-5 lg:p-6 bg-gradient-to-br from-white/80 via-white/70 to-white/60 dark:from-gray-900/80 dark:via-gray-900/70 dark:to-gray-900/60 backdrop-blur-sm border border-white/60 dark:border-white/10 shadow-[0_8px_32px_0_rgba(31,38,135,0.15)] dark:shadow-none before:absolute before:inset-0 before:bg-gradient-to-br before:from-blue-50/10 before:via-transparent before:to-purple-50/10 dark:before:from-blue-900/5 dark:before:to-purple-900/5 before:-z-10 hover:scale-[1.01] transition-all duration-500 animate-fade-in group">
            <!-- Background decoration -->
            <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-blue-400/10 to-purple-400/10 dark:from-blue-500/5 dark:to-purple-500/5 rounded-full blur-3xl transform translate-x-32 -translate-y-32 animate-float-slow"></div>
            
            <h2 class="text-lg sm:text-xl font-semibold text-gray-900 dark:text-white mb-4 sm:mb-5 lg:mb-6 flex items-center gap-2">
              <svg class="w-5 h-5 text-blue-600 dark:text-blue-400 animate-pulse-slow" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
              </svg>
              Network Statistics
            </h2>
            
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4">
              <CardStatisticsVertical
                v-if="blockchain.supportModule('staking')"
                :stats="format.formatToken({ amount: stakingStore.pool?.bonded_tokens || '0', denom: 'uflora' })"
                :change="Number(stakingStore.pool?.bonded_tokens || 0)"
                title="Bonded Tokens"
                subtitle="Total bonded tokens"
                :icon="'mdi:lock'"
                color="info"
                class="transition-all duration-200 hover:scale-[1.02]"
              />
              
              <CardStatisticsVertical
                v-if="blockchain.supportModule('bank')"
                :stats="totalSupply || '0'"
                title="Total Supply"
                subtitle="Total FLORA supply"
                :icon="'mdi:cash-multiple'"
                color="success"
                class="transition-all duration-200 hover:scale-[1.02]"
              />
              
              <CardStatisticsVertical
                v-if="blockchain.supportModule('mint')"
                :stats="`${(Number(mintStore?.inflation || 0) * 100).toFixed(2)}%`"
                title="Inflation"
                subtitle="Current inflation rate"
                :icon="'mdi:chart-line'"
                color="warning"
                class="transition-all duration-200 hover:scale-[1.02]"
              />
              
              <CardStatisticsVertical
                v-if="blockchain.supportModule('distribution')"
                :stats="format.formatToken((communityPool && communityPool[0]) || {})"
                title="Community Pool"
                subtitle="Available funds"
                :icon="'mdi:bank'"
                color="primary"
                class="transition-all duration-200 hover:scale-[1.02]"
              />
            </div>
          </div>

          <!-- Active Proposals - Icy Glassmorphic -->
          <div v-if="blockchain.supportModule('governance')" 
               class="relative overflow-hidden rounded-2xl sm:rounded-3xl bg-gradient-to-br from-white/50 via-white/30 to-white/20 dark:from-white/10 dark:via-white/5 dark:to-white/5 backdrop-blur-xl border border-white/60 dark:border-white/10 shadow-[0_8px_32px_0_rgba(31,38,135,0.15)] dark:shadow-none hover:scale-[1.01] transition-all duration-500 animate-fade-in group">
            <div class="p-4 sm:p-5 lg:p-6 border-b border-gray-200 dark:border-white/10">
              <h2 class="text-lg sm:text-xl font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <svg class="w-5 h-5 text-purple-600 dark:text-purple-400 animate-pulse-slow" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path>
                </svg>
                {{ $t('index.active_proposals') }}
              </h2>
            </div>
            <div class="p-4 sm:p-5 lg:p-6">
              <div v-if="govStore?.proposals?.['2'] && Array.isArray(govStore?.proposals?.['2']) && govStore?.proposals?.['2']?.length > 0" class="space-y-4">
                <ProposalListItem
                  v-for="(item, index) in govStore?.proposals?.['2'] || []"
                  :key="index"
                  :proposal="item"
                />
              </div>
              <div v-else class="text-center py-12">
                <svg class="w-16 h-16 text-gray-400 dark:text-gray-600 mx-auto mb-4 animate-float" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"></path>
                </svg>
                <p class="text-gray-600 dark:text-gray-400">{{ $t('index.no_active_proposals') }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Sidebar - Mobile Optimized -->
        <div class="space-y-4 sm:space-y-5 lg:space-y-6">
          <!-- Wallet Section - Icy Glassmorphic -->
          <div v-if="walletStore.currentAddress" 
               class="relative overflow-hidden rounded-2xl sm:rounded-3xl bg-gradient-to-br from-white/50 via-white/30 to-white/20 dark:from-white/10 dark:via-white/5 dark:to-white/5 backdrop-blur-xl border border-white/60 dark:border-white/10 shadow-[0_8px_32px_0_rgba(31,38,135,0.15)] dark:shadow-none hover:scale-[1.01] transition-all duration-500 animate-fade-in group">
            <div class="p-4 sm:p-5 lg:p-6 border-b border-gray-200 dark:border-white/10">
              <h2 class="text-lg sm:text-xl font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <svg class="w-5 h-5 text-green-600 dark:text-green-400 animate-pulse-slow" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"></path>
                </svg>
                {{ $t('index.wallet') }}
              </h2>
            </div>
            <div class="p-4 sm:p-5 lg:p-6">
              <div class="space-y-3 sm:space-y-4 mb-4 sm:mb-5 lg:mb-6">
                <div class="bg-gray-50 dark:bg-white/5 backdrop-blur rounded-xl p-3 sm:p-4 border border-gray-200 dark:border-white/10 group-hover:bg-gray-100 dark:group-hover:bg-white/10 transition-colors duration-300">
                  <p class="text-xs sm:text-sm text-gray-600 dark:text-gray-400">{{ format.formatToken(walletStore.balanceOfStakingToken) }}</p>
                  <p class="text-lg sm:text-xl font-semibold text-gray-900 dark:text-white">{{ walletStore.balanceOfStakingToken.amount }}</p>
                </div>
              </div>
              
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 sm:gap-4">
                <button class="w-full backdrop-blur-md bg-blue-500/20 hover:bg-blue-500/30 text-blue-600 dark:text-blue-300 font-medium py-2.5 sm:py-3 px-3 sm:px-4 rounded-xl border border-blue-500/30 transition-all duration-200 text-sm sm:text-base hover:scale-105 hover:shadow-lg"
                        @click="dialog.open('send', {})">
                  {{ $t('account.send') }}
                </button>
                <button class="w-full backdrop-blur-md bg-purple-500/20 hover:bg-purple-500/30 text-purple-600 dark:text-purple-300 font-medium py-2.5 sm:py-3 px-3 sm:px-4 rounded-xl border border-purple-500/30 transition-all duration-200 text-sm sm:text-base hover:scale-105 hover:shadow-lg"
                        @click="dialog.open('delegate', {})">
                  {{ $t('account.delegate') }}
                </button>
                <button class="w-full backdrop-blur-md bg-cyan-500/20 hover:bg-cyan-500/30 text-cyan-600 dark:text-cyan-300 font-medium py-2.5 sm:py-3 px-3 sm:px-4 rounded-xl border border-cyan-500/30 transition-all duration-200 text-sm sm:text-base hover:scale-105 hover:shadow-lg"
                        @click="dialog.open('transfer', {})">
                  {{ $t('account.transfer') }}
                </button>
              </div>
            </div>
          </div>

          <!-- Application Version - Icy Glassmorphic -->
          <div class="relative overflow-hidden rounded-2xl sm:rounded-3xl bg-gradient-to-br from-white/50 via-white/30 to-white/20 dark:from-white/10 dark:via-white/5 dark:to-white/5 backdrop-blur-xl border border-white/60 dark:border-white/10 shadow-[0_8px_32px_0_rgba(31,38,135,0.15)] dark:shadow-none hover:scale-[1.01] transition-all duration-500 animate-fade-in">
            <div class="p-4 sm:p-5 lg:p-6 border-b border-gray-200 dark:border-white/10">
              <h2 class="text-lg sm:text-xl font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <svg class="w-5 h-5 text-yellow-600 dark:text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                </svg>
                {{ $t('index.app_versions') }}
              </h2>
            </div>
            <div class="p-4 sm:p-5 lg:p-6">
              <ArrayObjectElement
                :value="paramStore.appVersion?.items"
                :thead="false"
              />
            </div>
          </div>

          <!-- Node Info - Icy Glassmorphic -->
          <div class="relative overflow-hidden rounded-2xl sm:rounded-3xl bg-gradient-to-br from-white/50 via-white/30 to-white/20 dark:from-white/10 dark:via-white/5 dark:to-white/5 backdrop-blur-xl border border-white/60 dark:border-white/10 shadow-[0_8px_32px_0_rgba(31,38,135,0.15)] dark:shadow-none hover:scale-[1.01] transition-all duration-500 animate-fade-in">
            <div class="p-4 sm:p-5 lg:p-6 border-b border-gray-200 dark:border-white/10">
              <h2 class="text-lg sm:text-xl font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <svg class="w-5 h-5 text-indigo-600 dark:text-indigo-400 animate-pulse-slow" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01"></path>
                </svg>
                {{ $t('index.node_info') }}
              </h2>
            </div>
            <div class="p-4 sm:p-5 lg:p-6">
              <ArrayObjectElement
                :value="paramStore.nodeVersion?.items || {}"
              />
            </div>
          </div>
          
          <!-- Deployment Version - Icy Glassmorphic -->
          <div v-if="versionInfo" class="relative overflow-hidden rounded-2xl sm:rounded-3xl bg-gradient-to-br from-white/50 via-white/30 to-white/20 dark:from-white/10 dark:via-white/5 dark:to-white/5 backdrop-blur-xl border border-white/60 dark:border-white/10 shadow-[0_8px_32px_0_rgba(31,38,135,0.15)] dark:shadow-none hover:scale-[1.01] transition-all duration-500 animate-fade-in">
            <div class="p-3 sm:p-4 lg:p-6">
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
    </div>
  </div>
</template>

<style scoped>
/* Smooth transitions for interactive elements */
.backdrop-blur-xl {
  transition: all 0.3s ease;
}

/* Subtle hover effect for glass cards */
.backdrop-blur-xl:hover {
  transform: translateY(-2px);
}

/* Shimmer effect for glass surfaces */
@keyframes shimmer {
  0% {
    background-position: -1000px 0;
  }
  100% {
    background-position: 1000px 0;
  }
}

.glass-shimmer {
  background: linear-gradient(
    90deg,
    transparent,
    rgba(255, 255, 255, 0.1),
    transparent
  );
  background-size: 1000px 100%;
  animation: shimmer 8s infinite;
}

/* Floating animation */
@keyframes float {
  0%, 100% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-20px);
  }
}

@keyframes float-slow {
  0%, 100% {
    transform: translate(0, 0) scale(1);
  }
  33% {
    transform: translate(30px, -30px) scale(1.05);
  }
  66% {
    transform: translate(-20px, 20px) scale(0.95);
  }
}

@keyframes float-slower {
  0%, 100% {
    transform: translate(0, 0) scale(1);
  }
  33% {
    transform: translate(-30px, 30px) scale(0.95);
  }
  66% {
    transform: translate(20px, -20px) scale(1.05);
  }
}

.animate-float {
  animation: float 3s ease-in-out infinite;
}

.animate-float-slow {
  animation: float-slow 20s ease-in-out infinite;
}

.animate-float-slower {
  animation: float-slower 25s ease-in-out infinite;
}

/* Removed spin animation - keeping it professional */

/* Pulse animation */
@keyframes pulse-slow {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.animate-pulse-slow {
  animation: pulse-slow 4s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Removed bounce animation - keeping it subtle */

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
  animation: gradient 5s ease infinite;
}

/* Slide animations */
@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-slide-down {
  animation: slideDown 0.6s ease-out forwards;
}

.animate-slide-up {
  animation: slideUp 0.6s ease-out forwards;
  opacity: 0;
}

/* Fade in animation */
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in {
  animation: fadeIn 0.5s ease-out forwards;
  animation-delay: 0.5s;
  opacity: 0;
}

/* Loading pulse */
@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Ensure smooth loading animations */
.space-y-4 > *,
.space-y-6 > *,
.space-y-8 > * {
  animation: fadeIn 0.5s ease-out;
  animation-fill-mode: both;
}

.space-y-4 > *:nth-child(1),
.space-y-6 > *:nth-child(1),
.space-y-8 > *:nth-child(1) { animation-delay: 0s; }
.space-y-4 > *:nth-child(2),
.space-y-6 > *:nth-child(2),
.space-y-8 > *:nth-child(2) { animation-delay: 0.1s; }
.space-y-4 > *:nth-child(3),
.space-y-6 > *:nth-child(3),
.space-y-8 > *:nth-child(3) { animation-delay: 0.2s; }

/* Glass shine effect on hover */
.stat-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(
    90deg,
    transparent,
    rgba(255, 255, 255, 0.2),
    transparent
  );
  transition: left 0.8s ease;
  pointer-events: none;
}

.stat-card:hover::before {
  left: 100%;
}
</style>

<route>
{
  "meta": {
    "i18n": "dashboard"
  }
}
</route>