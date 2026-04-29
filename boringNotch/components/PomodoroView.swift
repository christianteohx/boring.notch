//
//  PomodoroView.swift
//  boringNotch
//
//  Created by Claw on 2026-04-28.
//

import Defaults
import SwiftUI

struct PomodoroView: View {
    @ObservedObject var pomodoroManager = PomodoroManager.shared
    @EnvironmentObject var vm: BoringViewModel
    @State private var showSettings = false

    // Local copies bound to steippers
    @State private var workMins: Int = Defaults[.pomodoroWorkDuration]
    @State private var shortMins: Int = Defaults[.pomodoroShortBreakDuration]
    @State private var longMins: Int = Defaults[.pomodoroLongBreakDuration]
    @State private var sessions: Int = Defaults[.pomodoroSessionsBeforeLongBreak]

    var body: some View {
        VStack(spacing: 0) {
            if !showSettings {
                mainContent
            } else {
                settingsContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color.clear)
    }

    // MARK: - Main Timer View

    private var mainContent: some View {
        VStack(spacing: 6) {
            // Phase indicator + sessions + gear
            HStack(spacing: 8) {
                ForEach([PomodoroManager.PomodoroPhase.work, .shortBreak, .longBreak], id: \.self) { phase in
                    Text(phase.rawValue)
                        .font(.system(size: 9))
                        .foregroundColor(pomodoroManager.currentPhase == phase ? .white : .gray)
                }
                Text("• \(pomodoroManager.sessionsCompleted)")
                    .font(.system(size: 9))
                    .foregroundStyle(.gray)

                Spacer()

                Button(action: {
                    workMins = Defaults[.pomodoroWorkDuration]
                    shortMins = Defaults[.pomodoroShortBreakDuration]
                    longMins = Defaults[.pomodoroLongBreakDuration]
                    sessions = Defaults[.pomodoroSessionsBeforeLongBreak]
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSettings.toggle()
                    }
                }) {
                    Text("⚙️")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Circular progress + time
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: pomodoroManager.progress)
                    .stroke(
                        phaseColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: pomodoroManager.progress)

                VStack(spacing: 4) {
                    Text(pomodoroManager.currentPhase.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.gray)

                    Text(pomodoroManager.formattedTime)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 90, height: 90)

            // Controls
            HStack(spacing: 20) {
                Button(action: { pomodoroManager.stop() }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    if pomodoroManager.isRunning {
                        pomodoroManager.pause()
                    } else {
                        pomodoroManager.start()
                    }
                }) {
                    Image(systemName: pomodoroManager.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { pomodoroManager.skip() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(10)
    }

    // MARK: - Settings Panel

    private var settingsContent: some View {
        VStack(spacing: 8) {
            // Header with back button
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSettings.toggle()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.gray)
                }
                .buttonStyle(PlainButtonStyle())

                Text("Pomodoro Settings")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }

            // Duration rows
            VStack(spacing: 6) {
                settingRow(label: "Work", value: $workMins, range: 1...90)
                settingRow(label: "Short Break", value: $shortMins, range: 1...30)
                settingRow(label: "Long Break", value: $longMins, range: 1...60)
                settingRow(label: "Sessions", value: $sessions, range: 1...10)
            }
        }
        .padding(10)
    }

    // MARK: - Setting Row

    private func settingRow(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.gray)
                .frame(width: 70, alignment: .leading)

            Spacer()

            HStack(spacing: 6) {
                Button(action: { value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.gray)
                        .frame(width: 20, height: 20)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())

                Text("\(value.wrappedValue)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .frame(minWidth: 20)

                Button(action: { value.wrappedValue = min(range.upperBound, value.wrappedValue + 1) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.gray)
                        .frame(width: 20, height: 20)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .onChange(of: value.wrappedValue) { newValue in
            saveSetting(for: label, value: newValue)
        }
    }

    private func saveSetting(for label: String, value: Int) {
        switch label {
        case "Work":
            Defaults[.pomodoroWorkDuration] = value
        case "Short Break":
            Defaults[.pomodoroShortBreakDuration] = value
        case "Long Break":
            Defaults[.pomodoroLongBreakDuration] = value
        case "Sessions":
            Defaults[.pomodoroSessionsBeforeLongBreak] = value
        default:
            break
        }
    }

    // MARK: - Helpers

    private var phaseColor: Color {
        switch pomodoroManager.currentPhase {
        case .work: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }
}
