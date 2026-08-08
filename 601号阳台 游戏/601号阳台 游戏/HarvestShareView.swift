import SwiftUI

struct HarvestShareView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false
    @State private var mailboxFrame: CGRect = .zero
    @State private var showSentConfirmation = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.96, green: 0.93, blue: 0.88), Color(red: 0.88, green: 0.82, blue: 0.73)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 18)
                        .padding(.top, 14)

                    Spacer()

                    Text("点击番茄信箱，把收获分享给朋友")
                        .font(.headline)
                        .foregroundStyle(.brown.opacity(0.82))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }

                MailboxIcon(isAnimating: $isAnimating)
                    .frame(width: 78, height: 68)
                    .padding(.trailing, 22)
                    .padding(.top, 14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear {
                                    mailboxFrame = proxy.frame(in: .global)
                                }
                                .onChange(of: proxy.frame(in: .global)) { newFrame in
                                    mailboxFrame = newFrame
                                }
                        }
                    )

                if isAnimating {
                    LetterView(
                        isAnimating: $isAnimating,
                        startPoint: CGPoint(x: mailboxFrame.midX, y: mailboxFrame.midY),
                        screenSize: geometry.size,
                        onSent: {
                            showSentConfirmation = true
                        }
                    )
                }

                if showSentConfirmation {
                    VStack {
                        Spacer()
                        Text("分享已送出")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .foregroundStyle(.white)
                            .background(.green.opacity(0.88), in: Capsule())
                            .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 4)
                            .padding(.bottom, 26)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showSentConfirmation = false
                            }
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(.brown.opacity(0.78))
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.45), in: Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("收获分享")
                    .font(.title3.bold())
                    .foregroundStyle(.brown)
                Text("把刚刚摘下的番茄发出去")
                    .font(.footnote)
                    .foregroundStyle(.brown.opacity(0.65))
            }

            Spacer()
        }
    }
}

struct MailboxIcon: View {
    @Binding var isAnimating: Bool
    @State private var lidRotation: Double = 0

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color.red.opacity(0.92), Color.orange.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 42)
                .overlay(
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white.opacity(0.58))
                            .frame(height: 3)
                            .padding(.horizontal, 11)
                            .padding(.bottom, 8)
                    }
                )
                .shadow(color: .black.opacity(0.14), radius: 6, x: 0, y: 3)

            MailboxLid()
                .rotation3DEffect(
                    .degrees(lidRotation),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .bottom
                )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isAnimating else { return }
            isAnimating = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) {
                lidRotation = -180
            }
        }
        .onChange(of: isAnimating) { newValue in
            if !newValue {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                    lidRotation = 0
                }
            }
        }
    }
}

struct MailboxLid: View {
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 16))
                path.addQuadCurve(
                    to: CGPoint(x: 58, y: 16),
                    control: CGPoint(x: 29, y: 0)
                )
                path.addLine(to: CGPoint(x: 58, y: 21))
                path.addLine(to: CGPoint(x: 0, y: 21))
                path.closeSubpath()
            }
            .fill(Color.red.opacity(0.95))
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 16))
                    path.addQuadCurve(
                        to: CGPoint(x: 58, y: 16),
                        control: CGPoint(x: 29, y: 0)
                    )
                }
                .stroke(Color.white.opacity(0.42), lineWidth: 1.4)
            )

            Rectangle()
                .fill(Color.red.opacity(0.82))
                .frame(width: 58, height: 5)
                .offset(y: 18)
        }
        .frame(width: 58, height: 26)
        .offset(y: -5)
    }
}

struct LetterView: View {
    @Binding var isAnimating: Bool
    let startPoint: CGPoint
    let screenSize: CGSize
    let onSent: () -> Void

    @State private var animationPhase: AnimationPhase = .moveToCenter
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var rotation: Double = -8

    private var centerPoint: CGPoint {
        CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
    }

    enum AnimationPhase {
        case moveToCenter, display, dismiss
    }

    var body: some View {
        ZStack {
            if animationPhase != .moveToCenter {
                Color.black.opacity(0.18)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissLetter()
                    }
                    .transition(.opacity)
            }

            letterContent
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
                .position(animationPhase == .moveToCenter ? startPoint : centerPoint)
                .animation(.none, value: animationPhase)
        }
        .onAppear {
            startAnimationSequence()
        }
    }

    private var letterContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(width: 240, height: 300)
                .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🍅 收获报告")
                            .font(.headline)
                            .foregroundStyle(.red.opacity(0.82))
                        Text("本次番茄已成熟，可以分享啦")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("📮")
                        .font(.system(size: 28))
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)

                VStack(spacing: 10) {
                    ForEach(0..<7, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.25))
                            .frame(height: 1.5)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)

                Spacer()

                HStack(spacing: 10) {
                    Text("#阳台种植")
                    Text("#收获分享")
                    Text("#番茄成熟")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red.opacity(0.7))
                .padding(.bottom, 18)
            }
        }
        .frame(width: 240, height: 300)
        .contentShape(Rectangle())
        .onTapGesture {
            if animationPhase == .display {
                dismissLetter()
            }
        }
    }

    private func startAnimationSequence() {
        withAnimation(.easeOut(duration: 0.08)) {
            opacity = 1
            scale = 0.38
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.72, dampingFraction: 0.68)) {
                scale = 1.0
                rotation = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
                animationPhase = .display
            }
        }
    }

    private func dismissLetter() {
        animationPhase = .dismiss

        withAnimation(.easeIn(duration: 0.28)) {
            opacity = 0
            scale = 0.1
            rotation = 12
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            onSent()
            isAnimating = false
        }
    }
}

#Preview {
    HarvestShareView()
}
