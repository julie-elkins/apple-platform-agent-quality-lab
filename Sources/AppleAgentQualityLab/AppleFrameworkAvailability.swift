import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(AppIntents)
import AppIntents
#endif

#if canImport(AppIntentsTesting)
import AppIntentsTesting
#endif

#if canImport(Evaluations)
import Evaluations
#endif

public enum AppleFrameworkAvailabilityProvider {
    public static var current: FrameworkAvailability {
        #if canImport(FoundationModels)
        let foundationModels = true
        #else
        let foundationModels = false
        #endif

        #if canImport(AppIntents)
        let appIntents = true
        #else
        let appIntents = false
        #endif

        #if canImport(AppIntentsTesting)
        let appIntentsTesting = true
        #else
        let appIntentsTesting = false
        #endif

        #if canImport(Evaluations)
        let evaluations = true
        #else
        let evaluations = false
        #endif

        let note: String
        if foundationModels && appIntents && appIntentsTesting && evaluations {
            note = "Apple-native model, intent, intent-testing, and evaluations modules are available to the build."
        } else if foundationModels && appIntents {
            note = "FoundationModels and AppIntents are available; native testing and evaluation frameworks may require macOS 27."
        } else {
            note = "Running the provider-neutral offline slice; Apple-native model modules are unavailable to this build."
        }

        return FrameworkAvailability(
            foundationModels: foundationModels,
            appIntents: appIntents,
            appIntentsTesting: appIntentsTesting,
            evaluations: evaluations,
            note: note
        )
    }
}
