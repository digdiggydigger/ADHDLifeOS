import React, { useState, useEffect, useMemo } from 'react';
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
import { getAreaColorConfig } from '../utils/areaColors';
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
  SlidersHorizontal,
  Sparkles,
  Eye,
  EyeOff,
  Flame,
  Clock,
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

  // Persistent statistics widget expansion states with localStorage
  const [isWeeklyFocusExpanded, setIsWeeklyFocusExpanded] = useState<boolean>(() => {
    try {
      const saved = localStorage.getItem('lifeos_weekly_focus_expanded');
      return saved !== null ? JSON.parse(saved) : true;
    } catch {
      return true;
    }
  });

  const [isTrendChartExpanded, setIsTrendChartExpanded] = useState<boolean>(() => {
    try {
      const saved = localStorage.getItem('lifeos_trend_chart_expanded');
      return saved !== null ? JSON.parse(saved) : true;
    } catch {
      return true;
    }
  });

  // Save changes to localStorage
  useEffect(() => {
    try {
      localStorage.setItem('lifeos_weekly_focus_expanded', JSON.stringify(isWeeklyFocusExpanded));
    } catch {
      // ignore
    }
  }, [isWeeklyFocusExpanded]);

  useEffect(() => {
    try {
      localStorage.setItem('lifeos_trend_chart_expanded', JSON.stringify(isTrendChartExpanded));
    } catch {
      // ignore
    }
  }, [isTrendChartExpanded]);

  const activeAreas = lifeAreas
    .filter((a) => !a.isArchived)
    .sort((a, b) => a.sortOrder - b.sortOrder);

  const unprocessedCaptures = captures.filter((c) => c.status === 'unprocessed');
  const dueNudges = nudges.filter((n) => n.isDue);
  const openTasks = tasks.filter((t) => t.status !== 'completed');
  const completedTasks = tasks.filter((t) => t.status === 'completed');

  // Compute key summarized metrics for collapsed stats badges
  const statsSummary = useMemo(() => {
    let totalFocusSeconds = 0;
    let totalSprints = 0;
    tasks.forEach((t) => {
      if (t.focusHistory && t.focusHistory.length > 0) {
        totalSprints += t.focusHistory.length;
        t.focusHistory.forEach((h) => {
          totalFocusSeconds += h.durationSeconds;
        });
      }
    });

    const completionRate = tasks.length > 0 ? Math.round((completedTasks.length / tasks.length) * 100) : 0;
    return {
      totalFocusMinutes: Math.round(totalFocusSeconds / 60),
      totalSprints,
      completionRate,
    };
  }, [tasks, completedTasks]);

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
    triggerHaptic('medium');
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

      {/* Daily Summary & Gemini AI Highlights Spotlight */}
      <section
        id="home-daily-summary-spotlight"
        className="light-card rounded-2xl sm:rounded-[32px] p-5 sm:p-7 border-2 border-[#FF5B5B]/20 bg-gradient-to-r from-white via-white to-[#FF5B5B]/5 shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4"
      >
        <div className="flex items-start space-x-3 sm:space-x-4">
          <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-2xl bg-[#FF5B5B]/10 text-[#FF5B5B] flex items-center justify-center shrink-0 shadow-2xs">
            <Sparkles className="w-5 h-5 sm:w-6 sm:h-6" />
          </div>
          <div className="space-y-1">
            <div className="inline-flex items-center space-x-2">
              <span className="label text-[#FF5B5B] text-[10px] sm:text-xs font-mono font-bold">
                Daily Highlights • Gemini 3.7 Flash
              </span>
              <span className="text-[10px] font-mono px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800">
                {completedTasks.length} Done Today
              </span>
            </div>
            <h3 className="text-base sm:text-lg font-black text-[#1C1C1A]">
              Daily Executive Recap & Dopamine Wins
            </h3>
            <p className="text-xs text-[#1C1C1A]/70 max-w-xl">
              Synthesize today's completed tasks, focus stamina, and journal reflections into a motivating, neurodivergent-friendly highlight reel.
            </p>
          </div>
        </div>

        <button
          id="home-open-daily-summary-btn"
          onClick={() => {
            triggerHaptic('medium');
            setActiveTab('summary');
          }}
          className="inline-flex items-center justify-center space-x-2 px-5 py-3 rounded-2xl bg-[#111113] hover:bg-black active:scale-95 text-white text-xs sm:text-sm font-bold shadow-md transition-all cursor-pointer shrink-0"
        >
          <Sparkles className="w-4 h-4 text-[#FF5B5B]" />
          <span>View Daily Summary</span>
          <ArrowRight className="w-4 h-4 ml-0.5" />
        </button>
      </section>

      {/* Global Charts Free-Viewing & Dashboard Space Customizer Header */}
      <div className="bg-[#EFECE8] rounded-2xl sm:rounded-3xl p-3.5 sm:p-4 border border-black/5 space-y-3">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2.5">
          <div className="flex items-center space-x-2">
            <div className="p-1.5 rounded-xl bg-white shadow-xs border border-black/5">
              <BarChart3 className="w-4 h-4 text-[#FF5B5B]" />
            </div>
            <div>
              <span className="label text-[#1C1C1A]/70 text-[10px] sm:text-xs block">Dashboard Workspace</span>
              <h4 className="text-xs sm:text-sm font-bold text-[#1C1C1A] tracking-tight">Performance & Focus Intelligence</h4>
            </div>
          </div>

          {/* Quick Toggle Toolbar */}
          <div className="flex flex-wrap items-center gap-1.5 sm:gap-2">
            {/* Weekly Focus Toggle Chip */}
            <button
              onClick={() => {
                triggerHaptic('light');
                setIsWeeklyFocusExpanded(!isWeeklyFocusExpanded);
              }}
              className={`flex items-center space-x-1.5 text-[11px] font-mono font-bold px-2.5 sm:px-3 py-1 rounded-full border transition-all cursor-pointer ${
                isWeeklyFocusExpanded
                  ? 'bg-[#FF5B5B] text-white border-[#FF5B5B] shadow-xs'
                  : 'bg-white text-[#1C1C1A]/70 border-black/10 hover:border-black/20'
              }`}
              title={isWeeklyFocusExpanded ? 'Click to collapse Weekly Focus Sprints' : 'Click to show Weekly Focus Sprints'}
            >
              {isWeeklyFocusExpanded ? <Eye className="w-3 h-3" /> : <EyeOff className="w-3 h-3" />}
              <span>Sprints Graph</span>
            </button>

            {/* Velocity Curve Toggle Chip */}
            <button
              onClick={() => {
                triggerHaptic('light');
                setIsTrendChartExpanded(!isTrendChartExpanded);
              }}
              className={`flex items-center space-x-1.5 text-[11px] font-mono font-bold px-2.5 sm:px-3 py-1 rounded-full border transition-all cursor-pointer ${
                isTrendChartExpanded
                  ? 'bg-emerald-600 text-white border-emerald-600 shadow-xs'
                  : 'bg-white text-[#1C1C1A]/70 border-black/10 hover:border-black/20'
              }`}
              title={isTrendChartExpanded ? 'Click to collapse Velocity Trend' : 'Click to show Velocity Trend'}
            >
              {isTrendChartExpanded ? <Eye className="w-3 h-3" /> : <EyeOff className="w-3 h-3" />}
              <span>Velocity Curve</span>
            </button>

            {/* Expand / Collapse All Action */}
            <button
              onClick={() => toggleAllGraphs(!isWeeklyFocusExpanded || !isTrendChartExpanded)}
              className="flex items-center space-x-1.5 text-[11px] font-mono font-bold text-[#1C1C1A]/70 hover:text-[#1C1C1A] px-2.5 sm:px-3 py-1 rounded-full border border-black/10 hover:border-black/25 bg-white cursor-pointer transition-colors shadow-xs"
            >
              {isWeeklyFocusExpanded && isTrendChartExpanded ? (
                <>
                  <Minimize2 className="w-3 h-3" />
                  <span>Collapse All</span>
                </>
              ) : (
                <>
                  <Maximize2 className="w-3 h-3" />
                  <span>Expand All</span>
                </>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* 2. Focus Sessions Weekly Summary Widget (Collapsible) */}
      <section id="weekly-focus-graph-container" className="space-y-2">
        <div className="flex items-center justify-between px-1">
          <button
            type="button"
            onClick={() => {
              triggerHaptic('light');
              setIsWeeklyFocusExpanded(!isWeeklyFocusExpanded);
            }}
            className="flex items-center space-x-2 text-xs font-mono font-bold text-[#1C1C1A]/80 hover:text-[#FF5B5B] cursor-pointer group"
          >
            <div className="w-5 h-5 rounded-full bg-[#EFECE8] flex items-center justify-center border border-black/5 group-hover:border-[#FF5B5B]">
              {isWeeklyFocusExpanded ? (
                <ChevronUp className="w-3.5 h-3.5 transition-transform group-hover:-translate-y-0.5" />
              ) : (
                <ChevronDown className="w-3.5 h-3.5 transition-transform group-hover:translate-y-0.5" />
              )}
            </div>
            <span>Weekly Focus Sprints Breakdown</span>
            <span className="text-[10px] font-normal text-zinc-500 hidden sm:inline">
              {isWeeklyFocusExpanded ? '(Click to minimize)' : '(Minimized — Click to expand)'}
            </span>
          </button>

          <span className="text-[10px] font-mono text-zinc-500">
            {isWeeklyFocusExpanded ? 'Expanded' : 'Collapsed'}
          </span>
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
              initial={{ opacity: 0, scale: 0.98 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.98 }}
              onClick={() => {
                triggerHaptic('light');
                setIsWeeklyFocusExpanded(true);
              }}
              className="bg-white hover:bg-[#FAF8F5] p-3 sm:p-4 rounded-2xl sm:rounded-3xl border border-black/10 hover:border-[#FF5B5B]/40 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs font-mono text-[#1C1C1A]/80 cursor-pointer transition-all shadow-xs group"
            >
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 rounded-xl bg-[#FF5B5B]/10 text-[#FF5B5B] flex items-center justify-center font-bold">
                  <BarChart3 className="w-4 h-4" />
                </div>
                <div>
                  <div className="flex items-center space-x-2">
                    <span className="font-bold text-[#1C1C1A]">Focus Sprints Summary</span>
                    <span className="text-[10px] px-2 py-0.5 rounded-full bg-black/5 text-zinc-600 font-normal">
                      Minimized
                    </span>
                  </div>
                  <span className="text-[11px] text-zinc-500 block mt-0.5">
                    {statsSummary.totalSprints} recorded focus sprints ({statsSummary.totalFocusMinutes} min total flow time)
                  </span>
                </div>
              </div>

              <div className="flex items-center justify-between sm:justify-end space-x-3 pt-2 sm:pt-0 border-t sm:border-t-0 border-black/5">
                <div className="flex items-center space-x-1.5 text-xs text-[#FF5B5B] font-bold">
                  <Clock className="w-3.5 h-3.5" />
                  <span>{statsSummary.totalFocusMinutes} mins</span>
                </div>
                <span className="text-[11px] text-white bg-[#1C1C1A] px-3 py-1 rounded-full font-bold group-hover:bg-[#FF5B5B] transition-colors">
                  Expand Chart +
                </span>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </section>

      {/* 3. 7-Day Productivity Velocity Trend Chart (Collapsible) */}
      <section id="productivity-trend-graph-container" className="space-y-2">
        <div className="flex items-center justify-between px-1">
          <button
            type="button"
            onClick={() => {
              triggerHaptic('light');
              setIsTrendChartExpanded(!isTrendChartExpanded);
            }}
            className="flex items-center space-x-2 text-xs font-mono font-bold text-[#1C1C1A]/80 hover:text-[#FF5B5B] cursor-pointer group"
          >
            <div className="w-5 h-5 rounded-full bg-[#EFECE8] flex items-center justify-center border border-black/5 group-hover:border-emerald-600">
              {isTrendChartExpanded ? (
                <ChevronUp className="w-3.5 h-3.5 transition-transform group-hover:-translate-y-0.5" />
              ) : (
                <ChevronDown className="w-3.5 h-3.5 transition-transform group-hover:translate-y-0.5" />
              )}
            </div>
            <span>7-Day Productivity Velocity Trend</span>
            <span className="text-[10px] font-normal text-zinc-500 hidden sm:inline">
              {isTrendChartExpanded ? '(Click to minimize)' : '(Minimized — Click to expand)'}
            </span>
          </button>

          <span className="text-[10px] font-mono text-zinc-500">
            {isTrendChartExpanded ? 'Expanded' : 'Collapsed'}
          </span>
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
              initial={{ opacity: 0, scale: 0.98 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.98 }}
              onClick={() => {
                triggerHaptic('light');
                setIsTrendChartExpanded(true);
              }}
              className="bg-white hover:bg-[#FAF8F5] p-3 sm:p-4 rounded-2xl sm:rounded-3xl border border-black/10 hover:border-emerald-500/40 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs font-mono text-[#1C1C1A]/80 cursor-pointer transition-all shadow-xs group"
            >
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
                  <TrendingUp className="w-4 h-4" />
                </div>
                <div>
                  <div className="flex items-center space-x-2">
                    <span className="font-bold text-[#1C1C1A]">Productivity Velocity Trend</span>
                    <span className="text-[10px] px-2 py-0.5 rounded-full bg-black/5 text-zinc-600 font-normal">
                      Minimized
                    </span>
                  </div>
                  <span className="text-[11px] text-zinc-500 block mt-0.5">
                    {completedTasks.length} tasks completed ({statsSummary.completionRate}% completion rate)
                  </span>
                </div>
              </div>

              <div className="flex items-center justify-between sm:justify-end space-x-3 pt-2 sm:pt-0 border-t sm:border-t-0 border-black/5">
                <div className="flex items-center space-x-1.5 text-xs text-emerald-600 font-bold">
                  <Flame className="w-3.5 h-3.5" />
                  <span>{statsSummary.completionRate}% Rate</span>
                </div>
                <span className="text-[11px] text-white bg-[#1C1C1A] px-3 py-1 rounded-full font-bold group-hover:bg-emerald-600 transition-colors">
                  Expand Chart +
                </span>
              </div>
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
              const colorConfig = getAreaColorConfig(area.color);
              const areaTasks = tasks.filter((t) => t.lifeAreaId === area.id);
              const areaCompleted = areaTasks.filter((t) => t.status === 'completed');
              const areaOpen = areaTasks.filter((t) => t.status !== 'completed');

              return (
                <div
                  key={area.id}
                  id={`home-life-area-${area.id}`}
                  onClick={() => onSelectLifeArea(area.id)}
                  className={`bg-[#EFECE8] hover:bg-[#eae6e1] border border-black/5 hover:border-black/15 p-4 sm:p-5 rounded-2xl sm:rounded-3xl transition-all cursor-pointer group flex flex-col justify-between min-h-[130px] sm:min-h-[140px] border-l-4 ${colorConfig.borderLeftClass}`}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex items-center space-x-2.5">
                      <span className="text-2xl p-1 bg-white/60 rounded-xl shadow-xs">{area.emoji}</span>
                      <div>
                        <div className="flex items-center space-x-1.5">
                          <h4 className="font-bold text-sm sm:text-base text-[#1C1C1A] group-hover:text-[#FF5B5B] transition-colors truncate">
                            {area.name}
                          </h4>
                          <span className={`w-2 h-2 rounded-full ${colorConfig.dotClass} shrink-0 ring-1 ring-black/10`} />
                        </div>
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

