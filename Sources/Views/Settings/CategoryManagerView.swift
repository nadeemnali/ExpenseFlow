import SwiftUI

struct CategoryManagerView: View {
    @EnvironmentObject private var customCategoryStore: CustomCategoryStore
    @State private var newCategoryName: String = ""
    @State private var selectedColorHex: String = CustomCategoryStore.palette.first ?? "#FF6F59"

    var body: some View {
        BackgroundView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Category name", text: $newCategoryName)
                            .textInputAutocapitalization(.words)
                            .padding(10)
                            .background(AppTheme.cloud.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(CustomCategoryStore.palette, id: \.self) { hex in
                                    let color = Color(hex: hex)
                                    Circle()
                                        .fill(color)
                                        .frame(width: 26, height: 26)
                                        .overlay(
                                            Circle()
                                                .stroke(hex == selectedColorHex ? Color.white : Color.clear, lineWidth: 2)
                                        )
                                        .onTapGesture {
                                            selectedColorHex = hex
                                        }
                                }
                            }
                        }

                        Button("Add category") {
                            addCategory()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("New Category")
                }

                Section {
                    if customCategoryStore.categories.isEmpty {
                        Text("No custom categories yet.")
                            .font(AppTheme.body(12))
                            .foregroundStyle(AppTheme.ink.opacity(0.6))
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(customCategoryStore.categories) { category in
                            HStack {
                                Circle()
                                    .fill(Color(hex: category.colorHex))
                                    .frame(width: 12, height: 12)
                                Text(category.name)
                                    .font(AppTheme.body(14))
                                    .foregroundStyle(AppTheme.ink)
                            }
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteCategories)
                    }
                } header: {
                    Text("Your Categories")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .tabBarPadding()
        }
        .navigationTitle("Custom Categories")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addCategory() {
        customCategoryStore.add(name: newCategoryName, colorHex: selectedColorHex)
        newCategoryName = ""
    }

    private func deleteCategories(at offsets: IndexSet) {
        offsets.map { customCategoryStore.categories[$0] }.forEach(customCategoryStore.delete)
    }
}

#Preview {
    CategoryManagerView()
        .environmentObject(CustomCategoryStore())
}
