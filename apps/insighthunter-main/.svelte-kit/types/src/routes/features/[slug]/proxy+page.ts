// @ts-nocheck
import { features } from '$lib/data/features';
import { error } from '@sveltejs/kit';
import type { PageLoad } from './$types';

export const load = ({ params }: Parameters<PageLoad>[0]) => {
  const feature = features.find(f => f.slug === params.slug);
  if (!feature) throw error(404, `Feature "${params.slug}" not found`);
  return { feature };
};
