//
//  ProfileBodyDataView.swift
//  Wellness App
//
//  Body data and progress: weight trend, measurements over time, body fat, and
//  a private progress-photo gallery placeholder. Weight and measurement logging
//  are presented as sheets.
//

import SwiftUI
import Charts
import PhotosUI

struct ProfileBodyDataView: View {
    @Environment(UserStore.self) private var user

    @State private var metric: ProfileBodyMetric = .waist
    @State private var showLogWeight = false
    @State private var showLogMeasurement = false

    private var system: UnitSystem { user.profile?.unitSystem ?? .metric }

    var body: some View {
        List {
            weightSection
            measurementSection
            if hasBodyFat { bodyFatSection }
            latestSection
            historySection
            photosSection
        }
        .navigationTitle("Body data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showLogWeight = true
                    } label: {
                        Label("Log weight", systemImage: "scalemass")
                    }
                    Button {
                        showLogMeasurement = true
                    } label: {
                        Label("Log measurement", systemImage: "ruler")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showLogWeight) {
            ProfileLogWeightView()
        }
        .sheet(isPresented: $showLogMeasurement) {
            ProfileLogMeasurementView()
        }
    }

    // MARK: - Weight trend

    private var weightSection: some View {
        Section("Weight trend") {
            let series = user.weightSeries
            if series.count < 2 {
                ProfileEmptyState(
                    systemImage: "scalemass",
                    title: "Not enough weigh-ins yet",
                    message: "Log your weight a few times to see your trend line here."
                )
            } else {
                let points = series.map {
                    ProfileTrendPoint(date: $0.date,
                                      value: ProfileFormat.weightDisplayValue(kg: $0.weightKg, system: system))
                }
                Chart(points) { point in
                    LineMark(x: .value("Date", point.date),
                             y: .value("Weight", point.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.accent)
                    AreaMark(x: .value("Date", point.date),
                             y: .value("Weight", point.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.accent.opacity(0.12))
                    PointMark(x: .value("Date", point.date),
                              y: .value("Weight", point.value))
                        .foregroundStyle(Theme.accent)
                        .accessibilityLabel(point.date.formatted(.dateTime.month().day().year()))
                        .accessibilityValue(String(format: "%.1f %@", point.value, ProfileFormat.weightUnitLabel(system)))
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 200)
                .accessibilityLabel("Weight trend")
                .accessibilityValue(weightTrendSummary(points))

                if let target = targetWeightText {
                    Text(target)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func weightTrendSummary(_ points: [ProfileTrendPoint]) -> String {
        guard let first = points.first, let last = points.last else { return "No data" }
        let unit = ProfileFormat.weightUnitLabel(system)
        let delta = last.value - first.value
        let direction = delta > 0 ? "up" : (delta < 0 ? "down" : "unchanged")
        return String(format: "From %.1f to %.1f %@, %@ %.1f over %d entries.",
                      first.value, last.value, unit, direction, abs(delta), points.count)
    }

    private var targetWeightText: String? {
        guard let target = user.profile?.targetWeightKg else { return nil }
        return "Target " + Units.displayWeight(kg: target, system: system)
    }

    // MARK: - Measurement trend

    private var measurementSection: some View {
        Section("Measurements over time") {
            Picker("Measurement", selection: $metric) {
                ForEach(ProfileBodyMetric.lengthMetrics) { m in
                    Text(m.label).tag(m)
                }
            }
            .pickerStyle(.menu)

            let points = measurementPoints(for: metric)
            if points.count < 2 {
                ProfileEmptyState(
                    systemImage: metric.systemImage,
                    title: "No \(metric.label.lowercased()) history yet",
                    message: "Log this measurement over time to watch it change."
                )
            } else {
                Chart(points) { point in
                    LineMark(x: .value("Date", point.date),
                             y: .value(metric.label, point.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.activity)
                    PointMark(x: .value("Date", point.date),
                              y: .value(metric.label, point.value))
                        .foregroundStyle(Theme.activity)
                        .accessibilityLabel(point.date.formatted(.dateTime.month().day().year()))
                        .accessibilityValue(String(format: "%.1f %@", point.value, metric.unitLabel(system)))
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 180)
                .accessibilityLabel("\(metric.label) over time in \(metric.unitLabel(system))")
                .accessibilityValue(trendSummary(points, unit: metric.unitLabel(system)))
            }
        }
    }

    // MARK: - Body fat

    private var hasBodyFat: Bool {
        user.measurements.contains { $0.bodyFatPercent != nil }
    }

    private var bodyFatSection: some View {
        Section("Body fat") {
            let points = measurementPoints(for: .bodyFat)
            if points.count < 2 {
                ProfileEmptyState(
                    systemImage: "percent",
                    title: "Not enough body-fat data",
                    message: "Add body-fat percent when you log a measurement."
                )
            } else {
                Chart(points) { point in
                    LineMark(x: .value("Date", point.date),
                             y: .value("Body fat", point.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.restore)
                    PointMark(x: .value("Date", point.date),
                              y: .value("Body fat", point.value))
                        .foregroundStyle(Theme.restore)
                        .accessibilityLabel(point.date.formatted(.dateTime.month().day().year()))
                        .accessibilityValue(String(format: "%.1f percent", point.value))
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 160)
                .accessibilityLabel("Body fat percent over time")
                .accessibilityValue(trendSummary(points, unit: "percent"))
            }
        }
    }

    // MARK: - Latest snapshot

    private var latestSection: some View {
        Section("Latest measurement") {
            if let latest = user.measurements.first {
                ForEach(ProfileBodyMetric.allCases) { m in
                    if let value = m.displayValue(from: latest, system: system) {
                        HStack {
                            Label(m.label, systemImage: m.systemImage)
                            Spacer()
                            Text(String(format: "%.1f %@", value, m.unitLabel(system)))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Text("Recorded \(latest.recordedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ProfileEmptyState(
                    systemImage: "ruler",
                    title: "No measurements yet",
                    message: "Tap the plus button to log your first measurement."
                )
            }
        }
    }

    // MARK: - History

    @ViewBuilder private var historySection: some View {
        if user.measurements.count > 1 {
            Section("History") {
                ForEach(user.measurements) { m in
                    HStack {
                        Text(m.recordedAt.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        Text(historySummary(m))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
                .onDelete(perform: deleteMeasurements)
            }
        }
    }

    /// A short one-line description of a measurement for the history rows.
    private func historySummary(_ m: BodyMeasurement) -> String {
        if let kg = m.weightKg {
            let value = ProfileFormat.weightDisplayValue(kg: kg, system: system)
            return ProfileFormat.decimal.format(value) + " " + ProfileFormat.weightUnitLabel(system)
        }
        if let bf = m.bodyFatPercent {
            return String(format: "%.1f%% body fat", bf)
        }
        return "Measurement"
    }

    private func deleteMeasurements(at offsets: IndexSet) {
        let all = user.measurements
        for index in offsets {
            user.removeMeasurement(all[index])
        }
    }

    // MARK: - Progress photos

    private var photosSection: some View {
        Section {
            ProfilePhotoGallery()
        } header: {
            Text("Progress photos")
        } footer: {
            Text("Photos stay on your device for now. Private cloud sync arrives with your account.")
        }
    }

    // MARK: - Helpers

    private func measurementPoints(for metric: ProfileBodyMetric) -> [ProfileTrendPoint] {
        user.measurements
            .compactMap { m in
                metric.displayValue(from: m, system: system).map { ProfileTrendPoint(date: m.recordedAt, value: $0) }
            }
            .sorted { $0.date < $1.date }
    }

    private func trendSummary(_ points: [ProfileTrendPoint], unit: String) -> String {
        guard let first = points.first, let last = points.last else { return "No data" }
        return String(format: "From %.1f to %.1f %@ across %d entries.",
                      first.value, last.value, unit, points.count)
    }
}

// MARK: - Progress photo gallery placeholder

private struct ProfilePhotoGallery: View {
    @Environment(UserStore.self) private var user
    @State private var pickerItem: PhotosPickerItem?
    @State private var isUploading = false

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 12) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.accent.opacity(0.12))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            VStack(spacing: 6) {
                                if isUploading {
                                    ProgressView()
                                } else {
                                    Image(systemName: "plus").font(.title2)
                                    Text("Add").font(.caption)
                                }
                            }
                            .foregroundStyle(Theme.accent)
                        }
                }
                .disabled(isUploading)
                .accessibilityLabel("Add a progress photo")

                ForEach(user.progressPhotos) { photo in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            AsyncImage(url: URL(string: photo.url)) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color(uiColor: .tertiarySystemFill)
                                    .overlay { ProgressView() }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityLabel("Progress photo")
                }
            }

            Text(user.progressPhotos.isEmpty
                 ? "Add photos to track visible progress over time. Your gallery is private."
                 : "Your gallery is private. Nobody else can see these.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            isUploading = true
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await user.uploadPhoto(data)
                }
                pickerItem = nil
                isUploading = false
            }
        }
    }
}

// MARK: - Shared empty state

struct ProfileEmptyState: View {
    var systemImage: String
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

extension ProfileBodyMetric {
    /// Length-based metrics that make sense in the measurement picker.
    static var lengthMetrics: [ProfileBodyMetric] {
        [.waist, .hips, .chest, .arm, .thigh, .neck]
    }
}

/// A single (date, value) sample for a Swift Charts trend line.
struct ProfileTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

#Preview {
    NavigationStack {
        ProfileBodyDataView()
    }
    .withSampleStores()
}
