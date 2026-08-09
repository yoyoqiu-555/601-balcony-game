//
//  ContentView.swift
//  601号阳台 游戏
//
//  Created by student07 on 2026/5/23.
//

import SwiftUI

struct ContentView: View {
    @State private var showHideGame = false
    @State private var showPlantingView = false

    var body: some View {
        BalconySceneView()
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 10) {
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

                    Button {
                        showPlantingView = true
                    } label: {
                        Label("植物养护", systemImage: "leaf.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.green.opacity(0.55), in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.24), lineWidth: 1)
                            )
                    }
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
            .fullScreenCover(isPresented: $showPlantingView) {
                PlantingView()
            }
    }
}

struct BalconySceneView: View {
    @State private var showPlantingMode = false

    private var backgroundImageName: String {
        showPlantingMode ? "半枯萎状态" : "阳台远景"
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
                }
                .padding(.bottom, 2)

                if showPlantingMode {
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)

                        VStack(spacing: 0) {
                            Spacer(minLength: 0)

                            Text("")
                                .frame(width: 1, height: 1)
                                .hidden()
                        }
                        .frame(width: max(1, size.width * 0.72), height: size.height)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("辅助工具栏")
                                .font(.headline)
                                .foregroundStyle(.primary.opacity(0.8))

                            VStack(spacing: 12) {
                                ToolButton(title: "🐛 除虫") { }
                                ToolButton(title: "💧 浇水") { }
                                ToolButton(title: "✂️ 修剪枝叶") { }
                            }

                            Spacer()
                        }
                        .padding(16)
                        .frame(width: max(210, size.width * 0.28), height: size.height)
                        .background(.white.opacity(0.22), in: Rectangle())
                    }
                    .ignoresSafeArea()
                    .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.84), value: showPlantingMode)
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

struct ToolButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Color.white.opacity(0.92), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
