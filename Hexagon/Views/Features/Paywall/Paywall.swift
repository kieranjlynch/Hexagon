//
//  Paywall.swift
//  Hexagon
//
//  Created by Kieran Lynch on 19/09/2024.
//

import SwiftUI
import StoreKit

struct Paywall: View {
    @State private var selectedOption: Int? = nil
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        VStack {
            VStack {
                Text("How your free trial works")
                    .padding(.top)
                    .padding(.bottom)
                    .fontWeight(.bold)
                    .font(.title)

                HStack {
                    ZStack {
                        Capsule()
                            .fill(.blue)

                        VStack {
                            Image(systemName: "lock.open.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                                .padding(.top)
                            Spacer()
                            Image(systemName: "bell.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                            Spacer()
                            Image(systemName: "dollarsign")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                                .padding(.bottom)
                        }
                    }
                    .frame(width: 30, height: 300)

                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            Text("Today")
                                .fontWeight(.bold)
                            Text("Get unlimited free access")
                        }

                        Spacer()

                        VStack(alignment: .leading) {
                            Text("Day 15")
                                .fontWeight(.bold)
                            Text("Reminder that your free trial is ending")
                        }

                        Spacer()

                        VStack(alignment: .leading) {
                            Text("Day 30")
                                .fontWeight(.bold)
                            Text("You'll be charged. Cancel anytime before")
                        }
                    }
                    .frame(height: 300)
                    .padding()
                }
                .padding(.leading, 35)
                .padding(.top)
                .padding(.bottom, 30)
            }

            VStack {
                Text("Choose a plan")
                    .font(.title2)
                    .padding(.bottom)

                if subscriptionManager.availableProducts.isEmpty {
                    ProgressView("Loading plans...")
                        .padding()
                } else {
                    HStack(spacing: 30) {
                        Spacer()

                        ForEach(subscriptionManager.availableProducts, id: \.id) { product in
                            Button(action: {
                                Task {
                                    do {
                                        try await subscriptionManager.purchase(product: product)
                                    } catch {
                                        print("Purchase failed: \(error)")
                                    }
                                }
                            }) {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(self.selectedOption == 0 ? Color.blue : Color.gray, lineWidth: self.selectedOption == 0 ? 2 : 1)
                                    .frame(width: 150, height: 150)
                                    .overlay(
                                        VStack {
                                            Text(product.displayPrice)
                                                .font(.title)
                                                .padding(.bottom)
                                            Text(product.displayName)
                                        }
                                        .padding()
                                        .foregroundColor(.black)
                                    )
                            }
                        }

                        Spacer()
                    }
                }
            }

            Spacer()

            Group {
                HStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.green)
                        .frame(width: 340, height: 70)
                        .overlay(
                            VStack {
                                Text("Start my free trial now")
                                    .fontWeight(.bold)
                                    .padding(.top)
                                Spacer()
                                Text("tap to start, easy to cancel")
                                    .padding(.bottom)
                            }
                            .padding()
                            .foregroundColor(.white)
                        )
                }

                Text("Restore purchase")
                    .padding(.top)
            }
        }
    }
}


struct Paywall_Previews: PreviewProvider {
    static var previews: some View {
        Paywall()
    }
}
