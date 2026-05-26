// MARK: - DuoCharacters.swift
//
// SwiftUI ports of the five Duolingo-lane characters defined in
// docs/character-explorations.html (Set 02). Each character renders via
// Canvas using the same 140×160 reference coordinate system as the HTML
// source. Strokes/fills/positions track the HTML 1:1.

import SwiftUI

// =====================================================================
// MARK: - Coordinate helper
// =====================================================================

/// Maps a normalized 140×160 reference into whatever rect SwiftUI gives.
struct DuoCanvas {
    let size: CGSize
    let scale: CGFloat
    let ox: CGFloat
    let oy: CGFloat

    init(size: CGSize, refW: CGFloat = 140, refH: CGFloat = 160) {
        self.size = size
        self.scale = min(size.width / refW, size.height / refH)
        self.ox = (size.width  - refW * scale) / 2
        self.oy = (size.height - refH * scale) / 2
    }

    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: ox + x * scale, y: oy + y * scale)
    }
    func s(_ v: CGFloat) -> CGFloat { v * scale }

    /// Ellipse in normalized coords (cx, cy, rx, ry).
    func ellipse(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: ox + (cx - rx) * scale,
                               y: oy + (cy - ry) * scale,
                               width:  rx * 2 * scale,
                               height: ry * 2 * scale))
    }
    func circle(cx: CGFloat, cy: CGFloat, r: CGFloat) -> Path {
        ellipse(cx: cx, cy: cy, rx: r, ry: r)
    }
}

// =====================================================================
// MARK: - BuddyView — main tooth character
// =====================================================================

struct BuddyView: View {
    var body: some View {
        Canvas { ctx, size in
            let c = DuoCanvas(size: size)

            // Body path
            var body = Path()
            body.move(to: c.p(28, 38))
            body.addQuadCurve(to: c.p(50, 16),  control: c.p(28, 18))
            body.addLine(to: c.p(90, 16))
            body.addQuadCurve(to: c.p(112, 38), control: c.p(112, 18))
            body.addLine(to: c.p(112, 98))
            body.addQuadCurve(to: c.p(96, 152),  control: c.p(112, 130))
            body.addQuadCurve(to: c.p(80, 152),  control: c.p(90, 158))
            body.addQuadCurve(to: c.p(72, 118),  control: c.p(72, 138))
            body.addQuadCurve(to: c.p(64, 152),  control: c.p(72, 138))
            body.addQuadCurve(to: c.p(48, 152),  control: c.p(54, 158))
            body.addQuadCurve(to: c.p(28, 98),   control: c.p(28, 130))
            body.closeSubpath()

            // Shadow (offset y+4)
            var shadow = body
            shadow = shadow.applying(.init(translationX: 0, y: Duo.depthOffset))
            ctx.fill(shadow, with: .color(Duo.ink))

            ctx.fill(body, with: .color(Duo.cream))
            ctx.stroke(body, with: .color(Duo.ink), lineWidth: c.s(3.5))

            // Cheek blush
            ctx.fill(c.ellipse(cx: 42, cy: 78, rx: 9, ry: 6), with: .color(Duo.blush))
            ctx.fill(c.ellipse(cx: 98, cy: 78, rx: 9, ry: 6), with: .color(Duo.blush))

            // Dot eyes
            ctx.fill(c.circle(cx: 55, cy: 62, r: 5.5), with: .color(Duo.ink))
            ctx.fill(c.circle(cx: 85, cy: 62, r: 5.5), with: .color(Duo.ink))
            // Sparkle highlights
            ctx.fill(c.circle(cx: 57, cy: 60, r: 1.5), with: .color(.white))
            ctx.fill(c.circle(cx: 87, cy: 60, r: 1.5), with: .color(.white))

            // Asymmetric smile
            var smile = Path()
            smile.move(to: c.p(55, 84))
            smile.addQuadCurve(to: c.p(86, 86), control: c.p(72, 96))
            ctx.stroke(smile, with: .color(Duo.ink),
                       style: StrokeStyle(lineWidth: c.s(3.5), lineCap: .round))
        }
        .aspectRatio(140.0 / 160.0, contentMode: .fit)
    }
}

// =====================================================================
// MARK: - PlaqueView — cute germ creature (antagonist)
// =====================================================================

struct PlaqueView: View {
    var body: some View {
        Canvas { ctx, size in
            let c = DuoCanvas(size: size)

            // Ground shadow
            ctx.fill(c.ellipse(cx: 70, cy: 146, rx: 34, ry: 5),
                     with: .color(Duo.ink.opacity(0.18)))

            // Antennae lines + tip dots
            for (curveStart, curveEnd, control, tipX, tipY) in [
                (CGPoint(x: 58, y: 36), CGPoint(x: 60, y: 18), CGPoint(x: 54, y: 24), CGFloat(60), CGFloat(16)),
                (CGPoint(x: 82, y: 36), CGPoint(x: 80, y: 18), CGPoint(x: 86, y: 24), CGFloat(80), CGFloat(16))
            ] {
                var ant = Path()
                ant.move(to: c.p(curveStart.x, curveStart.y))
                ant.addQuadCurve(to: c.p(curveEnd.x, curveEnd.y), control: c.p(control.x, control.y))
                ctx.stroke(ant, with: .color(Duo.ink),
                           style: StrokeStyle(lineWidth: c.s(3), lineCap: .round))
                let dot = c.circle(cx: tipX, cy: tipY, r: 4)
                ctx.fill(dot, with: .color(Duo.red))
                ctx.stroke(dot, with: .color(Duo.ink), lineWidth: c.s(2.5))
            }

            // Stubby arms + hand circles
            for (start, end, handX) in [
                (CGPoint(x: 28, y: 86), CGPoint(x: 18, y: 78), CGFloat(18)),
                (CGPoint(x: 112, y: 86), CGPoint(x: 122, y: 78), CGFloat(122))
            ] {
                var arm = Path()
                arm.move(to: c.p(start.x, start.y))
                arm.addLine(to: c.p(end.x, end.y))
                ctx.stroke(arm, with: .color(Duo.ink),
                           style: StrokeStyle(lineWidth: c.s(6), lineCap: .round))
                let hand = c.circle(cx: handX, cy: 78, r: 5)
                ctx.fill(hand, with: .color(Duo.plaqueGreen))
                ctx.stroke(hand, with: .color(Duo.ink), lineWidth: c.s(2.5))
            }

            // Stubby legs
            for (start, end) in [
                (CGPoint(x: 50, y: 130), CGPoint(x: 46, y: 142)),
                (CGPoint(x: 90, y: 130), CGPoint(x: 94, y: 142))
            ] {
                var leg = Path()
                leg.move(to: c.p(start.x, start.y))
                leg.addLine(to: c.p(end.x, end.y))
                ctx.stroke(leg, with: .color(Duo.ink),
                           style: StrokeStyle(lineWidth: c.s(7), lineCap: .round))
            }

            // Body shape (rounded blob)
            var body = Path()
            body.move(to: c.p(28, 86))
            body.addQuadCurve(to: c.p(70, 42),   control: c.p(28, 46))
            body.addQuadCurve(to: c.p(112, 86),  control: c.p(112, 46))
            body.addQuadCurve(to: c.p(70, 128),  control: c.p(112, 124))
            body.addQuadCurve(to: c.p(28, 86),   control: c.p(28, 124))
            body.closeSubpath()

            // Body shadow
            var bodyShadow = body
            bodyShadow = bodyShadow.applying(.init(translationX: 0, y: Duo.depthOffset))
            ctx.fill(bodyShadow, with: .color(Duo.ink))

            ctx.fill(body, with: .color(Duo.plaqueGreen))
            ctx.stroke(body, with: .color(Duo.ink), lineWidth: c.s(3.5))

            // Texture spots
            ctx.fill(c.ellipse(cx: 44,  cy: 64,  rx: 6, ry: 5), with: .color(Duo.plaqueGreenDeep))
            ctx.fill(c.ellipse(cx: 98,  cy: 76,  rx: 7, ry: 5), with: .color(Duo.plaqueGreenDeep))
            ctx.fill(c.ellipse(cx: 56,  cy: 108, rx: 5, ry: 4), with: .color(Duo.plaqueGreenDeep))
            ctx.fill(c.ellipse(cx: 92,  cy: 112, rx: 6, ry: 4), with: .color(Duo.plaqueGreenDeep))

            // Eyes — white circles with ink stroke
            let leftEye  = c.circle(cx: 56, cy: 78, r: 10)
            let rightEye = c.circle(cx: 84, cy: 78, r: 10)
            ctx.fill(leftEye, with: .color(.white))
            ctx.stroke(leftEye, with: .color(Duo.ink), lineWidth: c.s(3))
            ctx.fill(rightEye, with: .color(.white))
            ctx.stroke(rightEye, with: .color(Duo.ink), lineWidth: c.s(3))

            // Pupils — looking sideways (mischief)
            ctx.fill(c.circle(cx: 60, cy: 80, r: 4), with: .color(Duo.ink))
            ctx.fill(c.circle(cx: 88, cy: 80, r: 4), with: .color(Duo.ink))
            ctx.fill(c.circle(cx: 61.5, cy: 78.5, r: 1.5), with: .color(.white))
            ctx.fill(c.circle(cx: 89.5, cy: 78.5, r: 1.5), with: .color(.white))

            // Sneaky smile
            var smile = Path()
            smile.move(to: c.p(56, 100))
            smile.addQuadCurve(to: c.p(84, 102), control: c.p(70, 110))
            ctx.stroke(smile, with: .color(Duo.ink),
                       style: StrokeStyle(lineWidth: c.s(3), lineCap: .round))

            // Single fang
            var fang = Path()
            fang.move(to: c.p(64, 104))
            fang.addLine(to: c.p(66, 110))
            fang.addLine(to: c.p(70, 105))
            fang.closeSubpath()
            ctx.fill(fang, with: .color(.white))
            ctx.stroke(fang, with: .color(Duo.ink), lineWidth: c.s(1.5))
        }
        .aspectRatio(140.0 / 160.0, contentMode: .fit)
    }
}

// =====================================================================
// MARK: - BrushCharacterView — toothbrush sidekick
// =====================================================================

struct BrushCharacterView: View {
    var body: some View {
        Canvas { ctx, size in
            let c = DuoCanvas(size: size)

            // Toothpaste blob
            var paste = Path()
            paste.move(to: c.p(56, 20))
            paste.addQuadCurve(to: c.p(84, 20), control: c.p(70, 6))
            paste.addQuadCurve(to: c.p(82, 30), control: c.p(86, 26))
            paste.addLine(to: c.p(58, 30))
            paste.addQuadCurve(to: c.p(56, 20), control: c.p(54, 26))
            paste.closeSubpath()
            ctx.fill(paste, with: .color(Duo.red))
            ctx.stroke(paste, with: .color(Duo.ink), lineWidth: c.s(2.5))
            ctx.fill(c.ellipse(cx: 66, cy: 20, rx: 3, ry: 2),
                     with: .color(.white.opacity(0.8)))

            // Bristles trapezoid path
            var bristles = Path()
            bristles.move(to: c.p(28, 30))
            bristles.addLine(to: c.p(112, 30))
            bristles.addLine(to: c.p(100, 56))
            bristles.addLine(to: c.p(40, 56))
            bristles.closeSubpath()

            var bristlesShadow = bristles
            bristlesShadow = bristlesShadow.applying(.init(translationX: 0, y: Duo.depthOffset))
            ctx.fill(bristlesShadow, with: .color(Duo.ink))
            ctx.fill(bristles, with: .color(.white))
            ctx.stroke(bristles, with: .color(Duo.ink), lineWidth: c.s(3.5))

            // Bristle vertical lines
            for (x1, x2) in [(40.0, 44.0), (54.0, 56.0), (70.0, 70.0), (86.0, 84.0), (100.0, 96.0)] {
                var line = Path()
                line.move(to: c.p(x1, 32))
                line.addLine(to: c.p(x2, 54))
                ctx.stroke(line, with: .color(Duo.ink), lineWidth: c.s(2))
            }

            // Handle path
            var handle = Path()
            handle.move(to: c.p(48, 56))
            handle.addLine(to: c.p(92, 56))
            handle.addLine(to: c.p(88, 140))
            handle.addQuadCurve(to: c.p(70, 150), control: c.p(88, 150))
            handle.addQuadCurve(to: c.p(52, 140), control: c.p(52, 150))
            handle.closeSubpath()

            var handleShadow = handle
            handleShadow = handleShadow.applying(.init(translationX: 0, y: Duo.depthOffset))
            ctx.fill(handleShadow, with: .color(Duo.ink))

            ctx.fill(handle, with: .color(Duo.blue))
            ctx.stroke(handle, with: .color(Duo.ink), lineWidth: c.s(3.5))

            // Eyes
            let lEye = c.circle(cx: 58, cy: 84, r: 9)
            let rEye = c.circle(cx: 82, cy: 84, r: 9)
            ctx.fill(lEye, with: .color(.white))
            ctx.stroke(lEye, with: .color(Duo.ink), lineWidth: c.s(3))
            ctx.fill(rEye, with: .color(.white))
            ctx.stroke(rEye, with: .color(Duo.ink), lineWidth: c.s(3))

            ctx.fill(c.circle(cx: 60, cy: 86, r: 4), with: .color(Duo.ink))
            ctx.fill(c.circle(cx: 84, cy: 86, r: 4), with: .color(Duo.ink))
            ctx.fill(c.circle(cx: 61, cy: 84.5, r: 1.5), with: .color(.white))
            ctx.fill(c.circle(cx: 85, cy: 84.5, r: 1.5), with: .color(.white))

            // Cheerful smile
            var smile = Path()
            smile.move(to: c.p(58, 108))
            smile.addQuadCurve(to: c.p(82, 108), control: c.p(70, 116))
            ctx.stroke(smile, with: .color(Duo.ink),
                       style: StrokeStyle(lineWidth: c.s(3), lineCap: .round))

            // Handle highlight stripe
            var hl = Path()
            hl.move(to: c.p(58, 66))
            hl.addLine(to: c.p(58, 128))
            ctx.stroke(hl, with: .color(.white.opacity(0.45)),
                       style: StrokeStyle(lineWidth: c.s(3), lineCap: .round))
        }
        .aspectRatio(140.0 / 160.0, contentMode: .fit)
    }
}

// =====================================================================
// MARK: - WisdomView — adult-mode molar
// =====================================================================

struct WisdomView: View {
    var body: some View {
        Canvas { ctx, size in
            let c = DuoCanvas(size: size)

            // Molar body
            var body = Path()
            body.move(to: c.p(18, 56))
            body.addQuadCurve(to: c.p(28, 32),  control: c.p(18, 40))
            body.addQuadCurve(to: c.p(52, 30),  control: c.p(40, 22))
            body.addQuadCurve(to: c.p(70, 28),  control: c.p(62, 24))
            body.addQuadCurve(to: c.p(88, 30),  control: c.p(78, 24))
            body.addQuadCurve(to: c.p(112, 32), control: c.p(100, 22))
            body.addQuadCurve(to: c.p(122, 56), control: c.p(122, 40))
            body.addLine(to: c.p(122, 116))
            body.addQuadCurve(to: c.p(110, 138), control: c.p(122, 132))
            body.addLine(to: c.p(30, 138))
            body.addQuadCurve(to: c.p(18, 116),  control: c.p(18, 132))
            body.closeSubpath()

            var bodyShadow = body
            bodyShadow = bodyShadow.applying(.init(translationX: 0, y: Duo.depthOffset))
            ctx.fill(bodyShadow, with: .color(Duo.ink))

            ctx.fill(body, with: .color(Duo.cream))
            ctx.stroke(body, with: .color(Duo.ink), lineWidth: c.s(3.5))

            // Reading glasses
            let lLens = c.circle(cx: 48, cy: 82, r: 14)
            let rLens = c.circle(cx: 92, cy: 82, r: 14)
            ctx.fill(lLens, with: .color(Duo.cream.opacity(0.5)))
            ctx.stroke(lLens, with: .color(Duo.ink), lineWidth: c.s(3))
            ctx.fill(rLens, with: .color(Duo.cream.opacity(0.5)))
            ctx.stroke(rLens, with: .color(Duo.ink), lineWidth: c.s(3))

            // Bridge between lenses
            var bridge = Path()
            bridge.move(to: c.p(62, 82))
            bridge.addLine(to: c.p(78, 82))
            ctx.stroke(bridge, with: .color(Duo.ink), lineWidth: c.s(3))

            // Temple arms out to sides
            var ltemple = Path()
            ltemple.move(to: c.p(34, 82))
            ltemple.addLine(to: c.p(24, 78))
            ctx.stroke(ltemple, with: .color(Duo.ink),
                       style: StrokeStyle(lineWidth: c.s(2.5), lineCap: .round))
            var rtemple = Path()
            rtemple.move(to: c.p(106, 82))
            rtemple.addLine(to: c.p(116, 78))
            ctx.stroke(rtemple, with: .color(Duo.ink),
                       style: StrokeStyle(lineWidth: c.s(2.5), lineCap: .round))

            // Almond closed-content eyes
            var leye = Path()
            leye.move(to: c.p(42, 82))
            leye.addQuadCurve(to: c.p(54, 82), control: c.p(48, 78))
            ctx.stroke(leye, with: .color(Duo.ink),
                       style: StrokeStyle(lineWidth: c.s(3), lineCap: .round))
            var reye = Path()
            reye.move(to: c.p(86, 82))
            reye.addQuadCurve(to: c.p(98, 82), control: c.p(92, 78))
            ctx.stroke(reye, with: .color(Duo.ink),
                       style: StrokeStyle(lineWidth: c.s(3), lineCap: .round))

            // Cheeks
            ctx.fill(c.ellipse(cx: 28,  cy: 104, rx: 7, ry: 4),
                     with: .color(Duo.blush.opacity(0.85)))
            ctx.fill(c.ellipse(cx: 112, cy: 104, rx: 7, ry: 4),
                     with: .color(Duo.blush.opacity(0.85)))

            // Calm small smile
            var smile = Path()
            smile.move(to: c.p(60, 110))
            smile.addQuadCurve(to: c.p(80, 110), control: c.p(70, 116))
            ctx.stroke(smile, with: .color(Duo.ink),
                       style: StrokeStyle(lineWidth: c.s(3), lineCap: .round))
        }
        .aspectRatio(140.0 / 160.0, contentMode: .fit)
    }
}

// =====================================================================
// MARK: - FoamView — celebration / completion
// =====================================================================

struct FoamView: View {
    var body: some View {
        Canvas { ctx, size in
            let c = DuoCanvas(size: size)

            // Small companion bubbles
            for (cx, cy, r, pupilX, pupilY, pupilR) in [
                (CGFloat(22), CGFloat(46), CGFloat(9), CGFloat(20), CGFloat(48), CGFloat(2)),
                (CGFloat(120), CGFloat(42), CGFloat(11), CGFloat(123), CGFloat(44), CGFloat(2.5)),
                (CGFloat(120), CGFloat(124), CGFloat(10), CGFloat(123), CGFloat(125), CGFloat(2)),
                (CGFloat(18), CGFloat(126), CGFloat(11), CGFloat(15), CGFloat(127), CGFloat(2.5))
            ] {
                let outer = c.circle(cx: cx, cy: cy, r: r)
                ctx.fill(outer, with: .color(Duo.foamFill))
                ctx.stroke(outer, with: .color(Duo.ink), lineWidth: c.s(2.5))
                ctx.fill(c.circle(cx: pupilX, cy: pupilY, r: pupilR),
                         with: .color(Duo.ink))
            }

            // Main bubble shadow
            var mainShadow = c.circle(cx: 72, cy: 84, r: 44)
            mainShadow = mainShadow.applying(.init(translationX: 0, y: Duo.depthOffset))
            ctx.fill(mainShadow, with: .color(Duo.ink))

            let main = c.circle(cx: 72, cy: 84, r: 44)
            ctx.fill(main, with: .color(Duo.foamFill))
            ctx.stroke(main, with: .color(Duo.ink), lineWidth: c.s(3.5))

            // Main highlights
            ctx.fill(c.ellipse(cx: 54, cy: 62, rx: 11, ry: 7),
                     with: .color(.white.opacity(0.9)))
            ctx.fill(c.ellipse(cx: 64, cy: 56, rx: 3, ry: 2),
                     with: .color(.white))

            // Closed happy eyes
            var leye = Path()
            leye.move(to: c.p(52, 80))
            leye.addQuadCurve(to: c.p(64, 80), control: c.p(58, 74))
            ctx.stroke(leye, with: .color(Duo.ink),
                       style: StrokeStyle(lineWidth: c.s(3.5), lineCap: .round))
            var reye = Path()
            reye.move(to: c.p(80, 80))
            reye.addQuadCurve(to: c.p(92, 80), control: c.p(86, 74))
            ctx.stroke(reye, with: .color(Duo.ink),
                       style: StrokeStyle(lineWidth: c.s(3.5), lineCap: .round))

            // Big open joy smile
            var smile = Path()
            smile.move(to: c.p(54, 96))
            smile.addQuadCurve(to: c.p(90, 96), control: c.p(72, 116))
            ctx.stroke(smile, with: .color(Duo.ink),
                       style: StrokeStyle(lineWidth: c.s(3.5),
                                          lineCap: .round,
                                          lineJoin: .round))

            // Pink tongue
            var tongue = Path()
            tongue.move(to: c.p(60, 100))
            tongue.addQuadCurve(to: c.p(84, 100), control: c.p(72, 112))
            tongue.addQuadCurve(to: c.p(60, 100), control: c.p(72, 108))
            tongue.closeSubpath()
            ctx.fill(tongue, with: .color(Duo.blush))
            ctx.stroke(tongue, with: .color(Duo.ink),
                       style: StrokeStyle(lineWidth: c.s(2),
                                          lineJoin: .round))

            // Cheek dabs
            ctx.fill(c.ellipse(cx: 48, cy: 92, rx: 5, ry: 3),
                     with: .color(Duo.blush.opacity(0.7)))
            ctx.fill(c.ellipse(cx: 96, cy: 92, rx: 5, ry: 3),
                     with: .color(Duo.blush.opacity(0.7)))
        }
        .aspectRatio(140.0 / 160.0, contentMode: .fit)
    }
}
