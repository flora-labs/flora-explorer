<script setup lang="ts">
import { Icon } from '@iconify/vue';
import { controlledComputed } from '@vueuse/core';

interface Props {
  title: string;
  color?: string;
  icon: string;
  stats: string;
  change?: number;
  subtitle?: string;
}

const props = withDefaults(defineProps<Props>(), {
  color: 'primary',
});

const isPositive = controlledComputed(
  () => props.change,
  () => Math.sign(props.change || 0) === 1
);

// Color mappings for different stat types
const colorClasses = {
  gradient: props.color === 'info' ? 'bg-gradient-to-br from-blue-500/20 to-cyan-500/20' :
            props.color === 'success' ? 'bg-gradient-to-br from-green-500/20 to-emerald-500/20' :
            props.color === 'warning' ? 'bg-gradient-to-br from-amber-500/20 to-orange-500/20' :
            props.color === 'primary' ? 'bg-gradient-to-br from-purple-500/20 to-indigo-500/20' :
            'bg-gradient-to-br from-gray-500/20 to-gray-600/20',
  
  iconBg: props.color === 'info' ? 'bg-blue-500/10 hover:bg-blue-500/20' :
          props.color === 'success' ? 'bg-green-500/10 hover:bg-green-500/20' :
          props.color === 'warning' ? 'bg-amber-500/10 hover:bg-amber-500/20' :
          props.color === 'primary' ? 'bg-purple-500/10 hover:bg-purple-500/20' :
          'bg-gray-500/10 hover:bg-gray-500/20',
  
  icon: props.color === 'info' ? 'text-blue-400' :
        props.color === 'success' ? 'text-green-400' :
        props.color === 'warning' ? 'text-amber-400' :
        props.color === 'primary' ? 'text-purple-400' :
        'text-gray-400',
  
  valueGradient: props.color === 'info' ? 'from-blue-400 to-cyan-400' :
                 props.color === 'success' ? 'from-green-400 to-emerald-400' :
                 props.color === 'warning' ? 'from-amber-400 to-orange-400' :
                 props.color === 'primary' ? 'from-purple-400 to-indigo-400' :
                 'from-gray-400 to-gray-300',
  
  accentLine: props.color === 'info' ? 'bg-gradient-to-r from-blue-500 to-cyan-500' :
              props.color === 'success' ? 'bg-gradient-to-r from-green-500 to-emerald-500' :
              props.color === 'warning' ? 'bg-gradient-to-r from-amber-500 to-orange-500' :
              props.color === 'primary' ? 'bg-gradient-to-r from-purple-500 to-indigo-500' :
              'bg-gradient-to-r from-gray-500 to-gray-400',
};
</script>

<template>
  <div class="stat-card group relative overflow-hidden rounded-2xl backdrop-blur-sm bg-gradient-to-br from-white/[0.02] to-white/[0.04] dark:from-white/[0.02] dark:to-white/[0.04] border border-white/5 hover:border-white/10 transition-all duration-300">
    <!-- Background gradient effect -->
    <div class="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500">
      <div :class="[
        'absolute -top-20 -right-20 w-40 h-40 rounded-full blur-3xl',
        colorClasses.gradient
      ]"></div>
    </div>
    
    <!-- Content -->
    <div class="relative p-6">
      <!-- Header with icon and change indicator -->
      <div class="flex items-start justify-between mb-4">
        <!-- Icon with subtle background -->
        <div :class="[
          'p-2.5 rounded-xl backdrop-blur-md transition-all duration-300',
          colorClasses.iconBg,
          'group-hover:scale-110 group-hover:shadow-lg'
        ]">
          <Icon 
            :icon="props.icon" 
            :class="['w-5 h-5', colorClasses.icon]"
            aria-hidden="true"
          />
        </div>
        
        <!-- Change indicator (if applicable) -->
        <div
          v-if="props.change && props.change !== 0"
          :class="[
            'flex items-center gap-1 text-xs font-medium px-2 py-1 rounded-lg backdrop-blur-sm',
            isPositive 
              ? 'bg-green-500/10 text-green-400' 
              : 'bg-red-500/10 text-red-400'
          ]"
        >
          <Icon 
            :icon="isPositive ? 'mdi:trending-up' : 'mdi:trending-down'" 
            class="w-3 h-3"
          />
          <span>{{ Math.abs(props.change) }}%</span>
        </div>
      </div>
      
      <!-- Stats value with gradient -->
      <div class="mb-3">
        <h3 :class="[
          'text-2xl font-bold tracking-tight bg-gradient-to-r bg-clip-text text-transparent',
          colorClasses.valueGradient
        ]">
          {{ props.stats || '—' }}
        </h3>
      </div>
      
      <!-- Title and subtitle -->
      <div class="space-y-1">
        <p class="text-sm font-medium text-gray-300 dark:text-gray-300">
          {{ props.title }}
        </p>
        <p v-if="props.subtitle" class="text-xs text-gray-500 dark:text-gray-500 truncate">
          {{ props.subtitle }}
        </p>
      </div>
      
      <!-- Hover accent line -->
      <div :class="[
        'absolute bottom-0 left-0 right-0 h-0.5 transform scale-x-0 group-hover:scale-x-100 transition-transform duration-300 origin-left',
        colorClasses.accentLine
      ]"></div>
    </div>
  </div>
</template>

<style scoped>
/* Ensure consistent rendering of gradient text */
.stat-card h3 {
  -webkit-background-clip: text;
  background-clip: text;
}

/* Smooth hover transitions */
.stat-card {
  transform: translateY(0);
}

.stat-card:hover {
  transform: translateY(-2px);
}

/* Prevent layout shift on hover */
.stat-card > div {
  transform: translateZ(0);
  will-change: transform;
}
</style>
