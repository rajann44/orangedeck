enum StoryFilter {
  top(displayName: 'Top Stories', apiKey: 'top'),
  newest(displayName: 'Newest', apiKey: 'new'),
  best(displayName: 'Best', apiKey: 'best'),
  ask(displayName: 'Ask HN', apiKey: 'ask'),
  show(displayName: 'Show HN', apiKey: 'show'),
  jobs(displayName: 'Jobs', apiKey: 'job');

  final String displayName;
  final String apiKey; // Maps to '{apiKey}stories.json'

  const StoryFilter({
    required this.displayName,
    required this.apiKey,
  });
}
