import React, { useState } from 'react';
import { motion, useMotionValue, useTransform } from 'motion/react';
import { TaskItem, LifeArea, TaskPriority } from '../types';
import { getAreaColorConfig } from '../utils/areaColors';
import { triggerHaptic, formatFocusDuration } from '../utils/haptics';
import {
  CheckCircle2,
  Circle,
  Clock,
  Play,
  Trash2,
  Check,
  RotateCcw,
  Sparkles,
  ArrowRight,
  ChevronRight,
} from 'lucide-react';

interface SwipeableTaskCardProps {
  task: TaskItem;
  area?: LifeArea;
  onToggleStatus: (taskId: string) => void;
  onDelete: (taskId: string) => void;
  onCyclePriority: (e: React.MouseEvent, task: TaskItem) => void;
  onInspect: (task: TaskItem) => void;
  onStartFocus: (task: TaskItem, durationSeconds?: number, nudgesCount?: number) => void;
}

export const SwipeableTaskCard: React.FC<SwipeableTaskCardProps> = ({
  task,
  area,
  onToggleStatus,
  onDelete,
  onCyclePriority,
  onInspect,
  onStartFocus,
}) => {
  const [isDeleting, setIsDeleting] = useState(false);
  const [dragOffset, setDragOffset] = useState(0);
  const isCompleted = task.status === 'completed';

  // Life Area Color Config
  const colorConfig = getAreaColorConfig(area?.color);

  const handleDrag = (_: any, info: { offset: { x: number } }) => {
    setDragOffset(info.offset.x);
  };

  const handleDragEnd = (_: any, info: { offset: { x: number } }) => {
    const threshold = 75; // px trigger threshold
    const x = info.offset.x;

    if (x > threshold) {
      // Swiped Right -> Complete / Toggle Task
      triggerHaptic('success');
      onToggleStatus(task.id);
    } else if (x < -threshold) {
      // Swiped Left -> Delete Task
      triggerHaptic('heavy');
      setIsDeleting(true);
      setTimeout(() => {
        onDelete(task.id);
      }, 180);
    }

    setDragOffset(0);
  };

  const isSwipingRight = dragOffset > 15;
  const isSwipingLeft = dragOffset < -15;
  const swipeProgress = Math.min(Math.abs(dragOffset) / 80, 1);

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 14, scale: 0.98 }}
      animate={{ opacity: isDeleting ? 0 : 1, y: 0, scale: isDeleting ? 0.92 : 1 }}
      exit={{ opacity: 0, x: dragOffset < 0 ? -120 : 120, scale: 0.92 }}
      transition={{
        opacity: { duration: 0.15 },
        layout: { type: 'spring', stiffness: 380, damping: 28 },
        scale: { duration: 0.15 },
      }}
      id={`task-item-card-${task.id}`}
      className="relative select-none overflow-hidden rounded-3xl group touch-pan-y"
    >
      {/* Background Revealed Action Layer */}
      <div
        aria-hidden="true"
        className={`absolute inset-0 rounded-3xl flex items-center justify-between px-6 transition-colors ${
          isSwipingRight
            ? 'bg-emerald-600 text-white'
            : isSwipingLeft
            ? 'bg-[#FF5B5B] text-white'
            : 'bg-black/5 text-transparent'
        }`}
      >
        {/* Left reveal: Swipe to Complete / Toggle */}
        <div
          className={`flex items-center space-x-2.5 transition-all duration-150 ${
            isSwipingRight ? 'opacity-100 translate-x-0' : 'opacity-0 -translate-x-4'
          }`}
          style={{ transform: `scale(${0.85 + swipeProgress * 0.2})` }}
        >
          <div className="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center shadow-xs">
            {isCompleted ? (
              <RotateCcw className="w-4 h-4 text-white" />
            ) : (
              <Check className="w-5 h-5 text-white stroke-[3]" />
            )}
          </div>
          <span className="font-mono text-xs font-bold uppercase tracking-wider text-white">
            {isCompleted ? 'Mark Incomplete' : 'Complete Task'}
          </span>
        </div>

        {/* Right reveal: Swipe to Delete */}
        <div
          className={`flex items-center space-x-2.5 transition-all duration-150 ${
            isSwipingLeft ? 'opacity-100 translate-x-0' : 'opacity-0 translate-x-4'
          }`}
          style={{ transform: `scale(${0.85 + swipeProgress * 0.2})` }}
        >
          <span className="font-mono text-xs font-bold uppercase tracking-wider text-white">
            Delete Task
          </span>
          <div className="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center shadow-xs">
            <Trash2 className="w-4.5 h-4.5 text-white" />
          </div>
        </div>
      </div>

      {/* Foreground Draggable Card */}
      <motion.div
        drag="x"
        dragDirectionLock
        dragConstraints={{ left: 0, right: 0 }}
        dragElastic={{ left: 0.7, right: 0.7 }}
        dragSnapToOrigin={true}
        onDrag={handleDrag}
        onDragEnd={handleDragEnd}
        className={`relative z-10 rounded-3xl p-4 sm:p-5 border transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-3 cursor-grab active:cursor-grabbing border-l-4 ${
          colorConfig.borderLeftClass
        } ${
          isCompleted
            ? 'bg-[#EFECE8]/80 border-black/5 opacity-65'
            : 'bg-[#EFECE8] border-black/5 hover:border-black/20 shadow-xs'
        }`}
      >
        <div className="flex items-start space-x-3.5 min-w-0">
          {/* Checkbox */}
          <button
            type="button"
            id={`task-checkbox-${task.id}`}
            onClick={(e) => {
              e.stopPropagation();
              triggerHaptic('toggle');
              onToggleStatus(task.id);
            }}
            className="mt-0.5 text-[#1C1C1A]/40 hover:text-[#FF5B5B] cursor-pointer transition-colors shrink-0"
            title={isCompleted ? 'Mark incomplete' : 'Mark complete'}
          >
            {isCompleted ? (
              <CheckCircle2 className="w-5 h-5 text-emerald-600 fill-emerald-100" />
            ) : (
              <Circle className="w-5 h-5 text-[#1C1C1A]/40 hover:text-[#1C1C1A]" />
            )}
          </button>

          <div className="space-y-1.5 min-w-0 flex-1">
            <div className="flex items-center space-x-2 flex-wrap gap-y-1">
              <span
                onClick={() => onInspect(task)}
                className={`text-sm sm:text-base font-bold cursor-pointer hover:text-[#FF5B5B] transition-colors truncate max-w-full ${
                  isCompleted ? 'line-through text-[#1C1C1A]/45' : 'text-[#1C1C1A]'
                }`}
                title={task.title}
              >
                {task.title}
              </span>

              {/* Life Area Badge with Color-coded Dot */}
              {area && (
                <span
                  className={`inline-flex items-center space-x-1.5 text-xs px-2.5 py-0.5 rounded-full font-mono border font-medium shadow-2xs ${colorConfig.badgeClass}`}
                >
                  <span
                    className={`w-2 h-2 rounded-full ${colorConfig.dotClass} shrink-0 ring-1 ring-black/10`}
                  />
                  <span>{area.emoji}</span>
                  <span className="truncate max-w-[120px]">{area.name}</span>
                </span>
              )}

              {/* Priority Badge with direct click-to-cycle */}
              <button
                type="button"
                id={`task-priority-badge-${task.id}`}
                onClick={(e) => onCyclePriority(e, task)}
                title="Click to cycle priority (Low / Medium / High)"
                className={`text-[10px] font-mono font-bold uppercase px-2.5 py-0.5 rounded-full transition-all cursor-pointer flex items-center space-x-1 ${
                  task.priority === 'high'
                    ? 'bg-[#FF5B5B]/15 text-[#FF5B5B] hover:bg-[#FF5B5B]/25'
                    : task.priority === 'medium'
                    ? 'bg-amber-500/15 text-amber-700 hover:bg-amber-500/25'
                    : 'bg-emerald-500/15 text-emerald-700 hover:bg-emerald-500/25'
                }`}
              >
                {task.priority === 'high' && (
                  <span className="w-1.5 h-1.5 rounded-full bg-[#FF5B5B]"></span>
                )}
                {task.priority === 'medium' && (
                  <span className="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
                )}
                {task.priority === 'low' && (
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                )}
                <span>{task.priority} urgency</span>
              </button>
            </div>

            {task.description && (
              <p className="text-xs text-[#1C1C1A]/70 line-clamp-2">{task.description}</p>
            )}

            {/* Task Metadata row */}
            <div className="flex items-center space-x-3 text-xs font-mono text-[#1C1C1A]/60 pt-0.5 flex-wrap gap-y-1">
              {task.dueDate && (
                <span className="flex items-center space-x-1">
                  <Clock className="w-3.5 h-3.5 text-[#FF5B5B]" />
                  <span>Due: {task.dueDate}</span>
                </span>
              )}

              <span className="text-[#1C1C1A] font-bold flex items-center space-x-1 bg-black/5 px-2 py-0.5 rounded-md">
                <span>
                  ⏱️{' '}
                  {formatFocusDuration(
                    task.focusDurationSeconds || (task.focusMinutesTarget || 15) * 60
                  )}
                </span>
                <span className="text-[#FF5B5B]">
                  (
                  {typeof task.nudgesCount === 'number'
                    ? task.nudgesCount
                    : (task.focusDurationSeconds || 900) <= 60
                    ? 1
                    : 2}{' '}
                  🔔)
                </span>
              </span>

              {task.tags?.map((tg) => (
                <span key={tg} className="text-[#1C1C1A]/40">
                  #{tg}
                </span>
              ))}
            </div>
          </div>
        </div>

        {/* Right side Actions */}
        <div className="flex items-center space-x-2 self-end sm:self-center shrink-0">
          {!isCompleted && (
            <button
              type="button"
              id={`task-start-focus-${task.id}`}
              onClick={(e) => {
                e.stopPropagation();
                const secs =
                  task.focusDurationSeconds ||
                  (task.focusMinutesTarget ? task.focusMinutesTarget * 60 : 15 * 60);
                const nudges =
                  typeof task.nudgesCount === 'number'
                    ? task.nudgesCount
                    : secs <= 60
                    ? 1
                    : 2;
                onStartFocus(task, secs, nudges);
              }}
              className="flex items-center space-x-1.5 bg-[#FF5B5B] hover:bg-[#ff4242] text-white px-3.5 sm:px-4 py-2 rounded-full text-xs font-mono font-bold uppercase tracking-wider transition-all cursor-pointer shadow-xs hover:scale-105 active:scale-95 whitespace-nowrap"
            >
              <Play className="w-3.5 h-3.5 fill-current" />
              <span>Start Focus</span>
            </button>
          )}

          <button
            type="button"
            id={`task-edit-${task.id}`}
            onClick={(e) => {
              e.stopPropagation();
              onInspect(task);
            }}
            className="text-xs text-[#1C1C1A]/70 hover:text-[#1C1C1A] font-mono px-3 py-2 rounded-full hover:bg-black/5 cursor-pointer font-bold uppercase"
          >
            Details
          </button>
        </div>
      </motion.div>
    </motion.div>
  );
};
