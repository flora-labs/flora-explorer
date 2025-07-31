import { defineStore } from 'pinia';

import { useBlockchain } from './useBlockchain';
import { useStakingStore } from './useStakingStore';
import type { Coin, DenomTrace } from '@/types';

export const useBankStore = defineStore('bankstore', {
  state: () => {
    return {
      supply: {} as Coin,
      balances: {} as Record<string, Coin[]>,
      totalSupply: { supply: [] as Coin[] },
      ibcDenoms: {} as Record<string, DenomTrace>,
    };
  },
  getters: {
    blockchain() {
      return useBlockchain();
    },
    staking() {
      return useStakingStore();
    },
  },
  actions: {
    initial() {
      this.$reset();
      this.supply = {} as Coin;
      const denom = this.staking.params.bond_denom || this.blockchain.current?.assets[0].base;
      if (denom) {
        // Check if this is Flora chain (doesn't implement supply by denom endpoint)
        const isFlora = this.blockchain.current?.chainName === 'flora' || 
                       this.blockchain.chainName === 'flora' ||
                       this.blockchain.chainName === 'flora-devnet' ||
                       this.blockchain.current?.chainName === 'flora-devnet' ||
                       denom === 'uflora';
        
        if (isFlora) {
          // Skip the failing endpoint and go straight to general supply
          this.blockchain.rpc.getBankSupply().then((res) => {
            if (res.supply) {
              const floraSupply = res.supply.find((s: Coin) => s.denom === denom);
              if (floraSupply) {
                this.supply = floraSupply;
              }
            }
          }).catch(error => {
            console.error('Error fetching bank supply:', error);
          });
        } else {
          // For other chains, try the specific endpoint first
          this.blockchain.rpc.getBankSupplyByDenom(denom).then((res) => {
            if (res.amount) this.supply = res.amount;
          }).catch((error) => {
            // Fallback to general supply endpoint if specific denom endpoint fails
            this.blockchain.rpc.getBankSupply().then((res) => {
              if (res.supply) {
                const supply = res.supply.find((s: Coin) => s.denom === denom);
                if (supply) this.supply = supply;
              }
            });
          });
        }
      }
    },
    async fetchSupply(denom: string) {
      try {
        return await this.blockchain.rpc.getBankSupplyByDenom(denom);
      } catch (error: any) {
        // Fallback to general supply endpoint if specific denom endpoint fails
        if (error.response?.status === 501) {
          const res = await this.blockchain.rpc.getBankSupply();
          if (res.supply) {
            const denomSupply = res.supply.find((s: Coin) => s.denom === denom);
            if (denomSupply) return { amount: denomSupply };
          }
        }
        throw error;
      }
    },
    async fetchDenomTrace(denom: string) {
      const hash = denom.replace('ibc/', '');
      let trace = this.ibcDenoms[hash];
      if (!trace) {
        trace = (await this.blockchain.rpc.getIBCAppTransferDenom(hash)).denom_trace;
        this.ibcDenoms[hash] = trace;
      }
      return trace;
    },
  },
});
