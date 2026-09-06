export interface AreaColorConfig {
  name: string;
  label: string;
  hex: string;
  dotClass: string;
  borderLeftClass: string;
  badgeClass: string;
  ringClass: string;
  bgLightClass: string;
}

export const AREA_COLOR_PALETTE: Record<string, AreaColorConfig> = {
  indigo: {
    name: 'indigo',
    label: 'Indigo',
    hex: '#6366F1',
    dotClass: 'bg-indigo-500',
    borderLeftClass: 'border-l-indigo-500',
    badgeClass: 'bg-indigo-50 text-indigo-700 border-indigo-200/80',
    ringClass: 'ring-indigo-400',
    bgLightClass: 'bg-indigo-50/30',
  },
  emerald: {
    name: 'emerald',
    label: 'Emerald',
    hex: '#10B981',
    dotClass: 'bg-emerald-500',
    borderLeftClass: 'border-l-emerald-500',
    badgeClass: 'bg-emerald-50 text-emerald-700 border-emerald-200/80',
    ringClass: 'ring-emerald-400',
    bgLightClass: 'bg-emerald-50/30',
  },
  amber: {
    name: 'amber',
    label: 'Amber',
    hex: '#F59E0B',
    dotClass: 'bg-amber-500',
    borderLeftClass: 'border-l-amber-500',
    badgeClass: 'bg-amber-50 text-amber-800 border-amber-200/80',
    ringClass: 'ring-amber-400',
    bgLightClass: 'bg-amber-50/30',
  },
  rose: {
    name: 'rose',
    label: 'Rose',
    hex: '#F43F5E',
    dotClass: 'bg-rose-500',
    borderLeftClass: 'border-l-rose-500',
    badgeClass: 'bg-rose-50 text-rose-700 border-rose-200/80',
    ringClass: 'ring-rose-400',
    bgLightClass: 'bg-rose-50/30',
  },
  purple: {
    name: 'purple',
    label: 'Purple',
    hex: '#8B5CF6',
    dotClass: 'bg-purple-500',
    borderLeftClass: 'border-l-purple-500',
    badgeClass: 'bg-purple-50 text-purple-700 border-purple-200/80',
    ringClass: 'ring-purple-400',
    bgLightClass: 'bg-purple-50/30',
  },
  sky: {
    name: 'sky',
    label: 'Sky',
    hex: '#0EA5E9',
    dotClass: 'bg-sky-500',
    borderLeftClass: 'border-l-sky-500',
    badgeClass: 'bg-sky-50 text-sky-700 border-sky-200/80',
    ringClass: 'ring-sky-400',
    bgLightClass: 'bg-sky-50/30',
  },
  teal: {
    name: 'teal',
    label: 'Teal',
    hex: '#14B8A6',
    dotClass: 'bg-teal-500',
    borderLeftClass: 'border-l-teal-500',
    badgeClass: 'bg-teal-50 text-teal-700 border-teal-200/80',
    ringClass: 'ring-teal-400',
    bgLightClass: 'bg-teal-50/30',
  },
  orange: {
    name: 'orange',
    label: 'Orange',
    hex: '#F97316',
    dotClass: 'bg-orange-500',
    borderLeftClass: 'border-l-orange-500',
    badgeClass: 'bg-orange-50 text-orange-800 border-orange-200/80',
    ringClass: 'ring-orange-400',
    bgLightClass: 'bg-orange-50/30',
  },
  pink: {
    name: 'pink',
    label: 'Pink',
    hex: '#EC4899',
    dotClass: 'bg-pink-500',
    borderLeftClass: 'border-l-pink-500',
    badgeClass: 'bg-pink-50 text-pink-700 border-pink-200/80',
    ringClass: 'ring-pink-400',
    bgLightClass: 'bg-pink-50/30',
  },
  violet: {
    name: 'violet',
    label: 'Violet',
    hex: '#7C3AED',
    dotClass: 'bg-violet-500',
    borderLeftClass: 'border-l-violet-500',
    badgeClass: 'bg-violet-50 text-violet-700 border-violet-200/80',
    ringClass: 'ring-violet-400',
    bgLightClass: 'bg-violet-50/30',
  },
  cyan: {
    name: 'cyan',
    label: 'Cyan',
    hex: '#06B6D4',
    dotClass: 'bg-cyan-500',
    borderLeftClass: 'border-l-cyan-500',
    badgeClass: 'bg-cyan-50 text-cyan-800 border-cyan-200/80',
    ringClass: 'ring-cyan-400',
    bgLightClass: 'bg-cyan-50/30',
  },
  lime: {
    name: 'lime',
    label: 'Lime',
    hex: '#84CC16',
    dotClass: 'bg-lime-500',
    borderLeftClass: 'border-l-lime-500',
    badgeClass: 'bg-lime-50 text-lime-800 border-lime-200/80',
    ringClass: 'ring-lime-400',
    bgLightClass: 'bg-lime-50/30',
  },
};

export const AVAILABLE_AREA_COLORS = Object.keys(AREA_COLOR_PALETTE);

export function getAreaColorConfig(colorName?: string): AreaColorConfig {
  if (!colorName) return AREA_COLOR_PALETTE.indigo;
  const normalized = colorName.toLowerCase().trim();
  return AREA_COLOR_PALETTE[normalized] || AREA_COLOR_PALETTE.indigo;
}
