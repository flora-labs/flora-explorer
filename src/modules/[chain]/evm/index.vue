<script lang="ts" setup>
import { useBlockchain } from '@/stores';
import { ref, onMounted, computed, onUnmounted } from 'vue';
import { Icon } from '@iconify/vue';

const props = defineProps(['chain']);
const blockchain = useBlockchain();

// EVM State
const evmRpcEndpoint = ref('');
const chainId = ref('');
const isConnected = ref(false);
const walletAddress = ref('');
const balance = ref('0');

// Gas Prices (in Gwei)
const gasPrice = ref({
  slow: '0',
  standard: '0',
  fast: '0'
});

// Latest blocks
const latestBlocks = ref([]);

// Latest transactions
const latestTransactions = ref([]);

// Network stats
const networkStats = ref({
  blockNumber: '0',
  gasPrice: '0',
  chainId: '',
  avgBlockTime: '0s'
});

// Loading states
const isLoading = ref({
  blocks: false,
  transactions: false,
  stats: false,
  gasPrice: false
});

// Error states
const errors = ref({
  rpc: '',
  general: ''
});

// Search
const searchQuery = ref('');
const searchType = ref('all'); // all, address, tx, block

// Timer for updates
let updateTimer: any = null;

onMounted(async () => {
  // Get EVM RPC from chain config
  const chainConfig = blockchain.current;
  if (chainConfig?.evm?.rpc && chainConfig.evm.rpc.length > 0) {
    // Handle both string and object formats for RPC endpoints
    const rpcEndpoint = chainConfig.evm.rpc[0];
    evmRpcEndpoint.value = typeof rpcEndpoint === 'string' 
      ? rpcEndpoint 
      : rpcEndpoint.address || rpcEndpoint;
    
    // Use chain ID from config if available
    if (chainConfig.evm.chainId) {
      // Convert hex chain ID to decimal
      chainId.value = parseInt(chainConfig.evm.chainId, 16).toString();
      networkStats.value.chainId = chainId.value;
    }
    
    // Fetch initial data
    await fetchChainId();
    await fetchNetworkStats();
    await fetchLatestBlocks();
    await fetchGasPrice();
    
    // Check if MetaMask is available
    checkMetaMaskConnection();
    
    // Start update timer
    updateTimer = setInterval(async () => {
      await fetchGasPrice();
      await fetchLatestBlocks();
      await fetchNetworkStats();
    }, 10000); // Update every 10 seconds
  } else {
    // No EVM configuration available
    errors.value.rpc = 'No EVM configuration found for this chain';
  }
});

onUnmounted(() => {
  if (updateTimer) {
    clearInterval(updateTimer);
  }
});

// Fetch chain ID
async function fetchChainId() {
  if (!evmRpcEndpoint.value) {
    console.error('No EVM RPC endpoint configured');
    return;
  }
  
  try {
    const response = await fetch(evmRpcEndpoint.value, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        jsonrpc: '2.0',
        method: 'eth_chainId',
        params: [],
        id: 1
      })
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const data = await response.json();
    if (data.result) {
      const id = parseInt(data.result, 16);
      chainId.value = id.toString();
      networkStats.value.chainId = chainId.value;
      errors.value.rpc = ''; // Clear any previous errors
    }
  } catch (error) {
    console.error('Error fetching chain ID:', error);
    errors.value.rpc = `Unable to connect to EVM RPC endpoint at ${evmRpcEndpoint.value}`;
  }
}

// Fetch gas price
async function fetchGasPrice() {
  if (!evmRpcEndpoint.value) return;
  
  try {
    isLoading.value.gasPrice = true;
    const response = await fetch(evmRpcEndpoint.value, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        jsonrpc: '2.0',
        method: 'eth_gasPrice',
        params: [],
        id: 1
      })
    });
    const data = await response.json();
    if (data.result) {
      const gasPriceWei = parseInt(data.result, 16);
      const gasPriceGwei = Math.max(1, Math.round(gasPriceWei / 1e9));
      networkStats.value.gasPrice = gasPriceGwei.toString();
      
      // Set gas tiers (estimated)
      gasPrice.value = {
        slow: gasPriceGwei.toString(),
        standard: Math.round(gasPriceGwei * 1.2).toString(),
        fast: Math.round(gasPriceGwei * 1.5).toString()
      };
    }
  } catch (error) {
    console.error('Error fetching gas price:', error);
  } finally {
    isLoading.value.gasPrice = false;
  }
}

// Fetch network stats
async function fetchNetworkStats() {
  if (!evmRpcEndpoint.value) return;
  
  try {
    isLoading.value.stats = true;
    const response = await fetch(evmRpcEndpoint.value, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        jsonrpc: '2.0',
        method: 'eth_blockNumber',
        params: [],
        id: 1
      })
    });
    const data = await response.json();
    if (data.result) {
      networkStats.value.blockNumber = parseInt(data.result, 16).toLocaleString();
    }
  } catch (error) {
    console.error('Error fetching network stats:', error);
  } finally {
    isLoading.value.stats = false;
  }
}

// Fetch latest blocks
async function fetchLatestBlocks() {
  if (!evmRpcEndpoint.value) return;
  
  try {
    isLoading.value.blocks = true;
    const blockNumberResponse = await fetch(evmRpcEndpoint.value, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        jsonrpc: '2.0',
        method: 'eth_blockNumber',
        params: [],
        id: 1
      })
    });
    const blockNumberData = await blockNumberResponse.json();
    
    if (blockNumberData.result) {
      const currentBlock = parseInt(blockNumberData.result, 16);
      const blocks = [];
      
      // Fetch last 4 blocks
      const blockPromises = [];
      for (let i = 0; i < 4; i++) {
        const blockNum = currentBlock - i;
        if (blockNum < 0) continue;
        
        blockPromises.push(
          fetch(evmRpcEndpoint.value, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              jsonrpc: '2.0',
              method: 'eth_getBlockByNumber',
              params: [`0x${blockNum.toString(16)}`, false],
              id: blockNum
            })
          }).then(res => res.json())
        );
      }
      
      const blockResponses = await Promise.all(blockPromises);
      
      for (const blockData of blockResponses) {
        if (blockData.result) {
          const block = blockData.result;
          blocks.push({
            number: parseInt(block.number, 16).toString(),
            transactions: block.transactions?.length || 0,
            timestamp: parseInt(block.timestamp, 16) * 1000,
            miner: block.miner ? formatAddress(block.miner) : '0x0000...0000',
            hash: block.hash ? formatAddress(block.hash) : '',
            gasUsed: block.gasUsed ? parseInt(block.gasUsed, 16) : 0,
            gasLimit: block.gasLimit ? parseInt(block.gasLimit, 16) : 0
          });
        }
      }
      
      latestBlocks.value = blocks.sort((a, b) => parseInt(b.number) - parseInt(a.number));
      
      // Calculate average block time
      if (blocks.length > 1) {
        const timeDiff = blocks[0].timestamp - blocks[blocks.length - 1].timestamp;
        const blockDiff = parseInt(blocks[0].number) - parseInt(blocks[blocks.length - 1].number);
        if (blockDiff > 0) {
          const avgTime = Math.round(timeDiff / blockDiff / 1000);
          networkStats.value.avgBlockTime = `${avgTime}s`;
        }
      }
      
      // Fetch transactions from blocks with transactions
      const blocksWithTxs = blocks.filter(b => b.transactions > 0);
      if (blocksWithTxs.length > 0) {
        await fetchLatestTransactions(blocksWithTxs);
      }
    }
  } catch (error) {
    console.error('Error fetching blocks:', error);
    errors.value.general = 'Error fetching block data';
  } finally {
    isLoading.value.blocks = false;
  }
}

// Fetch latest transactions from multiple blocks
async function fetchLatestTransactions(blocks: any[]) {
  if (!evmRpcEndpoint.value) return;
  
  try {
    isLoading.value.transactions = true;
    const allTransactions = [];
    
    for (const block of blocks) {
      if (allTransactions.length >= 4) break;
      
      const blockResponse = await fetch(evmRpcEndpoint.value, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          jsonrpc: '2.0',
          method: 'eth_getBlockByNumber',
          params: [`0x${parseInt(block.number).toString(16)}`, true],
          id: 1
        })
      });
      const blockData = await blockResponse.json();
      
      if (blockData.result && blockData.result.transactions) {
        const remainingSlots = 4 - allTransactions.length;
        const txs = blockData.result.transactions.slice(0, remainingSlots).map((tx: any) => ({
          hash: formatAddress(tx.hash),
          from: formatAddress(tx.from),
          to: tx.to ? formatAddress(tx.to) : 'Contract Creation',
          value: (parseInt(tx.value || '0', 16) / 1e18).toFixed(4),
          blockNumber: parseInt(tx.blockNumber, 16),
          gasPrice: (parseInt(tx.gasPrice || '0', 16) / 1e9).toFixed(0) + ' Gwei',
          type: parseInt(tx.type || '0', 16),
          status: 'success' // We'd need to check receipts for actual status
        }));
        
        allTransactions.push(...txs);
      }
    }
    
    latestTransactions.value = allTransactions;
  } catch (error) {
    console.error('Error fetching transactions:', error);
  } finally {
    isLoading.value.transactions = false;
  }
}

// MetaMask functions
async function checkMetaMaskConnection() {
  if (typeof window.ethereum !== 'undefined') {
    try {
      const accounts = await window.ethereum.request({ method: 'eth_accounts' });
      if (accounts.length > 0) {
        isConnected.value = true;
        walletAddress.value = accounts[0];
        getBalance();
      }
    } catch (error) {
      console.error('Error checking MetaMask connection:', error);
    }
  }
}

async function connectWallet() {
  if (typeof window.ethereum !== 'undefined') {
    try {
      const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
      isConnected.value = true;
      walletAddress.value = accounts[0];
      
      // Add Flora network to MetaMask
      await addNetworkToMetaMask();
      
      // Get balance
      getBalance();
    } catch (error) {
      console.error('Error connecting wallet:', error);
    }
  } else {
    alert('Please install MetaMask to use this feature');
  }
}

async function addNetworkToMetaMask() {
  if (!evmRpcEndpoint.value || !chainId.value) return;
  
  try {
    // Ensure RPC URL is a string, not an object
    const rpcUrl = typeof evmRpcEndpoint.value === 'string' 
      ? evmRpcEndpoint.value 
      : evmRpcEndpoint.value.address || evmRpcEndpoint.value;
      
    await window.ethereum.request({
      method: 'wallet_addEthereumChain',
      params: [{
        chainId: `0x${parseInt(chainId.value).toString(16)}`,
        chainName: 'Flora Testnet EVM',
        rpcUrls: [rpcUrl],
        nativeCurrency: {
          name: 'FLORA',
          symbol: 'FLR',
          decimals: 18
        },
        blockExplorerUrls: [`http://localhost:5173/${props.chain}/evm`]
      }]
    });
  } catch (error) {
    console.error('Error adding network:', error);
  }
}

async function getBalance() {
  if (!walletAddress.value || !window.ethereum) return;
  
  try {
    const balanceHex = await window.ethereum.request({
      method: 'eth_getBalance',
      params: [walletAddress.value, 'latest']
    });
    // Convert from wei to ether
    const etherBalance = parseInt(balanceHex, 16) / 1e18;
    balance.value = etherBalance.toFixed(4);
  } catch (error) {
    console.error('Error getting balance:', error);
  }
}

function disconnectWallet() {
  isConnected.value = false;
  walletAddress.value = '';
  balance.value = '0';
}

// Format address
function formatAddress(address: string) {
  if (!address) return '';
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

// Format timestamp
function formatTime(timestamp: number) {
  const seconds = Math.floor((Date.now() - timestamp) / 1000);
  if (seconds < 60) return `${seconds}s ago`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  return `${Math.floor(seconds / 86400)}d ago`;
}

// Search function
function handleSearch() {
  if (!searchQuery.value) return;
  
  // In a real implementation, this would navigate to the appropriate page
  console.log('Searching for:', searchQuery.value, 'Type:', searchType.value);
  // TODO: Implement search functionality
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header with Wallet Connection -->
    <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-purple-500/5 to-blue-500/5 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
      
      <div class="relative">
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h2 class="text-3xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent flex items-center gap-3">
              <Icon icon="mdi:ethereum" class="text-purple-500" />
              EVM Explorer
            </h2>
            <div class="mt-2 space-y-1">
              <div class="flex items-center gap-4 text-sm">
                <span class="text-gray-600 dark:text-gray-400">Chain ID:</span>
                <span class="font-mono font-medium text-gray-900 dark:text-white">{{ chainId || 'Not configured' }}</span>
              </div>
              <div v-if="evmRpcEndpoint" class="flex items-center gap-4 text-sm">
                <span class="text-gray-600 dark:text-gray-400">RPC:</span>
                <span class="font-mono text-xs text-gray-900 dark:text-white">{{ evmRpcEndpoint }}</span>
              </div>
            </div>
          </div>
          
          <!-- Wallet Connection -->
          <div v-if="!isConnected" class="flex gap-2">
            <button 
              @click="connectWallet"
              class="px-6 py-3 rounded-xl font-semibold bg-gradient-to-r from-purple-500 to-blue-500 text-white shadow-lg hover:shadow-xl hover:from-purple-600 hover:to-blue-600 transition-all duration-300 transform hover:-translate-y-0.5 active:translate-y-0 active:shadow-md flex items-center gap-2"
            >
              <Icon icon="mdi:wallet" />
              Connect Wallet
            </button>
          </div>
          <div v-else class="bg-gray-100 dark:bg-white/5 rounded-2xl p-4 border border-gray-200 dark:border-white/10">
            <div class="flex items-center gap-4">
              <div>
                <div class="text-xs text-gray-600 dark:text-gray-400 mb-1">Connected Wallet</div>
                <div class="font-mono text-sm font-medium text-gray-900 dark:text-white">{{ formatAddress(walletAddress) }}</div>
              </div>
              <div class="border-l border-gray-300 dark:border-white/10 pl-4">
                <div class="text-xs text-gray-600 dark:text-gray-400 mb-1">Balance</div>
                <div class="font-semibold text-gray-900 dark:text-white">{{ balance }} FLR</div>
              </div>
              <button 
                @click="disconnectWallet"
                class="ml-2 p-2 rounded-lg hover:bg-gray-200 dark:hover:bg-white/10 transition-colors"
              >
                <Icon icon="mdi:close" class="text-gray-600 dark:text-gray-400" />
              </button>
            </div>
          </div>
        </div>
        
        <!-- Error display -->
        <div v-if="errors.rpc" class="mt-4 p-3 rounded-lg bg-red-500/10 text-red-600 dark:text-red-400 border border-red-500/20">
          <Icon icon="mdi:alert-circle" class="inline mr-2" />
          {{ errors.rpc }}
        </div>
      </div>
    </div>

    <!-- Search Bar -->
    <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none p-4">
      <div class="flex gap-2">
        <select 
          v-model="searchType"
          class="px-4 py-3 rounded-xl bg-gray-100 dark:bg-white/5 border border-gray-200 dark:border-white/10 focus:border-purple-500 dark:focus:border-purple-400 focus:ring-2 focus:ring-purple-500/20 dark:focus:ring-purple-400/20 transition-all duration-200"
        >
          <option value="all">All</option>
          <option value="address">Address</option>
          <option value="tx">Transaction</option>
          <option value="block">Block</option>
        </select>
        <input 
          v-model="searchQuery"
          @keyup.enter="handleSearch"
          type="text" 
          placeholder="Search by address, transaction hash, or block number..."
          class="flex-1 px-4 py-3 rounded-xl bg-gray-100 dark:bg-white/5 border border-gray-200 dark:border-white/10 focus:border-purple-500 dark:focus:border-purple-400 focus:ring-2 focus:ring-purple-500/20 dark:focus:ring-purple-400/20 transition-all duration-200"
        />
        <button 
          @click="handleSearch"
          class="px-6 py-3 rounded-xl font-semibold bg-gradient-to-r from-purple-500 to-blue-500 text-white shadow-lg hover:shadow-xl hover:from-purple-600 hover:to-blue-600 transition-all duration-300 transform hover:-translate-y-0.5 active:translate-y-0 active:shadow-md"
        >
          <Icon icon="mdi:magnify" class="text-xl" />
        </button>
      </div>
    </div>

    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      <!-- Latest Block -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-green-500/10 to-emerald-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Latest Block</div>
            <Icon icon="mdi:cube" class="text-2xl text-green-500/70 dark:text-green-400/70" />
          </div>
          <div class="text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 dark:from-green-400 dark:to-emerald-400 bg-clip-text text-transparent">
            #{{ networkStats.blockNumber || '0' }}
          </div>
        </div>
      </div>

      <!-- Current Gas Price -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-blue-500/10 to-cyan-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Gas Price</div>
            <Icon icon="mdi:gas-station" class="text-2xl text-blue-500/70 dark:text-blue-400/70" />
          </div>
          <div class="text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 dark:from-blue-400 dark:to-cyan-400 bg-clip-text text-transparent">
            <span v-if="isLoading.gasPrice" class="text-base">Loading...</span>
            <span v-else>{{ networkStats.gasPrice || '0' }} Gwei</span>
          </div>
        </div>
      </div>

      <!-- Average Block Time -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-purple-500/10 to-pink-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Avg Block Time</div>
            <Icon icon="mdi:timer" class="text-2xl text-purple-500/70 dark:text-purple-400/70" />
          </div>
          <div class="text-2xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 dark:from-purple-400 dark:to-pink-400 bg-clip-text text-transparent">
            {{ networkStats.avgBlockTime || 'N/A' }}
          </div>
        </div>
      </div>

      <!-- Chain ID -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-orange-500/10 to-red-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">Chain ID</div>
            <Icon icon="mdi:identifier" class="text-2xl text-orange-500/70 dark:text-orange-400/70" />
          </div>
          <div class="text-2xl font-bold bg-gradient-to-r from-orange-600 to-red-600 dark:from-orange-400 dark:to-red-400 bg-clip-text text-transparent">
            {{ chainId || 'N/A' }}
          </div>
        </div>
      </div>
    </div>

    <!-- Gas Tracker -->
    <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
      <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-amber-500/5 to-orange-500/5 rounded-full blur-2xl transform translate-x-24 -translate-y-24"></div>
      
      <div class="relative">
        <h3 class="text-xl font-bold bg-gradient-to-r from-amber-600 to-orange-600 dark:from-amber-400 dark:to-orange-400 bg-clip-text text-transparent mb-4 flex items-center gap-2">
          <Icon icon="mdi:gas-station" />
          Gas Tracker
        </h3>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <!-- Slow -->
          <div class="bg-gradient-to-br from-green-500/10 to-emerald-500/10 rounded-2xl p-4 border border-green-500/20">
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Slow</span>
              <Icon icon="mdi:tortoise" class="text-green-600 dark:text-green-400" />
            </div>
            <div class="text-2xl font-bold text-green-600 dark:text-green-400">{{ gasPrice.slow }} Gwei</div>
            <div class="text-xs text-gray-600 dark:text-gray-400 mt-1">~10 mins</div>
          </div>
          
          <!-- Standard -->
          <div class="bg-gradient-to-br from-blue-500/10 to-cyan-500/10 rounded-2xl p-4 border border-blue-500/20">
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Standard</span>
              <Icon icon="mdi:rabbit" class="text-blue-600 dark:text-blue-400" />
            </div>
            <div class="text-2xl font-bold text-blue-600 dark:text-blue-400">{{ gasPrice.standard }} Gwei</div>
            <div class="text-xs text-gray-600 dark:text-gray-400 mt-1">~3 mins</div>
          </div>
          
          <!-- Fast -->
          <div class="bg-gradient-to-br from-purple-500/10 to-pink-500/10 rounded-2xl p-4 border border-purple-500/20">
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Fast</span>
              <Icon icon="mdi:rocket" class="text-purple-600 dark:text-purple-400" />
            </div>
            <div class="text-2xl font-bold text-purple-600 dark:text-purple-400">{{ gasPrice.fast }} Gwei</div>
            <div class="text-xs text-gray-600 dark:text-gray-400 mt-1">~30 secs</div>
          </div>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Latest Blocks -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
        <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-indigo-500/5 to-purple-500/5 rounded-full blur-2xl transform translate-x-24 -translate-y-24"></div>
        
        <div class="relative">
          <h3 class="text-xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 dark:from-indigo-400 dark:to-purple-400 bg-clip-text text-transparent mb-4 flex items-center gap-2">
            <Icon icon="mdi:cube" />
            Latest Blocks
          </h3>
          
          <div v-if="isLoading.blocks" class="flex justify-center py-8">
            <Icon icon="mdi:loading" class="text-3xl text-indigo-600 dark:text-indigo-400 animate-spin" />
          </div>
          <div v-else-if="latestBlocks.length === 0" class="text-center py-8 text-gray-500 dark:text-gray-400">
            No blocks found
          </div>
          <div v-else class="space-y-3">
            <div v-for="block in latestBlocks" :key="block.number" 
              class="bg-gray-50 dark:bg-white/5 rounded-xl p-4 border border-gray-200 dark:border-white/10 hover:shadow-md transition-all duration-200"
            >
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-indigo-500/20 to-purple-500/20 flex items-center justify-center">
                    <Icon icon="mdi:cube-outline" class="text-indigo-600 dark:text-indigo-400" />
                  </div>
                  <div>
                    <div class="font-mono text-sm font-medium text-gray-900 dark:text-white">#{{ block.number }}</div>
                    <div class="text-xs text-gray-600 dark:text-gray-400">{{ formatTime(block.timestamp) }}</div>
                  </div>
                </div>
                <div class="text-right">
                  <div class="text-sm font-medium text-gray-900 dark:text-white">{{ block.transactions }} txns</div>
                  <div class="text-xs text-gray-600 dark:text-gray-400">Miner: {{ block.miner }}</div>
                </div>
              </div>
            </div>
          </div>
          
          <button class="mt-4 w-full px-4 py-2 rounded-xl bg-gray-100 dark:bg-white/5 hover:bg-gray-200 dark:hover:bg-white/10 transition-colors text-sm font-medium text-gray-700 dark:text-gray-300">
            View All Blocks →
          </button>
        </div>
      </div>

      <!-- Latest Transactions -->
      <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden p-6">
        <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-green-500/5 to-emerald-500/5 rounded-full blur-2xl transform translate-x-24 -translate-y-24"></div>
        
        <div class="relative">
          <h3 class="text-xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 dark:from-green-400 dark:to-emerald-400 bg-clip-text text-transparent mb-4 flex items-center gap-2">
            <Icon icon="mdi:swap-horizontal" />
            Latest Transactions
          </h3>
          
          <div v-if="isLoading.transactions" class="flex justify-center py-8">
            <Icon icon="mdi:loading" class="text-3xl text-green-600 dark:text-green-400 animate-spin" />
          </div>
          <div v-else-if="latestTransactions.length === 0" class="text-center py-8 text-gray-500 dark:text-gray-400">
            No recent transactions
          </div>
          <div v-else class="space-y-3">
            <div v-for="tx in latestTransactions" :key="tx.hash" 
              class="bg-gray-50 dark:bg-white/5 rounded-xl p-4 border border-gray-200 dark:border-white/10 hover:shadow-md transition-all duration-200"
            >
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-green-500/20 to-emerald-500/20 flex items-center justify-center">
                    <Icon icon="mdi:arrow-right" class="text-green-600 dark:text-green-400" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="font-mono text-sm font-medium text-gray-900 dark:text-white truncate">{{ tx.hash }}</div>
                    <div class="text-xs text-gray-600 dark:text-gray-400 truncate">
                      From {{ tx.from }} → {{ tx.to }}
                    </div>
                  </div>
                </div>
                <div class="text-right ml-4">
                  <div class="text-sm font-medium text-gray-900 dark:text-white">{{ tx.value }} FLR</div>
                  <div class="text-xs text-gray-600 dark:text-gray-400">{{ tx.gasPrice }}</div>
                </div>
              </div>
            </div>
          </div>
          
          <button class="mt-4 w-full px-4 py-2 rounded-xl bg-gray-100 dark:bg-white/5 hover:bg-gray-200 dark:hover:bg-white/10 transition-colors text-sm font-medium text-gray-700 dark:text-gray-300">
            View All Transactions →
          </button>
        </div>
      </div>
    </div>

    <!-- Quick Actions -->
    <div class="backdrop-blur-xl bg-white/90 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none p-6">
      <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-4">Quick Actions</h3>
      
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <button class="bg-gradient-to-r from-purple-500/10 to-blue-500/10 hover:from-purple-500/20 hover:to-blue-500/20 rounded-2xl p-6 border border-purple-500/20 hover:border-purple-500/30 transition-all duration-200 hover:shadow-lg group">
          <Icon icon="mdi:file-document-plus" class="text-3xl text-purple-600 dark:text-purple-400 mb-3 group-hover:scale-110 transition-transform" />
          <h4 class="font-semibold text-gray-900 dark:text-white mb-1">Deploy Contract</h4>
          <p class="text-sm text-gray-600 dark:text-gray-400">Deploy a new smart contract</p>
        </button>
        
        <button class="bg-gradient-to-r from-green-500/10 to-emerald-500/10 hover:from-green-500/20 hover:to-emerald-500/20 rounded-2xl p-6 border border-green-500/20 hover:border-green-500/30 transition-all duration-200 hover:shadow-lg group">
          <Icon icon="mdi:code-braces" class="text-3xl text-green-600 dark:text-green-400 mb-3 group-hover:scale-110 transition-transform" />
          <h4 class="font-semibold text-gray-900 dark:text-white mb-1">Verify Contract</h4>
          <p class="text-sm text-gray-600 dark:text-gray-400">Verify and publish contract source</p>
        </button>
        
        <button class="bg-gradient-to-r from-blue-500/10 to-cyan-500/10 hover:from-blue-500/20 hover:to-cyan-500/20 rounded-2xl p-6 border border-blue-500/20 hover:border-blue-500/30 transition-all duration-200 hover:shadow-lg group">
          <Icon icon="mdi:api" class="text-3xl text-blue-600 dark:text-blue-400 mb-3 group-hover:scale-110 transition-transform" />
          <h4 class="font-semibold text-gray-900 dark:text-white mb-1">API Access</h4>
          <p class="text-sm text-gray-600 dark:text-gray-400">Access blockchain data via API</p>
        </button>
      </div>
    </div>
  </div>
</template>

<route>
{
  meta: {
    i18n: 'evm'
  }
}
</route>