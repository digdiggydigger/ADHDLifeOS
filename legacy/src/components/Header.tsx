import React from 'react';
import { ActiveTab, FocusSessionState } from '../types';
import { triggerHaptic } from '../utils/haptics';
import { Plus, Timer, Sparkles, Settings } from 'lucide-react';

interface HeaderProps {
  activeTab: ActiveTab;
  setActiveTab: (tab: ActiveTab) => void;
  unprocessedCount: number;
  dueNudgesCount: number;
  openTasksCount: number;
  focusSession: FocusSessionState;
  onOpenQuickCapture: () => void;
  onOpenFocusModal: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  activeTab,
  setActiveTab,
  unprocessedCount,
  dueNudgesCount,
  openTasksCount,
  focusSession,
  onOpenQuickCapture,
  onOpenFocusModal,
}) => {
  const formatTime = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  return (
    <header className="w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-4 sm:pt-8 pb-3 sm:pb-4">
      <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-3 sm:gap-4 border-b border-black/5 pb-4 sm:pb-6">
        {/* Left identity & Title matching Design */}
        <div>
          <div className="label text-[#FF5B5B] mb-1 sm:mb-1.5 font-mono text-[10px] sm:text-xs">Priority [01]</div>
          <button
            id="header-app-logo"
            onClick={() => setActiveTab('home')}
            className="text-left focus:outline-hidden group cursor-pointer"
          >
            <h1 className="hero-title text-3xl sm:text-5xl lg:text-6xl font-bold leading-[0.88] tracking-tighter text-[#1C1C1A]">
              ADHD<br />
              <span className="text-[#1C1C1A]">LifeOS</span>
            </h1>
          </button>
        </div>

        {/* Right side info & Actions */}
        <div className="flex sm:flex-col items-start sm:items-end justify-between sm:justify-center gap-1.5 sm:gap-2">
          <div className="text-left sm:text-right">
            <p className="text-base sm:text-lg lg:text-xl font-medium text-[#1C1C1A] leading-snug">Radiant Focus</p>
            <div className="label text-[#1C1C1A]/60 font-mono mt-0.5 text-[10px] sm:text-xs">System Ready</div>
          </div>

          <div className="flex items-center space-x-2 sm:space-x-2.5 mt-1 sm:mt-2">
            {/* Daily Summary Button */}
            <button
              id="header-daily-summary-btn"
              onClick={() => {
                triggerHaptic('light');
                setActiveTab('summary');
              }}
              className={`flex items-center space-x-1.5 px-3 sm:px-3.5 py-1.5 sm:py-2 rounded-full text-[11px] sm:text-xs font-mono font-bold transition-all cursor-pointer ${
                activeTab === 'summary'
                  ? 'bg-[#111113] text-white shadow-xs'
                  : 'bg-white hover:bg-[#F2EFE9] text-[#1C1C1A] border border-black/10'
              }`}
              title="Daily Summary & AI Highlights"
            >
              <Sparkles className="w-3.5 h-3.5 text-[#FF5B5B]" />
              <span className="hidden sm:inline">Daily Summary</span>
              <span className="sm:hidden">Summary</span>
            </button>

            {/* Running timer pill indicator */}
            {focusSession.isRunning && (
              <button
                id="header-focus-timer-pill"
                onClick={onOpenFocusModal}
                className="flex items-center space-x-1.5 sm:space-x-2 bg-[#111113] text-white px-3 sm:px-3.5 py-1.5 rounded-full text-[11px] sm:text-xs font-mono font-bold shadow-md hover:bg-black transition-all cursor-pointer border border-white/10"
              >
                <span className="w-2 h-2 rounded-full bg-[#FF5B5B] animate-ping"></span>
                <span>{focusSession.lifeAreaEmoji} {formatTime(focusSession.remainingSeconds)}</span>
              </button>
            )}

            <button
              id="quick-capture-header-btn"
              onClick={() => {
                triggerHaptic('capture');
                onOpenQuickCapture();
              }}
              className="flex items-center space-x-1.5 bg-[#FF5B5B] hover:bg-[#ff4242] active:bg-[#e04545] text-white px-3.5 sm:px-4 py-1.5 sm:py-2 rounded-full text-[11px] sm:text-xs font-mono font-bold uppercase tracking-wider shadow-xs transition-all cursor-pointer hover:scale-105 active:scale-95 whitespace-nowrap"
            >
              <Plus className="w-3.5 h-3.5 sm:w-4 sm:h-4 stroke-[3]" />
              <span>Capture</span>
            </button>
          </div>
        </div>
      </div>
    </header>
  );
};

