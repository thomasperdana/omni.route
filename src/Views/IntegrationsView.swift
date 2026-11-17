import SwiftUI

struct IntegrationSnippet: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let code: String
    let tip: String
}

struct IntegrationsView: View {
    @ObservedObject var appState: AppState
    
    var snippets: [IntegrationSnippet] {
        let base = "http://localhost:\(appState.activePort)/v1"
        return [
            IntegrationSnippet(
                title: "Cursor & Windsurf IDE",
                subtitle: "Configure custom OpenAI-compatible provider in settings",
                icon: "cursorarrow.rays",
                iconColor: .purple,
                code: """
                # In Cursor Settings -> Models -> OpenAI API:
                Base URL: \(base)
                API Key: omniroute
                """,
                tip: "OmniRoute automatically handles model routing and fallbacks behind this endpoint."
            ),
            IntegrationSnippet(
                title: "Cline (VS Code Extension)",
                subtitle: "OpenAI-compatible local gateway profile",
                icon: "laptopcomputer",
                iconColor: .blue,
                code: """
                API Provider: OpenAI Compatible
                Base URL: \(base)
                API Key: omniroute
                Model ID: <configured-in-omniroute>
                """,
                tip: "Run 'omniroute setup-cline' or configure manually in Cline settings."
            ),
            IntegrationSnippet(
                title: "Claude Code CLI",
                subtitle: "Point Claude Code directly at OmniRoute gateway",
                icon: "sparkles",
                iconColor: .orange,
                code: """
                export ANTHROPIC_BASE_URL="\(base)"
                export ANTHROPIC_API_KEY="omniroute"
                # Or run:
                omniroute launch
                """,
                tip: "Use 'omniroute launch' for built-in fallback chain and dual-upstream tracking."
            ),
            IntegrationSnippet(
                title: "Python (OpenAI SDK)",
                subtitle: "Connect standard python openai package",
                icon: "chevron.left.forwardslash.chevron.right",
                iconColor: .green,
                code: """
                from openai import OpenAI

                client = OpenAI(
                    base_url="\(base)",
                    api_key="omniroute",
                )

                response = client.chat.completions.create(
                    model="gpt-4o",
                    messages=[{"role": "user", "content": "Hello via OmniRoute!"}]
                )
                print(response.choices[0].message.content)
                """,
                tip: "Compatible with any library expecting standard OpenAI ChatCompletions."
            ),
            IntegrationSnippet(
                title: "cURL Quick Test",
                subtitle: "Verify gateway connectivity via terminal",
                icon: "terminal",
                iconColor: .gray,
                code: """
                curl \(base)/models
                """,
                tip: "Returns the active list of providers and models routed by OmniRoute."
            )
        ]
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connect Your Coding Agents & Tools")
                        .font(.title3.bold())
                    Text("Point any OpenAI-compatible AI client to your local OmniRoute endpoint.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Snippet cards
                ForEach(snippets) { snippet in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: snippet.icon)
                                .font(.title3)
                                .foregroundColor(snippet.iconColor)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(snippet.title)
                                    .font(.headline)
                                Text(snippet.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                appState.copySnippet(text: snippet.code, id: snippet.id)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: appState.copiedSnippetId == snippet.id ? "checkmark" : "doc.on.doc")
                                    Text(appState.copiedSnippetId == snippet.id ? "Copied" : "Copy")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        Text(snippet.code)
                            .font(.system(size: 11, design: .monospaced))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 0.08, green: 0.09, blue: 0.12))
                            .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.9))
                            .cornerRadius(6)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(snippet.tip)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(16)
        }
    }
}
