import { LifeArea, Tag, CaptureItem, TaskItem, JournalEntry, NudgeItem } from '../types';

export const INITIAL_LIFE_AREAS: LifeArea[] = [
  { id: 'area-1', name: 'Work & Career', emoji: '💼', color: 'indigo', sortOrder: 1, isArchived: false },
  { id: 'area-2', name: 'Health & Wellness', emoji: '🏋️', color: 'emerald', sortOrder: 2, isArchived: false },
  { id: 'area-3', name: 'Admin & Home', emoji: '📝', color: 'amber', sortOrder: 3, isArchived: false },
  { id: 'area-4', name: 'Personal Growth', emoji: '🧘', color: 'purple', sortOrder: 4, isArchived: false },
  { id: 'area-5', name: 'Hobbies & Projects', emoji: '🎨', color: 'rose', sortOrder: 5, isArchived: false },
];

export const INITIAL_TAGS: Tag[] = [
  { id: 'tag-1', name: 'quick-win', color: 'emerald' },
  { id: 'tag-2', name: 'deep-work', color: 'indigo' },
  { id: 'tag-3', name: 'low-dopamine', color: 'amber' },
  { id: 'tag-4', name: 'routine', color: 'purple' },
];

export const INITIAL_CAPTURES: CaptureItem[] = [
  {
    id: 'cap-1',
    title: 'Research car insurance rates before month ends',
    type: 'text',
    createdAt: new Date(Date.now() - 3600000 * 3).toISOString(),
    status: 'unprocessed',
    suggestedLifeAreaId: 'area-3',
  },
  {
    id: 'cap-2',
    title: 'Voice note: Idea for modular React component layout',
    type: 'voice',
    transcript: 'Remember to split the dashboard into small reusable widget components so focus isn’t overwhelming.',
    audioDurationSeconds: 14,
    createdAt: new Date(Date.now() - 3600000 * 8).toISOString(),
    status: 'unprocessed',
    suggestedLifeAreaId: 'area-1',
  },
  {
    id: 'cap-3',
    title: 'Order replacement water filter cartridges',
    type: 'text',
    createdAt: new Date(Date.now() - 3600000 * 18).toISOString(),
    status: 'unprocessed',
    suggestedLifeAreaId: 'area-3',
  },
];

const todayStr = new Date().toISOString().split('T')[0];
const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];

export const INITIAL_TASKS: TaskItem[] = [
  {
    id: 'task-1',
    title: 'Break down Q3 Project Proposal into 15-min micro-steps',
    description: 'Use body-doubling timer. Step 1: Write bullet points for problem statement only.',
    lifeAreaId: 'area-1',
    status: 'in_progress',
    priority: 'high',
    dueDate: todayStr,
    tags: ['deep-work'],
    createdAt: new Date(Date.now() - 86400000 * 2).toISOString(),
    focusMinutesTarget: 25,
    focusMinutesLogged: 15,
  },
  {
    id: 'task-2',
    title: 'Drink 500ml water & 10 min morning stretch',
    description: 'Quick dopamine reset before sitting at desk.',
    lifeAreaId: 'area-2',
    status: 'completed',
    priority: 'low',
    dueDate: todayStr,
    tags: ['quick-win', 'routine'],
    createdAt: new Date(Date.now() - 86400000).toISOString(),
    completedAt: new Date(Date.now() - 3600000 * 4).toISOString(),
    focusMinutesTarget: 10,
    focusMinutesLogged: 10,
  },
  {
    id: 'task-3',
    title: 'Sort through mail pile on kitchen counter',
    description: 'Trash junk mail immediately. Only keep bills to scan.',
    lifeAreaId: 'area-3',
    status: 'todo',
    priority: 'medium',
    dueDate: todayStr,
    tags: ['low-dopamine', 'quick-win'],
    createdAt: new Date(Date.now() - 86400000 * 3).toISOString(),
    focusMinutesTarget: 15,
    focusMinutesLogged: 0,
  },
  {
    id: 'task-4',
    title: 'Read Chapter 4 of ADHD Executive Function Guide',
    description: 'Highlight key strategies for time-blindness.',
    lifeAreaId: 'area-4',
    status: 'todo',
    priority: 'medium',
    dueDate: tomorrow,
    tags: ['routine'],
    createdAt: new Date(Date.now() - 86400000 * 4).toISOString(),
    focusMinutesTarget: 20,
    focusMinutesLogged: 0,
  },
  {
    id: 'task-5',
    title: 'Clean audio equipment & organize cables',
    description: 'Put cables into labeled Velcro ties.',
    lifeAreaId: 'area-5',
    status: 'todo',
    priority: 'low',
    dueDate: tomorrow,
    tags: ['quick-win'],
    createdAt: new Date(Date.now() - 86400000 * 5).toISOString(),
    focusMinutesTarget: 30,
    focusMinutesLogged: 0,
  },
];

export const INITIAL_JOURNAL: JournalEntry[] = [
  {
    id: 'jou-1',
    title: 'Morning Energy Check-in',
    content: 'Feeling a bit foggy today. Drank tea, set 15-min timers to keep tasks low-friction.',
    lifeAreaId: 'area-2',
    energyLevel: 'medium',
    moodEmoji: '⚡',
    createdAt: new Date(Date.now() - 3600000 * 5).toISOString(),
    tags: ['routine'],
  },
  {
    id: 'jou-2',
    title: 'Hyperfocus Reflection on Code Refactoring',
    content: 'Got into a great flow state after turning off notifications. Solved the state synchronization bug.',
    lifeAreaId: 'area-1',
    energyLevel: 'high',
    moodEmoji: '🔥',
    createdAt: new Date(Date.now() - 86400000).toISOString(),
    tags: ['deep-work'],
  },
];

export const INITIAL_NUDGES: NudgeItem[] = [
  {
    id: 'nudge-1',
    label: 'Unprocessed Inbox Items: 3 thoughts waiting',
    schedule: 'When inbox count > 0',
    type: 'triage',
    isDue: true,
  },
  {
    id: 'nudge-2',
    label: 'Hydration & Posture Reset',
    schedule: 'Every 90 minutes',
    type: 'hydrate',
    isDue: true,
  },
  {
    id: 'nudge-3',
    label: 'Evening Wind-down & Brain Dump',
    schedule: 'Daily at 9:00 PM',
    type: 'break',
    isDue: false,
  },
];
