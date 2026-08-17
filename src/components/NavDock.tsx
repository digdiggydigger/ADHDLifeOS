import React from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ActiveTab } from '../types';
import { LayoutGrid, Inbox, CheckSquare, BookOpen, Bell, Settings, Plus } from 'lucide-react';

interface NavDockProps {
  activeTab: ActiveTab;
  setActiveTab: (tab: ActiveTab) => void;
  unprocessedCount: number;
  dueNudgesCount: number;
  openTasksCount: number;
  onOpenQuickCapture: () => void;
}

export const NavDock: React.FC<NavDockProps> = ({
  activeTab,
  setActiveTab,
  unprocessedCount,
  dueNudgesCount,
  openTasksCount,
  onOpenQuickCapture,
}) => {
  const navItems: { tab: ActiveTab; label: string; badge?: number; badgeColor?: string }[] = [
    { tab: 'home', label: 'Dashboard' },
    { tab: 'capture', label: 'Inbox', badge: unprocessedCount, badgeColor: 'bg-[#FF5B5B]' },
    { tab: 'tasks', label: 'Tasks', badge: openTasksCount, badgeColor: 'bg-white/20' },
    { tab: 'journal', label: 'Journal' },
    { tab: 'nudges', label: 'Nudges', badge: dueNudgesCount, badgeColor: 'bg-[#FF5B5B]' },
    { tab: 'settings', label: 'Settings' },
  ];

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0, y: 24, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: 24, scale: 0.96 }}
        transition={{ type: 'spring', stiffness: 350, damping: 28 }}
        className="fixed bottom-3 sm:bottom-8 left-1/2 -translate-x-1/2 z-40 max-w-[calc(100vw-1.25rem)] w-auto flex items-center justify-center pointer-events-none"
      >
        <motion.nav
          id="nav-dock"
          layout
          className="pointer-events-auto bg-[#1C1C1A] text-white pl-3.5 pr-2 sm:pl-7 sm:pr-3 py-1.5 sm:py-2.5 rounded-full flex items-center shadow-[0_10px_40px_rgba(0,0,0,0.4)] border border-white/10 backdrop-blur-md transition-all max-w-full"
        >
          {/* Scrollable Nav links area */}
          <div className="flex items-center gap-3 sm:gap-6 overflow-x-auto no-scrollbar whitespace-nowrap scroll-smooth touch-pan-x overscroll-x-contain py-1 pr-2.5">
            {navItems.map((item) => {
              const isActive = activeTab === item.tab;
              return (
                <button
                  key={item.tab}
                  id={`nav-link-${item.tab}`}
                  onClick={() => setActiveTab(item.tab)}
                  className={`shrink-0 whitespace-nowrap relative flex items-center space-x-1.5 font-mono text-[11px] sm:text-xs font-bold uppercase tracking-[0.12em] sm:tracking-[0.15em] transition-all cursor-pointer py-1 px-1 sm:px-0 ${
                    isActive ? 'text-white' : 'text-[#AFAFAF] hover:text-white'
                  }`}
                >
                  <span>{item.label}</span>
                  {typeof item.badge === 'number' && item.badge > 0 && (
                    <motion.span
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      exit={{ scale: 0 }}
                      className={`text-[9px] px-1.5 py-0.2 rounded-full font-bold leading-none shrink-0 ${
                        item.badgeColor || 'bg-[#FF5B5B]'
                      } text-white`}
                    >
                      {item.badge}
                    </motion.span>
                  )}
                  {isActive && (
                    <motion.span
                      layoutId="activeNavIndicator"
                      className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-1.5 h-1.5 bg-[#FF5B5B] rounded-full"
                      transition={{ type: 'spring', stiffness: 380, damping: 30 }}
                    />
                  )}
                </button>
              );
            })}
          </div>

          {/* Fixed Divider */}
          <div className="h-5 w-px bg-white/20 shrink-0 mx-1"></div>

          {/* Pinned & Always Visible Quick Capture Button */}
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.94 }}
            id="nav-dock-quick-capture"
            onClick={onOpenQuickCapture}
            className="shrink-0 whitespace-nowrap flex items-center space-x-1.5 bg-[#FF5B5B] hover:bg-[#ff4242] active:bg-[#e04545] text-white px-3.5 sm:px-4 py-2 rounded-full font-mono text-[11px] sm:text-xs font-bold uppercase tracking-wider transition-colors cursor-pointer shadow-[0_2px_12px_rgba(255,91,91,0.4)] ml-1"
            title="Quick Capture thought (Always accessible)"
          >
            <Plus className="w-3.5 h-3.5 stroke-[3]" />
            <span>Capture</span>
          </motion.button>
        </motion.nav>
      </motion.div>
    </AnimatePresence>
  );
};
