import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { TaskItem, LifeArea, Tag, TaskStatus, TaskPriority } from '../types';
import { TaskDetailModal } from './TaskDetailModal';
import {
  CheckSquare,
  Plus,
  Search,
  Clock,
  Play,
  CheckCircle2,
  Circle,
  X,
} from 'lucide-react';

interface TaskListViewProps {
  tasks: TaskItem[];
  lifeAreas: LifeArea[];
  tags: Tag[];
  onToggleTaskStatus: (taskId: string) => void;
  onAddTask: (task: Omit<TaskItem, 'id' | 'createdAt' | 'focusMinutesLogged'>) => void;
  onUpdateTask: (id: string, updates: Partial<TaskItem>) => void;
  onDeleteTask: (id: string) => void;
  onStartFocus: (task: TaskItem, durationMinutes?: number) => void;
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
  const [tagFilter, setTagFilter] = useState<string>('all');

  const [inspectingTask, setInspectingTask] = useState<TaskItem | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);

  // New task form state
  const [newTitle, setNewTitle] = useState('');
  const [newDesc, setNewDesc] = useState('');
  const [newAreaId, setNewAreaId] = useState(lifeAreas[0]?.id || '');
  const [newPriority, setNewPriority] = useState<TaskPriority>('medium');
  const [newDueDate, setNewDueDate] = useState(new Date().toISOString().split('T')[0]);

  const filteredTasks = tasks.filter((task) => {
    if (searchQuery && !task.title.toLowerCase().includes(searchQuery.toLowerCase())) {
      return false;
    }
    if (statusFilter !== 'all' && task.status !== statusFilter) return false;
    if (priorityFilter !== 'all' && task.priority !== priorityFilter) return false;
    if (lifeAreaFilter !== 'all' && task.lifeAreaId !== lifeAreaFilter) return false;
    if (tagFilter !== 'all' && !task.tags.includes(tagFilter)) return false;
    return true;
  });

  const handleCreateTaskSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle.trim() || !newAreaId) return;

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

  return (
    <div className="space-y-6 pb-28">
      {/* Header & New Task Button */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="label text-[#FF5B5B]">Focus Stack</div>
          <h2 className="text-3xl sm:text-4xl font-bold text-[#1C1C1A] tracking-tight">Tasks & Micro-steps</h2>
          <p className="text-xs text-[#1C1C1A]/60 font-mono uppercase tracking-wider mt-1">
            Break tasks down to overcome ADHD activation resistance
          </p>
        </div>

        <button
          id="task-list-create-btn"
          onClick={() => setShowCreateModal(true)}
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
            <option value="all">All Priorities</option>
            <option value="low">Low Energy / Quick Win</option>
            <option value="medium">Medium Energy</option>
            <option value="high">High Energy Required</option>
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
          <p className="text-xs text-[#1C1C1A]/60 font-mono">Try adjusting your search or filters.</p>
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
                    layout: { type: "spring", stiffness: 350, damping: 28 },
                    y: { type: "spring", stiffness: 350, damping: 28 },
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
                      onClick={() => onToggleTaskStatus(task.id)}
                      className="mt-0.5 text-[#1C1C1A]/40 hover:text-[#FF5B5B] cursor-pointer transition-colors"
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

                        <span
                          className={`text-[10px] font-mono font-bold uppercase px-2.5 py-0.5 rounded-full ${
                            task.priority === 'high'
                              ? 'bg-[#FF5B5B]/15 text-[#FF5B5B]'
                              : task.priority === 'medium'
                              ? 'bg-amber-500/15 text-amber-700'
                              : 'bg-black/5 text-[#1C1C1A]/70'
                          }`}
                        >
                          {task.priority} energy
                        </span>
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

                        {task.focusMinutesTarget && (
                          <span className="text-[#1C1C1A] font-bold">
                            ⏱️ {task.focusMinutesLogged || 0} / {task.focusMinutesTarget}m logged
                          </span>
                        )}

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
                        onClick={() => onStartFocus(task, task.focusMinutesTarget || 15)}
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

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="label text-white/60 mb-1">
                      Energy Level
                    </label>
                    <select
                      id="new-task-priority-select"
                      value={newPriority}
                      onChange={(e) => setNewPriority(e.target.value as any)}
                      className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
                    >
                      <option value="low" className="bg-[#111113]">Low / Quick Win</option>
                      <option value="medium" className="bg-[#111113]">Medium Focus</option>
                      <option value="high" className="bg-[#111113]">High Energy Required</option>
                    </select>
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
