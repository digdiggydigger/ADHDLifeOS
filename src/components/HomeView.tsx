import React, { useState } from 'react';
import {
  LifeArea,
  TaskItem,
  NudgeItem,
  CaptureItem,
  ActiveTab,
} from '../types';
import {
  ArrowUpDown,
  ChevronUp,
  ChevronDown,
  Play,
  ArrowRight,
  Plus,
  CheckCircle2,
  Check,
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
  onStartFocus: (task: TaskItem, durationMinutes?: number) => void;
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

  return (
    <div className="space-y-10 pb-28">
      {/* 1. Main Bento Grid matching Design Variation */}
      <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5 sm:gap-6">
        {/* Card 1: Active Goal (Dark Card, Spans 2 cols & 2 rows on desktop) */}
        <div
          id="active-goal-card"
          className="dark-card rounded-[36px] sm:rounded-[40px] p-7 sm:p-10 lg:col-span-2 lg:row-span-2 flex flex-col justify-between shadow-2xl relative overflow-hidden group min-h-[380px]"
        >
          <div>
            <div className="flex items-center justify-between">
              <span className="label text-[#FF5B5B]">
                Active Goal {topTaskArea ? `• ${topTaskArea.name}` : ''}
              </span>
              <span className="text-[10px] font-mono uppercase font-bold text-white/70 bg-white/10 px-2.5 py-0.5 rounded-full">
                {topTask.priority} priority
              </span>
            </div>

            <h2 className="text-2xl sm:text-3xl lg:text-[2.2rem] font-light leading-[1.15] mt-4 mb-3 text-white tracking-tight">
              {topTask.title}
            </h2>

            {topTask.description && (
              <p className="text-sm text-zinc-400 font-sans line-clamp-2 mb-4">
                {topTask.description}
              </p>
            )}
          </div>

          <div className="space-y-6 pt-4">
            <div className="space-y-2">
              <div className="flex justify-between text-xs font-mono text-zinc-400">
                <span>Task Focus Target</span>
                <span className="text-[#FF5B5B] font-bold">
                  {topTask.focusMinutesTarget || 15}m sprint
                </span>
              </div>
              <div className="progress-bar">
                <div
                  className="progress-fill h-full"
                  style={{ width: `${Math.max(25, completionPercent)}%` }}
                ></div>
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-3">
              <button
                id="start-session-btn"
                onClick={() => onStartFocus(topTask, topTask.focusMinutesTarget || 15)}
                className="bg-[#FF5B5B] hover:bg-[#ff4242] text-white py-3.5 sm:py-4 px-8 sm:px-10 rounded-full font-bold font-mono text-xs sm:text-sm tracking-wider uppercase shadow-lg transition-all cursor-pointer hover:scale-105 active:scale-95 flex items-center space-x-2.5"
              >
                <Play className="w-4 h-4 fill-current" />
                <span>START SESSION</span>
              </button>

              <button
                id="manage-active-task-btn"
                onClick={() => {
                  onSelectLifeArea(topTask.lifeAreaId);
                }}
                className="bg-white/10 hover:bg-white/20 text-white py-3.5 px-6 rounded-full font-mono text-xs uppercase font-bold transition-all cursor-pointer"
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
          className="light-card rounded-[36px] sm:rounded-[40px] p-7 sm:p-8 flex flex-col justify-between shadow-xs hover:border-black/20 transition-all cursor-pointer group min-h-[190px]"
        >
          <div className="flex items-center justify-between">
            <span className="label text-[#1C1C1A]/70 group-hover:text-[#1C1C1A]">Inbox Triage</span>
            <ArrowRight className="w-4 h-4 text-[#1C1C1A]/40 group-hover:text-[#1C1C1A] transition-transform group-hover:translate-x-1" />
          </div>

          <div>
            <div className="text-5xl sm:text-6xl font-bold tracking-tight text-[#1C1C1A] leading-none mb-1 font-mono">
              {unprocessedCaptures.length}
            </div>
            <p className="text-xs text-[#1C1C1A]/60 font-medium">Unprocessed items.</p>
          </div>
        </div>

        {/* Card 3: Health & Progress (Light Card, Span 1) */}
        <div
          id="health-progress-card"
          onClick={() => setActiveTab('tasks')}
          className="light-card rounded-[36px] sm:rounded-[40px] p-7 sm:p-8 flex flex-col justify-between shadow-xs hover:border-black/20 transition-all cursor-pointer group min-h-[190px]"
        >
          <div className="flex items-center justify-between">
            <span className="label text-[#1C1C1A]/70">Health</span>
            <span className="text-[10px] font-mono text-[#1C1C1A]/50 uppercase">{completedTasks.length} done</span>
          </div>

          <div className="flex items-center space-x-4">
            <div className="progress-circle w-20 h-20 text-xl font-mono text-[#1C1C1A] shrink-0">
              {completionPercent}%
            </div>
            <div className="text-xs text-[#1C1C1A]/70 font-mono leading-tight">
              <span className="font-bold text-[#1C1C1A] block">{openTasks.length} pending</span>
              <span>Daily stack</span>
            </div>
          </div>
        </div>

        {/* Card 4: Journal (Dark Card, Span 1) */}
        <div
          id="journal-preview-card"
          onClick={() => setActiveTab('journal')}
          className="dark-card rounded-[36px] sm:rounded-[40px] p-7 sm:p-8 flex flex-col justify-between shadow-lg hover:border-white/20 transition-all cursor-pointer group min-h-[190px]"
        >
          <div className="flex items-center justify-between">
            <span className="label text-white/50 group-hover:text-white">Journal</span>
            <ArrowRight className="w-4 h-4 text-white/30 group-hover:text-white transition-transform group-hover:translate-x-1" />
          </div>

          <div>
            <p className="font-medium text-base sm:text-lg leading-snug text-white">
              Ready to log<br />the day.
            </p>
            <span className="text-[11px] font-mono text-zinc-400 mt-2 block">
              Dopamine & energy check
            </span>
          </div>
        </div>

        {/* Card 5: Nudges (Dark Card, Span 1) */}
        <div
          id="nudges-preview-card"
          onClick={() => setActiveTab('nudges')}
          className="dark-card rounded-[36px] sm:rounded-[40px] p-7 sm:p-8 flex flex-col justify-between shadow-lg hover:border-[#FF5B5B]/50 transition-all cursor-pointer group min-h-[190px]"
        >
          <div className="flex items-center justify-between">
            <span className="label text-[#FF5B5B]">Nudges</span>
            {dueNudges.length > 0 && (
              <span className="w-2.5 h-2.5 rounded-full bg-[#FF5B5B] animate-pulse"></span>
            )}
          </div>

          <div>
            <h3 className="text-base sm:text-lg font-light leading-snug text-white">
              {topDueNudge ? topDueNudge.label : 'Hydration & Posture Reset'}
            </h3>
            <span className="text-[11px] font-mono text-zinc-400 mt-1 block">
              {topDueNudge ? topDueNudge.schedule : 'Every 2 hours'}
            </span>
          </div>
        </div>
      </section>

      {/* 2. Life Areas Channels Section */}
      <section className="space-y-5">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-black/5 pb-3">
          <div>
            <span className="label text-[#FF5B5B]">Domain Alignment</span>
            <h3 className="text-xl sm:text-2xl font-bold text-[#1C1C1A] tracking-tight">Life Areas</h3>
          </div>

          <div className="flex items-center space-x-3">
            {activeAreas.length >= 2 && (
              <button
                id="home-arrange-button"
                onClick={() => setIsArranging(!isArranging)}
                className={`flex items-center space-x-1.5 px-4 py-1.5 rounded-full text-xs font-mono font-bold uppercase transition-all cursor-pointer border ${
                  isArranging
                    ? 'bg-emerald-600 hover:bg-emerald-700 text-white border-emerald-600 shadow-sm hover:scale-105 active:scale-95'
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
              className="text-xs font-mono text-[#1C1C1A] font-bold hover:underline flex items-center space-x-1 cursor-pointer"
            >
              <span>View All Tasks</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

        {/* Arrange Mode */}
        {isArranging ? (
          <div id="home-reorder-container" className="bg-[#EFECE8] rounded-3xl border border-black/5 divide-y divide-black/5 overflow-hidden">
            <div className="p-3 bg-black/5 text-xs font-mono text-[#1C1C1A]/60">
              Reorder Life Areas
            </div>
            {activeAreas.map((area, idx) => (
              <div
                key={area.id}
                className="p-4 flex items-center justify-between hover:bg-white/40 transition-colors"
              >
                <div className="flex items-center space-x-3">
                  <span className="text-2xl">{area.emoji}</span>
                  <span className="font-bold text-[#1C1C1A] text-sm">{area.name}</span>
                </div>
                <div className="flex items-center space-x-1.5">
                  <button
                    disabled={idx === 0}
                    onClick={() => moveArea(idx, 'up')}
                    className="p-2 rounded-full border border-black/10 hover:bg-black/5 disabled:opacity-25 cursor-pointer"
                    title="Move Up"
                  >
                    <ChevronUp className="w-4 h-4 text-[#1C1C1A]" />
                  </button>
                  <button
                    disabled={idx === activeAreas.length - 1}
                    onClick={() => moveArea(idx, 'down')}
                    className="p-2 rounded-full border border-black/10 hover:bg-black/5 disabled:opacity-25 cursor-pointer"
                    title="Move Down"
                  >
                    <ChevronDown className="w-4 h-4 text-[#1C1C1A]" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        ) : (
          /* Standard Life Areas Cards */
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {activeAreas.map((area) => {
              const areaTasks = tasks.filter((t) => t.lifeAreaId === area.id && t.status !== 'completed');
              const completedAreaTasks = tasks.filter((t) => t.lifeAreaId === area.id && t.status === 'completed');

              return (
                <div
                  key={area.id}
                  id={`life-area-card-${area.id}`}
                  onClick={() => onSelectLifeArea(area.id)}
                  className="light-card rounded-3xl p-5 hover:border-black/20 shadow-xs transition-all cursor-pointer flex flex-col justify-between group space-y-4"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex items-center space-x-3">
                      <span className="text-2xl p-2 rounded-2xl bg-white/80 border border-black/5">
                        {area.emoji}
                      </span>
                      <div>
                        <h4 className="text-base font-bold text-[#1C1C1A] leading-tight">{area.name}</h4>
                        <span className="text-[11px] font-mono text-[#1C1C1A]/50 uppercase">
                          {areaTasks.length} pending • {completedAreaTasks.length} done
                        </span>
                      </div>
                    </div>
                    <span className="text-xs font-mono font-bold text-[#FF5B5B] px-2.5 py-0.5 rounded-full bg-[#FF5B5B]/10">
                      {areaTasks.length} OPEN
                    </span>
                  </div>

                  {/* Micro-preview of next task */}
                  {areaTasks[0] ? (
                    <div className="bg-white/90 border border-black/5 p-3 rounded-2xl space-y-1">
                      <div className="flex items-center justify-between">
                        <span className="text-xs font-semibold text-[#1C1C1A] truncate max-w-[180px]">
                          {areaTasks[0].title}
                        </span>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            onStartFocus(areaTasks[0]);
                          }}
                          className="p-1 rounded-full bg-[#FF5B5B] hover:bg-[#ff4242] text-white transition-colors cursor-pointer"
                          title="Start focus"
                        >
                          <Play className="w-3 h-3 fill-current" />
                        </button>
                      </div>
                      {areaTasks[0].dueDate && (
                        <span className="text-[10px] text-zinc-500 font-mono block">
                          Due: {areaTasks[0].dueDate}
                        </span>
                      )}
                    </div>
                  ) : (
                    <div className="bg-black/5 p-3 rounded-2xl text-center">
                      <span className="text-xs text-[#1C1C1A]/50 font-mono">All clear in {area.name}</span>
                    </div>
                  )}

                  <div className="text-left text-xs font-mono text-[#1C1C1A]/60 group-hover:text-[#1C1C1A] transition-colors flex items-center justify-between pt-1 border-t border-black/5">
                    <span>Open {area.name} Tasks</span>
                    <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
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
