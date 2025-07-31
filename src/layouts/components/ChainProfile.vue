<script setup lang="ts">
import { useBlockchain, useBaseStore } from '@/stores';
import type { Endpoint } from '@/types/chaindata';
import { useRouter } from 'vue-router';
import { ref } from 'vue';

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
    <div @click="toggleModal" class="flex items-center cursor-pointer">
      <div class="p-1 relative mr-3">
        <img v-lazy="chainStore.logo" class="w-9 h-9 rounded-full" />
        <div
          class="w-2 h-2 rounded-full absolute right-0 bottom-0 shadow"
          :class="{
            'bg-success': baseStore.connected,
            'bg-error': !baseStore.connected,
          }"
        ></div>
      </div>
      <div class="flex-1 w-0">
        <div
          :key="baseStore.latest?.block?.header?.height || chainStore.chainName || ''"
          class="capitalize whitespace-nowrap text-base font-semibold text-gray-600 dark:text-gray-200 hidden md:!block"
        >
          {{
            baseStore.latest?.block?.header?.height
              ? `#${baseStore.latest.block.header.height}`
              : chainStore.chainName || ''
          }}
          <span class="text-error">{{ baseStore.connected ? '' : 'disconnected' }}</span>
        </div>
        <div class="text-xs text-gray-500 dark:text-gray-400 whitespace-nowrap hidden md:!block">
          {{ chainStore.connErr || chainStore.endpoint.address }}
        </div>
      </div>
    </div>

    <!-- Modal overlay -->
    <Teleport to="body">
      <div v-if="showModal" class="fixed inset-0 z-[99999] flex items-start justify-center pt-20" @click="showModal = false">
        <!-- Backdrop -->
        <div class="absolute inset-0 bg-black/50"></div>
        
        <!-- Modal content -->
        <div class="relative bg-base-100 dark:bg-base-200 rounded-2xl shadow-2xl w-96 max-h-[80vh] overflow-auto p-4" @click.stop>
          <!-- Close button -->
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-bold">Network Selection</h3>
            <button @click="showModal = false" class="btn btn-sm btn-circle btn-ghost">✕</button>
          </div>
          
          <!-- Rest Endpoints -->
          <div class="mb-4">
            <div class="text-sm text-gray-400 mb-2" v-if="chainStore.current?.endpoints?.rest">Rest Endpoint</div>
            <div
              v-for="(item, index) in chainStore.current?.endpoints?.rest?.filter(endpoint => !endpoint.address.includes('127.0.0.1') && !endpoint.address.includes('localhost'))"
              class="px-4 py-2 w-full hover:bg-gray-100 dark:hover:bg-[#384059] cursor-pointer rounded-lg mb-1"
              :key="index"
              @click="changeEndpoint(item)"
            >
              <div class="flex flex-col">
                <div class="flex items-center justify-between w-full">
                  <div class="text-gray-500 dark:text-gray-200 capitalize">
                    {{ item.provider }}
                  </div>
                  <span
                    v-if="item.address === chainStore.endpoint?.address"
                    class="bg-success inline-block h-2 w-2 rounded-full"
                  />
                </div>
                <div class="text-gray-400 text-xs whitespace-nowrap">
                  {{ item.address }}
                </div>
              </div>
            </div>
          </div>

          <!-- Information -->
          <div class="border-t border-gray-300 dark:border-gray-700 pt-4">
            <div class="text-sm text-gray-400 mb-2">Information</div>
            <div class="space-y-2">
              <div class="text-sm">
                <span class="text-gray-500">Chain Id:</span>
                <span class="ml-2 font-mono">
                  {{
                    baseStore.latest.block?.header.chain_id && baseStore.connected
                      ? baseStore.latest.block.header.chain_id
                      : 'N/A'
                  }}
                </span>
              </div>
              <div class="text-sm">
                <span class="text-gray-500">Height:</span>
                <span class="ml-2 font-mono">
                  {{
                    baseStore.latest.block?.header.height && baseStore.connected ? baseStore.latest.block.header.height : '0'
                  }}
                </span>
              </div>
            </div>
          </div>
        </div>
    </div>
    </Teleport>
  </div>
</template>
