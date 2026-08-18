import React from 'react';
import { Settings, ShieldCheck, Sparkles } from 'lucide-react';
import { ActiveTab } from '../types';
import { triggerHaptic } from '../utils/haptics';

interface FooterProps {
  activeTab: ActiveTab;
  setActiveTab: (tab: ActiveTab) => void;
}

export const Footer: React.FC<FooterProps> = ({ activeTab, setActiveTab }) => {
  const isSettingsActive = activeTab === 'settings';

  return (
    <footer
      id="app-footer"
      className="w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-12 pb-28 sm:pb-32"
    >
      <div className="rounded-3xl border border-black/10 bg-white/60 backdrop-blur-md p-4 sm:p-5 flex flex-col sm:flex-row items-center justify-between gap-4 shadow-xs">
        {/* Left info badge */}
        <div className="flex items-center space-x-2.5 text-xs text-[#1C1C1A]/70 font-mono">
          <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
          <span className="font-bold">LifeOS Engine</span>
          <span className="text-[#1C1C1A]/30">•</span>
          <span className="text-[#1C1C1A]/50 flex items-center space-x-1">
            <ShieldCheck className="w-3.5 h-3.5 text-emerald-600 inline" />
            <span>Local & Private</span>
          </span>
        </div>

        {/* Right Settings button container */}
        <div className="flex items-center space-x-2">
          <button
            id="footer-settings-btn"
            onClick={() => {
              triggerHaptic('light');
              setActiveTab('settings');
            }}
            className={`flex items-center space-x-2 px-4 py-2.5 rounded-2xl font-mono text-xs font-bold uppercase tracking-wider transition-all cursor-pointer border ${
              isSettingsActive
                ? 'bg-[#1C1C1A] text-white border-[#1C1C1A] shadow-md'
                : 'bg-white text-[#1C1C1A] border-black/10 hover:border-black/20 hover:bg-black/5 shadow-2xs'
            }`}
          >
            <Settings
              className={`w-4 h-4 transition-transform duration-300 ${
                isSettingsActive ? 'rotate-90 text-[#FF5B5B]' : 'text-[#1C1C1A]/70'
              }`}
            />
            <span>Settings & Preferences</span>
          </button>
        </div>
      </div>
    </footer>
  );
};
