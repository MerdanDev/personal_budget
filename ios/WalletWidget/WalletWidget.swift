//
//  WalletWidget.swift
//  WalletWidget
//
//  Home-screen widget: balance / income / expense on top, a large "Add
//  expense" button and a small "+" income button on the bottom. Reads the
//  figures the app writes via `home_widget`, and the buttons deep-link into the
//  app where an amount can be entered.
//

import WidgetKit
import SwiftUI

// App Group shared with the Runner target. Must match the group in both
// targets' entitlements and `WidgetService._appGroupId` on the Dart side.
private let appGroupId = "group.dev.merdan.wallet"

// Deep links the buttons open; routed by WidgetService on the Flutter side.
private let addExpenseURL = URL(string: "wallet://add?type=expense")!
private let addIncomeURL = URL(string: "wallet://add?type=income")!

struct WalletEntry: TimelineEntry {
    let date: Date
    let balance: String
    let income: String
    let expense: String
    let balanceNegative: Bool
    let addExpenseLabel: String
}

struct Provider: TimelineProvider {
    private func load() -> WalletEntry {
        // `home_widget` stores values in the App Group's UserDefaults under the
        // same keys passed to saveWidgetData().
        let defaults = UserDefaults(suiteName: appGroupId)
        return WalletEntry(
            date: Date(),
            balance: defaults?.string(forKey: "balance") ?? "—",
            income: defaults?.string(forKey: "income") ?? "—",
            expense: defaults?.string(forKey: "expense") ?? "—",
            balanceNegative: defaults?.bool(forKey: "balance_negative") ?? false,
            // Localized by the app and written on each sync; fall back until then.
            addExpenseLabel: defaults?.string(forKey: "add_expense") ?? "Add expense"
        )
    }

    func placeholder(in context: Context) -> WalletEntry {
        WalletEntry(
            date: Date(), balance: "—", income: "—", expense: "—",
            balanceNegative: false, addExpenseLabel: "Add expense"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WalletEntry) -> Void) {
        completion(load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WalletEntry>) -> Void) {
        // Single entry; the app reloads this timeline whenever data changes via
        // WidgetCenter, so no scheduled refresh is needed.
        completion(Timeline(entries: [load()], policy: .never))
    }
}

struct WalletWidgetEntryView: View {
    var entry: WalletEntry

    private let expenseColor = Color(red: 0.898, green: 0.224, blue: 0.208)
    private let incomeColor = Color(red: 0.180, green: 0.490, blue: 0.196)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Top: figures
            Text(entry.balance)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(entry.balanceNegative ? expenseColor : incomeColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            HStack(spacing: 12) {
                Label(entry.income, systemImage: "arrow.up")
                    .foregroundColor(incomeColor)
                Label(entry.expense, systemImage: "arrow.down")
                    .foregroundColor(expenseColor)
            }
            .font(.system(size: 13))
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Spacer(minLength: 8)

            // Bottom: large expense button + small income(+) button
            HStack(spacing: 8) {
                Link(destination: addExpenseURL) {
                    HStack(spacing: 6) {
                        Image(systemName: "minus")
                        Text(entry.addExpenseLabel)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundColor(.white)
                    .background(expenseColor)
                    .cornerRadius(12)
                }

                Link(destination: addIncomeURL) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 52, height: 44)
                        .foregroundColor(.white)
                        .background(incomeColor)
                        .cornerRadius(12)
                }
            }
        }
        .padding(14)
        .widgetBackgroundCompat()
    }
}

/// iOS 17+ requires `containerBackground` for widgets; earlier versions ignore
/// it. Keeps the same code building if the deployment target is lowered.
private extension View {
    @ViewBuilder
    func widgetBackgroundCompat() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(.background, for: .widget)
        } else {
            self.background(Color(UIColor.systemBackground))
        }
    }
}

struct WalletWidget: Widget {
    // Must match `WidgetService._iOSWidgetName` on the Dart side.
    let kind: String = "WalletWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WalletWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Balance")
        .description("Your balance with quick add buttons.")
        .supportedFamilies([.systemMedium])
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    WalletWidget()
} timeline: {
    WalletEntry(date: .now, balance: "1 250.00 TMT", income: "2 000.00 TMT", expense: "750.00 TMT", balanceNegative: false, addExpenseLabel: "Add expense")
}
