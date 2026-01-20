//
//  TacticalCanvasView.swift
//  Netrek
//
//  Created by Claude (Phase 2.1) on 1/18/26.
//  Performance optimization: Canvas-based rendering replaces ForEach loops
//

import SwiftUI

/// High-performance tactical view using Canvas rendering instead of ForEach loops.
/// Renders all game entities in a single draw call at controlled frame rate.
///
/// Performance improvement:
/// - Before: 8 ForEach loops × 32 entities = 256+ view updates per tick (20Hz)
/// - After: Single Canvas draw call per frame (20Hz or 60Hz)
/// - Expected CPU reduction: 70-80%
struct TacticalCanvasView: View {
    @EnvironmentObject var universe: Universe

    /// The player this view is centered on
    let me: Player

    /// Screen dimensions for coordinate calculations
    let screenWidth: CGFloat
    let screenHeight: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { _ in
            Canvas { context, size in
                // Draw background
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(.black)
                )

                // Calculate tactical viewport
                let visualWidth = universe.visualWidth
                let visualHeight = visualWidth * (size.height / size.width)

                // Draw boundary
                drawBoundary(context: context, size: size, visualWidth: visualWidth, visualHeight: visualHeight)

                // Draw planets
                for planet in universe.visiblePlanets {
                    drawPlanet(planet: planet, context: context, size: size, visualWidth: visualWidth, visualHeight: visualHeight)
                }

                // Draw tractor beams
                for target in universe.visibleTractors {
                    drawTractor(target: target, context: context, size: size, visualWidth: visualWidth, visualHeight: visualHeight)
                }

                // Draw torpedoes
                for torpedo in universe.visibleTorpedoes {
                    drawTorpedo(torpedo: torpedo, context: context, size: size, visualWidth: visualWidth, visualHeight: visualHeight)
                }

                // Draw torpedo detonations
                for torpedo in universe.explodingTorpedoes {
                    drawDetonation(torpedo: torpedo, context: context, size: size, visualWidth: visualWidth, visualHeight: visualHeight)
                }

                // Draw plasmas
                for plasma in universe.visiblePlasmas {
                    drawPlasma(plasma: plasma, context: context, size: size, visualWidth: visualWidth, visualHeight: visualHeight)
                }

                // Draw plasma detonations
                for plasma in universe.explodingPlasmas {
                    drawPlasmaDetonation(plasma: plasma, context: context, size: size, visualWidth: visualWidth, visualHeight: visualHeight)
                }

                // Draw lasers
                for laser in universe.visibleLasers {
                    drawLaser(laser: laser, context: context, size: size, visualWidth: visualWidth, visualHeight: visualHeight)
                }

                // Draw players
                for player in universe.visiblePlayers {
                    drawPlayer(player: player, context: context, size: size, visualWidth: visualWidth, visualHeight: visualHeight)
                }

                // Draw explosions
                for player in universe.explodingPlayers {
                    drawExplosion(player: player, context: context, size: size, visualWidth: visualWidth, visualHeight: visualHeight)
                }
            }
        }
    }

    // MARK: - Drawing Functions

    private func drawBoundary(context: GraphicsContext, size: CGSize, visualWidth: CGFloat, visualHeight: CGFloat) {
        let borderWidth: CGFloat = 2.0
        let rect = CGRect(x: borderWidth / 2, y: borderWidth / 2, width: size.width - borderWidth, height: size.height - borderWidth)
        context.stroke(Path(rect), with: .color(.blue), lineWidth: borderWidth)
    }

    private func drawPlanet(planet: Planet, context: GraphicsContext, size: CGSize, visualWidth: CGFloat, visualHeight: CGFloat) {
        let screenPos = calculateScreenPosition(
            entityX: planet.positionX,
            entityY: planet.positionY,
            size: size,
            visualWidth: visualWidth,
            visualHeight: visualHeight
        )

        let planetSize = calculateSize(baseSize: CGFloat(NetrekMath.planetDiameter), screenWidth: size.width, visualWidth: visualWidth)

        // Draw planet circle with team color
        let color = NetrekMath.color(team: planet.owner)
        let circle = Path(ellipseIn: CGRect(x: screenPos.x - planetSize / 2, y: screenPos.y - planetSize / 2, width: planetSize, height: planetSize))
        context.fill(circle, with: .color(color.opacity(0.5)))
        context.stroke(circle, with: .color(color), lineWidth: 2)

        // Draw planet name
        let text = Text(planet.shortName)
            .font(.system(size: 12))
            .foregroundColor(color)
        context.draw(text, at: CGPoint(x: screenPos.x, y: screenPos.y + planetSize / 2 + 8))
    }

    private func drawPlayer(player: Player, context: GraphicsContext, size: CGSize, visualWidth: CGFloat, visualHeight: CGFloat) {
        let screenPos = calculateScreenPosition(
            entityX: player.positionX,
            entityY: player.positionY,
            size: size,
            visualWidth: visualWidth,
            visualHeight: visualHeight
        )

        let playerSize = calculateSize(baseSize: CGFloat(NetrekMath.playerSize), screenWidth: size.width, visualWidth: visualWidth)

        // Draw player as colored circle
        let color = NetrekMath.color(team: player.team)
        let circle = Path(ellipseIn: CGRect(x: screenPos.x - playerSize / 2, y: screenPos.y - playerSize / 2, width: playerSize, height: playerSize))
        context.fill(circle, with: .color(color))

        // Draw player ID letter
        let playerLetter = NetrekMath.playerLetter(playerId: player.playerId)
        let text = Text(playerLetter)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
        context.draw(text, at: screenPos)
    }

    private func drawTorpedo(torpedo: Torpedo, context: GraphicsContext, size: CGSize, visualWidth: CGFloat, visualHeight: CGFloat) {
        let screenPos = calculateScreenPosition(
            entityX: torpedo.positionX,
            entityY: torpedo.positionY,
            size: size,
            visualWidth: visualWidth,
            visualHeight: visualHeight
        )

        let torpSize = calculateSize(baseSize: CGFloat(NetrekMath.torpedoSize), screenWidth: size.width, visualWidth: visualWidth)

        let rect = CGRect(x: screenPos.x - torpSize / 2, y: screenPos.y - torpSize / 2, width: torpSize, height: torpSize)
        context.fill(Path(rect), with: .color(torpedo.color))
    }

    private func drawDetonation(torpedo: Torpedo, context: GraphicsContext, size: CGSize, visualWidth: CGFloat, visualHeight: CGFloat) {
        let screenPos = calculateScreenPosition(
            entityX: torpedo.positionX,
            entityY: torpedo.positionY,
            size: size,
            visualWidth: visualWidth,
            visualHeight: visualHeight
        )

        let detonationSize: CGFloat = 40
        let circle = Path(ellipseIn: CGRect(x: screenPos.x - detonationSize / 2, y: screenPos.y - detonationSize / 2, width: detonationSize, height: detonationSize))
        context.fill(circle, with: .color(.orange.opacity(0.7)))
    }

    private func drawPlasma(plasma: Plasma, context: GraphicsContext, size: CGSize, visualWidth: CGFloat, visualHeight: CGFloat) {
        let screenPos = calculateScreenPosition(
            entityX: plasma.positionX,
            entityY: plasma.positionY,
            size: size,
            visualWidth: visualWidth,
            visualHeight: visualHeight
        )

        let plasmaSize = calculateSize(baseSize: CGFloat(NetrekMath.plasmaSize), screenWidth: size.width, visualWidth: visualWidth)

        let circle = Path(ellipseIn: CGRect(x: screenPos.x - plasmaSize / 2, y: screenPos.y - plasmaSize / 2, width: plasmaSize, height: plasmaSize))
        context.fill(circle, with: .color(plasma.color))
    }

    private func drawPlasmaDetonation(plasma: Plasma, context: GraphicsContext, size: CGSize, visualWidth: CGFloat, visualHeight: CGFloat) {
        let screenPos = calculateScreenPosition(
            entityX: plasma.positionX,
            entityY: plasma.positionY,
            size: size,
            visualWidth: visualWidth,
            visualHeight: visualHeight
        )

        let detonationSize: CGFloat = 50
        let circle = Path(ellipseIn: CGRect(x: screenPos.x - detonationSize / 2, y: screenPos.y - detonationSize / 2, width: detonationSize, height: detonationSize))
        context.fill(circle, with: .color(.red.opacity(0.7)))
    }

    private func drawLaser(laser: Laser, context: GraphicsContext, size: CGSize, visualWidth: CGFloat, visualHeight: CGFloat) {
        let sourcePos = calculateScreenPosition(
            entityX: laser.positionX,
            entityY: laser.positionY,
            size: size,
            visualWidth: visualWidth,
            visualHeight: visualHeight
        )

        let targetPos = calculateScreenPosition(
            entityX: laser.targetPositionX,
            entityY: laser.targetPositionY,
            size: size,
            visualWidth: visualWidth,
            visualHeight: visualHeight
        )

        var path = Path()
        path.move(to: sourcePos)
        path.addLine(to: targetPos)
        context.stroke(path, with: .color(.red), lineWidth: 2)
    }

    private func drawTractor(target: Player, context: GraphicsContext, size: CGSize, visualWidth: CGFloat, visualHeight: CGFloat) {
        let sourcePos = calculateScreenPosition(
            entityX: me.positionX,
            entityY: me.positionY,
            size: size,
            visualWidth: visualWidth,
            visualHeight: visualHeight
        )

        let targetPos = calculateScreenPosition(
            entityX: target.positionX,
            entityY: target.positionY,
            size: size,
            visualWidth: visualWidth,
            visualHeight: visualHeight
        )

        var path = Path()
        path.move(to: sourcePos)
        path.addLine(to: targetPos)
        context.stroke(path, with: .color(.green), lineWidth: 2)
    }

    private func drawExplosion(player: Player, context: GraphicsContext, size: CGSize, visualWidth: CGFloat, visualHeight: CGFloat) {
        let screenPos = calculateScreenPosition(
            entityX: player.positionX,
            entityY: player.positionY,
            size: size,
            visualWidth: visualWidth,
            visualHeight: visualHeight
        )

        let explosionSize: CGFloat = 60
        let circle = Path(ellipseIn: CGRect(x: screenPos.x - explosionSize / 2, y: screenPos.y - explosionSize / 2, width: explosionSize, height: explosionSize))
        context.fill(circle, with: .color(.yellow.opacity(0.7)))
        context.stroke(circle, with: .color(.orange), lineWidth: 3)
    }

    // MARK: - Helper Functions

    /// Calculate screen position from game coordinates
    private func calculateScreenPosition(entityX: Int, entityY: Int, size: CGSize, visualWidth: CGFloat, visualHeight: CGFloat) -> CGPoint {
        let deltaX = CGFloat(entityX - me.positionX)
        let deltaY = CGFloat(entityY - me.positionY)

        let screenX = size.width / 2 + (deltaX * size.width / visualWidth)
        let screenY = size.height / 2 - (deltaY * size.height / visualHeight)

        return CGPoint(x: screenX, y: screenY)
    }

    /// Calculate scaled size for entities
    private func calculateSize(baseSize: CGFloat, screenWidth: CGFloat, visualWidth: CGFloat) -> CGFloat {
        return baseSize * screenWidth / visualWidth
    }
}

#if DEBUG
#Preview {
    _ = PreviewHelpers.setupPreviewUniverse()
    let universe = Universe.universe
    let me = universe.players[universe.me]

    TacticalCanvasView(
        me: me,
        screenWidth: PreviewHelpers.screenWidthMac,
        screenHeight: PreviewHelpers.screenHeightMac
    )
    .environmentObject(universe)
    .frame(width: PreviewHelpers.screenWidthMac, height: PreviewHelpers.screenHeightMac)
}
#endif
