import SwiftUI

struct TimeEntry: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let duration: TimeInterval
}

struct ContentView: View {
    @State private var timeElapsed: TimeInterval = 0
    @State private var isRunning = false
    @State private var timeEntries: [TimeEntry] = []
    @State private var timer: Timer?
    
    var entriesByDay: [(date: Date, totalDuration: TimeInterval, entries: [TimeEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: timeEntries) { entry -> Date in
            let components = calendar.dateComponents([.year, .month, .day], from: entry.date)
            return calendar.date(from: components)!
        }
        let sortedKeys = grouped.keys.sorted(by: { $0 > $1 })
        return sortedKeys.map { date in
            let entries = grouped[date] ?? []
            let totalDuration = entries.reduce(0) { $0 + $1.duration }
            return (date: date, totalDuration: totalDuration, entries: entries)
        }
    }
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 20) {
                Text(timeString(time: timeElapsed))
                    .font(.system(size: 72, weight: .thin))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                    .padding(.top, 50)
                
                Button(action: {
                    if isRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    Text(isRunning ? "Pause" : "Start")
                        .font(.title2)
                        .frame(minWidth: 140)
                        .padding()
                        .background(isRunning ? Color.red.opacity(0.7) : Color.green.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                
                Divider()
                    .background(Color.white)
                    .padding(.horizontal)
                
                List {
                    ForEach(entriesByDay, id: \.date) { day in
                        Section(header: HStack {
                            Text(formattedDate(date: day.date))
                                .foregroundColor(.white)
                            Spacer()
                            Text(timeString(time: day.totalDuration))
                                .foregroundColor(.white)
                        }) {
                            ForEach(day.entries) { entry in
                                HStack {
                                    Text(formattedTime(date: entry.date))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(timeString(time: entry.duration))
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 5)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
            }
            .padding()
        }
        .onAppear {
            loadEntries()
        }
    }
    
    // MARK: - Timer Functions
    
    func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        saveTimeEntry()
        timeElapsed = 0
    }
    
    // MARK: - Persistence
    
    func saveTimeEntry() {
        guard timeElapsed > 0 else { return }
        let entry = TimeEntry(date: Date(), duration: timeElapsed)
        timeEntries.insert(entry, at: 0)
        saveEntries()
    }
    
    func saveEntries() {
        if let data = try? JSONEncoder().encode(timeEntries) {
            UserDefaults.standard.set(data, forKey: "TimeEntries")
        }
    }
    
    func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: "TimeEntries"),
           let entries = try? JSONDecoder().decode([TimeEntry].self, from: data) {
            timeEntries = entries
        }
    }
    
    // MARK: - Formatting Functions
    
    func timeString(time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: time) ?? "00:00:00"
    }
    
    func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func formattedTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
