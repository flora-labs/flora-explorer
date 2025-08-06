<script lang="ts" setup>
import { useBlockchain, useFormatter, useTxDialog, useWalletStore, useStakingStore, useParamStore, useBankStore, useMintStore, useGovStore, useBaseStore } from '@/stores';
import { useDistributionStore } from '@/stores/useDistributionStore';
import { onMounted, onUnmounted, ref, watchEffect, watch } from 'vue';
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

// Check if desktop
const isDesktop = ref(window.innerWidth >= 1280);

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
  stakingStore.init();
  
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
    communityPool: communityPool.value && communityPool.value[0] ? format.formatToken(communityPool.value[0]) : '0',
    validatorCount: stakingStore.validators?.length || 0
  };
});
</script>

<template>
  <div class="space-y-3 sm:space-y-4 min-w-0">
        <!-- Header Section -->
        <div v-if="blockchain.current" class="relative overflow-hidden rounded-2xl p-3 sm:p-6 
                    bg-white/10 dark:bg-gray-900/8 
                    backdrop-blur-md backdrop-saturate-150
                    border border-white/10 dark:border-white/6
                    shadow-sm hover:shadow-md
                    transition-all duration-200 ease-out">
            <!-- Glass tint layer -->
            <div class="absolute inset-0 bg-gradient-to-br from-emerald-400/5 to-teal-600/5 pointer-events-none"></div>
            
            <div class="relative z-10 flex items-center justify-between">
              <!-- Main Content -->
              <div class="flex items-center gap-2 sm:gap-4 min-w-0">
                <!-- Logo without container -->
                <img src="/logo.svg" class="w-8 h-8 sm:w-10 sm:h-10 flex-shrink-0" alt="Flora Logo" />
                
                <!-- Gradient title text -->
                <h1 class="text-xl sm:text-3xl font-bold bg-gradient-to-br from-emerald-400 via-teal-400 to-cyan-400 
                           dark:from-emerald-300 dark:via-teal-300 dark:to-cyan-300 
                           bg-clip-text text-transparent truncate">
                  {{ blockchain.current?.prettyName || 'Flora Devnet' }}
                </h1>
              </div>
              
              <!-- Action Icons - no containers -->
              <div class="flex gap-3 sm:gap-4 items-center flex-shrink-0">
                <!-- Discord button - just the icon -->
                <a 
                  href="https://discord.flora.network" 
                  target="_blank"
                  class="group inline-flex items-center justify-center p-1
                         transition-all duration-200 ease-out
                         hover:scale-[1.1] 
                         focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
                         focus-visible:outline-purple-500/60"
                  title="Join Flora Discord"
                >
                  <img 
                    :src="DiscordBotAvatar" 
                    alt="Flora Discord Bot" 
                    class="w-8 h-8 sm:w-9 sm:h-9 rounded-full object-cover"
                  />
                </a>
                
                <!-- Dev Portal button - just the icon -->
                <a 
                  href="https://dev.flora.network"
                  target="_blank"
                  class="group inline-flex items-center justify-center p-1
                         transition-all duration-200 ease-out
                         hover:scale-[1.1]
                         focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
                         focus-visible:outline-blue-500/60"
                  title="Flora Dev Portal"
                >
                  <Icon icon="mdi:robot-excited" class="text-2xl sm:text-3xl text-blue-500 dark:text-blue-400 hover:text-blue-400 dark:hover:text-blue-300 transition-colors" />
                </a>
              </div>
            </div>
        </div>

        <!-- Top Statistics Grid -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
        <!-- Block Height -->
        <div class="group relative min-h-[5.5rem] sm:h-32">
          <!-- Premium glass card with multi-layer effects -->
          <div class="relative overflow-hidden rounded-2xl p-3 h-full 
                      bg-white/10 dark:bg-gray-900/8 
                      backdrop-blur-md backdrop-saturate-150
                      border border-white/10 dark:border-white/6
                      shadow-sm hover:shadow-md
                      transition-all duration-200 ease-out">
            <!-- Glass tint layer -->
            <div class="absolute inset-0 bg-gradient-to-br from-amber-500/5 via-transparent to-transparent pointer-events-none"></div>
            <!-- Reflective glare layer -->
            <!-- Glare removed for cleaner look -->
            
            <!-- Content -->
            <div class="relative z-10">
              <div class="flex items-start justify-between mb-2">
                <!-- Icon chip -->
                <div class="grid place-content-center w-10 h-10 sm:w-12 sm:h-12 rounded-full
                            bg-amber-500/10 dark:bg-amber-400/5
                            group-hover:scale-105 transition-transform duration-200">
                  <Icon icon="mdi:cube-outline" class="text-xl sm:text-2xl text-amber-600 dark:text-amber-400" />
                </div>
              </div>
              
              <h3 class="text-[10px] sm:text-xs font-semibold tracking-wider text-amber-700/80 dark:text-amber-300/70 uppercase">Block Height</h3>
              <p class="text-lg sm:text-xl lg:text-2xl font-bold bg-gradient-to-br from-amber-600 to-orange-600 dark:from-amber-300 dark:to-orange-400 bg-clip-text text-transparent mt-1">
                {{ animatedHeight || baseStore.latest?.block?.header?.height || '0' }}
              </p>
            </div>
          </div>
        </div>
        
        <!-- Total Supply -->
        <div class="group relative min-h-[5.5rem] sm:h-32">
          <!-- Premium glass card with multi-layer effects -->
          <div class="relative overflow-hidden rounded-2xl p-3 h-full 
                      bg-white/10 dark:bg-gray-900/8 
                      backdrop-blur-md backdrop-saturate-150
                      border border-white/10 dark:border-white/6
                      shadow-sm hover:shadow-md
                      transition-all duration-200 ease-out">
            <!-- Glass tint layer -->
            <div class="absolute inset-0 bg-gradient-to-br from-purple-500/5 via-transparent to-transparent pointer-events-none"></div>
            <!-- Reflective glare layer -->
            <!-- Glare removed for cleaner look -->
            
            <!-- Content -->
            <div class="relative z-10">
              <div class="flex items-start justify-between mb-2">
                <!-- Icon chip -->
                <div class="grid place-content-center w-10 h-10 sm:w-12 sm:h-12 rounded-full
                            bg-purple-500/10 dark:bg-purple-400/5
                            group-hover:scale-105 transition-transform duration-200">
                  <Icon icon="mdi:cash-multiple" class="text-xl sm:text-2xl text-purple-600 dark:text-purple-400" />
                </div>
              </div>
              
              <h3 class="text-[10px] sm:text-xs font-semibold tracking-wider text-purple-700/80 dark:text-purple-300/70 uppercase">Total Supply</h3>
              <p class="text-sm sm:text-lg lg:text-xl font-bold bg-gradient-to-br from-purple-600 to-fuchsia-600 dark:from-purple-300 dark:to-fuchsia-400 bg-clip-text text-transparent mt-1 truncate">
                {{ floraStats.totalSupply }}
              </p>
            </div>
          </div>
        </div>
        
        <!-- Bonded Tokens -->
        <div class="group relative min-h-[5.5rem] sm:h-32">
          <!-- Premium glass card with multi-layer effects -->
          <div class="relative overflow-hidden rounded-2xl p-3 h-full 
                      bg-white/10 dark:bg-gray-900/8 
                      backdrop-blur-md backdrop-saturate-150
                      border border-white/10 dark:border-white/6
                      shadow-sm hover:shadow-md
                      transition-all duration-200 ease-out">
            <!-- Glass tint layer -->
            <div class="absolute inset-0 bg-gradient-to-br from-blue-500/5 via-transparent to-transparent pointer-events-none"></div>
            <!-- Reflective glare layer -->
            <!-- Glare removed for cleaner look -->
            
            <!-- Content -->
            <div class="relative z-10">
              <div class="flex items-start justify-between mb-2">
                <!-- Icon chip -->
                <div class="grid place-content-center w-10 h-10 sm:w-12 sm:h-12 rounded-full
                            bg-blue-500/10 dark:bg-blue-400/5
                            group-hover:scale-105 transition-transform duration-200">
                  <Icon icon="mdi:lock" class="text-xl sm:text-2xl text-blue-600 dark:text-blue-400" />
                </div>
              </div>
              
              <h3 class="text-[10px] sm:text-xs font-semibold tracking-wider text-blue-700/80 dark:text-blue-300/70 uppercase">Bonded Tokens</h3>
              <p class="text-sm sm:text-lg lg:text-xl font-bold bg-gradient-to-br from-blue-600 to-cyan-600 dark:from-blue-300 dark:to-cyan-400 bg-clip-text text-transparent mt-1 truncate">
                {{ floraStats.bondedTokens }}
              </p>
            </div>
          </div>
        </div>
        
        <!-- Community Pool -->
        <div class="group relative min-h-[5.5rem] sm:h-32">
          <!-- Premium glass card with multi-layer effects -->
          <div class="relative overflow-hidden rounded-2xl p-3 h-full 
                      bg-white/10 dark:bg-gray-900/8 
                      backdrop-blur-md backdrop-saturate-150
                      border border-white/10 dark:border-white/6
                      shadow-sm hover:shadow-md
                      transition-all duration-200 ease-out">
            <!-- Glass tint layer -->
            <div class="absolute inset-0 bg-gradient-to-br from-green-500/5 via-transparent to-transparent pointer-events-none"></div>
            <!-- Reflective glare layer -->
            <!-- Glare removed for cleaner look -->
            
            <!-- Content -->
            <div class="relative z-10">
              <div class="flex items-start justify-between mb-2">
                <!-- Icon chip -->
                <div class="grid place-content-center w-10 h-10 sm:w-12 sm:h-12 rounded-full
                            bg-green-500/10 dark:bg-green-400/5
                            group-hover:scale-105 transition-transform duration-200">
                  <Icon icon="mdi:bank" class="text-xl sm:text-2xl text-green-600 dark:text-green-400" />
                </div>
              </div>
              
              <h3 class="text-[10px] sm:text-xs font-semibold tracking-wider text-green-700/80 dark:text-green-300/70 uppercase">Community Pool</h3>
              <p class="text-sm sm:text-lg lg:text-xl font-bold bg-gradient-to-br from-green-600 to-teal-600 dark:from-green-300 dark:to-teal-400 bg-clip-text text-transparent mt-1 truncate">
                {{ floraStats.communityPool }}
              </p>
            </div>
          </div>
        </div>
        
        </div>

        <!-- Content Grid -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 lg:gap-6 min-w-0">
        <!-- Main Content Area -->
        <div class="lg:col-span-2 space-y-6 min-w-0">
          <!-- Network Statistics -->
          <div v-if="blockchain.supportModule('staking') || blockchain.supportModule('bank')" 
               class="relative overflow-hidden rounded-2xl p-4 sm:p-6
                      bg-white/10 dark:bg-gray-900/8 
                      backdrop-blur-md backdrop-saturate-150
                      border border-white/10 dark:border-white/6
                      shadow-sm hover:shadow-md
                      transition-all duration-200 ease-out">
            <!-- Glass tint layer -->
            <div class="absolute inset-0 bg-gradient-to-br from-blue-500/5 via-transparent to-transparent pointer-events-none"></div>
            
            <div class="relative z-10">
              <h2 class="text-lg font-semibold mb-6 flex items-center gap-3">
                <div class="h-10 w-10 flex items-center justify-center rounded-full
                            bg-gradient-to-br from-blue-400/20 to-cyan-600/10
                            backdrop-blur-md">
                  <Icon icon="mdi:chart-line" class="text-xl text-blue-500 dark:text-blue-400" />
                </div>
                <span class="bg-gradient-to-br from-blue-400 via-cyan-400 to-teal-400 
                             dark:from-blue-300 dark:via-cyan-300 dark:to-teal-300 
                             bg-clip-text text-transparent">
                  Network Statistics
                </span>
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
                  class="relative overflow-hidden rounded-xl p-4
                         bg-white/5 dark:bg-gray-900/5
                         border border-white/10 dark:border-white/5
                         shadow-[0_2px_6px_-2px_rgba(0,0,0,0.1)]
                         transition-all duration-150 ease-out
                         hover:scale-[1.005] hover:shadow-[0_4px_12px_-4px_rgba(0,0,0,0.15)]"
                />
                
                <CardStatisticsVertical
                  v-if="blockchain.supportModule('bank')"
                  :stats="totalSupply || '0'"
                  title="Total Supply"
                  subtitle="Total FLORA supply"
                  :icon="'mdi:cash-multiple'"
                  color="success"
                  class="relative overflow-hidden rounded-xl p-4
                         bg-white/5 dark:bg-gray-900/5
                         border border-white/10 dark:border-white/5
                         shadow-[0_2px_6px_-2px_rgba(0,0,0,0.1)]
                         transition-all duration-150 ease-out
                         hover:scale-[1.005] hover:shadow-[0_4px_12px_-4px_rgba(0,0,0,0.15)]"
                />
                
                <CardStatisticsVertical
                  v-if="blockchain.supportModule('mint')"
                  :stats="`${(Number(mintStore?.inflation || 0) * 100).toFixed(2)}%`"
                  title="Inflation"
                  subtitle="Current inflation rate"
                  :icon="'mdi:chart-line'"
                  color="warning"
                  class="relative overflow-hidden rounded-xl p-4
                         bg-white/5 dark:bg-gray-900/5
                         border border-white/10 dark:border-white/5
                         shadow-[0_2px_6px_-2px_rgba(0,0,0,0.1)]
                         transition-all duration-150 ease-out
                         hover:scale-[1.005] hover:shadow-[0_4px_12px_-4px_rgba(0,0,0,0.15)]"
                />
                
                <CardStatisticsVertical
                  v-if="blockchain.supportModule('distribution')"
                  :stats="format.formatToken((communityPool && communityPool[0]) || {})"
                  title="Community Pool"
                  subtitle="Available funds"
                  :icon="'mdi:bank'"
                  color="primary"
                  class="relative overflow-hidden rounded-xl p-4
                         bg-white/5 dark:bg-gray-900/5
                         border border-white/10 dark:border-white/5
                         shadow-[0_2px_6px_-2px_rgba(0,0,0,0.1)]
                         transition-all duration-150 ease-out
                         hover:scale-[1.005] hover:shadow-[0_4px_12px_-4px_rgba(0,0,0,0.15)]"
                />
              </div>
            </div>
          </div>

          <!-- Active Proposals -->
          <div v-if="blockchain.supportModule('governance')" 
               class="relative overflow-hidden rounded-2xl
                      bg-white/10 dark:bg-gray-900/8 
                      backdrop-blur-md backdrop-saturate-150
                      border border-white/10 dark:border-white/6
                      shadow-sm hover:shadow-md
                      transition-all duration-200 ease-out">
            <!-- Glass tint layer -->
            <div class="absolute inset-0 bg-gradient-to-br from-purple-400/5 to-fuchsia-600/5 pointer-events-none"></div>
            
            <div class="relative z-10">
              <div class="p-6 border-b border-white/10 dark:border-white/5">
                <h2 class="text-lg font-semibold flex items-center gap-3">
                  <div class="h-10 w-10 flex items-center justify-center rounded-full
                              bg-gradient-to-br from-purple-400/20 to-fuchsia-600/10
                              backdrop-blur-md">
                    <Icon icon="mdi:clipboard-text-outline" class="text-xl text-purple-500 dark:text-purple-400" />
                  </div>
                  <span class="bg-gradient-to-br from-purple-400 via-fuchsia-400 to-pink-400 
                               dark:from-purple-300 dark:via-fuchsia-300 dark:to-pink-300 
                               bg-clip-text text-transparent">
                    {{ $t('index.active_proposals') }}
                  </span>
                </h2>
              </div>
              <div class="p-6">
                <div v-if="govStore?.proposals?.['2'] && Array.isArray(govStore?.proposals?.['2']) && govStore?.proposals?.['2']?.length > 0" class="space-y-3">
                  <div v-for="(item, index) in govStore?.proposals?.['2'] || []"
                       :key="index"
                       class="relative overflow-hidden rounded-xl p-4
                              bg-white/8 dark:bg-gray-900/6
                              backdrop-blur-md border border-white/10 dark:border-white/6
                              shadow-sm
                              transition-all duration-200 ease-out
                              hover:scale-[1.01] hover:shadow-md
                              group">
                    <ProposalListItem :proposal="item" />
                  </div>
                </div>
                <div v-else class="text-center py-12">
                  <div class="h-14 w-14 mx-auto flex items-center justify-center rounded-full
                              bg-white/10 backdrop-blur-md
                              text-white/50 dark:text-white/40 mb-4">
                    <Icon icon="mdi:inbox-outline" class="text-3xl" />
                  </div>
                  <p class="text-white/60 dark:text-white/50">{{ $t('index.no_active_proposals') }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Sidebar -->
        <div class="space-y-6 min-w-0">
          <!-- Wallet Section -->
          <div v-if="walletStore.currentAddress" 
               class="relative overflow-hidden rounded-2xl
                      bg-white/10 dark:bg-gray-900/8 
                      backdrop-blur-md backdrop-saturate-150
                      border border-white/10 dark:border-white/6
                      shadow-sm hover:shadow-md
                      transition-all duration-200 ease-out">
            <!-- Glass tint layer -->
            <div class="absolute inset-0 bg-gradient-to-br from-green-400/5 to-emerald-600/5 pointer-events-none"></div>
            
            <div class="relative z-10">
              <div class="p-6 border-b border-white/10 dark:border-white/5">
                <h2 class="text-lg font-semibold flex items-center gap-3">
                  <div class="h-10 w-10 flex items-center justify-center rounded-full
                              bg-gradient-to-br from-green-400/20 to-emerald-600/10
                              backdrop-blur-md">
                    <Icon icon="mdi:wallet" class="text-xl text-green-500 dark:text-green-400" />
                  </div>
                  <span class="bg-gradient-to-br from-green-400 via-emerald-400 to-teal-400 
                               dark:from-green-300 dark:via-emerald-300 dark:to-teal-300 
                               bg-clip-text text-transparent">
                    {{ $t('index.wallet') }}
                  </span>
                </h2>
              </div>
              <div class="p-6">
                <!-- Balance Card -->
                <div class="mb-5 relative overflow-hidden rounded-xl p-4
                            bg-white/8 dark:bg-gray-900/6
                            backdrop-blur-md border border-white/10 dark:border-white/6
                            shadow-sm">
                  <p class="text-xs font-medium text-white/70 dark:text-white/60 uppercase tracking-wider mb-1">Balance</p>
                  <p class="text-2xl font-bold bg-gradient-to-br from-emerald-400 via-green-400 to-teal-400 
                            dark:from-emerald-300 dark:via-green-300 dark:to-teal-300 
                            bg-clip-text text-transparent">
                    {{ format.formatToken(walletStore.balanceOfStakingToken) }}
                  </p>
                </div>
                
                <!-- Action Buttons -->
                <div class="grid grid-cols-3 gap-2">
                  <!-- Send Button -->
                  <button class="group relative overflow-hidden rounded-full px-3 py-2
                                 bg-white/8 dark:bg-gray-900/6 border border-white/10 dark:border-white/6
                                 backdrop-blur-md text-sm font-medium
                                 transition-all duration-200 ease-out
                                 hover:scale-[1.02] hover:shadow-md
                                 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
                                 focus-visible:outline-blue-500/60"
                          @click="dialog.open('send', {})">
                    <span class="relative z-10 flex items-center justify-center gap-1">
                      <Icon icon="mdi:send" class="text-base text-blue-400" />
                      <span class="text-blue-300">{{ $t('account.send') }}</span>
                    </span>
                    <span class="absolute inset-0 bg-blue-500/10 opacity-0 group-hover:opacity-100 transition-opacity"></span>
                  </button>
                  
                  <!-- Delegate Button -->
                  <button class="group relative overflow-hidden rounded-full px-3 py-2
                                 bg-white/6 dark:bg-gray-900/6 border border-white/20 dark:border-white/15
                                 backdrop-blur-2xl text-sm font-medium
                                 transition-all duration-150 ease-out
                                 hover:scale-[1.03] hover:shadow-[0_6px_18px_-6px_rgba(168,85,247,0.4)]
                                 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
                                 focus-visible:outline-purple-500/60"
                          @click="dialog.open('delegate', {})">
                    <span class="relative z-10 flex items-center justify-center gap-1">
                      <Icon icon="mdi:account-convert" class="text-base text-purple-400" />
                      <span class="text-purple-300">{{ $t('account.delegate') }}</span>
                    </span>
                    <span class="absolute inset-0 bg-purple-500/10 opacity-0 group-hover:opacity-100 transition-opacity"></span>
                  </button>
                  
                  <!-- Transfer Button -->
                  <button class="group relative overflow-hidden rounded-full px-3 py-2
                                 bg-white/6 dark:bg-gray-900/6 border border-white/20 dark:border-white/15
                                 backdrop-blur-2xl text-sm font-medium
                                 transition-all duration-150 ease-out
                                 hover:scale-[1.03] hover:shadow-[0_6px_18px_-6px_rgba(6,182,212,0.4)]
                                 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
                                 focus-visible:outline-cyan-500/60"
                          @click="dialog.open('transfer', {})">
                    <span class="relative z-10 flex items-center justify-center gap-1">
                      <Icon icon="mdi:swap-horizontal" class="text-base text-cyan-400" />
                      <span class="text-cyan-300">{{ $t('account.transfer') }}</span>
                    </span>
                    <span class="absolute inset-0 bg-cyan-500/10 opacity-0 group-hover:opacity-100 transition-opacity"></span>
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Application Version -->
          <div class="relative overflow-hidden rounded-2xl
                      bg-white/10 dark:bg-gray-900/8 
                      backdrop-blur-md backdrop-saturate-150
                      border border-white/10 dark:border-white/6
                      shadow-sm hover:shadow-md
                      transition-all duration-200 ease-out">
            <!-- Glass tint layer -->
            <div class="absolute inset-0 bg-gradient-to-br from-yellow-400/5 to-amber-600/5 pointer-events-none"></div>
            
            <div class="relative z-10">
              <div class="p-6 border-b border-white/10 dark:border-white/5">
                <h2 class="text-lg font-semibold flex items-center gap-3">
                  <div class="h-10 w-10 flex items-center justify-center rounded-full
                              bg-gradient-to-br from-yellow-400/20 to-amber-600/10
                              backdrop-blur-md">
                    <Icon icon="mdi:information-outline" class="text-xl text-yellow-500 dark:text-yellow-400" />
                  </div>
                  <span class="bg-gradient-to-br from-yellow-400 via-amber-400 to-orange-400 
                               dark:from-yellow-300 dark:via-amber-300 dark:to-orange-300 
                               bg-clip-text text-transparent">
                    {{ $t('index.app_versions') }}
                  </span>
                </h2>
              </div>
              <div class="p-6">
                <ArrayObjectElement
                  :value="paramStore.appVersion?.items"
                  :thead="false"
                />
              </div>
            </div>
          </div>

          <!-- Node Info -->
          <div class="relative overflow-hidden rounded-2xl
                      bg-white/10 dark:bg-gray-900/8 
                      backdrop-blur-md backdrop-saturate-150
                      border border-white/10 dark:border-white/6
                      shadow-sm hover:shadow-md
                      transition-all duration-200 ease-out">
            <!-- Glass tint layer -->
            <div class="absolute inset-0 bg-gradient-to-br from-indigo-400/5 to-blue-600/5 pointer-events-none"></div>
            
            <div class="relative z-10">
              <div class="p-6 border-b border-white/10 dark:border-white/5">
                <h2 class="text-lg font-semibold flex items-center gap-3">
                  <div class="h-10 w-10 flex items-center justify-center rounded-full
                              bg-gradient-to-br from-indigo-400/20 to-blue-600/10
                              backdrop-blur-md">
                    <Icon icon="mdi:server" class="text-xl text-indigo-500 dark:text-indigo-400" />
                  </div>
                  <span class="bg-gradient-to-br from-indigo-400 via-blue-400 to-cyan-400 
                               dark:from-indigo-300 dark:via-blue-300 dark:to-cyan-300 
                               bg-clip-text text-transparent">
                    {{ $t('index.node_info') }}
                  </span>
                </h2>
              </div>
              <div class="p-6">
                <ArrayObjectElement
                  :value="paramStore.nodeVersion?.items || {}"
                />
              </div>
            </div>
          </div>
          
          <!-- Deployment Version -->
          <div v-if="versionInfo" class="relative overflow-hidden rounded-2xl
                      bg-white/10 dark:bg-gray-900/8 
                      backdrop-blur-md backdrop-saturate-150
                      border border-white/10 dark:border-white/6
                      shadow-sm hover:shadow-md
                      transition-all duration-200 ease-out">
            <!-- Glass tint layer -->
            <div class="absolute inset-0 bg-gradient-to-br from-gray-400/5 to-slate-600/5 pointer-events-none"></div>
            
            <div class="relative z-10">
              <div class="p-6 border-b border-white/10 dark:border-white/5">
                <h2 class="text-lg font-semibold flex items-center gap-3">
                  <div class="h-10 w-10 flex items-center justify-center rounded-full
                              bg-gradient-to-br from-gray-400/20 to-slate-600/10
                              backdrop-blur-md">
                    <Icon icon="mdi:source-branch" class="text-xl text-gray-500 dark:text-gray-400" />
                  </div>
                  <span class="bg-gradient-to-br from-gray-400 via-slate-400 to-zinc-400 
                               dark:from-gray-300 dark:via-slate-300 dark:to-zinc-300 
                               bg-clip-text text-transparent">
                    Deployment Version
                  </span>
                </h2>
              </div>
              <div class="p-6">
                <div class="space-y-3">
                  <div class="flex items-center gap-2">
                    <Icon icon="mdi:git" class="text-sm text-gray-500 dark:text-gray-400" />
                    <span class="text-sm text-gray-600 dark:text-gray-400">Build:</span>
                    <span class="font-mono text-sm bg-gradient-to-r from-gray-600 to-slate-600 dark:from-gray-300 dark:to-slate-300 bg-clip-text text-transparent font-semibold">
                      {{ versionInfo?.gitHash?.slice(0, 8) }}
                    </span>
                  </div>
                  <div class="flex items-center gap-2">
                    <Icon icon="mdi:calendar" class="text-sm text-gray-500 dark:text-gray-400" />
                    <span class="text-sm text-gray-600 dark:text-gray-400">Deployed:</span>
                    <span class="text-sm text-gray-700 dark:text-gray-300 font-medium">
                      {{ versionInfo?.buildTime ? new Date(versionInfo.buildTime).toLocaleDateString() : '' }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
  </div>
</template>

<style scoped>
/* Minimal necessary styles */
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

/* Glassmorphic card shine animation */
@keyframes glass-shine {
  0% {
    background-position: -200% 0;
  }
  100% {
    background-position: 200% 0;
  }
}

/* Glass sweep animation for reflective glare */
@keyframes glass-sweep {
  0% {
    transform: translateX(-100%) rotate(15deg);
  }
  100% {
    transform: translateX(400%) rotate(15deg);
  }
}

/* Premium glassmorphic effects */
.stat-glass {
  position: relative;
  overflow: hidden;
}

/* Add pseudo-elements for multi-layer glass effect */
.stat-glass::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.1) 0%,
    rgba(255, 255, 255, 0.03) 60%,
    transparent 100%
  );
  pointer-events: none;
  z-index: 1;
}

.stat-glass::after {
  content: '';
  position: absolute;
  inset: 0;
  background: 
    linear-gradient(75deg,
      rgba(255, 255, 255, 0.15) 0%,
      rgba(255, 255, 255, 0.03) 35%,
      transparent 40%),
    radial-gradient(circle at top left,
      rgba(255, 255, 255, 0.1) 0%,
      transparent 70%);
  mix-blend-mode: overlay;
  opacity: 0.5;
  pointer-events: none;
  z-index: 2;
}

/* Reduced motion support */
@media (prefers-reduced-motion: reduce) {
  .stat-glass,
  .glass-glare,
  .stat-glass::before,
  .stat-glass::after {
    animation: none !important;
    transition: none !important;
  }
}
</style>

<route>
{
  "meta": {
    "i18n": "dashboard"
  }
}
</route>