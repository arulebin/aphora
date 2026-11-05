/// Picture words for children's speech practice.
///
/// Pictures are emoji: bright, familiar to children, available offline on
/// every phone, and no image files to bundle. Each word carries a meaning
/// hint in both languages — the first rung of the cueing ladder — written
/// the way a parent would describe the thing to a child.
///
/// `level` 1 = words built from early-developing sounds (vowels, ம ப த ந க வ);
/// `level` 2 = words that need later sounds (ச ல ர ழ ள ற) or are longer.
enum KidCategory { animals, food, things, vehicles, body, nature, family }

extension KidCategoryName on KidCategory {
  (String, String) get names => switch (this) {
        KidCategory.animals => ('Animals', 'விலங்குகள்'),
        KidCategory.food => ('Food', 'உணவு'),
        KidCategory.things => ('Things', 'பொருட்கள்'),
        KidCategory.vehicles => ('Vehicles', 'வாகனங்கள்'),
        KidCategory.body => ('Body', 'உடல்'),
        KidCategory.nature => ('Nature', 'இயற்கை'),
        KidCategory.family => ('Family', 'குடும்பம்'),
      };
}

class KidWord {
  const KidWord(
    this.id,
    this.ta,
    this.en,
    this.emoji,
    this.category,
    this.level,
    this.cueEn,
    this.cueTa, {
    this.taAlternates = const [],
  });

  /// Stable id used in Firestore attempts (`kid_<id>`).
  final String id;
  final String ta;
  final String en;
  final String emoji;
  final KidCategory category;
  final int level;

  /// Meaning hint, e.g. "It says meow".
  final String cueEn;
  final String cueTa;

  /// Spoken / loan-word forms the recogniser may return (தண்ணி for தண்ணீர்).
  final List<String> taAlternates;
}

const List<KidWord> kidWords = [
  // ── Animals ──
  KidWord('elephant', 'யானை', 'Elephant', '🐘', KidCategory.animals, 1,
      'A big animal with a long trunk', 'நீண்ட தும்பிக்கை உள்ள பெரிய விலங்கு'),
  KidWord('cat', 'பூனை', 'Cat', '🐱', KidCategory.animals, 1,
      'It says meow', 'மியாவ் என்று கத்தும்'),
  KidWord('dog', 'நாய்', 'Dog', '🐶', KidCategory.animals, 1,
      'It says woof woof', 'லொள் லொள் என்று குரைக்கும்'),
  KidWord('cow', 'மாடு', 'Cow', '🐄', KidCategory.animals, 1,
      'It gives us milk', 'நமக்குப் பால் தரும்',
      taAlternates: ['பசு']),
  KidWord('fish', 'மீன்', 'Fish', '🐟', KidCategory.animals, 1,
      'It swims in water', 'தண்ணீரில் நீந்தும்'),
  KidWord('goat', 'ஆடு', 'Goat', '🐐', KidCategory.animals, 1,
      'It says baa', 'மே மே என்று கத்தும்'),
  KidWord('tortoise', 'ஆமை', 'Tortoise', '🐢', KidCategory.animals, 1,
      'It walks very slowly', 'மிக மெதுவாக நடக்கும்'),
  KidWord('duck', 'வாத்து', 'Duck', '🦆', KidCategory.animals, 1,
      'It says quack quack', 'குவாக் குவாக் என்று கத்தும்'),
  KidWord('snake', 'பாம்பு', 'Snake', '🐍', KidCategory.animals, 1,
      'It has no legs', 'இதற்குக் கால்கள் இல்லை'),
  KidWord('crab', 'நண்டு', 'Crab', '🦀', KidCategory.animals, 1,
      'It walks sideways', 'பக்கவாட்டில் நடக்கும்'),
  KidWord('monkey', 'குரங்கு', 'Monkey', '🐒', KidCategory.animals, 2,
      'It jumps from tree to tree', 'மரத்துக்கு மரம் தாவும்'),
  KidWord('lion', 'சிங்கம்', 'Lion', '🦁', KidCategory.animals, 2,
      'The king of the forest', 'காட்டின் ராஜா'),
  KidWord('rabbit', 'முயல்', 'Rabbit', '🐰', KidCategory.animals, 2,
      'It has long ears', 'நீண்ட காதுகள் உண்டு'),
  KidWord('hen', 'கோழி', 'Hen', '🐔', KidCategory.animals, 2,
      'It lays eggs', 'முட்டை இடும்'),
  KidWord('frog', 'தவளை', 'Frog', '🐸', KidCategory.animals, 2,
      'It hops near the pond', 'குளத்தருகே தாவித் தாவிச் செல்லும்'),
  KidWord('peacock', 'மயில்', 'Peacock', '🦚', KidCategory.animals, 2,
      'A bird with beautiful feathers', 'அழகான தோகை உள்ள பறவை'),
  KidWord('ant', 'எறும்பு', 'Ant', '🐜', KidCategory.animals, 2,
      'A tiny insect', 'சின்னஞ்சிறு பூச்சி'),
  KidWord('butterfly', 'பட்டாம்பூச்சி', 'Butterfly', '🦋', KidCategory.animals, 2,
      'It has colourful wings', 'வண்ண இறக்கைகள் உண்டு'),
  KidWord('horse', 'குதிரை', 'Horse', '🐴', KidCategory.animals, 2,
      'We can ride on it', 'இதன் மேல் சவாரி செய்யலாம்'),

  // ── Food ──
  KidWord('milk', 'பால்', 'Milk', '🥛', KidCategory.food, 1,
      'A white drink from the cow', 'மாடு தரும் வெள்ளை பானம்'),
  KidWord('egg', 'முட்டை', 'Egg', '🥚', KidCategory.food, 1,
      'The hen gives it', 'கோழி தரும்'),
  KidWord('coconut', 'தேங்காய்', 'Coconut', '🥥', KidCategory.food, 1,
      'It grows on a tall tree', 'உயரமான மரத்தில் காய்க்கும்'),
  KidWord('sweet', 'மிட்டாய்', 'Sweet', '🍬', KidCategory.food, 1,
      'A sweet treat', 'இனிப்பான தின்பண்டம்'),
  KidWord('water', 'தண்ணீர்', 'Water', '💧', KidCategory.food, 1,
      'We drink it when thirsty', 'தாகம் எடுத்தால் குடிப்போம்',
      taAlternates: ['தண்ணி']),
  KidWord('mango', 'மாம்பழம்', 'Mango', '🥭', KidCategory.food, 2,
      'A sweet yellow fruit', 'இனிப்பான மஞ்சள் பழம்'),
  KidWord('banana', 'வாழைப்பழம்', 'Banana', '🍌', KidCategory.food, 2,
      'A long yellow fruit', 'நீளமான மஞ்சள் பழம்'),
  KidWord('tomato', 'தக்காளி', 'Tomato', '🍅', KidCategory.food, 2,
      'A red vegetable', 'சிவப்பு நிறக் காய்'),
  KidWord('meal', 'சாப்பாடு', 'Food', '🍛', KidCategory.food, 2,
      'We eat it when hungry', 'பசித்தால் சாப்பிடுவோம்'),
  KidWord('icecream', 'ஐஸ்கிரீம்', 'Ice cream', '🍦', KidCategory.food, 2,
      'Cold and sweet', 'குளிர்ந்த இனிப்பு'),

  // ── Things ──
  KidWord('ball', 'பந்து', 'Ball', '⚽', KidCategory.things, 1,
      'We kick it and play', 'உதைத்து விளையாடுவோம்'),
  KidWord('kite', 'பட்டம்', 'Kite', '🪁', KidCategory.things, 1,
      'It flies in the wind', 'காற்றில் பறக்கும்'),
  KidWord('umbrella', 'குடை', 'Umbrella', '☂️', KidCategory.things, 1,
      'It keeps us dry in the rain', 'மழையில் நனையாமல் காக்கும்'),
  KidWord('book', 'புத்தகம்', 'Book', '📖', KidCategory.things, 1,
      'We read it', 'இதைப் படிப்போம்'),
  KidWord('bell', 'மணி', 'Bell', '🔔', KidCategory.things, 1,
      'It goes ding dong', 'டிங் டாங் என்று ஒலிக்கும்'),
  KidWord('cap', 'தொப்பி', 'Cap', '🧢', KidCategory.things, 1,
      'We wear it on our head', 'தலையில் அணிவோம்'),
  KidWord('balloon', 'பலூன்', 'Balloon', '🎈', KidCategory.things, 2,
      'We blow air into it', 'காற்று ஊதி விளையாடுவோம்'),
  KidWord('shirt', 'சட்டை', 'Shirt', '👕', KidCategory.things, 2,
      'We wear it every day', 'தினமும் அணியும் உடை'),

  // ── Vehicles ──
  KidWord('car', 'கார்', 'Car', '🚗', KidCategory.vehicles, 1,
      'It has four wheels', 'நான்கு சக்கரங்கள் உண்டு'),
  KidWord('aeroplane', 'விமானம்', 'Aeroplane', '✈️', KidCategory.vehicles, 1,
      'It flies in the sky', 'வானில் பறக்கும்'),
  KidWord('boat', 'படகு', 'Boat', '⛵', KidCategory.vehicles, 1,
      'It goes on water', 'தண்ணீரில் செல்லும்'),
  KidWord('bus', 'பேருந்து', 'Bus', '🚌', KidCategory.vehicles, 2,
      'Many people travel in it', 'நிறைய பேர் இதில் பயணிப்போம்',
      taAlternates: ['பஸ்']),
  KidWord('train', 'ரயில்', 'Train', '🚆', KidCategory.vehicles, 2,
      'It runs on tracks', 'தண்டவாளத்தில் ஓடும்'),
  KidWord('bicycle', 'மிதிவண்டி', 'Bicycle', '🚲', KidCategory.vehicles, 2,
      'Two wheels, we pedal it', 'இரண்டு சக்கரம், மிதித்து ஓட்டுவோம்',
      taAlternates: ['சைக்கிள்']),

  // ── Body ──
  KidWord('hand', 'கை', 'Hand', '✋', KidCategory.body, 1,
      'We hold things with it', 'இதனால் பொருட்களைப் பிடிப்போம்'),
  KidWord('eye', 'கண்', 'Eye', '👁️', KidCategory.body, 1,
      'We see with it', 'இதனால் பார்க்கிறோம்'),
  KidWord('foot', 'கால்', 'Foot', '🦶', KidCategory.body, 1,
      'We walk with it', 'இதனால் நடக்கிறோம்'),
  KidWord('tooth', 'பல்', 'Tooth', '🦷', KidCategory.body, 1,
      'We brush it every morning', 'தினமும் காலையில் துலக்குவோம்'),
  KidWord('nose', 'மூக்கு', 'Nose', '👃', KidCategory.body, 1,
      'We smell with it', 'இதனால் மணம் அறிகிறோம்'),
  KidWord('ear', 'காது', 'Ear', '👂', KidCategory.body, 1,
      'We hear with it', 'இதனால் கேட்கிறோம்'),

  // ── Nature ──
  KidWord('flower', 'பூ', 'Flower', '🌸', KidCategory.nature, 1,
      'It smells nice', 'நல்ல வாசனை வரும்'),
  KidWord('tree', 'மரம்', 'Tree', '🌳', KidCategory.nature, 1,
      'Birds sit on it', 'பறவைகள் இதில் அமரும்'),
  KidWord('moon', 'நிலா', 'Moon', '🌙', KidCategory.nature, 1,
      'We see it at night', 'இரவில் வானில் தெரியும்'),
  KidWord('sun', 'சூரியன்', 'Sun', '☀️', KidCategory.nature, 2,
      'It shines in the day', 'பகலில் ஒளி தரும்'),
  KidWord('rain', 'மழை', 'Rain', '🌧️', KidCategory.nature, 2,
      'Water falls from the sky', 'வானில் இருந்து தண்ணீர் விழும்'),
  KidWord('leaf', 'இலை', 'Leaf', '🍃', KidCategory.nature, 2,
      'It is green and grows on a tree', 'மரத்தில் வளரும் பச்சை'),
  KidWord('star', 'நட்சத்திரம்', 'Star', '⭐', KidCategory.nature, 2,
      'It twinkles at night', 'இரவில் மின்னும்'),

  // ── Family ──
  KidWord('mother', 'அம்மா', 'Mother', '👩', KidCategory.family, 1,
      'She is your mother', 'இவர் உன் தாய்'),
  KidWord('father', 'அப்பா', 'Father', '👨', KidCategory.family, 1,
      'He is your father', 'இவர் உன் தந்தை'),
  KidWord('grandmother', 'பாட்டி', 'Grandmother', '👵', KidCategory.family, 1,
      'Amma’s or Appa’s mother', 'அம்மா அல்லது அப்பாவின் அம்மா'),
  KidWord('grandfather', 'தாத்தா', 'Grandfather', '👴', KidCategory.family, 1,
      'Amma’s or Appa’s father', 'அம்மா அல்லது அப்பாவின் அப்பா'),
  KidWord('baby', 'பாப்பா', 'Baby', '👶', KidCategory.family, 1,
      'A very small child', 'சின்னக் குழந்தை'),
];
