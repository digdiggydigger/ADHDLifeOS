import { useState, useEffect, useRef } from 'react';
import { LifeArea, Tag, CaptureItem, TaskItem, JournalEntry, NudgeItem, FocusSessionState, NudgeHistoryRecord } from '../types';
import { INITIAL_LIFE_AREAS, INITIAL_TAGS, INITIAL_CAPTURES, INITIAL_TASKS, INITIAL_JOURNAL, INITIAL_NUDGES } from '../data/initialData';
import { triggerHaptic, playNudgeChime, playTimerCompleteChime, formatFocusDuration } from '../utils/haptics';

const STORAGE_KEY_PREFIX = 'adhd_lifeos_';

export function calculateNudgeCheckpoints(durationSeconds: number, nudgesCount: number): number[] {
  if (nudgesCount <= 0 || durationSeconds < 10) return [];
  const checkpoints: number[] = [];
  const segment = durationSeconds / (nudgesCount + 1);
  for (let i = 1; i <= nudgesCount; i++) {
    const elapsed = Math.round(segment * i);
    if (elapsed > 0 && elapsed < durationSeconds && !checkpoints.includes(elapsed)) {
      checkpoints.push(elapsed);
    }
  }
  return checkpoints.sort((a, b) => a - b);
}

export function calculateIntervalNudgeCheckpoints(durationSeconds: number, intervalSeconds: number): number[] {
  // Enforce minimum 30s interval
  const safeInterval = Math.max(30, intervalSeconds);
  const checkpoints: number[] = [];
  for (let t = safeInterval; t < durationSeconds; t += safeInterval) {
    checkpoints.push(t);
  }
  return checkpoints.sort((a, b) => a - b);
}

function getInitial<T>(key: string, fallback: T): T {
  try {
    const item = localStorage.getItem(STORAGE_KEY_PREFIX + key);
    return item ? JSON.parse(item) : fallback;
  } catch {
    return fallback;
  }
}

export function useLifeOSState() {
  const [lifeAreas, setLifeAreas] = useState<LifeArea[]>(() =>
    getInitial('life_areas', INITIAL_LIFE_AREAS)
  );
  const [tags, setTags] = useState<Tag[]>(() =>
    getInitial('tags', INITIAL_TAGS)
  );
  const [captures, setCaptures] = useState<CaptureItem[]>(() =>
    getInitial('captures', INITIAL_CAPTURES)
  );
  const [tasks, setTasks] = useState<TaskItem[]>(() =>
    getInitial('tasks', INITIAL_TASKS)
  );
  const [journal, setJournal] = useState<JournalEntry[]>(() =>
    getInitial('journal', INITIAL_JOURNAL)
  );
  const [nudges, setNudges] = useState<NudgeItem[]>(() =>
    getInitial('nudges', INITIAL_NUDGES)
  );
  const [nudgeHistory, setNudgeHistory] = useState<NudgeHistoryRecord[]>(() =>
    getInitial('nudge_history', [
      {
        id: 'nh-seed-1',
        taskId: 'task-1',
        taskTitle: 'Deep Work: Strategy Architecture',
        lifeAreaEmoji: '💼',
        timestamp: new Date(Date.now() - 3600000 * 2).toISOString(),
        elapsedSeconds: 300,
        totalDurationSeconds: 600,
        nudgeIndex: 1,
        totalNudges: 2,
        reaction: 'on_track',
      },
      {
        id: 'nh-seed-2',
        taskId: 'task-2',
        taskTitle: 'ADHD LifeOS Nudge Calibration',
        lifeAreaEmoji: '⚡',
        timestamp: new Date(Date.now() - 3600000 * 5).toISOString(),
        elapsedSeconds: 15,
        totalDurationSeconds: 30,
        nudgeIndex: 1,
        totalNudges: 1,
        reaction: 'completed_step',
      },
    ])
  );

  const [focusSession, setFocusSession] = useState<FocusSessionState>({
    taskId: null,
    taskTitle: '',
    lifeAreaEmoji: '⏱️',
    durationSeconds: 15 * 60,
    remainingSeconds: 15 * 60,
    isRunning: false,
    isPaused: false,
    nudgesCount: 2,
    nudgeCheckpoints: calculateNudgeCheckpoints(15 * 60, 2),
    triggeredNudgeIndices: [],
  });

  // Ref to track last tick time for high accuracy
  const lastTickTimeRef = useRef<number>(Date.now());

  // Save to localStorage whenever state changes
  useEffect(() => {
    localStorage.setItem(STORAGE_KEY_PREFIX + 'life_areas', JSON.stringify(lifeAreas));
  }, [lifeAreas]);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY_PREFIX + 'tags', JSON.stringify(tags));
  }, [tags]);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY_PREFIX + 'captures', JSON.stringify(captures));
  }, [captures]);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY_PREFIX + 'tasks', JSON.stringify(tasks));
  }, [tasks]);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY_PREFIX + 'journal', JSON.stringify(journal));
  }, [journal]);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY_PREFIX + 'nudges', JSON.stringify(nudges));
  }, [nudges]);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY_PREFIX + 'nudge_history', JSON.stringify(nudgeHistory));
  }, [nudgeHistory]);

  // Focus Timer Tick & High-Accuracy Nudge Detection
  useEffect(() => {
    let interval: any = null;
    if (focusSession.isRunning && !focusSession.isPaused && focusSession.remainingSeconds > 0) {
      lastTickTimeRef.current = Date.now();
      interval = setInterval(() => {
        setFocusSession((prev) => {
          if (!prev.isRunning || prev.isPaused || prev.remainingSeconds <= 0) {
            return prev;
          }

          const nextRemaining = prev.remainingSeconds - 1;
          const elapsed = prev.durationSeconds - nextRemaining;

          // Check if any nudge checkpoints are hit right now
          let newTriggered = [...prev.triggeredNudgeIndices];
          let nudgeMsg = prev.lastNudgeMessage;
          let nudgeTimestamp = prev.lastNudgeTimestamp;

          prev.nudgeCheckpoints.forEach((checkpointSec, idx) => {
            if (!newTriggered.includes(idx) && elapsed >= checkpointSec) {
              newTriggered.push(idx);
              // Trigger definitive audio chime and haptic feedback
              playNudgeChime();

              const percent = Math.round((checkpointSec / prev.durationSeconds) * 100);
              const elapsedStr = formatFocusDuration(checkpointSec);
              const totalStr = formatFocusDuration(prev.durationSeconds);
              nudgeMsg = `🔔 Nudge ${idx + 1}/${prev.nudgeCheckpoints.length}: ${elapsedStr} elapsed of ${totalStr} target (${percent}%). Stay centered!`;
              nudgeTimestamp = Date.now();

              // Record into Nudge History
              const newHistoryRecord: NudgeHistoryRecord = {
                id: 'nh-' + Date.now() + '-' + idx,
                taskId: prev.taskId,
                taskTitle: prev.taskTitle || 'Ad-hoc Focus Sprint',
                lifeAreaEmoji: prev.lifeAreaEmoji || '🎯',
                timestamp: new Date().toISOString(),
                elapsedSeconds: checkpointSec,
                totalDurationSeconds: prev.durationSeconds,
                nudgeIndex: idx + 1,
                totalNudges: prev.nudgeCheckpoints.length,
              };
              setNudgeHistory((hist) => [newHistoryRecord, ...hist]);
            }
          });

          if (nextRemaining <= 0) {
            // Timer finished! Play completion chime
            playTimerCompleteChime();

            // Log time to task if taskId exists
            if (prev.taskId) {
              const minutesSpent = Math.max(1, Math.round(prev.durationSeconds / 60));
              setTasks((currentTasks) =>
                currentTasks.map((t) =>
                  t.id === prev.taskId
                    ? { ...t, focusMinutesLogged: (t.focusMinutesLogged || 0) + minutesSpent }
                    : t
                )
              );
            }

            return {
              ...prev,
              remainingSeconds: 0,
              isRunning: false,
              isPaused: false,
              triggeredNudgeIndices: newTriggered,
              lastNudgeMessage: `🎉 Focus sprint complete! Target of ${formatFocusDuration(prev.durationSeconds)} reached. Excellent work!`,
              lastNudgeTimestamp: Date.now(),
            };
          }

          return {
            ...prev,
            remainingSeconds: nextRemaining,
            triggeredNudgeIndices: newTriggered,
            lastNudgeMessage: nudgeMsg,
            lastNudgeTimestamp: nudgeTimestamp,
          };
        });
      }, 1000);
    }

    return () => {
      if (interval) clearInterval(interval);
    };
  }, [focusSession.isRunning, focusSession.isPaused, focusSession.remainingSeconds]);

  // Handler functions
  const addCapture = (
    title: string,
    type: 'text' | 'voice' | 'photo' = 'text',
    transcript?: string,
    suggestedLifeAreaId?: string,
    imageUrl?: string,
    noteText?: string
  ) => {
    triggerHaptic('capture');
    const newItem: CaptureItem = {
      id: 'cap-' + Date.now(),
      title,
      type,
      transcript: transcript || noteText,
      noteText: noteText || transcript,
      imageUrl,
      createdAt: new Date().toISOString(),
      status: 'unprocessed',
      suggestedLifeAreaId,
    };
    setCaptures((prev) => [newItem, ...prev]);
  };

  const deleteCapture = (id: string) => {
    setCaptures((prev) => prev.filter((c) => c.id !== id));
  };

  const promoteCaptureToTask = (
    captureId: string,
    taskData: {
      title: string;
      description?: string;
      lifeAreaId: string;
      priority: 'low' | 'medium' | 'high';
      dueDate?: string;
      tags: string[];
      focusMinutesTarget?: number;
      imageUrl?: string;
    }
  ) => {
    const existingCapture = captures.find((c) => c.id === captureId);
    const newTask: TaskItem = {
      id: 'task-' + Date.now(),
      title: taskData.title,
      description: taskData.description,
      lifeAreaId: taskData.lifeAreaId,
      status: 'todo',
      priority: taskData.priority,
      dueDate: taskData.dueDate,
      tags: taskData.tags,
      createdAt: new Date().toISOString(),
      focusMinutesTarget: taskData.focusMinutesTarget || 15,
      focusMinutesLogged: 0,
      captureItemId: captureId,
      imageUrl: taskData.imageUrl || existingCapture?.imageUrl,
    };

    setTasks((prev) => [newTask, ...prev]);
    setCaptures((prev) =>
      prev.map((c) => (c.id === captureId ? { ...c, status: 'promoted' } : c))
    );
  };

  const promoteCaptureToJournal = (
    captureId: string,
    journalData: {
      title: string;
      content: string;
      lifeAreaId: string;
      energyLevel: 'low' | 'medium' | 'high';
      moodEmoji: string;
      tags: string[];
    }
  ) => {
    const newEntry: JournalEntry = {
      id: 'jou-' + Date.now(),
      title: journalData.title,
      content: journalData.content,
      lifeAreaId: journalData.lifeAreaId,
      energyLevel: journalData.energyLevel,
      moodEmoji: journalData.moodEmoji,
      createdAt: new Date().toISOString(),
      tags: journalData.tags,
    };
    setJournal((prev) => [newEntry, ...prev]);
    setCaptures((prev) =>
      prev.map((c) => (c.id === captureId ? { ...c, status: 'promoted' } : c))
    );
  };

  const toggleTaskStatus = (taskId: string) => {
    triggerHaptic('toggle');
    setTasks((prev) =>
      prev.map((t) => {
        if (t.id === taskId) {
          const nextStatus = t.status === 'completed' ? 'todo' : 'completed';
          return {
            ...t,
            status: nextStatus,
            completedAt: nextStatus === 'completed' ? new Date().toISOString() : undefined,
          };
        }
        return t;
      })
    );
  };

  const addTask = (task: Omit<TaskItem, 'id' | 'createdAt' | 'focusMinutesLogged'>) => {
    const newTask: TaskItem = {
      ...task,
      id: 'task-' + Date.now(),
      createdAt: new Date().toISOString(),
      focusMinutesLogged: 0,
    };
    setTasks((prev) => [newTask, ...prev]);
  };

  const updateTask = (id: string, updates: Partial<TaskItem>) => {
    setTasks((prev) => prev.map((t) => (t.id === id ? { ...t, ...updates } : t)));
  };

  const deleteTask = (id: string) => {
    setTasks((prev) => prev.filter((t) => t.id !== id));
  };

  const addJournalEntry = (entry: Omit<JournalEntry, 'id' | 'createdAt'>) => {
    const newEntry: JournalEntry = {
      ...entry,
      id: 'jou-' + Date.now(),
      createdAt: new Date().toISOString(),
    };
    setJournal((prev) => [newEntry, ...prev]);
  };

  const dismissNudge = (id: string) => {
    setNudges((prev) => prev.map((n) => (n.id === id ? { ...n, isDue: false } : n)));
  };

  const startFocusSession = (
    task: TaskItem,
    durationSeconds?: number,
    nudgesCount?: number
  ) => {
    const area = lifeAreas.find((a) => a.id === task.lifeAreaId);

    // Calculate total duration in seconds, enforcing minimum 30 seconds
    let totalSeconds = 15 * 60;
    if (typeof durationSeconds === 'number' && durationSeconds >= 30) {
      totalSeconds = durationSeconds;
    } else if (task.focusDurationSeconds && task.focusDurationSeconds >= 30) {
      totalSeconds = task.focusDurationSeconds;
    } else if (task.focusMinutesTarget) {
      totalSeconds = Math.max(30, Math.round(task.focusMinutesTarget * 60));
    }

    // Determine nudges count
    const finalNudgesCount = typeof nudgesCount === 'number'
      ? nudgesCount
      : typeof task.nudgesCount === 'number'
      ? task.nudgesCount
      : totalSeconds <= 60 ? 1 : 2;

    const checkpoints = calculateNudgeCheckpoints(totalSeconds, finalNudgesCount);

    setFocusSession({
      taskId: task.id,
      taskTitle: task.title,
      lifeAreaEmoji: area?.emoji || '🎯',
      durationSeconds: totalSeconds,
      remainingSeconds: totalSeconds,
      isRunning: true,
      isPaused: false,
      nudgesCount: finalNudgesCount,
      nudgeCheckpoints: checkpoints,
      triggeredNudgeIndices: [],
      lastNudgeMessage: undefined,
      lastNudgeTimestamp: undefined,
    });
  };

  const pauseFocusSession = () => {
    setFocusSession((prev) => ({ ...prev, isPaused: !prev.isPaused }));
  };

  const stopFocusSession = () => {
    setFocusSession((prev) => ({ ...prev, isRunning: false, isPaused: false }));
  };

  const updateFocusSessionNudges = (config: { mode: 'count' | 'interval'; value: number }) => {
    setFocusSession((prev) => {
      let newCheckpoints: number[] = [];
      let newCount = prev.nudgesCount;

      if (config.mode === 'interval') {
        const intervalSec = Math.max(30, config.value);
        newCheckpoints = calculateIntervalNudgeCheckpoints(prev.durationSeconds, intervalSec);
        newCount = newCheckpoints.length;
      } else {
        newCount = Math.max(0, config.value);
        newCheckpoints = calculateNudgeCheckpoints(prev.durationSeconds, newCount);
      }

      // Re-evaluate which checkpoints are already passed based on current elapsed time
      const elapsed = prev.durationSeconds - prev.remainingSeconds;
      const newTriggered: number[] = [];
      newCheckpoints.forEach((cp, idx) => {
        if (elapsed >= cp) {
          newTriggered.push(idx);
        }
      });

      return {
        ...prev,
        nudgesCount: newCount,
        nudgeCheckpoints: newCheckpoints,
        triggeredNudgeIndices: newTriggered,
      };
    });
  };

  const startFocusSession30sTest = () => {
    setFocusSession({
      taskId: 'test-30s',
      taskTitle: '🧪 30-Second Verification Sprint',
      lifeAreaEmoji: '⚡',
      durationSeconds: 30,
      remainingSeconds: 30,
      isRunning: true,
      isPaused: false,
      nudgesCount: 1,
      nudgeCheckpoints: [15], // 15-second halfway nudge
      triggeredNudgeIndices: [],
      lastNudgeMessage: 'Focus test initiated (30s target, 15s midpoint nudge)',
      lastNudgeTimestamp: Date.now(),
    });
  };

  const addNudgeReaction = (id: string, reaction: NudgeHistoryRecord['reaction']) => {
    setNudgeHistory((prev) =>
      prev.map((item) => (item.id === id ? { ...item, reaction } : item))
    );
  };

  const clearNudgeHistory = () => {
    setNudgeHistory([]);
  };

  const resetAllData = () => {
    setLifeAreas(INITIAL_LIFE_AREAS);
    setTags(INITIAL_TAGS);
    setCaptures(INITIAL_CAPTURES);
    setTasks(INITIAL_TASKS);
    setJournal(INITIAL_JOURNAL);
    setNudges(INITIAL_NUDGES);
    setNudgeHistory([]);
    localStorage.clear();
  };

  return {
    lifeAreas,
    setLifeAreas,
    tags,
    setTags,
    captures,
    setCaptures,
    tasks,
    setTasks,
    journal,
    setJournal,
    nudges,
    setNudges,
    nudgeHistory,
    setNudgeHistory,
    addNudgeReaction,
    clearNudgeHistory,
    focusSession,
    setFocusSession,
    addCapture,
    deleteCapture,
    promoteCaptureToTask,
    promoteCaptureToJournal,
    toggleTaskStatus,
    addTask,
    updateTask,
    deleteTask,
    addJournalEntry,
    dismissNudge,
    startFocusSession,
    pauseFocusSession,
    stopFocusSession,
    updateFocusSessionNudges,
    startFocusSession30sTest,
    resetAllData,
  };
}
