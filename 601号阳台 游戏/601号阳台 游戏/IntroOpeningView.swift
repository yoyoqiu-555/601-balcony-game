import SwiftUI

// MARK: - Opening Flow

enum OpeningScene: Int, CaseIterable {
    case city
    case building
    case elevatorTransition
    case room
    case deliveryWindow
    case choice
}

@MainActor
final class OpeningSceneManager: ObservableObject {
    @Published var scene: OpeningScene = .city
    @Published var sceneStartedAt = Date()
    @Published var transitionProgress: Double = 0
    @Published var selectedChoice: ChoiceSelection?
    @Published var isFinished = false

    enum ChoiceSelection {
        case destroy
        case keep
    }

    private var flowTask: Task<Void, Never>?
    private var choiceTask: Task<Void, Never>?

    func start() {
        flowTask?.cancel()
        choiceTask?.cancel()
        isFinished = false
        selectedChoice = nil
        scene = .city
        sceneStartedAt = .now
        transitionProgress = 0

        flowTask = Task {
            await runAutoScenes()
        }
    }

    func restart() {
        start()
    }

    func selectChoice(_ choice: ChoiceSelection) {
        guard scene == .choice, selectedChoice == nil else { return }
        selectedChoice = choice
        choiceTask?.cancel()
        choiceTask = Task {
            await finishFlowIfNeeded(after: 1.15)
        }
    }

    func progressRatio(currentTime: Date = .now) -> Double {
        let elapsed = currentTime.timeIntervalSince(sceneStartedAt)
        let duration: Double = switch scene {
        case .city: 6.0
        case .building: 4.0
        case .elevatorTransition: 4.0
        case .room: 6.0
        case .deliveryWindow: 7.0
        case .choice: 5.0
        }
        return min(max(elapsed / duration, 0), 1)
    }

    private func runAutoScenes() async {
        let timings: [(OpeningScene, UInt64)] = [
            (.city, 6_000_000_000),
            (.building, 4_000_000_000),
            (.elevatorTransition, 3_000_000_000),
            (.room, 6_000_000_000),
            (.deliveryWindow, 7_000_000_000),
            (.choice, 5_000_000_000)
        ]

        for (index, item) in timings.enumerated() {
            scene = item.0
            sceneStartedAt = .now
            transitionProgress = 0

            let start = Date()
            let durationSeconds = Double(item.1) / 1_000_000_000
            while Date().timeIntervalSince(start) < durationSeconds {
                if Task.isCancelled { return }
                transitionProgress = progressRatio()
                try? await Task.sleep(for: .milliseconds(33))
            }

            if Task.isCancelled { return }

            if item.0 == .choice {
                break
            }

            if index < timings.count - 1 {
                withAnimation(.easeInOut(duration: 0.35)) {
                    transitionProgress = 1
                }
            }
        }
    }

    private func finishFlowIfNeeded(after delay: Double) async {
        try? await Task.sleep(for: .seconds(delay))
        if Task.isCancelled { return }
        isFinished = true
    }
}

struct OpeningRootView: View {
    @StateObject private var manager = OpeningSceneManager()
    @State private var showMainGame = false

    var body: some View {
        ZStack {
            switch manager.scene {
            case .city:
                OpeningCityScene(progress: manager.progressRatio())
            case .building:
                OpeningBuildingScene(progress: manager.progressRatio())
            case .elevatorTransition:
                OpeningElevatorTransitionScene(progress: manager.progressRatio())
            case .room:
                OpeningRoomScene(progress: manager.progressRatio())
            case .deliveryWindow:
                OpeningDeliveryWindowScene(progress: manager.progressRatio())
            case .choice:
                OpeningChoiceScene(progress: manager.progressRatio(), selection: manager.selectedChoice) { choice in
                    manager.selectChoice(choice)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            manager.start()
        }
        .onChange(of: manager.isFinished) { _, newValue in
            if newValue {
                showMainGame = true
            }
        }
        .fullScreenCover(isPresented: $showMainGame) {
            ContentView()
        }
    }
}

// MARK: - Shared Visuals

struct OpeningTextBlock: View {
    let lines: [String]
    let alignment: Alignment
    let maxWidth: CGFloat

    var body: some View {
        VStack(alignment: alignment == .leading ? .leading : .center, spacing: 8) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .shadow(color: .black.opacity(0.45), radius: 0, x: 1, y: 1)
            }
        }
        .multilineTextAlignment(alignment == .leading ? .leading : .center)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .frame(maxWidth: maxWidth)
    }
}

struct AISystemMessage: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold, design: .monospaced))
            .foregroundStyle(Color.cyan.opacity(0.95))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.34), in: Capsule())
            .overlay(Capsule().stroke(Color.cyan.opacity(0.22), lineWidth: 1))
    }
}

struct OpeningSceneChrome<Content: View>: View {
    let content: Content
    let showNoise: Bool

    init(showNoise: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.showNoise = showNoise
    }

    var body: some View {
        ZStack {
            content
            if showNoise {
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.03),
                        .clear,
                        Color.white.opacity(0.02),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.screen)
            }
        }
    }
}

// MARK: - Scene 1

struct OpeningCityScene: View {
    let progress: Double
    @State private var droneOffset: CGFloat = -120
    @State private var secondDroneOffset: CGFloat = 100

    var body: some View {
        ZStack {
            Image("BalconyCity")
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width * 1.2, height: UIScreen.main.bounds.height)
                .scaleEffect(1.04 + progress * 0.08)
                .offset(y: -progress * 10)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.08), Color.clear, Color.black.opacity(0.10)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .ignoresSafeArea()

            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.18), Color.black.opacity(0.28)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 180)
            }
            .ignoresSafeArea()

            HStack {
                Circle()
                    .fill(Color.cyan.opacity(0.8))
                    .frame(width: 10, height: 10)
                    .shadow(color: .cyan.opacity(0.8), radius: 8)
                    .offset(x: droneOffset, y: -110)
                Spacer()
                Circle()
                    .fill(Color.cyan.opacity(0.8))
                    .frame(width: 8, height: 8)
                    .shadow(color: .cyan.opacity(0.8), radius: 8)
                    .offset(x: secondDroneOffset, y: -40)
            }
            .padding(.horizontal, 20)
            .onAppear {
                withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                    droneOffset = 180
                }
                withAnimation(.linear(duration: 7.5).repeatForever(autoreverses: false)) {
                    secondDroneOffset = -180
                }
            }

            ScanBeamOverlay(progress: progress)
        }
    }
}

struct ScanBeamOverlay: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            let y = proxy.size.height * (0.18 + 0.55 * progress)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.red.opacity(0), Color.red.opacity(0.45), Color.red.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 4)
                .blur(radius: 1.2)
                .offset(y: y)
                .opacity(0.55)
                .blendMode(.screen)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Scene 2

struct OpeningBuildingScene: View {
    let progress: Double

    var body: some View {
        ZStack {
            Image("BalconyCity")
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width * 1.2, height: UIScreen.main.bounds.height)
                .scaleEffect(1.1 + progress * 0.05)
                .blur(radius: 1.0)
                .opacity(0.9)
                .ignoresSafeArea()

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.cyan.opacity(0.18))
                        .frame(width: 320, height: 380)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.cyan.opacity(0.30), lineWidth: 2)
                        )
                        .overlay(
                            VStack(spacing: 6) {
                                ForEach(0..<9, id: \.self) { row in
                                    HStack(spacing: 6) {
                                        ForEach(0..<5, id: \.self) { column in
                                            RoundedRectangle(cornerRadius: 1)
                                                .fill(((row + column) % 3 == 0 ? Color.white : Color.blue).opacity(0.22))
                                                .frame(width: 18, height: 18)
                                        }
                                    }
                                }
                            }
                        )
                        .padding(.trailing, 66)
                        .offset(y: -40)
                        .scaleEffect(0.82 + progress * 0.18)
                }
            }

            Rectangle()
                .fill(Color.blue.opacity(0.12))
                .blendMode(.screen)
                .ignoresSafeArea()

            if progress > 0.56 {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.cyan.opacity(0.95))
                    .frame(width: 96, height: 36)
                    .shadow(color: .cyan.opacity(0.8), radius: 12)
                    .overlay(Text("601").font(.headline).foregroundStyle(.black.opacity(0.78)))
                    .offset(x: 118, y: -28)
                    .transition(.opacity)
            }

        }
    }
}

// MARK: - Scene 3

struct OpeningElevatorTransitionScene: View {
    let progress: Double

    private var doorOpenProgress: Double {
        min(max(progress / 0.72, 0), 1)
    }

    private var fadeToRoomProgress: Double {
        if progress <= 0.7 { return 0 }
        return min((progress - 0.7) / 0.3, 1)
    }

    var body: some View {
        ZStack {
            Image("ElevatorClose")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Image("ElevatorOpen")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(doorOpenProgress)

            ElevatorDoorCurtains(progress: doorOpenProgress)
                .ignoresSafeArea()

            roomPreview
                .opacity(fadeToRoomProgress)
        }
    }

    private var roomPreview: some View {
        Image("ApartmentRoom")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .overlay(Color.white.opacity(0.10))
            .scaleEffect(1.01)
    }
}

struct ElevatorDoorCurtains: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            let doorWidth = proxy.size.width * 0.22
            let offset = proxy.size.width * 0.12 * progress

            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.black.opacity(0.36))
                    .frame(width: doorWidth)
                    .offset(x: -offset)
                Spacer(minLength: 0)
                Rectangle()
                    .fill(Color.black.opacity(0.36))
                    .frame(width: doorWidth)
                    .offset(x: offset)
            }
            .overlay(
                Rectangle()
                    .fill(Color.cyan.opacity(0.12 + progress * 0.12))
                    .frame(height: 2)
                    .offset(y: -proxy.size.height * 0.08)
                    .opacity(0.8)
            )
        }
    }
}

// MARK: - Scene 4

struct OpeningElevatorRideScene: View {
    let progress: Double

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.14, blue: 0.24), Color(red: 0.05, green: 0.08, blue: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                Image("BalconyCity")
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width * 1.3, height: UIScreen.main.bounds.height * 0.8)
                    .offset(y: 200 - progress * 420)
                    .blur(radius: 1.6)
                    .mask(
                        LinearGradient(
                            colors: [.clear, .white, .white, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(0.86)
            }
            .ignoresSafeArea()

            VStack {
                Spacer()
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cyan.opacity(0.18))
                        .frame(width: 260, height: 72)
                    Spacer()
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cyan.opacity(0.18))
                        .frame(width: 260, height: 72)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 86)
                .opacity(0.85)
            }

            VStack(spacing: 12) {
                Text("楼层下降中")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.cyan.opacity(0.9))
                Text(progress < 0.5 ? "18" : progress < 0.75 ? "09" : "01")
                    .font(.system(size: 52, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.4), radius: 0, x: 1, y: 1)
            }
            .padding(.top, 60)

            if progress > 0.66 {
                OpeningTextBlock(
                    lines: ["系统路径已更新。", "返回房间。"],
                    alignment: .center,
                    maxWidth: 300
                )
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.24)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Scene 5

struct OpeningRoomScene: View {
    let progress: Double
    @State private var lightLevel: Double = 0.0
    @State private var screenPulse: Double = 0.0

    var body: some View {
        ZStack {
            Image("ApartmentRoom")
                .resizable()
                .scaledToFill()
                .scaleEffect(1.02)
                .overlay(Color.white.opacity(0.06 + progress * 0.06))
                .ignoresSafeArea()

            Rectangle()
                .fill(Color.cyan.opacity(0.08 + lightLevel * 0.12))
                .ignoresSafeArea()

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 14) {
                        AISystemMessage(text: "空气质量：优秀")
                        AISystemMessage(text: "营养供应：已完成")
                        AISystemMessage(text: "生活状态：稳定")
                    }
                    .padding(.trailing, 18)
                    .padding(.bottom, 22)
                }
            }

            if progress > 0.15 {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.cyan.opacity(0.12 + screenPulse * 0.10))
                    .frame(width: 240, height: 120)
                    .overlay(
                        VStack(spacing: 10) {
                            Text("今日状态")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.cyan.opacity(0.95))
                            Text("稳定运行")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.94))
                        }
                    )
                    .position(x: 160, y: 180)
            }

        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                lightLevel = 1.0
                screenPulse = 1.0
            }
        }
    }
}

// MARK: - Scene 6

struct OpeningDeliveryWindowScene: View {
    let progress: Double
    @State private var boxSlide: CGFloat = 0
    @State private var lidOpen: Double = 0
    @State private var boxBounce: CGFloat = 0

    var body: some View {
        ZStack {
            Image("FoodDeliveryWindow")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Rectangle()
                .fill(Color.white.opacity(0.10))
                .ignoresSafeArea()

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    DeliveryBoxIllustration(lidOpen: lidOpen, bounce: boxBounce)
                        .offset(y: 80 + boxSlide)
                    Spacer()
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                Spacer()
                AISystemMessage(text: "发现未知生态样本。")
                AISystemMessage(text: "检测结果异常。")
                AISystemMessage(text: "该样本不属于当前生态管理系统。")
                Text("建议立即销毁。")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.cyan.opacity(0.95))
                    .padding(.top, 4)
            }
            .padding(.leading, 18)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                boxSlide = -18
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                    lidOpen = 1
                    boxBounce = 1
                }
            }
        }
    }
}

struct DeliveryBoxIllustration: View {
    let lidOpen: Double
    let bounce: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.78, green: 0.80, blue: 0.84), Color(red: 0.55, green: 0.60, blue: 0.68)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 150, height: 90)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.18), radius: 14, y: 10)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.20))
                .frame(width: 130, height: 26)
                .offset(y: -42)
                .rotation3DEffect(.degrees(-86 * lidOpen), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.6)
                .offset(y: -14 * lidOpen)

            HStack(spacing: 12) {
                SeedCardMini()
                BadgeMini()
            }
            .scaleEffect(0.92 + bounce * 0.08)
            .offset(y: 4)
        }
    }
}

struct SeedCardMini: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(red: 0.90, green: 0.86, blue: 0.76))
                .frame(width: 48, height: 40)
            Circle()
                .fill(Color.brown.opacity(0.78))
                .frame(width: 10, height: 10)
                .offset(x: 8, y: 4)
        }
    }
}

struct BadgeMini: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color(red: 0.88, green: 0.90, blue: 0.92))
            .frame(width: 56, height: 40)
            .overlay(
                VStack(spacing: 2) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("生态样本")
                        .font(.system(size: 7, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color(red: 0.26, green: 0.36, blue: 0.44))
            )
    }
}

// MARK: - Scene 7

struct OpeningChoiceScene: View {
    let progress: Double
    let selection: OpeningSceneManager.ChoiceSelection?
    let onChoose: (OpeningSceneManager.ChoiceSelection) -> Void

    @State private var warmGlow: Double = 0

    var body: some View {
        ZStack {
            choiceBackground
            warmOrb

            VStack(spacing: 14) {
                Spacer(minLength: 10)
                DeliveryChoiceSeed()
                    .scaleEffect(0.86 + 0.04 * warmGlow)
                    .padding(.top, 6)

                OpeningTextBlock(
                    lines: ["请确认您的选择。"],
                    alignment: .center,
                    maxWidth: 280
                )
                .opacity(progress > 0.18 ? 1 : 0)

                choiceButtons
                    .padding(.top, 2)

                if let selection {
                    selectionText(selection)
                        .padding(.top, 2)
                }

                footerText
                    .padding(.top, 2)
                    .padding(.bottom, 18)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                warmGlow = 1
            }
        }
    }

    private var choiceBackground: some View {
        LinearGradient(
            colors: [Color(red: 0.08, green: 0.12, blue: 0.18), Color(red: 0.18, green: 0.15, blue: 0.13)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var warmOrb: some View {
        Circle()
            .fill(Color.orange.opacity(0.18 * warmGlow))
            .blur(radius: 40)
            .frame(width: 340, height: 340)
            .position(x: UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height * 0.46)
    }

    private var choiceButtons: some View {
        HStack(spacing: 14) {
            choiceButton(title: "销毁样本", isPrimary: false) {
                onChoose(.destroy)
            }
            choiceButton(title: "保留样本", isPrimary: true) {
                onChoose(.keep)
            }
        }
    }

    private func selectionText(_ selection: OpeningSceneManager.ChoiceSelection) -> some View {
        Text(selection == .keep ? "已选择：保留样本" : "已选择：销毁样本")
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.9))
    }

    private var footerText: some View {
        Text("当所有生命都被系统管理。\n是否还有一颗种子，等待重新生长？")
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white.opacity(0.82))
            .lineLimit(2)
            .minimumScaleFactor(0.85)
    }

    private func choiceButton(title: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isPrimary ? Color.orange.opacity(0.92) : Color.white.opacity(0.14))
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isPrimary ? Color.orange.opacity(0.8) : Color.white.opacity(0.20), lineWidth: 1)
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(isPrimary ? Color.black.opacity(0.8) : Color.white.opacity(0.88))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(selection == nil ? 1 : 0.98)
        .animation(.easeInOut(duration: 0.25), value: selection)
    }
}

struct DeliveryChoiceSeed: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .frame(width: 220, height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .overlay(
                    Circle()
                        .fill(Color.orange.opacity(0.42))
                        .frame(width: 120, height: 120)
                        .blur(radius: 18)
                )

            VStack(spacing: 10) {
                Image(systemName: "circle.grid.3x3.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(Color.orange.opacity(0.85))
                Text("未知生态样本")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
            }
        }
    }
}

#Preview {
    OpeningRootView()
}
