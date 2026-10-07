import SwiftUI
import WidgetKit

private let widgetGroupId = "group.com.yetzira.syncmonth"
private let spendURL = URL(string: "syncmonth://quicklog/spend?homeWidget")!

/// SyncMonth palette; the second value is the dark-appearance variant.
private func syncColor(_ light: UInt32, _ dark: UInt32) -> Color {
  func ui(_ hex: UInt32) -> UIColor {
    UIColor(
      red: CGFloat((hex >> 16) & 0xFF) / 255,
      green: CGFloat((hex >> 8) & 0xFF) / 255,
      blue: CGFloat(hex & 0xFF) / 255,
      alpha: 1
    )
  }
  return Color(UIColor { traits in
    traits.userInterfaceStyle == .dark ? ui(dark) : ui(light)
  })
}

private let colorText = syncColor(0x1C2A24, 0xE8EEE9)
private let colorMuted = syncColor(0x5A6B63, 0xA2B2AA)
private let colorPrimary = syncColor(0x3D7A5F, 0x6DB592)
private let colorOnPrimary = syncColor(0xFFFFFF, 0x0E1F17)
private let colorOverspend = syncColor(0xE07A5F, 0xF2957D)
private let colorSurface = syncColor(0xF7F4EF, 0x141A17)
private let colorStat = syncColor(0xE8F0EB, 0x1E2A24)

struct QuickLogEntry: TimelineEntry {
  let date: Date
  let title: String
  let status: String
  let ready: Bool
  let heroLabel: String
  let heroAmount: String
  let heroAmountCompact: String
  let heroIsOver: Bool
  let incomeLabel: String
  let incomeAmount: String
  let spentLabel: String
  let spentAmount: String
  let savedLabel: String
  let savedAmount: String
  let budgetLabel: String
  let budgetAmount: String
  let actionLabel: String
  let actionLabelShort: String
  let layoutRtl: Bool

  static func fromDefaults() -> QuickLogEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    return QuickLogEntry(
      date: Date(),
      title: data?.string(forKey: "title") ?? "SyncMonth",
      status: data?.string(forKey: "status") ?? "Open SyncMonth to refresh",
      ready: data?.string(forKey: "ready") == "1",
      heroLabel: data?.string(forKey: "heroLabel") ?? "Remaining",
      heroAmount: data?.string(forKey: "heroAmount") ?? "—",
      heroAmountCompact: data?.string(forKey: "heroAmountCompact")
        ?? data?.string(forKey: "heroAmount") ?? "—",
      heroIsOver: data?.string(forKey: "heroIsOver") == "1",
      incomeLabel: data?.string(forKey: "incomeLabel") ?? "Income",
      incomeAmount: data?.string(forKey: "incomeAmount") ?? "—",
      spentLabel: data?.string(forKey: "spentLabel") ?? "Spent",
      spentAmount: data?.string(forKey: "spentAmount") ?? "—",
      savedLabel: data?.string(forKey: "savedLabel") ?? "Saved",
      savedAmount: data?.string(forKey: "savedAmount") ?? "—",
      budgetLabel: data?.string(forKey: "budgetLabel") ?? "Budget",
      budgetAmount: data?.string(forKey: "budgetAmount") ?? "—",
      actionLabel: data?.string(forKey: "actionLabel") ?? "Log spend",
      actionLabelShort: data?.string(forKey: "actionLabelShort") ?? "+",
      layoutRtl: data?.string(forKey: "layoutRtl") == "1"
    )
  }
}

struct QuickLogProvider: TimelineProvider {
  func placeholder(in context: Context) -> QuickLogEntry {
    QuickLogEntry.fromDefaults()
  }

  func getSnapshot(in context: Context, completion: @escaping (QuickLogEntry) -> Void) {
    completion(QuickLogEntry.fromDefaults())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLogEntry>) -> Void) {
    let entry = QuickLogEntry.fromDefaults()
    completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60))))
  }
}

private struct LogSpendButton: View {
  let title: String

  var body: some View {
    Text(title)
      .font(.system(size: 12, weight: .bold))
      .foregroundColor(colorOnPrimary)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 6)
      .background(colorPrimary)
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
  }
}

private struct StatTile: View {
  let label: String
  let amount: String
  let alignment: HorizontalAlignment

  var body: some View {
    VStack(alignment: alignment, spacing: 2) {
      Text(label)
        .font(.system(size: 10, weight: .regular))
        .foregroundColor(colorMuted)
        .lineLimit(1)
      Text(amount)
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(colorText)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
    .frame(maxWidth: .infinity, alignment: alignment == .trailing ? .trailing : .leading)
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .background(colorStat)
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
  }
}

struct CompactWidgetView: View {
  var entry: QuickLogEntry

  var body: some View {
    let align: HorizontalAlignment = .leading
    Group {
      if entry.ready {
        VStack(alignment: align, spacing: 4) {
          Text(entry.heroLabel)
            .font(.system(size: 9, weight: .regular))
            .foregroundColor(colorMuted)
            .lineLimit(1)
          Text(entry.heroAmountCompact)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(entry.heroIsOver ? colorOverspend : colorPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
          Spacer(minLength: 0)
          LogSpendButton(title: entry.actionLabelShort)
        }
      } else {
        VStack(alignment: align, spacing: 6) {
          Text(entry.status)
            .font(.system(size: 10))
            .foregroundColor(colorMuted)
            .lineLimit(3)
          Spacer(minLength: 0)
          LogSpendButton(title: entry.actionLabelShort)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .environment(\.layoutDirection, entry.layoutRtl ? .rightToLeft : .leftToRight)
    .widgetURL(spendURL)
    .modifier(WidgetSurface())
  }
}

struct ExtendedWidgetView: View {
  var entry: QuickLogEntry

  var body: some View {
    let align: HorizontalAlignment = .leading
    Group {
      if entry.ready {
        VStack(alignment: align, spacing: 5) {
          Text(entry.title)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(colorText)
            .lineLimit(1)
          Text(entry.heroLabel)
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(colorMuted)
            .lineLimit(1)
          Text(entry.heroAmount)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(entry.heroIsOver ? colorOverspend : colorPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
          VStack(spacing: 5) {
            HStack(spacing: 5) {
              StatTile(label: entry.incomeLabel, amount: entry.incomeAmount, alignment: align)
              StatTile(label: entry.spentLabel, amount: entry.spentAmount, alignment: align)
            }
            HStack(spacing: 5) {
              StatTile(label: entry.savedLabel, amount: entry.savedAmount, alignment: align)
              StatTile(label: entry.budgetLabel, amount: entry.budgetAmount, alignment: align)
            }
          }
          LogSpendButton(title: entry.actionLabel)
        }
      } else {
        VStack(alignment: align, spacing: 8) {
          Text(entry.title)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(colorText)
          Text(entry.status)
            .font(.system(size: 12))
            .foregroundColor(colorMuted)
          Spacer(minLength: 0)
          LogSpendButton(title: entry.actionLabel)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .environment(\.layoutDirection, entry.layoutRtl ? .rightToLeft : .leftToRight)
    .widgetURL(spendURL)
    .modifier(WidgetSurface())
  }
}

private struct WidgetSurface: ViewModifier {
  func body(content: Content) -> some View {
    Group {
      if #available(iOSApplicationExtension 17.0, *) {
        content.containerBackground(for: .widget) { colorSurface }
      } else {
        content
          .padding(8)
          .background(colorSurface)
      }
    }
  }
}

struct QuickLogCompactWidget: Widget {
  let kind: String = "QuickLogCompactWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: QuickLogProvider()) { entry in
      CompactWidgetView(entry: entry)
    }
    .configurationDisplayName("Log spend")
    .description("Remaining balance and quick spend logging")
    .supportedFamilies([.systemSmall])
  }
}

struct QuickLogExtendedWidget: Widget {
  let kind: String = "QuickLogExtendedWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: QuickLogProvider()) { entry in
      ExtendedWidgetView(entry: entry)
    }
    .configurationDisplayName("Month overview")
    .description("Month remaining, income, spent, and quick spend logging")
    .supportedFamilies([.systemMedium])
  }
}

@main
struct QuickLogWidgetBundle: WidgetBundle {
  var body: some Widget {
    QuickLogCompactWidget()
    QuickLogExtendedWidget()
  }
}
