//
//  NutritionBarcode.swift
//  Wellness App
//
//  Barcode scanning for food labels. The camera scanner reads a product barcode,
//  which is looked up in the free Open Food Facts database to fill in the food's
//  name and nutrition. Only the barcode is sent; no personal data leaves the app,
//  and the user always confirms the values before adding.
//

import SwiftUI
import VisionKit

// MARK: - Result

struct ScannedFood {
    var name: String
    var calories: Int
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    /// True when only per-100g data was available (no per-serving values).
    var per100g: Bool
}

// MARK: - Lookup

enum FoodDatabase {
    /// Look up a barcode in Open Food Facts. Returns nil when the product is not
    /// found or has no usable nutrition. Throws only on network/transport errors.
    static func lookup(barcode: String) async throws -> ScannedFood? {
        let code = barcode.filter(\.isNumber)
        guard code.count >= 6 else { return nil }

        var components = URLComponents(string: "https://world.openfoodfacts.org/api/v2/product/\(code).json")!
        components.queryItems = [
            URLQueryItem(name: "fields", value: "product_name,brands,nutriments")
        ]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("PlatoWellness/1.0 (iOS wellness app)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

        let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)
        guard decoded.status == 1, let product = decoded.product else { return nil }
        return product.scannedFood()
    }
}

// MARK: - Open Food Facts response

private struct OFFResponse: Decodable {
    let status: Int
    let product: OFFProduct?
}

private struct OFFProduct: Decodable {
    let product_name: String?
    let brands: String?
    let nutriments: OFFNutriments?

    func scannedFood() -> ScannedFood? {
        guard let n = nutriments else { return nil }
        let hasServing = n.energyKcalServing != nil
        guard let cal = n.energyKcalServing ?? n.energyKcal100g else { return nil }

        let candidates = [product_name, brands].compactMap { $0 }.filter { !$0.isEmpty }
        let name = candidates.first ?? "Scanned food"

        return ScannedFood(
            name: name,
            calories: Int(cal.rounded()),
            proteinG: max(0, n.proteinsServing ?? n.proteins100g ?? 0),
            carbsG: max(0, n.carbsServing ?? n.carbs100g ?? 0),
            fatG: max(0, n.fatServing ?? n.fat100g ?? 0),
            per100g: !hasServing
        )
    }
}

private struct OFFNutriments: Decodable {
    let energyKcalServing: Double?
    let energyKcal100g: Double?
    let proteinsServing: Double?
    let proteins100g: Double?
    let carbsServing: Double?
    let carbs100g: Double?
    let fatServing: Double?
    let fat100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcalServing = "energy-kcal_serving"
        case energyKcal100g = "energy-kcal_100g"
        case proteinsServing = "proteins_serving"
        case proteins100g = "proteins_100g"
        case carbsServing = "carbohydrates_serving"
        case carbs100g = "carbohydrates_100g"
        case fatServing = "fat_serving"
        case fat100g = "fat_100g"
    }
}

// MARK: - Camera scanner

/// A full-screen barcode scanner presented as a sheet. Reports the first
/// recognized barcode, then leaves it to the caller to dismiss.
struct BarcodeScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onScan: (String) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if BarcodeScannerView.isAvailable {
                    BarcodeScannerView { code in
                        onScan(code)
                    }
                    .ignoresSafeArea(edges: .bottom)
                } else {
                    ContentUnavailableView {
                        Label("Scanning unavailable", systemImage: "barcode.viewfinder")
                    } description: {
                        Text("This device cannot scan barcodes. Enter the number manually instead.")
                    }
                }
            }
            .navigationTitle("Scan barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

/// VisionKit data scanner limited to product barcodes.
struct BarcodeScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void

    static var isAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        try? controller.startScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScan: (String) -> Void
        private var didScan = false

        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            guard !didScan else { return }
            for item in addedItems {
                if case let .barcode(barcode) = item, let value = barcode.payloadStringValue {
                    didScan = true
                    dataScanner.stopScanning()
                    onScan(value)
                    return
                }
            }
        }
    }
}
