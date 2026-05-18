import SwiftUI
import ToothBuddyCore

// MARK: - Visual entities (value types; one array each, culled when done)

fileprivate struct GameBug: Identifiable {
    let id: Int
    let zone: CoarseZone
    let colorIndex: Int
    let phase: Double          // desync idle wobble/blink
    let offset: CGSize         // scatter within the zone cluster
    var clearingSince: Double? // nil = idle; else sim-time the pop began
    var fadingOut = false      // zone changed away while bugs remained
    var fadeSince: Double?
}

fileprivate struct Bubble: Identifiable { let id = UUID(); var pos: CGPoint; var vel: CGVector; var born: Double }
fileprivate struct Floater: Identifiable { let id = UUID(); var pos: CGPoint; var born: Double; let text: String }
fileprivate struct Confetto: Identifiable { let id = UUID(); var pos: CGPoint; var vel: CGVector; var born: Double; let colorIndex: Int }

// MARK: - View model (pure-ish sim; draw is a pure render of current state)

@MainActor
fileprivate final class BrushGameViewModel: ObservableObject {
    private var game = BrushGame()
    private let monitor = BrushingZoneMonitor.shared

    private(set) var bugs: [GameBug] = []
    private(set) var bubbles: [Bubble] = []
    private(set) var floaters: [Floater] = []
    private(set) var confetti: [Confetto] = []
    private(set) var won = false

    private var elapsed: Double = 0           // sim clock (sum of clamped dt)
    private var lastDate: Date?
    private var lastZone: CoarseZone?
    private var nextBugID = 0
    private var lastSoundAt: Double = -1

    // Tunables (Spec 04.3 §3/§4)
    private let juiceDuration = 0.45
    private let fadeDuration = 0.30
    private let bubbleLife = 0.34
    private let floaterLife = 0.40
    private let confettiLife = 1.4
    private let maxConfetti = 60

    func start() {
        game = BrushGame()
        bugs = []; bubbles = []; floaters = []; confetti = []
        won = false; elapsed = 0; lastDate = nil; lastZone = nil
        nextBugID = 0; lastSoundAt = -1
    }

    func stop() {
        bugs = []; bubbles = []; floaters = []; confetti = []
    }

    /// Fixed normalized anchor per zone (engagement layout — NOT real mouth pixels).
    private func anchor(_ z: CoarseZone) -> CGPoint {
        switch z {
        case .upperLeft:   return CGPoint(x: 0.30, y: 0.34)
        case .upperRight:  return CGPoint(x: 0.70, y: 0.34)
        case .lowerLeft:   return CGPoint(x: 0.30, y: 0.66)
        case .lowerRight:  return CGPoint(x: 0.70, y: 0.66)
        case .frontTop:    return CGPoint(x: 0.50, y: 0.30)
        case .frontBottom: return CGPoint(x: 0.50, y: 0.72)
        }
    }

    private func coarse(_ z: BrushingZone?) -> CoarseZone? {
        switch z {
        case .upperLeft:   return .upperLeft
        case .upperRight:  return .upperRight
        case .lowerLeft:   return .lowerLeft
        case .lowerRight:  return .lowerRight
        case .frontTop:    return .frontTop
        case .frontBottom: return .frontBottom
        case nil:          return nil
        }
    }

    private func spawnCluster(for zone: CoarseZone) {
        let count = max(0, game.remaining[zone] ?? 0)
        var made: [GameBug] = []
        for i in 0..<count {
            let ang = Double(i) * 2.399963             // golden-angle scatter
            let rad = 26.0 + Double(i) * 7.0
            made.append(GameBug(
                id: nextBugID, zone: zone, colorIndex: nextBugID % 4,
                phase: Double(nextBugID) * 0.7,
                offset: CGSize(width: cos(ang) * rad, height: sin(ang) * rad),
                clearingSince: nil))
            nextBugID += 1
        }
        bugs = made
    }

    /// One simulation step. Driven by the TimelineView date.
    func step(date: Date, reduceMotion: Bool) {
        let dt: Double = {
            guard let l = lastDate else { return 0 }
            return min(max(0, date.timeIntervalSince(l)), 1.0 / 20.0)
        }()
        lastDate = date
        elapsed += dt

        let zone = coarse(monitor.currentZone)
        let active = monitor.isBrushingActive

        if zone != lastZone {
            // Fade any leftover bugs from the previous zone, spawn the new cluster.
            for idx in bugs.indices where bugs[idx].clearingSince == nil && !bugs[idx].fadingOut {
                bugs[idx].fadingOut = true
                bugs[idx].fadeSince = elapsed
            }
            lastZone = zone
            if let z = zone { spawnCluster(for: z) }
        }

        // Advance pure rules; detect how many bugs cleared in the active zone.
        if let z = zone {
            let before = game.remaining[z] ?? 0
            game.advance(currentZone: z, isActive: active, dt: dt)
            let cleared = before - (game.remaining[z] ?? 0)
            if cleared > 0 { popBugs(count: cleared, in: z, reduceMotion: reduceMotion) }
        } else {
            game.advance(currentZone: nil, isActive: active, dt: dt)
        }

        cull(reduceMotion: reduceMotion)

        if !won, game.totalRemaining == 0 {
            won = true
            if !reduceMotion { burstConfetti() }
        }
    }

    private func popBugs(count: Int, in zone: CoarseZone, reduceMotion: Bool) {
        var done = 0
        for idx in bugs.indices where done < count
            && bugs[idx].zone == zone && bugs[idx].clearingSince == nil
            && !bugs[idx].fadingOut {
            bugs[idx].clearingSince = elapsed
            done += 1
            let center = screenless(bugs[idx])     // logical center (0..1 space)
            floaters.append(Floater(pos: center, born: elapsed, text: "+10"))
            if !reduceMotion {
                for _ in 0..<6 {
                    let a = Double.random(in: 0..<(2 * .pi))
                    bubbles.append(Bubble(
                        pos: center,
                        vel: CGVector(dx: cos(a) * 0.10, dy: sin(a) * 0.10 - 0.06),
                        born: elapsed))
                }
            }
            if elapsed - lastSoundAt > 0.18 {      // throttle so bursts aren't noisy
                SoundManager.tabTapped()
                lastSoundAt = elapsed
            }
        }
    }

    /// Logical (normalized 0..1) center of a bug — screen mapping happens in draw.
    private func screenless(_ b: GameBug) -> CGPoint {
        let a = anchor(b.zone)
        return CGPoint(x: a.x + b.offset.width / 1000.0,
                       y: a.y + b.offset.height / 1000.0)
    }

    private func burstConfetti() {
        for i in 0..<maxConfetti {
            let a = Double.random(in: 0..<(2 * .pi))
            confetti.append(Confetto(
                pos: CGPoint(x: 0.5, y: 0.42),
                vel: CGVector(dx: cos(a) * Double.random(in: 0.05...0.22),
                              dy: sin(a) * Double.random(in: 0.05...0.22) - 0.10),
                born: elapsed, colorIndex: i % 4))
        }
    }

    private func cull(reduceMotion: Bool) {
        let jd = reduceMotion ? 0.18 : juiceDuration
        bugs.removeAll {
            if let c = $0.clearingSince { return elapsed - c > jd }
            if let f = $0.fadeSince { return elapsed - f > fadeDuration }
            return false
        }
        bubbles.removeAll { elapsed - $0.born > bubbleLife }
        floaters.removeAll { elapsed - $0.born > floaterLife }
        confetti.removeAll { elapsed - $0.born > confettiLife }
        // integrate simple physics
        for i in bubbles.indices {
            bubbles[i].pos.x += bubbles[i].vel.dx * 0.016
            bubbles[i].pos.y += bubbles[i].vel.dy * 0.016
        }
        for i in confetti.indices {
            confetti[i].pos.x += confetti[i].vel.dx * 0.016
            confetti[i].pos.y += confetti[i].vel.dy * 0.016
            confetti[i].vel.dy += 0.012                 // gravity
        }
    }

    // MARK: Render (pure: only reads current state)

    private static let candy: [Color] = [
        Color(red: 1.00, green: 0.45, blue: 0.42),   // coral
        Color(red: 0.62, green: 0.45, blue: 0.90),   // grape
        Color(red: 0.30, green: 0.80, blue: 0.65),   // mint
        Color(red: 1.00, green: 0.60, blue: 0.25)    // tangerine
    ]

    func draw(in ctx: inout GraphicsContext, size: CGSize, reduceMotion: Bool) {
        func P(_ n: CGPoint) -> CGPoint {
            CGPoint(x: n.x * size.width, y: n.y * size.height)
        }

        // Target zone spotlight ring.
        if let z = lastZone {
            let c = P(anchor(z))
            let pulse = reduceMotion ? 0.0 : 0.5 + 0.5 * sin(elapsed * 3.0)
            let r: CGFloat = 78 + CGFloat(pulse) * 6
            let ring = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r,
                                              width: r * 2, height: r * 2))
            ctx.stroke(ring,
                       with: .color(Theme.accentBlue.opacity(0.35 + pulse * 0.25)),
                       lineWidth: 4)
        }

        // Sugar Bugs.
        for b in bugs {
            let center = P(screenless(b))
            var alpha = 1.0
            var sx = 1.0, sy = 1.0
            if let c = b.clearingSince {
                let p = min(1.0, (elapsed - c) / (reduceMotion ? 0.18 : juiceDuration))
                if reduceMotion {
                    alpha = 1.0 - p
                    sx = 1.0 - 0.15 * p; sy = sx
                } else if p < 0.25 {
                    let q = p / 0.25                // squash
                    sy = 1.0 - 0.45 * q; sx = 1.0 + 0.35 * q
                } else {
                    let q = (p - 0.25) / 0.75       // fade
                    alpha = 1.0 - q
                    sx = 1.35; sy = 0.55
                }
            } else if let f = b.fadeSince {
                alpha = max(0, 1.0 - (elapsed - f) / fadeDuration)
            } else if !reduceMotion {
                let breathe = 1.0 + 0.05 * sin(elapsed * 3.6 + b.phase)
                sx = breathe; sy = breathe
            }
            guard alpha > 0.01 else { continue }
            drawBug(&ctx, at: center, scaleX: sx, scaleY: sy,
                    rot: (b.clearingSince == nil && !reduceMotion)
                        ? sin(elapsed * 2.2 + b.phase) * 0.10 : 0,
                    color: Self.candy[b.colorIndex].opacity(0.85 * alpha),
                    blink: !reduceMotion && sin(elapsed * 1.3 + b.phase) > 0.97)
        }

        // Burst bubbles.
        for bub in bubbles {
            let p = min(1.0, (elapsed - bub.born) / bubbleLife)
            let pt = P(bub.pos)
            let rr = CGFloat(10 * (1.0 - p)) + 3
            let rect = CGRect(x: pt.x - rr, y: pt.y - rr, width: rr * 2, height: rr * 2)
            ctx.fill(Path(ellipseIn: rect),
                     with: .color(.white.opacity(0.55 * (1.0 - p))))
        }

        // Confetti (win).
        for c in confetti {
            let p = min(1.0, (elapsed - c.born) / confettiLife)
            let pt = P(c.pos)
            let rect = CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8)
            ctx.fill(Path(roundedRect: rect, cornerRadius: 2),
                     with: .color(Self.candy[c.colorIndex].opacity(1.0 - p)))
        }
    }

    private func drawBug(_ ctx: inout GraphicsContext, at c: CGPoint,
                         scaleX: Double, scaleY: Double, rot: Double,
                         color: Color, blink: Bool) {
        ctx.drawLayer { l in
            l.translateBy(x: c.x, y: c.y)
            l.rotate(by: .radians(rot))
            l.scaleBy(x: scaleX, y: scaleY)
            let r: CGFloat = 24
            // legs
            for dx in [CGFloat(-10), CGFloat(0), CGFloat(10)] {
                let leg = CGRect(x: dx - 2.5, y: r - 4, width: 5, height: 12)
                l.fill(Path(roundedRect: leg, cornerRadius: 2.5), with: .color(color))
            }
            // body
            l.fill(Path(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2)),
                   with: .color(color))
            // eyes
            let pupilColor = Color(red: 0.16, green: 0.16, blue: 0.22)
            for ex in [CGFloat(-8), CGFloat(8)] {
                l.fill(Path(ellipseIn: CGRect(x: ex - 7, y: -8, width: 14, height: 14)),
                       with: .color(.white))
                let ph: CGFloat = blink ? 1 : 7
                let pupil = CGRect(x: ex - 3,
                                   y: CGFloat(-1) - (ph - 7) / 2,
                                   width: 6, height: ph)
                l.fill(Path(ellipseIn: pupil), with: .color(pupilColor))
            }
        }
    }
}

// MARK: - Overlay view

struct BrushGameOverlay: View {
    @StateObject private var vm = BrushGameViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { timeline in
            ZStack {
                Canvas { ctx, size in
                    vm.draw(in: &ctx, size: size, reduceMotion: reduceMotion)
                }
                .allowsHitTesting(false)

                GeometryReader { geo in
                    ForEach(vm.floaters) { f in
                        Text(f.text)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(Theme.accentBlue)
                            .modifier(FloaterFade(born: f.born, vmElapsed: vm.elapsedPublic))
                            .position(x: f.pos.x * geo.size.width,
                                      y: f.pos.y * geo.size.height)
                    }
                }
                .allowsHitTesting(false)

                hud

                if vm.won { winCelebration }
            }
            .onChange(of: timeline.date) { newDate in
                vm.step(date: newDate, reduceMotion: reduceMotion)
            }
        }
        .allowsHitTesting(false)
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }

    private var hud: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "mouth.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.accentBlue)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.35))
                        Capsule().fill(Theme.accentBlue)
                            .frame(width: g.size.width * vm.progressPublic)
                    }
                }
                .frame(height: 6)
                Text("\(vm.scorePublic)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            Spacer()
        }
        .allowsHitTesting(false)
    }

    private var winCelebration: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.accentBlue)
            Text("All sparkly clean!")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.textPrimary)
        }
        .padding(24)
        .background(Theme.surfaceFrost, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
        .transition(.scale.combined(with: .opacity))
        .allowsHitTesting(false)
    }
}

/// Floater rise + fade as a pure function of sim time.
fileprivate struct FloaterFade: ViewModifier {
    let born: Double
    let vmElapsed: Double
    func body(content: Content) -> some View {
        let p = min(1.0, max(0.0, (vmElapsed - born) / 0.40))
        return content.opacity(1.0 - p).offset(y: CGFloat(-28 * p))
    }
}

// Read-only views of sim state for SwiftUI (same-file extension can read privates).
// TimelineView re-evaluates the body each tick, so these stay current without @Published.
extension BrushGameViewModel {
    var elapsedPublic: Double { elapsed }
    var scorePublic: Int { game.score }
    var progressPublic: Double {
        let total = Double(CoarseZone.allCases.count * 3)
        return total > 0 ? min(1.0, Double(game.bugsZapped) / total) : 0
    }
}
