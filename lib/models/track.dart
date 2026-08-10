class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.audioUrl,
    required this.gradient,
  });

  final String id;
  final String title;
  final String artist;
  final Duration duration;
  final String audioUrl;
  final List<int> gradient;
}

const demoTracks = <Track>[
  Track(id: 'blinding-lights', title: 'Blinding Lights', artist: 'The Weeknd', duration: Duration(minutes: 3, seconds: 20), audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', gradient: [0xFFFFB347, 0xFF8B1E1E]),
  Track(id: 'after-hours', title: 'After Hours', artist: 'The Weeknd', duration: Duration(minutes: 3, seconds: 42), audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', gradient: [0xFF57213B, 0xFF101522]),
  Track(id: 'starboy', title: 'Starboy', artist: 'The Weeknd', duration: Duration(minutes: 3, seconds: 50), audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', gradient: [0xFFB40027, 0xFF00153D]),
  Track(id: 'save-your-tears', title: 'Save Your Tears', artist: 'The Weeknd', duration: Duration(minutes: 3, seconds: 35), audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3', gradient: [0xFF4A1C82, 0xFF0C1028]),
  Track(id: 'another-love', title: 'Another Love', artist: 'Tom Odell', duration: Duration(minutes: 4, seconds: 4), audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3', gradient: [0xFFB9B9B9, 0xFF202020]),
  Track(id: 'believer', title: 'Believer', artist: 'Imagine Dragons', duration: Duration(minutes: 3, seconds: 24), audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3', gradient: [0xFF00A9B7, 0xFF073B4C]),
  Track(id: 'hurt', title: 'Hurt', artist: 'Johnny Cash', duration: Duration(minutes: 3, seconds: 38), audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3', gradient: [0xFF777777, 0xFF111111]),
  Track(id: 'wasted-times', title: 'Wasted Times', artist: 'The Weeknd', duration: Duration(minutes: 3, seconds: 40), audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3', gradient: [0xFFFF6B35, 0xFF3C1A0E]),
];
