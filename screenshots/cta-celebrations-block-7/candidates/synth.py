"""Three celebration-chime candidates, pure stdlib additive synthesis.

Peak-normalised to the SAME dBFS so E compares timbre rather than loudness (the
block's spec). 44.1 kHz, 16-bit mono, each under 1.0 s — the confetti is the star.
"""
import array, math, wave

RATE = 44100
PEAK_DBFS = -3.0

def note(freq, dur, partials, attack=0.008, decay=0.55, start=0.0, gain=1.0):
    """One struck tone: inharmonic partials under a shared exponential decay.

    `partials` is [(ratio, amplitude, decay_scale)]. Upper partials decay FASTER,
    which is what makes a struck bar read as struck rather than as an organ.
    """
    out = []
    n = int(dur * RATE)
    for i in range(n):
        t = i / RATE
        # Raised-cosine attack: soft enough that .ambient playback never clicks.
        env = 0.5 - 0.5 * math.cos(math.pi * min(t / attack, 1.0)) if t < attack else 1.0
        s = 0.0
        for ratio, amp, dscale in partials:
            s += amp * math.sin(2 * math.pi * freq * ratio * t) * math.exp(-t / (decay * dscale))
        out.append((start + t, env * s * gain))
    return out

def mix(voices, total):
    buf = [0.0] * int(total * RATE)
    for v in voices:
        for t, s in v:
            i = int(t * RATE)
            if 0 <= i < len(buf):
                buf[i] += s
    return buf

def write(path, buf):
    peak = max(abs(s) for s in buf) or 1.0
    target = (10 ** (PEAK_DBFS / 20)) * 32767
    scale = target / peak
    data = array.array("h", (int(max(-32768, min(32767, s * scale))) for s in buf))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    rms = math.sqrt(sum((s * scale) ** 2 for s in buf) / len(buf)) / 32767
    print(f"{path}  {len(buf)/RATE:.2f}s  peak {PEAK_DBFS:.1f} dBFS  rms {20*math.log10(rms):.1f} dBFS")

# A glockenspiel/celesta-ish strike: a touch of inharmonicity so it reads as a
# struck bar, not a sine beep. Upper partials fade fastest.
BELL = [(1.0, 1.00, 1.00), (2.76, 0.34, 0.45), (5.40, 0.13, 0.22), (8.93, 0.05, 0.12)]

C6, E6, G6 = 1046.50, 1318.51, 1567.98

# 1 — one note. The most restrained thing that still reads as "landed".
write("01-single-note.wav", mix([note(C6, 0.90, BELL, decay=0.30)], 0.90))

# 2 — a rising fifth. The classic "done", and the interval does the work.
write("02-rising-fifth.wav", mix([
    note(C6, 0.85, BELL, decay=0.22, start=0.00),
    note(G6, 0.85, BELL, decay=0.30, start=0.10, gain=0.95),
], 0.95))

# 3 — a major arpeggio with a shimmer octave on top. The most celebratory.
SHIMMER = BELL + [(2.01, 0.10, 0.30)]
write("03-rising-arpeggio.wav", mix([
    note(C6, 0.80, BELL, decay=0.16, start=0.00),
    note(E6, 0.80, BELL, decay=0.18, start=0.075),
    note(G6, 0.85, SHIMMER, decay=0.32, start=0.150, gain=1.0),
], 1.00))
