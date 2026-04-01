import SwiftUI

struct ConversationListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.conversations.isEmpty {
                    emptyState
                } else {
                    List(viewModel.conversations) { conversation in
                        NavigationLink(destination: ChatView(
                            conversationId: conversation.id ?? "",
                            userId: authViewModel.currentUser?.uid ?? ""
                        )) {
                            ConversationRow(conversation: conversation)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("AI Coach")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            guard let userId = authViewModel.currentUser?.uid else { return }
                            await viewModel.createNewConversation(userId: userId)
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                guard let userId = authViewModel.currentUser?.uid else { return }
                await viewModel.loadConversations(userId: userId)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("Ask your AI coach anything about pickleball")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Button {
                Task {
                    guard let userId = authViewModel.currentUser?.uid else { return }
                    await viewModel.createNewConversation(userId: userId)
                }
            } label: {
                Text("Start a Conversation")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
            Text(conversation.lastMessageAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
