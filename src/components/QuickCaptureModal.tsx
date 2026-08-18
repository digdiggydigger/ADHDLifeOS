import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { LifeArea, CaptureType } from '../types';
import { triggerHaptic } from '../utils/haptics';
import {
  X,
  Mic,
  FileText,
  Camera,
  UploadCloud,
  RefreshCw,
  Image as ImageIcon,
  Check,
  AlertCircle,
  Sparkles,
} from 'lucide-react';

interface QuickCaptureModalProps {
  isOpen: boolean;
  onClose: () => void;
  lifeAreas: LifeArea[];
  onAddCapture: (
    title: string,
    type: CaptureType,
    transcript?: string,
    suggestedLifeAreaId?: string,
    imageUrl?: string,
    noteText?: string
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

  // Photo state
  const [photoDataUrl, setPhotoDataUrl] = useState<string | null>(null);
  const [photoNoteContent, setPhotoNoteContent] = useState('');
  const [isCameraActive, setIsCameraActive] = useState(false);
  const [cameraError, setCameraError] = useState<string | null>(null);
  const [facingMode, setFacingMode] = useState<'user' | 'environment'>('environment');
  const [isDraggingOver, setIsDraggingOver] = useState(false);

  const videoRef = useRef<HTMLVideoElement | null>(null);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const streamRef = useRef<MediaStream | null>(null);

  // Stop camera helper
  const stopCamera = () => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
    }
    if (videoRef.current) {
      videoRef.current.srcObject = null;
    }
    setIsCameraActive(false);
  };

  // Start camera helper
  const startCamera = async (mode: 'user' | 'environment' = facingMode) => {
    stopCamera();
    setCameraError(null);
    try {
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        throw new Error('Camera API is not supported in this browser environment.');
      }
      const stream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: mode,
          width: { ideal: 1280 },
          height: { ideal: 720 },
        },
        audio: false,
      });

      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        await videoRef.current.play().catch(() => {});
      }
      setIsCameraActive(true);
      triggerHaptic('light');
    } catch (err: any) {
      console.warn('Camera access error:', err);
      setIsCameraActive(false);
      setCameraError(
        err.name === 'NotAllowedError'
          ? 'Camera permission denied. You can still choose a photo from your camera roll or files below.'
          : 'Camera is unavailable or in use. Please select a photo from your camera roll or device.'
      );
    }
  };

  // Switch between front/back camera
  const toggleFacingMode = () => {
    const nextMode = facingMode === 'environment' ? 'user' : 'environment';
    setFacingMode(nextMode);
    startCamera(nextMode);
  };

  // Take snapshot from video stream
  const captureSnapshot = () => {
    if (!videoRef.current) return;
    const video = videoRef.current;
    const width = video.videoWidth || 640;
    const height = video.videoHeight || 480;

    const canvas = canvasRef.current || document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // If front camera, flip horizontally for natural mirror selfie feel
    if (facingMode === 'user') {
      ctx.translate(width, 0);
      ctx.scale(-1, 1);
    }
    ctx.drawImage(video, 0, 0, width, height);

    const dataUrl = canvas.toDataURL('image/jpeg', 0.88);
    setPhotoDataUrl(dataUrl);
    stopCamera();
    triggerHaptic('success');

    // Auto populate a default title if empty
    if (!title.trim()) {
      const now = new Date();
      setTitle(`Photo note - ${now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`);
    }
  };

  // File upload reader
  const processImageFile = (file: File) => {
    if (!file.type.startsWith('image/')) {
      alert('Please select a valid image file.');
      return;
    }
    const reader = new FileReader();
    reader.onload = (e) => {
      const result = e.target?.result as string;
      setPhotoDataUrl(result);
      stopCamera();
      triggerHaptic('success');
      if (!title.trim()) {
        const cleanFileName = file.name.replace(/\.[^/.]+$/, '');
        setTitle(cleanFileName.length > 2 ? cleanFileName : `Photo note (${new Date().toLocaleDateString()})`);
      }
    };
    reader.readAsDataURL(file);
  };

  const handleFileInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (files && files[0]) {
      processImageFile(files[0]);
    }
  };

  // Cleanup camera stream when switching away or unmounting
  useEffect(() => {
    if (!isOpen || captureType !== 'photo') {
      stopCamera();
    }
    return () => {
      stopCamera();
    };
  }, [isOpen, captureType]);

  const handleStartVoiceRecord = () => {
    triggerHaptic('capture');
    setIsRecording(true);
    setRecordedVoiceText('Recording voice thought...');
    setTimeout(() => {
      setRecordedVoiceText(
        'Captured thought: Schedule doctor appointment and renew prescription by Friday.'
      );
      setIsRecording(false);
      setTitle('Voice note: Schedule doctor appointment & renew prescription');
      triggerHaptic('success');
    }, 2000);
  };

  const handleCloseModal = () => {
    stopCamera();
    onClose();
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const finalTitle = title.trim() || (photoDataUrl ? 'Photo note' : 'Quick Capture');
    triggerHaptic('capture');

    onAddCapture(
      finalTitle,
      captureType,
      captureType === 'voice' ? recordedVoiceText : (photoNoteContent || undefined),
      selectedAreaId || undefined,
      captureType === 'photo' ? photoDataUrl || undefined : undefined,
      captureType === 'photo' ? photoNoteContent || undefined : undefined
    );

    // Reset
    stopCamera();
    setTitle('');
    setRecordedVoiceText('');
    setPhotoDataUrl(null);
    setPhotoNoteContent('');
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
          className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/70 backdrop-blur-xs overflow-y-auto"
          onClick={handleCloseModal}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.94, y: 12 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.94, y: 12 }}
            transition={{ duration: 0.2, ease: [0.16, 1, 0.3, 1] }}
            onClick={(e) => e.stopPropagation()}
            className="dark-card text-white rounded-3xl sm:rounded-[36px] max-w-lg w-full p-5 sm:p-7 shadow-2xl space-y-4 sm:space-y-5 my-auto max-h-[90vh] overflow-y-auto"
          >
            <div className="flex items-center justify-between pb-3 border-b border-white/10">
              <div>
                <span className="label text-[#FF5B5B] text-[10px] sm:text-xs">Frictionless Ingestion</span>
                <h3 className="text-lg sm:text-xl font-bold text-white tracking-tight">Quick Capture</h3>
              </div>
              <button
                id="quick-capture-close-btn"
                onClick={handleCloseModal}
                className="p-1.5 rounded-full text-white/50 hover:text-white hover:bg-white/10 transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Capture Type Selector */}
            <div className="grid grid-cols-3 gap-1.5 sm:gap-2 p-1 bg-white/5 rounded-2xl border border-white/10 text-xs font-mono">
              <button
                type="button"
                id="capture-type-text"
                onClick={() => {
                  triggerHaptic('light');
                  stopCamera();
                  setCaptureType('text');
                }}
                className={`flex items-center justify-center space-x-1.5 sm:space-x-2 py-2 rounded-xl font-bold transition-all cursor-pointer ${
                  captureType === 'text'
                    ? 'bg-[#FF5B5B] text-white shadow-xs'
                    : 'text-white/60 hover:text-white hover:bg-white/5'
                }`}
              >
                <FileText className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
                <span className="text-[11px] sm:text-xs">Text</span>
              </button>

              <button
                type="button"
                id="capture-type-voice"
                onClick={() => {
                  triggerHaptic('light');
                  stopCamera();
                  setCaptureType('voice');
                }}
                className={`flex items-center justify-center space-x-1.5 sm:space-x-2 py-2 rounded-xl font-bold transition-all cursor-pointer ${
                  captureType === 'voice'
                    ? 'bg-[#FF5B5B] text-white shadow-xs'
                    : 'text-white/60 hover:text-white hover:bg-white/5'
                }`}
              >
                <Mic className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
                <span className="text-[11px] sm:text-xs">Voice</span>
              </button>

              <button
                type="button"
                id="capture-type-photo"
                onClick={() => {
                  triggerHaptic('light');
                  setCaptureType('photo');
                }}
                className={`flex items-center justify-center space-x-1.5 sm:space-x-2 py-2 rounded-xl font-bold transition-all cursor-pointer ${
                  captureType === 'photo'
                    ? 'bg-[#FF5B5B] text-white shadow-xs'
                    : 'text-white/60 hover:text-white hover:bg-white/5'
                }`}
              >
                <Camera className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
                <span className="text-[11px] sm:text-xs">Photo Note</span>
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              {/* Photo Note specific capture controls */}
              {captureType === 'photo' && (
                <div className="space-y-3">
                  {/* Hidden inputs & canvas for capturing */}
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    className="hidden"
                    onChange={handleFileInputChange}
                  />
                  <canvas ref={canvasRef} className="hidden" />

                  {/* 1. When photo is captured or selected: Show Preview */}
                  {photoDataUrl ? (
                    <div className="relative rounded-2xl overflow-hidden border border-white/15 bg-black/40 group">
                      <img
                        src={photoDataUrl}
                        alt="Captured Note Attachment"
                        className="w-full h-44 sm:h-52 object-contain bg-black/60"
                      />
                      <div className="absolute top-2.5 right-2.5 flex items-center space-x-2">
                        <button
                          type="button"
                          onClick={() => {
                            triggerHaptic('light');
                            setPhotoDataUrl(null);
                          }}
                          className="bg-black/70 hover:bg-black text-white text-[11px] font-mono px-3 py-1.5 rounded-full border border-white/20 transition-all cursor-pointer flex items-center space-x-1 backdrop-blur-xs"
                        >
                          <RefreshCw className="w-3 h-3" />
                          <span>Retake / Change</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            triggerHaptic('light');
                            setPhotoDataUrl(null);
                          }}
                          className="bg-[#FF5B5B] hover:bg-[#ff4242] text-white p-1.5 rounded-full transition-all cursor-pointer"
                          title="Remove Photo"
                        >
                          <X className="w-3.5 h-3.5" />
                        </button>
                      </div>
                      <div className="absolute bottom-2 left-2 bg-black/75 px-2.5 py-0.5 rounded-md text-[10px] font-mono text-emerald-400 flex items-center space-x-1 border border-white/10">
                        <Check className="w-3 h-3 stroke-[3]" />
                        <span>Photo attached</span>
                      </div>
                    </div>
                  ) : isCameraActive ? (
                    /* 2. Live Camera Viewfinder */
                    <div className="space-y-2.5">
                      <div className="relative rounded-2xl overflow-hidden bg-black border border-white/20 aspect-4/3 flex items-center justify-center">
                        <video
                          ref={videoRef}
                          autoPlay
                          playsInline
                          muted
                          className={`w-full h-full object-cover ${facingMode === 'user' ? 'scale-x-[-1]' : ''}`}
                        />

                        {/* Viewfinder crosshairs overlay */}
                        <div className="absolute inset-0 pointer-events-none border-2 border-white/20 m-4 rounded-xl flex items-center justify-center">
                          <div className="w-12 h-12 border border-white/40 rounded-full"></div>
                        </div>

                        {/* Camera Toolbar Controls */}
                        <div className="absolute bottom-3 inset-x-0 flex items-center justify-center space-x-4 px-4">
                          <button
                            type="button"
                            onClick={toggleFacingMode}
                            className="bg-white/20 hover:bg-white/30 text-white p-2.5 rounded-full backdrop-blur-md transition-all cursor-pointer"
                            title="Switch Camera (Front/Back)"
                          >
                            <RefreshCw className="w-4 h-4" />
                          </button>

                          {/* Shutter Button */}
                          <button
                            type="button"
                            id="take-snapshot-btn"
                            onClick={captureSnapshot}
                            className="w-14 h-14 rounded-full bg-white hover:bg-zinc-200 border-4 border-[#FF5B5B] flex items-center justify-center shadow-lg transition-transform active:scale-90 cursor-pointer"
                            title="Take Photo"
                          >
                            <div className="w-9 h-9 rounded-full bg-[#FF5B5B]"></div>
                          </button>

                          <button
                            type="button"
                            onClick={stopCamera}
                            className="bg-black/60 hover:bg-black/80 text-white text-xs font-mono px-3 py-2 rounded-full border border-white/20 backdrop-blur-md transition-all cursor-pointer"
                          >
                            Cancel
                          </button>
                        </div>
                      </div>
                    </div>
                  ) : (
                    /* 3. Photo Action Options: Open Camera or Choose from Camera Roll */
                    <div className="space-y-2.5">
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                        <button
                          type="button"
                          id="open-live-camera-btn"
                          onClick={() => startCamera()}
                          className="flex flex-col items-center justify-center p-4 rounded-2xl bg-white/5 hover:bg-white/10 border border-white/10 hover:border-[#FF5B5B]/50 transition-all cursor-pointer group text-center space-y-2"
                        >
                          <div className="w-10 h-10 rounded-full bg-[#FF5B5B]/20 text-[#FF5B5B] group-hover:bg-[#FF5B5B] group-hover:text-white flex items-center justify-center transition-colors">
                            <Camera className="w-5 h-5" />
                          </div>
                          <div>
                            <span className="font-bold text-xs sm:text-sm text-white block">Take Photo</span>
                            <span className="text-[10px] text-white/50 font-mono">Use device camera</span>
                          </div>
                        </button>

                        <button
                          type="button"
                          id="choose-camera-roll-btn"
                          onClick={() => fileInputRef.current?.click()}
                          className="flex flex-col items-center justify-center p-4 rounded-2xl bg-white/5 hover:bg-white/10 border border-white/10 hover:border-purple-400/50 transition-all cursor-pointer group text-center space-y-2"
                        >
                          <div className="w-10 h-10 rounded-full bg-purple-500/20 text-purple-400 group-hover:bg-purple-600 group-hover:text-white flex items-center justify-center transition-colors">
                            <ImageIcon className="w-5 h-5" />
                          </div>
                          <div>
                            <span className="font-bold text-xs sm:text-sm text-white block">From Camera Roll</span>
                            <span className="text-[10px] text-white/50 font-mono">Select image from files</span>
                          </div>
                        </button>
                      </div>

                      {/* Drag & Drop Zone */}
                      <div
                        onDragOver={(e) => {
                          e.preventDefault();
                          setIsDraggingOver(true);
                        }}
                        onDragLeave={() => setIsDraggingOver(false)}
                        onDrop={(e) => {
                          e.preventDefault();
                          setIsDraggingOver(false);
                          if (e.dataTransfer.files && e.dataTransfer.files[0]) {
                            processImageFile(e.dataTransfer.files[0]);
                          }
                        }}
                        onClick={() => fileInputRef.current?.click()}
                        className={`p-3 rounded-xl border border-dashed text-center transition-all cursor-pointer ${
                          isDraggingOver
                            ? 'bg-[#FF5B5B]/10 border-[#FF5B5B]'
                            : 'bg-white/5 border-white/15 hover:border-white/30 text-white/60 hover:text-white'
                        }`}
                      >
                        <p className="text-[11px] font-mono">
                          Or drag & drop an image here / tap to browse
                        </p>
                      </div>

                      {cameraError && (
                        <div className="p-3 bg-amber-500/10 border border-amber-500/30 rounded-xl text-amber-300 text-xs font-mono flex items-start space-x-2">
                          <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                          <span>{cameraError}</span>
                        </div>
                      )}
                    </div>
                  )}

                  {/* Accompanying Photo Note Text Input */}
                  <div>
                    <label className="label text-white/60 mb-1 flex items-center justify-between text-[11px]">
                      <span>Accompanying Thoughts / Context</span>
                      <span className="text-zinc-400 font-normal">Optional description</span>
                    </label>
                    <textarea
                      id="photo-note-text"
                      rows={2}
                      value={photoNoteContent}
                      onChange={(e) => setPhotoNoteContent(e.target.value)}
                      placeholder="Add reflections, micro-steps, or insights about this photo note..."
                      className="w-full px-3.5 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-xs sm:text-sm text-white focus:outline-hidden focus:border-[#FF5B5B] transition-all resize-none placeholder:text-zinc-400"
                    />
                  </div>
                </div>
              )}

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

              {/* Note Title / Action Item Input */}
              <div>
                <label className="label text-white/60 mb-1 text-[11px]">
                  {captureType === 'photo'
                    ? 'Photo Note Title / Headline'
                    : 'Captured Thought / Action Item'}
                </label>
                <input
                  type="text"
                  id="capture-input-text"
                  required={captureType !== 'photo' || !photoDataUrl}
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder={
                    captureType === 'photo'
                      ? 'e.g., Whiteboard brainstorming diagram, receipt...'
                      : 'Dump whatever thought is taking cognitive bandwidth...'
                  }
                  className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white focus:outline-hidden focus:border-[#FF5B5B] transition-all placeholder:text-zinc-400"
                />
              </div>

              {/* Optional Life Area Suggestion */}
              <div>
                <label className="label text-white/60 mb-1 text-[11px]">
                  Suggested Life Area (Optional)
                </label>
                <select
                  id="capture-life-area-select"
                  value={selectedAreaId}
                  onChange={(e) => setSelectedAreaId(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-xs sm:text-sm text-white font-mono"
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
                  onClick={handleCloseModal}
                  className="px-4 py-2 text-xs font-mono uppercase text-white/60 hover:text-white rounded-full cursor-pointer font-bold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  id="quick-capture-submit-btn"
                  className="px-6 py-2.5 text-xs font-mono font-bold uppercase bg-[#FF5B5B] hover:bg-[#ff4242] text-white rounded-full shadow-md transition-all cursor-pointer flex items-center space-x-1.5"
                >
                  <span>Save to Inbox</span>
                </button>
              </div>
            </form>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};
