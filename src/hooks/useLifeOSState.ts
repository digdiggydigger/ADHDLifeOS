import { useState, useEffect } from 'react';
import { LifeArea, Tag, CaptureItem, TaskItem, JournalEntry, NudgeItem, FocusSessionState } from '../types';
import { INITIAL_LIFE_AREAS, INITIAL_TAGS, INITIAL_CAPTURES, INITIAL_TASKS, INITIAL_JOURNAL, INITIAL_NUDGES } from '../data/initialData';

const STORAGE_KEY_PREFIX = 'adhd_lifeos_';

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

  const [focusSession, setFocusSession] = useState<FocusSessionState>({
    taskId: null,
    taskTitle: '',
    lifeAreaEmoji: '⏱️',
    durationSeconds: 15 * 60,
    remainingSeconds: 15 * 60,
    isRunning: false,
    isPaused: false,
  });

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

  // Focus Timer Tick
  useEffect(() => {
    let interval: any = null;
    if (focusSession.isRunning && !focusSession.isPaused && focusSession.remainingSeconds > 0) {
      interval = setInterval(() => {
        setFocusSession((prev) => {
          if (prev.remainingSeconds <= 1) {
            // Timer finished! Log target minutes to task if taskId exists
            if (prev.taskId) {
              const minutesSpent = Math.round(prev.durationSeconds / 60);
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
            };
          }
          return { ...prev, remainingSeconds: prev.remainingSeconds - 1 };
        });
      }, 1000);
    }
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [focusSession.isRunning, focusSession.isPaused, focusSession.remainingSeconds]);

  // Handler functions
  const addCapture = (title: string, type: 'text' | 'voice' | 'photo' = 'text', transcript?: string, suggestedLifeAreaId?: string) => {
    const newItem: CaptureItem = {
      id: 'cap-' + Date.now(),
      title,
      type,
      transcript,
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
    }
  ) => {
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

  const startFocusSession = (task: TaskItem, durationMinutes: number = 15) => {
    const area = lifeAreas.find((a) => a.id === task.lifeAreaId);
    setFocusSession({
      taskId: task.id,
      taskTitle: task.title,
      lifeAreaEmoji: area?.emoji || '🎯',
      durationSeconds: durationMinutes * 60,
      remainingSeconds: durationMinutes * 60,
      isRunning: true,
      isPaused: false,
    });
  };

  const pauseFocusSession = () => {
    setFocusSession((prev) => ({ ...prev, isPaused: !prev.isPaused }));
  };

  const stopFocusSession = () => {
    setFocusSession((prev) => ({ ...prev, isRunning: false, isPaused: false }));
  };

  const resetAllData = () => {
    setLifeAreas(INITIAL_LIFE_AREAS);
    setTags(INITIAL_TAGS);
    setCaptures(INITIAL_CAPTURES);
    setTasks(INITIAL_TASKS);
    setJournal(INITIAL_JOURNAL);
    setNudges(INITIAL_NUDGES);
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
    resetAllData,
  };
}
