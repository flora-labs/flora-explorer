<script setup lang="ts">
import { useBlockchain, useBaseStore } from '@/stores';
import type { Endpoint } from '@/types/chaindata';
import { useRouter } from 'vue-router';
import { ref } from 'vue';
import { Icon } from '@iconify/vue';

const chainStore = useBlockchain();
const baseStore = useBaseStore();
chainStore.initial();
const router = useRouter();
const showModal = ref(false);

function changeEndpoint(item: Endpoint) {
  chainStore.setRestEndpoint(item);
  showModal.value = false;
  if (chainStore.current) router.push(`/${chainStore.current.chainName}`);
}

function toggleModal() {
  showModal.value = !showModal.value;
}
</script>

<template>
  <div>
    <!-- Clickable area -->
    <div @click="toggleModal" class="flex items-center cursor-pointer group px-3 py-2 rounded-xl hover:bg-gray-100 dark:hover:bg-white/5 transition-all duration-200">
      <div class="p-1 relative mr-3">
        <img v-lazy="chainStore.logo" class="w-9 h-9 rounded-full ring-2 ring-white/20 group-hover:ring-purple-500/30 transition-all duration-200" />
        <div
          class="w-2.5 h-2.5 rounded-full absolute right-0 bottom-0 ring-2 ring-white dark:ring-gray-900 transition-all duration-200"
          :class="{
            'bg-green-500 shadow-lg shadow-green-500/50': baseStore.connected,
            'bg-red-500 shadow-lg shadow-red-500/50': !baseStore.connected,
          }"
        ></div>
      </div>
      <div class="flex-1 w-0">
        <div
          :key="baseStore.latest?.block?.header?.height || chainStore.chainName || ''"
          class="capitalize whitespace-nowrap text-base font-semibold text-gray-700 dark:text-gray-200 hidden md:!block transition-colors duration-200 group-hover:text-purple-600 dark:group-hover:text-purple-400"
        >
          {{
            baseStore.latest?.block?.header?.height
              ? `#${baseStore.latest.block.header.height.toLocaleString()}`
              : chainStore.chainName || ''
          }}
          <span class="text-red-500 dark:text-red-400 ml-1">{{ baseStore.connected ? '' : '(disconnected)' }}</span>
        </div>
        <div class="text-xs text-gray-500 dark:text-gray-400 whitespace-nowrap hidden md:!block">
          {{ chainStore.connErr || chainStore.endpoint.address.replace('testnet-api', 'devnet-api') }}
        </div>
      </div>
      <Icon icon="mdi:chevron-down" class="text-gray-400 group-hover:text-purple-500 transition-all duration-200 ml-2" />
    </div>

    <!-- Modal overlay -->
    <Teleport to="body">
      <div v-if="showModal" class="fixed inset-0 z-[99999] flex items-start justify-center pt-20" @click="showModal = false">
        <!-- Backdrop -->
        <div class="absolute inset-0 bg-black/50"></div>
        
        <!-- Modal content -->
        <div class="relative backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-2xl w-96 max-h-[80vh] overflow-hidden" @click.stop>
          <!-- Background decorations -->
          <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-purple-500/10 to-blue-500/10 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
          <div class="absolute bottom-0 left-0 w-48 h-48 bg-gradient-to-tr from-blue-500/10 to-indigo-500/10 rounded-full blur-3xl transform -translate-x-24 translate-y-24"></div>
          
          <!-- Header -->
          <div class="relative p-6 border-b border-gray-200 dark:border-white/10">
            <div class="flex items-center justify-between">
              <h3 class="text-xl font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <Icon icon="mdi:network" class="text-purple-500/70" />
                Network Selection
              </h3>
              <button 
                @click="showModal = false"
                class="w-8 h-8 rounded-full backdrop-blur-md bg-white/20 dark:bg-white/5 hover:bg-white/30 dark:hover:bg-white/10 border border-gray-300 dark:border-white/10 flex items-center justify-center transition-all duration-200 hover:scale-105 group"
              >
                <Icon icon="mdi:close" class="text-lg text-gray-600 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white transition-colors" />
              </button>
            </div>
          </div>
          
          <!-- Content with scrollable area -->
          <div class="relative max-h-[60vh] overflow-y-auto p-6">
            <!-- Rest Endpoints Section -->
            <div class="mb-6">
              <div class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3 flex items-center gap-2" v-if="chainStore.current?.endpoints?.rest">
                <Icon icon="mdi:server-network" class="text-blue-500/70" />
                Rest Endpoints
              </div>
              <div class="space-y-2">
                <div
                  v-for="(item, index) in chainStore.current?.endpoints?.rest?.filter(endpoint => endpoint.address.startsWith('https://') && !endpoint.address.includes('127.0.0.1') && !endpoint.address.includes('localhost'))"
                  class="relative group backdrop-blur-md bg-white/50 dark:bg-white/5 hover:bg-white/70 dark:hover:bg-white/10 border border-gray-200 dark:border-white/10 hover:border-purple-500/30 rounded-xl p-4 cursor-pointer transition-all duration-200 hover:scale-[1.02] hover:shadow-md"
                  :class="{
                    'bg-purple-500/10 dark:bg-purple-500/10 border-purple-500/30': item.address === chainStore.endpoint?.address
                  }"
                  :key="index"
                  @click="changeEndpoint(item)"
                >
                  <div class="flex items-center justify-between">
                    <div>
                      <div class="font-medium text-gray-900 dark:text-white capitalize flex items-center gap-2">
                        {{ item.provider }}
                        <span
                          v-if="item.address === chainStore.endpoint?.address"
                          class="inline-flex items-center gap-1 text-xs font-normal text-purple-600 dark:text-purple-400"
                        >
                          <Icon icon="mdi:check-circle" class="text-sm" />
                          Active
                        </span>
                      </div>
                      <div class="text-sm text-gray-600 dark:text-gray-400 font-mono mt-1">
                        {{ item.address.replace('testnet-api', 'devnet-api') }}
                      </div>
                    </div>
                    <Icon 
                      icon="mdi:chevron-right" 
                      class="text-gray-400 group-hover:text-purple-500 transition-colors"
                      :class="{ 'text-purple-500': item.address === chainStore.endpoint?.address }"
                    />
                  </div>
                </div>
              </div>
            </div>

            <!-- Information Section -->
            <div class="mt-6">
              <div class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3 flex items-center gap-2">
                <Icon icon="mdi:information-outline" class="text-indigo-500/70" />
                Network Information
              </div>
              <div class="backdrop-blur-md bg-white/50 dark:bg-white/5 border border-gray-200 dark:border-white/10 rounded-xl p-4">
                <div class="space-y-3">
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-gray-600 dark:text-gray-400">Chain ID</span>
                    <span class="text-sm font-mono font-medium text-gray-900 dark:text-white">
                      {{
                        baseStore.latest.block?.header.chain_id && baseStore.connected
                          ? baseStore.latest.block.header.chain_id
                          : 'Not Connected'
                      }}
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-gray-600 dark:text-gray-400">Block Height</span>
                    <span class="text-sm font-mono font-medium text-gray-900 dark:text-white flex items-center gap-1">
                      <Icon v-if="baseStore.connected" icon="mdi:cube" class="text-amber-500/70" />
                      {{
                        baseStore.latest.block?.header.height && baseStore.connected 
                          ? `#${baseStore.latest.block.header.height.toLocaleString()}` 
                          : '---'
                      }}
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-gray-600 dark:text-gray-400">Status</span>
                    <span class="text-sm flex items-center gap-2">
                      <span 
                        class="w-2 h-2 rounded-full"
                        :class="{
                          'bg-green-500 shadow-lg shadow-green-500/50': baseStore.connected,
                          'bg-red-500 shadow-lg shadow-red-500/50': !baseStore.connected
                        }"
                      ></span>
                      <span :class="{
                        'text-green-600 dark:text-green-400': baseStore.connected,
                        'text-red-600 dark:text-red-400': !baseStore.connected
                      }">
                        {{ baseStore.connected ? 'Connected' : 'Disconnected' }}
                      </span>
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
    </div>
    </Teleport>
  </div>
</template>
