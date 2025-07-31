/**
 * Navigation Icon Configuration
 * Maps module names to their respective icons for consistent navigation UI
 */

export interface ModuleIconConfig {
  icon: string;
  color?: string;
  description?: string;
}

export const navigationIcons: Record<string, ModuleIconConfig> = {
  // Core Modules
  dashboard: {
    icon: 'mdi:view-dashboard',
    color: 'text-blue-400',
    description: 'Overview and statistics'
  },
  
  // Blockchain Modules
  blocks: {
    icon: 'mdi:cube',
    color: 'text-amber-400',
    description: 'Block explorer'
  },
  
  tx: {
    icon: 'mdi:swap-horizontal',
    color: 'text-green-400',
    description: 'Transaction history'
  },
  
  // Staking & Governance
  staking: {
    icon: 'mdi:shield-check',
    color: 'text-purple-400',
    description: 'Validators and delegations'
  },
  
  governance: {
    icon: 'mdi:vote',
    color: 'text-indigo-400',
    description: 'Governance proposals'
  },
  
  // Token & Finance
  supply: {
    icon: 'mdi:cash-multiple',
    color: 'text-emerald-400',
    description: 'Token supply'
  },
  
  bank: {
    icon: 'mdi:bank',
    color: 'text-cyan-400',
    description: 'Bank module'
  },
  
  // IBC & Network
  ibc: {
    icon: 'mdi:transit-connection-variant',
    color: 'text-pink-400',
    description: 'IBC connections'
  },
  
  consensus: {
    icon: 'mdi:network',
    color: 'text-orange-400',
    description: 'Consensus state'
  },
  
  // Technical Modules
  parameters: {
    icon: 'mdi:cog',
    color: 'text-gray-400',
    description: 'Chain parameters'
  },
  
  uptime: {
    icon: 'mdi:chart-timeline-variant',
    color: 'text-lime-400',
    description: 'Validator uptime'
  },
  
  'state-sync': {
    icon: 'mdi:sync',
    color: 'text-teal-400',
    description: 'State sync'
  },
  
  // Advanced Features
  cosmwasm: {
    icon: 'mdi:code-braces',
    color: 'text-yellow-400',
    description: 'Smart contracts'
  },
  
  widget: {
    icon: 'mdi:widgets',
    color: 'text-rose-400',
    description: 'Widgets'
  },
  
  nft: {
    icon: 'mdi:palette',
    color: 'text-violet-400',
    description: 'NFTs'
  },
  
  group: {
    icon: 'mdi:account-group',
    color: 'text-sky-400',
    description: 'Groups'
  },
  
  // Special Modules
  evm: {
    icon: 'mdi:ethereum',
    color: 'text-blue-500',
    description: 'EVM module'
  },
  
  faucet: {
    icon: 'mdi:water',
    color: 'text-blue-300',
    description: 'Testnet faucet'
  },
  
  // Account (for potential future use)
  account: {
    icon: 'mdi:account-circle',
    color: 'text-gray-400',
    description: 'Account details'
  }
};

// Helper function to get icon config with fallback
export function getModuleIcon(moduleName: string): ModuleIconConfig {
  return navigationIcons[moduleName] || {
    icon: 'mdi:circle-outline',
    color: 'text-gray-400',
    description: 'Module'
  };
}