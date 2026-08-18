import React, { useState, useMemo } from 'react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from 'recharts';
import { TaskItem } from '../types';
import { TrendingUp, CheckCircle2, Flame, Clock, Sparkles, BarChart2, LineChart as LineChartIcon } from 'lucide-react';
import { motion } from 'motion/react';
import { triggerHaptic } from '../utils/haptics';

interface ProductivityTrendChartProps {
  tasks: TaskItem[];
  onViewTasksTab?: () => void;
}

interface DayData {
  dateKey: string;
  dayLabel: string;
  shortWeekday: string;
  fullDate: string;
  isToday: boolean;
  completedCount: number;
  focusMinutes: number;
  taskTitles: string[];
}

export const ProductivityTrendChart: React.FC<ProductivityTrendChartProps> = ({
  tasks,
  onViewTasksTab,
}) => {
  const [chartType, setChartType] = useState<'area' | 'bar'>('area');
  const [metricType, setMetricType] = useState<'tasks' | 'minutes'>('tasks');

  // Compute 7-day trend data
  const { chartData, totalCompleted7Days, totalFocusMinutes7Days, streakDays, peakDay } = useMemo(() => {
    const days: DayData[] = [];
    const now = new Date();

    // Loop through past 7 days (day 6 down to 0)
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(now.getDate() - i);
      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      const dateKey = `${year}-${month}-${day}`;

      const shortWeekday = d.toLocaleDateString('en-US', { weekday: 'short' });
      const dayNum = d.getDate();
      const dayLabel = `${shortWeekday} ${dayNum}`;
      const fullDate = d.toLocaleDateString('en-US', {
        weekday: 'short',
        month: 'short',
        day: 'numeric',
      });
      const isToday = i === 0;

      // Find tasks completed on this date
      const matchingTasks = tasks.filter((t) => {
        if (t.status !== 'completed') return false;
        if (t.completedAt) {
          const compDate = t.completedAt.split('T')[0];
          return compDate === dateKey;
        }
        if (t.dueDate === dateKey) return true;
        return false;
      });

      const completedCount = matchingTasks.length;
      const focusMinutes = matchingTasks.reduce(
        (acc, curr) => acc + (curr.focusMinutesLogged || curr.focusMinutesTarget || 15),
        0
      );
      const taskTitles = matchingTasks.map((t) => t.title);

      days.push({
        dateKey,
        dayLabel: isToday ? 'Today' : shortWeekday,
        shortWeekday,
        fullDate: isToday ? `Today (${fullDate})` : fullDate,
        isToday,
        completedCount,
        focusMinutes,
        taskTitles,
      });
    }

    const totalCompleted = days.reduce((sum, d) => sum + d.completedCount, 0);
    const totalMins = days.reduce((sum, d) => sum + d.focusMinutes, 0);

    // Active days count
    const activeDays = days.filter((d) => d.completedCount > 0).length;

    // Peak day
    let maxDay = days[0];
    for (const d of days) {
      if (d.completedCount > maxDay.completedCount) {
        maxDay = d;
      }
    }

    return {
      chartData: days,
      totalCompleted7Days: totalCompleted,
      totalFocusMinutes7Days: totalMins,
      streakDays: activeDays,
      peakDay: maxDay.completedCount > 0 ? maxDay : null,
    };
  }, [tasks]);

  // Custom tooltip
  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const data: DayData = payload[0].payload;
      return (
        <div className="bg-[#1C1C1A] text-white p-3.5 rounded-2xl shadow-2xl border border-white/15 max-w-xs font-sans text-xs space-y-2 z-50">
          <div className="flex items-center justify-between border-b border-white/10 pb-1.5">
            <span className="font-bold text-white font-mono text-xs">{data.fullDate}</span>
            {data.isToday && (
              <span className="bg-[#FF5B5B] text-white text-[9px] px-1.5 py-0.5 rounded-full font-mono uppercase font-bold">
                Today
              </span>
            )}
          </div>

          <div className="grid grid-cols-2 gap-2 text-xs font-mono">
            <div className="bg-white/5 p-2 rounded-xl border border-white/5">
              <span className="text-zinc-400 text-[10px] block">Completed</span>
              <span className="text-[#FF5B5B] font-bold text-sm">
                {data.completedCount} {data.completedCount === 1 ? 'task' : 'tasks'}
              </span>
            </div>
            <div className="bg-white/5 p-2 rounded-xl border border-white/5">
              <span className="text-zinc-400 text-[10px] block">Focus Logged</span>
              <span className="text-emerald-400 font-bold text-sm">
                {data.focusMinutes}m
              </span>
            </div>
          </div>

          {data.taskTitles.length > 0 ? (
            <div className="space-y-1 pt-1">
              <span className="text-[10px] font-mono uppercase tracking-wider text-zinc-400 block">
                Accomplishments:
              </span>
              <ul className="space-y-1 max-h-24 overflow-y-auto no-scrollbar">
                {data.taskTitles.slice(0, 3).map((title, i) => (
                  <li key={i} className="flex items-start space-x-1.5 text-zinc-200 text-[11px] leading-tight">
                    <CheckCircle2 className="w-3 h-3 text-[#FF5B5B] shrink-0 mt-0.5" />
                    <span className="truncate">{title}</span>
                  </li>
                ))}
                {data.taskTitles.length > 3 && (
                  <li className="text-[10px] text-zinc-400 font-mono">
                    +{data.taskTitles.length - 3} more tasks
                  </li>
                )}
              </ul>
            </div>
          ) : (
            <p className="text-[11px] text-zinc-400 italic">No tasks completed on this day.</p>
          )}
        </div>
      );
    }
    return null;
  };

  return (
    <div
      id="productivity-trend-card"
      className="dark-card rounded-2xl sm:rounded-[32px] lg:rounded-[40px] p-5 sm:p-7 lg:p-8 shadow-2xl relative overflow-hidden space-y-4 sm:space-y-5"
    >
      {/* Top Header & Metrics */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 sm:gap-4 border-b border-white/10 pb-3 sm:pb-4">
        <div>
          <div className="flex items-center space-x-2">
            <span className="label text-[#FF5B5B] text-[10px] sm:text-xs">Velocity & Momentum</span>
            <span className="inline-flex items-center space-x-1 bg-white/10 text-white/80 px-2 py-0.5 rounded-full text-[10px] font-mono font-bold">
              <Flame className="w-3 h-3 text-[#FF5B5B]" />
              <span>{streakDays}/7 Days Active</span>
            </span>
          </div>
          <h3 className="text-lg sm:text-2xl font-bold text-white tracking-tight mt-0.5 sm:mt-1 flex items-center space-x-2">
            <TrendingUp className="w-4 h-4 sm:w-5 sm:h-5 text-[#FF5B5B]" />
            <span>7-Day Productivity Trend</span>
          </h3>
        </div>

        {/* Metric & Chart Type Switchers */}
        <div className="flex items-center space-x-2 flex-wrap gap-y-2">
          {/* Toggle Tasks vs Minutes */}
          <div className="bg-white/10 p-0.5 sm:p-1 rounded-full flex items-center text-[11px] sm:text-xs font-mono">
            <button
              onClick={() => {
                triggerHaptic('light');
                setMetricType('tasks');
              }}
              className={`px-2.5 sm:px-3 py-1 rounded-full font-bold transition-all cursor-pointer ${
                metricType === 'tasks'
                  ? 'bg-[#FF5B5B] text-white shadow-xs'
                  : 'text-white/60 hover:text-white'
              }`}
            >
              Tasks
            </button>
            <button
              onClick={() => {
                triggerHaptic('light');
                setMetricType('minutes');
              }}
              className={`px-2.5 sm:px-3 py-1 rounded-full font-bold transition-all cursor-pointer ${
                metricType === 'minutes'
                  ? 'bg-[#FF5B5B] text-white shadow-xs'
                  : 'text-white/60 hover:text-white'
              }`}
            >
              Focus Mins
            </button>
          </div>

          {/* Toggle Area vs Bar */}
          <div className="bg-white/10 p-0.5 sm:p-1 rounded-full flex items-center text-[11px] sm:text-xs font-mono">
            <button
              onClick={() => {
                triggerHaptic('light');
                setChartType('area');
              }}
              className={`p-1.5 rounded-full transition-all cursor-pointer ${
                chartType === 'area' ? 'bg-white/20 text-white' : 'text-white/50 hover:text-white'
              }`}
              title="Area Curve"
            >
              <LineChartIcon className="w-3.5 h-3.5" />
            </button>
            <button
              onClick={() => {
                triggerHaptic('light');
                setChartType('bar');
              }}
              className={`p-1.5 rounded-full transition-all cursor-pointer ${
                chartType === 'bar' ? 'bg-white/20 text-white' : 'text-white/50 hover:text-white'
              }`}
              title="Bar Chart"
            >
              <BarChart2 className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>

      {/* KPI Stats Strip */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5 sm:gap-3 pt-1">
        <div className="bg-white/5 rounded-xl sm:rounded-2xl p-3 sm:p-3.5 border border-white/5 space-y-0.5">
          <span className="text-[9px] sm:text-[10px] font-mono uppercase tracking-wider text-zinc-400 block truncate">
            7-Day Completed
          </span>
          <div className="text-xl sm:text-2xl font-bold font-mono text-white flex items-baseline space-x-1">
            <span>{totalCompleted7Days}</span>
            <span className="text-[11px] sm:text-xs font-sans text-[#FF5B5B] font-normal">tasks</span>
          </div>
        </div>

        <div className="bg-white/5 rounded-xl sm:rounded-2xl p-3 sm:p-3.5 border border-white/5 space-y-0.5">
          <span className="text-[9px] sm:text-[10px] font-mono uppercase tracking-wider text-zinc-400 block truncate">
            Daily Average
          </span>
          <div className="text-xl sm:text-2xl font-bold font-mono text-white flex items-baseline space-x-1">
            <span>{(totalCompleted7Days / 7).toFixed(1)}</span>
            <span className="text-[11px] sm:text-xs font-sans text-zinc-400 font-normal">/ day</span>
          </div>
        </div>

        <div className="bg-white/5 rounded-xl sm:rounded-2xl p-3 sm:p-3.5 border border-white/5 space-y-0.5">
          <span className="text-[9px] sm:text-[10px] font-mono uppercase tracking-wider text-zinc-400 block truncate">
            Sprint Time
          </span>
          <div className="text-xl sm:text-2xl font-bold font-mono text-white flex items-baseline space-x-1">
            <span>{totalFocusMinutes7Days}</span>
            <span className="text-[11px] sm:text-xs font-sans text-emerald-400 font-normal">mins</span>
          </div>
        </div>

        <div className="bg-white/5 rounded-xl sm:rounded-2xl p-3 sm:p-3.5 border border-white/5 space-y-0.5">
          <span className="text-[9px] sm:text-[10px] font-mono uppercase tracking-wider text-zinc-400 block truncate">
            Peak Day
          </span>
          <div className="text-sm sm:text-lg font-bold font-mono text-white truncate">
            {peakDay ? `${peakDay.shortWeekday} (${peakDay.completedCount})` : 'None yet'}
          </div>
        </div>
      </div>

      {/* Recharts Canvas */}
      <div className="h-52 sm:h-56 w-full pt-2">
        <ResponsiveContainer width="100%" height="100%">
          {chartType === 'area' ? (
            <AreaChart data={chartData} margin={{ top: 10, right: 10, left: -24, bottom: 0 }}>
              <defs>
                <linearGradient id="productivityGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#FF5B5B" stopOpacity={0.45} />
                  <stop offset="95%" stopColor="#FF5B5B" stopOpacity={0.0} />
                </linearGradient>
                <linearGradient id="minutesGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#10B981" stopOpacity={0.4} />
                  <stop offset="95%" stopColor="#10B981" stopOpacity={0.0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.07)" vertical={false} />
              <XAxis
                dataKey="dayLabel"
                stroke="rgba(255,255,255,0.4)"
                tick={{ fill: '#AFAFAF', fontSize: 11, fontFamily: 'monospace' }}
                tickLine={false}
                axisLine={false}
              />
              <YAxis
                allowDecimals={false}
                stroke="rgba(255,255,255,0.4)"
                tick={{ fill: '#AFAFAF', fontSize: 11, fontFamily: 'monospace' }}
                tickLine={false}
                axisLine={false}
                domain={[0, 'dataMax + 1']}
              />
              <Tooltip content={<CustomTooltip />} />
              <Area
                type="monotone"
                dataKey={metricType === 'tasks' ? 'completedCount' : 'focusMinutes'}
                stroke={metricType === 'tasks' ? '#FF5B5B' : '#10B981'}
                strokeWidth={3}
                fill={metricType === 'tasks' ? 'url(#productivityGradient)' : 'url(#minutesGradient)'}
                activeDot={{
                  r: 6,
                  fill: metricType === 'tasks' ? '#FF5B5B' : '#10B981',
                  stroke: '#FFFFFF',
                  strokeWidth: 2,
                }}
              />
            </AreaChart>
          ) : (
            <BarChart data={chartData} margin={{ top: 10, right: 10, left: -24, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.07)" vertical={false} />
              <XAxis
                dataKey="dayLabel"
                stroke="rgba(255,255,255,0.4)"
                tick={{ fill: '#AFAFAF', fontSize: 11, fontFamily: 'monospace' }}
                tickLine={false}
                axisLine={false}
              />
              <YAxis
                allowDecimals={false}
                stroke="rgba(255,255,255,0.4)"
                tick={{ fill: '#AFAFAF', fontSize: 11, fontFamily: 'monospace' }}
                tickLine={false}
                axisLine={false}
                domain={[0, 'dataMax + 1']}
              />
              <Tooltip content={<CustomTooltip />} />
              <Bar
                dataKey={metricType === 'tasks' ? 'completedCount' : 'focusMinutes'}
                fill={metricType === 'tasks' ? '#FF5B5B' : '#10B981'}
                radius={[8, 8, 0, 0]}
              />
            </BarChart>
          )}
        </ResponsiveContainer>
      </div>

      {/* Footer Encouragement Note */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between text-xs font-mono text-zinc-400 pt-2 border-t border-white/10 gap-2">
        <div className="flex items-center space-x-1.5">
          <Sparkles className="w-3.5 h-3.5 text-[#FF5B5B]" />
          <span>ADHD Positive Reinforcement: Micro-steps compound into weekly streaks.</span>
        </div>
        {onViewTasksTab && (
          <button
            onClick={() => {
              triggerHaptic('light');
              onViewTasksTab();
            }}
            className="text-white hover:text-[#FF5B5B] underline cursor-pointer shrink-0 font-bold"
          >
            Review Task History →
          </button>
        )}
      </div>
    </div>
  );
};
