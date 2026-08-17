import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { NudgeItem } from '../types';
import { Bell, Plus, Clock, X } from 'lucide-react';

interface NudgesViewProps {
  nudges: NudgeItem[];
  setNudges: React.Dispatch<React.SetStateAction<NudgeItem[]>>;
  onDismissNudge: (id: string) => void;
}

export const NudgesView: React.FC<NudgesViewProps> = ({
  nudges,
  setNudges,
  onDismissNudge,
}) => {
  const [showAdd, setShowAdd] = useState(false);
  const [newLabel, setNewLabel] = useState('');
  const [newSchedule, setNewSchedule] = useState('Daily at 2:00 PM');
  const [newType, setNewType] = useState<'break' | 'triage' | 'hydrate' | 'focus' | 'custom'>('custom');

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newLabel.trim()) return;

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
    setNudges((prev) =>
      prev.map((n) => (n.id === id ? { ...n, isDue: !n.isDue } : n))
    );
  };

  return (
    <div className="space-y-6 pb-28">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="label text-[#FF5B5B]">Behavioral Prompts</div>
          <h2 className="text-3xl sm:text-4xl font-bold text-[#1C1C1A] tracking-tight">Executive Nudges</h2>
          <p className="text-xs text-[#1C1C1A]/60 font-mono uppercase tracking-wider mt-1">
            Automated environmental triggers for hydration, breaks, and posture
          </p>
        </div>

        <button
          id="nudges-add-btn"
          onClick={() => setShowAdd(!showAdd)}
          className="flex items-center justify-center space-x-2 bg-[#FF5B5B] hover:bg-[#ff4242] text-white px-5 py-3 rounded-full text-xs font-mono font-bold uppercase tracking-wider shadow-sm transition-all cursor-pointer hover:scale-105 active:scale-95"
        >
          <Plus className="w-4 h-4 stroke-[3]" />
          <span>Add Custom Nudge</span>
        </button>
      </div>

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

      {/* Nudges List */}
      <div className="space-y-3">
        {nudges.map((nudge) => (
          <div
            key={nudge.id}
            className={`rounded-3xl p-5 border transition-all flex items-center justify-between gap-4 ${
              nudge.isDue
                ? 'bg-[#EFECE8] border-[#FF5B5B]/40 shadow-sm'
                : 'bg-[#EFECE8]/60 border-black/5 opacity-70'
            }`}
          >
            <div className="flex items-center space-x-3.5">
              <div
                className={`w-11 h-11 rounded-2xl flex items-center justify-center font-bold text-lg border ${
                  nudge.isDue
                    ? 'bg-[#FF5B5B]/10 text-[#FF5B5B] border-[#FF5B5B]/20'
                    : 'bg-white text-[#1C1C1A]/40 border-black/5'
                }`}
              >
                <Bell className="w-5 h-5" />
              </div>

              <div>
                <h4 className="text-base font-bold text-[#1C1C1A]">{nudge.label}</h4>
                <div className="flex items-center space-x-2 text-xs text-[#1C1C1A]/60 font-mono mt-0.5">
                  <Clock className="w-3.5 h-3.5" />
                  <span>{nudge.schedule}</span>
                  {nudge.isDue && (
                    <span className="text-white font-bold bg-[#FF5B5B] px-2.5 py-0.5 rounded-full text-[10px] tracking-wider uppercase font-mono">
                      DUE NOW
                    </span>
                  )}
                </div>
              </div>
            </div>

            <button
              id={`toggle-nudge-${nudge.id}`}
              onClick={() => toggleNudgeDue(nudge.id)}
              className={`px-4 py-2 rounded-full text-xs font-mono font-bold uppercase transition-all cursor-pointer ${
                nudge.isDue
                  ? 'bg-[#111113] hover:bg-black text-white shadow-xs'
                  : 'bg-white hover:bg-black/5 text-[#1C1C1A] border border-black/10'
              }`}
            >
              {nudge.isDue ? 'Dismiss Nudge' : 'Trigger Test Nudge'}
            </button>
          </div>
        ))}
      </div>
    </div>
  );
};
