<script lang="ts" setup>
import ApexCharts from 'vue3-apexcharts';
import { computed, ref, onMounted, watch } from 'vue';
import { useBaseStore } from '@/stores';

const baseStore = useBaseStore();

const options = computed(() => {
  return {
    chart: {
      type: 'bar',
      height: 150,
      background: 'transparent',
      toolbar: {
        show: false,
      },
      sparkline: {
        enabled: false,
      }
    },
    plotOptions: {
      bar: {
        borderRadius: 6,
        horizontal: false,
        columnWidth: '60%',
      },
    },
    dataLabels: {
      enabled: false,
    },
    colors: ['#818CF8'],
    fill: {
      type: 'gradient',
      gradient: {
        shade: 'light',
        type: 'vertical',
        shadeIntensity: 0.5,
        gradientToColors: ['#3B82F6'],
        inverseColors: false,
        opacityFrom: 0.85,
        opacityTo: 0.55,
        stops: [0, 100]
      }
    },
    grid: {
      show: false,
    },
    xaxis: {
      labels: {
        show: false,
      },
      axisBorder: {
        show: false,
      },
      axisTicks: {
        show: false,
      },
      categories: baseStore.recents
        .map((x) => x.block.header.height)
        .concat(Array(50 - baseStore.recents.length).fill('')),
    },
    yaxis: {
      show: false,
    },
    tooltip: {
      enabled: true,
      theme: 'dark',
      style: {
        fontSize: '12px',
      },
      y: {
        formatter: function(val) {
          return val + ' transactions'
        }
      },
      x: {
        formatter: function(val) {
          return 'Block #' + val
        }
      }
    }
  };
});
const series = computed(() => {
  const data = baseStore.recents?.map((x) => x.block.data.txs.length) || [];
  // If all values are 0, show a sample chart with mock data
  const allZero = data.every(val => val === 0);
  
  if (allZero && data.length > 0) {
    // Show a subtle placeholder chart
    return [{
      name: 'Txs',
      data: Array(data.length).fill(0).map((_, i) => i % 7 === 0 ? 1 : 0)
    }];
  }
  
  return [
    {
      name: 'Txs',
      data: data,
    },
  ];
});

const hasData = computed(() => {
  return baseStore.recents && baseStore.recents.length > 0;
});
</script>

<template>
  <div class="relative">
    <ApexCharts v-if="hasData" type="bar" height="150" :options="options" :series="series" />
    <div v-else class="flex items-center justify-center h-[150px] text-gray-500 dark:text-gray-400">
      <span class="text-sm">Loading transaction data...</span>
    </div>
  </div>
</template>
