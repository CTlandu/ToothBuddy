import { useState, useEffect } from "react";

const slides = [
  {
    id: 0,
    bg: "linear-gradient(160deg, #0f2645 0%, #0369a1 60%, #38bdf8 100%)",
    accent: "#38bdf8",
    emoji: null,
    isWelcome: true,
  },
  {
    id: 1,
    bg: "linear-gradient(160deg, #0c1a3a 0%, #1e3a8a 60%, #3b82f6 100%)",
    accent: "#60a5fa",
    title: "Open & See Yourself!",
    subtitle: "Your front camera turns on so you can watch yourself brush. No more missing a spot!",
    emoji: "📷",
    illustration: "camera",
  },
  {
    id: 2,
    bg: "linear-gradient(160deg, #0a1628 0%, #1e3a5f 50%, #0ea5e9 100%)",
    accent: "#38bdf8",
    title: "Tap to Start Brushing!",
    subtitle: "Hit the big button and your timer begins. Brush for 2 full minutes to get 3 stars! ⭐⭐⭐",
    emoji: "🪥",
    illustration: "timer",
  },
  {
    id: 3,
    bg: "linear-gradient(160deg, #0f172a 0%, #1e1b4b 60%, #4f46e5 100%)",
    accent: "#818cf8",
    title: "Earn Gems & Rewards!",
    subtitle: "Every brush earns you 💎 gems. Unlock cool badges and build your streak. Can you hit 7 days?",
    emoji: "🏆",
    illustration: "rewards",
  },
  {
    id: 4,
    bg: "linear-gradient(160deg, #0a1628 0%, #064e3b 50%, #10b981 100%)",
    accent: "#34d399",
    title: "Track Your Progress!",
    subtitle: "Check your History tab to see every session. Watch your smile get brighter day by day! 😁",
    emoji: "📋",
    illustration: "history",
  },
  {
    id: 5,
    id: 5,
    bg: "linear-gradient(160deg, #1a0533 0%, #4c1d95 50%, #7c3aed 100%)",
    accent: "#a78bfa",
    isReady: true,
  },
];

/* ── Illustrations ── */
function CameraIllustration({ active }) {
  return (
    <svg width="200" height="190" viewBox="0 0 200 190" style={{ filter: "drop-shadow(0 12px 32px rgba(56,189,248,0.35))" }}>
      {/* Phone */}
      <rect x="40" y="20" width="120" height="155" rx="22" fill="#0f2645" stroke="#38bdf8" strokeWidth="2.5" />
      {/* Screen */}
      <rect x="50" y="35" width="100" height="120" rx="12" fill="#1e3a5f" />
      {/* Camera gradient face */}
      <rect x="50" y="35" width="100" height="120" rx="12" fill="url(#camGrad)" />
      <defs>
        <linearGradient id="camGrad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#0ea5e9" stopOpacity="0.5" />
          <stop offset="100%" stopColor="#38bdf8" stopOpacity="0.15" />
        </linearGradient>
      </defs>
      {/* Face silhouette */}
      <ellipse cx="100" cy="90" rx="28" ry="33" fill="rgba(255,255,255,0.15)" />
      <ellipse cx="100" cy="70" rx="18" ry="20" fill="rgba(255,255,255,0.18)" />
      {/* Eyes */}
      <circle cx="91" cy="84" r="4" fill="white" opacity="0.8" />
      <circle cx="109" cy="84" r="4" fill="white" opacity="0.8" />
      {/* Smile */}
      <path d="M91 96 Q100 104 109 96" stroke="white" strokeWidth="2.5" fill="none" strokeLinecap="round" opacity="0.8" />
      {/* Camera notch */}
      <rect x="82" y="38" width="36" height="8" rx="4" fill="#0f2645" />
      <circle cx="100" cy="42" r="2.5" fill="#38bdf8" />
      {/* Corner brackets */}
      {[
        [56, 41, 66, 41, 56, 51],
        [134, 41, 144, 41, 144, 51],
        [56, 149, 56, 139, 66, 149],
        [134, 149, 144, 149, 144, 139],
      ].map(([x1, y1, x2, y2, x3, y3], i) => (
        <polyline key={i} points={`${x1},${y1} ${x2},${y2} ${x3},${y3}`} stroke="#38bdf8" strokeWidth="2" fill="none" strokeLinecap="round" />
      ))}
      {/* Sparkles */}
      <text x="152" y="50" fontSize="18" style={{ animation: "sparkle 1.2s infinite alternate" }}>✨</text>
      <text x="25" y="75" fontSize="14">💫</text>
      {/* Home bar */}
      <rect x="80" y="168" width="40" height="4" rx="2" fill="#38bdf8" opacity="0.5" />
    </svg>
  );
}

function TimerIllustration() {
  const [t, setT] = useState(47);
  useEffect(() => {
    const iv = setInterval(() => setT((v) => (v >= 120 ? 0 : v + 1)), 80);
    return () => clearInterval(iv);
  }, []);
  const pct = t / 120;
  const r = 60, cx = 100, cy = 95;
  const circ = 2 * Math.PI * r;
  const dash = pct * circ;
  return (
    <svg width="200" height="190" viewBox="0 0 200 190" style={{ filter: "drop-shadow(0 12px 32px rgba(56,189,248,0.4))" }}>
      {/* BG circle */}
      <circle cx={cx} cy={cy} r={r + 14} fill="rgba(14,165,233,0.08)" />
      <circle cx={cx} cy={cy} r={r} fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth="12" />
      {/* Progress arc */}
      <circle cx={cx} cy={cy} r={r} fill="none" stroke="url(#arcGrad)" strokeWidth="12"
        strokeDasharray={`${dash} ${circ}`} strokeLinecap="round"
        transform={`rotate(-90 ${cx} ${cy})`} />
      <defs>
        <linearGradient id="arcGrad" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#38bdf8" />
          <stop offset="100%" stopColor="#818cf8" />
        </linearGradient>
      </defs>
      {/* Time text */}
      <text x={cx} y={cy - 10} textAnchor="middle" fill="white" fontSize="28" fontFamily="'Fredoka One', cursive" fontWeight="bold">
        {`${String(Math.floor(t / 60)).padStart(2, "0")}:${String(t % 60).padStart(2, "0")}`}
      </text>
      <text x={cx} y={cy + 18} textAnchor="middle" fill="rgba(255,255,255,0.5)" fontSize="13" fontFamily="Nunito, sans-serif" fontWeight="700">
        out of 2:00
      </text>
      {/* Stars */}
      {[0, 1, 2].map((i) => (
        <text key={i} x={cx - 22 + i * 22} y={cy + 46} textAnchor="middle" fontSize="20"
          style={{ filter: pct > (i + 1) / 3 ? "none" : "grayscale(1) opacity(0.25)" }}>⭐</text>
      ))}
      {/* Brush icon */}
      <text x="160" y="50" fontSize="28">🪥</text>
      <text x="22" y="55" fontSize="18">💧</text>
      <text x="155" y="155" fontSize="16">💧</text>
    </svg>
  );
}

function RewardsIllustration() {
  const [glow, setGlow] = useState(false);
  useEffect(() => {
    const iv = setInterval(() => setGlow((g) => !g), 900);
    return () => clearInterval(iv);
  }, []);
  return (
    <svg width="200" height="190" viewBox="0 0 200 190" style={{ filter: `drop-shadow(0 12px 32px rgba(129,140,248,${glow ? "0.6" : "0.3"}))`, transition: "filter 0.9s" }}>
      {/* Trophy */}
      <text x="68" y="95" fontSize="72">🏆</text>
      {/* Gems floating */}
      <text x="22" y="65" fontSize="22" style={{ animation: "float1 2s ease-in-out infinite" }}>💎</text>
      <text x="155" y="58" fontSize="18" style={{ animation: "float2 2.4s ease-in-out infinite" }}>💎</text>
      <text x="30" y="145" fontSize="16" style={{ animation: "float1 3s ease-in-out infinite" }}>⭐</text>
      <text x="150" y="140" fontSize="20" style={{ animation: "float2 2s ease-in-out infinite" }}>⭐</text>
      {/* Badge row */}
      {["🌟", "🔥", "👑"].map((b, i) => (
        <g key={i}>
          <rect x={38 + i * 46} y={148} width={38} height={34} rx={10}
            fill={i === 0 ? "rgba(99,102,241,0.3)" : "rgba(255,255,255,0.07)"}
            stroke={i === 0 ? "#818cf8" : "rgba(255,255,255,0.1)"} strokeWidth="1.5" />
          <text x={57 + i * 46} y={172} textAnchor="middle" fontSize="18">{i === 0 ? b : "🔒"}</text>
        </g>
      ))}
    </svg>
  );
}

function HistoryIllustration() {
  const rows = [
    { time: "8:02 AM", dur: "2:22", stars: 3 },
    { time: "9:45 PM", dur: "1:58", stars: 2 },
    { time: "8:10 AM", dur: "2:05", stars: 3 },
  ];
  return (
    <svg width="220" height="190" viewBox="0 0 220 190" style={{ filter: "drop-shadow(0 12px 28px rgba(52,211,153,0.35))" }}>
      {/* Card bg */}
      <rect x="20" y="10" width="180" height="168" rx="22" fill="rgba(16,185,129,0.1)" stroke="rgba(52,211,153,0.25)" strokeWidth="1.5" />
      {/* Streak banner */}
      <rect x="30" y="20" width="160" height="40" rx="12" fill="rgba(245,158,11,0.25)" stroke="rgba(251,191,36,0.4)" strokeWidth="1" />
      <text x="55" y="46" fontSize="20">🔥</text>
      <text x="82" y="38" fill="white" fontSize="13" fontFamily="'Fredoka One', cursive">5-Day Streak!</text>
      <text x="82" y="53" fill="rgba(255,255,255,0.55)" fontSize="10" fontFamily="Nunito, sans-serif" fontWeight="700">Keep it going!</text>
      {/* Rows */}
      {rows.map((r, i) => (
        <g key={i}>
          <rect x="30" y={72 + i * 34} width="160" height="28" rx="9"
            fill={i % 2 === 0 ? "rgba(255,255,255,0.06)" : "rgba(255,255,255,0.03)"}
            stroke="rgba(255,255,255,0.05)" strokeWidth="1" />
          <text x="44" y={90 + i * 34} fill="white" fontSize="11" fontFamily="Nunito" fontWeight="800">{r.time}</text>
          <text x="110" y={90 + i * 34} fill="#34d399" fontSize="12" fontFamily="'Fredoka One', cursive">{r.dur}</text>
          <text x="158" y={90 + i * 34} fontSize="11">{"⭐".repeat(r.stars)}</text>
        </g>
      ))}
    </svg>
  );
}

/* ── Welcome screen ── */
function WelcomeSlide({ onNext }) {
  const [visible, setVisible] = useState(false);
  useEffect(() => { setTimeout(() => setVisible(true), 100); }, []);

  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 28px", textAlign: "center" }}>
      {/* Big tooth character */}
      <div style={{ opacity: visible ? 1 : 0, transform: visible ? "scale(1) translateY(0)" : "scale(0.5) translateY(30px)", transition: "all 0.7s cubic-bezier(0.34,1.56,0.64,1)" }}>
        <svg width="160" height="170" viewBox="0 0 160 170" style={{ filter: "drop-shadow(0 16px 40px rgba(56,189,248,0.5))" }}>
          {/* Tooth glow ring */}
          <ellipse cx="80" cy="105" rx="62" ry="58" fill="rgba(56,189,248,0.12)" />
          {/* Tooth body */}
          <ellipse cx="80" cy="100" rx="52" ry="56" fill="white" />
          <ellipse cx="80" cy="100" rx="52" ry="56" fill="none" stroke="#bae6fd" strokeWidth="3" />
          {/* Sheen */}
          <ellipse cx="56" cy="72" rx="10" ry="16" fill="rgba(186,230,253,0.7)" transform="rotate(-20 56 72)" />
          {/* Eyes */}
          <circle cx="64" cy="90" r="9.5" fill="#1a1a2e" />
          <circle cx="96" cy="90" r="9.5" fill="#1a1a2e" />
          <circle cx="66.5" cy="87" r="3.5" fill="white" />
          <circle cx="98.5" cy="87" r="3.5" fill="white" />
          {/* Smile */}
          <path d="M61 110 Q80 128 99 110" stroke="#fda4af" strokeWidth="4.5" fill="none" strokeLinecap="round" />
          {/* Blush */}
          <ellipse cx="50" cy="106" rx="11" ry="7" fill="rgba(255,150,150,0.2)" />
          <ellipse cx="110" cy="106" rx="11" ry="7" fill="rgba(255,150,150,0.2)" />
          {/* Crown */}
          <text x="60" y="46" fontSize="32">👑</text>
          {/* Sparkles */}
          <text x="120" y="58" fontSize="18" style={{ animation: "sparkle 1.2s infinite alternate" }}>✨</text>
          <text x="14" y="64" fontSize="14" style={{ animation: "sparkle 1.6s infinite alternate" }}>💫</text>
        </svg>
      </div>

      <div style={{ opacity: visible ? 1 : 0, transform: visible ? "translateY(0)" : "translateY(20px)", transition: "all 0.6s ease 0.3s" }}>
        <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: 42, color: "white", lineHeight: 1.1, marginBottom: 10, textShadow: "0 4px 20px rgba(56,189,248,0.5)" }}>
          Meet<br />
          <span style={{ color: "#38bdf8" }}>ToothBuddy!</span>
        </div>
        <div style={{ color: "rgba(255,255,255,0.65)", fontSize: 15, lineHeight: 1.6, fontFamily: "Nunito, sans-serif", fontWeight: 700, maxWidth: 260, margin: "0 auto" }}>
          Your super fun brushing companion! 🦷<br />Let's build a habit together!
        </div>
      </div>

      <div style={{ opacity: visible ? 1 : 0, transition: "opacity 0.5s ease 0.8s", marginTop: 40, width: "100%" }}>
        <button onClick={onNext} style={{ width: "100%", padding: "20px 0", background: "linear-gradient(135deg, #38bdf8, #6366f1)", border: "none", borderRadius: 28, fontFamily: "'Fredoka One', cursive", fontSize: 22, color: "white", cursor: "pointer", boxShadow: "0 8px 32px rgba(56,189,248,0.45)", letterSpacing: 0.5, animation: "pulse-ring 2s infinite" }}>
          Let's Go! 🚀
        </button>
        <div style={{ color: "rgba(255,255,255,0.3)", fontSize: 12, marginTop: 14, fontFamily: "Nunito, sans-serif", fontWeight: 700 }}>
          Swipe through to learn how it works
        </div>
      </div>
    </div>
  );
}

/* ── Ready screen ── */
function ReadySlide({ onDone }) {
  const [pop, setPop] = useState(false);
  useEffect(() => { setTimeout(() => setPop(true), 200); }, []);
  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 28px", textAlign: "center" }}>
      <div style={{ fontSize: 80, marginBottom: 12, opacity: pop ? 1 : 0, transform: pop ? "scale(1)" : "scale(0)", transition: "all 0.5s cubic-bezier(0.34,1.56,0.64,1)" }}>🎉</div>
      <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: 38, color: "white", marginBottom: 12, opacity: pop ? 1 : 0, transition: "opacity 0.4s ease 0.2s", textShadow: "0 4px 20px rgba(167,139,250,0.5)" }}>
        You're all set!
      </div>
      <div style={{ color: "rgba(255,255,255,0.65)", fontSize: 15, lineHeight: 1.7, fontFamily: "Nunito, sans-serif", fontWeight: 700, maxWidth: 270, marginBottom: 36, opacity: pop ? 1 : 0, transition: "opacity 0.4s ease 0.35s" }}>
        Time to start your first brushing session. Your ToothBuddy is cheering for you! 🦷💪
      </div>

      {/* Checklist */}
      <div style={{ width: "100%", marginBottom: 36, opacity: pop ? 1 : 0, transition: "opacity 0.4s ease 0.5s" }}>
        {[
          { icon: "📷", text: "Camera permission ready" },
          { icon: "⏱️", text: "2-minute timer set" },
          { icon: "💎", text: "Rewards waiting for you" },
        ].map((item, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 12, background: "rgba(255,255,255,0.07)", borderRadius: 16, padding: "12px 16px", marginBottom: 8, border: "1px solid rgba(167,139,250,0.2)" }}>
            <span style={{ fontSize: 22 }}>{item.icon}</span>
            <span style={{ color: "white", fontFamily: "Nunito, sans-serif", fontWeight: 800, fontSize: 14 }}>{item.text}</span>
            <span style={{ marginLeft: "auto", color: "#34d399", fontSize: 18 }}>✓</span>
          </div>
        ))}
      </div>

      <button onClick={onDone} style={{ width: "100%", padding: "20px 0", background: "linear-gradient(135deg, #a855f7, #7c3aed)", border: "none", borderRadius: 28, fontFamily: "'Fredoka One', cursive", fontSize: 22, color: "white", cursor: "pointer", boxShadow: "0 8px 32px rgba(168,85,247,0.45)", opacity: pop ? 1 : 0, transition: "opacity 0.4s ease 0.7s", animation: pop ? "pulse-ring-purple 2s infinite 0.7s" : "none" }}>
        Start Brushing! 🪥
      </button>
    </div>
  );
}

/* ── Feature Slide ── */
function FeatureSlide({ slide, isActive }) {
  const [show, setShow] = useState(false);
  useEffect(() => {
    if (isActive) setTimeout(() => setShow(true), 80);
    else setShow(false);
  }, [isActive]);

  const IllustrationMap = { camera: CameraIllustration, timer: TimerIllustration, rewards: RewardsIllustration, history: HistoryIllustration };
  const Illustration = IllustrationMap[slide.illustration];

  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 28px", textAlign: "center" }}>
      <div style={{ opacity: show ? 1 : 0, transform: show ? "translateY(0) scale(1)" : "translateY(24px) scale(0.9)", transition: "all 0.55s cubic-bezier(0.34,1.2,0.64,1)", marginBottom: 28 }}>
        <Illustration active={isActive} />
      </div>

      <div style={{ opacity: show ? 1 : 0, transform: show ? "translateY(0)" : "translateY(18px)", transition: "all 0.5s ease 0.15s" }}>
        <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: 30, color: "white", marginBottom: 12, lineHeight: 1.2, textShadow: `0 4px 20px ${slide.accent}88` }}>
          {slide.title}
        </div>
        <div style={{ color: "rgba(255,255,255,0.65)", fontSize: 15, lineHeight: 1.7, fontFamily: "Nunito, sans-serif", fontWeight: 700, maxWidth: 280, margin: "0 auto" }}>
          {slide.subtitle}
        </div>
      </div>
    </div>
  );
}

/* ── Main ── */
export default function ToothBuddyOnboarding() {
  const [current, setCurrent] = useState(0);
  const [exiting, setExiting] = useState(false);
  const [done, setDone] = useState(false);

  const goNext = () => {
    if (current < slides.length - 1) {
      setExiting(true);
      setTimeout(() => { setCurrent((c) => c + 1); setExiting(false); }, 280);
    }
  };

  const goTo = (i) => {
    if (i !== current) {
      setExiting(true);
      setTimeout(() => { setCurrent(i); setExiting(false); }, 280);
    }
  };

  const slide = slides[current];

  if (done) {
    return (
      <div style={{ minHeight: "100vh", background: "linear-gradient(135deg, #0f172a, #1e3a5f, #0ea5e9)", display: "flex", alignItems: "center", justifyContent: "center", fontFamily: "Nunito, sans-serif" }}>
        <div style={{ color: "white", textAlign: "center" }}>
          <div style={{ fontSize: 64 }}>🦷</div>
          <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: 28, marginTop: 12 }}>Onboarding Complete!</div>
          <div style={{ color: "rgba(255,255,255,0.6)", marginTop: 8 }}>This is where the main app would load.</div>
          <button onClick={() => { setCurrent(0); setDone(false); }} style={{ marginTop: 24, padding: "12px 28px", background: "rgba(255,255,255,0.1)", border: "1px solid rgba(255,255,255,0.2)", borderRadius: 20, color: "white", cursor: "pointer", fontFamily: "Nunito", fontWeight: 800 }}>
            ↩ Replay Onboarding
          </button>
        </div>
      </div>
    );
  }

  return (
    <div style={{ minHeight: "100vh", background: "linear-gradient(135deg, #0f172a 0%, #1e3a5f 50%, #0ea5e9 100%)", display: "flex", alignItems: "center", justifyContent: "center", fontFamily: "'Nunito', sans-serif" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Nunito:wght@400;700;900&family=Fredoka+One&display=swap');
        @keyframes sparkle { from { opacity:0.5; transform:scale(0.85); } to { opacity:1; transform:scale(1.15); } }
        @keyframes float1 { 0%,100%{transform:translateY(0);} 50%{transform:translateY(-8px);} }
        @keyframes float2 { 0%,100%{transform:translateY(0);} 50%{transform:translateY(-12px);} }
        @keyframes pulse-ring { 0%{box-shadow:0 0 0 0 rgba(56,189,248,0.5);} 70%{box-shadow:0 0 0 20px rgba(56,189,248,0);} 100%{box-shadow:0 0 0 0 rgba(56,189,248,0);} }
        @keyframes pulse-ring-purple { 0%{box-shadow:0 0 0 0 rgba(168,85,247,0.5);} 70%{box-shadow:0 0 0 20px rgba(168,85,247,0);} 100%{box-shadow:0 0 0 0 rgba(168,85,247,0);} }
        @keyframes slideIn { from{opacity:0;transform:translateX(40px)} to{opacity:1;transform:translateX(0)} }
        @keyframes slideOut { from{opacity:1;transform:translateX(0)} to{opacity:0;transform:translateX(-40px)} }
      `}</style>

      {/* Phone frame */}
      <div style={{ width: 390, height: 844, borderRadius: 50, background: slide.bg, boxShadow: "0 32px 80px rgba(0,0,0,0.7), inset 0 1px 0 rgba(255,255,255,0.1)", overflow: "hidden", display: "flex", flexDirection: "column", border: "2px solid rgba(255,255,255,0.08)", transition: "background 0.6s ease", position: "relative" }}>

        {/* Ambient particle dots */}
        {[...Array(12)].map((_, i) => (
          <div key={i} style={{ position: "absolute", width: Math.random() * 4 + 2, height: Math.random() * 4 + 2, borderRadius: "50%", background: "rgba(255,255,255,0.15)", top: `${Math.random() * 100}%`, left: `${Math.random() * 100}%`, pointerEvents: "none" }} />
        ))}

        {/* Status bar */}
        <div style={{ display: "flex", justifyContent: "space-between", padding: "16px 28px 6px", color: "rgba(255,255,255,0.6)", fontSize: 12, fontWeight: 700 }}>
          <span>9:41</span>
          <span style={{ fontFamily: "'Fredoka One', cursive", fontSize: 14, color: "rgba(255,255,255,0.4)" }}>🦷 ToothBuddy</span>
          <span>●●●</span>
        </div>

        {/* Skip button (not on last slide) */}
        {!slide.isWelcome && !slide.isReady && (
          <div style={{ display: "flex", justifyContent: "flex-end", padding: "0 24px" }}>
            <button onClick={() => goTo(slides.length - 1)} style={{ background: "rgba(255,255,255,0.1)", border: "1px solid rgba(255,255,255,0.15)", borderRadius: 20, padding: "6px 16px", color: "rgba(255,255,255,0.6)", fontFamily: "Nunito, sans-serif", fontWeight: 800, fontSize: 12, cursor: "pointer", letterSpacing: 0.5 }}>
              Skip →
            </button>
          </div>
        )}

        {/* Slide content */}
        <div style={{ flex: 1, display: "flex", flexDirection: "column", animation: exiting ? "slideOut 0.28s ease forwards" : "slideIn 0.4s ease" }}>
          {slide.isWelcome && <WelcomeSlide onNext={goNext} />}
          {slide.isReady && <ReadySlide onDone={() => setDone(true)} />}
          {!slide.isWelcome && !slide.isReady && <FeatureSlide slide={slide} isActive={!exiting} />}
        </div>

        {/* Bottom nav (not on welcome/ready) */}
        {!slide.isWelcome && !slide.isReady && (
          <div style={{ padding: "16px 28px 36px" }}>
            {/* Dot indicators */}
            <div style={{ display: "flex", justifyContent: "center", gap: 8, marginBottom: 20 }}>
              {slides.filter(s => !s.isWelcome && !s.isReady).map((_, i) => {
                const dotIndex = i + 1;
                const isActive = current === dotIndex;
                return (
                  <div key={i} onClick={() => goTo(dotIndex)} style={{ width: isActive ? 24 : 8, height: 8, borderRadius: 4, background: isActive ? slide.accent : "rgba(255,255,255,0.25)", cursor: "pointer", transition: "all 0.3s ease" }} />
                );
              })}
            </div>

            {/* Next button */}
            <button onClick={goNext} style={{ width: "100%", padding: "18px 0", background: `linear-gradient(135deg, ${slide.accent}, ${current === 4 ? "#10b981" : "#6366f1"})`, border: "none", borderRadius: 26, fontFamily: "'Fredoka One', cursive", fontSize: 21, color: "white", cursor: "pointer", boxShadow: `0 8px 28px ${slide.accent}55`, letterSpacing: 0.5, transition: "all 0.3s" }}>
              {current === slides.length - 2 ? "Almost Ready! 🎉" : "Next →"}
            </button>
          </div>
        )}

        {/* Home bar */}
        <div style={{ height: 6, display: "flex", justifyContent: "center", paddingBottom: 8 }}>
          <div style={{ width: 120, height: 4, borderRadius: 2, background: "rgba(255,255,255,0.2)" }} />
        </div>
      </div>
    </div>
  );
}
