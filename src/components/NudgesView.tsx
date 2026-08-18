import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { NudgeItem, NudgeHistoryRecord } from '../types';
import { triggerHaptic, playNudgeChime, formatFocusDuration } from '../utils/haptics';
import {
  Bell,
  Plus,
  Clock,
  X,
  History,
  CheckCircle2,
  AlertCircle,
  Coffee,
  Sparkles,
  Trash2,
  Search,
  Filter,
  Check,
  Volume2,
} from 'lucide-react';

interface NudgesViewProps {
  nudges: NudgeItem[];
  setNudges: React.Dispatch<React.SetStateAction<NudgeItem[]>>;
  onDismissNudge: (id: string) => void;
  nudgeHistory: NudgeHistoryRecord[];
  onAddNudgeReaction?: (id: string, reaction: NudgeHistoryRecord['reaction']) => void;
  onClearNudgeHistory?: () => void;
  onStartTestSession?: () => void;
}

export const NudgesView: React.FC<NudgesViewProps> = ({
  nudges,
  setNudges,
  onDismissNudge,
  nudgeHistory,
  onAddNudgeReaction,
  onClearNudgeHistory,
  onStartTestSession,
}) => {
  const [showAdd, setShowAdd] = useState(false);
  const [newLabel, setNewLabel] = useState('');
  const [newSchedule, setNewSchedule] = useState('Daily at 2:00 PM');
  const [newType, setNewType] = useState<'break' | 'triage' | 'hydrate' | 'focus' | 'custom'>('custom');
  const [historySearch, setHistorySearch] = useState('');
  const [historyFilter, setHistoryFilter] = useState<'all' | 'reacted' | 'pending'>('all');

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newLabel.trim()) return;

    triggerHaptic('success');
    const newNudge: NudgeItem = {
      id: 'nudge-' + Date.now(),
      label: newLabel.trim(),
      schedule: newSchedule,
      type: newType,
      isDue: true,
    };

    setNudges((prev) => [newNudge, ...prev]);
    setNewLabel('');
    setShowAdd(false);
  };

  const toggleNudgeDue = (id: string) => {
    triggerHaptic('toggle');
    setNudges((prev) =>
      prev.map((n) => {
        if (n.id === id) {
          const nextDue = !n.isDue;
          if (nextDue) playNudgeChime();
          return { ...n, isDue: nextDue };
        }
        return n;
      })
    );
  };

  const filteredHistory = nudgeHistory.filter((item) => {
    const matchesSearch =
      item.taskTitle.toLowerCase().includes(historySearch.toLowerCase()) ||
      (item.reaction && item.reaction.toLowerCase().includes(historySearch.toLowerCase()));

    if (!matchesSearch) return false;
    if (historyFilter === 'reacted') return Boolean(item.reaction);
    if (historyFilter === 'pending') return !item.reaction;
    return true;
  });

  const totalNudgesTriggered = nudgeHistory.length;
  const reactedCount = nudgeHistory.filter((h) => Boolean(h.reaction)).length;
  const positiveCheckins = nudgeHistory.filter(
    (h) => h.reaction === 'on_track' || h.reaction === 'completed_step'
  ).length;
  const checkinRate = totalNudgesTriggered > 0 ? Math.round((reactedCount / totalNudgesTriggered) * 100) : 100;

  return (
    <div className="space-y-8 pb-28">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="label text-[#FF5B5B]">Behavioral Prompts & Feedback</div>
          <h2 className="text-3xl sm:text-4xl font-bold text-[#1C1C1A] tracking-tight">Executive Nudges</h2>
          <p className="text-xs text-[#1C1C1A]/60 font-mono uppercase tracking-wider mt-1">
            Automated acoustic and haptic prompts to keep your ADHD executive functions grounded
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <button
            type="button"
            onClick={() => {
              triggerHaptic('medium');
              playNudgeChime();
            }}
            className="flex items-center justify-center space-x-1.5 bg-white hover:bg-black/5 text-[#1C1C1A] border border-black/10 px-4 py-3 rounded-full text-xs font-mono font-bold uppercase tracking-wider transition-all cursor-pointer hover:scale-105 active:scale-95"
            title="Test Bell Chime Sound"
          >
            <Volume2 className="w-3.5 h-3.5 text-[#FF5B5B]" />
            <span>Test Chime</span>
          </button>

          <button
            id="nudges-add-btn"
            onClick={() => {
              triggerHaptic('light');
              setShowAdd(!showAdd);
            }}
            className="flex items-center justify-center space-x-2 bg-[#FF5B5B] hover:bg-[#ff4242] text-white px-5 py-3 rounded-full text-xs font-mono font-bold uppercase tracking-wider shadow-sm transition-all cursor-pointer hover:scale-105 active:scale-95"
          >
            <Plus className="w-4 h-4 stroke-[3]" />
            <span>Add Routine</span>
          </button>
        </div>
      </div>

      {/* Add Custom Routine Modal Form */}
      <AnimatePresence>
        {showAdd && (
          <motion.form
            initial={{ opacity: 0, height: 0, scale: 0.98 }}
            animate={{ opacity: 1, height: 'auto', scale: 1 }}
            exit={{ opacity: 0, height: 0, scale: 0.98 }}
            transition={{ type: 'spring', stiffness: 320, damping: 28 }}
            onSubmit={handleCreate}
            className="dark-card text-white rounded-[32px] p-6 sm:p-7 shadow-xl space-y-4 overflow-hidden"
          >
            <div className="flex items-center justify-between pb-2 border-b border-white/10">
              <h3 className="text-xl font-bold text-white">Create Nudge Routine</h3>
              <button
                type="button"
                onClick={() => setShowAdd(false)}
                className="text-white/50 hover:text-white p-1 rounded-full cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div>
              <label className="label text-white/60 mb-1">Nudge Label</label>
              <input
                type="text"
                required
                id="nudge-label-input"
                value={newLabel}
                onChange={(e) => setNewLabel(e.target.value)}
                placeholder="E.g., 5-minute desk walk and water drink"
                className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm font-semibold text-white focus:outline-hidden focus:border-[#FF5B5B] placeholder:text-zinc-400"
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="label text-white/60 mb-1">Schedule / Frequency</label>
                <input
                  type="text"
                  id="nudge-schedule-input"
                  value={newSchedule}
                  onChange={(e) => setNewSchedule(e.target.value)}
                  placeholder="E.g., Every 2 hours"
                  className="w-full px-4 py-2 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
                />
              </div>

              <div>
                <label className="label text-white/60 mb-1">Type</label>
                <select
                  id="nudge-type-select"
                  value={newType}
                  onChange={(e) => setNewType(e.target.value as any)}
                  className="w-full px-4 py-2 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
                >
                  <option value="break" className="bg-[#111113]">Movement / Break</option>
                  <option value="hydrate" className="bg-[#111113]">Hydrate</option>
                  <option value="triage" className="bg-[#111113]">Inbox Triage</option>
                  <option value="focus" className="bg-[#111113]">Task Chunking</option>
                  <option value="custom" className="bg-[#111113]">Custom Routine</option>
                </select>
              </div>
            </div>

            <div className="flex items-center justify-end space-x-3 pt-2">
              <button
                type="button"
                onClick={() => setShowAdd(false)}
                className="px-4 py-2 text-xs font-mono uppercase text-white/60 hover:text-white rounded-full cursor-pointer font-bold"
              >
                Cancel
              </button>
              <button
                type="submit"
                id="nudge-submit-btn"
                className="px-6 py-2.5 text-xs font-mono font-bold uppercase bg-[#FF5B5B] hover:bg-[#ff4242] text-white rounded-full shadow-md cursor-pointer transition-all"
              >
                Save Nudge
              </button>
            </div>
          </motion.form>
        )}
      </AnimatePresence>

      {/* Active Nudges List */}
      <section className="space-y-3">
        <div className="flex items-center justify-between">
          <span className="label text-[#1C1C1A]/70 text-xs">Active Environmental Routines</span>
          <span className="text-[11px] font-mono text-[#1C1C1A]/50">{nudges.length} configured</span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {nudges.map((nudge) => (
            <div
              key={nudge.id}
              className={`rounded-3xl p-5 border transition-all flex items-center justify-between gap-4 ${
                nudge.isDue
                  ? 'bg-[#EFECE8] border-[#FF5B5B]/40 shadow-sm'
                  : 'bg-[#EFECE8]/60 border-black/5 opacity-75 hover:opacity-100'
              }`}
            >
              <div className="flex items-center space-x-3.5 overflow-hidden">
                <div
                  className={`w-11 h-11 rounded-2xl flex items-center justify-center font-bold text-lg border shrink-0 ${
                    nudge.isDue
                      ? 'bg-[#FF5B5B]/10 text-[#FF5B5B] border-[#FF5B5B]/20'
                      : 'bg-white text-[#1C1C1A]/40 border-black/5'
                  }`}
                >
                  <Bell className="w-5 h-5" />
                </div>

                <div className="truncate">
                  <h4 className="text-sm sm:text-base font-bold text-[#1C1C1A] truncate">{nudge.label}</h4>
                  <div className="flex items-center space-x-2 text-xs text-[#1C1C1A]/60 font-mono mt-0.5">
                    <Clock className="w-3.5 h-3.5 shrink-0" />
                    <span className="truncate">{nudge.schedule}</span>
                    {nudge.isDue && (
                      <span className="text-white font-bold bg-[#FF5B5B] px-2.5 py-0.5 rounded-full text-[10px] tracking-wider uppercase font-mono shrink-0">
                        DUE NOW
                      </span>
                    )}
                  </div>
                </div>
              </div>

              <button
                id={`toggle-nudge-${nudge.id}`}
                onClick={() => toggleNudgeDue(nudge.id)}
                className={`px-4 py-2 rounded-full text-xs font-mono font-bold uppercase transition-all cursor-pointer shrink-0 ${
                  nudge.isDue
                    ? 'bg-[#111113] hover:bg-black text-white shadow-xs'
                    : 'bg-white hover:bg-black/5 text-[#1C1C1A] border border-black/10'
                }`}
              >
                {nudge.isDue ? 'Dismiss' : 'Test Trigger'}
              </button>
            </div>
          ))}
        </div>
      </section>

      {/* SECTION 2: Nudge History & Focus Effectiveness Review */}
      <section id="nudge-history-section" className="space-y-4 pt-4 border-t border-black/10">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
          <div>
            <div className="flex items-center space-x-2">
              <History className="w-4 h-4 text-[#FF5B5B]" />
              <span className="label text-[#FF5B5B]">Audit & Effectiveness</span>
            </div>
            <h3 className="text-2xl font-bold text-[#1C1C1A] tracking-tight">Nudge History & Focus Review</h3>
            <p className="text-xs text-[#1C1C1A]/60 font-mono mt-0.5">
              Detailed timestamps, task contexts, and behavioral reactions across all completed focus sprints
            </p>
          </div>

          {nudgeHistory.length > 0 && onClearNudgeHistory && (
            <button
              id="clear-nudge-history-btn"
              onClick={() => {
                triggerHaptic('warning');
                if (confirm('Clear all recorded nudge history?')) {
                  onClearNudgeHistory();
                }
              }}
              className="flex items-center space-x-1 text-xs font-mono text-[#1C1C1A]/50 hover:text-[#FF5B5B] px-3 py-1.5 rounded-full border border-black/10 hover:border-[#FF5B5B]/30 transition-colors cursor-pointer self-start md:self-auto"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>Clear History</span>
            </button>
          )}
        </div>

        {/* Effectiveness Stats Bar */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <div className="bg-[#EFECE8] rounded-2xl p-4 border border-black/5">
            <span className="text-[10px] font-mono uppercase text-[#1C1C1A]/50 block">Total Triggered</span>
            <div className="text-2xl font-bold font-mono text-[#1C1C1A] mt-1">{totalNudgesTriggered}</div>
            <span className="text-[10px] text-zinc-500 font-mono">In-sprint notifications</span>
          </div>

          <div className="bg-[#EFECE8] rounded-2xl p-4 border border-black/5">
            <span className="text-[10px] font-mono uppercase text-[#1C1C1A]/50 block">Audited Check-ins</span>
            <div className="text-2xl font-bold font-mono text-emerald-600 mt-1">{reactedCount}</div>
            <span className="text-[10px] text-zinc-500 font-mono">{checkinRate}% reaction rate</span>
          </div>

          <div className="bg-[#EFECE8] rounded-2xl p-4 border border-black/5">
            <span className="text-[10px] font-mono uppercase text-[#1C1C1A]/50 block">On Track Score</span>
            <div className="text-2xl font-bold font-mono text-[#FF5B5B] mt-1">{positiveCheckins}</div>
            <span className="text-[10px] text-zinc-500 font-mono">Positive momentum</span>
          </div>

          <div className="bg-[#EFECE8] rounded-2xl p-4 border border-black/5">
            <span className="text-[10px] font-mono uppercase text-[#1C1C1A]/50 block">Floor Interval</span>
            <div className="text-2xl font-bold font-mono text-[#1C1C1A] mt-1">30s</div>
            <span className="text-[10px] text-zinc-500 font-mono">Enforced minimum</span>
          </div>
        </div>

        {/* Search and Filters */}
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 bg-white p-3 rounded-2xl border border-black/5">
          <div className="flex items-center space-x-2 px-3 py-1.5 bg-[#F8F7F4] rounded-xl flex-1 border border-black/5">
            <Search className="w-4 h-4 text-zinc-400" />
            <input
              type="text"
              value={historySearch}
              onChange={(e) => setHistorySearch(e.target.value)}
              placeholder="Search by task title or reaction..."
              className="bg-transparent text-xs font-mono w-full focus:outline-hidden text-[#1C1C1A]"
            />
            {historySearch && (
              <button onClick={() => setHistorySearch('')} className="text-zinc-400 hover:text-black">
                <X className="w-3.5 h-3.5" />
              </button>
            )}
          </div>

          <div className="flex items-center space-x-1.5 self-end sm:self-auto">
            <Filter className="w-3.5 h-3.5 text-[#1C1C1A]/50" />
            <button
              onClick={() => setHistoryFilter('all')}
              className={`px-3 py-1 rounded-lg text-xs font-mono transition-colors cursor-pointer ${
                historyFilter === 'all' ? 'bg-[#111113] text-white font-bold' : 'text-[#1C1C1A]/70 hover:bg-black/5'
              }`}
            >
              All ({nudgeHistory.length})
            </button>
            <button
              onClick={() => setHistoryFilter('reacted')}
              className={`px-3 py-1 rounded-lg text-xs font-mono transition-colors cursor-pointer ${
                historyFilter === 'reacted' ? 'bg-[#111113] text-white font-bold' : 'text-[#1C1C1A]/70 hover:bg-black/5'
              }`}
            >
              Logged ({reactedCount})
            </button>
            <button
              onClick={() => setHistoryFilter('pending')}
              className={`px-3 py-1 rounded-lg text-xs font-mono transition-colors cursor-pointer ${
                historyFilter === 'pending' ? 'bg-[#111113] text-white font-bold' : 'text-[#1C1C1A]/70 hover:bg-black/5'
              }`}
            >
              Pending ({totalNudgesTriggered - reactedCount})
            </button>
          </div>
        </div>

        {/* History Records List */}
        {filteredHistory.length === 0 ? (
          <div className="bg-[#EFECE8] rounded-3xl p-8 text-center space-y-3 border border-black/5">
            <div className="w-12 h-12 rounded-full bg-white flex items-center justify-center mx-auto text-[#FF5B5B] shadow-xs">
              <History className="w-6 h-6" />
            </div>
            <h4 className="text-base font-bold text-[#1C1C1A]">No Nudge History Found</h4>
            <p className="text-xs text-[#1C1C1A]/60 max-w-sm mx-auto font-mono">
              Start an ADHD Focus Sprint (min 30s) or trigger an environmental nudge to review your focus cadence.
            </p>
          </div>
        ) : (
          <div className="space-y-2.5">
            {filteredHistory.map((item) => {
              const formattedDate = new Date(item.timestamp).toLocaleString(undefined, {
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
              });
              const pct = Math.round((item.elapsedSeconds / item.totalDurationSeconds) * 100);

              return (
                <div
                  key={item.id}
                  className="bg-white rounded-2xl p-4 border border-black/5 shadow-xs hover:border-[#FF5B5B]/30 transition-all flex flex-col md:flex-row md:items-center justify-between gap-3"
                >
                  <div className="flex items-start space-x-3">
                    <span className="text-2xl p-1.5 bg-[#F8F7F4] rounded-xl shrink-0">{item.lifeAreaEmoji || '🎯'}</span>
                    <div>
                      <div className="flex items-center space-x-2 flex-wrap gap-y-1">
                        <h4 className="text-sm font-bold text-[#1C1C1A]">{item.taskTitle}</h4>
                        <span className="bg-[#FF5B5B]/10 text-[#FF5B5B] text-[10px] font-mono px-2 py-0.5 rounded-full font-bold">
                          Nudge {item.nudgeIndex}/{item.totalNudges} ({pct}%)
                        </span>
                      </div>

                      <div className="flex items-center space-x-3 text-xs text-[#1C1C1A]/60 font-mono mt-1 flex-wrap">
                        <span className="flex items-center space-x-1">
                          <Clock className="w-3 h-3 text-zinc-400" />
                          <span>{formattedDate}</span>
                        </span>
                        <span>•</span>
                        <span>
                          Checkpoint: <strong className="text-[#1C1C1A]">{formatFocusDuration(item.elapsedSeconds)}</strong> / {formatFocusDuration(item.totalDurationSeconds)}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Reaction Badges / Buttons */}
                  <div className="flex items-center space-x-1.5 pt-2 md:pt-0 border-t md:border-t-0 border-black/5 shrink-0">
                    <span className="text-[10px] font-mono text-[#1C1C1A]/50 mr-1 hidden sm:inline">Self-Audit:</span>
                    <button
                      onClick={() => onAddNudgeReaction && onAddNudgeReaction(item.id, 'on_track')}
                      className={`px-2.5 py-1 rounded-lg text-[11px] font-mono font-bold flex items-center space-x-1 transition-all cursor-pointer ${
                        item.reaction === 'on_track'
                          ? 'bg-emerald-600 text-white shadow-xs'
                          : 'bg-[#F8F7F4] hover:bg-emerald-50 text-emerald-700 border border-emerald-200'
                      }`}
                      title="Mark as Stayed on Track"
                    >
                      <CheckCircle2 className="w-3 h-3" />
                      <span>On Track</span>
                    </button>

                    <button
                      onClick={() => onAddNudgeReaction && onAddNudgeReaction(item.id, 'refocused')}
                      className={`px-2.5 py-1 rounded-lg text-[11px] font-mono font-bold flex items-center space-x-1 transition-all cursor-pointer ${
                        item.reaction === 'refocused'
                          ? 'bg-amber-600 text-white shadow-xs'
                          : 'bg-[#F8F7F4] hover:bg-amber-50 text-amber-700 border border-amber-200'
                      }`}
                      title="Mark as Refocused via Nudge"
                    >
                      <Sparkles className="w-3 h-3" />
                      <span>Refocused</span>
                    </button>

                    <button
                      onClick={() => onAddNudgeReaction && onAddNudgeReaction(item.id, 'completed_step')}
                      className={`px-2.5 py-1 rounded-lg text-[11px] font-mono font-bold flex items-center space-x-1 transition-all cursor-pointer ${
                        item.reaction === 'completed_step'
                          ? 'bg-indigo-600 text-white shadow-xs'
                          : 'bg-[#F8F7F4] hover:bg-indigo-50 text-indigo-700 border border-indigo-200'
                      }`}
                      title="Completed micro-step at this nudge"
                    >
                      <Check className="w-3 h-3" />
                      <span>Done Step</span>
                    </button>

                    <button
                      onClick={() => onAddNudgeReaction && onAddNudgeReaction(item.id, 'needed_break')}
                      className={`px-2.5 py-1 rounded-lg text-[11px] font-mono font-bold flex items-center space-x-1 transition-all cursor-pointer ${
                        item.reaction === 'needed_break'
                          ? 'bg-zinc-700 text-white shadow-xs'
                          : 'bg-[#F8F7F4] hover:bg-zinc-200 text-zinc-700 border border-zinc-200'
                      }`}
                      title="Needed water or quick pause"
                    >
                      <Coffee className="w-3 h-3" />
                      <span>Break</span>
                    </button>
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

