import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { TaskItem, LifeArea, Tag } from '../types';
import { X, Play, Clock, CheckCircle2, Trash2, Sparkles } from 'lucide-react';

interface TaskDetailModalProps {
  task: TaskItem | null;
  onClose: () => void;
  lifeAreas: LifeArea[];
  tags: Tag[];
  onUpdateTask: (id: string, updates: Partial<TaskItem>) => void;
  onDeleteTask: (id: string) => void;
  onStartFocus: (task: TaskItem, durationMinutes: number) => void;
}

export const TaskDetailModal: React.FC<TaskDetailModalProps> = ({
  task,
  onClose,
  lifeAreas,
  tags,
  onUpdateTask,
  onDeleteTask,
  onStartFocus,
}) => {
  return (
    <AnimatePresence>
      {task && (
        <TaskDetailModalContent
          key={task.id}
          task={task}
          onClose={onClose}
          lifeAreas={lifeAreas}
          tags={tags}
          onUpdateTask={onUpdateTask}
          onDeleteTask={onDeleteTask}
          onStartFocus={onStartFocus}
        />
      )}
    </AnimatePresence>
  );
};

const TaskDetailModalContent: React.FC<{
  task: TaskItem;
  onClose: () => void;
  lifeAreas: LifeArea[];
  tags: Tag[];
  onUpdateTask: (id: string, updates: Partial<TaskItem>) => void;
  onDeleteTask: (id: string) => void;
  onStartFocus: (task: TaskItem, durationMinutes: number) => void;
}> = ({
  task,
  onClose,
  lifeAreas,
  tags,
  onUpdateTask,
  onDeleteTask,
  onStartFocus,
}) => {
  const [title, setTitle] = useState(task.title);
  const [description, setDescription] = useState(task.description || '');
  const [lifeAreaId, setLifeAreaId] = useState(task.lifeAreaId);
  const [priority, setPriority] = useState(task.priority);
  const [dueDate, setDueDate] = useState(task.dueDate || '');
  const [selectedTags, setSelectedTags] = useState<string[]>(task.tags || []);
  const [focusTarget, setFocusTarget] = useState<number>(task.focusMinutesTarget || 15);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    onUpdateTask(task.id, {
      title,
      description,
      lifeAreaId,
      priority,
      dueDate: dueDate || undefined,
      tags: selectedTags,
      focusMinutesTarget: focusTarget,
    });
    onClose();
  };

  const toggleTag = (tagName: string) => {
    setSelectedTags((prev) =>
      prev.includes(tagName) ? prev.filter((t) => t !== tagName) : [...prev, tagName]
    );
  };

  const area = lifeAreas.find((a) => a.id === lifeAreaId);

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
      onClick={onClose}
    >
      <motion.div
        initial={{ opacity: 0, scale: 0.92, y: 16 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.92, y: 16 }}
        transition={{ type: 'spring', stiffness: 320, damping: 26 }}
        onClick={(e) => e.stopPropagation()}
        className="dark-card text-white rounded-[32px] max-w-lg w-full p-6 sm:p-7 shadow-2xl space-y-5 max-h-[90vh] overflow-y-auto"
      >
        {/* Header */}
        <div className="flex items-center justify-between pb-3 border-b border-white/10">
          <div className="flex items-center space-x-3">
            <span className="text-2xl p-1.5 rounded-xl bg-white/10">{area?.emoji || '📝'}</span>
            <div>
              <span className="label text-[#FF5B5B]">Task Specification</span>
              <h3 className="text-xl font-bold text-white tracking-tight">Edit Task & Focus</h3>
            </div>
          </div>
          <button
            id="task-detail-close-btn"
            onClick={onClose}
            className="p-1 rounded-full text-white/50 hover:text-white cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Start Focus Timer Callout */}
        <div className="bg-white/5 border border-[#FF5B5B]/30 rounded-2xl p-4 shadow-sm flex items-center justify-between">
          <div className="space-y-0.5">
            <div className="flex items-center space-x-1.5">
              <Sparkles className="w-4 h-4 text-[#FF5B5B]" />
              <span className="text-xs font-mono uppercase font-bold text-[#FF5B5B]">Focus Session</span>
            </div>
            <p className="text-xs text-zinc-300 font-mono">
              Start {focusTarget}m sprint countdown
            </p>
          </div>

          <button
            id="task-detail-start-focus-btn"
            onClick={() => {
              onStartFocus(task, focusTarget);
              onClose();
            }}
            className="flex items-center space-x-2 bg-[#FF5B5B] hover:bg-[#ff4242] text-white px-4 py-2 rounded-full text-xs font-mono font-bold uppercase shadow-sm transition-all cursor-pointer hover:scale-105 shrink-0"
          >
            <Play className="w-4 h-4 fill-current" />
            <span>Start {focusTarget}m</span>
          </button>
        </div>

        <form onSubmit={handleSave} className="space-y-4">
          <div>
            <label className="label text-white/60 mb-1">Title</label>
            <input
              type="text"
              required
              id="task-detail-title-input"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm font-semibold text-white focus:outline-hidden focus:border-[#FF5B5B]"
            />
          </div>

          <div>
            <label className="label text-white/60 mb-1">
              Micro-steps & Description
            </label>
            <textarea
              rows={3}
              id="task-detail-desc-input"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Break task down into 2-minute starter steps..."
              className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white focus:outline-hidden focus:border-[#FF5B5B] placeholder:text-zinc-400"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label text-white/60 mb-1">Life Area</label>
              <select
                id="task-detail-area-select"
                value={lifeAreaId}
                onChange={(e) => setLifeAreaId(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
              >
                {lifeAreas.map((a) => (
                  <option key={a.id} value={a.id} className="bg-[#111113]">
                    {a.emoji} {a.name}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="label text-white/60 mb-1">Priority Level</label>
              <select
                id="task-detail-priority-select"
                value={priority}
                onChange={(e) => setPriority(e.target.value as any)}
                className="w-full px-3.5 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
              >
                <option value="low" className="bg-[#111113]">Low / Quick Win</option>
                <option value="medium" className="bg-[#111113]">Medium Focus</option>
                <option value="high" className="bg-[#111113]">High Energy Required</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label text-white/60 mb-1">Due Date</label>
              <input
                type="date"
                id="task-detail-due-date"
                value={dueDate}
                onChange={(e) => setDueDate(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
              />
            </div>

            <div>
              <label className="label text-white/60 mb-1">
                Target Focus Mins
              </label>
              <input
                type="number"
                min={5}
                max={180}
                step={5}
                id="task-detail-focus-mins"
                value={focusTarget}
                onChange={(e) => setFocusTarget(Number(e.target.value))}
                className="w-full px-3.5 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
              />
            </div>
          </div>

          {/* Tags */}
          <div>
            <label className="label text-white/60 mb-1">Tags</label>
            <div className="flex flex-wrap gap-1.5 font-mono">
              {tags.map((tag) => {
                const selected = selectedTags.includes(tag.name);
                return (
                  <button
                    key={tag.id}
                    type="button"
                    onClick={() => toggleTag(tag.name)}
                    className={`px-3 py-1 rounded-full text-xs font-bold transition-colors cursor-pointer ${
                      selected
                        ? 'bg-[#FF5B5B] text-white'
                        : 'bg-white/10 text-white/60 hover:text-white'
                    }`}
                  >
                    #{tag.name}
                  </button>
                );
              })}
            </div>
          </div>

          <div className="flex items-center justify-between pt-4 border-t border-white/10">
            <button
              type="button"
              id="task-detail-delete-btn"
              onClick={() => {
                onDeleteTask(task.id);
                onClose();
              }}
              className="flex items-center space-x-1.5 text-xs font-mono text-[#FF5B5B] hover:underline font-bold p-2 rounded-lg cursor-pointer"
            >
              <Trash2 className="w-4 h-4" />
              <span>Delete Task</span>
            </button>

            <div className="flex items-center space-x-2">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 text-xs font-mono uppercase text-white/60 hover:text-white rounded-full cursor-pointer font-bold"
              >
                Cancel
              </button>
              <button
                type="submit"
                id="task-detail-save-btn"
                className="px-6 py-2 text-xs font-mono font-bold uppercase bg-[#FF5B5B] hover:bg-[#ff4242] text-white rounded-full shadow-xs cursor-pointer transition-all"
              >
                Save Changes
              </button>
            </div>
          </div>
        </form>
      </motion.div>
    </motion.div>
  );
};
