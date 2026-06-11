export const PORTAL_URL = 'https://openteam.ai/auth';

export const PORTAL_HOSTS = [
  'openteam.ai',
  'www.openteam.ai',
  'portal.openteam.ai',
] as const;

export const PORTAL_HOST_SET = new Set<string>(PORTAL_HOSTS);
