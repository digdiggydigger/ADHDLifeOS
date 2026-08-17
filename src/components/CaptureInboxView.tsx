import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { CaptureItem, LifeArea, Tag } from '../types';
import {
  Inbox,
  CheckCircle2,
  BookOpen,
  Trash2,
  FileText,
  Mic,
  Camera,
  ArrowRight,
  Sparkles,
  Plus,
  X,
} from 'lucide-react';

interface CaptureInboxViewProps {
  captures: CaptureItem[];
  lifeAreas: LifeArea[];
  tags: Tag[];
  onDeleteCapture: (id: string) => void;
  onPromoteToTask: (
    captureId: string,
    taskData: {
      title: string;
      description?: string;
      lifeAreaId: string;
      priority: 'low' | 'medium' | 'high';
      dueDate?: string;
      tags: string[];
      focusMinutesTarget?: number;
    }
  ) => void;
  onPromoteToJournal: (
    captureId: string,
    journalData: {
      title: string;
      content: string;
      lifeAreaId: string;
      energyLevel: 'low' | 'medium' | 'high';
      moodEmoji: string;
      tags: string[];
    }
  ) => void;
  onOpenQuickCapture: () => void;
}

export const CaptureInboxView: React.FC<CaptureInboxViewProps> = ({
  captures,
  lifeAreas,
  tags,
  onDeleteCapture,
  onPromoteToTask,
  onPromoteToJournal,
  onOpenQuickCapture,
}) => {
  const [activeTabFilter, setActiveTabFilter] = useState<'unprocessed' | 'promoted'>('unprocessed');
  const [promotingCapture, setPromotingCapture] = useState<CaptureItem | null>(null);
  const [promoteMode, setPromoteMode] = useState<'task' | 'journal'>('task');

  // Promote Task form state
  const [taskTitle, setTaskTitle] = useState('');
  const [taskDescription, setTaskDescription] = useState('');
  const [taskLifeAreaId, setTaskLifeAreaId] = useState('');
  const [taskPriority, setTaskPriority] = useState<'low' | 'medium' | 'high'>('medium');
  const [taskDueDate, setTaskDueDate] = useState('');
  const [taskSelectedTags, setTaskSelectedTags] = useState<string[]>([]);
  const [taskFocusTarget, setTaskFocusTarget] = useState<number>(15);

  // Promote Journal form state
  const [journalContent, setJournalContent] = useState('');
  const [journalEnergy, setJournalEnergy] = useState<'low' | 'medium' | 'high'>('medium');
  const [journalMood, setJournalMood] = useState('⚡');

  const filteredCaptures = captures.filter((c) =>
    activeTabFilter === 'unprocessed' ? c.status === 'unprocessed' : c.status === 'promoted'
  );

  const openPromoteModal = (capture: CaptureItem, mode: 'task' | 'journal') => {
    setPromotingCapture(capture);
    setPromoteMode(mode);
    setTaskTitle(capture.title);
    setTaskDescription(capture.transcript || '');
    setTaskLifeAreaId(capture.suggestedLifeAreaId || lifeAreas[0]?.id || '');
    setTaskPriority('medium');
    setTaskDueDate(new Date().toISOString().split('T')[0]);
    setTaskSelectedTags([]);
    setTaskFocusTarget(15);
    setJournalContent(capture.transcript || capture.title);
  };

  const handleConfirmTaskPromote = (e: React.FormEvent) => {
    e.preventDefault();
    if (!promotingCapture || !taskLifeAreaId) return;

    onPromoteToTask(promotingCapture.id, {
      title: taskTitle,
      description: taskDescription,
      lifeAreaId: taskLifeAreaId,
      priority: taskPriority,
      dueDate: taskDueDate || undefined,
      tags: taskSelectedTags,
      focusMinutesTarget: taskFocusTarget,
    });

    setPromotingCapture(null);
  };

  const handleConfirmJournalPromote = (e: React.FormEvent) => {
    e.preventDefault();
    if (!promotingCapture || !taskLifeAreaId) return;

    onPromoteToJournal(promotingCapture.id, {
      title: taskTitle,
      content: journalContent,
      lifeAreaId: taskLifeAreaId,
      energyLevel: journalEnergy,
      moodEmoji: journalMood,
      tags: taskSelectedTags,
    });

    setPromotingCapture(null);
  };

  const toggleTag = (tagName: string) => {
    setTaskSelectedTags((prev) =>
      prev.includes(tagName) ? prev.filter((t) => t !== tagName) : [...prev, tagName]
    );
  };

  return (
    <div className="space-y-6 pb-28">
      {/* Header Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="label text-[#FF5B5B]">Frictionless Ingestion</div>
          <h2 className="text-3xl sm:text-4xl font-bold text-[#1C1C1A] tracking-tight">Capture Inbox</h2>
          <p className="text-xs text-[#1C1C1A]/60 font-mono uppercase tracking-wider mt-1">
            Dump thoughts instantly, triage when executive bandwidth allows
          </p>
        </div>

        <button
          id="inbox-quick-capture-btn"
          onClick={onOpenQuickCapture}
          className="flex items-center justify-center space-x-2 bg-[#FF5B5B] hover:bg-[#ff4242] text-white px-5 py-3 rounded-full text-xs font-mono font-bold uppercase tracking-wider shadow-sm transition-all cursor-pointer hover:scale-105 active:scale-95"
        >
          <Plus className="w-4 h-4 stroke-[3]" />
          <span>New Quick Capture</span>
        </button>
      </div>

      {/* Tabs Filter */}
      <div className="flex items-center space-x-2 border-b border-black/5 pb-2 text-xs font-mono uppercase tracking-wider">
        <button
          id="inbox-filter-unprocessed"
          onClick={() => setActiveTabFilter('unprocessed')}
          className={`px-4 py-2 rounded-full font-bold transition-all cursor-pointer ${
            activeTabFilter === 'unprocessed'
              ? 'bg-[#111113] text-white'
              : 'text-[#1C1C1A]/60 hover:text-[#1C1C1A] hover:bg-black/5'
          }`}
        >
          Unprocessed ({captures.filter((c) => c.status === 'unprocessed').length})
        </button>

        <button
          id="inbox-filter-promoted"
          onClick={() => setActiveTabFilter('promoted')}
          className={`px-4 py-2 rounded-full font-bold transition-all cursor-pointer ${
            activeTabFilter === 'promoted'
              ? 'bg-[#111113] text-white'
              : 'text-[#1C1C1A]/60 hover:text-[#1C1C1A] hover:bg-black/5'
          }`}
        >
          Triaged / Promoted ({captures.filter((c) => c.status === 'promoted').length})
        </button>
      </div>

      {/* Captures List */}
      {filteredCaptures.length === 0 ? (
        <div className="light-card rounded-[32px] p-12 text-center space-y-3">
          <div className="w-14 h-14 mx-auto rounded-full bg-[#FF5B5B]/10 text-[#FF5B5B] flex items-center justify-center">
            <Inbox className="w-7 h-7" />
          </div>
          <h3 className="text-lg font-bold text-[#1C1C1A]">
            {activeTabFilter === 'unprocessed' ? 'Your Inbox is Clean!' : 'No Triaged Items Yet'}
          </h3>
          <p className="text-xs text-[#1C1C1A]/60 max-w-sm mx-auto font-mono">
            {activeTabFilter === 'unprocessed'
              ? 'All captured thoughts have been converted into action tasks or logs. Tap Quick Capture to record any idea.'
              : 'Triaged thoughts will appear here once promoted.'}
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {filteredCaptures.map((capture) => {
            const suggestedArea = lifeAreas.find((a) => a.id === capture.suggestedLifeAreaId);

            return (
              <div
                key={capture.id}
                id={`inbox-item-${capture.id}`}
                className="light-card rounded-3xl p-5 shadow-xs hover:border-black/20 transition-all flex flex-col md:flex-row md:items-center justify-between gap-4"
              >
                <div className="flex items-start space-x-3.5">
                  <div className="w-10 h-10 rounded-2xl bg-white border border-black/5 text-[#1C1C1A] flex items-center justify-center shrink-0">
                    {capture.type === 'voice' ? (
                      <Mic className="w-5 h-5 text-[#FF5B5B]" />
                    ) : capture.type === 'photo' ? (
                      <Camera className="w-5 h-5 text-purple-600" />
                    ) : (
                      <FileText className="w-5 h-5 text-amber-600" />
                    )}
                  </div>

                  <div className="space-y-1">
                    <div className="flex items-center space-x-2 flex-wrap">
                      <span className="text-sm sm:text-base font-bold text-[#1C1C1A]">{capture.title}</span>
                      {suggestedArea && (
                        <span className="text-xs px-2.5 py-0.5 rounded-full bg-white border border-black/5 text-[#1C1C1A]/70 font-mono">
                          {suggestedArea.emoji} {suggestedArea.name}
                        </span>
                      )}
                    </div>

                    {capture.transcript && (
                      <p className="text-xs text-[#1C1C1A]/80 italic bg-white/70 p-2.5 rounded-xl border border-black/5 font-sans">
                        "{capture.transcript}"
                      </p>
                    )}

                    <span className="text-[11px] text-[#1C1C1A]/50 font-mono block">
                      Captured {new Date(capture.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} • {capture.type} note
                    </span>
                  </div>
                </div>

                {/* Triage Action Buttons */}
                {capture.status === 'unprocessed' && (
                  <div className="flex items-center space-x-2 shrink-0 self-end md:self-center">
                    <button
                      id={`inbox-promote-task-${capture.id}`}
                      onClick={() => openPromoteModal(capture, 'task')}
                      className="flex items-center space-x-1.5 bg-[#FF5B5B] hover:bg-[#ff4242] text-white px-4 py-2 rounded-full text-xs font-mono font-bold uppercase shadow-xs transition-all cursor-pointer hover:scale-105"
                    >
                      <CheckCircle2 className="w-3.5 h-3.5" />
                      <span>Promote to Task</span>
                    </button>

                    <button
                      id={`inbox-promote-journal-${capture.id}`}
                      onClick={() => openPromoteModal(capture, 'journal')}
                      className="flex items-center space-x-1.5 bg-white hover:bg-black/5 text-[#1C1C1A] border border-black/10 px-3.5 py-2 rounded-full text-xs font-mono font-bold uppercase transition-all cursor-pointer"
                    >
                      <BookOpen className="w-3.5 h-3.5" />
                      <span>Log to Journal</span>
                    </button>

                    <button
                      id={`inbox-delete-${capture.id}`}
                      onClick={() => onDeleteCapture(capture.id)}
                      className="p-2 text-[#1C1C1A]/40 hover:text-[#FF5B5B] hover:bg-[#FF5B5B]/10 rounded-full transition-colors cursor-pointer"
                      title="Delete capture"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* Promote Triage Modal */}
      <AnimatePresence>
        {promotingCapture && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
            onClick={() => setPromotingCapture(null)}
          >
            <motion.div
              initial={{ opacity: 0, scale: 0.94, y: 16 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.94, y: 16 }}
              transition={{ type: 'spring', stiffness: 350, damping: 28 }}
              onClick={(e) => e.stopPropagation()}
              className="dark-card text-white rounded-[32px] max-w-lg w-full p-6 sm:p-7 shadow-2xl space-y-5"
            >
              <div className="flex items-center justify-between pb-3 border-b border-white/10">
                <div className="flex items-center space-x-2">
                  <Sparkles className="w-5 h-5 text-[#FF5B5B]" />
                  <h3 className="text-xl font-bold text-white">
                    {promoteMode === 'task' ? 'Promote Thought to Action Task' : 'Log Thought to Journal'}
                  </h3>
                </div>
                <button
                  id="promote-modal-close"
                  onClick={() => setPromotingCapture(null)}
                  className="text-white/50 hover:text-white p-1 rounded-full cursor-pointer"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

            {promoteMode === 'task' ? (
              <form onSubmit={handleConfirmTaskPromote} className="space-y-4">
                <div>
                  <label className="label text-white/60 mb-1">
                    Task Title
                  </label>
                  <input
                    type="text"
                    required
                    id="promote-task-title-input"
                    value={taskTitle}
                    onChange={(e) => setTaskTitle(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm font-semibold text-white focus:outline-hidden focus:border-[#FF5B5B]"
                  />
                </div>

                <div>
                  <label className="label text-white/60 mb-1">
                    Description & Micro-steps
                  </label>
                  <textarea
                    rows={2}
                    id="promote-task-desc-input"
                    value={taskDescription}
                    onChange={(e) => setTaskDescription(e.target.value)}
                    placeholder="Break into tiny 2-min starter steps..."
                    className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white focus:outline-hidden focus:border-[#FF5B5B] placeholder:text-zinc-400"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="label text-white/60 mb-1">
                      Life Area
                    </label>
                    <select
                      required
                      id="promote-task-life-area-select"
                      value={taskLifeAreaId}
                      onChange={(e) => setTaskLifeAreaId(e.target.value)}
                      className="w-full px-3.5 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
                    >
                      {lifeAreas.map((area) => (
                        <option key={area.id} value={area.id} className="bg-[#111113]">
                          {area.emoji} {area.name}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="label text-white/60 mb-1">
                      Priority / Energy Level
                    </label>
                    <select
                      id="promote-task-priority-select"
                      value={taskPriority}
                      onChange={(e) => setTaskPriority(e.target.value as any)}
                      className="w-full px-3.5 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
                    >
                      <option value="low" className="bg-[#111113]">Low Energy / Quick Win</option>
                      <option value="medium" className="bg-[#111113]">Medium Focus</option>
                      <option value="high" className="bg-[#111113]">High Energy Required</option>
                    </select>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="label text-white/60 mb-1">
                      Due Date
                    </label>
                    <input
                      type="date"
                      id="promote-task-due-date"
                      value={taskDueDate}
                      onChange={(e) => setTaskDueDate(e.target.value)}
                      className="w-full px-3.5 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
                    />
                  </div>

                  <div>
                    <label className="label text-white/60 mb-1">
                      Target Focus (mins)
                    </label>
                    <input
                      type="number"
                      min={5}
                      max={120}
                      step={5}
                      id="promote-task-focus-mins"
                      value={taskFocusTarget}
                      onChange={(e) => setTaskFocusTarget(Number(e.target.value))}
                      className="w-full px-3.5 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
                    />
                  </div>
                </div>

                <div className="flex items-center justify-end space-x-3 pt-3">
                  <button
                    type="button"
                    onClick={() => setPromotingCapture(null)}
                    className="px-4 py-2 text-xs font-mono uppercase text-white/60 hover:text-white rounded-full cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    id="promote-task-confirm-btn"
                    className="px-6 py-2.5 text-xs font-mono font-bold uppercase bg-[#FF5B5B] hover:bg-[#ff4242] text-white rounded-full shadow-md cursor-pointer"
                  >
                    Confirm & Create Task
                  </button>
                </div>
              </form>
            ) : (
              <form onSubmit={handleConfirmJournalPromote} className="space-y-4">
                <div>
                  <label className="label text-white/60 mb-1">
                    Journal Title
                  </label>
                  <input
                    type="text"
                    required
                    id="promote-journal-title-input"
                    value={taskTitle}
                    onChange={(e) => setTaskTitle(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm font-semibold text-white focus:outline-hidden focus:border-[#FF5B5B]"
                  />
                </div>

                <div>
                  <label className="label text-white/60 mb-1">
                    Journal Reflection
                  </label>
                  <textarea
                    rows={4}
                    required
                    id="promote-journal-content-input"
                    value={journalContent}
                    onChange={(e) => setJournalContent(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white focus:outline-hidden focus:border-[#FF5B5B]"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="label text-white/60 mb-1">
                      Life Area
                    </label>
                    <select
                      required
                      id="promote-journal-life-area-select"
                      value={taskLifeAreaId}
                      onChange={(e) => setTaskLifeAreaId(e.target.value)}
                      className="w-full px-3.5 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
                    >
                      {lifeAreas.map((area) => (
                        <option key={area.id} value={area.id} className="bg-[#111113]">
                          {area.emoji} {area.name}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="label text-white/60 mb-1">
                      Energy Level
                    </label>
                    <select
                      id="promote-journal-energy-select"
                      value={journalEnergy}
                      onChange={(e) => setJournalEnergy(e.target.value as any)}
                      className="w-full px-3.5 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
                    >
                      <option value="low" className="bg-[#111113]">Low Energy</option>
                      <option value="medium" className="bg-[#111113]">Medium Energy</option>
                      <option value="high" className="bg-[#111113]">High Energy</option>
                    </select>
                  </div>
                </div>

                <div className="flex items-center justify-end space-x-3 pt-3">
                  <button
                    type="button"
                    onClick={() => setPromotingCapture(null)}
                    className="px-4 py-2 text-xs font-mono uppercase text-white/60 hover:text-white rounded-full cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    id="promote-journal-confirm-btn"
                    className="px-6 py-2.5 text-xs font-mono font-bold uppercase bg-[#FF5B5B] hover:bg-[#ff4242] text-white rounded-full shadow-md cursor-pointer"
                  >
                    Save to Journal
                  </button>
                </div>
              </form>
            )}
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};
