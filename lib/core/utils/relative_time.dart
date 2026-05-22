String formatRelativeTime(DateTime dateTime, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(dateTime);

  if (diff.inSeconds < 10) return 'now';
  if (diff.inMinutes < 1) return '${diff.inSeconds}s';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';

  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}
