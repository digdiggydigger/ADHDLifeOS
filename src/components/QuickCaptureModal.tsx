import React, { useState, useRef, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { LifeArea, CaptureType } from '../types';
import { triggerHaptic, formatDigitalTime } from '../utils/haptics';
import {
  getSupportedAudioMimeType,
  blobToDataUrl,
  analyzeVoiceTranscript,
} from '../utils/audioProcessor';
import {
  X,
  Mic,
  FileText,
  Camera,
  RefreshCw,
  Image as ImageIcon,
  Check,
  AlertCircle,
  Sparkles,
  Play,
  Pause,
  Square,
  Volume2,
  RotateCcw,
  Clock,
  Radio,
  Tag as TagIcon,
  CheckCircle2,
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
    noteText?: string,
    audioDurationSeconds?: number,
    audioDataUrl?: string
  ) => void;
}

type RecordingState = 'idle' | 'recording' | 'paused' | 'processing' | 'recorded';

export const QuickCaptureModal: React.FC<QuickCaptureModalProps> = ({
  isOpen,
  onClose,
  lifeAreas,
  onAddCapture,
}) => {
  const [title, setTitle] = useState('');
  const [captureType, setCaptureType] = useState<CaptureType>('text');
  const [selectedAreaId, setSelectedAreaId] = useState<string>('');

  // ---------------------------------------------
  // Voice Recording (MediaRecorder + Web Audio + Speech Recognition) State
  // ---------------------------------------------
  const [recordingState, setRecordingState] = useState<RecordingState>('idle');
  const [recordedVoiceText, setRecordedVoiceText] = useState('');
  const [interimVoiceText, setInterimVoiceText] = useState('');
  const [recordingDuration, setRecordingDuration] = useState(0);
  const [audioBlob, setAudioBlob] = useState<Blob | null>(null);
  const [audioDataUrl, setAudioDataUrl] = useState<string | null>(null);
  const [audioPlaybackTime, setAudioPlaybackTime] = useState(0);
  const [isPlayingAudio, setIsPlayingAudio] = useState(false);
  const [micError, setMicError] = useState<string | null>(null);
  const [autoDetectedAreaId, setAutoDetectedAreaId] = useState<string | null>(null);
  const [audioLevels, setAudioLevels] = useState<number[]>([15, 20, 30, 25, 40, 35, 20, 15]);

  // Audio References
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioStreamRef = useRef<MediaStream | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);
  const audioContextRef = useRef<AudioContext | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const animFrameRef = useRef<number | null>(null);
  const recordTimerRef = useRef<any>(null);
  const speechRecognitionRef = useRef<any>(null);
  const audioPlayerRef = useRef<HTMLAudioElement | null>(null);

  // ---------------------------------------------
  // Photo State
  // ---------------------------------------------
  const [photoDataUrl, setPhotoDataUrl] = useState<string | null>(null);
  const [photoNoteContent, setPhotoNoteContent] = useState('');
  const [isCameraActive, setIsCameraActive] = useState(false);
  const [cameraError, setCameraError] = useState<string | null>(null);
  const [facingMode, setFacingMode] = useState<'user' | 'environment'>('environment');
  const [isDraggingOver, setIsDraggingOver] = useState(false);

  const videoRef = useRef<HTMLVideoElement | null>(null);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const cameraStreamRef = useRef<MediaStream | null>(null);

  // ---------------------------------------------
  // Camera Management
  // ---------------------------------------------
  const stopCamera = useCallback(() => {
    if (cameraStreamRef.current) {
      cameraStreamRef.current.getTracks().forEach((track) => track.stop());
      cameraStreamRef.current = null;
    }
    if (videoRef.current) {
      videoRef.current.srcObject = null;
    }
    setIsCameraActive(false);
  }, []);

  const startCamera = async (mode: 'user' | 'environment' = facingMode) => {
    stopCamera();
    setCameraError(null);
    try {
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        throw new Error('Camera API is not supported in this browser.');
      }
      const stream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: mode,
          width: { ideal: 1280 },
          height: { ideal: 720 },
        },
        audio: false,
      });

      cameraStreamRef.current = stream;
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
          ? 'Camera permission denied. You can select a photo from your camera roll below.'
          : 'Camera is unavailable or in use. Please select a photo from your device.'
      );
    }
  };

  const toggleFacingMode = () => {
    const nextMode = facingMode === 'environment' ? 'user' : 'environment';
    setFacingMode(nextMode);
    startCamera(nextMode);
  };

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

    if (facingMode === 'user') {
      ctx.translate(width, 0);
      ctx.scale(-1, 1);
    }
    ctx.drawImage(video, 0, 0, width, height);

    const dataUrl = canvas.toDataURL('image/jpeg', 0.88);
    setPhotoDataUrl(dataUrl);
    stopCamera();
    triggerHaptic('success');

    if (!title.trim()) {
      const now = new Date();
      setTitle(`Photo note - ${now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`);
    }
  };

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

  // ---------------------------------------------
  // Voice Recording (MediaRecorder + AudioContext Analyser)
  // ---------------------------------------------
  const stopAudioTracks = useCallback(() => {
    if (audioStreamRef.current) {
      audioStreamRef.current.getTracks().forEach((t) => t.stop());
      audioStreamRef.current = null;
    }
    if (animFrameRef.current) {
      cancelAnimationFrame(animFrameRef.current);
      animFrameRef.current = null;
    }
    if (recordTimerRef.current) {
      clearInterval(recordTimerRef.current);
      recordTimerRef.current = null;
    }
    if (audioContextRef.current && audioContextRef.current.state !== 'closed') {
      try {
        audioContextRef.current.close().catch(() => {});
      } catch {
        // ignore
      }
      audioContextRef.current = null;
    }
    if (speechRecognitionRef.current) {
      try {
        speechRecognitionRef.current.stop();
      } catch {
        // ignore
      }
      speechRecognitionRef.current = null;
    }
  }, []);

  // Update visualizer waveform bars in real-time
  const startAudioVisualizer = (stream: MediaStream) => {
    try {
      const AudioCtxClass = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioCtxClass) return;

      const audioCtx = new AudioCtxClass();
      audioContextRef.current = audioCtx;
      const analyser = audioCtx.createAnalyser();
      analyser.fftSize = 64;
      analyser.smoothingTimeConstant = 0.8;
      analyserRef.current = analyser;

      const source = audioCtx.createMediaStreamSource(stream);
      source.connect(analyser);

      const bufferLength = analyser.frequencyBinCount;
      const dataArray = new Uint8Array(bufferLength);

      const updateVisualizer = () => {
        if (!analyserRef.current) return;
        analyserRef.current.getByteFrequencyData(dataArray);

        // Map to 12 aesthetic bars
        const numBars = 12;
        const step = Math.floor(bufferLength / numBars) || 1;
        const levels: number[] = [];

        for (let i = 0; i < numBars; i++) {
          const val = dataArray[i * step] || 0;
          // Scale between 12% and 100% height
          const barHeightPercent = Math.max(12, Math.min(100, Math.round((val / 255) * 100)));
          levels.push(barHeightPercent);
        }

        setAudioLevels(levels);
        animFrameRef.current = requestAnimationFrame(updateVisualizer);
      };

      updateVisualizer();
    } catch (e) {
      console.warn('Web Audio Visualizer initialization failed:', e);
    }
  };

  // Start MediaRecorder & Speech Recognition
  const startVoiceRecording = async () => {
    stopAudioTracks();
    setMicError(null);
    setAudioBlob(null);
    setAudioDataUrl(null);
    setRecordedVoiceText('');
    setInterimVoiceText('');
    setRecordingDuration(0);
    audioChunksRef.current = [];

    try {
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        throw new Error('Microphone access is not supported in this browser.');
      }

      triggerHaptic('capture');

      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        },
      });

      audioStreamRef.current = stream;

      // 1. Initialize MediaRecorder
      const mimeType = getSupportedAudioMimeType();
      const options: MediaRecorderOptions = mimeType ? { mimeType } : {};
      const recorder = new MediaRecorder(stream, options);
      mediaRecorderRef.current = recorder;

      recorder.ondataavailable = (event) => {
        if (event.data && event.data.size > 0) {
          audioChunksRef.current.push(event.data);
        }
      };

      recorder.onstop = async () => {
        setRecordingState('processing');
        const blobType = mimeType || 'audio/webm';
        const finalBlob = new Blob(audioChunksRef.current, { type: blobType });
        setAudioBlob(finalBlob);

        try {
          const dataUrl = await blobToDataUrl(finalBlob);
          setAudioDataUrl(dataUrl);
        } catch (e) {
          console.warn('Failed to convert audio blob:', e);
        }

        stopAudioTracks();
        setRecordingState('recorded');
        triggerHaptic('success');
      };

      recorder.start(250); // Request chunks every 250ms

      // 2. Start Live Speech Recognition if supported in browser
      const SpeechRecognitionClass =
        (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;

      if (SpeechRecognitionClass) {
        try {
          const recognition = new SpeechRecognitionClass();
          recognition.continuous = true;
          recognition.interimResults = true;
          recognition.lang = 'en-US';

          let cumulativeTranscript = '';

          recognition.onresult = (event: any) => {
            let interim = '';
            for (let i = event.resultIndex; i < event.results.length; ++i) {
              if (event.results[i].isFinal) {
                cumulativeTranscript += event.results[i][0].transcript + ' ';
              } else {
                interim += event.results[i][0].transcript;
              }
            }

            const currentFull = (cumulativeTranscript + interim).trim();
            setInterimVoiceText(interim);
            setRecordedVoiceText(currentFull);

            // Dynamically analyze transcript for title & life area
            if (currentFull.length > 5) {
              const analysis = analyzeVoiceTranscript(currentFull, lifeAreas);
              if (!title.trim() || title.startsWith('Voice note') || title.startsWith('Voice memo')) {
                setTitle(analysis.suggestedTitle);
              }
              if (analysis.suggestedLifeAreaId && !selectedAreaId) {
                setAutoDetectedAreaId(analysis.suggestedLifeAreaId);
                setSelectedAreaId(analysis.suggestedLifeAreaId);
              }
            }
          };

          recognition.onerror = (event: any) => {
            console.warn('Speech recognition warning:', event.error);
          };

          recognition.start();
          speechRecognitionRef.current = recognition;
        } catch (e) {
          console.warn('SpeechRecognition initialization error:', e);
        }
      }

      // 3. Start Audio Visualizer
      startAudioVisualizer(stream);

      // 4. Start Duration Timer
      setRecordingState('recording');
      let currentSec = 0;
      recordTimerRef.current = setInterval(() => {
        currentSec += 1;
        setRecordingDuration(currentSec);

        // Auto-stop at 2 minutes limit
        if (currentSec >= 120) {
          stopVoiceRecording();
        }
      }, 1000);
    } catch (err: any) {
      console.warn('Microphone error:', err);
      setRecordingState('idle');
      stopAudioTracks();
      setMicError(
        err.name === 'NotAllowedError'
          ? 'Microphone permission was denied. Please allow microphone access in your browser settings to record voice notes.'
          : 'Could not connect to microphone. You can still type your capture below.'
      );
    }
  };

  // Pause / Resume Voice Recording
  const togglePauseVoiceRecording = () => {
    if (!mediaRecorderRef.current) return;

    if (recordingState === 'recording') {
      mediaRecorderRef.current.pause();
      if (recordTimerRef.current) {
        clearInterval(recordTimerRef.current);
        recordTimerRef.current = null;
      }
      setRecordingState('paused');
      triggerHaptic('light');
    } else if (recordingState === 'paused') {
      mediaRecorderRef.current.resume();
      let currentSec = recordingDuration;
      recordTimerRef.current = setInterval(() => {
        currentSec += 1;
        setRecordingDuration(currentSec);
      }, 1000);
      setRecordingState('recording');
      triggerHaptic('light');
    }
  };

  // Finish and stop recording
  const stopVoiceRecording = () => {
    if (mediaRecorderRef.current && mediaRecorderRef.current.state !== 'inactive') {
      triggerHaptic('capture');
      mediaRecorderRef.current.stop();
    }
  };

  // Cancel & Discard Recording
  const cancelVoiceRecording = () => {
    stopAudioTracks();
    setRecordingState('idle');
    setAudioBlob(null);
    setAudioDataUrl(null);
    setRecordedVoiceText('');
    setInterimVoiceText('');
    setRecordingDuration(0);
    triggerHaptic('light');
  };

  // Audio Playback Controls
  const togglePlayRecordedAudio = () => {
    if (!audioPlayerRef.current) return;

    if (isPlayingAudio) {
      audioPlayerRef.current.pause();
      setIsPlayingAudio(false);
    } else {
      audioPlayerRef.current.play().catch(() => {});
      setIsPlayingAudio(true);
    }
    triggerHaptic('light');
  };

  // Post-processing fallback if speech recognition didn't yield text
  useEffect(() => {
    if (recordingState === 'recorded' && !recordedVoiceText.trim()) {
      const fallbackTranscript = `Recorded voice memo (${formatDigitalTime(recordingDuration)})`;
      setRecordedVoiceText(fallbackTranscript);
      if (!title.trim()) {
        const now = new Date();
        setTitle(`Voice memo - ${now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`);
      }
    } else if (recordingState === 'recorded' && recordedVoiceText.trim()) {
      const analysis = analyzeVoiceTranscript(recordedVoiceText, lifeAreas);
      if (!title.trim()) {
        setTitle(analysis.suggestedTitle);
      }
      if (analysis.suggestedLifeAreaId && !selectedAreaId) {
        setAutoDetectedAreaId(analysis.suggestedLifeAreaId);
        setSelectedAreaId(analysis.suggestedLifeAreaId);
      }
    }
  }, [recordingState, recordedVoiceText, recordingDuration, title, selectedAreaId, lifeAreas]);

  // Cleanup on unmount or close
  useEffect(() => {
    if (!isOpen) {
      stopCamera();
      stopAudioTracks();
      if (audioPlayerRef.current) {
        audioPlayerRef.current.pause();
      }
      setIsPlayingAudio(false);
    }
    return () => {
      stopCamera();
      stopAudioTracks();
    };
  }, [isOpen, stopCamera, stopAudioTracks]);

  const handleCloseModal = () => {
    stopCamera();
    stopAudioTracks();
    onClose();
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const finalTitle =
      title.trim() ||
      (captureType === 'voice'
        ? 'Voice Note'
        : captureType === 'photo'
        ? 'Photo Note'
        : 'Quick Capture');

    triggerHaptic('capture');

    onAddCapture(
      finalTitle,
      captureType,
      captureType === 'voice' ? recordedVoiceText : photoNoteContent || undefined,
      selectedAreaId || undefined,
      captureType === 'photo' ? photoDataUrl || undefined : undefined,
      captureType === 'photo' ? photoNoteContent || undefined : undefined,
      captureType === 'voice' ? recordingDuration : undefined,
      captureType === 'voice' ? audioDataUrl || undefined : undefined
    );

    // Reset Form
    stopCamera();
    stopAudioTracks();
    setTitle('');
    setRecordedVoiceText('');
    setInterimVoiceText('');
    setAudioBlob(null);
    setAudioDataUrl(null);
    setRecordingDuration(0);
    setRecordingState('idle');
    setPhotoDataUrl(null);
    setPhotoNoteContent('');
    setSelectedAreaId('');
    setAutoDetectedAreaId(null);
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
            {/* Modal Header */}
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

            {/* Capture Mode Selector */}
            <div className="grid grid-cols-3 gap-1.5 sm:gap-2 p-1 bg-white/5 rounded-2xl border border-white/10 text-xs font-mono">
              <button
                type="button"
                id="capture-type-text"
                onClick={() => {
                  triggerHaptic('light');
                  stopCamera();
                  stopAudioTracks();
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
                <span className="text-[11px] sm:text-xs">Voice Note</span>
              </button>

              <button
                type="button"
                id="capture-type-photo"
                onClick={() => {
                  triggerHaptic('light');
                  stopAudioTracks();
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
              {/* ============================================================ */}
              {/* VOICE CAPTURE SECTION (MediaRecorder + Waveform + Transcription) */}
              {/* ============================================================ */}
              {captureType === 'voice' && (
                <div className="space-y-3">
                  {/* Hidden Audio Player for Playback Preview */}
                  {audioDataUrl && (
                    <audio
                      ref={audioPlayerRef}
                      src={audioDataUrl}
                      onTimeUpdate={() => {
                        if (audioPlayerRef.current) {
                          setAudioPlaybackTime(audioPlayerRef.current.currentTime);
                        }
                      }}
                      onEnded={() => {
                        setIsPlayingAudio(false);
                        setAudioPlaybackTime(0);
                      }}
                      className="hidden"
                    />
                  )}

                  {/* 1. IDLE STATE: Large friendly one-tap record button */}
                  {recordingState === 'idle' && (
                    <div className="bg-white/5 border border-white/10 rounded-2xl p-5 sm:p-6 text-center space-y-4">
                      <div className="space-y-2">
                        <button
                          type="button"
                          id="start-mediarecorder-btn"
                          onClick={startVoiceRecording}
                          className="w-16 h-16 sm:w-20 sm:h-20 mx-auto rounded-full bg-[#FF5B5B] hover:bg-[#ff4242] text-white flex items-center justify-center shadow-lg shadow-[#FF5B5B]/30 hover:scale-105 active:scale-95 transition-all cursor-pointer group"
                        >
                          <Mic className="w-8 h-8 sm:w-9 sm:h-9 group-hover:scale-110 transition-transform" />
                        </button>
                        <div>
                          <h4 className="font-bold text-sm sm:text-base text-white">Tap to Record Voice Thought</h4>
                          <p className="text-[11px] sm:text-xs text-white/50 font-mono mt-0.5">
                            Real-time dictation & auto-transcription with MediaRecorder
                          </p>
                        </div>
                      </div>

                      {micError && (
                        <div className="p-3 bg-amber-500/10 border border-amber-500/30 rounded-xl text-amber-300 text-xs font-mono flex items-start space-x-2 text-left">
                          <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                          <span>{micError}</span>
                        </div>
                      )}
                    </div>
                  )}

                  {/* 2. ACTIVE RECORDING / PAUSED STATE: Live Waveform, Timer, and Controls */}
                  {(recordingState === 'recording' || recordingState === 'paused') && (
                    <div className="bg-white/5 border border-[#FF5B5B]/40 rounded-2xl p-4 sm:p-5 space-y-4">
                      {/* Status header & Duration */}
                      <div className="flex items-center justify-between">
                        <div className="flex items-center space-x-2">
                          <span className="relative flex h-3 w-3">
                            <span
                              className={`animate-ping absolute inline-flex h-full w-full rounded-full ${
                                recordingState === 'recording' ? 'bg-[#FF5B5B] opacity-75' : 'bg-amber-400 opacity-75'
                              }`}
                            ></span>
                            <span
                              className={`relative inline-flex rounded-full h-3 w-3 ${
                                recordingState === 'recording' ? 'bg-[#FF5B5B]' : 'bg-amber-400'
                              }`}
                            ></span>
                          </span>
                          <span className="text-xs font-mono font-bold text-white uppercase tracking-wider">
                            {recordingState === 'recording' ? 'Recording Voice Memo' : 'Recording Paused'}
                          </span>
                        </div>

                        {/* Digital Timer */}
                        <div className="flex items-center space-x-1.5 px-3 py-1 bg-black/40 rounded-full border border-white/10 font-mono text-xs text-[#FF5B5B] font-bold">
                          <Clock className="w-3.5 h-3.5" />
                          <span>{formatDigitalTime(recordingDuration)}</span>
                          <span className="text-white/40 text-[10px]">/ 02:00</span>
                        </div>
                      </div>

                      {/* Dynamic Waveform Visualizer */}
                      <div className="h-16 bg-black/50 rounded-xl border border-white/10 p-2 flex items-center justify-center space-x-1.5">
                        {audioLevels.map((level, idx) => (
                          <motion.div
                            key={idx}
                            className={`w-2 sm:w-2.5 rounded-full transition-all duration-75 ${
                              recordingState === 'recording'
                                ? 'bg-gradient-to-t from-[#FF5B5B] to-rose-400'
                                : 'bg-zinc-600'
                            }`}
                            style={{
                              height: `${recordingState === 'recording' ? level : 15}%`,
                            }}
                          />
                        ))}
                      </div>

                      {/* Live Interim Transcript Stream */}
                      {(recordedVoiceText || interimVoiceText) && (
                        <div className="bg-black/40 p-3 rounded-xl border border-white/10 text-xs font-sans text-white/90 max-h-24 overflow-y-auto leading-relaxed">
                          <div className="flex items-center space-x-1 text-[10px] text-[#FF5B5B] font-mono mb-1 font-bold">
                            <Radio className="w-3 h-3 animate-pulse" />
                            <span>Live Transcription Stream:</span>
                          </div>
                          <p>
                            <span>{recordedVoiceText}</span>
                            <span className="text-white/50 italic ml-1">{interimVoiceText}</span>
                          </p>
                        </div>
                      )}

                      {/* Recording Action Controls */}
                      <div className="flex items-center justify-center space-x-3 pt-1">
                        {/* Cancel / Discard */}
                        <button
                          type="button"
                          onClick={cancelVoiceRecording}
                          className="px-3.5 py-2 rounded-full bg-white/10 hover:bg-white/20 text-white text-xs font-mono font-bold transition-all cursor-pointer flex items-center space-x-1.5"
                          title="Discard recording"
                        >
                          <RotateCcw className="w-3.5 h-3.5" />
                          <span>Discard</span>
                        </button>

                        {/* Pause / Resume */}
                        <button
                          type="button"
                          onClick={togglePauseVoiceRecording}
                          className="px-3.5 py-2 rounded-full bg-white/10 hover:bg-white/20 text-white text-xs font-mono font-bold transition-all cursor-pointer flex items-center space-x-1.5"
                        >
                          {recordingState === 'recording' ? (
                            <>
                              <Pause className="w-3.5 h-3.5" />
                              <span>Pause</span>
                            </>
                          ) : (
                            <>
                              <Play className="w-3.5 h-3.5" />
                              <span>Resume</span>
                            </>
                          )}
                        </button>

                        {/* Finish & Transcribe */}
                        <button
                          type="button"
                          id="stop-and-transcribe-btn"
                          onClick={stopVoiceRecording}
                          className="px-5 py-2 rounded-full bg-[#FF5B5B] hover:bg-[#ff4242] text-white text-xs font-mono font-bold transition-all shadow-md cursor-pointer flex items-center space-x-1.5"
                        >
                          <Square className="w-3.5 h-3.5 fill-current" />
                          <span>Finish & Transcribe</span>
                        </button>
                      </div>
                    </div>
                  )}

                  {/* 3. PROCESSING / TRANSCRIBING STATE */}
                  {recordingState === 'processing' && (
                    <div className="bg-white/5 border border-white/10 rounded-2xl p-6 text-center space-y-3">
                      <div className="w-10 h-10 mx-auto rounded-full bg-[#FF5B5B]/20 text-[#FF5B5B] flex items-center justify-center animate-spin">
                        <RefreshCw className="w-5 h-5" />
                      </div>
                      <div>
                        <h4 className="font-bold text-sm text-white">Transcribing & Processing Audio...</h4>
                        <p className="text-[11px] text-white/50 font-mono">
                          Extracting actionable task title & suggested life area
                        </p>
                      </div>
                    </div>
                  )}

                  {/* 4. RECORDED STATE: Playback bar + Transcription & Editing */}
                  {recordingState === 'recorded' && (
                    <div className="bg-white/5 border border-emerald-500/30 rounded-2xl p-4 space-y-3.5">
                      {/* Audio Playback Bar */}
                      <div className="flex items-center justify-between bg-black/40 p-3 rounded-xl border border-white/10">
                        <div className="flex items-center space-x-3">
                          <button
                            type="button"
                            onClick={togglePlayRecordedAudio}
                            className="w-9 h-9 rounded-full bg-[#FF5B5B] hover:bg-[#ff4242] text-white flex items-center justify-center shadow-xs cursor-pointer transition-transform active:scale-95"
                          >
                            {isPlayingAudio ? (
                              <Pause className="w-4 h-4 fill-current" />
                            ) : (
                              <Play className="w-4 h-4 fill-current ml-0.5" />
                            )}
                          </button>
                          <div>
                            <div className="flex items-center space-x-1.5">
                              <Volume2 className="w-3.5 h-3.5 text-emerald-400" />
                              <span className="text-xs font-mono font-bold text-white">Voice Memo Recorded</span>
                            </div>
                            <span className="text-[10px] font-mono text-white/50">
                              {formatDigitalTime(Math.round(audioPlaybackTime))} / {formatDigitalTime(recordingDuration)}
                            </span>
                          </div>
                        </div>

                        <button
                          type="button"
                          onClick={() => {
                            setRecordingState('idle');
                            setAudioBlob(null);
                            setAudioDataUrl(null);
                          }}
                          className="text-[11px] font-mono text-white/60 hover:text-white px-2.5 py-1 rounded-lg hover:bg-white/10 transition-colors flex items-center space-x-1 cursor-pointer"
                        >
                          <RotateCcw className="w-3 h-3" />
                          <span>Re-record</span>
                        </button>
                      </div>

                      {/* Transcribed Text Editable Box */}
                      <div className="space-y-1.5">
                        <div className="flex items-center justify-between">
                          <label className="label text-emerald-400 text-[11px] flex items-center space-x-1">
                            <Sparkles className="w-3 h-3" />
                            <span>Auto-Transcribed Thought</span>
                          </label>
                          <span className="text-[10px] font-mono text-white/40">
                            {recordedVoiceText.split(/\s+/).filter(Boolean).length} words
                          </span>
                        </div>
                        <textarea
                          id="voice-transcription-text"
                          rows={3}
                          value={recordedVoiceText}
                          onChange={(e) => {
                            setRecordedVoiceText(e.target.value);
                            const analysis = analyzeVoiceTranscript(e.target.value, lifeAreas);
                            if (analysis.suggestedLifeAreaId && !selectedAreaId) {
                              setAutoDetectedAreaId(analysis.suggestedLifeAreaId);
                            }
                          }}
                          placeholder="Transcribed voice text will appear here. You can edit any details..."
                          className="w-full px-3.5 py-2.5 rounded-xl bg-black/40 border border-white/15 text-xs sm:text-sm text-white focus:outline-hidden focus:border-[#FF5B5B] transition-all resize-none font-sans"
                        />
                      </div>

                      {/* Auto-detected Area Suggestion Badge */}
                      {autoDetectedAreaId && (
                        <div className="flex items-center justify-between p-2.5 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-xs">
                          <div className="flex items-center space-x-2">
                            <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                            <span className="text-white/80 font-mono text-[11px]">
                              Auto-routed to{' '}
                              <strong className="text-white">
                                {lifeAreas.find((a) => a.id === autoDetectedAreaId)?.name}
                              </strong>
                            </span>
                          </div>
                          <button
                            type="button"
                            onClick={() => setSelectedAreaId(autoDetectedAreaId)}
                            className="text-[10px] font-mono font-bold text-emerald-400 hover:text-emerald-300 underline cursor-pointer"
                          >
                            Applied
                          </button>
                        </div>
                      )}
                    </div>
                  )}
                </div>
              )}

              {/* ============================================================ */}
              {/* PHOTO NOTE CAPTURE SECTION */}
              {/* ============================================================ */}
              {captureType === 'photo' && (
                <div className="space-y-3">
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    className="hidden"
                    onChange={handleFileInputChange}
                  />
                  <canvas ref={canvasRef} className="hidden" />

                  {/* Photo Preview when taken */}
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
                    /* Live Camera Viewfinder */
                    <div className="space-y-2.5">
                      <div className="relative rounded-2xl overflow-hidden bg-black border border-white/20 aspect-4/3 flex items-center justify-center">
                        <video
                          ref={videoRef}
                          autoPlay
                          playsInline
                          muted
                          className={`w-full h-full object-cover ${facingMode === 'user' ? 'scale-x-[-1]' : ''}`}
                        />

                        <div className="absolute inset-0 pointer-events-none border-2 border-white/20 m-4 rounded-xl flex items-center justify-center">
                          <div className="w-12 h-12 border border-white/40 rounded-full"></div>
                        </div>

                        <div className="absolute bottom-3 inset-x-0 flex items-center justify-center space-x-4 px-4">
                          <button
                            type="button"
                            onClick={toggleFacingMode}
                            className="bg-white/20 hover:bg-white/30 text-white p-2.5 rounded-full backdrop-blur-md transition-all cursor-pointer"
                            title="Switch Camera"
                          >
                            <RefreshCw className="w-4 h-4" />
                          </button>

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
                    /* Photo Action Options */
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

                  {/* Accompanying Photo Context */}
                  <div>
                    <label className="label text-white/60 mb-1 flex items-center justify-between text-[11px]">
                      <span>Accompanying Thoughts / Context</span>
                      <span className="text-zinc-400 font-normal">Optional</span>
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

              {/* ============================================================ */}
              {/* NOTE TITLE / HEADLINE INPUT (Common to all modes) */}
              {/* ============================================================ */}
              <div>
                <label className="label text-white/60 mb-1 text-[11px] flex items-center justify-between">
                  <span>
                    {captureType === 'voice'
                      ? 'Action Title (Auto-Generated from Voice)'
                      : captureType === 'photo'
                      ? 'Photo Note Headline'
                      : 'Captured Thought / Action Item'}
                  </span>
                  {captureType === 'voice' && title && (
                    <span className="text-emerald-400 font-mono text-[10px] flex items-center space-x-1">
                      <Sparkles className="w-2.5 h-2.5" />
                      <span>Smart Title</span>
                    </span>
                  )}
                </label>
                <input
                  type="text"
                  id="capture-input-text"
                  required={captureType === 'text'}
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder={
                    captureType === 'voice'
                      ? 'e.g., Schedule dentist appointment by Friday...'
                      : captureType === 'photo'
                      ? 'e.g., Whiteboard brainstorming diagram, receipt...'
                      : 'Dump whatever thought is taking cognitive bandwidth...'
                  }
                  className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-sm text-white focus:outline-hidden focus:border-[#FF5B5B] transition-all placeholder:text-zinc-400"
                />
              </div>

              {/* Suggested Life Area Selector */}
              <div>
                <label className="label text-white/60 mb-1 text-[11px] flex items-center justify-between">
                  <span>Target Life Area</span>
                  <span className="text-zinc-400 font-normal">Optional (auto-suggested)</span>
                </label>
                <select
                  id="capture-life-area-select"
                  value={selectedAreaId}
                  onChange={(e) => setSelectedAreaId(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-2xl bg-white/10 border border-white/10 text-xs sm:text-sm text-white font-mono"
                >
                  <option value="" className="bg-[#111113]">
                    Unassigned (Triage in Inbox later)
                  </option>
                  {lifeAreas.map((area) => (
                    <option key={area.id} value={area.id} className="bg-[#111113]">
                      {area.emoji} {area.name}
                    </option>
                  ))}
                </select>
              </div>

              {/* Modal Footer Action Buttons */}
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
                  <Check className="w-4 h-4 stroke-[2.5]" />
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
