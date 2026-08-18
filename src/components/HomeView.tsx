import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import {
  LifeArea,
  TaskItem,
  NudgeItem,
  CaptureItem,
  ActiveTab,
} from '../types';
import { ProductivityTrendChart } from './ProductivityTrendChart';
import { WeeklyFocusSummaryWidget } from './WeeklyFocusSummaryWidget';
import { triggerHaptic, formatFocusDuration } from '../utils/haptics';
import {
  ArrowUpDown,
  ChevronUp,
  ChevronDown,
  Play,
  ArrowRight,
  Plus,
  CheckCircle2,
  Check,
  BarChart3,
  TrendingUp,
  Maximize2,
  Minimize2,
} from 'lucide-react';

interface HomeViewProps {
  lifeAreas: LifeArea[];
  setLifeAreas: React.Dispatch<React.SetStateAction<LifeArea[]>>;
  tasks: TaskItem[];
  nudges: NudgeItem[];
  captures: CaptureItem[];
  onDismissNudge: (id: string) => void;
  onSelectLifeArea: (areaId: string) => void;
  setActiveTab: (tab: ActiveTab) => void;
  onOpenQuickCapture: () => void;
  onStartFocus: (task: TaskItem, durationSeconds?: number, nudgesCount?: number) => void;
}

export const HomeView: React.FC<HomeViewProps> = ({
  lifeAreas,
  setLifeAreas,
  tasks,
  nudges,
  captures,
  onDismissNudge,
  onSelectLifeArea,
  setActiveTab,
  onOpenQuickCapture,
  onStartFocus,
}) => {
  const [isArranging, setIsArranging] = useState(false);
  const [isWeeklyFocusExpanded, setIsWeeklyFocusExpanded] = useState(true);
  const [isTrendChartExpanded, setIsTrendChartExpanded] = useState(true);

  const activeAreas = lifeAreas
    .filter((a) => !a.isArchived)
    .sort((a, b) => a.sortOrder - b.sortOrder);

  const unprocessedCaptures = captures.filter((c) => c.status === 'unprocessed');
  const dueNudges = nudges.filter((n) => n.isDue);
  const openTasks = tasks.filter((t) => t.status !== 'completed');
  const completedTasks = tasks.filter((t) => t.status === 'completed');

  // Overall task progress percentage
  const totalTasks = tasks.length;
  const completionPercent = totalTasks > 0 ? Math.round((completedTasks.length / totalTasks) * 100) : 75;

  // Active top priority task
  const topTask =
    openTasks.find((t) => t.priority === 'high') ||
    openTasks[0] || {
      id: 'default-active-goal',
      title: 'Break down Q3 Project Proposal into 15-min micro-steps',
      description: 'Focus on primary executive objectives first to avoid cognitive fatigue.',
      lifeAreaId: lifeAreas[0]?.id || 'work',
      priority: 'high' as const,
      status: 'todo' as const,
      tags: ['focus'],
      createdAt: new Date().toISOString(),
      focusMinutesTarget: 15,
    };

  const topTaskArea = lifeAreas.find((a) => a.id === topTask.lifeAreaId) || lifeAreas[0];
  const topDueNudge = dueNudges[0] || nudges[0];

  const moveArea = (index: number, direction: 'up' | 'down') => {
    const newAreas = [...activeAreas];
    const targetIndex = direction === 'up' ? index - 1 : index + 1;
    if (targetIndex < 0 || targetIndex >= newAreas.length) return;

    const temp = newAreas[index];
    newAreas[index] = newAreas[targetIndex];
    newAreas[targetIndex] = temp;

    const updated = lifeAreas.map((area) => {
      const foundIdx = newAreas.findIndex((a) => a.id === area.id);
      if (foundIdx !== -1) {
        return { ...area, sortOrder: foundIdx + 1 };
      }
      return area;
    });

    setLifeAreas(updated);
  };

  const toggleAllGraphs = (expand: boolean) => {
    triggerHaptic('light');
    setIsWeeklyFocusExpanded(expand);
    setIsTrendChartExpanded(expand);
  };

  return (
    <div className="space-y-6 sm:space-y-10 pb-24 sm:pb-28">
      {/* 1. Main Bento Grid matching Design Variation */}
      <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3.5 sm:gap-5 lg:gap-6">
        {/* Card 1: Active Goal (Dark Card, Spans 2 cols & 2 rows on desktop) */}
        <div
          id="active-goal-card"
          className="dark-card rounded-2xl sm:rounded-[32px] lg:rounded-[40px] p-5 sm:p-7 lg:p-9 lg:col-span-2 lg:row-span-2 flex flex-col justify-between shadow-2xl relative overflow-hidden group min-h-[320px] sm:min-h-[380px]"
        >
          <div>
            <div className="flex items-center justify-between">
              <span className="label text-[#FF5B5B] text-[10px] sm:text-xs">
                Active Goal {topTaskArea ? `• ${topTaskArea.name}` : ''}
              </span>
              <span className="text-[9px] sm:text-[10px] font-mono uppercase font-bold text-white/70 bg-white/10 px-2 sm:px-2.5 py-0.5 rounded-full">
                {topTask.priority} priority
              </span>
            </div>

            <h2 className="text-xl sm:text-2xl lg:text-3xl font-light leading-snug mt-3 mb-2 sm:mt-4 sm:mb-3 text-white tracking-tight">
              {topTask.title}
            </h2>

            {topTask.description && (
              <p className="text-xs sm:text-sm text-zinc-400 font-sans line-clamp-2 mb-3 sm:mb-4">
                {topTask.description}
              </p>
            )}
          </div>

          <div className="space-y-4 sm:space-y-6 pt-3 sm:pt-4">
            <div className="space-y-1.5 sm:space-y-2">
              <div className="flex justify-between text-[11px] sm:text-xs font-mono text-zinc-400">
                <span>Task Focus Target</span>
                <span className="text-[#FF5B5B] font-bold">
                  {formatFocusDuration(topTask.focusDurationSeconds || (topTask.focusMinutesTarget || 15) * 60)} sprint ({typeof topTask.nudgesCount === 'number' ? topTask.nudgesCount : (topTask.focusDurationSeconds || 900) <= 60 ? 1 : 2} 🔔)
                </span>
              </div>
              <div className="progress-bar">
                <div
                  className="progress-fill h-full"
                  style={{ width: `${Math.max(25, completionPercent)}%` }}
                ></div>
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-2.5 sm:gap-3">
              <button
                id="start-session-btn"
                onClick={() => {
                  const secs = topTask.focusDurationSeconds || (topTask.focusMinutesTarget ? topTask.focusMinutesTarget * 60 : 15 * 60);
                  const nudges = typeof topTask.nudgesCount === 'number' ? topTask.nudgesCount : secs <= 60 ? 1 : 2;
                  onStartFocus(topTask, secs, nudges);
                }}
                className="bg-[#FF5B5B] hover:bg-[#ff4242] active:bg-[#e04545] text-white py-2.5 sm:py-3.5 px-6 sm:px-8 rounded-full font-bold font-mono text-xs sm:text-sm tracking-wider uppercase shadow-md transition-all cursor-pointer hover:scale-105 active:scale-95 flex items-center space-x-2 whitespace-nowrap"
              >
                <Play className="w-3.5 h-3.5 sm:w-4 sm:h-4 fill-current" />
                <span>START SESSION</span>
              </button>

              <button
                id="manage-active-task-btn"
                onClick={() => {
                  onSelectLifeArea(topTask.lifeAreaId);
                }}
                className="bg-white/10 hover:bg-white/20 active:bg-white/30 text-white py-2.5 sm:py-3.5 px-4 sm:px-6 rounded-full font-mono text-xs uppercase font-bold transition-all cursor-pointer whitespace-nowrap"
              >
                Manage Tasks
              </button>
            </div>
          </div>
        </div>

        {/* Card 2: Inbox Triage (Light Card, Span 1) */}
        <div
          id="inbox-triage-card"
          onClick={() => setActiveTab('capture')}
          className="light-card rounded-2xl sm:rounded-[32px] p-5 sm:p-7 flex flex-col justify-between shadow-xs hover:border-black/20 transition-all cursor-pointer group min-h-[170px] sm:min-h-[190px]"
        >
          <div className="flex items-center justify-between">
            <span className="label text-[#1C1C1A]/70 group-hover:text-[#1C1C1A] text-[10px] sm:text-xs">Inbox Triage</span>
            <ArrowRight className="w-4 h-4 text-[#1C1C1A]/40 group-hover:text-[#1C1C1A] transition-transform group-hover:translate-x-1" />
          </div>

          <div>
            <div className="text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight text-[#1C1C1A] leading-none mb-1 font-mono">
              {unprocessedCaptures.length}
            </div>
            <p className="text-[11px] sm:text-xs text-[#1C1C1A]/60 font-medium">Unprocessed items.</p>
          </div>
        </div>

        {/* Card 3: Health & Progress (Light Card, Span 1) */}
        <div
          id="health-progress-card"
          onClick={() => setActiveTab('tasks')}
          className="light-card rounded-2xl sm:rounded-[32px] p-5 sm:p-7 flex flex-col justify-between shadow-xs hover:border-black/20 transition-all cursor-pointer group min-h-[170px] sm:min-h-[190px]"
        >
          <div className="flex items-center justify-between">
            <span className="label text-[#1C1C1A]/70 text-[10px] sm:text-xs">Health</span>
            <span className="text-[9px] sm:text-[10px] font-mono text-[#1C1C1A]/50 uppercase">{completedTasks.length} done</span>
          </div>

          <div className="flex items-center space-x-3 sm:space-x-4">
            <div className="progress-circle w-16 h-16 sm:w-20 sm:h-20 text-base sm:text-xl font-mono text-[#1C1C1A] shrink-0">
              {completionPercent}%
            </div>
            <div className="text-[11px] sm:text-xs text-[#1C1C1A]/70 font-mono leading-tight">
              <span className="font-bold text-[#1C1C1A] block">{openTasks.length} pending</span>
              <span>Daily stack</span>
            </div>
          </div>
        </div>

        {/* Card 4: Journal (Dark Card, Span 1) */}
        <div
          id="journal-preview-card"
          onClick={() => setActiveTab('journal')}
          className="dark-card rounded-2xl sm:rounded-[32px] p-5 sm:p-7 flex flex-col justify-between shadow-lg hover:border-white/20 transition-all cursor-pointer group min-h-[170px] sm:min-h-[190px]"
        >
          <div className="flex items-center justify-between">
            <span className="label text-white/50 group-hover:text-white text-[10px] sm:text-xs">Journal</span>
            <ArrowRight className="w-4 h-4 text-white/30 group-hover:text-white transition-transform group-hover:translate-x-1" />
          </div>

          <div>
            <p className="font-medium text-sm sm:text-base lg:text-lg leading-snug text-white">
              Ready to log<br />the day.
            </p>
            <span className="text-[10px] sm:text-[11px] font-mono text-zinc-400 mt-1.5 sm:mt-2 block">
              Dopamine & energy check
            </span>
          </div>
        </div>

        {/* Card 5: Nudges (Dark Card, Span 1) */}
        <div
          id="nudges-preview-card"
          onClick={() => setActiveTab('nudges')}
          className="dark-card rounded-2xl sm:rounded-[32px] p-5 sm:p-7 flex flex-col justify-between shadow-lg hover:border-[#FF5B5B]/50 transition-all cursor-pointer group min-h-[170px] sm:min-h-[190px]"
        >
          <div className="flex items-center justify-between">
            <span className="label text-[#FF5B5B] text-[10px] sm:text-xs">Nudges</span>
            {dueNudges.length > 0 && (
              <span className="w-2 h-2 rounded-full bg-[#FF5B5B] animate-pulse"></span>
            )}
          </div>

          <div>
            <h3 className="text-sm sm:text-base lg:text-lg font-light leading-snug text-white line-clamp-2">
              {topDueNudge ? topDueNudge.label : 'Hydration & Posture Reset'}
            </h3>
            <span className="text-[10px] sm:text-[11px] font-mono text-zinc-400 mt-1 block">
              {topDueNudge ? topDueNudge.schedule : 'Every 2 hours'}
            </span>
          </div>
        </div>
      </section>

      {/* Global Charts Free-Viewing Header */}
      <div className="flex items-center justify-between pt-2 border-t border-black/5">
        <div className="flex items-center space-x-2">
          <BarChart3 className="w-4 h-4 text-[#FF5B5B]" />
          <span className="label text-[#1C1C1A]/70 text-[10px] sm:text-xs">Performance & Focus Intelligence</span>
        </div>

        <div className="flex items-center space-x-2">
          <button
            onClick={() => toggleAllGraphs(!isWeeklyFocusExpanded || !isTrendChartExpanded)}
            className="flex items-center space-x-1.5 text-[11px] font-mono text-[#1C1C1A]/60 hover:text-[#1C1C1A] px-3 py-1 rounded-full border border-black/10 hover:border-black/20 bg-white cursor-pointer transition-colors"
          >
            {isWeeklyFocusExpanded && isTrendChartExpanded ? (
              <>
                <Minimize2 className="w-3 h-3" />
                <span>Collapse Analytics</span>
              </>
            ) : (
              <>
                <Maximize2 className="w-3 h-3" />
                <span>Expand All Analytics</span>
              </>
            )}
          </button>
        </div>
      </div>

      {/* 2. Focus Sessions Weekly Summary Widget (Collapsible) */}
      <section id="weekly-focus-graph-container" className="space-y-2">
        <div className="flex items-center justify-between">
          <button
            type="button"
            onClick={() => {
              triggerHaptic('light');
              setIsWeeklyFocusExpanded(!isWeeklyFocusExpanded);
            }}
            className="flex items-center space-x-2 text-xs font-mono font-bold text-[#1C1C1A]/80 hover:text-[#FF5B5B] cursor-pointer group"
          >
            {isWeeklyFocusExpanded ? (
              <ChevronUp className="w-4 h-4 transition-transform group-hover:-translate-y-0.5" />
            ) : (
              <ChevronDown className="w-4 h-4 transition-transform group-hover:translate-y-0.5" />
            )}
            <span>Weekly Focus Sprints Breakdown</span>
            <span className="text-[10px] font-normal text-zinc-500">
              {isWeeklyFocusExpanded ? '(Click to collapse)' : '(Collapsed — Click to expand)'}
            </span>
          </button>
        </div>

        <AnimatePresence initial={false}>
          {isWeeklyFocusExpanded ? (
            <motion.div
              key="weekly-focus-expanded"
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              transition={{ duration: 0.25, ease: 'easeInOut' }}
              className="overflow-hidden"
            >
              <WeeklyFocusSummaryWidget
                tasks={tasks}
                lifeAreas={lifeAreas}
                onStartFocus={onStartFocus}
                onViewTasksTab={() => setActiveTab('tasks')}
              />
            </motion.div>
          ) : (
            <motion.div
              key="weekly-focus-collapsed"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsWeeklyFocusExpanded(true)}
              className="bg-[#EFECE8] hover:bg-[#eae6e1] p-3 rounded-2xl border border-black/5 flex items-center justify-between text-xs font-mono text-[#1C1C1A]/70 cursor-pointer transition-colors"
            >
              <div className="flex items-center space-x-2">
                <BarChart3 className="w-4 h-4 text-[#FF5B5B]" />
                <span>Focus Sprint Analytics (Minimized)</span>
              </div>
              <span className="text-[11px] text-[#FF5B5B] font-bold">Expand graph +</span>
            </motion.div>
          )}
        </AnimatePresence>
      </section>

      {/* 3. 7-Day Productivity Velocity Trend Chart (Collapsible) */}
      <section id="productivity-trend-graph-container" className="space-y-2">
        <div className="flex items-center justify-between">
          <button
            type="button"
            onClick={() => {
              triggerHaptic('light');
              setIsTrendChartExpanded(!isTrendChartExpanded);
            }}
            className="flex items-center space-x-2 text-xs font-mono font-bold text-[#1C1C1A]/80 hover:text-[#FF5B5B] cursor-pointer group"
          >
            {isTrendChartExpanded ? (
              <ChevronUp className="w-4 h-4 transition-transform group-hover:-translate-y-0.5" />
            ) : (
              <ChevronDown className="w-4 h-4 transition-transform group-hover:translate-y-0.5" />
            )}
            <span>7-Day Productivity Velocity Trend</span>
            <span className="text-[10px] font-normal text-zinc-500">
              {isTrendChartExpanded ? '(Click to collapse)' : '(Collapsed — Click to expand)'}
            </span>
          </button>
        </div>

        <AnimatePresence initial={false}>
          {isTrendChartExpanded ? (
            <motion.div
              key="trend-chart-expanded"
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              transition={{ duration: 0.25, ease: 'easeInOut' }}
              className="overflow-hidden"
            >
              <ProductivityTrendChart
                tasks={tasks}
                onViewTasksTab={() => setActiveTab('tasks')}
              />
            </motion.div>
          ) : (
            <motion.div
              key="trend-chart-collapsed"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsTrendChartExpanded(true)}
              className="bg-[#EFECE8] hover:bg-[#eae6e1] p-3 rounded-2xl border border-black/5 flex items-center justify-between text-xs font-mono text-[#1C1C1A]/70 cursor-pointer transition-colors"
            >
              <div className="flex items-center space-x-2">
                <TrendingUp className="w-4 h-4 text-emerald-600" />
                <span>Productivity Velocity Curve (Minimized)</span>
              </div>
              <span className="text-[11px] text-[#FF5B5B] font-bold">Expand graph +</span>
            </motion.div>
          )}
        </AnimatePresence>
      </section>

      {/* 4. Life Areas Channels Section */}
      <section className="space-y-4 sm:space-y-5">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 sm:gap-3 border-b border-black/5 pb-3">
          <div>
            <span className="label text-[#FF5B5B] text-[10px] sm:text-xs">Domain Alignment</span>
            <h3 className="text-lg sm:text-2xl font-bold text-[#1C1C1A] tracking-tight">Life Areas</h3>
          </div>

          <div className="flex items-center space-x-3">
            {activeAreas.length >= 2 && (
              <button
                id="home-arrange-button"
                onClick={() => setIsArranging(!isArranging)}
                className={`flex items-center space-x-1.5 px-3.5 sm:px-4 py-1.5 rounded-full text-[11px] sm:text-xs font-mono font-bold uppercase transition-all cursor-pointer border ${
                  isArranging
                    ? 'bg-emerald-600 hover:bg-emerald-700 text-white border-emerald-600 shadow-xs hover:scale-105 active:scale-95'
                    : 'bg-white hover:bg-black/5 text-[#1C1C1A] border-black/10'
                }`}
              >
                {isArranging ? (
                  <Check className="w-3.5 h-3.5 stroke-[2.5]" />
                ) : (
                  <ArrowUpDown className="w-3.5 h-3.5" />
                )}
                <span>{isArranging ? 'Done' : 'Arrange'}</span>
              </button>
            )}

            <button
              onClick={() => setActiveTab('tasks')}
              className="text-[11px] sm:text-xs font-mono text-[#1C1C1A] font-bold hover:underline flex items-center space-x-1 cursor-pointer whitespace-nowrap"
            >
              <span>View All Tasks</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

        {/* Arrange Mode */}
        {isArranging ? (
          <div id="home-reorder-container" className="bg-[#EFECE8] rounded-2xl sm:rounded-3xl border border-black/5 divide-y divide-black/5 overflow-hidden">
            <div className="p-3 bg-black/5 text-[11px] sm:text-xs font-mono text-[#1C1C1A]/60">
              Reorder Life Areas
            </div>
            {activeAreas.map((area, idx) => (
              <div
                key={area.id}
                className="p-3 sm:p-4 flex items-center justify-between bg-white hover:bg-[#F8F7F4] transition-colors"
              >
                <div className="flex items-center space-x-3">
                  <span className="text-xl">{area.emoji}</span>
                  <span className="font-bold text-sm sm:text-base text-[#1C1C1A]">{area.name}</span>
                </div>

                <div className="flex items-center space-x-1">
                  <button
                    disabled={idx === 0}
                    onClick={() => moveArea(idx, 'up')}
                    className="p-2 rounded-xl bg-[#EFECE8] hover:bg-black/10 disabled:opacity-30 cursor-pointer disabled:cursor-not-allowed"
                  >
                    <ChevronUp className="w-4 h-4 text-[#1C1C1A]" />
                  </button>
                  <button
                    disabled={idx === activeAreas.length - 1}
                    onClick={() => moveArea(idx, 'down')}
                    className="p-2 rounded-xl bg-[#EFECE8] hover:bg-black/10 disabled:opacity-30 cursor-pointer disabled:cursor-not-allowed"
                  >
                    <ChevronDown className="w-4 h-4 text-[#1C1C1A]" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3.5 sm:gap-4">
            {activeAreas.map((area) => {
              const areaTasks = tasks.filter((t) => t.lifeAreaId === area.id);
              const areaCompleted = areaTasks.filter((t) => t.status === 'completed');
              const areaOpen = areaTasks.filter((t) => t.status !== 'completed');

              return (
                <div
                  key={area.id}
                  id={`home-life-area-${area.id}`}
                  onClick={() => onSelectLifeArea(area.id)}
                  className="bg-[#EFECE8] hover:bg-[#eae6e1] border border-black/5 hover:border-black/15 p-4 sm:p-5 rounded-2xl sm:rounded-3xl transition-all cursor-pointer group flex flex-col justify-between min-h-[130px] sm:min-h-[140px]"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex items-center space-x-2.5">
                      <span className="text-2xl p-1 bg-white/60 rounded-xl shadow-xs">{area.emoji}</span>
                      <div>
                        <h4 className="font-bold text-sm sm:text-base text-[#1C1C1A] group-hover:text-[#FF5B5B] transition-colors">
                          {area.name}
                        </h4>
                        <span className="text-[10px] sm:text-[11px] font-mono text-[#1C1C1A]/50 uppercase">
                          Channel
                        </span>
                      </div>
                    </div>

                    <span className="text-xs font-mono font-bold text-[#1C1C1A]/70 bg-white/70 px-2 py-0.5 rounded-full border border-black/5">
                      {areaOpen.length} active
                    </span>
                  </div>

                  <div className="pt-3 flex items-center justify-between text-[11px] font-mono text-[#1C1C1A]/60 border-t border-black/5 mt-3">
                    <span>{areaCompleted.length} completed</span>
                    <span className="group-hover:translate-x-0.5 transition-transform text-[#1C1C1A] font-bold">
                      Open →
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </section>
    </div>
  );
};

