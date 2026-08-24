//
//  LifeAreaDetailComponents.swift
//  ADHD LifeOS
//
//  The v3 area screen's section builders and rows, split from `LifeAreaDetailView.swift` for
//  its length budgets — same screen, same identity-hue language.
//

import SwiftUI

extension LifeAreaDetailView {
    // MARK: - Header

    /// The identity wash: emoji, name, the honest status line, and the avatar rail — every
    /// active area one tap away, the current one solid in its own hue.
    var washHeader: some View {
        let momentum = areaMomentum
        let status = MomentumScoreboard.areaStatusLine(
            closedThisWeek: momentum.closedThisWeek,
            open: momentum.open,
            lastClosedAt: momentum.lastClosedAt
        )
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Text(lifeArea.colour)
                    .font(.system(size: 40))
                VStack(alignment: .leading, spacing: 2) {
                    Text(lifeArea.name)
                        .font(.title.bold())
                        .tracking(-0.5)
                        .minimumScaleFactor(0.8)
                    Text(status.text)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(family.color)
                }
            }
            if allAreas.count > 1 {
                rail
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(family.tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityIdentifier("lifeAreaDetailHeader")
    }

    private var rail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(allAreas) { area in
                    if area.id == lifeArea.id {
                        railWell(for: area, isCurrent: true)
                    } else {
                        NavigationLink(value: area) {
                            railWell(for: area, isCurrent: false)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(area.name)
                    }
                }
            }
        }
    }

    private func railWell(for area: LifeArea, isCurrent: Bool) -> some View {
        let wellFamily = AreaPalette.family(for: area)
        return Text(area.colour)
            .font(.title3)
            .frame(width: 46, height: 46)
            .background(
                isCurrent ? AnyShapeStyle(wellFamily.vivid) : AnyShapeStyle(Color.cardSurface),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isCurrent ? Color.clear : Color.cardBorder,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isCurrent ? wellFamily.vivid.opacity(0.35) : .clear,
                radius: 6, x: 0, y: 2
            )
    }

    // MARK: - Filter

    var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(for: .tasks, count: service.allTasks.count)
                chip(for: .journal, count: service.logs.count)
                chip(for: .captures, count: splitCaptures.filedHere.count)
                chip(for: .all, count: 0)
            }
        }
        .accessibilityIdentifier("lifeAreaDetailFilterChips")
    }

    private func chip(for option: AreaDetailFilter, count: Int) -> some View {
        let selected = filter == option
        return Button {
            filter = option
        } label: {
            Text(option.title(count: count))
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(selected ? family.onColor : Color("LabelSecondary"))
                .padding(.horizontal, 16)
                .frame(minHeight: 36)
                .background(
                    selected ? AnyShapeStyle(family.vivid) : AnyShapeStyle(Color("CardSurfaceSecondary")),
                    in: Capsule()
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tasks

    var tasksSection: some View {
        let nextOpenId = service.allTasks.first { $0.status != .done }?.id
        return VStack(spacing: 0) {
            if service.allTasks.isEmpty {
                Text("No tasks here yet")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("lifeAreaDetailTasksEmptyState")
            }
            ForEach(Array(service.allTasks.enumerated()), id: \.element.id) { index, task in
                AreaTaskRow(
                    task: task,
                    family: family,
                    isNextOpen: task.id == nextOpenId,
                    isToggling: togglingTaskId == task.id,
                    onTick: { toggleTask(task) }
                )
                if index != service.allTasks.indices.last {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Momentum

    var areaMomentum: MomentumScoreboard.AreaMomentum {
        let closed = MomentumScoreboard.closedThisWeek(tasks: service.allTasks).count
        let open = service.allTasks.filter { $0.status != .done }.count
        let lastClosed = service.allTasks
            .filter { $0.status == .done }
            .compactMap(\.completedAt)
            .max()
        return MomentumScoreboard.AreaMomentum(
            area: lifeArea, closedThisWeek: closed, open: open, lastClosedAt: lastClosed
        )
    }

    @ViewBuilder
    var momentumSection: some View {
        let momentum = areaMomentum
        VStack(alignment: .leading, spacing: 8) {
            Text("Momentum in this area")
                .sectionLabel()
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 16) {
                    ClosureRing(
                        progress: momentum.rate ?? 0,
                        size: 56,
                        lineWidth: 5,
                        arcStyle: AnyShapeStyle(family.vivid)
                    ) {
                        Text(lifeArea.colour)
                            .font(.title3)
                    }
                    Text(AreaDetailPresentation.ringLine(rate: momentum.rate, areaName: lifeArea.name))
                        .font(.callout.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if momentumPreferences.showCharts {
                    let counts = MomentumWeekCharts.closedPerDay(tasks: service.allTasks)
                    if counts.contains(where: { $0 > 0 }) {
                        WeekBarStrip(
                            fractions: MomentumWeekCharts.barFractions(counts),
                            barColor: family.vivid
                        )
                    }
                }
            }
            .bentoCard()
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("lifeAreaDetailMomentum")
    }

    // MARK: - Journal

    @ViewBuilder
    var journalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Journal")
                .sectionLabel()
                .foregroundStyle(.secondary)
            if service.logs.isEmpty {
                Text("No journal entries for this area")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("lifeAreaDetailLogsEmptyState")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(service.logs) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.entryDate.formatted(date: .abbreviated, time: .shortened))
                                .sectionLabel()
                                .foregroundStyle(.secondary)
                            Text(log.body)
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .bentoCard()
                    }
                }
            }
        }
    }

    // MARK: - Captures

    var splitCaptures: (filedHere: [Capture], unfiled: [Capture]) {
        AreaDetailPresentation.splitCaptures(service.captures, areaId: lifeArea.id)
    }

    @ViewBuilder
    var capturesSection: some View {
        let split = splitCaptures
        if !split.filedHere.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Waiting here")
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                captureCard(split.filedHere, action: nil)
            }
        }
        if !split.unfiled.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Waiting to be filed here")
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                captureCard(split.unfiled) { capture in
                    fileCaptureHere(capture)
                }
            }
        }
    }

    private func captureCard(_ captures: [Capture], action: ((Capture) -> Void)?) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(captures.enumerated()), id: \.element.id) { index, capture in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(capture.title ?? capture.content)
                            .font(.callout)
                            .lineLimit(2)
                        Text(capture.kind.rawValue)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if let action {
                        Button("File here") {
                            action(capture)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(family.color)
                        .padding(.horizontal, 8)
                        .frame(minHeight: 32)
                        .background(family.tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .accessibilityIdentifier("lifeAreaDetailFileHere-\(capture.id)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minHeight: 56)
                if index != captures.indices.last {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Add

    var addSection: some View {
        VStack(spacing: 8) {
            Button {
                isPresentingAdd = true
            } label: {
                Label("Add to \(lifeArea.name)", systemImage: "plus")
            }
            .buttonStyle(MomentumSolidButtonStyle(fill: family.vivid, foreground: family.onColor))
            .accessibilityIdentifier("lifeAreaDetailAddButton")
            Text("Whatever you add here is already filed in this area.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
    }
}
