class Story {
  final String id;
  final String userId;
  final String username;
  final String avatarUrl;
  final String? contentUrl;
  final DateTime createdAt;
  final bool isUnseen;

  Story({
    required this.id,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    this.contentUrl,
    required this.createdAt,
    this.isUnseen = true,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      contentUrl: json['content_url'],
      createdAt: DateTime.parse(json['created_at']),
      isUnseen: json['is_unseen'] ?? true,
    );
  }

  static List<Story> getMockStories() {
    return [
      Story(
        id: '1',
        userId: 'u1',
        username: 'Your Story',
        avatarUrl: 'https://i.pravatar.cc/150?u=me',
        createdAt: DateTime.now(),
        isUnseen: false,
      ),
      Story(
        id: '2',
        userId: 'u2',
        username: 'Alex_Trader',
        avatarUrl: 'https://i.pravatar.cc/150?u=alex',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Story(
        id: '3',
        userId: 'u3',
        username: 'Eco_Sarah',
        avatarUrl: 'https://i.pravatar.cc/150?u=sarah',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Story(
        id: '4',
        userId: 'u4',
        username: 'Vintage_Vibe',
        avatarUrl: 'https://i.pravatar.cc/150?u=vintage',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      Story(
        id: '5',
        userId: 'u5',
        username: 'Tech_Guru',
        avatarUrl: 'https://i.pravatar.cc/150?u=tech',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];
  }
}
