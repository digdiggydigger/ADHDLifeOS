import express from 'express';
import path from 'path';
import { GoogleGenAI, Type } from '@google/genai';

const app = express();
const PORT = 3000;

app.use(express.json({ limit: '10mb' }));

// Helper to get Gemini client lazily
function getGeminiClient(): GoogleGenAI | null {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return null;
  }
  return new GoogleGenAI({
    apiKey,
    httpOptions: {
      headers: {
        'User-Agent': 'aistudio-build',
      },
    },
  });
}

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    hasGeminiKey: Boolean(process.env.GEMINI_API_KEY),
    timestamp: new Date().toISOString(),
  });
});

// Daily Summary API endpoint using Gemini API (gemini-3.7-flash)
app.post('/api/gemini/daily-summary', async (req, res) => {
  try {
    const {
      date,
      completedTasks = [],
      inProgressTasks = [],
      journalEntries = [],
      capturesCount = 0,
      focusMinutesTotal = 0,
      tone = 'energizing', // 'energizing' | 'gentle' | 'bulleted' | 'coaching'
    } = req.body;

    const ai = getGeminiClient();

    // If Gemini key is not configured, provide intelligent heuristic fallback
    if (!ai) {
      const fallbackSummary = generateFallbackSummary(
        date,
        completedTasks,
        inProgressTasks,
        journalEntries,
        capturesCount,
        focusMinutesTotal,
        tone
      );
      return res.json({
        success: true,
        source: 'local_heuristic',
        summary: fallbackSummary,
        notice: 'Gemini API key is not set. Using smart local synthesis. You can attach your Gemini API key in Settings > Secrets for deeper AI analysis.',
      });
    }

    // Build prompt for Gemini
    const systemInstruction = `You are the empathetic, neurodivergent-informed AI coach inside "ADHD LifeOS".
Your mission is to craft a compassionate, executive-function-friendly Daily Summary for the user based on their actual completed tasks, journal reflections, focus sessions, and captured thoughts today.

Guidelines:
1. Focus on VALIDATION and DOPAMINE WINS. For ADHD individuals, recognizing small and large efforts alike prevents burnout and overcomes executive dysfunction.
2. Keep text punchy, visually segmented, and easy to scan (short sentences, bullet points, emojis).
3. Synthesize emotions & reflections from the journal entries with genuine empathy.
4. If there are few or no completed tasks, emphasize self-compassion, cognitive recovery, and intentional pausing—never shame or induce guilt.
5. Offer 1-2 ultra-low-friction, gentle kickstart recommendations for tomorrow (micro-steps that require minimal activation energy).
6. Tone preference requested: ${tone}. Adapt vocabulary appropriately (${
      tone === 'energizing' ? 'high dopamine, celebrating momentum, dynamic' :
      tone === 'gentle' ? 'soothing, peaceful, restorative, compassionate' :
      tone === 'coaching' ? 'strategic, practical, clear insights, structured' :
      'crisp, clear, scannable bullet points'
    }).`;

    const tasksCompletedSummary = completedTasks.length > 0
      ? completedTasks
          .map((t: any) => `- [Completed] "${t.title}" (${t.lifeAreaName || 'General'}, Priority: ${t.priority || 'medium'}, Focus Logged: ${t.focusMinutesLogged || 0}m)`)
          .join('\n')
      : 'No tasks marked completed today (remind user that rest and thought processing are valuable).';

    const tasksInProgressSummary = inProgressTasks.length > 0
      ? inProgressTasks
          .map((t: any) => `- [Open/In-Progress] "${t.title}" (${t.lifeAreaName || 'General'})`)
          .join('\n')
      : 'No lingering tasks recorded.';

    const journalsSummary = journalEntries.length > 0
      ? journalEntries
          .map((j: any) => `- [Journal Entry] "${j.title || 'Untitled'}": "${j.content}" (Energy: ${j.energyLevel || 'medium'}, Mood: ${j.moodEmoji || '😐'}, Area: ${j.lifeAreaName || 'General'})`)
          .join('\n\n')
      : 'No journal reflections written today.';

    const userPrompt = `Generate a Daily Summary for date: ${date || 'Today'}.

Context data from user's ADHD LifeOS:
- Total Focus Minutes Logged: ${focusMinutesTotal} minutes
- Completed Tasks (${completedTasks.length}):
${tasksCompletedSummary}

- Open / In-Progress Tasks (${inProgressTasks.length}):
${tasksInProgressSummary}

- Journal & Reflection Logs (${journalEntries.length}):
${journalsSummary}

- Thoughts / Notes Captured into Inbox today: ${capturesCount} items

Return a structured JSON output adhering to the requested schema.`;

    const response = await ai.models.generateContent({
      model: 'gemini-3.7-flash',
      contents: userPrompt,
      config: {
        systemInstruction,
        responseMimeType: 'application/json',
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            headline: {
              type: Type.STRING,
              description: 'A punchy, motivating 1-line headline summarizing the day (e.g. "⚡ High Momentum & Creative Breakthroughs").',
            },
            dopamineWins: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: '2 to 4 bullet points celebrating specific concrete accomplishments, focus time, or mental steps made today.',
            },
            journalReflections: {
              type: Type.STRING,
              description: '2 to 3 sentences synthesizing the user feelings, emotional energy, and journal reflections.',
            },
            focusStaminaInsight: {
              type: Type.STRING,
              description: '1 to 2 sentences analyzing focus stamina and cognitive pacing for the day.',
            },
            gentleTomorrowKickstart: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: '1 to 2 ultra-low-friction micro-actions recommended for tomorrow to build effortless momentum.',
            },
            fullNarrativeMarkdown: {
              type: Type.STRING,
              description: 'A warm, beautifully formatted markdown recap of the day (including bolding, headings, and friendly formatting).',
            },
          },
          required: [
            'headline',
            'dopamineWins',
            'journalReflections',
            'focusStaminaInsight',
            'gentleTomorrowKickstart',
            'fullNarrativeMarkdown',
          ],
        },
      },
    });

    const responseText = response.text || '';
    let parsedData;
    try {
      parsedData = JSON.parse(responseText);
    } catch {
      parsedData = {
        headline: '✨ Daily Reflection & Progress Summary',
        dopamineWins: completedTasks.map((t: any) => `Finished ${t.title}`),
        journalReflections: responseText.slice(0, 300),
        focusStaminaInsight: `${focusMinutesTotal} minutes of deep focus logged today.`,
        gentleTomorrowKickstart: ['Choose one high-impact micro-step in the morning.'],
        fullNarrativeMarkdown: responseText,
      };
    }

    return res.json({
      success: true,
      source: 'gemini_3.7_flash',
      summary: parsedData,
    });
  } catch (error: any) {
    console.error('Error generating daily summary with Gemini:', error);
    // Graceful fallback on API error
    const fallback = generateFallbackSummary(
      req.body.date,
      req.body.completedTasks || [],
      req.body.inProgressTasks || [],
      req.body.journalEntries || [],
      req.body.capturesCount || 0,
      req.body.focusMinutesTotal || 0,
      req.body.tone || 'energizing'
    );
    return res.json({
      success: true,
      source: 'local_heuristic_fallback',
      summary: fallback,
      errorDetails: error.message || 'Gemini API call encountered an issue.',
    });
  }
});

// Helper for high quality local heuristic summary
function generateFallbackSummary(
  date: string,
  completedTasks: any[],
  inProgressTasks: any[],
  journalEntries: any[],
  capturesCount: number,
  focusMinutesTotal: number,
  tone: string
) {
  const completedCount = completedTasks.length;
  const journalCount = journalEntries.length;

  let headline = '✨ Steady Progress & Mindful Momentum';
  if (completedCount >= 3 && focusMinutesTotal >= 30) {
    headline = '🔥 Exceptional Focus & Execution Flow';
  } else if (completedCount > 0) {
    headline = '⚡ Meaningful Steps Forward & Dopamine Wins';
  } else if (journalCount > 0) {
    headline = '🌱 Mindful Reflection & Thought Alignment';
  } else {
    headline = '🌿 Restorative Rhythm & Recharging Energy';
  }

  const dopamineWins: string[] = [];
  if (completedCount > 0) {
    completedTasks.slice(0, 3).forEach((t) => {
      dopamineWins.push(`Conquered "${t.title}" in ${t.lifeAreaName || 'daily tasks'}`);
    });
  } else {
    dopamineWins.push('Protected mental bandwidth and processed thoughts');
  }

  if (focusMinutesTotal > 0) {
    dopamineWins.push(`Dedicated ${focusMinutesTotal} minutes to intentional focus sessions`);
  }

  if (capturesCount > 0) {
    dopamineWins.push(`Offloaded ${capturesCount} spontaneous ideas into Inbox to prevent mental clutter`);
  }

  const moodEmojis = journalEntries.map((j) => j.moodEmoji).filter(Boolean);
  const moodsStr = moodEmojis.length > 0 ? ` (${moodEmojis.join(' ')})` : '';

  const journalReflections = journalCount > 0
    ? `Logged ${journalCount} reflection entry today${moodsStr}. You captured thoughtful awareness around your day's experiences, clarifying internal priorities.`
    : 'No formal journal reflections logged today—consider jotting a quick 1-sentence thought before wrapping up.';

  const focusStaminaInsight = focusMinutesTotal > 0
    ? `You channeled ${focusMinutesTotal} minutes of targeted energy today. Pacing yourself with structured checkpoints keeps executive strain in check.`
    : 'No active focus timers were recorded today. Remember that taking space to reset is vital for neurodivergent stamina.';

  const tomorrowKickstart: string[] = [];
  if (inProgressTasks.length > 0) {
    tomorrowKickstart.push(`Start with a 5-minute micro-pass on "${inProgressTasks[0].title}"`);
  } else {
    tomorrowKickstart.push('Review your Capture Inbox over morning tea for quick 2-minute triages');
  }
  tomorrowKickstart.push('Set one single high-priority milestone before opening incoming distractions');

  const fullNarrativeMarkdown = `### ${headline}

**Today's Highlights & Accomplishments:**
${dopamineWins.map((w) => `- ${w}`).join('\n')}

**Reflections & Emotional Space:**
${journalReflections}

**Focus & Executive Stamina:**
${focusStaminaInsight}

**Tomorrow's Kickstart:**
${tomorrowKickstart.map((k) => `1. ${k}`).join('\n')}`;

  return {
    headline,
    dopamineWins,
    journalReflections,
    focusStaminaInsight,
    gentleTomorrowKickstart: tomorrowKickstart,
    fullNarrativeMarkdown,
  };
}

async function startServer() {
  if (process.env.NODE_ENV !== 'production') {
    const { createServer: createViteServer } = await import('vite');
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.resolve(process.cwd(), 'dist');
    app.use(express.static(distPath));
    // For SPA fallback in Express 5
    app.use((req, res, next) => {
      if (req.method === 'GET' && !req.path.startsWith('/api/')) {
        return res.sendFile(path.resolve(distPath, 'index.html'));
      }
      next();
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`ADHD LifeOS Server running on http://localhost:${PORT}`);
  });
}

startServer().catch((err) => {
  console.error('Failed to start server:', err);
});
