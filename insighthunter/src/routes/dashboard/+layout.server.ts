import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = async ({ cookies, url }) => {
  const sessionToken = cookies.get('ih_session') ?? '';
  return {
    sessionToken,
    currentPath: url.pathname,
  };
};
