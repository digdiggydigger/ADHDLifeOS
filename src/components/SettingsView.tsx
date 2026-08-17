import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { LifeArea, Tag } from '../types';
import {
  Settings,
  Plus,
  RotateCcw,
  Archive,
  ChevronDown,
  ChevronUp,
  FolderTree,
  Tags,
  CheckCircle2,
} from 'lucide-react';

interface SettingsViewProps {
  lifeAreas: LifeArea[];
  setLifeAreas: React.Dispatch<React.SetStateAction<LifeArea[]>>;
  tags: Tag[];
  setTags: React.Dispatch<React.SetStateAction<Tag[]>>;
  onResetAllData: () => void;
}

const colorOptions = ['indigo', 'emerald', 'amber', 'purple', 'rose', 'sky'];
const emojiOptions = ['💼', '🏋️', '📝', '🧘', '🎨', '🏠', '🚀', '📚', '💰', '🌱', '⚡', '☕'];

export const SettingsView: React.FC<SettingsViewProps> = ({
  lifeAreas,
  setLifeAreas,
  tags,
  setTags,
  onResetAllData,
}) => {
  // Collapsible state for each section (default collapsed, can toggle)
  const [isLifeAreasOpen, setIsLifeAreasOpen] = useState(false);
  const [isTagsOpen, setIsTagsOpen] = useState(false);

  const [showAddArea, setShowAddArea] = useState(false);
  const [newAreaName, setNewAreaName] = useState('');
  const [newAreaEmoji, setNewAreaEmoji] = useState('💼');
  const [newAreaColor, setNewAreaColor] = useState('indigo');

  const [showAddTag, setShowAddTag] = useState(false);
  const [newTagName, setNewTagName] = useState('');

  // Stats calculation
  const totalAreas = lifeAreas.length;
  const activeAreasCount = lifeAreas.filter((a) => !a.isArchived).length;
  const archivedAreasCount = lifeAreas.filter((a) => a.isArchived).length;
  const totalTags = tags.length;

  const handleCreateArea = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newAreaName.trim()) return;

    const newArea: LifeArea = {
      id: 'area-' + Date.now(),
      name: newAreaName.trim(),
      emoji: newAreaEmoji,
      color: newAreaColor,
      sortOrder: lifeAreas.length + 1,
      isArchived: false,
    };

    setLifeAreas((prev) => [...prev, newArea]);
    setNewAreaName('');
    setShowAddArea(false);
  };

  const toggleArchiveArea = (id: string) => {
    setLifeAreas((prev) =>
      prev.map((a) => (a.id === id ? { ...a, isArchived: !a.isArchived } : a))
    );
  };

  const handleCreateTag = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTagName.trim()) return;

    const newTag: Tag = {
      id: 'tag-' + Date.now(),
      name: newTagName.trim().toLowerCase().replace(/\s+/g, '-'),
      color: 'indigo',
    };

    setTags((prev) => [...prev, newTag]);
    setNewTagName('');
    setShowAddTag(false);
  };

  const handleDeleteTag = (id: string) => {
    setTags((prev) => prev.filter((t) => t.id !== id));
  };

  return (
    <div className="space-y-8 pb-28">
      <div>
        <div className="label text-[#FF5B5B]">Configuration</div>
        <h2 className="text-3xl sm:text-4xl font-bold text-[#1C1C1A] tracking-tight">
          System Settings & Taxonomy
        </h2>
        <p className="text-xs text-[#1C1C1A]/60 font-mono uppercase tracking-wider mt-1">
          Manage Life Areas, contextual tags, and reset preferences
        </p>
      </div>

      {/* Life Area Domains Section */}
      <div className="light-card rounded-[32px] p-6 sm:p-8 shadow-xs space-y-5 transition-all">
        <div className="flex items-center justify-between pb-4 border-b border-black/5">
          <div
            onClick={() => setIsLifeAreasOpen((prev) => !prev)}
            className="flex items-center space-x-3 cursor-pointer select-none group"
            id="settings-toggle-life-areas"
          >
            <div className="p-2 rounded-2xl bg-black/5 group-hover:bg-black/10 transition-colors">
              <FolderTree className="w-5 h-5 text-[#1C1C1A]" />
            </div>
            <div>
              <div className="flex items-center space-x-2">
                <h3 className="text-lg font-bold text-[#1C1C1A]">Life Area Domains</h3>
                <span className="p-1 rounded-full text-[#1C1C1A]/40 group-hover:text-[#1C1C1A] transition-transform">
                  {isLifeAreasOpen ? (
                    <ChevronUp className="w-4 h-4" />
                  ) : (
                    <ChevronDown className="w-4 h-4" />
                  )}
                </span>
              </div>
              <p className="text-xs text-[#1C1C1A]/60 font-mono">
                {isLifeAreasOpen
                  ? 'Add, edit, or archive life domains'
                  : `${totalAreas} Total Domains • ${activeAreasCount} Active • ${archivedAreasCount} Archived`}
              </p>
            </div>
          </div>

          <div className="flex items-center space-x-2">
            <button
              type="button"
              id="settings-add-area-btn"
              onClick={() => {
                setIsLifeAreasOpen(true);
                setShowAddArea((prev) => !prev);
              }}
              className="flex items-center space-x-1.5 bg-[#FF5B5B] hover:bg-[#ff4242] text-white px-3.5 sm:px-4 py-2 rounded-full text-xs font-mono font-bold uppercase shadow-sm transition-all cursor-pointer hover:scale-105"
            >
              <Plus className="w-4 h-4 stroke-[3]" />
              <span>Add Life Area</span>
            </button>
          </div>
        </div>

        {/* Collapsed Stats Summary for Life Areas */}
        {!isLifeAreasOpen && (
          <motion.div
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.2 }}
            className="space-y-4 pt-1"
          >
            {/* Metric counters */}
            <div className="grid grid-cols-3 gap-3">
              <div className="bg-white/80 rounded-2xl p-3.5 border border-black/5 flex flex-col justify-center">
                <span className="text-[10px] font-mono uppercase text-[#1C1C1A]/60 font-bold">
                  Total Areas
                </span>
                <span className="text-2xl font-bold font-mono text-[#1C1C1A]">
                  {totalAreas}
                </span>
              </div>

              <div className="bg-white/80 rounded-2xl p-3.5 border border-black/5 flex flex-col justify-center">
                <span className="text-[10px] font-mono uppercase text-[#1C1C1A]/60 font-bold">
                  Active
                </span>
                <span className="text-2xl font-bold font-mono text-[#1C1C1A]">
                  {activeAreasCount}
                </span>
              </div>

              <div className="bg-white/80 rounded-2xl p-3.5 border border-black/5 flex flex-col justify-center">
                <span className="text-[10px] font-mono uppercase text-[#1C1C1A]/60 font-bold">
                  Archived
                </span>
                <span className="text-2xl font-bold font-mono text-[#1C1C1A]/50">
                  {archivedAreasCount}
                </span>
              </div>
            </div>

            {/* Quick Preview Chips */}
            <div className="flex flex-wrap gap-2 pt-1 items-center">
              <span className="text-xs font-mono text-[#1C1C1A]/50">Domains:</span>
              {lifeAreas.map((area) => (
                <span
                  key={area.id}
                  className={`inline-flex items-center space-x-1.5 px-3 py-1 rounded-full text-xs font-medium border ${
                    area.isArchived
                      ? 'bg-black/5 border-black/5 text-[#1C1C1A]/40 line-through'
                      : 'bg-white border-black/5 text-[#1C1C1A] shadow-xs'
                  }`}
                >
                  <span>{area.emoji}</span>
                  <span className="font-semibold">{area.name}</span>
                </span>
              ))}
            </div>
          </motion.div>
        )}

        {/* Expanded View for Life Areas */}
        <AnimatePresence>
          {isLifeAreasOpen && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              transition={{ duration: 0.25 }}
              className="space-y-5 overflow-hidden"
            >
              {showAddArea && (
                <form
                  onSubmit={handleCreateArea}
                  className="dark-card text-white rounded-3xl p-5 space-y-4 shadow-lg"
                >
                  <div>
                    <label className="label text-white/60 mb-1">Area Name</label>
                    <input
                      type="text"
                      required
                      id="settings-area-name-input"
                      value={newAreaName}
                      onChange={(e) => setNewAreaName(e.target.value)}
                      placeholder="E.g. Side Hustle, Deep Work, Health"
                      className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm font-semibold text-white focus:outline-hidden focus:border-[#FF5B5B] placeholder:text-zinc-400"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="label text-white/60 mb-1">Emoji Icon</label>
                      <div className="flex flex-wrap gap-1 bg-white/5 p-2 rounded-2xl border border-white/10">
                        {emojiOptions.map((emoji) => (
                          <button
                            key={emoji}
                            type="button"
                            onClick={() => setNewAreaEmoji(emoji)}
                            className={`w-8 h-8 text-lg rounded-xl flex items-center justify-center cursor-pointer ${
                              newAreaEmoji === emoji ? 'bg-[#FF5B5B] text-white' : 'hover:bg-white/10'
                            }`}
                          >
                            {emoji}
                          </button>
                        ))}
                      </div>
                    </div>

                    <div>
                      <label className="label text-white/60 mb-1">Color Theme</label>
                      <select
                        id="settings-area-color-select"
                        value={newAreaColor}
                        onChange={(e) => setNewAreaColor(e.target.value)}
                        className="w-full px-3.5 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
                      >
                        {colorOptions.map((c) => (
                          <option key={c} value={c} className="bg-[#111113]">
                            {c.toUpperCase()}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>

                  <div className="flex justify-end space-x-2 pt-2">
                    <button
                      type="button"
                      onClick={() => setShowAddArea(false)}
                      className="px-4 py-1.5 text-xs font-mono uppercase text-white/60 hover:text-white rounded-full cursor-pointer"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      id="settings-area-submit-btn"
                      className="px-5 py-1.5 text-xs font-mono font-bold uppercase bg-[#FF5B5B] text-white rounded-full shadow-sm cursor-pointer"
                    >
                      Save Area
                    </button>
                  </div>
                </form>
              )}

              {/* Life Areas List */}
              <div className="space-y-2.5">
                {lifeAreas.map((area) => (
                  <div
                    key={area.id}
                    className={`p-4 rounded-2xl border flex items-center justify-between transition-all ${
                      area.isArchived
                        ? 'bg-black/5 border-black/5 opacity-60'
                        : 'bg-white border-black/5 shadow-xs'
                    }`}
                  >
                    <div className="flex items-center space-x-3">
                      <span className="text-2xl p-1.5 rounded-xl bg-black/5">{area.emoji}</span>
                      <div>
                        <h4 className="text-sm font-bold text-[#1C1C1A]">{area.name}</h4>
                        <span className="text-[11px] font-mono text-[#1C1C1A]/50 capitalize">
                          Color: {area.color} {area.isArchived ? '• Archived' : '• Active'}
                        </span>
                      </div>
                    </div>

                    <button
                      id={`toggle-archive-area-${area.id}`}
                      onClick={() => toggleArchiveArea(area.id)}
                      className={`flex items-center space-x-1 px-3.5 py-1.5 rounded-full text-xs font-mono font-bold uppercase transition-all cursor-pointer ${
                        area.isArchived
                          ? 'bg-[#FF5B5B]/20 text-[#FF5B5B]'
                          : 'bg-black/5 text-[#1C1C1A] hover:bg-black/10'
                      }`}
                    >
                      <Archive className="w-3.5 h-3.5" />
                      <span>{area.isArchived ? 'Unarchive' : 'Archive'}</span>
                    </button>
                  </div>
                ))}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Tag Registry Section */}
      <div className="light-card rounded-[32px] p-6 sm:p-8 shadow-xs space-y-5 transition-all">
        <div className="flex items-center justify-between pb-4 border-b border-black/5">
          <div
            onClick={() => setIsTagsOpen((prev) => !prev)}
            className="flex items-center space-x-3 cursor-pointer select-none group"
            id="settings-toggle-tags"
          >
            <div className="p-2 rounded-2xl bg-black/5 group-hover:bg-black/10 transition-colors">
              <Tags className="w-5 h-5 text-[#1C1C1A]" />
            </div>
            <div>
              <div className="flex items-center space-x-2">
                <h3 className="text-lg font-bold text-[#1C1C1A]">Tag Registry</h3>
                <span className="p-1 rounded-full text-[#1C1C1A]/40 group-hover:text-[#1C1C1A] transition-transform">
                  {isTagsOpen ? (
                    <ChevronUp className="w-4 h-4" />
                  ) : (
                    <ChevronDown className="w-4 h-4" />
                  )}
                </span>
              </div>
              <p className="text-xs text-[#1C1C1A]/60 font-mono">
                {isTagsOpen
                  ? 'Organize ADHD context tags & energy labels'
                  : `${totalTags} Registered Tags`}
              </p>
            </div>
          </div>

          <div className="flex items-center space-x-2">
            <button
              type="button"
              id="settings-add-tag-btn"
              onClick={() => {
                setIsTagsOpen(true);
                setShowAddTag((prev) => !prev);
              }}
              className="flex items-center space-x-1.5 bg-[#FF5B5B] hover:bg-[#ff4242] text-white px-3.5 sm:px-4 py-2 rounded-full text-xs font-mono font-bold uppercase shadow-sm cursor-pointer transition-all hover:scale-105"
            >
              <Plus className="w-4 h-4 stroke-[3]" />
              <span>Add Tag</span>
            </button>
          </div>
        </div>

        {/* Collapsed Stats Summary for Tags */}
        {!isTagsOpen && (
          <motion.div
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.2 }}
            className="space-y-4 pt-1"
          >
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              <div className="bg-white/80 rounded-2xl p-3.5 border border-black/5 flex flex-col justify-center">
                <span className="text-[10px] font-mono uppercase text-[#1C1C1A]/60 font-bold">
                  Total Tags
                </span>
                <span className="text-2xl font-bold font-mono text-[#1C1C1A]">
                  {totalTags}
                </span>
              </div>

              <div className="bg-white/80 rounded-2xl p-3.5 border border-black/5 flex flex-col justify-center">
                <span className="text-[10px] font-mono uppercase text-[#1C1C1A]/60 font-bold">
                  Classification
                </span>
                <span className="text-xs font-mono font-semibold text-[#1C1C1A]/70 mt-1">
                  Contexts & Energy
                </span>
              </div>

              <div className="hidden sm:flex bg-white/80 rounded-2xl p-3.5 border border-black/5 flex-col justify-center">
                <span className="text-[10px] font-mono uppercase text-[#1C1C1A]/60 font-bold">
                  Active Filter
                </span>
                <span className="text-xs font-mono font-semibold text-[#1C1C1A]/70 mt-1">
                  Global Taxonomy
                </span>
              </div>
            </div>

            {/* Quick tag preview chips */}
            <div className="flex flex-wrap gap-1.5 pt-1 items-center">
              <span className="text-xs font-mono text-[#1C1C1A]/50">Registered:</span>
              {tags.map((tag) => (
                <span
                  key={tag.id}
                  className="bg-white text-[#1C1C1A] font-mono font-bold px-2.5 py-1 rounded-full text-[11px] border border-black/5 shadow-xs"
                >
                  #{tag.name}
                </span>
              ))}
            </div>
          </motion.div>
        )}

        {/* Expanded View for Tags */}
        <AnimatePresence>
          {isTagsOpen && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              transition={{ duration: 0.25 }}
              className="space-y-4 overflow-hidden"
            >
              {showAddTag && (
                <form
                  onSubmit={handleCreateTag}
                  className="dark-card text-white rounded-3xl p-4 space-y-3 shadow-lg"
                >
                  <div>
                    <label className="label text-white/60 mb-1">Tag Name</label>
                    <input
                      type="text"
                      required
                      id="settings-tag-name-input"
                      value={newTagName}
                      onChange={(e) => setNewTagName(e.target.value)}
                      placeholder="E.g. low-dopamine, 2-min-step"
                      className="w-full px-4 py-2 rounded-2xl bg-white/10 border border-white/10 text-sm font-semibold text-white focus:outline-hidden focus:border-[#FF5B5B] placeholder:text-zinc-400"
                    />
                  </div>

                  <div className="flex justify-end space-x-2 pt-2">
                    <button
                      type="button"
                      onClick={() => setShowAddTag(false)}
                      className="px-3 py-1.5 text-xs font-mono uppercase text-white/60 hover:text-white rounded-full cursor-pointer"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      id="settings-tag-submit-btn"
                      className="px-5 py-1.5 text-xs font-mono font-bold uppercase bg-[#FF5B5B] text-white rounded-full shadow-sm cursor-pointer"
                    >
                      Save Tag
                    </button>
                  </div>
                </form>
              )}

              <div className="flex flex-wrap gap-2">
                {tags.map((tag) => (
                  <div
                    key={tag.id}
                    className="bg-white text-[#1C1C1A] font-mono font-bold px-3.5 py-1.5 rounded-full text-xs flex items-center space-x-2 border border-black/5 shadow-xs transition-all hover:border-black/20"
                  >
                    <span>#{tag.name}</span>
                    <button
                      id={`delete-tag-${tag.id}`}
                      onClick={() => handleDeleteTag(tag.id)}
                      className="text-[#1C1C1A]/40 hover:text-[#FF5B5B] cursor-pointer ml-1"
                      title="Delete tag"
                    >
                      ✕
                    </button>
                  </div>
                ))}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Reset System Data */}
      <div className="bg-[#FF5B5B]/10 rounded-[32px] p-6 sm:p-8 border border-[#FF5B5B]/20 space-y-3">
        <div className="flex items-center space-x-2 text-[#FF5B5B] font-bold">
          <RotateCcw className="w-5 h-5 text-[#FF5B5B]" />
          <h3 className="text-lg">Restore Default Workspace</h3>
        </div>
        <p className="text-xs text-[#1C1C1A]/70 font-mono">
          Resets all tasks, captures, journal entries, and life areas back to starter defaults.
        </p>
        <button
          id="settings-reset-all-btn"
          onClick={() => {
            onResetAllData();
          }}
          className="bg-[#FF5B5B] hover:bg-[#ff4242] text-white px-5 py-2.5 rounded-full text-xs font-mono font-bold uppercase shadow-sm transition-colors cursor-pointer"
        >
          Reset All Workspace Data
        </button>
      </div>
    </div>
  );
};

