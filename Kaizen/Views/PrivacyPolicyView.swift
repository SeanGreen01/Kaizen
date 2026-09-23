import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Privacy Policy for Kaizen")
                    .font(.title.weight(.medium))
                    .accessibilityAddTraits(.isHeader)
                Text("Effective date: 23 September 2026")
                    .font(.subheadline.weight(.semibold))
                policyText("""
                Kaizen is a productivity application designed to help users plan their day, organise tasks, manage calendar events and reflect on their daily priorities.

                Kaizen is developed and operated by Sean Green in the United Kingdom.

                If you have any questions about this Privacy Policy or the handling of your personal information, you can contact:
                """)
                contactEmail

                policySection("Information Kaizen collects", "To provide Kaizen's account and synchronisation features, the app collects and stores certain information.")
                policySection("Account information", """
                When you create an account, Kaizen uses Firebase Authentication to process:

                • your email address;
                • your authentication credentials;
                • a unique Firebase user identifier associated with your account.

                Firebase Authentication may also process technical information such as your IP address and user-agent information for authentication, security and abuse-prevention purposes.
                """)
                policySection("Content you create", """
                Information you enter into Kaizen may be stored in Firebase Cloud Firestore. This can include:

                • tasks and priorities;
                • calendar events;
                • daily planning information;
                • daily reviews;
                • associated timestamps and account information.

                This information is associated with your Firebase user ID so that Kaizen can retrieve the correct information for your account.
                """)
                policySection("How your information is used", """
                Your information is used only to provide and operate Kaizen.

                This includes:

                • creating and managing your account;
                • signing you into Kaizen;
                • saving your tasks, calendar events and daily reviews;
                • synchronising your information between app sessions and supported devices;
                • displaying your agenda and priorities;
                • maintaining the security and operation of the service.

                Kaizen does not use your personal information for targeted advertising.

                Kaizen does not sell your personal information.

                Kaizen does not use your information to track you across apps or websites owned by other companies.

                Kaizen does not currently use Firebase Analytics, advertising SDKs or third-party behavioural analytics services.
                """)
                policySection("Legal basis for processing", """
                Where UK data protection law applies, personal information required to create your account and provide Kaizen's features is processed because it is necessary to provide the service you have requested.

                Where processing is necessary to protect the security and integrity of Kaizen, information may also be processed for legitimate interests relating to security, fraud prevention and service operation.
                """)
                policySection("Firebase and service providers", """
                Kaizen uses services provided by Google Firebase.

                The Firebase services currently used by Kaizen are:

                • Firebase Authentication, for account registration and authentication;
                • Firebase Cloud Firestore, for storing Kaizen user data.

                Google generally processes Firebase customer data on behalf of the developer as a data processor.

                Firebase Authentication operates using infrastructure located in the United States. Cloud Firestore may process data using Google infrastructure according to the configured Firebase and Google Cloud service locations.

                As a result, your information may be processed outside the United Kingdom.

                Google provides contractual and organisational safeguards intended to protect personal information processed through Firebase services.
                """)
                policySection("Data security", """
                Kaizen uses Firebase security controls to restrict access to stored user information.

                Kaizen user data is associated with a Firebase user identifier, and access controls are designed so that authenticated users can access only information associated with their own account.

                Firebase encrypts supported Authentication and Cloud Firestore data while in transit and at rest.

                Although reasonable technical and organisational measures are used to protect information, no internet-based service can guarantee absolute security.
                """)
                policySection("Data retention", """
                Your Kaizen data is retained while your account remains active or until you choose to delete it.

                When you permanently delete your Kaizen account, Kaizen is designed to delete the associated Kaizen data stored for your account and then delete your Firebase Authentication account.

                Some information may remain temporarily within Firebase or Google backup and operational systems in accordance with their normal backup, security and service-retention processes.
                """)
                policySection("Account deletion", """
                You can permanently delete your account from within Kaizen through the account settings.

                Account deletion removes your Kaizen account and the personal Kaizen data associated with that account, except where information must be retained for legal, security or regulatory reasons.

                If you experience difficulty deleting your account, you can contact:
                """)
                contactEmail
                policySection("Your data protection rights", """
                Depending on where you live, you may have rights relating to your personal information.

                Under UK data protection law, these may include the right to:

                • request access to personal information held about you;
                • request correction of inaccurate information;
                • request deletion of your personal information;
                • request restriction of certain processing;
                • object to certain processing;
                • request a copy of your information in a portable format where applicable.

                You can exercise these rights by contacting:
                """)
                contactEmail
                policyText("If you are located in the United Kingdom and believe your personal information has not been handled correctly, you also have the right to raise a concern with the UK Information Commissioner's Office.")
                policySection("Children's privacy", """
                Kaizen is not specifically designed for children and does not intentionally seek to collect personal information from children.

                If you believe that a child has provided personal information to Kaizen inappropriately, please contact us so that the situation can be investigated.
                """)
                policySection("Changes to this Privacy Policy", """
                This Privacy Policy may be updated if Kaizen's features, data practices or service providers change.

                When material changes are made, the updated Privacy Policy will be made available within the app and through Kaizen's public Privacy Policy webpage.

                The effective date at the top of this policy will be updated when changes are made.
                """)
                policySection("Contact", """
                For privacy questions, requests or concerns relating to Kaizen, contact:

                Sean Green
                United Kingdom
                """)
                contactEmail
            }
            .textSelection(.enabled)
            .padding(24)
            .frame(maxWidth: 700, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(KaizenTheme.background)
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var contactEmail: some View {
        Link("Email: seangreen640@gmail.com", destination: URL(string: "mailto:seangreen640@gmail.com")!)
            .font(.subheadline)
            .tint(KaizenTheme.accent)
    }

    private func policyText(_ text: String) -> some View {
        Text(text).font(.subheadline).foregroundStyle(KaizenTheme.muted)
    }

    private func policySection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            policyText(body)
        }
    }
}

#Preview { NavigationStack { PrivacyPolicyView() } }
