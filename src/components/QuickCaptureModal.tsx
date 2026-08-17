import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { LifeArea, CaptureType } from '../types';
import { X, Mic, FileText, Camera } from 'lucide-react';

interface QuickCaptureModalProps {
  isOpen: boolean;
  onClose: () => void;
  lifeAreas: LifeArea[];
  onAddCapture: (
    title: string,
    type: CaptureType,
    transcript?: string,
    suggestedLifeAreaId?: string
  ) => void;
}

export const QuickCaptureModal: React.FC<QuickCaptureModalProps> = ({
  isOpen,
  onClose,
  lifeAreas,
  onAddCapture,
}) => {
  const [title, setTitle] = useState('');
  const [captureType, setCaptureType] = useState<CaptureType>('text');
  const [selectedAreaId, setSelectedAreaId] = useState<string>('');
  const [isRecording, setIsRecording] = useState(false);
  const [recordedVoiceText, setRecordedVoiceText] = useState('');

  const handleStartVoiceRecord = () => {
    setIsRecording(true);
    setRecordedVoiceText('Recording voice thought...');
    setTimeout(() => {
      setRecordedVoiceText(
        'Captured thought: Schedule doctor appointment and renew prescription by Friday.'
      );
      setIsRecording(false);
      setTitle('Voice note: Schedule doctor appointment & renew prescription');
    }, 2000);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;

    onAddCapture(
      title.trim(),
      captureType,
      captureType === 'voice' ? recordedVoiceText : undefined,
      selectedAreaId || undefined
    );

    // Reset
    setTitle('');
    setRecordedVoiceText('');
    setSelectedAreaId('');
    setCaptureType('text');
    onClose();
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
          onClick={onClose}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.94, y: 12 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.94, y: 12 }}
            transition={{ duration: 0.2, ease: [0.16, 1, 0.3, 1] }}
            onClick={(e) => e.stopPropagation()}
            className="dark-card text-white rounded-[32px] max-w-lg w-full p-6 sm:p-7 shadow-2xl space-y-5"
          >
            <div className="flex items-center justify-between pb-3 border-b border-white/10">
              <div>
                <span className="label text-[#FF5B5B]">Frictionless Input</span>
                <h3 className="text-xl font-bold text-white tracking-tight">Quick Capture</h3>
              </div>
              <button
                id="quick-capture-close-btn"
                onClick={onClose}
                className="p-1.5 rounded-full text-white/50 hover:text-white transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Capture Type Selector */}
            <div className="grid grid-cols-3 gap-2 p-1 bg-white/5 rounded-2xl border border-white/10 text-xs font-mono">
              <button
                type="button"
                id="capture-type-text"
                onClick={() => setCaptureType('text')}
                className={`flex items-center justify-center space-x-2 py-2 rounded-xl font-bold transition-all cursor-pointer ${
                  captureType === 'text'
                    ? 'bg-[#FF5B5B] text-white'
                    : 'text-white/60 hover:text-white'
                }`}
              >
                <FileText className="w-4 h-4" />
                <span>Text Note</span>
              </button>

              <button
                type="button"
                id="capture-type-voice"
                onClick={() => setCaptureType('voice')}
                className={`flex items-center justify-center space-x-2 py-2 rounded-xl font-bold transition-all cursor-pointer ${
                  captureType === 'voice'
                    ? 'bg-[#FF5B5B] text-white'
                    : 'text-white/60 hover:text-white'
                }`}
              >
                <Mic className="w-4 h-4" />
                <span>Voice Note</span>
              </button>

              <button
                type="button"
                id="capture-type-photo"
                onClick={() => setCaptureType('photo')}
                className={`flex items-center justify-center space-x-2 py-2 rounded-xl font-bold transition-all cursor-pointer ${
                  captureType === 'photo'
                    ? 'bg-[#FF5B5B] text-white'
                    : 'text-white/60 hover:text-white'
                }`}
              >
                <Camera className="w-4 h-4" />
                <span>Photo Note</span>
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              {/* Voice recorder simulation panel */}
              {captureType === 'voice' && (
                <div className="bg-white/5 border border-white/10 rounded-2xl p-4 text-center space-y-3">
                  {isRecording ? (
                    <div className="space-y-2">
                      <div className="w-10 h-10 mx-auto rounded-full bg-[#FF5B5B] text-white flex items-center justify-center animate-ping">
                        <Mic className="w-5 h-5" />
                      </div>
                      <p className="text-xs font-mono text-[#FF5B5B]">Listening to voice memo...</p>
                    </div>
                  ) : (
                    <div className="space-y-2">
                      <button
                        type="button"
                        id="start-voice-record-btn"
                        onClick={handleStartVoiceRecord}
                        className="inline-flex items-center space-x-2 bg-[#FF5B5B] hover:bg-[#ff4242] text-white px-4 py-2 rounded-full text-xs font-mono font-bold uppercase shadow-sm transition-all cursor-pointer"
                      >
                        <Mic className="w-4 h-4" />
                        <span>Tap to Dictate Memo</span>
                      </button>
                      {recordedVoiceText && (
                        <p className="text-xs text-white/80 italic bg-black/40 p-2.5 rounded-xl border border-white/10 font-sans">
                          "{recordedVoiceText}"
                        </p>
                      )}
                    </div>
                  )}
                </div>
              )}

              {/* Note Input */}
              <div>
                <label className="label text-white/60 mb-1">
                  Captured Thought / Action Item
                </label>
                <textarea
                  id="capture-input-text"
                  rows={3}
                  required
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="Dump whatever thought is taking cognitive bandwidth..."
                  className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white focus:outline-hidden focus:border-[#FF5B5B] transition-all resize-none placeholder:text-zinc-400"
                />
              </div>

              {/* Optional Life Area Suggestion */}
              <div>
                <label className="label text-white/60 mb-1">
                  Suggested Life Area (Optional)
                </label>
                <select
                  id="capture-life-area-select"
                  value={selectedAreaId}
                  onChange={(e) => setSelectedAreaId(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white font-mono"
                >
                  <option value="" className="bg-[#111113]">Unassigned (Triage in Inbox later)</option>
                  {lifeAreas.map((area) => (
                    <option key={area.id} value={area.id} className="bg-[#111113]">
                      {area.emoji} {area.name}
                    </option>
                  ))}
                </select>
              </div>

              <div className="flex items-center justify-end space-x-3 pt-2">
                <button
                  type="button"
                  id="quick-capture-cancel-btn"
                  onClick={onClose}
                  className="px-4 py-2 text-xs font-mono uppercase text-white/60 hover:text-white rounded-full cursor-pointer font-bold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  id="quick-capture-submit-btn"
                  className="px-6 py-2.5 text-xs font-mono font-bold uppercase bg-[#FF5B5B] hover:bg-[#ff4242] text-white rounded-full shadow-md transition-all cursor-pointer"
                >
                  Save to Inbox
                </button>
              </div>
            </form>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};
