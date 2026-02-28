import { useState, useEffect, useRef } from "react";

const BUBBLE_COUNT = 18;

function Bubble({ style }) {
  return (
    <div
      style={{
        position: "absolute",
        borderRadius: "50%",
        background: "rgba(255,255,255,0.18)",
        backdropFilter: "blur(2px)",
        animation: `floatUp ${style.duration}s ease-in infinite`,
        animationDelay: `${style.delay}s`,
        width: style.size,
        height: style.size,
        left: style.left,
        bottom: "-60px",
        pointerEvents: "none",
      }}
    />
  );
}

const bubbles = Array.from({ length: BUBBLE_COUNT }, (_, i) => ({
  size: `${Math.random() * 28 + 10}px`,
  left: `${Math.random() * 100}%`,
  delay: Math.random() * 6,
  duration: Math.random() * 5 + 5,
}));

const STARS = Array.from({ length: 5 }, (_, i) => i);

const records = [
  { id: 1, date: "Today", time: "8:02 AM", duration: 142, stars: 3 },
  { id: 2, date: "Today", time: "9:45 PM", duration: 118, stars: 2 },
  { id: 3, date: "Yesterday", time: "7:58 AM", duration: 180, stars: 3 },
  { id: 4, date: "Yesterday", time: "10:12 PM", duration: 89, stars: 1 },
  { id: 5, date: "Mon, Feb 26", time: "8:20 AM", duration: 161, stars: 3 },
  { id: 6, date: "Mon, Feb 26", time: "9:30 PM", duration: 177, stars: 3 },
];

function fmtTime(s) {
  const m = Math.floor(s / 60);
  const sec = s % 60;
  return `${String(m).padStart(2, "0")}:${String(sec).padStart(2, "0")}`;
}

function getStars(sec) {
  if (sec >= 120) return 3;
  if (sec >= 60) return 2;
  if (sec > 0) return 1;
  return 0;
}

function StarRow({ count, max = 3, size = 22 }) {
  return (
    <div style={{ display: "flex", gap: 3 }}>
      {Array.from({ length: max }).map((_, i) => (
        <span key={i} style={{ fontSize: size, filter: i < count ? "none" : "grayscale(1) opacity(0.3)" }}>
          ⭐
        </span>
      ))}
    </div>
  );
}

function ToothCharacter({ brushing }) {
  return (
    <div
      style={{
        position: "relative",
        width: 110,
        height: 110,
        margin: "0 auto",
        animation: brushing ? "wiggle 0.4s infinite" : "none",
      }}
    >
      {/* Face */}
      <svg width="110" height="110" viewBox="0 0 110 110">
        {/* Tooth body */}
        <ellipse cx="55" cy="62" rx="40" ry="42" fill="white" />
        <ellipse cx="55" cy="62" rx="40" ry="42" fill="none" stroke="#d0eaff" strokeWidth="3" />
        {/* Shiny glint */}
        <ellipse cx="37" cy="38" rx="7" ry="11" fill="rgba(200,240,255,0.7)" transform="rotate(-20 37 38)" />
        {/* Eyes */}
        <circle cx="42" cy="54" r="7" fill="#1a1a2e" />
        <circle cx="68" cy="54" r="7" fill="#1a1a2e" />
        <circle cx="44" cy="51" r="2.5" fill="white" />
        <circle cx="70" cy="51" r="2.5" fill="white" />
        {/* Mouth */}
        {brushing ? (
          <path d="M42 72 Q55 82 68 72" stroke="#f9a8d4" strokeWidth="3" fill="none" strokeLinecap="round" />
        ) : (
          <path d="M41 70 Q55 84 69 70" stroke="#f9a8d4" strokeWidth="3.5" fill="none" strokeLinecap="round" />
        )}
        {/* Cheek blush */}
        <ellipse cx="30" cy="68" rx="9" ry="6" fill="rgba(255,150,150,0.22)" />
        <ellipse cx="80" cy="68" rx="9" ry="6" fill="rgba(255,150,150,0.22)" />
        {/* Sparkles when not brushing */}
        {!brushing && (
          <>
            <text x="88" y="30" fontSize="16">✨</text>
            <text x="5" y="28" fontSize="13">💫</text>
          </>
        )}
        {brushing && (
          <>
            <text x="85" y="25" fontSize="13" style={{ animation: "sparkle 0.5s infinite alternate" }}>💧</text>
            <text x="2" y="30" fontSize="13">💧</text>
          </>
        )}
      </svg>
    </div>
  );
}

export default function ToothBuddy() {
  const [tab, setTab] = useState("brush");
  const [brushing, setBrushing] = useState(false);
  const [elapsed, setElapsed] = useState(0);
  const [done, setDone] = useState(null); // {duration, stars}
  const intervalRef = useRef(null);

  const handleStart = () => {
    setBrushing(true);
    setElapsed(0);
    setDone(null);
    intervalRef.current = setInterval(() => setElapsed((e) => e + 1), 1000);
  };

  const handleStop = () => {
    clearInterval(intervalRef.current);
    setBrushing(false);
    const stars = getStars(elapsed);
    setDone({ duration: elapsed, stars });
  };

  useEffect(() => () => clearInterval(intervalRef.current), []);

  const camBg = brushing
    ? "linear-gradient(160deg, #0ea5e9 0%, #38bdf8 40%, #7dd3fc 100%)"
    : "linear-gradient(160deg, #1e3a5f 0%, #0369a1 60%, #0ea5e9 100%)";

  return (
    <div
      style={{
        minHeight: "100vh",
        background: "linear-gradient(135deg, #0f172a 0%, #1e3a5f 50%, #0ea5e9 100%)",
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        fontFamily: "'Nunito', 'Fredoka One', sans-serif",
        padding: "0",
      }}
    >
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Nunito:wght@400;700;900&family=Fredoka+One&display=swap');
        @keyframes floatUp {
          0% { transform: translateY(0) scale(1); opacity: 0.7; }
          80% { opacity: 0.4; }
          100% { transform: translateY(-100vh) scale(0.5); opacity: 0; }
        }
        @keyframes wiggle {
          0%,100% { transform: rotate(-4deg); }
          50% { transform: rotate(4deg); }
        }
        @keyframes pop {
          0% { transform: scale(0.8); opacity: 0; }
          70% { transform: scale(1.08); }
          100% { transform: scale(1); opacity: 1; }
        }
        @keyframes pulse-ring {
          0% { box-shadow: 0 0 0 0 rgba(56,189,248,0.5); }
          70% { box-shadow: 0 0 0 22px rgba(56,189,248,0); }
          100% { box-shadow: 0 0 0 0 rgba(56,189,248,0); }
        }
        @keyframes sparkle {
          from { opacity: 0.4; transform: scale(0.8); }
          to { opacity: 1; transform: scale(1.2); }
        }
        @keyframes bounce {
          0%,100% { transform: translateY(0); }
          50% { transform: translateY(-6px); }
        }
        @keyframes fadeSlideUp {
          from { opacity: 0; transform: translateY(24px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .tab-btn:hover { transform: scale(1.08); }
        .start-btn:active { transform: scale(0.95); }
      `}</style>

      {/* Phone frame */}
      <div
        style={{
          width: 390,
          minHeight: 780,
          maxHeight: 860,
          borderRadius: 48,
          background: "linear-gradient(170deg, #0b1a2e 0%, #0f2645 100%)",
          boxShadow: "0 30px 80px rgba(0,0,0,0.7), inset 0 1px 0 rgba(255,255,255,0.08)",
          overflow: "hidden",
          position: "relative",
          display: "flex",
          flexDirection: "column",
          border: "2px solid rgba(255,255,255,0.07)",
        }}
      >
        {/* Status bar */}
        <div style={{ display: "flex", justifyContent: "space-between", padding: "16px 28px 8px", color: "rgba(255,255,255,0.7)", fontSize: 13, fontWeight: 700, letterSpacing: 0.5 }}>
          <span>9:41</span>
          <span>●●●</span>
        </div>

        {/* App header */}
        <div style={{ textAlign: "center", padding: "4px 0 12px" }}>
          <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: 30, color: "white", letterSpacing: 1, textShadow: "0 2px 16px rgba(56,189,248,0.6)" }}>
            🦷 ToothBuddy
          </div>
        </div>

        {/* Main content */}
        <div style={{ flex: 1, overflowY: "auto", padding: "0 18px 12px" }}>
          {tab === "brush" && (
            <div style={{ animation: "fadeSlideUp 0.4s ease" }}>
              {/* Camera area */}
              <div
                style={{
                  borderRadius: 32,
                  background: camBg,
                  height: 310,
                  position: "relative",
                  overflow: "hidden",
                  boxShadow: brushing ? "0 0 0 4px #38bdf8, 0 12px 40px rgba(14,165,233,0.5)" : "0 8px 32px rgba(0,0,0,0.4)",
                  transition: "box-shadow 0.4s, background 0.6s",
                  marginBottom: 20,
                }}
              >
                {/* Bubbles */}
                {bubbles.map((b, i) => <Bubble key={i} style={b} />)}

                {/* Camera placeholder text */}
                {!brushing && (
                  <div style={{ position: "absolute", top: 16, left: 0, right: 0, textAlign: "center", color: "rgba(255,255,255,0.45)", fontSize: 12, fontWeight: 700, letterSpacing: 2, textTransform: "uppercase" }}>
                    📷 Camera Preview
                  </div>
                )}

                {/* Brushing indicator */}
                {brushing && (
                  <div style={{ position: "absolute", top: 14, left: 16, background: "rgba(255,255,255,0.18)", borderRadius: 20, padding: "5px 14px", display: "flex", alignItems: "center", gap: 6 }}>
                    <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#f87171", animation: "sparkle 0.7s infinite alternate" }} />
                    <span style={{ color: "white", fontSize: 12, fontWeight: 800 }}>LIVE</span>
                  </div>
                )}

                {/* Character */}
                <div style={{ position: "absolute", bottom: 28, left: 0, right: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
                  <ToothCharacter brushing={brushing} />
                  {brushing && (
                    <div style={{ marginTop: 6, background: "rgba(255,255,255,0.15)", borderRadius: 16, padding: "4px 18px", backdropFilter: "blur(8px)" }}>
                      <span style={{ fontFamily: "'Fredoka One'", fontSize: 28, color: "white", letterSpacing: 2 }}>
                        {fmtTime(elapsed)}
                      </span>
                    </div>
                  )}
                  {!brushing && !done && (
                    <div style={{ marginTop: 8, color: "rgba(255,255,255,0.75)", fontSize: 14, fontWeight: 700 }}>
                      Ready to brush? 🪥
                    </div>
                  )}
                </div>
              </div>

              {/* Done card */}
              {done && (
                <div style={{ background: "linear-gradient(135deg, #1d4ed8, #0ea5e9)", borderRadius: 24, padding: "18px 20px", marginBottom: 16, animation: "pop 0.4s ease", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <div>
                    <div style={{ color: "rgba(255,255,255,0.8)", fontSize: 12, fontWeight: 700, marginBottom: 4 }}>GREAT JOB! 🎉</div>
                    <div style={{ fontFamily: "'Fredoka One'", color: "white", fontSize: 26 }}>{fmtTime(done.duration)}</div>
                    <div style={{ color: "rgba(255,255,255,0.75)", fontSize: 12, marginTop: 2 }}>
                      {done.duration >= 120 ? "Perfect brushing time! 🏆" : done.duration >= 60 ? "Good job! Keep going! 💪" : "Try for 2 minutes! ⏱️"}
                    </div>
                  </div>
                  <StarRow count={done.stars} size={24} />
                </div>
              )}

              {/* Goal bar */}
              {!brushing && (
                <div style={{ background: "rgba(255,255,255,0.06)", borderRadius: 18, padding: "12px 16px", marginBottom: 18, border: "1px solid rgba(255,255,255,0.1)" }}>
                  <div style={{ display: "flex", justifyContent: "space-between", color: "rgba(255,255,255,0.6)", fontSize: 12, fontWeight: 700, marginBottom: 8 }}>
                    <span>TODAY'S GOAL</span>
                    <span>1/2 sessions</span>
                  </div>
                  <div style={{ background: "rgba(255,255,255,0.1)", borderRadius: 8, height: 10, overflow: "hidden" }}>
                    <div style={{ width: "50%", height: "100%", background: "linear-gradient(90deg, #38bdf8, #818cf8)", borderRadius: 8, boxShadow: "0 0 10px rgba(56,189,248,0.5)" }} />
                  </div>
                </div>
              )}

              {/* Start / Stop button */}
              {!brushing ? (
                <button
                  onClick={handleStart}
                  className="start-btn"
                  style={{
                    width: "100%",
                    padding: "20px 0",
                    background: "linear-gradient(135deg, #0ea5e9 0%, #6366f1 100%)",
                    border: "none",
                    borderRadius: 28,
                    fontFamily: "'Fredoka One', cursive",
                    fontSize: 24,
                    color: "white",
                    cursor: "pointer",
                    letterSpacing: 1,
                    boxShadow: "0 6px 30px rgba(99,102,241,0.5)",
                    animation: "pulse-ring 2s infinite, bounce 2s infinite",
                    transition: "transform 0.15s",
                  }}
                >
                  🪥 Start Brushing!
                </button>
              ) : (
                <button
                  onClick={handleStop}
                  className="start-btn"
                  style={{
                    width: "100%",
                    padding: "20px 0",
                    background: "linear-gradient(135deg, #f43f5e 0%, #fb923c 100%)",
                    border: "none",
                    borderRadius: 28,
                    fontFamily: "'Fredoka One', cursive",
                    fontSize: 24,
                    color: "white",
                    cursor: "pointer",
                    letterSpacing: 1,
                    boxShadow: "0 6px 30px rgba(244,63,94,0.4)",
                    transition: "transform 0.15s",
                  }}
                >
                  ✅ Done Brushing!
                </button>
              )}
            </div>
          )}

          {tab === "history" && (
            <div style={{ animation: "fadeSlideUp 0.4s ease" }}>
              {/* Streak card */}
              <div style={{ background: "linear-gradient(135deg, #f59e0b, #f97316)", borderRadius: 24, padding: "16px 20px", marginBottom: 18, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div>
                  <div style={{ color: "rgba(255,255,255,0.85)", fontSize: 12, fontWeight: 800, letterSpacing: 1 }}>CURRENT STREAK 🔥</div>
                  <div style={{ fontFamily: "'Fredoka One'", color: "white", fontSize: 36, lineHeight: 1.1 }}>5 Days</div>
                </div>
                <div style={{ textAlign: "center" }}>
                  <div style={{ fontSize: 42 }}>🏆</div>
                  <div style={{ color: "rgba(255,255,255,0.8)", fontSize: 11, fontWeight: 700 }}>Keep it up!</div>
                </div>
              </div>

              {/* Stats row */}
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginBottom: 18 }}>
                {[
                  { label: "Avg Duration", val: "2:30 min", icon: "⏱️" },
                  { label: "Total Sessions", val: "24", icon: "🦷" },
                ].map((s, i) => (
                  <div key={i} style={{ background: "rgba(255,255,255,0.07)", borderRadius: 18, padding: "14px 14px", border: "1px solid rgba(255,255,255,0.1)" }}>
                    <div style={{ fontSize: 22, marginBottom: 4 }}>{s.icon}</div>
                    <div style={{ fontFamily: "'Fredoka One'", color: "white", fontSize: 20 }}>{s.val}</div>
                    <div style={{ color: "rgba(255,255,255,0.5)", fontSize: 11, fontWeight: 700 }}>{s.label}</div>
                  </div>
                ))}
              </div>

              {/* Records */}
              <div style={{ color: "rgba(255,255,255,0.5)", fontSize: 12, fontWeight: 800, letterSpacing: 1.5, marginBottom: 10 }}>RECENT SESSIONS</div>
              {records.map((r) => (
                <div
                  key={r.id}
                  style={{ background: "rgba(255,255,255,0.07)", borderRadius: 20, padding: "14px 16px", marginBottom: 10, display: "flex", justifyContent: "space-between", alignItems: "center", border: "1px solid rgba(255,255,255,0.07)", animation: "fadeSlideUp 0.3s ease" }}
                >
                  <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <div style={{ width: 44, height: 44, borderRadius: 14, background: "linear-gradient(135deg, #0ea5e9, #6366f1)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20 }}>
                      🦷
                    </div>
                    <div>
                      <div style={{ color: "white", fontWeight: 800, fontSize: 15 }}>{r.time}</div>
                      <div style={{ color: "rgba(255,255,255,0.45)", fontSize: 12 }}>{r.date}</div>
                    </div>
                  </div>
                  <div style={{ textAlign: "right" }}>
                    <div style={{ fontFamily: "'Fredoka One'", color: "#38bdf8", fontSize: 18 }}>{fmtTime(r.duration)}</div>
                    <StarRow count={r.stars} size={14} />
                  </div>
                </div>
              ))}
            </div>
          )}

          {tab === "rewards" && (
            <div style={{ animation: "fadeSlideUp 0.4s ease" }}>
              <div style={{ background: "linear-gradient(135deg, #7c3aed, #a855f7)", borderRadius: 24, padding: "18px 20px", marginBottom: 18, textAlign: "center" }}>
                <div style={{ fontSize: 48, marginBottom: 8 }}>💎</div>
                <div style={{ fontFamily: "'Fredoka One'", color: "white", fontSize: 28 }}>120 Gems</div>
                <div style={{ color: "rgba(255,255,255,0.7)", fontSize: 13 }}>Keep brushing to earn more!</div>
              </div>

              <div style={{ color: "rgba(255,255,255,0.5)", fontSize: 12, fontWeight: 800, letterSpacing: 1.5, marginBottom: 12 }}>ACHIEVEMENTS</div>
              {[
                { icon: "🌟", name: "First Brush!", desc: "Complete your 1st session", done: true, gems: 10 },
                { icon: "🔥", name: "3-Day Streak", desc: "Brush 3 days in a row", done: true, gems: 30 },
                { icon: "👑", name: "Perfect Week", desc: "7-day brushing streak", done: false, gems: 100 },
                { icon: "⏱️", name: "Time Master", desc: "Brush 2+ min, 10 times", done: false, gems: 50 },
              ].map((a, i) => (
                <div
                  key={i}
                  style={{ background: a.done ? "rgba(99,102,241,0.15)" : "rgba(255,255,255,0.05)", borderRadius: 20, padding: "14px 16px", marginBottom: 10, display: "flex", alignItems: "center", gap: 14, border: a.done ? "1px solid rgba(99,102,241,0.4)" : "1px solid rgba(255,255,255,0.07)", opacity: a.done ? 1 : 0.6 }}
                >
                  <div style={{ width: 48, height: 48, borderRadius: 16, background: a.done ? "linear-gradient(135deg, #6366f1, #a855f7)" : "rgba(255,255,255,0.08)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 24 }}>
                    {a.done ? a.icon : "🔒"}
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ color: "white", fontWeight: 800, fontSize: 15 }}>{a.name}</div>
                    <div style={{ color: "rgba(255,255,255,0.45)", fontSize: 12 }}>{a.desc}</div>
                  </div>
                  <div style={{ background: "rgba(253,224,71,0.15)", borderRadius: 12, padding: "4px 10px", color: "#fde047", fontWeight: 800, fontSize: 13 }}>
                    +{a.gems} 💎
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Bottom Tab Bar */}
        <div
          style={{
            background: "rgba(255,255,255,0.05)",
            backdropFilter: "blur(16px)",
            borderTop: "1px solid rgba(255,255,255,0.08)",
            padding: "12px 8px 24px",
            display: "flex",
            justifyContent: "space-around",
          }}
        >
          {[
            { id: "brush", icon: "🪥", label: "Brush" },
            { id: "history", icon: "📋", label: "History" },
            { id: "rewards", icon: "🏆", label: "Rewards" },
          ].map((t) => (
            <button
              key={t.id}
              className="tab-btn"
              onClick={() => setTab(t.id)}
              style={{
                background: tab === t.id ? "rgba(56,189,248,0.2)" : "transparent",
                border: tab === t.id ? "1px solid rgba(56,189,248,0.3)" : "1px solid transparent",
                borderRadius: 18,
                padding: "8px 20px",
                cursor: "pointer",
                transition: "all 0.2s",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                gap: 3,
              }}
            >
              <span style={{ fontSize: 22 }}>{t.icon}</span>
              <span style={{ color: tab === t.id ? "#38bdf8" : "rgba(255,255,255,0.4)", fontSize: 11, fontWeight: 800, letterSpacing: 0.5 }}>
                {t.label}
              </span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
