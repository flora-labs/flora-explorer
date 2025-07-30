<script setup lang="ts">
import { useRoute } from 'vue-router';
import { useBaseStore, useBlockchain, useWalletStore } from '@/stores';
import { Icon } from '@iconify/vue';
import { ref, computed, onMounted, onUnmounted } from 'vue';

const route = useRoute();
const walletStore = useWalletStore();
const chainStore = useBlockchain();
const baseStore = useBaseStore();
const showDrawer = ref(false);

// Handle escape key
const handleEscape = (e: KeyboardEvent) => {
  if (e.key === 'Escape' && showDrawer.value) {
    showDrawer.value = false;
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
</script>

<template>
  <div>
    <!-- Wallet Button -->
    <button
      @click="showDrawer = true"
      class="btn btn-sm btn-primary m-1 lowercase truncate !inline-flex text-xs md:!text-sm"
    >
      <Icon icon="mdi:wallet" />
      <span class="ml-1 hidden md:block"> {{ walletStore.shortAddress || 'Wallet' }}</span>
    </button>

    <!-- Wallet Drawer -->
    <Teleport to="body">
      <div v-if="showDrawer" class="fixed inset-0 z-[2000]">
        <!-- Backdrop -->
        <div 
          class="absolute inset-0 bg-black/50 backdrop-blur-sm"
          @click="showDrawer = false"
        ></div>
        
        <!-- Drawer Content -->
        <div 
          class="absolute right-0 top-0 h-full w-full sm:w-80 bg-base-100 shadow-2xl transform transition-transform duration-300 overflow-y-auto"
          :class="showDrawer ? 'translate-x-0' : 'translate-x-full'"
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
            <div v-if="!walletStore?.currentAddress">
              <label
                for="PingConnectWallet"
                class="btn btn-primary w-full"
                @click="showDrawer = false"
              >
                <Icon icon="mdi:wallet" /><span class="ml-2">Connect Wallet</span>
              </label>
            </div>
            
            <div v-else>
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
.ping-connect-btn,
.ping-connect-dropdown {
  display: none !important;
}
</style>
