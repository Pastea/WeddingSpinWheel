import { ref, watch } from 'vue';

export const PageTitle = ref(
  localStorage.getItem('PageTitle') || 'La ruota degli sposi Arianna&Giuseppe'
);
export const PageDescription = ref(localStorage.getItem('PageDescription') || '26 settembre 2026');

watch(PageTitle, (val) => localStorage.setItem('PageTitle', val));
watch(PageDescription, (val) => localStorage.setItem('PageDescription', val));
