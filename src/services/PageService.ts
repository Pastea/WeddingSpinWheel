import { ref, watch } from 'vue';
import { defaultPageTitle, defaultPageDescription } from '@/assets/TemplateData';

export const PageTitle = ref(localStorage.getItem('PageTitle') || defaultPageTitle);
export const PageDescription = ref(
  localStorage.getItem('PageDescription') || defaultPageDescription
);

watch(PageTitle, (val) => localStorage.setItem('PageTitle', val));
watch(PageDescription, (val) => localStorage.setItem('PageDescription', val));

export const resetPageDefaults = () => {
  PageTitle.value = defaultPageTitle;
  PageDescription.value = defaultPageDescription;
};
