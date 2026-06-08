import AppKit
import SwiftUI

struct NowPlayingCompactView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var manager = NowPlayingManager.shared

    var body: some View {
        HStack(spacing: 8) {
            albumHint

            if appState.usesWideCompactLayout && !manager.title.isEmpty {
                Text(manager.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
            playbackHint
        }
    }

    private var compactArtSize: CGFloat {
        appState.usesWideCompactLayout ? 22 : 24
    }

    @ViewBuilder
    private var albumHint: some View {
        if let art = manager.albumArt {
            Image(nsImage: art)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: compactArtSize, height: compactArtSize)
                .clipShape(Circle())
        } else {
            Image(systemName: "music.note")
                .font(.system(size: appState.usesWideCompactLayout ? 11 : 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: compactArtSize, height: compactArtSize)
                .background(.white.opacity(0.08), in: Circle())
        }
    }

    @ViewBuilder
    private var playbackHint: some View {
        NowPlayingPlaybackCompactButton()
    }
}

// MARK: - Equalizer Bars Animation

final class CompactAudioSpectrumView: NSView {
    private var barLayers: [CAShapeLayer] = []
    private var barScales: [CGFloat] = []
    private var animationTimer: Timer?
    private var barColor: NSColor = .white

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupBars()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupBars()
    }

    deinit {
        animationTimer?.invalidate()
    }

    private func setupBars() {
        let barWidth: CGFloat = 2
        let barCount = 4
        let spacing: CGFloat = barWidth
        let totalWidth = CGFloat(barCount) * (barWidth + spacing)
        let totalHeight: CGFloat = 14

        frame.size = CGSize(width: totalWidth, height: totalHeight)

        for index in 0..<barCount {
            let xPosition = CGFloat(index) * (barWidth + spacing)
            let barLayer = CAShapeLayer()
            barLayer.frame = CGRect(x: xPosition, y: 0, width: barWidth, height: totalHeight)
            barLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            barLayer.position = CGPoint(x: xPosition + (barWidth / 2), y: totalHeight / 2)
            barLayer.fillColor = barColor.cgColor
            barLayer.backgroundColor = barColor.cgColor
            barLayer.allowsGroupOpacity = false
            barLayer.masksToBounds = true
            barLayer.path = NSBezierPath(
                roundedRect: CGRect(x: 0, y: 0, width: barWidth, height: totalHeight),
                xRadius: barWidth / 2,
                yRadius: barWidth / 2
            ).cgPath

            barLayers.append(barLayer)
            barScales.append(0.35)
            layer?.addSublayer(barLayer)
        }
    }

    func updateBarColor(_ color: NSColor) {
        guard color != barColor else { return }
        barColor = color
        for barLayer in barLayers {
            barLayer.fillColor = color.cgColor
            barLayer.backgroundColor = color.cgColor
        }
    }

    func setPlaying(_ isPlaying: Bool) {
        if isPlaying {
            startAnimating()
        } else {
            stopAnimating()
        }
    }

    private func startAnimating() {
        guard animationTimer == nil else { return }

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.updateBars()
        }
        updateBars()
    }

    private func stopAnimating() {
        animationTimer?.invalidate()
        animationTimer = nil
        resetBars()
    }

    private func updateBars() {
        for (index, barLayer) in barLayers.enumerated() {
            let currentScale = barScales[index]
            let targetScale = CGFloat.random(in: 0.35...1.0)
            barScales[index] = targetScale

            let animation = CABasicAnimation(keyPath: "transform.scale.y")
            animation.fromValue = currentScale
            animation.toValue = targetScale
            animation.duration = 0.3
            animation.autoreverses = true
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false

            if #available(macOS 13.0, *) {
                animation.preferredFrameRateRange = CAFrameRateRange(minimum: 24, maximum: 24, preferred: 24)
            }

            barLayer.add(animation, forKey: "scaleY")
        }
    }

    private func resetBars() {
        for (index, barLayer) in barLayers.enumerated() {
            barLayer.removeAllAnimations()
            barLayer.transform = CATransform3DMakeScale(1, 0.35, 1)
            barScales[index] = 0.35
        }
    }
}

struct EqualizerBarsView: NSViewRepresentable {
    let isPlaying: Bool
    var barColor: NSColor = .white

    func makeNSView(context: Context) -> CompactAudioSpectrumView {
        let spectrumView = CompactAudioSpectrumView()
        spectrumView.updateBarColor(barColor)
        spectrumView.setPlaying(isPlaying)
        return spectrumView
    }

    func updateNSView(_ nsView: CompactAudioSpectrumView, context: Context) {
        nsView.updateBarColor(barColor)
        nsView.setPlaying(isPlaying)
    }
}

struct NowPlayingPlaybackCompactButton: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var manager = NowPlayingManager.shared

    var body: some View {
        collapsedPlaybackHint
        .frame(width: 22, height: 34, alignment: .trailing)
        .contentShape(Rectangle())
        .onHover { hovering in
            appState.setCompactMediaControlsHover(hovering)
        }
        .animation(appState.hoverAnimation, value: appState.compactMediaControlsExpanded)
    }

    @ViewBuilder
    private var collapsedPlaybackHint: some View {
        Button {
            AppState.shared.beginCompactControlInteraction()
            manager.togglePlayPause()
        } label: {
            Group {
                if manager.isPlaying {
                    EqualizerBarsView(
                        isPlaying: !appState.shouldReduceAnimations,
                        barColor: manager.albumArtColor ?? .white
                    )
                    .frame(width: 20, height: 16)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 18, height: 18)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverPointer()
    }
}

struct NowPlayingCompactTransportPopout: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var manager = NowPlayingManager.shared

    var body: some View {
        HStack(spacing: 6) {
            transportButton(systemName: "backward.fill", size: 9) {
                manager.previousTrack()
            }

            transportButton(
                systemName: manager.isPlaying ? "pause.fill" : "play.fill",
                size: manager.isPlaying ? 9 : 8.25,
                isPrimary: true
            ) {
                manager.togglePlayPause()
            }

            transportButton(systemName: "forward.fill", size: 9) {
                manager.nextTrack()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.trailing, 8)
        .contentShape(Rectangle())
        .animation(appState.hoverAnimation, value: manager.isPlaying)
    }

    private func transportButton(
        systemName: String,
        size: CGFloat,
        isPrimary: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            AppState.shared.beginCompactControlInteraction()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .bold))
                .foregroundColor(iconColor.opacity(isPrimary ? 0.98 : 0.86))
                .frame(width: 26, height: 26)
                .background(
                    Circle()
                        .fill(buttonFillColor.opacity(isPrimary ? 0.38 : 0.28))
                )
                .overlay(
                    Circle()
                        .stroke(accentColor.opacity(isPrimary ? 0.32 : 0.2), lineWidth: 1)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .hoverPointer()
        .help(helpText(for: systemName))
    }

    private var accentNSColor: NSColor {
        manager.albumArtColor ?? .controlAccentColor
    }

    private var accentColor: Color {
        Color(nsColor: accentNSColor)
    }

    private var buttonFillColor: Color {
        Color(nsColor: accentNSColor.blended(withFraction: 0.72, of: .black) ?? accentNSColor)
    }

    private var iconColor: Color {
        accentNSColor.perceivedBrightness < 0.42
            ? .white
            : Color(nsColor: accentNSColor)
    }

    private func helpText(for systemName: String) -> String {
        switch systemName {
        case "backward.fill":
            return "Previous track"
        case "forward.fill":
            return "Next track"
        default:
            return manager.isPlaying ? "Pause" : "Play"
        }
    }
}

private extension NSColor {
    var perceivedBrightness: CGFloat {
        let color = usingColorSpace(.sRGB) ?? .white
        return (0.299 * color.redComponent) + (0.587 * color.greenComponent) + (0.114 * color.blueComponent)
    }
}
