//
//  LinkSheetView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI

struct LinkSheetView: View {
    @Environment(\.appTintColor) var appTintColor
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    @Binding var url: String
    @State private var isValidURL: Bool = false
    @State private var formattedURL: URL?
    @Environment(\.presentationMode) var presentationMode
    @State private var validationError: String?
    @State private var isLoading: Bool = false
    @State private var webViewError: String? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack {
                    TextField("Enter link", text: $url)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                        .onChange(of: url) { newValue, oldValue in
                            self.isValidURL = false
                            self.validationError = nil
                        }
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Button(action: {
                        validateURL(url)
                    }) {
                        Text("Check Link")
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(appTintColor)
                            .cornerRadius(4)
                    }
                }
                .padding()
                if let error = validationError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                if let formattedURL = formattedURL, isValidURL {
                    ZStack {
                        WebView(url: formattedURL, isLoading: $isLoading, errorMessage: $webViewError)
                            .frame(maxHeight: 400)
                            .cornerRadius(8)
                            .padding(.horizontal)
                        if isLoading {
                            ProgressView("Loading...")
                                .padding()
                        }
                    }
                    if let webError = webViewError {
                        Text("Error: \(webError)")
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                Spacer()
            }
            .navigationTitle("Enter Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .disabled(!isValidURL)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func validateURL(_ urlString: String) {
        let trimmedString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        var urlToValidate = trimmedString
        if !trimmedString.lowercased().hasPrefix("http://") && !trimmedString.lowercased().hasPrefix("https://") {
            urlToValidate = "https://" + trimmedString
        }
        if let url = URL(string: urlToValidate),
           let scheme = url.scheme?.lowercased(),
           (scheme == "http" || scheme == "https"),
           let host = url.host,
           !host.isEmpty {
            self.formattedURL = url
            self.isValidURL = true
            self.validationError = nil
        } else {
            self.formattedURL = nil
            self.isValidURL = false
            self.validationError = "Please enter a valid URL with a proper scheme and host."
        }
    }

    private func saveAndDismiss() {
        if let formattedURL = formattedURL {
            url = formattedURL.absoluteString
            presentationMode.wrappedValue.dismiss()
        }
    }
}
