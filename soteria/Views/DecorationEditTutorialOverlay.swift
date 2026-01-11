//
//  DecorationEditTutorialOverlay.swift
//  soteria
//
//  Full-screen overlay for the decoration edit tutorial
//

import SwiftUI

struct DecorationEditTutorialOverlay: View {
    @StateObject private var tutorialManager = DecorationEditTutorialManager.shared
    @AppStorage("hide_animal_edit_tutorial_forever") private var hideTutorialForever = false
    @State private var dontShowAgain = false
    
    var body: some View {
        Group {
            if tutorialManager.showTutorial {
                AnimalEditTutorialModal(
                    onDismiss: {
                        if dontShowAgain {
                            hideTutorialForever = true
                        }
                        tutorialManager.dismissTutorial()
                    },
                    dontShowAgain: $dontShowAgain
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: tutorialManager.showTutorial)
    }
}
