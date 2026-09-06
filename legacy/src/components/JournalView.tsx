import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { JournalEntry, LifeArea, Tag, EnergyLevel } from '../types';
import { BookOpen, Plus, Sparkles } from 'lucide-react';

interface JournalViewProps {
  journal: JournalEntry[];
  lifeAreas: LifeArea[];
  tags: Tag[];
  onAddJournalEntry: (entry: Omit<JournalEntry, 'id' | 'createdAt'>) => void;
}

const moodOptions = ['⚡', '🔥', '🧘', '🔋', '😴', '🧠', '🌊', '🎯'];

export const JournalView: React.FC<JournalViewProps> = ({
  journal,
  lifeAreas,
  tags,
  onAddJournalEntry,
}) => {
  const [showComposer, setShowComposer] = useState(false);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [selectedLifeAreaId, setSelectedLifeAreaId] = useState(lifeAreas[0]?.id || '');
  const [energyLevel, setEnergyLevel] = useState<EnergyLevel>('medium');
  const [selectedMood, setSelectedMood] = useState('⚡');
  const [selectedTags, setSelectedTags] = useState<string[]>([]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !content.trim()) return;

    onAddJournalEntry({
      title: title.trim(),
      content: content.trim(),
      lifeAreaId: selectedLifeAreaId,
      energyLevel,
      moodEmoji: selectedMood,
      tags: selectedTags,
    });

    setTitle('');
    setContent('');
    setShowComposer(false);
  };

  return (
    <div className="space-y-6 pb-28">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="label text-[#FF5B5B]">Reflective State</div>
          <h2 className="text-3xl sm:text-4xl font-bold text-[#1C1C1A] tracking-tight">Journal & Reflections</h2>
          <p className="text-xs text-[#1C1C1A]/60 font-mono uppercase tracking-wider mt-1">
            Track energy levels, mood cycles, and ADHD hyperfocus observations
          </p>
        </div>

        <button
          id="journal-new-log-btn"
          onClick={() => setShowComposer(!showComposer)}
          className="flex items-center justify-center space-x-2 bg-[#FF5B5B] hover:bg-[#ff4242] text-white px-5 py-3 rounded-full text-xs font-mono font-bold uppercase tracking-wider shadow-sm transition-all cursor-pointer hover:scale-105 active:scale-95"
        >
          <Plus className="w-4 h-4 stroke-[3]" />
          <span>New Reflection Log</span>
        </button>
      </div>

      {/* New Log Composer */}
      <AnimatePresence>
        {showComposer && (
          <motion.form
            initial={{ opacity: 0, height: 0, scale: 0.98 }}
            animate={{ opacity: 1, height: 'auto', scale: 1 }}
            exit={{ opacity: 0, height: 0, scale: 0.98 }}
            transition={{ type: 'spring', stiffness: 320, damping: 28 }}
            onSubmit={handleSubmit}
            className="dark-card text-white rounded-[32px] p-6 sm:p-7 shadow-xl space-y-4 overflow-hidden"
          >
            <div className="flex items-center space-x-2 pb-2 border-b border-white/10">
              <Sparkles className="w-5 h-5 text-[#FF5B5B]" />
              <h3 className="text-xl font-bold text-white">Add Log Entry</h3>
            </div>

            <div>
              <label className="label text-white/60 mb-1">Title</label>
              <input
                type="text"
                required
                id="journal-title-input"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="E.g., Midday energy check-in or hyperfocus sprint notes"
                className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm font-semibold text-white focus:outline-hidden focus:border-[#FF5B5B] placeholder:text-zinc-400"
              />
            </div>

            <div>
              <label className="label text-white/60 mb-1">
                Reflection Content
              </label>
              <textarea
                rows={3}
                required
                id="journal-content-input"
                value={content}
                onChange={(e) => setContent(e.target.value)}
                placeholder="What worked? Where was friction? Note dopamine patterns..."
                className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white focus:outline-hidden focus:border-[#FF5B5B] placeholder:text-zinc-400"
              />
            </div>

            {/* Energy & Mood selection */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <label className="label text-white/60 mb-1">Life Area</label>
                <select
                  id="journal-area-select"
                  value={selectedLifeAreaId}
                  onChange={(e) => setSelectedLifeAreaId(e.target.value)}
                  className="w-full px-3.5 py-2 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
                >
                  {lifeAreas.map((a) => (
                    <option key={a.id} value={a.id} className="bg-[#111113]">
                      {a.emoji} {a.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="label text-white/60 mb-1">Energy Level</label>
                <select
                  id="journal-energy-select"
                  value={energyLevel}
                  onChange={(e) => setEnergyLevel(e.target.value as EnergyLevel)}
                  className="w-full px-3.5 py-2 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
                >
                  <option value="low" className="bg-[#111113]">🪫 Low Energy / Fatigue</option>
                  <option value="medium" className="bg-[#111113]">⚡ Medium Steady Energy</option>
                  <option value="high" className="bg-[#111113]">🔥 High Energy / Hyperfocus</option>
                </select>
              </div>

              <div>
                <label className="label text-white/60 mb-1">Mood Emoji</label>
                <div className="flex items-center space-x-1.5 overflow-x-auto py-1">
                  {moodOptions.map((emoji) => (
                    <button
                      key={emoji}
                      type="button"
                      onClick={() => setSelectedMood(emoji)}
                      className={`w-9 h-9 rounded-xl text-lg flex items-center justify-center transition-all cursor-pointer ${
                        selectedMood === emoji
                          ? 'bg-[#FF5B5B] text-white scale-110 shadow-sm'
                          : 'hover:bg-white/10 border border-transparent'
                      }`}
                    >
                      {emoji}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <div className="flex items-center justify-end space-x-3 pt-3">
              <button
                type="button"
                onClick={() => setShowComposer(false)}
                className="px-4 py-2 text-xs font-mono uppercase text-white/60 hover:text-white rounded-full cursor-pointer font-bold"
              >
                Cancel
              </button>
              <button
                type="submit"
                id="journal-submit-btn"
                className="px-6 py-2.5 text-xs font-mono font-bold uppercase bg-[#FF5B5B] hover:bg-[#ff4242] text-white rounded-full shadow-md cursor-pointer transition-all"
              >
                Save Journal Entry
              </button>
            </div>
          </motion.form>
        )}
      </AnimatePresence>

      {/* Journal Entries List */}
      <div className="space-y-4">
        {journal.map((entry) => {
          const area = lifeAreas.find((a) => a.id === entry.lifeAreaId);

          return (
            <div
              key={entry.id}
              className="light-card rounded-3xl p-6 shadow-xs hover:border-black/20 transition-all space-y-3"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <span className="text-3xl p-2 rounded-2xl bg-white border border-black/5">{entry.moodEmoji}</span>
                  <div>
                    <h3 className="text-base sm:text-lg font-bold text-[#1C1C1A]">{entry.title}</h3>
                    <div className="flex items-center space-x-2 text-xs text-[#1C1C1A]/60 font-mono">
                      {area && (
                        <span>
                          {area.emoji} {area.name}
                        </span>
                      )}
                      <span>•</span>
                      <span>{new Date(entry.createdAt).toLocaleDateString()}</span>
                    </div>
                  </div>
                </div>

                <span
                  className={`text-xs font-mono font-bold uppercase px-3 py-1 rounded-full ${
                    entry.energyLevel === 'high'
                      ? 'bg-[#FF5B5B]/15 text-[#FF5B5B]'
                      : entry.energyLevel === 'medium'
                      ? 'bg-amber-500/15 text-amber-800'
                      : 'bg-black/5 text-[#1C1C1A]/70'
                  }`}
                >
                  {entry.energyLevel} energy
                </span>
              </div>

              <p className="text-sm text-[#1C1C1A]/85 leading-relaxed bg-white/80 p-4 rounded-2xl border border-black/5 font-sans">
                {entry.content}
              </p>
            </div>
          );
        })}
      </div>
    </div>
  );
};
