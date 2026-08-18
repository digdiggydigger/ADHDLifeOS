import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { TaskItem, LifeArea, Tag } from '../types';
import { triggerHaptic, playNudgeChime, formatFocusDuration } from '../utils/haptics';
import { calculateNudgeCheckpoints } from '../hooks/useLifeOSState';
import { X, Play, Clock, CheckCircle2, Trash2, Sparkles, Bell, Volume2, Plus, Minus } from 'lucide-react';

interface TaskDetailModalProps {
  task: TaskItem | null;
  onClose: () => void;
  lifeAreas: LifeArea[];
  tags: Tag[];
  onUpdateTask: (id: string, updates: Partial<TaskItem>) => void;
  onDeleteTask: (id: string) => void;
  onStartFocus: (task: TaskItem, durationSeconds?: number, nudgesCount?: number) => void;
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
  onStartFocus: (task: TaskItem, durationSeconds?: number, nudgesCount?: number) => void;
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

  // Duration in seconds: default from task, or minimum 30s
  const initialDurationSeconds = task.focusDurationSeconds && task.focusDurationSeconds >= 30
    ? task.focusDurationSeconds
    : task.focusMinutesTarget
    ? Math.max(30, Math.round(task.focusMinutesTarget * 60))
    : 15 * 60;

  const [durationSeconds, setDurationSeconds] = useState<number>(initialDurationSeconds);
  const [durationUnit, setDurationUnit] = useState<'minutes' | 'seconds'>(
    initialDurationSeconds < 60 ? 'seconds' : 'minutes'
  );
  const [durationValueInput, setDurationValueInput] = useState<number>(
    initialDurationSeconds < 60 ? initialDurationSeconds : Math.round(initialDurationSeconds / 60)
  );

  // Nudges count during focus session
  const [nudgesCount, setNudgesCount] = useState<number>(
    typeof task.nudgesCount === 'number'
      ? task.nudgesCount
      : initialDurationSeconds <= 60
      ? 1
      : 2
  );

  const [hasTestedChime, setHasTestedChime] = useState(false);

  // Calculate checkpoints for timeline preview
  const checkpoints = calculateNudgeCheckpoints(durationSeconds, nudgesCount);

  const handleDurationChange = (val: number, unit: 'minutes' | 'seconds') => {
    const rawVal = Math.max(1, val);
    setDurationValueInput(rawVal);
    let totalSecs = unit === 'seconds' ? rawVal : rawVal * 60;
    // Enforce minimum 30 seconds
    if (totalSecs < 30) totalSecs = 30;
    setDurationSeconds(totalSecs);
  };

  const handleSelectPreset = (seconds: number) => {
    triggerHaptic('light');
    setDurationSeconds(seconds);
    if (seconds < 60) {
      setDurationUnit('seconds');
      setDurationValueInput(seconds);
    } else {
      setDurationUnit('minutes');
      setDurationValueInput(Math.round(seconds / 60));
    }
  };

  const handleTestChime = () => {
    triggerHaptic('medium');
    playNudgeChime();
    setHasTestedChime(true);
    setTimeout(() => setHasTestedChime(false), 2500);
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    triggerHaptic('success');
    const finalSecs = Math.max(30, durationSeconds);
    const finalMins = Math.max(1, Math.round(finalSecs / 60));

    onUpdateTask(task.id, {
      title,
      description,
      lifeAreaId,
      priority,
      dueDate: dueDate || undefined,
      tags: selectedTags,
      focusDurationSeconds: finalSecs,
      focusMinutesTarget: finalMins,
      nudgesCount,
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
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-xs"
      onClick={onClose}
    >
      <motion.div
        initial={{ opacity: 0, scale: 0.92, y: 16 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.92, y: 16 }}
        transition={{ type: 'spring', stiffness: 320, damping: 26 }}
        onClick={(e) => e.stopPropagation()}
        className="dark-card text-white rounded-[32px] max-w-xl w-full p-6 sm:p-7 shadow-2xl space-y-5 max-h-[92vh] overflow-y-auto"
      >
        {/* Header */}
        <div className="flex items-center justify-between pb-3 border-b border-white/10">
          <div className="flex items-center space-x-3">
            <span className="text-2xl p-1.5 rounded-xl bg-white/10">{area?.emoji || '📝'}</span>
            <div>
              <span className="label text-[#FF5B5B]">Task Specification</span>
              <h3 className="text-xl font-bold text-white tracking-tight">Edit Task & Focus Plan</h3>
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

        {/* Start Focus Timer Hero Callout */}
        <div className="bg-white/5 border border-[#FF5B5B]/30 rounded-3xl p-4 sm:p-5 shadow-sm space-y-3">
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <div className="flex items-center space-x-1.5">
                <Sparkles className="w-4 h-4 text-[#FF5B5B]" />
                <span className="text-xs font-mono uppercase font-bold text-[#FF5B5B]">
                  Launch Focus Sprint
                </span>
              </div>
              <p className="text-xs text-zinc-300 font-mono">
                {formatFocusDuration(durationSeconds)} sprint with {nudgesCount} time-check {nudgesCount === 1 ? 'nudge' : 'nudges'}
              </p>
            </div>

            <button
              id="task-detail-start-focus-btn"
              onClick={() => {
                triggerHaptic('success');
                onStartFocus(task, durationSeconds, nudgesCount);
                onClose();
              }}
              className="flex items-center space-x-2 bg-[#FF5B5B] hover:bg-[#ff4242] text-white px-5 py-2.5 rounded-full text-xs font-mono font-bold uppercase shadow-md transition-all cursor-pointer hover:scale-105 active:scale-95 shrink-0"
            >
              <Play className="w-4 h-4 fill-current" />
              <span>Start {formatFocusDuration(durationSeconds)}</span>
            </button>
          </div>
        </div>

        <form onSubmit={handleSave} className="space-y-5">
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
              placeholder="Break task down into 2-minute starter micro-steps..."
              className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white focus:outline-hidden focus:border-[#FF5B5B] placeholder:text-zinc-400 font-sans"
            />
          </div>

          {/* Photo Note Attachment if present */}
          {task.imageUrl && (
            <div className="p-3 bg-white/5 border border-white/10 rounded-2xl space-y-2">
              <span className="text-[10px] font-mono uppercase tracking-wider text-purple-400 font-bold block">
                Attached Photo Note
              </span>
              <div className="rounded-xl overflow-hidden border border-white/15 bg-black/40 max-h-48 flex items-center justify-center">
                <img
                  src={task.imageUrl}
                  alt={task.title}
                  className="w-full max-h-48 object-contain"
                />
              </div>
            </div>
          )}

          {/* ============================================================ */}
          {/* TARGET FOCUS DURATION & IN-SESSION NUDGES CONFIGURATION */}
          {/* ============================================================ */}
          <div className="bg-black/30 border border-white/10 rounded-3xl p-4 sm:p-5 space-y-4">
            <div className="flex items-center justify-between border-b border-white/10 pb-2.5">
              <div className="flex items-center space-x-2">
                <Clock className="w-4 h-4 text-[#FF5B5B]" />
                <span className="text-xs font-mono uppercase font-bold text-white tracking-wider">
                  Target Focus & Nudges Configuration
                </span>
              </div>
              <span className="text-[11px] font-mono text-[#FF5B5B]">Min. 30 seconds</span>
            </div>

            {/* 1. Target Focus Duration */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <label className="text-xs font-mono text-white/70">
                  1. Target Focus Time: <strong className="text-white">{formatFocusDuration(durationSeconds)}</strong>
                </label>
                <div className="flex items-center bg-white/10 rounded-xl p-0.5 text-[11px] font-mono">
                  <button
                    type="button"
                    onClick={() => {
                      setDurationUnit('seconds');
                      handleDurationChange(durationSeconds, 'seconds');
                    }}
                    className={`px-2.5 py-0.5 rounded-lg transition-colors cursor-pointer ${
                      durationUnit === 'seconds' ? 'bg-[#FF5B5B] text-white font-bold' : 'text-white/60 hover:text-white'
                    }`}
                  >
                    Seconds
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setDurationUnit('minutes');
                      const mins = Math.max(1, Math.round(durationSeconds / 60));
                      handleDurationChange(mins, 'minutes');
                    }}
                    className={`px-2.5 py-0.5 rounded-lg transition-colors cursor-pointer ${
                      durationUnit === 'minutes' ? 'bg-[#FF5B5B] text-white font-bold' : 'text-white/60 hover:text-white'
                    }`}
                  >
                    Minutes
                  </button>
                </div>
              </div>

              {/* Number Input */}
              <div className="flex items-center gap-2">
                <input
                  type="number"
                  min={durationUnit === 'seconds' ? 30 : 0.5}
                  max={durationUnit === 'seconds' ? 7200 : 120}
                  step={durationUnit === 'seconds' ? 5 : 1}
                  id="task-detail-focus-duration-input"
                  value={durationValueInput}
                  onChange={(e) => handleDurationChange(Number(e.target.value), durationUnit)}
                  className="flex-1 px-4 py-2 rounded-2xl bg-white/10 border border-white/10 text-sm font-mono text-white focus:outline-hidden focus:border-[#FF5B5B]"
                />
                <span className="text-xs font-mono text-white/50 w-16">
                  {durationUnit}
                </span>
              </div>

              {/* Quick Preset Buttons (including 30s, 1m, 2m, 5m, 10m, 15m, 25m) */}
              <div className="flex flex-wrap gap-1.5 pt-1">
                {[
                  { label: '30s', secs: 30 },
                  { label: '1m', secs: 60 },
                  { label: '2m', secs: 120 },
                  { label: '5m', secs: 300 },
                  { label: '10m', secs: 600 },
                  { label: '15m', secs: 900 },
                  { label: '25m', secs: 1500 },
                ].map((preset) => (
                  <button
                    key={preset.secs}
                    type="button"
                    id={`duration-preset-${preset.secs}`}
                    onClick={() => handleSelectPreset(preset.secs)}
                    className={`px-3 py-1 rounded-xl text-xs font-mono font-bold transition-all cursor-pointer ${
                      durationSeconds === preset.secs
                        ? 'bg-[#FF5B5B] text-white shadow-xs'
                        : 'bg-white/10 text-white/70 hover:bg-white/20 hover:text-white'
                    }`}
                  >
                    {preset.label}
                  </button>
                ))}
              </div>
            </div>

            {/* 2. Nudges Count During Focus Session */}
            <div className="space-y-2 pt-2 border-t border-white/5">
              <div className="flex items-center justify-between">
                <label className="text-xs font-mono text-white/70 flex items-center space-x-1.5">
                  <Bell className="w-3.5 h-3.5 text-[#FF5B5B]" />
                  <span>2. In-Session Nudges during {formatFocusDuration(durationSeconds)}:</span>
                </label>
                <span className="text-xs font-mono font-bold text-[#FF5B5B]">
                  {nudgesCount === 0 ? 'No nudges' : `${nudgesCount} ${nudgesCount === 1 ? 'Nudge' : 'Nudges'}`}
                </span>
              </div>

              {/* Nudge Preset Segmented Options */}
              <div className="flex items-center gap-1.5 flex-wrap">
                {[0, 1, 2, 3, 4, 5].map((cnt) => (
                  <button
                    key={cnt}
                    type="button"
                    id={`nudges-count-${cnt}`}
                    onClick={() => {
                      triggerHaptic('light');
                      setNudgesCount(cnt);
                    }}
                    className={`px-3 py-1 rounded-xl text-xs font-mono font-bold transition-all cursor-pointer ${
                      nudgesCount === cnt
                        ? 'bg-[#FF5B5B] text-white shadow-xs'
                        : 'bg-white/10 text-white/60 hover:bg-white/20 hover:text-white'
                    }`}
                  >
                    {cnt === 0 ? 'Off (0)' : cnt === 1 ? '1 (Halfway)' : `${cnt} Nudges`}
                  </button>
                ))}

                {/* Custom Stepper */}
                <div className="flex items-center bg-white/10 rounded-xl p-0.5 ml-auto">
                  <button
                    type="button"
                    onClick={() => setNudgesCount(Math.max(0, nudgesCount - 1))}
                    className="p-1 text-white/60 hover:text-white cursor-pointer"
                  >
                    <Minus className="w-3.5 h-3.5" />
                  </button>
                  <span className="px-2 text-xs font-mono font-bold">{nudgesCount}</span>
                  <button
                    type="button"
                    onClick={() => setNudgesCount(Math.min(10, nudgesCount + 1))}
                    className="p-1 text-white/60 hover:text-white cursor-pointer"
                  >
                    <Plus className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>

            {/* 3. Dynamic Nudge Timeline Preview */}
            <div className="bg-white/5 rounded-2xl p-3 space-y-2 border border-white/5">
              <div className="flex items-center justify-between text-[11px] font-mono">
                <span className="text-white/60 uppercase font-bold">Nudge Cadence Timeline</span>
                <button
                  type="button"
                  id="test-nudge-chime-btn"
                  onClick={handleTestChime}
                  className="flex items-center space-x-1 text-[#FF5B5B] hover:text-[#ff7878] cursor-pointer font-bold transition-colors"
                  title="Play synthesized multi-tone chime & vibration"
                >
                  <Volume2 className="w-3 h-3" />
                  <span>{hasTestedChime ? 'Chime Played! 🔔' : 'Test Sound & Vibrate'}</span>
                </button>
              </div>

              {nudgesCount === 0 ? (
                <p className="text-xs text-white/40 font-mono py-1">
                  Silent countdown. No milestone alerts will sound during the sprint.
                </p>
              ) : (
                <div className="space-y-1.5">
                  <div className="flex items-center justify-between text-[10px] font-mono text-zinc-400">
                    <span>Start: 0m</span>
                    <span>Target: {formatFocusDuration(durationSeconds)}</span>
                  </div>

                  {/* Visual timeline bar */}
                  <div className="relative h-2 bg-white/10 rounded-full overflow-hidden">
                    <div className="absolute inset-0 bg-white/5"></div>
                    {checkpoints.map((cp, idx) => {
                      const pos = (cp / durationSeconds) * 100;
                      return (
                        <div
                          key={idx}
                          className="absolute top-0 bottom-0 w-1 bg-[#FF5B5B] rounded-full shadow-[0_0_8px_#FF5B5B]"
                          style={{ left: `${pos}%` }}
                        />
                      );
                    })}
                  </div>

                  {/* List of exact notification timestamps */}
                  <div className="flex flex-wrap gap-1.5 pt-1">
                    {checkpoints.map((cp, idx) => {
                      const pct = Math.round((cp / durationSeconds) * 100);
                      return (
                        <span
                          key={idx}
                          className="text-[10px] font-mono bg-white/10 text-white px-2 py-0.5 rounded-md flex items-center space-x-1"
                        >
                          <span className="text-[#FF5B5B]">🔔</span>
                          <span>Nudge {idx + 1}: @ {formatFocusDuration(cp)} ({pct}%)</span>
                        </span>
                      );
                    })}
                  </div>
                </div>
              )}

              <p className="text-[11px] text-zinc-400 font-sans leading-relaxed pt-1">
                At each checkpoint, a distinct acoustic bell chime and haptic pulse will signal elapsed time so you stay grounded in the micro-step.
              </p>
            </div>
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
              <label className="label text-white/60 mb-1">Priority / Urgency</label>
              <select
                id="task-detail-priority-select"
                value={priority}
                onChange={(e) => setPriority(e.target.value as any)}
                className="w-full px-3.5 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
              >
                <option value="high" className="bg-[#111113]">🔴 High Urgency</option>
                <option value="medium" className="bg-[#111113]">🟡 Medium Urgency</option>
                <option value="low" className="bg-[#111113]">🟢 Low Urgency / Quick Win</option>
              </select>
            </div>
          </div>

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

