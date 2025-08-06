<script lang="ts" setup>
import { useBaseStore, useBlockchain, useFormatter, useMintStore, useStakingStore, useTxDialog, useWalletStore } from '@/stores';
import { computed } from '@vue/reactivity';
import { onMounted, ref } from 'vue';
import { Icon } from '@iconify/vue';
import type { Key, SlashingParam, Validator } from '@/types';
import { formatSeconds } from '@/libs/utils';
import { diff } from 'semver';
import DelegateDialog from '@/components/DelegateDialog.vue';

const staking = useStakingStore();
const base = useBaseStore();
const format = useFormatter();
const dialog = useTxDialog();
const chainStore = useBlockchain();
const mintStore = useMintStore();
const walletStore = useWalletStore();

const cache = JSON.parse(localStorage.getItem('avatars') || '{}');
const avatars = ref(cache || {});
const latest = ref({} as Record<string, number>);
const yesterday = ref({} as Record<string, number>);
const tab = ref('active');
const unbondList = ref([] as Validator[]);
const slashing = ref({} as SlashingParam);

// Delegation dialog state
const showDelegateDialog = ref(false);
const selectedValidator = ref<Validator | null>(null);

onMounted(() => {
  staking.fetchUnbondingValdiators().then((res) => {
    unbondList.value = res.concat(unbondList.value);
  });
  staking.fetchInacitveValdiators().then((res) => {
    unbondList.value = unbondList.value.concat(res);
  });
  chainStore.rpc.getSlashingParams().then((res) => {
    slashing.value = res.params;
  });
});

async function fetchChange(blockWindow: number = 14400) {
  let page = 0;

  let height = Number(base.latest?.block?.header?.height || 0);
  if (height > blockWindow) {
    height -= blockWindow;
  } else {
    height = 1;
  }
  // voting power in 24h ago
  while (page < staking.validators.length && height > 0) {
    await base.fetchValidatorByHeight(height, page).then((x) => {
      x.validators.forEach((v) => {
        yesterday.value[v.pub_key.key] = Number(v.voting_power);
      });
    });
    page += 100;
  }

  page = 0;
  // voting power for now
  while (page < staking.validators.length) {
    await base.fetchLatestValidators(page).then((x) => {
      x.validators.forEach((v) => {
        latest.value[v.pub_key.key] = Number(v.voting_power);
      });
    });
    page += 100;
  }
}

const changes = computed(() => {
  const changes = {} as Record<string, number>;
  Object.keys(latest.value).forEach((k) => {
    const l = latest.value[k] || 0;
    const y = yesterday.value[k] || 0;
    changes[k] = l - y;
  });
  return changes;
});

const change24 = (entry: { consensus_pubkey: Key; tokens: string }) => {
  const txt = entry.consensus_pubkey.key;
  // const n: number = latest.value[txt];
  // const o: number = yesterday.value[txt];
  // // console.log( txt, n, o)
  // return n > 0 && o > 0 ? n - o : 0;

  const latestValue = latest.value[txt];
  if (!latestValue) {
    return 0;
  }

  const displayTokens = format.tokenAmountNumber({
    amount: parseInt(entry.tokens, 10).toString(),
    denom: staking.params.bond_denom,
  });
  const coefficient = displayTokens / latestValue;
  return changes.value[txt] * coefficient;
};

const handleDelegate = (validator: Validator) => {
  console.log('Delegate clicked for validator:', validator.operator_address);
  
  // Check if wallet is connected
  if (!walletStore.currentAddress) {
    alert('Please connect your wallet first!');
    return;
  }
  
  // Set the selected validator and show the custom dialog
  selectedValidator.value = validator;
  showDelegateDialog.value = true;
};

const onDelegationSuccess = (txHash: string) => {
  console.log('Delegation successful with TX hash:', txHash);
  // Refresh the staking data
  staking.fetchValidators();
  if (walletStore.currentAddress) {
    walletStore.loadMyAsset(walletStore.currentAddress);
  }
};

const change24Text = (entry: { consensus_pubkey: Key; tokens: string }) => {
  if (!entry) return '';
  const v = change24(entry);
  return v && v !== 0 ? format.showChanges(v) : '';
};

const change24Color = (entry: { consensus_pubkey: Key; tokens: string }) => {
  if (!entry) return '';
  const v = change24(entry);
  if (v > 0) return 'text-success';
  if (v < 0) return 'text-error';
};

const calculateRank = function (position: number) {
  let sum = 0;
  for (let i = 0; i < position; i++) {
    sum += Number(staking.validators[i]?.delegator_shares);
  }
  const percent = sum / staking.totalPower;

  switch (true) {
    case tab.value === 'active' && percent < 0.33:
      return 'error';
    case tab.value === 'active' && percent < 0.67:
      return 'warning';
    default:
      return 'primary';
  }
};

function isFeatured(endpoints: string[], who?: { website?: string; moniker: string }) {
  if (!endpoints || !who) return false;
  return (
    endpoints.findIndex(
      (x) =>
        (who.website && who.website?.substring(0, who.website?.lastIndexOf('.')).endsWith(x)) ||
        who?.moniker?.toLowerCase().search(x.toLowerCase()) > -1
    ) > -1
  );
}

const list = computed(() => {
  if (tab.value === 'active') {
    return staking.validators.map((x, i) => ({ v: x, rank: calculateRank(i), logo: logo(x.description.identity) }));
  } else if (tab.value === 'featured') {
    const endpoint = chainStore.current?.endpoints?.rest?.map((x) => x.provider);
    if (endpoint) {
      endpoint.push('ping');
      return staking.validators
        .filter((x) => isFeatured(endpoint.filter(Boolean) as string[], x.description))
        .map((x, i) => ({ v: x, rank: 'primary', logo: logo(x.description.identity) }));
    }
    return [];
  }
  return unbondList.value.map((x, i) => ({ v: x, rank: 'primary', logo: logo(x.description.identity) }));
});

const fetchAvatar = (identity: string) => {
  // fetch avatar from keybase
  return new Promise<void>((resolve) => {
    staking
      .keybase(identity)
      .then((d) => {
        if (Array.isArray(d.them) && d.them.length > 0) {
          const uri = String(d.them[0]?.pictures?.primary?.url).replace(
            'https://s3.amazonaws.com/keybase_processed_uploads/',
            ''
          );

          avatars.value[identity] = uri;
          resolve();
        } else throw new Error(`failed to fetch avatar for ${identity}`);
      })
      .catch((error) => {
        // console.error(error); // uncomment this if you want the user to see which avatars failed to load.
        resolve();
      });
  });
};

const loadAvatar = (identity: string) => {
  // fetches avatar from keybase and stores it in localStorage
  fetchAvatar(identity).then(() => {
    localStorage.setItem('avatars', JSON.stringify(avatars.value));
  });
};

const loadAvatars = () => {
  // fetches all avatars from keybase and stores it in localStorage
  const promises = staking.validators.map((validator) => {
    const identity = validator.description?.identity;

    // Here we also check whether we haven't already fetched the avatar
    if (identity && !avatars.value[identity]) {
      return fetchAvatar(identity);
    } else {
      return Promise.resolve();
    }
  });

  Promise.all(promises).then(() => localStorage.setItem('avatars', JSON.stringify(avatars.value)));
};

const logo = (identity?: string) => {
  if (!identity || !avatars.value[identity]) return '';
  const url = avatars.value[identity] || '';
  return url.startsWith('http') ? url : `https://s3.amazonaws.com/keybase_processed_uploads/${url}`;
};

const loaded = ref(false);
base.$subscribe((_, s) => {
  if (s.recents.length >= 2 && loaded.value === false) {
    loaded.value = true;
    const diff_time = Date.parse(s.recents[1].block.header.time) - Date.parse(s.recents[0].block.header.time);
    const diff_height = Number(s.recents[1].block.header.height) - Number(s.recents[0].block.header.height);
    const block_window = Number(Number((86400 * 1000 * diff_height) / diff_time).toFixed(0));
    fetchChange(block_window);
  }
});

loadAvatars();
</script>
<template>
  <div class="space-y-6">
    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      <!-- Inflation -->
      <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-green-500/10 to-emerald-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">{{ $t('staking.inflation') }}</div>
            <Icon icon="mdi:trending-up" class="text-2xl text-green-500/70 dark:text-green-400/70" />
          </div>
          <div class="text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 dark:from-green-400 dark:to-emerald-400 bg-clip-text text-transparent">
            {{ format.percent(mintStore.inflation) }}
          </div>
        </div>
      </div>

      <!-- Unbonding Time -->
      <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-blue-500/10 to-cyan-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">{{ $t('staking.unbonding_time') }}</div>
            <Icon icon="mdi:lock-open-outline" class="text-2xl text-blue-500/70 dark:text-blue-400/70" />
          </div>
          <div class="text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 dark:from-blue-400 dark:to-cyan-400 bg-clip-text text-transparent">
            {{ formatSeconds(staking.params?.unbonding_time) }}
          </div>
        </div>
      </div>

      <!-- Double Sign Slashing -->
      <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-red-500/10 to-orange-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">{{ $t('staking.double_sign_slashing') }}</div>
            <Icon icon="mdi:alert-octagon-outline" class="text-2xl text-red-500/70 dark:text-red-400/70" />
          </div>
          <div class="text-2xl font-bold bg-gradient-to-r from-red-600 to-orange-600 dark:from-red-400 dark:to-orange-400 bg-clip-text text-transparent">
            {{ format.percent(slashing.slash_fraction_double_sign) }}
          </div>
        </div>
      </div>

      <!-- Downtime Slashing -->
      <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 p-6 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-amber-500/10 to-orange-500/10 rounded-full blur-3xl transform translate-x-8 -translate-y-8"></div>
        <div class="relative">
          <div class="flex items-center justify-between mb-2">
            <div class="text-sm text-gray-600 dark:text-gray-400 font-medium">{{ $t('staking.downtime_slashing') }}</div>
            <Icon icon="mdi:pause" class="text-2xl text-amber-500/70 dark:text-amber-400/70" />
          </div>
          <div class="text-2xl font-bold bg-gradient-to-r from-amber-600 to-orange-600 dark:from-amber-400 dark:to-orange-400 bg-clip-text text-transparent">
            {{ format.percent(slashing.slash_fraction_downtime) }}
          </div>
        </div>
      </div>
    </div>

    <!-- Validator Table Section -->
    <div class="backdrop-blur-xl bg-white/95 dark:bg-white/5 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-purple-500/5 to-blue-500/5 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
      
      <!-- Header with tabs -->
      <div class="relative p-6 border-b border-gray-200 dark:border-white/10">
        <div class="flex items-center justify-between">
          <!-- Tab Navigation -->
          <div class="flex gap-2">
            <button 
              class="px-4 py-2 rounded-xl font-medium transition-all duration-200"
              :class="tab === 'featured' 
                ? 'bg-gradient-to-r from-purple-500/20 to-blue-500/20 text-purple-600 dark:text-purple-400 border border-purple-500/30' 
                : 'bg-gray-100 dark:bg-white/5 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-white/10'"
              @click="tab = 'featured'"
            >
              {{ $t('staking.popular') }}
            </button>
            <button 
              class="px-4 py-2 rounded-xl font-medium transition-all duration-200"
              :class="tab === 'active' 
                ? 'bg-gradient-to-r from-purple-500/20 to-blue-500/20 text-purple-600 dark:text-purple-400 border border-purple-500/30' 
                : 'bg-gray-100 dark:bg-white/5 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-white/10'"
              @click="tab = 'active'"
            >
              {{ $t('staking.active') }}
            </button>
            <button 
              class="px-4 py-2 rounded-xl font-medium transition-all duration-200"
              :class="tab === 'inactive' 
                ? 'bg-gradient-to-r from-purple-500/20 to-blue-500/20 text-purple-600 dark:text-purple-400 border border-purple-500/30' 
                : 'bg-gray-100 dark:bg-white/5 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-white/10'"
              @click="tab = 'inactive'"
            >
              {{ $t('staking.inactive') }}
            </button>
          </div>

          <!-- Validator Count -->
          <div class="text-lg font-semibold bg-gradient-to-r from-purple-600 to-blue-600 dark:from-purple-400 dark:to-blue-400 bg-clip-text text-transparent">
            {{ list.length }}/{{ staking.params.max_validators }}
          </div>
        </div>
      </div>

      <!-- Table Content -->
      <div class="p-6">
        <div class="overflow-x-auto">
          <table class="table staking-table w-full">
            <thead>
              <tr class="border-b border-gray-200 dark:border-white/10">
                <th scope="col" class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-2" style="width: 3rem">
                  {{ $t('staking.rank') }}
                </th>
                <th scope="col" class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-2">{{ $t('staking.validator') }}</th>
                <th scope="col" class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-2 text-right">{{ $t('staking.voting_power') }}</th>
                <th scope="col" class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-2 text-right">{{ $t('staking.24h_changes') }}</th>
                <th scope="col" class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-2 text-right">{{ $t('staking.commission') }}</th>
                <th scope="col" class="text-xs uppercase font-semibold text-gray-600 dark:text-gray-400 py-3 px-2 text-center">{{ $t('staking.actions') }}</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="({ v, rank, logo }, i) in list"
                :key="v.operator_address"
                class="border-b border-gray-100 dark:border-white/5 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors duration-200"
              >
                <!-- 👉 rank -->
                <td class="py-4 px-2">
                  <div class="text-xs font-semibold relative px-3 py-1 rounded-xl w-fit backdrop-blur-sm" 
                       :class="rank === 'error' ? 'bg-red-500/20 text-red-600 dark:text-red-400 border border-red-500/30' :
                               rank === 'warning' ? 'bg-amber-500/20 text-amber-600 dark:text-amber-400 border border-amber-500/30' :
                               'bg-blue-500/20 text-blue-600 dark:text-blue-400 border border-blue-500/30'">
                    {{ i + 1 }}
                  </div>
                </td>
                <!-- 👉 Validator -->
                <td class="py-4 px-2">
                  <div class="flex items-center overflow-hidden" style="max-width: 300px">
                    <div class="avatar mr-4 relative w-10 h-10 rounded-full overflow-hidden backdrop-blur-sm bg-gradient-to-br from-purple-500/10 to-blue-500/10 border border-purple-500/20">
                      <div class="w-10 h-10 rounded-full">
                        <img
                          v-if="logo"
                          :src="logo"
                          class="object-cover w-full h-full"
                          @error="
                            (e) => {
                              const identity = v.description?.identity;
                              if (identity) loadAvatar(identity);
                            }
                          "
                        />
                        <Icon v-else class="text-2xl text-purple-400 absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2" :icon="`mdi-account-circle`" />
                      </div>
                    </div>

                    <div class="flex flex-col">
                      <RouterLink
                        :to="{
                          name: 'chain-staking-validator',
                          params: {
                            validator: v.operator_address,
                          },
                        }"
                        class="text-sm font-semibold text-gray-900 dark:text-white hover:text-purple-600 dark:hover:text-purple-400 transition-colors"
                      >
                        {{ v.description?.moniker }}
                      </RouterLink>
                      <span class="text-xs text-gray-500 dark:text-gray-400">{{ v.description?.website || v.description?.identity || '-' }}</span>
                    </div>
                  </div>
                </td>

                <!-- 👉 Voting Power -->
                <td class="text-right py-4 px-2">
                  <div class="flex flex-col">
                    <div class="text-sm font-semibold text-gray-900 dark:text-white">
                      {{
                        format.formatToken(
                          {
                            amount: parseInt(v.tokens).toString(),
                            denom: staking.params.bond_denom,
                          },
                          true,
                          '0,0'
                        )
                      }}
                    </div>
                    <span class="text-xs text-gray-500 dark:text-gray-400">{{ format.calculatePercent(v.delegator_shares, staking.totalPower) }}</span>
                  </div>
                </td>
                <!-- 👉 24h Changes -->
                <td class="text-right py-4 px-2">
                  <span class="text-sm font-semibold" :class="change24Color(v)">
                    {{ change24Text(v) }}
                  </span>
                </td>
                <!-- 👉 commission -->
                <td class="text-right py-4 px-2">
                  <span class="text-sm text-gray-600 dark:text-gray-400">
                    {{ format.formatCommissionRate(v.commission?.commission_rates?.rate) }}
                  </span>
                </td>
                <!-- 👉 Action -->
                <td class="text-center py-4 px-2">
                  <div v-if="v.jailed" class="inline-flex items-center gap-1 px-3 py-1 rounded-xl text-xs font-medium bg-red-500/20 text-red-600 dark:text-red-400 border border-red-500/30">
                    <Icon icon="mdi:lock" class="text-sm" />
                    {{ $t('staking.jailed') }}
                  </div>
                  <button
                    v-else
                    class="px-4 py-2 rounded-xl text-xs font-medium bg-gradient-to-r from-purple-500/20 to-blue-500/20 hover:from-purple-500/30 hover:to-blue-500/30 text-purple-600 dark:text-purple-400 border border-purple-500/30 transition-all duration-200 transform hover:scale-105"
                    @click="handleDelegate(v)"
                  >
                    {{ $t('account.btn_delegate') }}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Legend Footer -->
      <div class="p-6 pt-0">
        <div class="flex flex-wrap items-center gap-4 text-sm">
          <div class="flex items-center gap-2">
            <div class="px-3 py-1 rounded-xl text-xs font-medium bg-red-500/20 text-red-600 dark:text-red-400 border border-red-500/30">
              {{ $t('staking.top') }} 33%
            </div>
            <span class="text-gray-600 dark:text-gray-400">Most centralized</span>
          </div>
          <div class="flex items-center gap-2">
            <div class="px-3 py-1 rounded-xl text-xs font-medium bg-amber-500/20 text-amber-600 dark:text-amber-400 border border-amber-500/30">
              {{ $t('staking.top') }} 67%
            </div>
            <span class="text-gray-600 dark:text-gray-400">Moderately distributed</span>
          </div>
          <div class="flex-1 text-xs text-gray-500 dark:text-gray-400 hidden md:block text-right">
            {{ $t('staking.description') }}
          </div>
        </div>
      </div>
    </div>
  </div>
  
  <!-- Delegation Dialog -->
  <DelegateDialog 
    v-model="showDelegateDialog"
    :validator-address="selectedValidator?.operator_address || ''"
    :validator-name="selectedValidator?.description?.moniker"
    @success="onDelegationSuccess"
  />
</template>

<route>
  {
    meta: {
      i18n: 'staking',
      order: 3
    }
  }
</route>

<style>
.staking-table.table :where(th, td) {
  padding: 8px 5px;
  background: transparent;
}
</style>
