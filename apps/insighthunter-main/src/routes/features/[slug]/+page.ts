import { features } from '$lib/data/features';
import { error } from '@sveltejs/kit';
import type { PageLoad } from './$types';

export const load: PageLoad = ({ params }) => {
  const feature = features.find(f => f.slug === params.slug);
  if (!feature) throw error(404, `Feature "${params.slug}" not found`);
  return { feature };
};
