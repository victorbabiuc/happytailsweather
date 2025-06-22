import SwiftUI

struct ProfileView: View {
    @AppStorage("selectedBreed") private var selectedBreed: DogBreed = .labradorRetriever
    @AppStorage("isPremium") private var isPremium: Bool = false
    @State private var searchText = ""
    @State private var showingNotifications = true
    @State private var useFahrenheit = true
    @State private var showingPremiumUpgrade = false
    
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
                    
                    // Premium Status Section
                    premiumStatusSection
                    
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
        .sheet(isPresented: $showingPremiumUpgrade) {
            premiumUpgradeView
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
    
    // MARK: - Premium Status Section
    private var premiumStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: isPremium ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundColor(isPremium ? .yellow : .gray)
                
                Text(isPremium ? "Premium Active" : "Free Plan")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isPremium ? .primary : .secondary)
                
                Spacer()
                
                if isPremium {
                    PremiumBadge()
                }
            }
            
            if isPremium {
                PremiumBenefitsList(benefits: Constants.Premium.premiumBenefits)
            } else {
                UpgradePrompt(
                    title: "Unlock Premium Features",
                    subtitle: "Get personalized walking times, extended forecasts, and advanced safety insights",
                    onUpgrade: { showingPremiumUpgrade = true }
                )
            }
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
                
                Divider()
                    .padding(.leading, 44)
                
                settingsRow(
                    icon: "star.fill",
                    title: "Premium Features",
                    subtitle: isPremium ? "Active - All features unlocked" : "Upgrade for advanced features",
                    isToggle: false,
                    action: { showingPremiumUpgrade = true }
                )
                
                // Developer toggle for testing premium features
                Divider()
                    .padding(.leading, 44)
                
                settingsRow(
                    icon: "hammer.fill",
                    title: "Developer Mode",
                    subtitle: "Toggle premium status for testing",
                    isToggle: true,
                    toggleValue: $isPremium
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
    
    // MARK: - Premium Upgrade View
    private var premiumUpgradeView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Upgrade to Premium")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Get advanced weather insights and personalized recommendations for your \(selectedBreed.characteristics.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Premium Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Premium Features")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            featureRow("Today's Best Times", "Find 3-4 optimal walking windows throughout the day")
                            featureRow("Hourly Weather Analysis", "Detailed temperature, humidity, and wind predictions")
                            featureRow("Breed-Specific Insights", "Advanced recommendations tailored to your dog")
                            featureRow("Priority Safety Alerts", "Get notified about changing conditions first")
                            featureRow("Extended Forecasts", "7-day weather predictions with breed safety")
                            featureRow("Enhanced Walk Tracking", "Advanced analytics and walk history")
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .fill(Color(.systemGray6))
                    )
                    
                    // Pricing (Demo)
                    VStack(spacing: 12) {
                        Text("Premium Plan")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("$4.99/month or $39.99/year")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("Cancel anytime • 7-day free trial")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            // Simulate premium upgrade
                            isPremium = true
                            showingPremiumUpgrade = false
                        }) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.subheadline)
                                Text("Start Free Trial")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                        }
                        
                        Button(action: {
                            showingPremiumUpgrade = false
                        }) {
                            Text("Maybe Later")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Terms
                    Text("By subscribing, you agree to our Terms of Service and Privacy Policy. You can cancel your subscription at any time.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                showingPremiumUpgrade = false
            })
        }
    }
    
    private func featureRow(_ title: String, _ description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ProfileView()
} 