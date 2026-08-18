import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { TaskItem, LifeArea, Tag, TaskStatus, TaskPriority } from '../types';
import { TaskDetailModal } from './TaskDetailModal';
import { triggerHaptic, formatFocusDuration } from '../utils/haptics';
import {
  CheckSquare,
  Plus,
  Search,
  Clock,
  Play,
  CheckCircle2,
  Circle,
  X,
  AlertCircle,
  Flame,
  ArrowUpDown,
  Bell,
} from 'lucide-react';

interface TaskListViewProps {
  tasks: TaskItem[];
  lifeAreas: LifeArea[];
  tags: Tag[];
  onToggleTaskStatus: (taskId: string) => void;
  onAddTask: (task: Omit<TaskItem, 'id' | 'createdAt' | 'focusMinutesLogged'>) => void;
  onUpdateTask: (id: string, updates: Partial<TaskItem>) => void;
  onDeleteTask: (id: string) => void;
  onStartFocus: (task: TaskItem, durationSeconds?: number, nudgesCount?: number) => void;
  selectedLifeAreaId?: string;
  onClearLifeAreaFilter?: () => void;
}

export const TaskListView: React.FC<TaskListViewProps> = ({
  tasks,
  lifeAreas,
  tags,
  onToggleTaskStatus,
  onAddTask,
  onUpdateTask,
  onDeleteTask,
  onStartFocus,
  selectedLifeAreaId,
  onClearLifeAreaFilter,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | TaskStatus>('all');
  const [priorityFilter, setPriorityFilter] = useState<'all' | TaskPriority>('all');
  const [lifeAreaFilter, setLifeAreaFilter] = useState<string>(selectedLifeAreaId || 'all');
  const [sortBy, setSortBy] = useState<'default' | 'priority' | 'due'>('default');

  const [inspectingTask, setInspectingTask] = useState<TaskItem | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);

  // Inline quick-add state
  const [inlineTitle, setInlineTitle] = useState('');
  const [inlinePriority, setInlinePriority] = useState<TaskPriority>('medium');
  const [inlineAreaId, setInlineAreaId] = useState(lifeAreas[0]?.id || 'area-1');

  // Modal new task form state
  const [newTitle, setNewTitle] = useState('');
  const [newDesc, setNewDesc] = useState('');
  const [newAreaId, setNewAreaId] = useState(lifeAreas[0]?.id || '');
  const [newPriority, setNewPriority] = useState<TaskPriority>('medium');
  const [newDueDate, setNewDueDate] = useState(new Date().toISOString().split('T')[0]);

  const handleInlineQuickAdd = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inlineTitle.trim()) return;

    triggerHaptic('capture');
    onAddTask({
      title: inlineTitle.trim(),
      lifeAreaId: inlineAreaId || lifeAreas[0]?.id || 'area-1',
      status: 'todo',
      priority: inlinePriority,
      dueDate: new Date().toISOString().split('T')[0],
      tags: [],
      focusMinutesTarget: 15,
    });

    setInlineTitle('');
  };

  const handleCreateTaskSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle.trim() || !newAreaId) return;

    triggerHaptic('success');
    onAddTask({
      title: newTitle.trim(),
      description: newDesc.trim() || undefined,
      lifeAreaId: newAreaId,
      status: 'todo',
      priority: newPriority,
      dueDate: newDueDate || undefined,
      tags: [],
      focusMinutesTarget: 15,
    });

    setNewTitle('');
    setNewDesc('');
    setShowCreateModal(false);
  };

  // Cycle priority directly on the card
  const handleCyclePriority = (e: React.MouseEvent, task: TaskItem) => {
    e.stopPropagation();
    triggerHaptic('light');
    const order: TaskPriority[] = ['low', 'medium', 'high'];
    const currentIndex = order.indexOf(task.priority);
    const nextPriority = order[(currentIndex + 1) % order.length];
    onUpdateTask(task.id, { priority: nextPriority });
  };

  const priorityWeight: Record<TaskPriority, number> = {
    high: 3,
    medium: 2,
    low: 1,
  };

  const filteredTasks = tasks
    .filter((task) => {
      if (searchQuery && !task.title.toLowerCase().includes(searchQuery.toLowerCase())) {
        return false;
      }
      if (statusFilter !== 'all' && task.status !== statusFilter) return false;
      if (priorityFilter !== 'all' && task.priority !== priorityFilter) return false;
      if (lifeAreaFilter !== 'all' && task.lifeAreaId !== lifeAreaFilter) return false;
      return true;
    })
    .sort((a, b) => {
      if (sortBy === 'priority') {
        // High priority first
        return priorityWeight[b.priority] - priorityWeight[a.priority];
      }
      if (sortBy === 'due') {
        if (!a.dueDate) return 1;
        if (!b.dueDate) return -1;
        return a.dueDate.localeCompare(b.dueDate);
      }
      return 0;
    });

  return (
    <div className="space-y-6 pb-28">
      {/* Header & New Task Button */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="label text-[#FF5B5B]">Focus Stack</div>
          <h2 className="text-3xl sm:text-4xl font-bold text-[#1C1C1A] tracking-tight">Tasks & Micro-steps</h2>
          <p className="text-xs text-[#1C1C1A]/60 font-mono uppercase tracking-wider mt-1">
            Categorise tasks by urgency and overcome ADHD activation resistance
          </p>
        </div>

        <button
          id="task-list-create-btn"
          onClick={() => {
            triggerHaptic('light');
            setShowCreateModal(true);
          }}
          className="flex items-center justify-center space-x-2 bg-[#FF5B5B] hover:bg-[#ff4242] text-white px-5 py-3 rounded-full text-xs font-mono font-bold uppercase tracking-wider shadow-sm transition-all cursor-pointer hover:scale-105 active:scale-95"
        >
          <Plus className="w-4 h-4 stroke-[3]" />
          <span>Add New Task</span>
        </button>
      </div>

      {/* Selected Life Area Filter Banner */}
      {selectedLifeAreaId && selectedLifeAreaId !== 'all' && (
        <div className="bg-[#FF5B5B]/10 border border-[#FF5B5B]/30 rounded-2xl p-3 flex items-center justify-between text-xs font-mono text-[#FF5B5B]">
          <span>
            FILTERED AREA:{' '}
            <strong className="text-[#1C1C1A]">
              {lifeAreas.find((a) => a.id === selectedLifeAreaId)?.emoji}{' '}
              {lifeAreas.find((a) => a.id === selectedLifeAreaId)?.name}
            </strong>
          </span>
          <button
            onClick={onClearLifeAreaFilter}
            className="text-[#FF5B5B] hover:underline cursor-pointer font-bold uppercase"
          >
            SHOW ALL
          </button>
        </div>
      )}

      {/* Fast Inline Quick-Add Task Bar with Urgency Selector */}
      <div className="light-card rounded-3xl p-4 sm:p-5 shadow-xs border border-black/5 space-y-3">
        <div className="flex items-center justify-between">
          <span className="text-xs font-mono uppercase font-bold text-[#FF5B5B] flex items-center space-x-1.5">
            <Plus className="w-3.5 h-3.5" />
            <span>Quick-Add Task</span>
          </span>
          <span className="text-[11px] font-mono text-[#1C1C1A]/50">Press Enter to Add</span>
        </div>

        <form onSubmit={handleInlineQuickAdd} className="flex flex-col md:flex-row gap-2.5">
          <input
            type="text"
            id="quick-add-task-input"
            value={inlineTitle}
            onChange={(e) => setInlineTitle(e.target.value)}
            placeholder="Type a new task or micro-step... (e.g. Schedule meeting, Draft proposal)"
            className="flex-1 px-4 py-2.5 rounded-2xl bg-white border border-black/10 text-sm text-[#1C1C1A] placeholder:text-zinc-400 focus:outline-hidden focus:border-[#FF5B5B] font-sans"
          />

          {/* Priority / Urgency Segmented Selector */}
          <div className="flex items-center bg-white border border-black/10 rounded-2xl p-1 gap-1">
            <span className="text-[10px] font-mono uppercase font-bold text-[#1C1C1A]/40 px-2">Urgency:</span>
            <button
              type="button"
              id="inline-priority-low"
              onClick={() => {
                triggerHaptic('light');
                setInlinePriority('low');
              }}
              className={`px-2.5 py-1 rounded-xl text-xs font-mono font-bold transition-all cursor-pointer flex items-center space-x-1 ${
                inlinePriority === 'low'
                  ? 'bg-emerald-500 text-white shadow-xs'
                  : 'text-emerald-700 hover:bg-emerald-50'
              }`}
            >
              <span>Low</span>
            </button>

            <button
              type="button"
              id="inline-priority-medium"
              onClick={() => {
                triggerHaptic('light');
                setInlinePriority('medium');
              }}
              className={`px-2.5 py-1 rounded-xl text-xs font-mono font-bold transition-all cursor-pointer flex items-center space-x-1 ${
                inlinePriority === 'medium'
                  ? 'bg-amber-500 text-white shadow-xs'
                  : 'text-amber-700 hover:bg-amber-50'
              }`}
            >
              <span>Medium</span>
            </button>

            <button
              type="button"
              id="inline-priority-high"
              onClick={() => {
                triggerHaptic('light');
                setInlinePriority('high');
              }}
              className={`px-2.5 py-1 rounded-xl text-xs font-mono font-bold transition-all cursor-pointer flex items-center space-x-1 ${
                inlinePriority === 'high'
                  ? 'bg-[#FF5B5B] text-white shadow-xs'
                  : 'text-[#FF5B5B] hover:bg-rose-50'
              }`}
            >
              <span>High</span>
            </button>
          </div>

          {/* Life Area dropdown */}
          <select
            id="inline-task-area"
            value={inlineAreaId}
            onChange={(e) => setInlineAreaId(e.target.value)}
            className="px-3 py-2.5 rounded-2xl bg-white border border-black/10 text-xs font-mono text-[#1C1C1A]"
          >
            {lifeAreas.map((a) => (
              <option key={a.id} value={a.id}>
                {a.emoji} {a.name}
              </option>
            ))}
          </select>

          <button
            type="submit"
            id="inline-task-submit"
            disabled={!inlineTitle.trim()}
            className="bg-[#FF5B5B] hover:bg-[#ff4242] disabled:opacity-40 text-white px-5 py-2.5 rounded-2xl font-mono text-xs font-bold uppercase tracking-wider transition-all cursor-pointer shrink-0"
          >
            Add
          </button>
        </form>
      </div>

      {/* Search & Filter Controls */}
      <div className="light-card rounded-3xl p-5 shadow-xs space-y-4">
        <div className="flex flex-col sm:flex-row gap-3">
          {/* Search bar */}
          <div className="relative flex-1">
            <Search className="w-4 h-4 absolute left-3.5 top-3.5 text-[#1C1C1A]/40" />
            <input
              type="text"
              id="task-search-input"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search tasks or micro-steps..."
              className="w-full pl-10 pr-4 py-2.5 rounded-2xl bg-white border border-black/10 text-sm text-[#1C1C1A] focus:outline-hidden focus:border-[#FF5B5B] placeholder:text-zinc-400 font-sans"
            />
          </div>

          {/* Life Area dropdown */}
          <select
            id="task-filter-life-area"
            value={lifeAreaFilter}
            onChange={(e) => setLifeAreaFilter(e.target.value)}
            className="px-4 py-2.5 rounded-2xl bg-white border border-black/10 text-sm text-[#1C1C1A] font-mono"
          >
            <option value="all">All Life Areas</option>
            {lifeAreas.map((a) => (
              <option key={a.id} value={a.id}>
                {a.emoji} {a.name}
              </option>
            ))}
          </select>

          {/* Priority dropdown */}
          <select
            id="task-filter-priority"
            value={priorityFilter}
            onChange={(e) => setPriorityFilter(e.target.value as any)}
            className="px-4 py-2.5 rounded-2xl bg-white border border-black/10 text-sm text-[#1C1C1A] font-mono"
          >
            <option value="all">All Urgency Levels</option>
            <option value="high">🔴 High Urgency</option>
            <option value="medium">🟡 Medium Urgency</option>
            <option value="low">🟢 Low Urgency / Quick Win</option>
          </select>

          {/* Sort By dropdown */}
          <select
            id="task-sort-by"
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value as any)}
            className="px-4 py-2.5 rounded-2xl bg-white border border-black/10 text-sm text-[#1C1C1A] font-mono"
          >
            <option value="default">Default Order</option>
            <option value="priority">Sort by Urgency (High → Low)</option>
            <option value="due">Sort by Due Date</option>
          </select>
        </div>

        {/* Status Pills */}
        <div className="flex items-center space-x-2 pt-2 border-t border-black/5 overflow-x-auto text-xs font-mono uppercase tracking-wider">
          {(['all', 'todo', 'in_progress', 'completed'] as const).map((status) => (
            <button
              key={status}
              id={`task-filter-status-${status}`}
              onClick={() => setStatusFilter(status)}
              className={`px-4 py-1.5 rounded-full font-bold transition-all whitespace-nowrap cursor-pointer ${
                statusFilter === status
                  ? 'bg-[#111113] text-white'
                  : 'bg-white/60 text-[#1C1C1A]/70 hover:bg-white hover:text-[#1C1C1A]'
              }`}
            >
              {status === 'all'
                ? 'All Tasks'
                : status === 'todo'
                ? 'To Do'
                : status === 'in_progress'
                ? 'In Progress'
                : 'Completed'}
            </button>
          ))}
        </div>
      </div>

      {/* Task List items */}
      {filteredTasks.length === 0 ? (
        <div className="light-card rounded-3xl p-12 text-center space-y-3">
          <CheckSquare className="w-8 h-8 mx-auto text-[#1C1C1A]/30" />
          <h3 className="text-base font-bold text-[#1C1C1A]">No tasks match your filters</h3>
          <p className="text-xs text-[#1C1C1A]/60 font-mono">Try adjusting your search, priority filter, or life area.</p>
        </div>
      ) : (
        <div className="space-y-3">
          <AnimatePresence mode="popLayout">
            {filteredTasks.map((task) => {
              const area = lifeAreas.find((a) => a.id === task.lifeAreaId);
              const isCompleted = task.status === 'completed';

              return (
                <motion.div
                  key={task.id}
                  layout
                  initial={{ opacity: 0, y: 14, scale: 0.98 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, y: -14, scale: 0.98 }}
                  transition={{
                    opacity: { duration: 0.15 },
                    layout: { type: 'spring', stiffness: 350, damping: 28 },
                    y: { type: 'spring', stiffness: 350, damping: 28 },
                  }}
                  id={`task-item-card-${task.id}`}
                  className={`rounded-3xl p-4 sm:p-5 border transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-3 ${
                    isCompleted
                      ? 'bg-[#EFECE8]/60 border-black/5 opacity-60'
                      : 'bg-[#EFECE8] border-black/5 hover:border-black/20 shadow-xs'
                  }`}
                >
                  <div className="flex items-start space-x-3.5">
                    <button
                      id={`task-checkbox-${task.id}`}
                      onClick={() => {
                        triggerHaptic('toggle');
                        onToggleTaskStatus(task.id);
                      }}
                      className="mt-0.5 text-[#1C1C1A]/40 hover:text-[#FF5B5B] cursor-pointer transition-colors"
                      title={isCompleted ? 'Mark incomplete' : 'Mark complete'}
                    >
                      {isCompleted ? (
                        <CheckCircle2 className="w-5 h-5 text-[#FF5B5B] fill-[#FF5B5B]/20" />
                      ) : (
                        <Circle className="w-5 h-5" />
                      )}
                    </button>

                    <div className="space-y-1">
                      <div className="flex items-center space-x-2 flex-wrap gap-y-1">
                        <span
                          onClick={() => setInspectingTask(task)}
                          className={`text-sm sm:text-base font-bold cursor-pointer hover:text-[#FF5B5B] transition-colors ${
                            isCompleted ? 'line-through text-[#1C1C1A]/40' : 'text-[#1C1C1A]'
                          }`}
                        >
                          {task.title}
                        </span>

                        {area && (
                          <span className="text-xs px-2.5 py-0.5 rounded-full bg-white border border-black/5 text-[#1C1C1A]/70 font-mono">
                            {area.emoji} {area.name}
                          </span>
                        )}

                        {/* Priority Badge with direct click-to-cycle */}
                        <button
                          type="button"
                          id={`task-priority-badge-${task.id}`}
                          onClick={(e) => handleCyclePriority(e, task)}
                          title="Click to cycle priority (Low / Medium / High)"
                          className={`text-[10px] font-mono font-bold uppercase px-2.5 py-0.5 rounded-full transition-all cursor-pointer flex items-center space-x-1 ${
                            task.priority === 'high'
                              ? 'bg-[#FF5B5B]/15 text-[#FF5B5B] hover:bg-[#FF5B5B]/25'
                              : task.priority === 'medium'
                              ? 'bg-amber-500/15 text-amber-700 hover:bg-amber-500/25'
                              : 'bg-emerald-500/15 text-emerald-700 hover:bg-emerald-500/25'
                          }`}
                        >
                          {task.priority === 'high' && <span className="w-1.5 h-1.5 rounded-full bg-[#FF5B5B]"></span>}
                          {task.priority === 'medium' && <span className="w-1.5 h-1.5 rounded-full bg-amber-500"></span>}
                          {task.priority === 'low' && <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>}
                          <span>{task.priority} urgency</span>
                        </button>
                      </div>

                      {task.description && (
                        <p className="text-xs text-[#1C1C1A]/70 line-clamp-1">{task.description}</p>
                      )}

                      <div className="flex items-center space-x-3 text-xs font-mono text-[#1C1C1A]/60 pt-0.5 flex-wrap gap-y-1">
                        {task.dueDate && (
                          <span className="flex items-center space-x-1">
                            <Clock className="w-3.5 h-3.5 text-[#FF5B5B]" />
                            <span>Due: {task.dueDate}</span>
                          </span>
                        )}

                        <span className="text-[#1C1C1A] font-bold flex items-center space-x-1 bg-black/5 px-2 py-0.5 rounded-md">
                          <span>⏱️ {formatFocusDuration(task.focusDurationSeconds || (task.focusMinutesTarget || 15) * 60)}</span>
                          <span className="text-[#FF5B5B]">({typeof task.nudgesCount === 'number' ? task.nudgesCount : (task.focusDurationSeconds || 900) <= 60 ? 1 : 2} 🔔)</span>
                        </span>

                        {task.tags.map((tg) => (
                          <span key={tg} className="text-[#1C1C1A]/40">
                            #{tg}
                          </span>
                        ))}
                      </div>
                    </div>
                  </div>

                  {/* Focus Timer Trigger Button */}
                  {!isCompleted && (
                    <div className="flex items-center space-x-2 self-end sm:self-center shrink-0">
                      <button
                        id={`task-start-focus-${task.id}`}
                        onClick={() => {
                          const secs = task.focusDurationSeconds || (task.focusMinutesTarget ? task.focusMinutesTarget * 60 : 15 * 60);
                          const nudges = typeof task.nudgesCount === 'number' ? task.nudgesCount : secs <= 60 ? 1 : 2;
                          onStartFocus(task, secs, nudges);
                        }}
                        className="flex items-center space-x-1.5 bg-[#FF5B5B] hover:bg-[#ff4242] text-white px-4 py-2 rounded-full text-xs font-mono font-bold uppercase tracking-wider transition-all cursor-pointer shadow-xs hover:scale-105 active:scale-95"
                      >
                        <Play className="w-3.5 h-3.5 fill-current" />
                        <span>Start Focus</span>
                      </button>

                      <button
                        id={`task-edit-${task.id}`}
                        onClick={() => setInspectingTask(task)}
                        className="text-xs text-[#1C1C1A]/70 hover:text-[#1C1C1A] font-mono px-3 py-2 rounded-full hover:bg-black/5 cursor-pointer font-bold uppercase"
                      >
                        Details
                      </button>
                    </div>
                  )}
                </motion.div>
              );
            })}
          </AnimatePresence>
        </div>
      )}

      {/* Task Inspection Modal */}
      <TaskDetailModal
        task={inspectingTask}
        onClose={() => setInspectingTask(null)}
        lifeAreas={lifeAreas}
        tags={tags}
        onUpdateTask={onUpdateTask}
        onDeleteTask={onDeleteTask}
        onStartFocus={onStartFocus}
      />

      {/* Quick Add Task Modal */}
      <AnimatePresence>
        {showCreateModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
            onClick={() => setShowCreateModal(false)}
          >
            <motion.div
              initial={{ opacity: 0, scale: 0.92, y: 16 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.92, y: 16 }}
              transition={{ type: 'spring', stiffness: 320, damping: 26 }}
              onClick={(e) => e.stopPropagation()}
              className="dark-card text-white rounded-[32px] max-w-md w-full p-6 sm:p-7 shadow-2xl space-y-4"
            >
              <div className="flex items-center justify-between pb-3 border-b border-white/10">
                <div>
                  <span className="label text-[#FF5B5B]">Create Item</span>
                  <h3 className="text-xl font-bold text-white tracking-tight">Add New Task</h3>
                </div>
                <button
                  onClick={() => setShowCreateModal(false)}
                  className="p-1 rounded-full text-white/50 hover:text-white cursor-pointer"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <form onSubmit={handleCreateTaskSubmit} className="space-y-4">
                <div>
                  <label className="label text-white/60 mb-1">
                    Task Title
                  </label>
                  <input
                    type="text"
                    required
                    id="new-task-title-input"
                    value={newTitle}
                    onChange={(e) => setNewTitle(e.target.value)}
                    placeholder="E.g., Complete taxes micro-step 1"
                    className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm font-semibold text-white focus:border-[#FF5B5B] focus:outline-hidden"
                  />
                </div>

                <div>
                  <label className="label text-white/60 mb-1">Life Area</label>
                  <select
                    required
                    id="new-task-area-select"
                    value={newAreaId}
                    onChange={(e) => setNewAreaId(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
                  >
                    {lifeAreas.map((a) => (
                      <option key={a.id} value={a.id} className="bg-[#111113]">
                        {a.emoji} {a.name}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Priority / Urgency Selection with segmented buttons */}
                <div>
                  <label className="label text-white/60 mb-1.5">
                    Priority / Urgency Level
                  </label>
                  <div className="grid grid-cols-3 gap-2">
                    <button
                      type="button"
                      id="modal-priority-low"
                      onClick={() => {
                        triggerHaptic('light');
                        setNewPriority('low');
                      }}
                      className={`p-2.5 rounded-2xl border text-center transition-all cursor-pointer ${
                        newPriority === 'low'
                          ? 'bg-emerald-500/20 border-emerald-500 text-emerald-400 font-bold'
                          : 'bg-white/5 border-white/10 text-zinc-400 hover:text-white'
                      }`}
                    >
                      <span className="text-xs font-mono block">🟢 Low</span>
                      <span className="text-[10px] text-zinc-400 block mt-0.5">Quick Win</span>
                    </button>

                    <button
                      type="button"
                      id="modal-priority-medium"
                      onClick={() => {
                        triggerHaptic('light');
                        setNewPriority('medium');
                      }}
                      className={`p-2.5 rounded-2xl border text-center transition-all cursor-pointer ${
                        newPriority === 'medium'
                          ? 'bg-amber-500/20 border-amber-500 text-amber-400 font-bold'
                          : 'bg-white/5 border-white/10 text-zinc-400 hover:text-white'
                      }`}
                    >
                      <span className="text-xs font-mono block">🟡 Medium</span>
                      <span className="text-[10px] text-zinc-400 block mt-0.5">Standard</span>
                    </button>

                    <button
                      type="button"
                      id="modal-priority-high"
                      onClick={() => {
                        triggerHaptic('light');
                        setNewPriority('high');
                      }}
                      className={`p-2.5 rounded-2xl border text-center transition-all cursor-pointer ${
                        newPriority === 'high'
                          ? 'bg-[#FF5B5B]/20 border-[#FF5B5B] text-[#FF5B5B] font-bold'
                          : 'bg-white/5 border-white/10 text-zinc-400 hover:text-white'
                      }`}
                    >
                      <span className="text-xs font-mono block">🔴 High</span>
                      <span className="text-[10px] text-zinc-400 block mt-0.5">Urgent</span>
                    </button>
                  </div>
                </div>

                <div>
                  <label className="label text-white/60 mb-1">
                    Due Date
                  </label>
                  <input
                    type="date"
                    id="new-task-due-date"
                    value={newDueDate}
                    onChange={(e) => setNewDueDate(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
                  />
                </div>

                <div className="flex items-center justify-end space-x-3 pt-3">
                  <button
                    type="button"
                    onClick={() => setShowCreateModal(false)}
                    className="px-4 py-2 text-xs font-mono uppercase text-white/60 hover:text-white rounded-full cursor-pointer font-bold"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    id="new-task-submit-btn"
                    className="px-6 py-2.5 text-xs font-mono font-bold uppercase bg-[#FF5B5B] hover:bg-[#ff4242] text-white rounded-full shadow-md cursor-pointer transition-all"
                  >
                    Create Task
                  </button>
                </div>
              </form>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

