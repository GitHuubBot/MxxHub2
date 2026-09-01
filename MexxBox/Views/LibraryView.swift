import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: GameStore
    @State private var showingAddGame = false

    private let columns = [
        GridItem(.adaptive(minimum: 155, maximum: 230), spacing: 18)
    ]

    var body: some View {
        TabView {
            NavigationStack {
                Group {
                    if store.games.isEmpty {
                        ContentUnavailableView {
                            Label("No Games Yet", systemImage: "gamecontroller")
                        } description: {
                            Text("Add a Windows game folder. MexxBox will find its .exe files and add the game to your library.")
                        } actions: {
                            Button("Add Game") { showingAddGame = true }
                                .buttonStyle(.borderedProminent)
                        }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(store.games) { game in
                                    NavigationLink {
                                        GameDetailView(game: game)
                                    } label: {
                                        GameCard(game: game)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .navigationTitle("My Games")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showingAddGame = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddGame) {
                    AddGameView().environmentObject(store)
                }
            }
            .tabItem { Label("Library", systemImage: "square.grid.2x2.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.green)
    }
}
