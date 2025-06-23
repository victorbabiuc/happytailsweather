import SwiftUI

struct ProfileView: View {
    @AppStorage("selectedBreed") private var selectedBreed: DogBreed = .labradorRetriever
    @AppStorage("isPremium") private var isPremium: Bool = false
    @State private var searchText = ""
    @State private var showingNotifications = true
    @State private var useFahrenheit = true
    
    private var filteredBreeds: [DogBreed] {
        if searchText.isEmpty {
            return DogBreed.allCases
        } else {
            return DogBreed.allCases.filter { breed in
                breed.characteristics.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Selected Breed Card
                    selectedBreedCard
                    
                    // Breed Selection Section
                    breedSelectionSection
                    
                    // Settings Section
                    settingsSection
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search breeds...")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Weather Safety for Your Dog")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Select your dog's breed to get personalized weather safety recommendations")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Selected Breed Card
    private var selectedBreedCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Current Selection")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("Selected")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            HStack(spacing: 16) {
                Image(systemName: "dog.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedBreed.characteristics.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Safe: \(Int(selectedBreed.characteristics.safeTemperatureRange.lowerBound))°F - \(Int(selectedBreed.characteristics.safeTemperatureRange.upperBound))°F")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Breed Characteristics")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    characteristicChip("Size", selectedBreed.characteristics.sizeCategory.displayName)
                    characteristicChip("Coat", selectedBreed.characteristics.coatType.displayName)
                    characteristicChip("Heat", selectedBreed.characteristics.heatSensitivity.displayName)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Breed Selection Section
    private var breedSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Your Dog's Breed")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(filteredBreeds, id: \.self) { breed in
                    breedCard(for: breed)
                }
            }
        }
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                settingsRow(
                    icon: "bell.fill",
                    title: "Weather Alerts",
                    subtitle: "Get notified about unsafe conditions",
                    isToggle: true,
                    toggleValue: $showingNotifications
                )
                
                Divider()
                    .padding(.leading, 44)
                
                settingsRow(
                    icon: "thermometer",
                    title: "Temperature Units",
                    subtitle: useFahrenheit ? "Fahrenheit" : "Celsius",
                    isToggle: true,
                    toggleValue: $useFahrenheit
                )
            }
            .background(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    // MARK: - Helper Views
    private func breedCard(for breed: DogBreed) -> some View {
        Button(action: {
            selectedBreed = breed
        }) {
            HStack(spacing: 16) {
                Image(systemName: "dog.fill")
                    .font(.title2)
                    .foregroundColor(breed == selectedBreed ? .white : .blue)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(breed.characteristics.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(breed == selectedBreed ? .white : .primary)
                    
                    Text("Safe: \(Int(breed.characteristics.safeTemperatureRange.lowerBound))°F - \(Int(breed.characteristics.safeTemperatureRange.upperBound))°F")
                        .font(.caption)
                        .foregroundColor(breed == selectedBreed ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if breed == selectedBreed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(breed == selectedBreed ? Color.blue : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .stroke(breed == selectedBreed ? Color.clear : Color(.systemGray4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func characteristicChip(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(6)
    }
    
    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String,
        isToggle: Bool,
        toggleValue: Binding<Bool>? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isToggle, let toggleValue = toggleValue {
                Toggle("", isOn: toggleValue)
                    .labelsHidden()
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            action?()
        }
    }
}

#Preview {
    ProfileView()
} 