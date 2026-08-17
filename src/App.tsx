import React, { useState } from 'react';
import { ActiveTab, TaskItem } from './types';
import { useLifeOSState } from './hooks/useLifeOSState';
import { Header } from './components/Header';
import { NavDock } from './components/NavDock';
import { HomeView } from './components/HomeView';
import { CaptureInboxView } from './components/CaptureInboxView';
import { QuickCaptureModal } from './components/QuickCaptureModal';
import { TaskListView } from './components/TaskListView';
import { JournalView } from './components/JournalView';
import { NudgesView } from './components/NudgesView';
import { SettingsView } from './components/SettingsView';
import { FocusTimerBar } from './components/FocusTimerBar';

export function App() {
  const [activeTab, setActiveTab] = useState<ActiveTab>('home');
  const [isQuickCaptureOpen, setIsQuickCaptureOpen] = useState(false);
  const [isFocusModalOpen, setIsFocusModalOpen] = useState(false);
  const [selectedLifeAreaFilter, setSelectedLifeAreaFilter] = useState<string | undefined>(undefined);

  const {
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
  } = useLifeOSState();

  const unprocessedCapturesCount = captures.filter((c) => c.status === 'unprocessed').length;
  const dueNudgesCount = nudges.filter((n) => n.isDue).length;
  const openTasksCount = tasks.filter((t) => t.status !== 'completed').length;

  const handleSelectLifeAreaFromHome = (areaId: string) => {
    setSelectedLifeAreaFilter(areaId);
    setActiveTab('tasks');
  };

  const handleStartFocusTask = (task: TaskItem, durationMinutes: number = 15) => {
    startFocusSession(task, durationMinutes);
    setIsFocusModalOpen(true);
  };

  const handleAddMinutesToFocus = (minutes: number) => {
    setFocusSession((prev) => ({
      ...prev,
      durationSeconds: prev.durationSeconds + minutes * 60,
      remainingSeconds: prev.remainingSeconds + minutes * 60,
    }));
  };

  return (
    <div className="min-h-screen bg-[#F8F7F4] text-[#1C1C1A] flex flex-col font-sans selection:bg-[#FF5B5B] selection:text-white">
      {/* Header */}
      <Header
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        unprocessedCount={unprocessedCapturesCount}
        dueNudgesCount={dueNudgesCount}
        openTasksCount={openTasksCount}
        focusSession={focusSession}
        onOpenQuickCapture={() => setIsQuickCaptureOpen(true)}
        onOpenFocusModal={() => setIsFocusModalOpen(true)}
      />

      {/* Main Container */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-4">
        {activeTab === 'home' && (
          <HomeView
            lifeAreas={lifeAreas}
            setLifeAreas={setLifeAreas}
            tasks={tasks}
            nudges={nudges}
            captures={captures}
            onDismissNudge={dismissNudge}
            onSelectLifeArea={handleSelectLifeAreaFromHome}
            setActiveTab={setActiveTab}
            onOpenQuickCapture={() => setIsQuickCaptureOpen(true)}
            onStartFocus={handleStartFocusTask}
          />
        )}

        {activeTab === 'capture' && (
          <CaptureInboxView
            captures={captures}
            lifeAreas={lifeAreas}
            tags={tags}
            onDeleteCapture={deleteCapture}
            onPromoteToTask={promoteCaptureToTask}
            onPromoteToJournal={promoteCaptureToJournal}
            onOpenQuickCapture={() => setIsQuickCaptureOpen(true)}
          />
        )}

        {activeTab === 'tasks' && (
          <TaskListView
            tasks={tasks}
            lifeAreas={lifeAreas}
            tags={tags}
            onToggleTaskStatus={toggleTaskStatus}
            onAddTask={addTask}
            onUpdateTask={updateTask}
            onDeleteTask={deleteTask}
            onStartFocus={handleStartFocusTask}
            selectedLifeAreaId={selectedLifeAreaFilter}
            onClearLifeAreaFilter={() => setSelectedLifeAreaFilter(undefined)}
          />
        )}

        {activeTab === 'journal' && (
          <JournalView
            journal={journal}
            lifeAreas={lifeAreas}
            tags={tags}
            onAddJournalEntry={addJournalEntry}
          />
        )}

        {activeTab === 'nudges' && (
          <NudgesView
            nudges={nudges}
            setNudges={setNudges}
            onDismissNudge={dismissNudge}
          />
        )}

        {activeTab === 'settings' && (
          <SettingsView
            lifeAreas={lifeAreas}
            setLifeAreas={setLifeAreas}
            tags={tags}
            setTags={setTags}
            onResetAllData={resetAllData}
          />
        )}
      </main>

      {/* Floating Bottom NavDock */}
      <NavDock
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        unprocessedCount={unprocessedCapturesCount}
        dueNudgesCount={dueNudgesCount}
        openTasksCount={openTasksCount}
        onOpenQuickCapture={() => setIsQuickCaptureOpen(true)}
      />

      {/* Quick Capture Modal with Entry/Exit animation */}
      <QuickCaptureModal
        isOpen={isQuickCaptureOpen}
        onClose={() => setIsQuickCaptureOpen(false)}
        lifeAreas={lifeAreas}
        onAddCapture={addCapture}
      />

      {/* Active Focus Session Widget / Full Modal */}
      <FocusTimerBar
        focusSession={focusSession}
        onPause={pauseFocusSession}
        onStop={stopFocusSession}
        onAddMinutes={handleAddMinutesToFocus}
        isOpenModal={isFocusModalOpen}
        onCloseModal={() => setIsFocusModalOpen(false)}
      />
    </div>
  );
}

export default App;
