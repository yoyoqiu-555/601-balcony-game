//
//  ContentView.swift
//  601号阳台 游戏
//
//  Created by student07 on 2026/5/23.
//

import SwiftUI

struct ContentView: View {
    @State private var showHideGame = false

    var body: some View {
        BalconySceneView()
            .overlay(alignment: .topLeading) {
                Button {
                    showHideGame = true
                } label: {
                    Label("躲藏", systemImage: "eye.slash.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.28), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.22), lineWidth: 1)
                        )
                }
                .padding(.top, 18)
                .padding(.leading, 16)
            }
            .fullScreenCover(isPresented: $showHideGame) {
                BalconyGameView()
                    .overlay(alignment: .topTrailing) {
                        Button {
                            showHideGame = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white.opacity(0.92))
                                .padding(12)
                        }
                        .accessibilityLabel(Text("关闭"))
                    }
            }
    }
}

struct BalconySceneView: View {
    @State private var showPlantingMode = false
    @State private var showTomatoMenu = false
    @State private var showPlantingView = false

    private var backgroundImageName: String {
        showPlantingMode ? "阳台近景" : "阳台远景"
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                balconyBackground

                VStack(spacing: 0) {
                    HStack {
                        Spacer()

                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                                showPlantingMode.toggle()
                                showTomatoMenu = false
                            }
                        } label: {
                            Label(showPlantingMode ? "远景模式" : "近景模式", systemImage: "arrow.triangle.2.circlepath")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(.black.opacity(0.28), in: Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(.white.opacity(0.22), lineWidth: 1)
                                )
                        }
                        .padding(.top, 18)
                        .padding(.trailing, 16)
                    }

                    Spacer()

                    HStack {
                        Spacer()

                        Button {
                            showPlantingView = true
                        } label: {
                            TomatoButtonShape()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red.opacity(0.95), Color.red.opacity(0.72), Color.orange.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(TomatoButtonShape().stroke(.white.opacity(0.25), lineWidth: 1.5))
                                .overlay(
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.green.opacity(0.9))
                                        .offset(y: -6)
                                )
                                .frame(width: 64, height: 64)
                                .shadow(color: .black.opacity(0.22), radius: 10, x: 0, y: 6)
                        }
                        .padding(.trailing, max(22, size.width * 0.10))
                        .padding(.bottom, max(28, size.height * 0.08))
                    }
                }
                .padding(.bottom, 2)

                if showTomatoMenu {
                    Color.black.opacity(0.14)
                        .ignoresSafeArea()
                        .onTapGesture { showTomatoMenu = false }

                    VStack {
                        Spacer()

                        HStack {
                            Spacer()

                            VStack(spacing: 10) {
                                MenuActionButton(title: "食用", systemImage: "fork.knife") {
                                    showTomatoMenu = false
                                }
                                MenuActionButton(title: "分享", systemImage: "square.and.arrow.up") {
                                    showTomatoMenu = false
                                }
                            }
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(.white.opacity(0.18), lineWidth: 1)
                            )
                            .padding(.trailing, max(18, size.width * 0.07))
                            .padding(.bottom, max(96, size.height * 0.18))
                        }
                    }
                }

                if showPlantingMode {
                    VStack {
                        Spacer()

                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.thinMaterial)
                            .overlay(alignment: .leading) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("已切换到近景 / 种植模式")
                                        .font(.headline)
                                    Text("这里可以进入更细的浇水、施肥、收获和交互操作界面。")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(18)
                            }
                            .frame(width: min(size.width * 0.62, 420), height: 110)
                            .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.84), value: showPlantingMode)
            .animation(.spring(response: 0.28, dampingFraction: 0.84), value: showTomatoMenu)
            .fullScreenCover(isPresented: $showPlantingView) {
                PlantingView()
            }
        }
    }

    private var balconyBackground: some View {
        ZStack {
            Image(backgroundImageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.18),
                            Color.black.opacity(0.08),
                            Color.black.opacity(0.28)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 0)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.16))
                    .frame(height: 20)
                    .blur(radius: 12)
                    .padding(.bottom, 90)
            }
            .ignoresSafeArea()
        }
    }
}

struct TomatoButtonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radiusX = rect.width * 0.42
        let radiusY = rect.height * 0.37
        path.addEllipse(in: CGRect(x: center.x - radiusX, y: center.y - radiusY, width: radiusX * 2, height: radiusY * 2))
        return path
    }
}

struct MenuActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 116, height: 42)
                .background(Color.white.opacity(0.92), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
