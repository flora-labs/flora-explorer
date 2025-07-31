<script setup lang="ts">
import { useRoute } from 'vue-router';
import { useBaseStore, useBlockchain, useWalletStore } from '@/stores';
import { Icon } from '@iconify/vue';
import { ref, computed, onMounted, onUnmounted } from 'vue';

// Add window type declarations
declare global {
  interface Window {
    keplr: any;
    ethereum: any;
  }
}

const route = useRoute();
const walletStore = useWalletStore();
const chainStore = useBlockchain();
const baseStore = useBaseStore();
const showDrawer = ref(false);
const showWalletSelector = ref(false);

// Don't allow drawer on wallet/suggest page
const isWalletSuggestPage = computed(() => {
  return route.path === '/wallet/suggest';
});

// Handle escape key
const handleEscape = (e: KeyboardEvent) => {
  if (e.key === 'Escape') {
    if (showWalletSelector.value) {
      showWalletSelector.value = false;
    } else if (showDrawer.value) {
      showDrawer.value = false;
    }
  }
};

onMounted(() => {
  document.addEventListener('keydown', handleEscape);
});

onUnmounted(() => {
  document.removeEventListener('keydown', handleEscape);
});

// walletStore.$subscribe((m, s) => {
//   console.log(m, s);
// });
function walletStateChange(res: any) {
  walletStore.setConnectedWallet(res.detail?.value);
}
let showCopyToast = ref(0);
async function copyAdress(address: string) {
  try {
    await navigator.clipboard.writeText(address);
    showCopyToast.value = 1;
    setTimeout(() => {
      showCopyToast.value = 0;
    }, 1000);
  } catch (err) {
    showCopyToast.value = 2;
    setTimeout(() => {
      showCopyToast.value = 0;
    }, 1000);
  }
}
const tipMsg = computed(() => {
  return showCopyToast.value === 2
    ? { class: 'error', msg: 'Copy Error!' }
    : { class: 'success', msg: 'Copy Success!' };
});

const params = computed(() => {
  if (chainStore.chainName == 'side') {
    return JSON.stringify({
      wallet: ['okex', 'unisat'],
    });
  }
  return '';
});

async function connectKeplr() {
  if (!window.keplr) {
    alert('Please install Keplr extension');
    return;
  }
  
  try {
    // First, suggest the chain to Keplr
    const chainId = baseStore.currentChainId || 'flora_7668378-1';
    
    // Try to suggest chain configuration first
    try {
      await walletStore.suggestChain();
    } catch (e) {
      console.log('Chain already added or suggestion failed:', e);
    }
    
    // Enable the chain
    await window.keplr.enable(chainId);
    
    // Get account info
    const offlineSigner = window.keplr.getOfflineSigner(chainId);
    const accounts = await offlineSigner.getAccounts();
    
    if (accounts.length > 0) {
      walletStore.setConnectedWallet({
        wallet: 'Keplr',
        address: accounts[0].address,
      });
      showWalletSelector.value = false;
      showDrawer.value = true;
    }
  } catch (error) {
    console.error('Keplr connection failed:', error);
    alert('Failed to connect to Keplr. Please try adding the chain manually.');
  }
}

async function connectMetaMask() {
  showWalletSelector.value = false;
  
  if (!window.ethereum) {
    alert('Please install MetaMask extension');
    return;
  }
  
  try {
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    
    if (accounts.length > 0) {
      walletStore.setConnectedWallet({
        wallet: 'MetaMask',
        address: accounts[0],
      });
    }
  } catch (error) {
    console.error('MetaMask connection failed:', error);
    alert('Failed to connect to MetaMask');
  }
}

function handleWalletClick() {
  if (walletStore.currentAddress) {
    // If connected, show wallet drawer
    showDrawer.value = true;
  } else {
    // If not connected, show wallet selector
    showWalletSelector.value = true;
  }
}
</script>

<template>
  <div>
    <!-- Wallet Button -->
    <button
      @click="!isWalletSuggestPage && handleWalletClick()"
      class="btn btn-sm btn-primary m-1 lowercase truncate !inline-flex text-xs md:!text-sm"
    >
      <Icon icon="mdi:wallet" />
      <span class="ml-1 hidden md:block"> {{ walletStore.shortAddress || 'Wallet' }}</span>
    </button>

    <!-- Wallet Modal -->
    <Teleport to="body">
      <div v-if="showDrawer && !isWalletSuggestPage" class="fixed inset-0 z-[2000] flex items-center justify-center p-4">
        <!-- Backdrop -->
        <div 
          class="absolute inset-0 bg-black/50"
          @click="showDrawer = false"
        ></div>
        
        <!-- Modal Content -->
        <div 
          class="relative bg-base-100 rounded-2xl shadow-2xl max-w-md w-full max-h-[80vh] overflow-y-auto"
        >
          <!-- Header -->
          <div class="flex items-center justify-between p-4 border-b border-base-300">
            <h3 class="text-lg font-semibold">Wallet</h3>
            <button 
              @click="showDrawer = false"
              class="btn btn-sm btn-ghost btn-circle"
            >
              <Icon icon="mdi:close" class="text-xl" />
            </button>
          </div>
          
          <!-- Content -->
          <div class="p-4 space-y-4">
            <!-- Wallet Info -->
            <div class="space-y-3">
              <div class="text-sm text-gray-500 dark:text-gray-400 font-semibold">
                {{ walletStore.connectedWallet?.wallet }}
              </div>
              
              <!-- Address with Copy -->
              <div 
                class="p-3 bg-base-200 rounded-lg cursor-pointer hover:bg-base-300 transition-colors group"
                @click="copyAdress(walletStore.currentAddress)"
              >
                <div class="flex items-center justify-between">
                  <p class="text-sm break-all mr-2">{{ walletStore.currentAddress }}</p>
                  <Icon icon="mdi:content-copy" class="text-gray-500 group-hover:text-primary transition-colors" />
                </div>
              </div>
            </div>
            
            <div class="divider"></div>
            
            <!-- Navigation Links -->
            <div class="space-y-2">
              <RouterLink 
                to="/wallet/accounts" 
                @click="showDrawer = false"
                class="block w-full p-3 rounded-lg hover:bg-base-200 transition-colors"
              >
                <div class="flex items-center">
                  <Icon icon="mdi:account-multiple" class="mr-3 text-lg" />
                  <span>Accounts</span>
                </div>
              </RouterLink>
              
              <RouterLink 
                to="/wallet/portfolio" 
                @click="showDrawer = false"
                class="block w-full p-3 rounded-lg hover:bg-base-200 transition-colors"
              >
                <div class="flex items-center">
                  <Icon icon="mdi:chart-pie" class="mr-3 text-lg" />
                  <span>Portfolio</span>
                </div>
              </RouterLink>
              
              <RouterLink 
                to="/wallet/suggest" 
                @click="showDrawer = false"
                class="block w-full p-3 rounded-lg hover:bg-base-200 transition-colors"
              >
                <div class="flex items-center">
                  <Icon icon="mdi:wallet-plus" class="mr-3 text-lg" />
                  <span>Add to Wallet</span>
                </div>
              </RouterLink>
            </div>
            
            <div class="divider"></div>
            
            <!-- Disconnect Button -->
            <button
              class="btn btn-error btn-outline w-full"
              @click="walletStore.disconnect(); showDrawer = false"
            >
              <Icon icon="mdi:logout" class="mr-2" />
              Disconnect
            </button>
          </div>
        </div>
      </div>
    </Teleport>
    
    <!-- Wallet Selector Modal -->
    <Teleport to="body">
      <div v-if="showWalletSelector" class="fixed inset-0 z-[2500] flex items-center justify-center p-4">
        <!-- Backdrop -->
        <div 
          class="absolute inset-0 bg-black/50"
          @click="showWalletSelector = false"
        ></div>
        
        <!-- Modal Content -->
        <div 
          class="relative bg-base-100 rounded-2xl shadow-2xl max-w-md w-full p-6"
        >
          <!-- Header -->
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-xl font-bold">Connect Wallet</h3>
            <button 
              @click="showWalletSelector = false"
              class="btn btn-sm btn-ghost btn-circle"
            >
              <Icon icon="mdi:close" class="text-xl" />
            </button>
          </div>
          
          <!-- Wallet Options -->
          <div class="space-y-4">
            <!-- Keplr Option -->
            <button
              @click="connectKeplr"
              class="w-full p-4 rounded-xl border-2 border-gray-200 dark:border-gray-700 hover:border-purple-500 dark:hover:border-purple-500 transition-all duration-200 flex items-center justify-between group"
            >
              <div class="flex items-center gap-4">
                <div class="w-12 h-12 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
                  <Icon icon="mdi:alpha-k-circle" class="text-2xl text-purple-600 dark:text-purple-400" />
                </div>
                <div class="text-left">
                  <h4 class="font-semibold text-gray-900 dark:text-white">Keplr</h4>
                  <p class="text-sm text-gray-500 dark:text-gray-400">For Cosmos chains</p>
                </div>
              </div>
              <Icon icon="mdi:chevron-right" class="text-xl text-gray-400 group-hover:text-purple-500 transition-colors" />
            </button>
            
            <!-- MetaMask Option -->
            <button
              @click="connectMetaMask"
              class="w-full p-4 rounded-xl border-2 border-gray-200 dark:border-gray-700 hover:border-orange-500 dark:hover:border-orange-500 transition-all duration-200 flex items-center justify-between group"
            >
              <div class="flex items-center gap-4">
                <div class="w-12 h-12 rounded-full bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center">
                  <Icon icon="simple-icons:metamask" class="text-2xl text-orange-600 dark:text-orange-400" />
                </div>
                <div class="text-left">
                  <h4 class="font-semibold text-gray-900 dark:text-white">MetaMask</h4>
                  <p class="text-sm text-gray-500 dark:text-gray-400">For EVM chains</p>
                </div>
              </div>
              <Icon icon="mdi:chevron-right" class="text-xl text-gray-400 group-hover:text-orange-500 transition-colors" />
            </button>
          </div>
        </div>
      </div>
    </Teleport>
    
    <!-- Toast Notifications -->
    <div class="toast toast-top toast-end z-[2100]" v-show="showCopyToast > 0">
      <div 
        class="alert"
        :class="tipMsg.class === 'success' ? 'alert-success' : 'alert-error'"
      >
        <span>{{ tipMsg.msg }}</span>
      </div>
    </div>
  </div>
  <Teleport to="body">
    <ping-connect-wallet
      id="PingConnectWallet"
      :chain-id="baseStore.currentChainId || 'cosmoshub-4'"
      :hd-path="chainStore.defaultHDPath"
      :addr-prefix="chainStore.current?.bech32Prefix || 'cosmos'"
      @connect="walletStateChange"
      @keplr-config="walletStore.suggestChain()"
      :params="params"
    />
  </Teleport>
</template>

<style>
/* Make ping wallet visible but hidden */
ping-connect-wallet {
  opacity: 1 !important;
  pointer-events: auto !important;
}

.ping-connect-btn {
  opacity: 0 !important;
  position: fixed !important;
  bottom: 20px !important;
  right: 20px !important;
  z-index: -1 !important;
  pointer-events: auto !important;
}

.ping-connect-dropdown {
  /* Allow dropdown to work */
}
</style>
