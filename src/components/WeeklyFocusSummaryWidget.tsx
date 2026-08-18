import React, { useState, useMemo } from 'react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  ReferenceLine,
  Cell,
} from 'recharts';
import { TaskItem, LifeArea } from '../types';
import { Timer, Flame, Target, Play, Sparkles, TrendingUp, BarChart2, Layers } from 'lucide-react';
import { triggerHaptic } from '../utils/haptics';

interface WeeklyFocusSummaryWidgetProps {
  tasks: TaskItem[];
  lifeAreas: LifeArea[];
  onStartFocus?: (task: TaskItem, durationMinutes?: number) => void;
  onViewTasksTab?: () => void;
}

interface DayFocusData {
  dateKey: string;
  dayShort: string;
  dayFullName: string;
  formattedDate: string;
  isToday: boolean;
  focusMinutes: number;
  focusHours: number;
  tasksCompleted: number;
  taskTitles: string[];
}

export const WeeklyFocusSummaryWidget: React.FC<WeeklyFocusSummaryWidgetProps> = ({
  tasks,
  lifeAreas,
  onStartFocus,
  onViewTasksTab,
}) => {
  const [viewMode, setViewMode] = useState<'minutes' | 'hours'>('minutes');
  const [chartStyle, setChartStyle] = useState<'bar' | 'area'>('bar');
  const [dailyTargetMinutes, setDailyTargetMinutes] = useState(30);

  // Compute Current Week's Focus Session Data (Monday through Sunday of the current week)
  const {
    weekDaysData,
    totalMinutesThisWeek,
    totalHoursThisWeek,
    weeklyGoalMinutes,
    weeklyProgressPercent,
    dailyAverageMinutes,
    activeFocusDaysCount,
    mostFocusedArea,
    weekDateRangeLabel,
  } = useMemo(() => {
    const now = new Date();
    // Get current day of week (0 = Sunday, 1 = Monday, ... 6 = Saturday)
    const currentDayOfWeek = now.getDay();
    // Convert so Monday = 0, Tuesday = 1, ... Sunday = 6
    const distanceToMonday = (currentDayOfWeek + 6) % 7;

    const monday = new Date(now);
    monday.setDate(now.getDate() - distanceToMonday);
    monday.setHours(0, 0, 0, 0);

    const days: DayFocusData[] = [];
    const areaMinutesMap: Record<string, number> = {};

    for (let i = 0; i < 7; i++) {
      const d = new Date(monday);
      d.setDate(monday.getDate() + i);

      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      const dateKey = `${year}-${month}-${day}`;

      const dayShort = d.toLocaleDateString('en-US', { weekday: 'short' });
      const dayFullName = d.toLocaleDateString('en-US', { weekday: 'long' });
      const formattedDate = d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      const isToday =
        d.getDate() === now.getDate() &&
        d.getMonth() === now.getMonth() &&
        d.getFullYear() === now.getFullYear();

      // Find tasks completed or logged on this date
      const matchingTasks = tasks.filter((t) => {
        let taskDate = '';
        if (t.completedAt) {
          taskDate = t.completedAt.split('T')[0];
        } else if (t.dueDate) {
          taskDate = t.dueDate;
        } else if (t.createdAt) {
          taskDate = t.createdAt.split('T')[0];
        }

        return taskDate === dateKey;
      });

      // Aggregate focus time logged for matching tasks
      let focusMins = 0;
      const titles: string[] = [];

      matchingTasks.forEach((t) => {
        const mins = t.focusMinutesLogged && t.focusMinutesLogged > 0
          ? t.focusMinutesLogged
          : t.status === 'completed'
          ? (t.focusMinutesTarget || 15)
          : 0;

        if (mins > 0) {
          focusMins += mins;
          titles.push(`${t.title} (${mins}m)`);
          areaMinutesMap[t.lifeAreaId] = (areaMinutesMap[t.lifeAreaId] || 0) + mins;
        }
      });

      days.push({
        dateKey,
        dayShort,
        dayFullName,
        formattedDate,
        isToday,
        focusMinutes: focusMins,
        focusHours: Number((focusMins / 60).toFixed(1)),
        tasksCompleted: matchingTasks.filter((t) => t.status === 'completed').length,
        taskTitles: titles,
      });
    }

    const totalMins = days.reduce((sum, d) => sum + d.focusMinutes, 0);
    const totalHrs = Number((totalMins / 60).toFixed(1));
    const weeklyGoal = dailyTargetMinutes * 7;
    const progressPct = Math.min(100, Math.round((totalMins / weeklyGoal) * 100));
    const activeDays = days.filter((d) => d.focusMinutes > 0).length;
    const dailyAvg = Math.round(totalMins / 7);

    // Identify Most Focused Area
    let topAreaId = '';
    let maxAreaMins = 0;
    Object.entries(areaMinutesMap).forEach(([id, m]) => {
      if (m > maxAreaMins) {
        maxAreaMins = m;
        topAreaId = id;
      }
    });

    const topArea = lifeAreas.find((a) => a.id === topAreaId);

    // Date range label: e.g. "Aug 11 – Aug 17"
    const startStr = days[0]?.formattedDate || '';
    const endStr = days[6]?.formattedDate || '';
    const rangeLabel = `${startStr} – ${endStr}`;

    return {
      weekDaysData: days,
      totalMinutesThisWeek: totalMins,
      totalHoursThisWeek: totalHrs,
      weeklyGoalMinutes: weeklyGoal,
      weeklyProgressPercent: progressPct,
      dailyAverageMinutes: dailyAvg,
      activeFocusDaysCount: activeDays,
      mostFocusedArea: topArea ? { area: topArea, minutes: maxAreaMins } : null,
      weekDateRangeLabel: rangeLabel,
    };
  }, [tasks, lifeAreas, dailyTargetMinutes]);

  // Format hours/minutes readable string
  const formatTotalTime = (totalMinutes: number) => {
    const hours = Math.floor(totalMinutes / 60);
    const mins = totalMinutes % 60;
    if (hours === 0) return `${mins}m`;
    if (mins === 0) return `${hours}h`;
    return `${hours}h ${mins}m`;
  };

  // Custom Tooltip for Recharts
  const CustomFocusTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const data: DayFocusData = payload[0].payload;
      return (
        <div className="bg-[#1C1C1A] text-white p-3.5 rounded-2xl shadow-2xl border border-white/15 max-w-xs font-sans text-xs space-y-2.5 z-50">
          <div className="flex items-center justify-between border-b border-white/10 pb-1.5">
            <span className="font-bold text-white font-mono text-xs">
              {data.dayFullName}, {data.formattedDate}
            </span>
            {data.isToday && (
              <span className="bg-[#FF5B5B] text-white text-[9px] px-1.5 py-0.5 rounded-full font-mono uppercase font-bold">
                Today
              </span>
            )}
          </div>

          <div className="grid grid-cols-2 gap-2 text-xs font-mono">
            <div className="bg-white/5 p-2 rounded-xl border border-white/5">
              <span className="text-zinc-400 text-[10px] block">Focus Time</span>
              <span className="text-[#FF5B5B] font-bold text-sm">
                {data.focusMinutes} mins
              </span>
              <span className="text-zinc-400 text-[10px] block">
                ({data.focusHours} hrs)
              </span>
            </div>
            <div className="bg-white/5 p-2 rounded-xl border border-white/5">
              <span className="text-zinc-400 text-[10px] block">Daily Goal</span>
              <span className={`font-bold text-sm ${data.focusMinutes >= dailyTargetMinutes ? 'text-emerald-400' : 'text-amber-400'}`}>
                {data.focusMinutes >= dailyTargetMinutes ? '✓ Met' : `${Math.max(0, dailyTargetMinutes - data.focusMinutes)}m left`}
              </span>
              <span className="text-zinc-400 text-[10px] block">
                Target: {dailyTargetMinutes}m
              </span>
            </div>
          </div>

          {data.taskTitles.length > 0 ? (
            <div className="space-y-1 pt-0.5">
              <span className="text-[10px] font-mono uppercase tracking-wider text-zinc-400 block">
                Focus Sessions:
              </span>
              <ul className="space-y-1 max-h-24 overflow-y-auto no-scrollbar">
                {data.taskTitles.map((t, idx) => (
                  <li key={idx} className="text-[11px] text-zinc-200 flex items-start space-x-1.5">
                    <span className="text-[#FF5B5B]">•</span>
                    <span className="truncate">{t}</span>
                  </li>
                ))}
              </ul>
            </div>
          ) : (
            <p className="text-[11px] text-zinc-400 italic">No focus sessions logged on this day.</p>
          )}
        </div>
      );
    }
    return null;
  };

  return (
    <div
      id="weekly-focus-summary-widget"
      className="dark-card rounded-2xl sm:rounded-[32px] lg:rounded-[40px] p-5 sm:p-7 lg:p-8 shadow-2xl relative overflow-hidden space-y-4 sm:space-y-6"
    >
      {/* Header Section */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 sm:gap-4 border-b border-white/10 pb-3 sm:pb-4">
        <div className="space-y-0.5 sm:space-y-1">
          <div className="flex items-center space-x-2 flex-wrap gap-y-1">
            <span className="label text-[#FF5B5B] text-[10px] sm:text-xs">Focus Intelligence</span>
            <span className="inline-flex items-center space-x-1 bg-white/10 text-white/90 px-2 sm:px-2.5 py-0.5 rounded-full text-[10px] sm:text-[11px] font-mono font-bold">
              <Timer className="w-3 h-3 sm:w-3.5 sm:h-3.5 text-[#FF5B5B]" />
              <span>Current Week ({weekDateRangeLabel})</span>
            </span>
          </div>
          <h3 className="text-lg sm:text-2xl font-bold text-white tracking-tight flex items-center space-x-2">
            <span>Weekly Focus Session Summary</span>
          </h3>
        </div>

        {/* Action Controls & Toggles */}
        <div className="flex items-center space-x-2 flex-wrap gap-y-2">
          {/* Unit Toggle: Minutes vs Hours */}
          <div className="bg-white/10 p-0.5 sm:p-1 rounded-full flex items-center text-[11px] sm:text-xs font-mono">
            <button
              id="weekly-focus-toggle-mins"
              onClick={() => {
                triggerHaptic('light');
                setViewMode('minutes');
              }}
              className={`px-2.5 sm:px-3 py-1 rounded-full font-bold transition-all cursor-pointer ${
                viewMode === 'minutes'
                  ? 'bg-[#FF5B5B] text-white shadow-xs'
                  : 'text-white/60 hover:text-white'
              }`}
            >
              Mins
            </button>
            <button
              id="weekly-focus-toggle-hrs"
              onClick={() => {
                triggerHaptic('light');
                setViewMode('hours');
              }}
              className={`px-2.5 sm:px-3 py-1 rounded-full font-bold transition-all cursor-pointer ${
                viewMode === 'hours'
                  ? 'bg-[#FF5B5B] text-white shadow-xs'
                  : 'text-white/60 hover:text-white'
              }`}
            >
              Hours
            </button>
          </div>

          {/* Chart Style Toggle: Bar vs Area */}
          <div className="bg-white/10 p-0.5 sm:p-1 rounded-full flex items-center text-[11px] sm:text-xs font-mono">
            <button
              id="weekly-focus-chart-bar"
              onClick={() => {
                triggerHaptic('light');
                setChartStyle('bar');
              }}
              className={`p-1.5 rounded-full transition-all cursor-pointer ${
                chartStyle === 'bar' ? 'bg-white/20 text-white' : 'text-white/50 hover:text-white'
              }`}
              title="Bar Breakdown"
            >
              <BarChart2 className="w-3.5 h-3.5" />
            </button>
            <button
              id="weekly-focus-chart-area"
              onClick={() => {
                triggerHaptic('light');
                setChartStyle('area');
              }}
              className={`p-1.5 rounded-full transition-all cursor-pointer ${
                chartStyle === 'area' ? 'bg-white/20 text-white' : 'text-white/50 hover:text-white'
              }`}
              title="Area Curve"
            >
              <TrendingUp className="w-3.5 h-3.5" />
            </button>
          </div>

          {onViewTasksTab && (
            <button
              id="weekly-focus-view-tasks-btn"
              onClick={() => {
                triggerHaptic('light');
                onViewTasksTab();
              }}
              className="bg-white/10 hover:bg-white/20 text-white px-3 sm:px-3.5 py-1.5 rounded-full text-[11px] sm:text-xs font-mono font-bold uppercase transition-all cursor-pointer hidden md:inline-flex items-center space-x-1"
            >
              <span>Manage Tasks</span>
            </button>
          )}
        </div>
      </div>

      {/* KPI Highlight Strip */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5 sm:gap-4">
        {/* Total Focus Time */}
        <div className="bg-white/5 rounded-xl sm:rounded-2xl p-3.5 sm:p-4 border border-white/5 space-y-1 relative overflow-hidden">
          <span className="text-[9px] sm:text-[10px] font-mono uppercase tracking-wider text-zinc-400 block truncate">
            Total Focus This Week
          </span>
          <div className="text-xl sm:text-3xl font-bold font-mono text-white flex items-baseline space-x-1.5">
            <span className="text-[#FF5B5B]">{formatTotalTime(totalMinutesThisWeek)}</span>
          </div>
          <div className="text-[10px] sm:text-[11px] font-mono text-zinc-400 truncate">
            {totalMinutesThisWeek} total mins
          </div>
        </div>

        {/* Weekly Goal Progress */}
        <div className="bg-white/5 rounded-xl sm:rounded-2xl p-3.5 sm:p-4 border border-white/5 space-y-1.5">
          <div className="flex items-center justify-between text-[9px] sm:text-[10px] font-mono uppercase tracking-wider text-zinc-400">
            <span>Weekly Goal</span>
            <span className="text-emerald-400 font-bold">{weeklyProgressPercent}%</span>
          </div>
          <div className="text-base sm:text-2xl font-bold font-mono text-white truncate">
            {formatTotalTime(totalMinutesThisWeek)} <span className="text-[10px] sm:text-xs text-zinc-400 font-normal">/ {formatTotalTime(weeklyGoalMinutes)}</span>
          </div>
          <div className="progress-bar">
            <div
              className="progress-fill h-full"
              style={{ width: `${weeklyProgressPercent}%` }}
            ></div>
          </div>
        </div>

        {/* Daily Average */}
        <div className="bg-white/5 rounded-xl sm:rounded-2xl p-3.5 sm:p-4 border border-white/5 space-y-1">
          <span className="text-[9px] sm:text-[10px] font-mono uppercase tracking-wider text-zinc-400 block truncate">
            Daily Average
          </span>
          <div className="text-xl sm:text-3xl font-bold font-mono text-white flex items-baseline space-x-1">
            <span>{dailyAverageMinutes}</span>
            <span className="text-[11px] sm:text-xs font-sans text-emerald-400 font-normal">mins/day</span>
          </div>
          <div className="text-[10px] sm:text-[11px] font-mono text-zinc-400 truncate">
            {activeFocusDaysCount} of 7 days active
          </div>
        </div>

        {/* Top Life Area */}
        <div className="bg-white/5 rounded-xl sm:rounded-2xl p-3.5 sm:p-4 border border-white/5 space-y-1">
          <span className="text-[9px] sm:text-[10px] font-mono uppercase tracking-wider text-zinc-400 block truncate">
            Top Domain Focus
          </span>
          <div className="text-sm sm:text-lg font-bold text-white truncate flex items-center space-x-1.5">
            <span>{mostFocusedArea?.area.emoji || '🎯'}</span>
            <span className="truncate">{mostFocusedArea?.area.name || 'General'}</span>
          </div>
          <div className="text-[10px] sm:text-[11px] font-mono text-[#FF5B5B] truncate">
            {mostFocusedArea ? `${mostFocusedArea.minutes}m logged` : '0m logged'}
          </div>
        </div>
      </div>

      {/* Recharts Canvas Section */}
      <div className="space-y-2">
        <div className="flex items-center justify-between text-xs font-mono text-zinc-400 px-1">
          <span className="flex items-center space-x-1.5">
            <Target className="w-3.5 h-3.5 text-emerald-400" />
            <span>Target Line: {viewMode === 'minutes' ? `${dailyTargetMinutes}m / day` : `${(dailyTargetMinutes / 60).toFixed(1)}h / day`}</span>
          </span>
          <span>Click any bar for task details</span>
        </div>

        <div className="h-56 sm:h-64 w-full pt-1">
          <ResponsiveContainer width="100%" height="100%">
            {chartStyle === 'bar' ? (
              <BarChart data={weekDaysData} margin={{ top: 12, right: 12, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.07)" vertical={false} />
                <XAxis
                  dataKey="dayShort"
                  stroke="rgba(255,255,255,0.4)"
                  tick={{ fill: '#AFAFAF', fontSize: 11, fontFamily: 'monospace' }}
                  tickLine={false}
                  axisLine={false}
                />
                <YAxis
                  allowDecimals={viewMode === 'hours'}
                  stroke="rgba(255,255,255,0.4)"
                  tick={{ fill: '#AFAFAF', fontSize: 11, fontFamily: 'monospace' }}
                  tickLine={false}
                  axisLine={false}
                  domain={[0, 'dataMax + 10']}
                />
                <Tooltip content={<CustomFocusTooltip />} />
                <ReferenceLine
                  y={viewMode === 'minutes' ? dailyTargetMinutes : dailyTargetMinutes / 60}
                  stroke="#10B981"
                  strokeDasharray="4 4"
                  strokeOpacity={0.7}
                />
                <Bar
                  dataKey={viewMode === 'minutes' ? 'focusMinutes' : 'focusHours'}
                  radius={[8, 8, 0, 0]}
                  maxBarSize={48}
                >
                  {weekDaysData.map((entry, index) => (
                    <Cell
                      key={`cell-${index}`}
                      fill={
                        entry.isToday
                          ? '#FF5B5B'
                          : entry.focusMinutes >= dailyTargetMinutes
                          ? '#F59E0B'
                          : entry.focusMinutes > 0
                          ? '#E5E5E5'
                          : 'rgba(255,255,255,0.12)'
                      }
                    />
                  ))}
                </Bar>
              </BarChart>
            ) : (
              <AreaChart data={weekDaysData} margin={{ top: 12, right: 12, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="weeklyFocusGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#FF5B5B" stopOpacity={0.5} />
                    <stop offset="95%" stopColor="#FF5B5B" stopOpacity={0.0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.07)" vertical={false} />
                <XAxis
                  dataKey="dayShort"
                  stroke="rgba(255,255,255,0.4)"
                  tick={{ fill: '#AFAFAF', fontSize: 11, fontFamily: 'monospace' }}
                  tickLine={false}
                  axisLine={false}
                />
                <YAxis
                  allowDecimals={viewMode === 'hours'}
                  stroke="rgba(255,255,255,0.4)"
                  tick={{ fill: '#AFAFAF', fontSize: 11, fontFamily: 'monospace' }}
                  tickLine={false}
                  axisLine={false}
                />
                <Tooltip content={<CustomFocusTooltip />} />
                <ReferenceLine
                  y={viewMode === 'minutes' ? dailyTargetMinutes : dailyTargetMinutes / 60}
                  stroke="#10B981"
                  strokeDasharray="4 4"
                  strokeOpacity={0.7}
                />
                <Area
                  type="monotone"
                  dataKey={viewMode === 'minutes' ? 'focusMinutes' : 'focusHours'}
                  stroke="#FF5B5B"
                  strokeWidth={3}
                  fill="url(#weeklyFocusGradient)"
                  activeDot={{
                    r: 6,
                    fill: '#FF5B5B',
                    stroke: '#FFFFFF',
                    strokeWidth: 2,
                  }}
                />
              </AreaChart>
            )}
          </ResponsiveContainer>
        </div>
      </div>

      {/* Footer Legend & Action */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between text-xs font-mono text-zinc-400 pt-3 border-t border-white/10 gap-3">
        <div className="flex items-center space-x-3 flex-wrap gap-y-1">
          <span className="flex items-center space-x-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#FF5B5B]"></span>
            <span className="text-zinc-300">Today</span>
          </span>
          <span className="flex items-center space-x-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#F59E0B]"></span>
            <span className="text-zinc-300">Goal Reached</span>
          </span>
          <span className="flex items-center space-x-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#E5E5E5]"></span>
            <span className="text-zinc-300">Active</span>
          </span>
        </div>

        <div className="flex items-center space-x-2">
          {onStartFocus && (
            <button
              id="weekly-focus-start-sprint-btn"
              onClick={() => {
                triggerHaptic('success');
                const candidateTask = tasks.find((t) => t.status !== 'completed') || tasks[0];
                if (candidateTask) {
                  onStartFocus(candidateTask, 20);
                }
              }}
              className="flex items-center space-x-1.5 bg-[#FF5B5B] hover:bg-[#ff4242] text-white px-4 py-2 rounded-full font-mono text-xs font-bold uppercase tracking-wider transition-all cursor-pointer shadow-md hover:scale-105 active:scale-95"
            >
              <Play className="w-3.5 h-3.5 fill-current" />
              <span>Start 20m Focus Sprint</span>
            </button>
          )}
        </div>
      </div>
    </div>
  );
};
