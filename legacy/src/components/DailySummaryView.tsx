import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import {
  Sparkles,
  CheckCircle2,
  Calendar,
  RefreshCw,
  Copy,
  Check,
  BookOpen,
  Zap,
  Flame,
  Brain,
  ArrowRight,
  Sun,
  Smile,
  Clock,
  Share2,
  ListTodo,
  Inbox,
  AlertCircle,
  TrendingUp,
} from 'lucide-react';
import { TaskItem, JournalEntry, CaptureItem, LifeArea, DailySummaryData } from '../types';
import { triggerHaptic } from '../utils/haptics';

interface DailySummaryViewProps {
  tasks: TaskItem[];
  journal: JournalEntry[];
  captures: CaptureItem[];
  lifeAreas: LifeArea[];
  onOpenQuickCapture?: () => void;
  onNavigateToTasks?: () => void;
}

type SummaryTone = 'energizing' | 'gentle' | 'coaching' | 'bulleted';

export function DailySummaryView({
  tasks,
  journal,
  captures,
  lifeAreas,
  onOpenQuickCapture,
  onNavigateToTasks,
}: DailySummaryViewProps) {
  const [selectedDate, setSelectedDate] = useState<string>(
    new Date().toISOString().split('T')[0]
  );
  const [tone, setTone] = useState<SummaryTone>('energizing');
  const [isLoading, setIsLoading] = useState(false);
  const [isCopied, setIsCopied] = useState(false);
  const [summaryData, setSummaryData] = useState<DailySummaryData | null>(null);
  const [viewMode, setViewMode] = useState<'cards' | 'markdown'>('cards');
  const [errorNotice, setErrorNotice] = useState<string | null>(null);

  // Load cached summary for selected date from localStorage
  useEffect(() => {
    try {
      const storageKey = `adhd_lifeos_daily_summary_${selectedDate}`;
      const cached = localStorage.getItem(storageKey);
      if (cached) {
        setSummaryData(JSON.parse(cached));
      } else {
        setSummaryData(null);
      }
    } catch {
      setSummaryData(null);
    }
  }, [selectedDate]);

  // Filter tasks, journals, captures for the selected date
  const completedTasksToday = tasks.filter((t) => {
    if (t.status !== 'completed') return false;
    const completedDate = t.completedAt
      ? t.completedAt.split('T')[0]
      : t.createdAt.split('T')[0];
    return completedDate === selectedDate;
  });

  const inProgressTasks = tasks.filter((t) => t.status !== 'completed');

  const journalEntriesToday = journal.filter((j) => {
    const entryDate = j.createdAt.split('T')[0];
    return entryDate === selectedDate;
  });

  const capturesToday = captures.filter((c) => {
    const capDate = c.createdAt.split('T')[0];
    return capDate === selectedDate;
  });

  // Calculate total focus minutes
  const totalFocusMinutesToday = completedTasksToday.reduce((acc, task) => {
    return acc + (task.focusMinutesLogged || task.focusMinutesTarget || 0);
  }, 0);

  // Helper to get life area name
  const getAreaName = (areaId?: string) => {
    const area = lifeAreas.find((a) => a.id === areaId);
    return area ? `${area.emoji} ${area.name}` : 'General';
  };

  // Generate Daily Summary via Gemini API backend
  const handleGenerateSummary = async () => {
    triggerHaptic('medium');
    setIsLoading(true);
    setErrorNotice(null);

    const payload = {
      date: selectedDate,
      tone,
      focusMinutesTotal: totalFocusMinutesToday,
      capturesCount: capturesToday.length,
      completedTasks: completedTasksToday.map((t) => ({
        id: t.id,
        title: t.title,
        description: t.description,
        lifeAreaName: getAreaName(t.lifeAreaId),
        priority: t.priority,
        focusMinutesLogged: t.focusMinutesLogged || t.focusMinutesTarget || 0,
        nudgesCount: t.nudgesCount || 0,
        completedAt: t.completedAt || t.createdAt,
      })),
      inProgressTasks: inProgressTasks.slice(0, 5).map((t) => ({
        id: t.id,
        title: t.title,
        lifeAreaName: getAreaName(t.lifeAreaId),
      })),
      journalEntries: journalEntriesToday.map((j) => ({
        id: j.id,
        title: j.title,
        content: j.content,
        lifeAreaName: getAreaName(j.lifeAreaId),
        energyLevel: j.energyLevel,
        moodEmoji: j.moodEmoji,
        createdAt: j.createdAt,
      })),
    };

    try {
      const response = await fetch('/api/gemini/daily-summary', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        throw new Error(`Server responded with HTTP ${response.status}`);
      }

      const data = await response.json();
      if (data.success && data.summary) {
        const fullData: DailySummaryData = {
          ...data.summary,
          date: selectedDate,
          tone,
          source: data.source,
          generatedAt: new Date().toISOString(),
        };
        setSummaryData(fullData);
        localStorage.setItem(
          `adhd_lifeos_daily_summary_${selectedDate}`,
          JSON.stringify(fullData)
        );
        triggerHaptic('success');
      } else {
        throw new Error('Could not parse summary data.');
      }
    } catch (err: any) {
      console.error('Failed to generate summary:', err);
      setErrorNotice(
        err.message || 'Failed to reach Gemini API. Please retry.'
      );
      triggerHaptic('heavy');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCopySummary = () => {
    if (!summaryData) return;
    triggerHaptic('light');

    const copyText = `✨ ADHD LifeOS Daily Summary (${summaryData.date})
${summaryData.headline}

🏆 Dopamine Wins:
${summaryData.dopamineWins.map((w) => `• ${w}`).join('\n')}

💭 Reflections:
${summaryData.journalReflections}

⚡ Focus & Stamina:
${summaryData.focusStaminaInsight}

🚀 Tomorrow's Kickstart:
${summaryData.gentleTomorrowKickstart.map((k) => `• ${k}`).join('\n')}
`;

    navigator.clipboard.writeText(copyText).then(() => {
      setIsCopied(true);
      setTimeout(() => setIsCopied(false), 2500);
    });
  };

  return (
    <div className="space-y-6 pb-24 max-w-5xl mx-auto">
      {/* Top Banner & Date / Tone Toolbar */}
      <div className="light-card rounded-[32px] p-6 sm:p-8 space-y-6">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="space-y-1.5">
            <div className="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-[#FF5B5B]/10 text-[#FF5B5B] text-xs font-mono font-bold">
              <Sparkles className="w-3.5 h-3.5" />
              <span>Gemini 3.7 Flash AI Highlights</span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-black text-[#1C1C1A] tracking-tight">
              Daily Executive Summary
            </h1>
            <p className="text-xs sm:text-sm text-[#1C1C1A]/60 max-w-xl">
              Synthesize completed milestones, emotional journal reflections, and focus stamina into compassionate, dopamine-fueling highlights.
            </p>
          </div>

          {/* Date Selector & Generate Action */}
          <div className="flex flex-wrap items-center gap-3">
            <div className="inline-flex items-center space-x-2 bg-[#F2EFE9] px-3.5 py-2 rounded-2xl border border-black/5">
              <Calendar className="w-4 h-4 text-[#1C1C1A]/60" />
              <input
                id="summary-date-picker"
                type="date"
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                className="bg-transparent text-xs font-mono font-bold text-[#1C1C1A] outline-none cursor-pointer"
              />
            </div>

            <button
              id="generate-daily-summary-btn"
              onClick={handleGenerateSummary}
              disabled={isLoading}
              className="inline-flex items-center space-x-2 px-5 py-2.5 rounded-2xl bg-[#FF5B5B] hover:bg-[#ff4242] active:scale-95 text-white font-bold text-xs sm:text-sm shadow-md transition-all cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? (
                <>
                  <RefreshCw className="w-4 h-4 animate-spin" />
                  <span>Synthesizing Day...</span>
                </>
              ) : (
                <>
                  <Sparkles className="w-4 h-4" />
                  <span>{summaryData ? 'Regenerate Summary' : 'Generate Summary'}</span>
                </>
              )}
            </button>
          </div>
        </div>

        {/* Tone Selector Pills */}
        <div className="pt-4 border-t border-black/5 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="flex items-center space-x-2">
            <span className="text-xs font-mono text-[#1C1C1A]/60">Tone:</span>
            <div className="inline-flex p-1 bg-[#F2EFE9] rounded-xl border border-black/5 gap-1 flex-wrap">
              <button
                type="button"
                onClick={() => {
                  triggerHaptic('light');
                  setTone('energizing');
                }}
                className={`px-3 py-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  tone === 'energizing'
                    ? 'bg-white text-[#1C1C1A] shadow-2xs'
                    : 'text-[#1C1C1A]/60 hover:text-[#1C1C1A]'
                }`}
              >
                ⚡ Energizing
              </button>
              <button
                type="button"
                onClick={() => {
                  triggerHaptic('light');
                  setTone('gentle');
                }}
                className={`px-3 py-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  tone === 'gentle'
                    ? 'bg-white text-[#1C1C1A] shadow-2xs'
                    : 'text-[#1C1C1A]/60 hover:text-[#1C1C1A]'
                }`}
              >
                🌿 Gentle
              </button>
              <button
                type="button"
                onClick={() => {
                  triggerHaptic('light');
                  setTone('coaching');
                }}
                className={`px-3 py-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  tone === 'coaching'
                    ? 'bg-white text-[#1C1C1A] shadow-2xs'
                    : 'text-[#1C1C1A]/60 hover:text-[#1C1C1A]'
                }`}
              >
                🎯 Coaching
              </button>
              <button
                type="button"
                onClick={() => {
                  triggerHaptic('light');
                  setTone('bulleted');
                }}
                className={`px-3 py-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  tone === 'bulleted'
                    ? 'bg-white text-[#1C1C1A] shadow-2xs'
                    : 'text-[#1C1C1A]/60 hover:text-[#1C1C1A]'
                }`}
              >
                📋 Bulleted
              </button>
            </div>
          </div>

          {/* Quick Date Shortcuts */}
          <div className="flex items-center space-x-2">
            <button
              type="button"
              onClick={() => {
                triggerHaptic('light');
                setSelectedDate(new Date().toISOString().split('T')[0]);
              }}
              className="text-xs font-mono text-[#1C1C1A]/60 hover:text-[#FF5B5B] px-2.5 py-1 rounded-lg hover:bg-black/5 transition-colors cursor-pointer"
            >
              Today
            </button>
            <button
              type="button"
              onClick={() => {
                triggerHaptic('light');
                const d = new Date();
                d.setDate(d.getDate() - 1);
                setSelectedDate(d.toISOString().split('T')[0]);
              }}
              className="text-xs font-mono text-[#1C1C1A]/60 hover:text-[#FF5B5B] px-2.5 py-1 rounded-lg hover:bg-black/5 transition-colors cursor-pointer"
            >
              Yesterday
            </button>
          </div>
        </div>
      </div>

      {/* Error / Notice Display */}
      {errorNotice && (
        <div className="p-4 rounded-2xl bg-amber-50 border border-amber-200/80 text-amber-900 flex items-start space-x-3 text-xs">
          <AlertCircle className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
          <div className="flex-1">
            <p className="font-bold">Notice:</p>
            <p>{errorNotice}</p>
          </div>
        </div>
      )}

      {/* Day Metrics Quick Strip */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-4">
        <div className="light-card rounded-2xl p-4 flex items-center space-x-3.5">
          <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
            <CheckCircle2 className="w-5 h-5" />
          </div>
          <div>
            <div className="text-xl font-black text-[#1C1C1A]">
              {completedTasksToday.length}
            </div>
            <div className="text-[11px] font-mono text-[#1C1C1A]/60">
              Tasks Completed
            </div>
          </div>
        </div>

        <div className="light-card rounded-2xl p-4 flex items-center space-x-3.5">
          <div className="w-10 h-10 rounded-xl bg-[#FF5B5B]/10 text-[#FF5B5B] flex items-center justify-center shrink-0">
            <Flame className="w-5 h-5" />
          </div>
          <div>
            <div className="text-xl font-black text-[#1C1C1A]">
              {totalFocusMinutesToday}m
            </div>
            <div className="text-[11px] font-mono text-[#1C1C1A]/60">
              Focus Time Logged
            </div>
          </div>
        </div>

        <div className="light-card rounded-2xl p-4 flex items-center space-x-3.5">
          <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0">
            <BookOpen className="w-5 h-5" />
          </div>
          <div>
            <div className="text-xl font-black text-[#1C1C1A]">
              {journalEntriesToday.length}
            </div>
            <div className="text-[11px] font-mono text-[#1C1C1A]/60">
              Journal Reflections
            </div>
          </div>
        </div>

        <div className="light-card rounded-2xl p-4 flex items-center space-x-3.5">
          <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center shrink-0">
            <Inbox className="w-5 h-5" />
          </div>
          <div>
            <div className="text-xl font-black text-[#1C1C1A]">
              {capturesToday.length}
            </div>
            <div className="text-[11px] font-mono text-[#1C1C1A]/60">
              Ideas Offloaded
            </div>
          </div>
        </div>
      </div>

      {/* Generated AI Summary Content */}
      <AnimatePresence mode="wait">
        {summaryData ? (
          <motion.div
            key={summaryData.date + summaryData.generatedAt}
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="space-y-6"
          >
            {/* Main AI Highlight Box */}
            <div className="light-card rounded-[32px] p-6 sm:p-8 space-y-6 border-2 border-[#FF5B5B]/20 relative overflow-hidden bg-gradient-to-br from-white via-white to-[#FF5B5B]/5">
              {/* Card Header & Controls */}
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-black/5">
                <div className="flex items-center space-x-2.5">
                  <div className="w-8 h-8 rounded-full bg-[#FF5B5B] text-white flex items-center justify-center shadow-xs">
                    <Sparkles className="w-4 h-4" />
                  </div>
                  <div>
                    <span className="text-xs font-mono font-bold text-[#FF5B5B] uppercase tracking-wider block">
                      AI Daily Highlight • {summaryData.date}
                    </span>
                    <span className="text-[10px] text-[#1C1C1A]/40 font-mono">
                      Generated via {summaryData.source === 'gemini_3.7_flash' ? 'Gemini 3.7 Flash' : 'Neuro-Synthesis'} • {new Date(summaryData.generatedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </span>
                  </div>
                </div>

                <div className="flex items-center space-x-2">
                  <div className="inline-flex p-1 bg-[#F2EFE9] rounded-xl border border-black/5 text-xs">
                    <button
                      type="button"
                      onClick={() => setViewMode('cards')}
                      className={`px-3 py-1 rounded-lg font-bold transition-all cursor-pointer ${
                        viewMode === 'cards'
                          ? 'bg-white text-[#1C1C1A] shadow-2xs'
                          : 'text-[#1C1C1A]/60 hover:text-[#1C1C1A]'
                      }`}
                    >
                      Bento View
                    </button>
                    <button
                      type="button"
                      onClick={() => setViewMode('markdown')}
                      className={`px-3 py-1 rounded-lg font-bold transition-all cursor-pointer ${
                        viewMode === 'markdown'
                          ? 'bg-white text-[#1C1C1A] shadow-2xs'
                          : 'text-[#1C1C1A]/60 hover:text-[#1C1C1A]'
                      }`}
                    >
                      Full Readout
                    </button>
                  </div>

                  <button
                    type="button"
                    onClick={handleCopySummary}
                    className="inline-flex items-center space-x-1.5 px-3 py-1.5 rounded-xl bg-white border border-black/10 hover:border-[#FF5B5B]/40 text-xs font-mono font-bold text-[#1C1C1A] shadow-2xs transition-all cursor-pointer"
                    title="Copy Summary"
                  >
                    {isCopied ? (
                      <>
                        <Check className="w-3.5 h-3.5 text-emerald-600" />
                        <span className="text-emerald-700">Copied!</span>
                      </>
                    ) : (
                      <>
                        <Copy className="w-3.5 h-3.5 text-[#1C1C1A]/60" />
                        <span>Copy</span>
                      </>
                    )}
                  </button>
                </div>
              </div>

              {/* Headline */}
              <div className="space-y-1">
                <h2 className="text-xl sm:text-2xl font-black text-[#1C1C1A] leading-tight">
                  {summaryData.headline}
                </h2>
              </div>

              {viewMode === 'cards' ? (
                /* Bento Cards Grid */
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {/* Dopamine Wins */}
                  <div className="p-5 rounded-2xl bg-white border border-black/5 shadow-2xs space-y-3 md:col-span-2">
                    <div className="flex items-center space-x-2 text-emerald-700">
                      <Zap className="w-4 h-4" />
                      <h3 className="text-xs font-mono font-bold uppercase tracking-wider">
                        Dopamine Wins & Milestones
                      </h3>
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                      {summaryData.dopamineWins.map((win, idx) => (
                        <div
                          key={idx}
                          className="flex items-start space-x-2.5 p-3 rounded-xl bg-emerald-50/70 border border-emerald-200/60 text-xs text-[#1C1C1A]"
                        >
                          <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                          <span className="font-medium leading-relaxed">{win}</span>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Journal & Reflections */}
                  <div className="p-5 rounded-2xl bg-white border border-black/5 shadow-2xs space-y-3">
                    <div className="flex items-center space-x-2 text-indigo-700">
                      <BookOpen className="w-4 h-4" />
                      <h3 className="text-xs font-mono font-bold uppercase tracking-wider">
                        Mindset & Emotional Space
                      </h3>
                    </div>
                    <p className="text-xs sm:text-sm text-[#1C1C1A]/80 leading-relaxed font-sans bg-indigo-50/40 p-3.5 rounded-xl border border-indigo-100/60">
                      {summaryData.journalReflections}
                    </p>
                  </div>

                  {/* Focus & Stamina */}
                  <div className="p-5 rounded-2xl bg-white border border-black/5 shadow-2xs space-y-3">
                    <div className="flex items-center space-x-2 text-rose-700">
                      <Flame className="w-4 h-4" />
                      <h3 className="text-xs font-mono font-bold uppercase tracking-wider">
                        Executive Pacing & Focus
                      </h3>
                    </div>
                    <p className="text-xs sm:text-sm text-[#1C1C1A]/80 leading-relaxed font-sans bg-rose-50/40 p-3.5 rounded-xl border border-rose-100/60">
                      {summaryData.focusStaminaInsight}
                    </p>
                  </div>

                  {/* Tomorrow's Gentle Kickstart */}
                  <div className="p-5 rounded-2xl bg-gradient-to-r from-amber-50/80 to-amber-100/40 border border-amber-200/80 shadow-2xs space-y-3 md:col-span-2">
                    <div className="flex items-center space-x-2 text-amber-800">
                      <Sun className="w-4 h-4" />
                      <h3 className="text-xs font-mono font-bold uppercase tracking-wider">
                        Tomorrow's Gentle Kickstart (Low Activation Energy)
                      </h3>
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                      {summaryData.gentleTomorrowKickstart.map((step, idx) => (
                        <div
                          key={idx}
                          className="flex items-start space-x-2.5 p-3 rounded-xl bg-white/90 border border-amber-200/80 text-xs text-[#1C1C1A]"
                        >
                          <span className="w-5 h-5 rounded-full bg-amber-500 text-white font-mono font-bold flex items-center justify-center shrink-0 text-[10px]">
                            {idx + 1}
                          </span>
                          <span className="font-medium leading-relaxed">{step}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              ) : (
                /* Full Markdown Narrative View */
                <div className="p-6 rounded-2xl bg-white border border-black/5 shadow-2xs space-y-4 font-sans text-xs sm:text-sm text-[#1C1C1A]/90 whitespace-pre-wrap leading-relaxed">
                  {summaryData.fullNarrativeMarkdown}
                </div>
              )}
            </div>
          </motion.div>
        ) : (
          /* Empty / Un-generated State */
          <div className="light-card rounded-[32px] p-10 text-center space-y-4">
            <div className="w-14 h-14 mx-auto rounded-full bg-[#FF5B5B]/10 text-[#FF5B5B] flex items-center justify-center">
              <Sparkles className="w-7 h-7" />
            </div>
            <div className="space-y-1 max-w-md mx-auto">
              <h3 className="text-lg font-bold text-[#1C1C1A]">
                Ready for Today's Highlight Reel?
              </h3>
              <p className="text-xs text-[#1C1C1A]/60 font-mono">
                Click "Generate Summary" above to have Gemini review your {completedTasksToday.length} completed tasks, {journalEntriesToday.length} journal reflections, and focus time for {selectedDate}.
              </p>
            </div>
            <button
              type="button"
              onClick={handleGenerateSummary}
              disabled={isLoading}
              className="inline-flex items-center space-x-2 px-6 py-2.5 rounded-2xl bg-[#111113] hover:bg-black text-white text-xs font-bold shadow-md transition-all active:scale-95 cursor-pointer"
            >
              <Sparkles className="w-4 h-4 text-[#FF5B5B]" />
              <span>Generate with Gemini</span>
            </button>
          </div>
        )}
      </AnimatePresence>

      {/* Raw Activity Log for the Day */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-2">
        {/* Completed Tasks List */}
        <div className="light-card rounded-[32px] p-6 space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <CheckCircle2 className="w-4 h-4 text-emerald-600" />
              <h3 className="text-sm font-bold text-[#1C1C1A]">
                Completed Tasks ({completedTasksToday.length})
              </h3>
            </div>
            {onNavigateToTasks && (
              <button
                type="button"
                onClick={onNavigateToTasks}
                className="text-xs font-mono text-[#FF5B5B] hover:underline flex items-center space-x-1 cursor-pointer"
              >
                <span>View All Tasks</span>
                <ArrowRight className="w-3 h-3" />
              </button>
            )}
          </div>

          {completedTasksToday.length === 0 ? (
            <div className="p-6 text-center rounded-2xl bg-[#F8F7F4] border border-black/5 text-xs text-[#1C1C1A]/50 font-mono">
              No tasks marked complete for this date.
            </div>
          ) : (
            <div className="space-y-2 max-h-72 overflow-y-auto pr-1">
              {completedTasksToday.map((task) => (
                <div
                  key={task.id}
                  className="p-3 rounded-2xl bg-[#F8F7F4] border border-black/5 flex items-center justify-between space-x-2"
                >
                  <div className="flex items-center space-x-2.5 min-w-0">
                    <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                    <div className="truncate">
                      <span className="text-xs font-bold text-[#1C1C1A] block truncate">
                        {task.title}
                      </span>
                      <span className="text-[10px] font-mono text-[#1C1C1A]/50">
                        {getAreaName(task.lifeAreaId)} • {task.focusMinutesLogged || task.focusMinutesTarget || 0}m focus
                      </span>
                    </div>
                  </div>
                  <span className="text-[10px] font-mono px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 shrink-0">
                    Done
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Journal Entries Log */}
        <div className="light-card rounded-[32px] p-6 space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <BookOpen className="w-4 h-4 text-indigo-600" />
              <h3 className="text-sm font-bold text-[#1C1C1A]">
                Journal Reflections ({journalEntriesToday.length})
              </h3>
            </div>
          </div>

          {journalEntriesToday.length === 0 ? (
            <div className="p-6 text-center rounded-2xl bg-[#F8F7F4] border border-black/5 text-xs text-[#1C1C1A]/50 font-mono">
              No reflections written for this date.
            </div>
          ) : (
            <div className="space-y-2 max-h-72 overflow-y-auto pr-1">
              {journalEntriesToday.map((entry) => (
                <div
                  key={entry.id}
                  className="p-3.5 rounded-2xl bg-[#F8F7F4] border border-black/5 space-y-1.5"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-1.5">
                      <span className="text-sm">{entry.moodEmoji || '📝'}</span>
                      <span className="text-xs font-bold text-[#1C1C1A] truncate max-w-[200px]">
                        {entry.title}
                      </span>
                    </div>
                    <span className="text-[10px] font-mono text-[#1C1C1A]/50">
                      {new Date(entry.createdAt).toLocaleTimeString([], {
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </span>
                  </div>
                  <p className="text-xs text-[#1C1C1A]/70 font-sans line-clamp-2 italic">
                    "{entry.content}"
                  </p>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
