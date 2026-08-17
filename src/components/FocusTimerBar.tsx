import React from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { FocusSessionState } from '../types';
import { Play, Pause, Square, Plus, X } from 'lucide-react';

interface FocusTimerBarProps {
  focusSession: FocusSessionState;
  onPause: () => void;
  onStop: () => void;
  onAddMinutes: (mins: number) => void;
  isOpenModal: boolean;
  onCloseModal: () => void;
}

export const FocusTimerBar: React.FC<FocusTimerBarProps> = ({
  focusSession,
  onPause,
  onStop,
  onAddMinutes,
  isOpenModal,
  onCloseModal,
}) => {
  const formatTime = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  const progress =
    focusSession.durationSeconds > 0
      ? ((focusSession.durationSeconds - focusSession.remainingSeconds) /
          focusSession.durationSeconds) *
        100
      : 0;

  return (
    <>
      {/* Modal View */}
      <AnimatePresence>
        {isOpenModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-xs"
            onClick={onCloseModal}
          >
            <motion.div
              initial={{ opacity: 0, scale: 0.92, y: 16 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.92, y: 16 }}
              transition={{ duration: 0.2, ease: [0.16, 1, 0.3, 1] }}
              onClick={(e) => e.stopPropagation()}
              className="dark-card text-white rounded-[36px] max-w-md w-full p-8 shadow-2xl text-center space-y-6"
            >
              <div className="flex justify-end">
                <button
                  id="focus-modal-close"
                  onClick={onCloseModal}
                  className="text-white/40 hover:text-white p-1 rounded-full cursor-pointer transition-colors"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>

              <div className="space-y-2">
                <span className="text-4xl">{focusSession.lifeAreaEmoji}</span>
                <span className="label text-[#FF5B5B] block">
                  ADHD Focus Session
                </span>
                <h2 className="text-2xl font-light text-white leading-tight">
                  {focusSession.taskTitle}
                </h2>
              </div>

              {/* Large Countdown Display */}
              <div className="py-4 space-y-3">
                <div className="text-6xl font-bold font-mono tracking-tight text-white">
                  {formatTime(focusSession.remainingSeconds)}
                </div>

                {/* Progress Bar */}
                <div className="progress-bar">
                  <div
                    className="progress-fill"
                    style={{ width: `${progress}%` }}
                  ></div>
                </div>
              </div>

              {/* Controls */}
              <div className="flex items-center justify-center space-x-3">
                <button
                  id="focus-timer-pause-btn"
                  onClick={onPause}
                  className="p-4 rounded-full bg-white/10 hover:bg-white/20 text-white font-bold transition-all cursor-pointer"
                  title={focusSession.isPaused ? 'Resume' : 'Pause'}
                >
                  {focusSession.isPaused ? (
                    <Play className="w-5 h-5 fill-current" />
                  ) : (
                    <Pause className="w-5 h-5 fill-current" />
                  )}
                </button>

                <button
                  id="focus-timer-stop-btn"
                  onClick={() => {
                    onStop();
                    onCloseModal();
                  }}
                  className="px-8 py-3.5 rounded-full bg-[#FF5B5B] hover:bg-[#ff4242] text-white font-mono font-bold text-xs uppercase tracking-wider shadow-lg transition-all cursor-pointer"
                >
                  Complete & Stop
                </button>

                <button
                  id="focus-timer-add-5m"
                  onClick={() => onAddMinutes(5)}
                  className="p-3.5 rounded-full bg-white/10 hover:bg-white/20 text-white font-mono font-bold text-xs transition-all cursor-pointer flex items-center space-x-1"
                  title="Add 5 Mins"
                >
                  <Plus className="w-3.5 h-3.5" />
                  <span>5m</span>
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Bottom Floating Bar */}
      <AnimatePresence>
        {focusSession.isRunning && !isOpenModal && (
          <motion.div
            initial={{ opacity: 0, y: 30, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 30, scale: 0.95 }}
            transition={{ duration: 0.25, ease: 'easeOut' }}
            className="fixed bottom-24 left-4 right-4 sm:left-auto sm:right-6 sm:max-w-md z-40 dark-card text-white rounded-3xl p-4 shadow-xl flex items-center justify-between gap-3"
          >
            <div className="flex items-center space-x-3 overflow-hidden">
              <span className="text-xl">{focusSession.lifeAreaEmoji}</span>
              <div className="truncate">
                <div className="flex items-center space-x-2">
                  <span className="text-xs font-bold text-white truncate">
                    {focusSession.taskTitle}
                  </span>
                  <span className="text-[10px] font-mono bg-[#FF5B5B] text-white px-2 py-0.5 rounded-full font-bold shrink-0">
                    {formatTime(focusSession.remainingSeconds)}
                  </span>
                </div>
                <div className="w-36 bg-white/10 h-1.5 rounded-full overflow-hidden mt-1.5">
                  <div
                    className="bg-[#FF5B5B] h-full rounded-full transition-all duration-1000"
                    style={{ width: `${progress}%` }}
                  ></div>
                </div>
              </div>
            </div>

            <div className="flex items-center space-x-1 shrink-0">
              <button
                id="focus-bar-pause"
                onClick={onPause}
                className="p-2 rounded-full text-white/70 hover:text-white hover:bg-white/10 cursor-pointer transition-colors"
              >
                {focusSession.isPaused ? (
                  <Play className="w-4 h-4 fill-current" />
                ) : (
                  <Pause className="w-4 h-4 fill-current" />
                )}
              </button>

              <button
                id="focus-bar-stop"
                onClick={onStop}
                className="p-2 rounded-full text-[#FF5B5B] hover:bg-[#FF5B5B]/10 cursor-pointer transition-colors"
              >
                <Square className="w-4 h-4 fill-current" />
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
};
