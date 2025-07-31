<script setup lang="ts">
import { parseCoins } from '@cosmjs/stargate';
import {
  useBankStore,
  useBlockchain,
  useDistributionStore,
  useFormatter,
  useMintStore,
  useStakingStore,
  useTxDialog,
} from '@/stores';
import { onMounted, computed, ref } from 'vue';
import { Icon } from '@iconify/vue';
import CommissionRate from '@/components/ValidatorCommissionRate.vue';
import { consensusPubkeyToHexAddress, operatorAddressToAccount, pubKeyToValcons } from '@/libs';
import {
  PageRequest,
  type Coin,
  type Delegation,
  type PaginatedDelegations,
  type PaginatedTxs,
  type Validator,
} from '@/types';
import PaginationBar from '@/components/PaginationBar.vue';
import { fromBase64, toBase64 } from '@cosmjs/encoding';
import { stringToUint8Array, uint8ArrayToString } from '@/libs/utils';

const props = defineProps(['validator', 'chain']);

const staking = useStakingStore();
const blockchain = useBlockchain();
const format = useFormatter();
const dialog = useTxDialog();
const page = new PageRequest();

const validator: string = props.validator;

const v = ref({} as Validator);
const cache = JSON.parse(localStorage.getItem('avatars') || '{}');
const avatars = ref(cache || {});
const identity = ref('');
const rewards = ref([] as Coin[] | undefined);
const commission = ref([] as Coin[] | undefined);
const delegations = ref({} as PaginatedDelegations);
const addresses = ref(
  {} as {
    account: string;
    operAddress: string;
    hex: string;
    valCons: string;
  }
);
const selfBonded = ref({} as Delegation);

addresses.value.account = operatorAddressToAccount(validator);
// load self bond
staking.fetchValidatorDelegation(validator, addresses.value.account).then((x) => {
  if (x) {
    selfBonded.value = x.delegation_response;
  }
});

const txs = ref({} as PaginatedTxs);

blockchain.rpc.getTxsBySender(addresses.value.account).then((x) => {
  txs.value = x;
});

const apr = computed(() => {
  const rate = Number(v.value.commission?.commission_rates.rate || 0);
  const inflation = useMintStore().inflation;
  const communityTax = Number(useDistributionStore().params.community_tax);
  const bondedRatio =
    Number(staking.pool.bonded_tokens) / Number(useBankStore().supply.amount);

  return format.percent(((1 - communityTax) * (1 - rate) * Number(inflation)) / bondedRatio);
});

const selfRate = computed(() => {
  if (selfBonded.value.balance?.amount) {
    return format.calculatePercent(selfBonded.value.balance.amount, v.value.tokens);
  }
  return '-';
});

const logo = (identity?: string) => {
  if (!identity) return '';
  const url = avatars.value[identity] || '';
  return url.startsWith('http') ? url : `https://s3.amazonaws.com/keybase_processed_uploads/${url}`;
};

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
        } else throw new Error(`failed to fetch avatar for ${identity}.`);
      })
      .catch((error) => {
        // console.error(error); // uncomment this if you want the user to see if the avatar failed to load.
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

onMounted(() => {
  if (validator) {
    staking.fetchValidator(validator).then((res) => {
      v.value = res.validator;
      identity.value = res.validator?.description?.identity || '';
      if (identity.value && !avatars.value[identity.value])
        loadAvatar(identity.value);

      addresses.value.hex = consensusPubkeyToHexAddress(v.value.consensus_pubkey);
      addresses.value.valCons = pubKeyToValcons(
        v.value.consensus_pubkey,
        blockchain.current?.bech32ConsensusPrefix || ''
      );
    });
    blockchain.rpc.getDistributionValidatorOutstandingRewards(validator).then((res) => {
      rewards.value = res.rewards?.rewards?.sort((a, b) => Number(b.amount) - Number(a.amount));
      res.rewards?.rewards?.forEach((x) => {
        if (x.denom.startsWith('ibc/')) {
          format.fetchDenomTrace(x.denom);
        }
      });
    });
    blockchain.rpc.getDistributionValidatorCommission(validator).then((res) => {
      commission.value = res.commission?.commission?.sort((a, b) => Number(b.amount) - Number(a.amount));
      res.commission?.commission?.forEach((x) => {
        if (x.denom.startsWith('ibc/')) {
          format.fetchDenomTrace(x.denom);
        }
      });
    });

    // Disable delegations due to its bad performance
    // Comment out the following code if you want to enable it
    // pageload(1)
  }
});
let showCopyToast = ref(0);
const copyWebsite = async (url: string) => {
  if (!url) {
    return;
  }
  try {
    await navigator.clipboard.writeText(url);
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
};
const tipMsg = computed(() => {
  return showCopyToast.value === 2
    ? { class: 'error', msg: 'Copy Error!' }
    : { class: 'success', msg: 'Copy Success!' };
});

function pageload(p: number) {
  page.setPage(p);
  page.limit = 10;

  blockchain.rpc.getStakingValidatorsDelegations(validator, page).then((res) => {
    delegations.value = res;
  });
}

const events = ref({} as PaginatedTxs);

enum EventType {
  Delegate = 'delegate',
  Unbond = 'unbond',
}

const selectedEventType = ref(EventType.Delegate);

function loadPowerEvents(p: number, type: EventType) {
  selectedEventType.value = type;
  page.setPage(p);
  page.setPageSize(5);
  blockchain.rpc
    .getTxs("?order_by=2&events={type}.validator='{validator}'", { type: selectedEventType.value, validator }, page)
    .then((res) => {
      events.value = res;
    });
}

function pagePowerEvents(page: number) {
  loadPowerEvents(page, selectedEventType.value);
}

pagePowerEvents(1);

function mapEvents(events: { type: string; attributes: { key: string; value: string }[] }[]) {
  const attributes = events
    .filter((x) => x.type === selectedEventType.value)
    .filter(
      (x) =>
        x.attributes.findIndex(
          (attr) => attr.value === validator || attr.value === toBase64(stringToUint8Array(validator))
        ) > -1
    )
    .map((x) => {
      // check if attributes need to decode
      const output = {} as { [key: string]: string };

      if (x.attributes.findIndex((a) => a.key === `amount`) > -1) {
        x.attributes.forEach((attr) => {
          output[attr.key] = attr.value;
        });
      } else {
        x.attributes.forEach((attr) => {
          output[uint8ArrayToString(fromBase64(attr.key))] = uint8ArrayToString(fromBase64(attr.value));
        });
      }

      return output;
    });

  const coinsAsString = attributes.map((x: any) => x.amount).join(',');
  const coins = parseCoins(coinsAsString);

  return coins.map((coin) => format.formatToken(coin)).join(', ');
}

function mapDelegators(messages: any[]) {
  if (!messages) return [];
  return Array.from(new Set(messages.map((x) => x.delegator_address || x.grantee)));
}
</script>
<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-6">
    <!-- Validator Header Card -->
    <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-purple-50/90 to-blue-50/90 dark:from-white/5 dark:via-purple-900/10 dark:to-blue-900/10 rounded-2xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-purple-400/20 via-blue-400/15 to-pink-400/20 rounded-full blur-3xl transform translate-x-32 -translate-y-32 animate-pulse-slow"></div>
      <div class="absolute bottom-0 left-0 w-56 h-56 bg-gradient-to-tr from-blue-400/20 via-indigo-400/15 to-purple-400/20 rounded-full blur-3xl transform -translate-x-28 translate-y-28 animate-pulse-slow" style="animation-delay: 2s"></div>
      
      <div class="relative p-6">
        <!-- Header with Avatar and Name -->
        <div class="flex items-start gap-6 mb-6">
          <!-- Avatar -->
          <div class="relative w-20 h-20 rounded-xl overflow-hidden bg-gradient-to-br from-purple-500/20 to-blue-500/20 backdrop-blur-sm border border-purple-500/30 shadow-lg flex-shrink-0">
            <img
              v-if="identity && avatars[identity] !== 'undefined'"
              v-lazy="logo(identity)"
              class="w-full h-full object-cover"
              @error="(e) => { loadAvatar(identity); }"
            />
            <div v-else class="w-full h-full flex items-center justify-center">
              <Icon icon="mdi:account-circle" class="text-4xl text-purple-600 dark:text-purple-400" />
            </div>
          </div>
          
          <!-- Name and Delegate Button -->
          <div class="flex-1">
            <h1 class="text-2xl font-bold bg-gradient-to-r from-purple-600 via-blue-600 to-pink-600 dark:from-purple-400 dark:via-blue-400 dark:to-pink-400 bg-clip-text text-transparent mb-1">
              {{ v.description?.moniker }}
            </h1>
            <p class="text-sm text-gray-600 dark:text-gray-400 mb-3">
              {{ v.description?.identity || '-' }}
            </p>
            <button
              @click="dialog.open('delegate', { validator_address: v.operator_address })"
              class="px-4 py-2 rounded-lg bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white text-sm font-medium transition-all duration-200 transform hover:scale-105 shadow-lg hover:shadow-xl"
            >
              <Icon icon="mdi:plus-circle" class="inline-block mr-1" />
              {{ $t('account.btn_delegate') }}
            </button>
          </div>
        </div>
        
        <!-- Combined Info and Stats Grid -->
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-4">
          <!-- Left Column: Info -->
          <div class="lg:col-span-7 space-y-3">
            <!-- About Us and Description Combined -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <!-- About Us -->
              <div>
                <h3 class="text-xs font-semibold text-gray-900 dark:text-white mb-2 flex items-center gap-1">
                  <div class="p-1 rounded bg-gradient-to-br from-indigo-500/20 to-purple-500/20">
                    <Icon icon="mdi:information" class="text-xs text-indigo-600 dark:text-indigo-400" />
                  </div>
                  {{ $t('staking.about_us') }}
                </h3>
                <div class="space-y-2 bg-gradient-to-br from-white/50 to-purple-50/30 dark:from-white/5 dark:to-purple-900/5 rounded-lg p-2.5 border border-gray-200/30 dark:border-white/5">
                  <div class="flex items-center gap-2">
                    <Icon icon="mdi:web" class="text-xs text-blue-600 dark:text-blue-400" />
                    <a
                      :href="v?.description?.website || '#'"
                      :class="v?.description?.website ? 'text-xs text-blue-600 dark:text-blue-400 hover:underline truncate block' : 'text-xs text-gray-500'"
                    >
                      {{ v.description?.website || '-' }}
                    </a>
                  </div>
                  <div class="flex items-center gap-2">
                    <Icon icon="mdi:email-outline" class="text-xs text-emerald-600 dark:text-emerald-400" />
                    <a
                      v-if="v.description?.security_contact"
                      :href="'mailto:' + v.description.security_contact"
                      class="text-xs text-emerald-600 dark:text-emerald-400 hover:underline truncate block"
                    >
                      {{ v.description?.security_contact }}
                    </a>
                    <span v-else class="text-xs text-gray-500">-</span>
                  </div>
                </div>
              </div>
              
              <!-- Description -->
              <div v-if="v.description?.details">
                <h3 class="text-xs font-semibold text-gray-900 dark:text-white mb-2 flex items-center gap-1">
                  <div class="p-1 rounded bg-gradient-to-br from-gray-500/20 to-gray-600/20">
                    <Icon icon="mdi:text" class="text-xs text-gray-600 dark:text-gray-400" />
                  </div>
                  Description
                </h3>
                <div class="bg-gradient-to-br from-white/50 to-gray-50/30 dark:from-white/5 dark:to-gray-900/5 rounded-lg p-2.5 border border-gray-200/30 dark:border-white/5">
                  <p class="text-xs text-gray-700 dark:text-gray-300 line-clamp-3">{{ v.description?.details }}</p>
                </div>
              </div>
            </div>
            
            <!-- Validator Status & Liquid Staking Combined -->
            <div class="grid grid-cols-2 gap-3">
              <!-- Validator Status -->
              <div>
                <h3 class="text-xs font-semibold text-gray-900 dark:text-white mb-2 flex items-center gap-1">
                  <div class="p-1 rounded bg-gradient-to-br from-amber-500/20 to-orange-500/20">
                    <Icon icon="mdi:shield-check" class="text-xs text-amber-600 dark:text-amber-400" />
                  </div>
                  {{ $t('staking.validator_status') }}
                </h3>
                <div class="space-y-2 bg-gradient-to-br from-white/50 to-amber-50/30 dark:from-white/5 dark:to-amber-900/5 rounded-lg p-2.5 border border-gray-200/30 dark:border-white/5">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center gap-1">
                      <Icon icon="mdi:shield-account-outline" class="text-xs text-amber-600 dark:text-amber-400" />
                      <span class="text-xs font-medium text-gray-700 dark:text-gray-300">{{ $t('staking.status') }}</span>
                    </div>
                    <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium"
                      :class="v.status === 'BOND_STATUS_BONDED' 
                        ? 'bg-gradient-to-r from-emerald-500/20 to-green-500/20 text-emerald-700 dark:text-emerald-300 border border-emerald-500/30'
                        : 'bg-gradient-to-r from-gray-500/20 to-gray-600/20 text-gray-700 dark:text-gray-300 border border-gray-500/30'"
                    >
                      {{ String(v.status).replace('BOND_STATUS_', '') }}
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <div class="flex items-center gap-1">
                      <Icon icon="mdi:shield-alert-outline" class="text-xs text-red-600 dark:text-red-400" />
                      <span class="text-xs font-medium text-gray-700 dark:text-gray-300">{{ $t('staking.jailed') }}</span>
                    </div>
                    <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium"
                      :class="v.jailed 
                        ? 'bg-gradient-to-r from-red-500/20 to-pink-500/20 text-red-700 dark:text-red-300 border border-red-500/30'
                        : 'bg-gradient-to-r from-emerald-500/20 to-green-500/20 text-emerald-700 dark:text-emerald-300 border border-emerald-500/30'"
                    >
                      {{ v.jailed ? 'Yes' : 'No' }}
                    </span>
                  </div>
                </div>
              </div>
              
              <!-- Liquid Staking -->
              <div>
                <h3 class="text-xs font-semibold text-gray-900 dark:text-white mb-2 flex items-center gap-1">
                  <div class="p-1 rounded bg-gradient-to-br from-blue-500/20 to-indigo-500/20">
                    <Icon icon="mdi:water" class="text-xs text-blue-600 dark:text-blue-400" />
                  </div>
                  {{ $t('staking.liquid_staking') }}
                </h3>
                <div class="space-y-2 bg-gradient-to-br from-white/50 to-blue-50/30 dark:from-white/5 dark:to-blue-900/5 rounded-lg p-2.5 border border-gray-200/30 dark:border-white/5">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center gap-1">
                      <Icon icon="mdi:lock" class="text-xs text-blue-600 dark:text-blue-400" />
                      <span class="text-xs font-medium text-gray-700 dark:text-gray-300">Bond Share</span>
                    </div>
                    <span class="text-xs font-semibold text-gray-900 dark:text-white">
                      {{ format.formatToken({ amount: v.validator_bond_shares, denom: staking.params.bond_denom }, false) }}
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <div class="flex items-center gap-1">
                      <Icon icon="mdi:waves-arrow-right" class="text-xs text-cyan-600 dark:text-cyan-400" />
                      <span class="text-xs font-medium text-gray-700 dark:text-gray-300">Liquid Shares</span>
                    </div>
                    <span class="text-xs font-semibold text-gray-900 dark:text-white">
                      {{ format.formatToken({ amount: v.liquid_shares, denom: staking.params.bond_denom }, false) }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Right Column: Stats -->
          <div class="lg:col-span-5">
            <div class="grid grid-cols-2 gap-3">
              <!-- Total Bonded -->
              <div class="backdrop-blur-sm bg-gradient-to-br from-white/70 to-purple-50/70 dark:from-white/10 dark:to-purple-900/10 rounded-xl border border-purple-200/50 dark:border-purple-500/20 p-4 hover:from-white/90 hover:to-purple-100/90 dark:hover:from-white/15 dark:hover:to-purple-900/15 transition-all duration-200 hover:scale-105 hover:shadow-lg">
                <div class="flex items-center gap-2 mb-2">
                  <div class="p-2 rounded-lg bg-gradient-to-br from-purple-500/20 to-pink-500/20">
                    <Icon icon="mdi:coin" class="text-lg text-purple-600 dark:text-purple-400" />
                  </div>
                  <p class="text-xs font-medium text-gray-700 dark:text-gray-300 leading-tight">{{ $t('staking.total_bonded') }}</p>
                </div>
                <p class="text-lg font-bold bg-gradient-to-r from-purple-600 to-pink-600 dark:from-purple-400 dark:to-pink-400 bg-clip-text text-transparent">
                  {{ format.formatToken2({ amount: v.tokens, denom: staking.params.bond_denom }) }}
                </p>
              </div>
              
              <!-- Self Bonded -->
              <div class="backdrop-blur-sm bg-gradient-to-br from-white/70 to-blue-50/70 dark:from-white/10 dark:to-blue-900/10 rounded-xl border border-blue-200/50 dark:border-blue-500/20 p-4 hover:from-white/90 hover:to-blue-100/90 dark:hover:from-white/15 dark:hover:to-blue-900/15 transition-all duration-200 hover:scale-105 hover:shadow-lg">
                <div class="flex items-center gap-2 mb-2">
                  <div class="p-2 rounded-lg bg-gradient-to-br from-blue-500/20 to-cyan-500/20">
                    <Icon icon="mdi:percent" class="text-lg text-blue-600 dark:text-blue-400" />
                  </div>
                  <p class="text-xs font-medium text-gray-700 dark:text-gray-300 leading-tight">{{ $t('staking.self_bonded') }}</p>
                </div>
                <p class="text-lg font-bold bg-gradient-to-r from-blue-600 to-cyan-600 dark:from-blue-400 dark:to-cyan-400 bg-clip-text text-transparent">
                  {{ selfRate }}
                </p>
                <p class="text-xs text-gray-600 dark:text-gray-400">{{ format.formatToken(selfBonded.balance) }}</p>
              </div>
              
              <!-- Min Self Delegation -->
              <div class="backdrop-blur-sm bg-gradient-to-br from-white/70 to-indigo-50/70 dark:from-white/10 dark:to-indigo-900/10 rounded-xl border border-indigo-200/50 dark:border-indigo-500/20 p-4 hover:from-white/90 hover:to-indigo-100/90 dark:hover:from-white/15 dark:hover:to-indigo-900/15 transition-all duration-200 hover:scale-105 hover:shadow-lg">
                <div class="flex items-center gap-2 mb-2">
                  <div class="p-2 rounded-lg bg-gradient-to-br from-indigo-500/20 to-purple-500/20">
                    <Icon icon="mdi:account-tie" class="text-lg text-indigo-600 dark:text-indigo-400" />
                  </div>
                  <p class="text-xs font-medium text-gray-700 dark:text-gray-300 leading-tight">{{ $t('staking.min_self') }}</p>
                </div>
                <p class="text-lg font-bold bg-gradient-to-r from-indigo-600 to-purple-600 dark:from-indigo-400 dark:to-purple-400 bg-clip-text text-transparent">
                  {{ v.min_self_delegation }}
                </p>
                <p class="text-xs text-gray-600 dark:text-gray-400">{{ staking.params.bond_denom }}</p>
              </div>
              
              <!-- APR -->
              <div class="backdrop-blur-sm bg-gradient-to-br from-white/70 to-emerald-50/70 dark:from-white/10 dark:to-emerald-900/10 rounded-xl border border-emerald-200/50 dark:border-emerald-500/20 p-4 hover:from-white/90 hover:to-emerald-100/90 dark:hover:from-white/15 dark:hover:to-emerald-900/15 transition-all duration-200 hover:scale-105 hover:shadow-lg">
                <div class="flex items-center gap-2 mb-2">
                  <div class="p-2 rounded-lg bg-gradient-to-br from-emerald-500/20 to-green-500/20">
                    <Icon icon="mdi:finance" class="text-lg text-emerald-600 dark:text-emerald-400" />
                  </div>
                  <p class="text-xs font-medium text-gray-700 dark:text-gray-300 leading-tight">{{ $t('staking.annual_profit') }}</p>
                </div>
                <p class="text-lg font-bold bg-gradient-to-r from-emerald-600 to-green-600 dark:from-emerald-400 dark:to-green-400 bg-clip-text text-transparent">
                  {{ apr }}
                </p>
              </div>
              
              <!-- Unbonding Height -->
              <div class="backdrop-blur-sm bg-gradient-to-br from-white/70 to-amber-50/70 dark:from-white/10 dark:to-amber-900/10 rounded-xl border border-amber-200/50 dark:border-amber-500/20 p-4 hover:from-white/90 hover:to-amber-100/90 dark:hover:from-white/15 dark:hover:to-amber-900/15 transition-all duration-200 hover:scale-105 hover:shadow-lg">
                <div class="flex items-center gap-2 mb-2">
                  <div class="p-2 rounded-lg bg-gradient-to-br from-amber-500/20 to-orange-500/20">
                    <Icon icon="mdi:arrow-down-bold-circle-outline" class="text-lg text-amber-600 dark:text-amber-400" />
                  </div>
                  <p class="text-xs font-medium text-gray-700 dark:text-gray-300 leading-tight">{{ $t('staking.unbonding_height') }}</p>
                </div>
                <p class="text-lg font-bold bg-gradient-to-r from-amber-600 to-orange-600 dark:from-amber-400 dark:to-orange-400 bg-clip-text text-transparent">
                  {{ v.unbonding_height || '-' }}
                </p>
              </div>
              
              <!-- Unbonding Time -->
              <div class="backdrop-blur-sm bg-gradient-to-br from-white/70 to-red-50/70 dark:from-white/10 dark:to-red-900/10 rounded-xl border border-red-200/50 dark:border-red-500/20 p-4 hover:from-white/90 hover:to-red-100/90 dark:hover:from-white/15 dark:hover:to-red-900/15 transition-all duration-200 hover:scale-105 hover:shadow-lg">
                <div class="flex items-center gap-2 mb-2">
                  <div class="p-2 rounded-lg bg-gradient-to-br from-red-500/20 to-pink-500/20">
                    <Icon icon="mdi:clock" class="text-lg text-red-600 dark:text-red-400" />
                  </div>
                  <p class="text-xs font-medium text-gray-700 dark:text-gray-300 leading-tight">{{ $t('staking.unbonding_time') }}</p>
                </div>
                <p class="text-lg font-bold bg-gradient-to-r from-red-600 to-pink-600 dark:from-red-400 dark:to-pink-400 bg-clip-text text-transparent">
                  <span v-if="v.unbonding_time && !v.unbonding_time.startsWith('1970')">
                    {{ format.toDay(v.unbonding_time, 'from') }}
                  </span>
                  <span v-else>-</span>
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Info Cards Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Commission Rate -->
      <div>
        <CommissionRate :commission="v.commission"></CommissionRate>
      </div>
      
      <!-- Commissions & Rewards -->
      <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-white/90 to-emerald-50/90 dark:from-white/5 dark:via-white/5 dark:to-emerald-900/10 rounded-2xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-emerald-400/10 via-green-400/10 to-teal-400/10 rounded-full blur-3xl transform translate-x-24 -translate-y-24"></div>
        
        <div class="relative p-4">
          <div class="flex items-center gap-2 mb-3">
            <div class="p-2 rounded-xl bg-gradient-to-br from-emerald-500/20 to-green-500/20 backdrop-blur-sm">
              <Icon icon="mdi:cash-multiple" class="text-lg text-emerald-600 dark:text-emerald-400" />
            </div>
            <h3 class="text-sm font-bold bg-gradient-to-r from-emerald-600 to-green-600 dark:from-emerald-400 dark:to-green-400 bg-clip-text text-transparent">
              {{ $t('staking.commissions_&_rewards') }}
            </h3>
          </div>
          
          <div class="space-y-3 max-h-48 overflow-y-auto">
            <div>
              <p class="text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">{{ $t('staking.commissions') }}</p>
              <div class="flex flex-wrap gap-1">
                <span
                  v-for="(i, k) in commission"
                  :key="`commission-${k}`"
                  class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-gradient-to-r from-emerald-500/20 to-green-500/20 text-emerald-700 dark:text-emerald-300 border border-emerald-500/30"
                >
                  {{ format.formatToken2(i) }}
                </span>
              </div>
            </div>
            
            <div>
              <p class="text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                {{ $t('staking.outstanding') }} {{ $t('account.rewards') }}
              </p>
              <div class="flex flex-wrap gap-1">
                <span
                  v-for="(i, k) in rewards"
                  :key="`reward-${k}`"
                  class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-gradient-to-r from-blue-500/20 to-indigo-500/20 text-blue-700 dark:text-blue-300 border border-blue-500/30"
                >
                  {{ format.formatToken2(i) }}
                </span>
              </div>
            </div>
          </div>
          
          <button
            @click="dialog.open('withdraw_commission', { validator_address: v.operator_address })"
            class="mt-4 w-full px-3 py-2 rounded-lg bg-gradient-to-r from-emerald-600 to-green-600 hover:from-emerald-700 hover:to-green-700 text-white text-sm font-medium transition-all duration-200 transform hover:scale-105 shadow-lg hover:shadow-xl"
          >
            <Icon icon="mdi:cash-check" class="inline-block mr-1 text-sm" />
            {{ $t('account.btn_withdraw') }}
          </button>
        </div>
      </div>
      
      <!-- Addresses -->
      <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-white/90 to-indigo-50/90 dark:from-white/5 dark:via-white/5 dark:to-indigo-900/10 rounded-2xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
        <div class="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-indigo-400/10 via-purple-400/10 to-blue-400/10 rounded-full blur-3xl transform translate-x-24 -translate-y-24"></div>
        
        <div class="relative p-4">
          <div class="flex items-center gap-2 mb-3">
            <div class="p-2 rounded-xl bg-gradient-to-br from-indigo-500/20 to-purple-500/20 backdrop-blur-sm">
              <Icon icon="mdi:map-marker" class="text-lg text-indigo-600 dark:text-indigo-400" />
            </div>
            <h3 class="text-sm font-bold bg-gradient-to-r from-indigo-600 to-purple-600 dark:from-indigo-400 dark:to-purple-400 bg-clip-text text-transparent">
              {{ $t('staking.addresses') }}
            </h3>
          </div>
          
          <div class="space-y-2">
            <!-- Account Address -->
            <div class="group">
              <div class="flex items-center gap-1 mb-0.5">
                <p class="text-xs font-medium text-gray-700 dark:text-gray-300">
                  {{ $t('staking.account_addr') }}
                </p>
                <Icon
                  icon="mdi:content-copy"
                  class="text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 cursor-pointer transition-colors text-xs"
                  v-show="addresses.account"
                  @click="copyWebsite(addresses.account || '')"
                />
              </div>
              <RouterLink 
                class="text-xs text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 dark:hover:text-indigo-300 break-all transition-colors" 
                :to="`/${chain}/account/${addresses.account}`"
              >
                {{ addresses.account }}
              </RouterLink>
            </div>
            
            <!-- Operator Address -->
            <div class="group">
              <div class="flex items-center gap-1 mb-0.5">
                <p class="text-xs font-medium text-gray-700 dark:text-gray-300">
                  {{ $t('staking.operator_addr') }}
                </p>
                <Icon
                  icon="mdi:content-copy"
                  class="text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 cursor-pointer transition-colors text-xs"
                  v-show="v.operator_address"
                  @click="copyWebsite(v.operator_address || '')"
                />
              </div>
              <p class="text-xs text-gray-600 dark:text-gray-400 break-all">
                {{ v.operator_address }}
              </p>
            </div>
            
            <!-- Hex Address -->
            <div class="group">
              <div class="flex items-center gap-1 mb-0.5">
                <p class="text-xs font-medium text-gray-700 dark:text-gray-300">
                  {{ $t('staking.hex_addr') }}
                </p>
                <Icon
                  icon="mdi:content-copy"
                  class="text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 cursor-pointer transition-colors text-xs"
                  v-show="addresses.hex"
                  @click="copyWebsite(addresses.hex || '')"
                />
              </div>
              <p class="text-xs text-gray-600 dark:text-gray-400 break-all">
                {{ addresses.hex }}
              </p>
            </div>
            
            <!-- Signer Address -->
            <div class="group">
              <div class="flex items-center gap-1 mb-0.5">
                <p class="text-xs font-medium text-gray-700 dark:text-gray-300">
                  {{ $t('staking.signer_addr') }}
                </p>
                <Icon
                  icon="mdi:content-copy"
                  class="text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 cursor-pointer transition-colors text-xs"
                  v-show="addresses.valCons"
                  @click="copyWebsite(addresses.valCons || '')"
                />
              </div>
              <p class="text-xs text-gray-600 dark:text-gray-400 break-all">
                {{ addresses.valCons }}
              </p>
            </div>
            
            <!-- Consensus Pub Key -->
            <div class="group">
              <div class="flex items-center gap-1 mb-0.5">
                <p class="text-xs font-medium text-gray-700 dark:text-gray-300">
                  {{ $t('staking.consensus_pub_key') }}
                </p>
                <Icon
                  icon="mdi:content-copy"
                  class="text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 cursor-pointer transition-colors text-xs"
                  v-show="v.consensus_pubkey"
                  @click="copyWebsite(JSON.stringify(v.consensus_pubkey) || '')"
                />
              </div>
              <p class="text-xs text-gray-600 dark:text-gray-400 break-all">
                {{ JSON.stringify(v.consensus_pubkey) }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Delegations Section -->
    <div v-if="delegations.delegation_responses" class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-white/90 to-purple-50/90 dark:from-white/5 dark:via-white/5 dark:to-purple-900/10 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-80 h-80 bg-gradient-to-br from-purple-400/10 via-indigo-400/10 to-blue-400/10 rounded-full blur-3xl transform translate-x-40 -translate-y-40"></div>
      
      <div class="relative p-6">
        <div class="flex items-center justify-between mb-6">
          <div class="flex items-center gap-3">
            <div class="p-3 rounded-2xl bg-gradient-to-br from-purple-500/20 to-indigo-500/20 backdrop-blur-sm">
              <Icon icon="mdi:account-group" class="text-2xl text-purple-600 dark:text-purple-400" />
            </div>
            <h2 class="text-xl font-bold bg-gradient-to-r from-purple-600 to-indigo-600 dark:from-purple-400 dark:to-indigo-400 bg-clip-text text-transparent">
              {{ $t('account.delegations') }}
            </h2>
          </div>
          <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-gradient-to-r from-purple-500/20 to-indigo-500/20 text-purple-700 dark:text-purple-300 border border-purple-500/30">
            {{ delegations.delegation_responses?.length || 0 }} / {{ delegations.pagination?.total || 0 }}
          </span>
        </div>
        
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="border-b border-gray-200/50 dark:border-white/10">
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-700 dark:text-gray-300">
                  {{ $t('account.delegator') }}
                </th>
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-700 dark:text-gray-300">
                  {{ $t('account.delegation') }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="{ balance, delegation } in delegations.delegation_responses" 
                :key="delegation.delegator_address"
                class="border-b border-gray-200/30 dark:border-white/5 hover:bg-gradient-to-r hover:from-transparent hover:via-purple-500/5 hover:to-transparent transition-all duration-200"
              >
                <td class="px-4 py-3">
                  <p class="text-sm font-medium text-purple-600 dark:text-purple-400 truncate max-w-xs">
                    {{ delegation.delegator_address }}
                  </p>
                </td>
                <td class="px-4 py-3">
                  <p class="text-sm font-semibold text-gray-900 dark:text-white">
                    {{ format.formatToken(balance) }}
                  </p>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        
        <div class="mt-4">
          <PaginationBar :total="delegations.pagination?.total" :limit="page.limit" :callback="pageload" />
        </div>
      </div>
    </div>

    <!-- Transactions Section -->
    <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-white/90 to-blue-50/90 dark:from-white/5 dark:via-white/5 dark:to-blue-900/10 rounded-3xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-80 h-80 bg-gradient-to-br from-blue-400/10 via-cyan-400/10 to-teal-400/10 rounded-full blur-3xl transform translate-x-40 -translate-y-40"></div>
      
      <div class="relative p-6">
        <div class="flex items-center gap-3 mb-6">
          <div class="p-3 rounded-2xl bg-gradient-to-br from-blue-500/20 to-cyan-500/20 backdrop-blur-sm">
            <Icon icon="mdi:swap-horizontal" class="text-2xl text-blue-600 dark:text-blue-400" />
          </div>
          <h2 class="text-xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 dark:from-blue-400 dark:to-cyan-400 bg-clip-text text-transparent">
            {{ $t('account.transactions') }}
          </h2>
        </div>
        
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="border-b border-gray-200/50 dark:border-white/10">
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-700 dark:text-gray-300">
                  {{ $t('account.height') }}
                </th>
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-700 dark:text-gray-300">
                  {{ $t('account.hash') }}
                </th>
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-700 dark:text-gray-300">
                  {{ $t('account.messages') }}
                </th>
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-700 dark:text-gray-300">
                  {{ $t('account.time') }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="(item, i) in txs.tx_responses" 
                :key="i"
                class="border-b border-gray-200/30 dark:border-white/5 hover:bg-gradient-to-r hover:from-transparent hover:via-blue-500/5 hover:to-transparent transition-all duration-200"
              >
                <td class="px-4 py-3">
                  <RouterLink 
                    :to="`/${props.chain}/block/${item.height}`"
                    class="text-sm font-medium text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 transition-colors"
                  >
                    {{ item.height }}
                  </RouterLink>
                </td>
                <td class="px-4 py-3">
                  <RouterLink 
                    :to="`/${props.chain}/tx/${item.txhash}`"
                    class="text-sm font-medium text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 dark:hover:text-indigo-300 transition-colors truncate block max-w-[200px]"
                  >
                    {{ item.txhash }}
                  </RouterLink>
                </td>
                <td class="px-4 py-3">
                  <div class="flex items-center gap-2">
                    <span class="text-sm text-gray-700 dark:text-gray-300">
                      {{ format.messages(item.tx.body.messages) }}
                    </span>
                    <Icon 
                      v-if="item.code === 0" 
                      icon="mdi:check-circle" 
                      class="text-emerald-500"
                    />
                    <Icon 
                      v-else 
                      icon="mdi:close-circle" 
                      class="text-red-500"
                    />
                  </div>
                </td>
                <td class="px-4 py-3">
                  <p class="text-sm text-gray-600 dark:text-gray-400">
                    {{ format.toDay(item.timestamp, 'from') }}
                  </p>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Voting Power Events -->
    <div class="backdrop-blur-xl bg-gradient-to-br from-white/95 via-white/90 to-amber-50/90 dark:from-white/5 dark:via-white/5 dark:to-amber-900/10 rounded-2xl border border-gray-200 dark:border-white/10 shadow-lg dark:shadow-none relative overflow-hidden">
      <div class="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-amber-400/10 via-orange-400/10 to-yellow-400/10 rounded-full blur-3xl transform translate-x-32 -translate-y-32"></div>
      
      <div class="relative p-4">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-2">
            <div class="p-2 rounded-xl bg-gradient-to-br from-amber-500/20 to-orange-500/20 backdrop-blur-sm">
              <Icon icon="mdi:swap-vertical" class="text-lg text-amber-600 dark:text-amber-400" />
            </div>
            <h3 class="text-sm font-bold bg-gradient-to-r from-amber-600 to-orange-600 dark:from-amber-400 dark:to-orange-400 bg-clip-text text-transparent">
              Voting Power Events
            </h3>
          </div>
          
          <div class="flex gap-2">
            <button
              class="px-3 py-1 rounded-lg text-xs font-medium transition-all duration-200"
              :class="selectedEventType === EventType.Delegate 
                ? 'bg-gradient-to-r from-emerald-500/20 to-green-500/20 text-emerald-700 dark:text-emerald-300 border border-emerald-500/30' 
                : 'bg-gray-100 dark:bg-white/5 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-white/10'"
              @click="loadPowerEvents(1, EventType.Delegate)"
            >
              {{ $t('account.btn_delegate') }}
            </button>
            <button
              class="px-3 py-1 rounded-lg text-xs font-medium transition-all duration-200"
              :class="selectedEventType === EventType.Unbond 
                ? 'bg-gradient-to-r from-red-500/20 to-pink-500/20 text-red-700 dark:text-red-300 border border-red-500/30' 
                : 'bg-gray-100 dark:bg-white/5 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-white/10'"
              @click="loadPowerEvents(1, EventType.Unbond)"
            >
              {{ $t('account.btn_unbond') }}
            </button>
          </div>
        </div>
        
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="border-b border-gray-200/50 dark:border-white/10">
                <th class="px-3 py-2 text-left text-xs font-semibold text-gray-700 dark:text-gray-300">{{ $t('account.delegator') }}</th>
                <th class="px-3 py-2 text-left text-xs font-semibold text-gray-700 dark:text-gray-300">{{ $t('account.amount') }}</th>
                <th class="px-3 py-2 text-left text-xs font-semibold text-gray-700 dark:text-gray-300">{{ $t('account.height') }} / {{ $t('account.time') }}</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="(item, i) in events.tx_responses" 
                :key="i"
                class="border-b border-gray-200/30 dark:border-white/5 hover:bg-gradient-to-r hover:from-transparent hover:via-amber-500/5 hover:to-transparent transition-all duration-200"
              >
                <td class="px-3 py-2">
                  <RouterLink
                    v-for="d in mapDelegators(item.tx?.body?.messages)"
                    :key="d"
                    :to="`/${props.chain}/account/${d}`"
                    class="text-xs font-medium text-amber-600 dark:text-amber-400 hover:text-amber-700 dark:hover:text-amber-300 truncate block max-w-[200px]"
                  >
                    {{ d }}
                  </RouterLink>
                </td>
                <td class="px-3 py-2">
                  <RouterLink 
                    :to="`/${props.chain}/tx/${item.txhash}`"
                    class="flex items-center gap-1 text-xs"
                    :class="{
                      'text-emerald-600 dark:text-emerald-400': selectedEventType === EventType.Delegate,
                      'text-red-600 dark:text-red-400': selectedEventType === EventType.Unbond,
                    }"
                  >
                    <span>{{ selectedEventType === EventType.Delegate ? '+' : '-' }} {{ mapEvents(item.events) }}</span>
                    <Icon v-if="item.code === 0" icon="mdi:check-circle" class="text-emerald-500" />
                    <Icon v-else icon="mdi:close-circle" class="text-red-500" />
                  </RouterLink>
                </td>
                <td class="px-3 py-2">
                  <RouterLink 
                    :to="`/${props.chain}/block/${item.height}`"
                    class="text-xs font-medium text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
                  >
                    {{ item.height }}
                  </RouterLink>
                  <p class="text-xs text-gray-600 dark:text-gray-400">{{ format.toDay(item.timestamp, 'from') }}</p>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        
        <div class="mt-3">
          <PaginationBar :total="events.pagination?.total" :limit="page.limit" :callback="pagePowerEvents" />
        </div>
      </div>
    </div>
    <!-- end -->
    <div class="toast" v-show="showCopyToast === 1">
      <div class="alert alert-success">
        <div class="text-xs md:!text-sm">
          <span>{{ tipMsg.msg }}</span>
        </div>
      </div>
    </div>
    <div class="toast" v-show="showCopyToast === 2">
      <div class="alert alert-error">
        <div class="text-xs md:!text-sm">
          <span>{{ tipMsg.msg }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<style>
.validatore-table.table :where(th, td) {
  padding: 0.6rem 1rem;
  font-size: 14px;
}
</style>
