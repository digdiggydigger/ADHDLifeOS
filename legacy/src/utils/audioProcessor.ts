import { LifeArea } from '../types';

/**
 * Supported MIME type detection for MediaRecorder
 */
export function getSupportedAudioMimeType(): string {
  if (typeof window === 'undefined' || !('MediaRecorder' in window)) {
    return 'audio/webm';
  }

  const candidateTypes = [
    'audio/webm;codecs=opus',
    'audio/webm',
    'audio/mp4',
    'audio/aac',
    'audio/ogg;codecs=opus',
    'audio/ogg',
    'audio/wav',
  ];

  for (const type of candidateTypes) {
    if (MediaRecorder.isTypeSupported(type)) {
      return type;
    }
  }

  return '';
}

/**
 * Converts an Audio Blob to a Base64 Data URL for persistent storage & playback
 */
export function blobToDataUrl(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onloadend = () => {
      if (typeof reader.result === 'string') {
        resolve(reader.result);
      } else {
        reject(new Error('Failed to convert audio blob to Data URL'));
      }
    };
    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
}

/**
 * NLP Keyword analysis for transcribing voice notes and auto-routing to Life Areas
 */
export function analyzeVoiceTranscript(
  transcript: string,
  lifeAreas: LifeArea[]
): {
  suggestedTitle: string;
  suggestedLifeAreaId: string | undefined;
  tags: string[];
} {
  const clean = transcript.trim();
  if (!clean) {
    return {
      suggestedTitle: 'Voice Memo',
      suggestedLifeAreaId: undefined,
      tags: ['Voice Note'],
    };
  }

  const lower = clean.toLowerCase();

  // 1. Generate Smart Title by stripping filler lead-ins
  let suggestedTitle = clean;
  const prefixesToRemove = [
    /^i need to\s+/i,
    /^i have to\s+/i,
    /^don't forget to\s+/i,
    /^remember to\s+/i,
    /^note to self:?\s+/i,
    /^quick thought:?\s+/i,
    /^memo:?\s+/i,
    /^remind me to\s+/i,
    /^please\s+/i,
    /^we should\s+/i,
    /^i want to\s+/i,
  ];

  for (const regex of prefixesToRemove) {
    if (regex.test(suggestedTitle)) {
      suggestedTitle = suggestedTitle.replace(regex, '');
      break;
    }
  }

  // Capitalize first letter
  if (suggestedTitle.length > 0) {
    suggestedTitle = suggestedTitle.charAt(0).toUpperCase() + suggestedTitle.slice(1);
  }

  // Limit title to first sentence or first 70 characters
  const sentenceEnd = suggestedTitle.search(/[.!?]/);
  if (sentenceEnd > 10 && sentenceEnd < 90) {
    suggestedTitle = suggestedTitle.slice(0, sentenceEnd).trim();
  } else if (suggestedTitle.length > 80) {
    suggestedTitle = suggestedTitle.slice(0, 77).trim() + '...';
  }

  // 2. Keyword dictionary for domain routing
  const domainKeywords: Record<string, string[]> = {
    health: [
      'doctor', 'dentist', 'medicine', 'prescription', 'health', 'hospital', 'clinic',
      'gym', 'workout', 'exercise', 'run', 'cardio', 'sleep', 'water', 'vitamins',
      'therapy', 'walk', 'diet', 'nutrition', 'physio', 'checkup', 'flu', 'headache'
    ],
    work: [
      'meeting', 'client', 'call', 'project', 'boss', 'email', 'presentation', 'deadline',
      'code', 'deploy', 'github', 'jira', 'review', 'sprint', 'report', 'manager',
      'customer', 'invoice', 'contract', 'interview', 'resume', 'sales', 'pitch'
    ],
    home: [
      'groceries', 'supermarket', 'clean', 'laundry', 'dishes', 'trash', 'cook', 'dinner',
      'vacuum', 'repair', 'house', 'apartment', 'plumber', 'electrician', 'hardware',
      'plants', 'garden', 'buy milk', 'fridge', 'kitchen', 'bedroom', 'order'
    ],
    finance: [
      'bank', 'budget', 'bill', 'pay', 'tax', 'rent', 'mortgage', 'money', 'credit',
      'subscription', 'receipt', 'expense', 'invest', 'savings', 'crypto', 'statement'
    ],
    growth: [
      'read', 'book', 'course', 'study', 'exam', 'research', 'podcast', 'article',
      'learn', 'practice', 'piano', 'guitar', 'language', 'meditate', 'journal', 'habit'
    ],
    social: [
      'mom', 'dad', 'sister', 'brother', 'friend', 'birthday', 'party', 'dinner',
      'catch up', 'gift', 'anniversary', 'family', 'hangout', 'coffee with'
    ],
  };

  // Check matching life area
  let bestAreaId: string | undefined = undefined;
  let highestScore = 0;

  for (const area of lifeAreas) {
    const areaNameLower = area.name.toLowerCase();
    let score = 0;

    // Check direct name match
    if (lower.includes(areaNameLower)) {
      score += 5;
    }

    // Check keywords related to area name
    for (const [domain, words] of Object.entries(domainKeywords)) {
      if (areaNameLower.includes(domain) || domain.includes(areaNameLower)) {
        for (const word of words) {
          if (lower.includes(word)) {
            score += 2;
          }
        }
      }
    }

    if (score > highestScore) {
      highestScore = score;
      bestAreaId = area.id;
    }
  }

  // Tags detection
  const tags: string[] = ['Voice Note'];
  if (lower.includes('urgent') || lower.includes('asap') || lower.includes('today')) {
    tags.push('High Priority');
  }
  if (lower.includes('idea') || lower.includes('brainstorm')) {
    tags.push('Idea');
  }

  return {
    suggestedTitle: suggestedTitle || 'Voice Note',
    suggestedLifeAreaId: bestAreaId,
    tags,
  };
}
