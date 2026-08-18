// Haptic feedback utility for mobile physical confirmation and multi-sensory feedback

export type HapticType = 'light' | 'medium' | 'toggle' | 'capture' | 'success';

let audioCtx: AudioContext | null = null;

function getAudioContext(): AudioContext | null {
  if (typeof window === 'undefined') return null;
  try {
    const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
    if (!AudioContextClass) return null;
    if (!audioCtx) {
      audioCtx = new AudioContextClass();
    }
    if (audioCtx && audioCtx.state === 'suspended') {
      audioCtx.resume().catch(() => {});
    }
    return audioCtx;
  } catch {
    return null;
  }
}

/**
 * Plays a tiny, crisp audio tick providing physical sensory confirmation
 * particularly on iOS devices where navigator.vibrate is restricted.
 */
function playTactileTick(type: HapticType) {
  try {
    const ctx = getAudioContext();
    if (!ctx) return;

    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = 'sine';
    const now = ctx.currentTime;

    if (type === 'toggle') {
      // Satisfying double-frequency tactile pop for task completion
      osc.frequency.setValueAtTime(320, now);
      osc.frequency.exponentialRampToValueAtTime(840, now + 0.04);
      gain.gain.setValueAtTime(0.06, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.05);
    } else if (type === 'capture') {
      // Crisp subtle trigger pop for capture
      osc.frequency.setValueAtTime(440, now);
      osc.frequency.exponentialRampToValueAtTime(220, now + 0.035);
      gain.gain.setValueAtTime(0.05, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.04);
    } else if (type === 'success') {
      // Harmonic affirmation
      osc.frequency.setValueAtTime(520, now);
      osc.frequency.exponentialRampToValueAtTime(660, now + 0.06);
      gain.gain.setValueAtTime(0.06, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.07);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.07);
    } else {
      // Light subtle tap
      osc.frequency.setValueAtTime(300, now);
      gain.gain.setValueAtTime(0.03, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.025);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.025);
    }
  } catch {
    // Ignore audio context errors silently
  }
}

/**
 * Triggers physical vibration on supported mobile devices
 * and subtle tactile audio confirmation.
 */
export function triggerHaptic(type: HapticType = 'light') {
  if (typeof window === 'undefined') return;

  // 1. Mobile Device Vibration API
  if (typeof navigator !== 'undefined' && 'vibrate' in navigator && typeof navigator.vibrate === 'function') {
    try {
      switch (type) {
        case 'toggle':
          // Double-pulse for rewarding task completion
          navigator.vibrate([18, 30, 25]);
          break;
        case 'capture':
          // Sharp single pulse for thought capture
          navigator.vibrate([16, 20, 16]);
          break;
        case 'success':
          navigator.vibrate([25, 40, 35]);
          break;
        case 'medium':
          navigator.vibrate(20);
          break;
        case 'light':
        default:
          navigator.vibrate(12);
          break;
      }
    } catch {
      // Ignore vibration errors if blocked by browser policy
    }
  }

  // 2. Tactile audio tick confirmation
  playTactileTick(type);
}

/**
 * Plays a definitive, pleasant resonant chime when a Focus Nudge fires.
 * Designed to cut through ADHD time-blindness without causing startle fatigue.
 */
export function playNudgeChime() {
  if (typeof window === 'undefined') return;

  // 1. Multi-pulse haptic vibration
  if (typeof navigator !== 'undefined' && 'vibrate' in navigator && typeof navigator.vibrate === 'function') {
    try {
      navigator.vibrate([40, 50, 40, 50, 70]);
    } catch {
      // ignore
    }
  }

  // 2. Definitive resonant bell chime (D5 -> A5 -> D6)
  try {
    const ctx = getAudioContext();
    if (!ctx) return;

    const notes = [587.33, 880.0, 1174.66]; // D5, A5, D6
    const startTime = ctx.currentTime;

    notes.forEach((freq, index) => {
      const noteTime = startTime + index * 0.11;
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'triangle';
      osc.frequency.setValueAtTime(freq, noteTime);

      // Smooth attack and gentle exponential decay
      gain.gain.setValueAtTime(0.001, noteTime);
      gain.gain.linearRampToValueAtTime(0.14, noteTime + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.001, noteTime + 0.45);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(noteTime);
      osc.stop(noteTime + 0.46);
    });
  } catch {
    // ignore
  }
}

/**
 * Plays a triumphant, rewarding completion chime when a Focus Session ends.
 */
export function playTimerCompleteChime() {
  if (typeof window === 'undefined') return;

  // 1. Rewarding triumphant vibration
  if (typeof navigator !== 'undefined' && 'vibrate' in navigator && typeof navigator.vibrate === 'function') {
    try {
      navigator.vibrate([60, 60, 60, 60, 120, 80, 150]);
    } catch {
      // ignore
    }
  }

  // 2. Harmonic fanfare (C5 -> E5 -> G5 -> C6)
  try {
    const ctx = getAudioContext();
    if (!ctx) return;

    const notes = [523.25, 659.25, 783.99, 1046.5];
    const startTime = ctx.currentTime;

    notes.forEach((freq, index) => {
      const noteTime = startTime + index * 0.12;
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, noteTime);

      gain.gain.setValueAtTime(0.001, noteTime);
      gain.gain.linearRampToValueAtTime(0.18, noteTime + 0.03);
      gain.gain.exponentialRampToValueAtTime(0.001, noteTime + (index === 3 ? 0.9 : 0.45));

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(noteTime);
      osc.stop(noteTime + (index === 3 ? 0.95 : 0.46));
    });
  } catch {
    // ignore
  }
}

/**
 * Helper to display human-readable seconds/minutes duration
 * e.g. 30s, 1m, 1m 30s, 10m
 */
export function formatFocusDuration(totalSeconds: number): string {
  if (totalSeconds < 60) {
    return `${totalSeconds}s`;
  }
  const mins = Math.floor(totalSeconds / 60);
  const remSecs = totalSeconds % 60;
  if (remSecs === 0) {
    return `${mins}m`;
  }
  return `${mins}m ${remSecs}s`;
}

/**
 * Helper to format digital time mm:ss or hh:mm:ss
 */
export function formatDigitalTime(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
}
