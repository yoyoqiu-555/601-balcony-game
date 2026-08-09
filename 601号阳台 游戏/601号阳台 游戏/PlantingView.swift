import SwiftUI

enum PlantState {
    case withered
    case recovering
    case healthy
}

struct PlantingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var plantState: PlantState = .withered
    @State private var hasRemovedBug = false
    @State private var hasWatered = false
    @State private var hasTrimmed = false
    @State private var bugOffset: CGFloat = 0
    @State private var showWaterDrops = false
    @State private var showScissors = false
    @State private var showCompletion = false
    @State private var showHarvestShare = false

    private let witheredPlantImage = "半枯萎状态"
    private let healthyPlantImage = "阳台近景"

    private var isHealthy: Bool {
        hasRemovedBug && hasWatered && hasTrimmed
    }

    private var currentImageName: String {
        isHealthy ? healthyPlantImage : witheredPlantImage
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let isLandscape = size.width > size.height

            ZStack {
                Color(red: 0.92, green: 0.86, blue: 0.74).ignoresSafeArea()

                if isLandscape {
                    landscapeLayout(size: size)
                } else {
                    portraitLayout(size: size)
                }

                if showCompletion {
                    VStack {
                        Text("养护完成")
                            .font(.headline)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(.green.opacity(0.92), in: Capsule())
                            .foregroundStyle(.white)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.top, 18)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .overlay(alignment: .topLeading) {
                topLeftControls
                    .padding(.top, 14)
                    .padding(.leading, 14)
            }
            .sheet(isPresented: $showHarvestShare) {
                HarvestShareView()
            }
            .ignoresSafeArea(size.width > size.height ? [] : [])
        }
    }

    private func landscapeLayout(size: CGSize) -> some View {
        HStack(spacing: 0) {
            plantArea(size: size)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            toolbar
                .frame(width: max(210, size.width * 0.28))
                .padding(.vertical, 18)
                .padding(.trailing, 14)
        }
        .overlay(alignment: .topLeading) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.black.opacity(0.7))
                    .padding(14)
            }
        }
    }

    private func portraitLayout(size: CGSize) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.black.opacity(0.7))
                }
                Spacer()
                Text("植物养护")
                    .font(.title2.bold())
                Spacer()
                Color.clear.frame(width: 28, height: 28)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            plantArea(size: size)
                .frame(maxWidth: .infinity)

            toolbar
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
    }

    private func plantArea(size: CGSize) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Image(currentImageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: size.width * 0.32, maxHeight: size.height * 0.44)
                .scaleEffect(plantState == .recovering ? 0.86 : 0.92)
                .opacity(plantState == .recovering ? 0.72 : 1)
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: plantState == .recovering)
                .animation(.easeInOut(duration: 1), value: isHealthy)

            if showWaterDrops {
                VStack(spacing: 4) {
                    ForEach(0..<8, id: \.self) { _ in
                        Text("💧")
                    }
                }
                .font(.title3)
                .offset(y: -120)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if showScissors {
                Text("✂️")
                    .font(.system(size: 42))
                    .offset(x: 88, y: 16)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if !hasRemovedBug {
                Text("🐛")
                    .font(.system(size: 28))
                    .offset(x: 95 + bugOffset, y: -105)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var toolbar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("辅助工具栏")
                .font(.headline)
                .foregroundStyle(.primary.opacity(0.8))
                .padding(.bottom, 4)

            careButton("🐛", "除虫", completed: hasRemovedBug) { removeBug() }
            careButton("💧", "浇水", completed: hasWatered) { waterPlant() }
            careButton("✂️", "修剪枝叶", completed: hasTrimmed) { trimPlant() }

            Spacer(minLength: 0)

            Text(isHealthy ? "植物已经恢复健康" : "完成三项养护，让植物恢复生机")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.34), lineWidth: 1)
        )
    }

    private var topLeftControls: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.black.opacity(0.7))
                    .padding(12)
                    .background(.white.opacity(0.55), in: Capsule())
            }
            .buttonStyle(.plain)

            Button {
                showHarvestShare = true
            } label: {
                HStack(spacing: 8) {
                    Text("🍅")
                    Text("分享收获")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.95), in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.34), lineWidth: 1))
                .shadow(color: .black.opacity(0.24), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
        }
    }


    private func careButton(_ icon: String, _ title: String, completed: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(icon).font(.title3)
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: completed ? "checkmark.circle.fill" : "chevron.right")
            }
            .foregroundStyle(completed ? .green : .primary)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(completed)
    }

    private func finishIfNeeded() {
        guard isHealthy else { return }
        withAnimation(.easeInOut(duration: 1)) {
            plantState = .healthy
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.8)) {
            showCompletion = true
        }
    }

    private func removeBug() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            bugOffset = 180
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation {
                hasRemovedBug = true
                plantState = .recovering
            }
            finishIfNeeded()
        }
    }

    private func waterPlant() {
        withAnimation(.easeInOut(duration: 0.55)) {
            showWaterDrops = true
            plantState = .recovering
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation {
                hasWatered = true
                showWaterDrops = false
            }
            finishIfNeeded()
        }
    }

    private func trimPlant() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showScissors = true
            plantState = .recovering
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation {
                hasTrimmed = true
                showScissors = false
            }
            finishIfNeeded()
        }
    }
}

#Preview {
    PlantingView()
}
