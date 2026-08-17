export type EnergyLevel = 'low' | 'medium' | 'high';
export type TaskPriority = 'low' | 'medium' | 'high';
export type TaskStatus = 'todo' | 'in_progress' | 'completed';
export type CaptureType = 'text' | 'voice' | 'photo';
export type CaptureStatus = 'unprocessed' | 'promoted' | 'archived';

export interface LifeArea {
  id: string;
  name: string;
  emoji: string;
  color: string; // e.g. 'indigo', 'emerald', 'amber', 'rose', 'purple', 'sky'
  sortOrder: number;
  isArchived: boolean;
}

export interface Tag {
  id: string;
  name: string;
  color: string;
}

export interface CaptureItem {
  id: string;
  title: string;
  type: CaptureType;
  transcript?: string;
  audioDurationSeconds?: number;
  createdAt: string;
  status: CaptureStatus;
  suggestedLifeAreaId?: string;
}

export interface TaskItem {
  id: string;
  title: string;
  description?: string;
  lifeAreaId: string;
  status: TaskStatus;
  priority: TaskPriority;
  dueDate?: string;
  tags: string[];
  createdAt: string;
  completedAt?: string;
  focusMinutesTarget?: number;
  focusMinutesLogged?: number;
  captureItemId?: string;
}

export interface JournalEntry {
  id: string;
  title: string;
  content: string;
  lifeAreaId: string;
  energyLevel: EnergyLevel;
  moodEmoji: string;
  createdAt: string;
  tags: string[];
}

export interface NudgeItem {
  id: string;
  label: string;
  schedule: string;
  type: 'break' | 'triage' | 'hydrate' | 'focus' | 'custom';
  isDue: boolean;
  lifeAreaId?: string;
}

export interface FocusSessionState {
  taskId: string | null;
  taskTitle: string;
  lifeAreaEmoji: string;
  durationSeconds: number;
  remainingSeconds: number;
  isRunning: boolean;
  isPaused: boolean;
}

export type ActiveTab = 'home' | 'capture' | 'tasks' | 'journal' | 'nudges' | 'settings';
