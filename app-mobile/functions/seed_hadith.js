/**
 * Hadith Seeder — Sihah Sittah (~1000 hadith across 6 books)
 *
 * Usage:
 *   node seed_hadith.js
 *
 * Prerequisites:
 *   npm install firebase-admin
 *   Set GOOGLE_APPLICATION_CREDENTIALS env var to your service account JSON path
 *   OR place serviceAccountKey.json next to this file
 */

const admin = require('firebase-admin');
const path  = require('path');
const fs    = require('fs');

// ── Firebase init ─────────────────────────────────────────────────────────────
const keyPath = path.join(__dirname, 'serviceAccountKey.json');
if (!fs.existsSync(keyPath)) {
  console.error('ERROR: serviceAccountKey.json not found in functions/');
  console.error('Download it from Firebase Console → Project Settings → Service Accounts');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(keyPath)),
});

const db = admin.firestore();

// ── Hadith dataset ────────────────────────────────────────────────────────────
// Each entry: { book, chapter, hadithNumber, textEn, textAr, textBn }
// Distributed across 6 books: Bukhari, Muslim, Abu Dawud, Tirmidhi, Nasai, Ibn Majah
// This seed contains representative hadith from each book.
// Extend this array to reach your target count.

const HADITH = [
  // ── Sahih al-Bukhari ──────────────────────────────────────────────────────
  {
    book: 'Sahih al-Bukhari', chapter: 'Revelation', hadithNumber: 1,
    textEn: 'The reward of deeds depends upon the intentions and every person will get the reward according to what he has intended.',
    textAr: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى.',
    textBn: 'নিশ্চয়ই কাজের ফলাফল নিয়তের উপর নির্ভরশীল এবং প্রত্যেক ব্যক্তি তাই পাবে যা সে নিয়ত করেছে।',
  },
  {
    book: 'Sahih al-Bukhari', chapter: 'Faith', hadithNumber: 8,
    textEn: 'Islam is based on five pillars: testifying that there is no god but Allah and Muhammad is His Messenger, performing prayers, paying the Zakat, making Hajj to the House, and fasting in Ramadan.',
    textAr: 'بُنِيَ الإِسْلاَمُ عَلَى خَمْسٍ: شَهَادَةِ أَنْ لاَ إِلَهَ إِلاَّ اللَّهُ وَأَنَّ مُحَمَّدًا رَسُولُ اللَّهِ، وَإِقَامِ الصَّلاَةِ، وَإِيتَاءِ الزَّكَاةِ، وَالحَجِّ، وَصَوْمِ رَمَضَانَ.',
    textBn: 'ইসলাম পাঁচটি স্তম্ভের উপর প্রতিষ্ঠিত: সাক্ষ্য দেওয়া যে আল্লাহ ছাড়া কোনো ইলাহ নেই এবং মুহাম্মদ তাঁর রাসূল, সালাত কায়েম করা, যাকাত দেওয়া, হজ্জ করা এবং রমজানে রোজা রাখা।',
  },
  {
    book: 'Sahih al-Bukhari', chapter: 'Knowledge', hadithNumber: 59,
    textEn: 'To seek knowledge is an obligation upon every Muslim.',
    textAr: 'طَلَبُ الْعِلْمِ فَرِيضَةٌ عَلَى كُلِّ مُسْلِمٍ.',
    textBn: 'জ্ঞান অর্জন করা প্রত্যেক মুসলমানের উপর ফরজ।',
  },
  {
    book: 'Sahih al-Bukhari', chapter: 'Prayer', hadithNumber: 354,
    textEn: 'Pray as you have seen me praying.',
    textAr: 'صَلُّوا كَمَا رَأَيْتُمُونِي أُصَلِّي.',
    textBn: 'তোমরা নামাজ পড়ো যেভাবে আমাকে নামাজ পড়তে দেখেছ।',
  },
  {
    book: 'Sahih al-Bukhari', chapter: 'Fasting', hadithNumber: 1894,
    textEn: 'When Ramadan begins, the gates of Paradise are opened, the gates of Hell are closed, and the devils are chained.',
    textAr: 'إِذَا جَاءَ رَمَضَانُ فُتِّحَتْ أَبْوَابُ الجَنَّةِ، وَغُلِّقَتْ أَبْوَابُ النَّارِ، وَصُفِّدَتِ الشَّيَاطِينُ.',
    textBn: 'যখন রমজান আসে, জান্নাতের দরজাগুলো খুলে দেওয়া হয়, জাহান্নামের দরজাগুলো বন্ধ করা হয় এবং শয়তানদের শৃঙ্খলে আবদ্ধ করা হয়।',
  },
  {
    book: 'Sahih al-Bukhari', chapter: 'Zakat', hadithNumber: 1395,
    textEn: 'Save yourself from the Fire even if with half a date in charity.',
    textAr: 'اتَّقُوا النَّارَ وَلَوْ بِشِقِّ تَمْرَةٍ.',
    textBn: 'আগুন থেকে বাঁচো, যদিও অর্ধেক খেজুর দিয়ে দান করেই হোক।',
  },
  {
    book: 'Sahih al-Bukhari', chapter: 'Good Manners', hadithNumber: 5765,
    textEn: 'The best among you are those who have the best manners and character.',
    textAr: 'إِنَّ مِنْ خِيَارِكُمْ أَحْسَنَكُمْ أَخْلاَقًا.',
    textBn: 'তোমাদের মধ্যে সর্বোত্তম সে, যার চরিত্র সর্বোত্তম।',
  },
  {
    book: 'Sahih al-Bukhari', chapter: 'Dhikr', hadithNumber: 6406,
    textEn: 'The most beloved words to Allah are four: SubhanAllah, Alhamdulillah, La ilaha illallah, Allahu Akbar.',
    textAr: 'أَحَبُّ الْكَلاَمِ إِلَى اللَّهِ أَرْبَعٌ: سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلاَ إِلَهَ إِلاَّ اللَّهُ، وَاللَّهُ أَكْبَرُ.',
    textBn: 'আল্লাহর কাছে সবচেয়ে প্রিয় কথা চারটি: সুবহানাল্লাহ, আলহামদুলিল্লাহ, লা ইলাহা ইল্লাল্লাহ, আল্লাহু আকবার।',
  },
  {
    book: 'Sahih al-Bukhari', chapter: 'Virtues', hadithNumber: 3551,
    textEn: 'I have been sent to perfect good character.',
    textAr: 'إِنَّمَا بُعِثْتُ لِأُتَمِّمَ صَالِحَ الأَخْلاَقِ.',
    textBn: 'আমাকে উত্তম চরিত্র পরিপূর্ণ করতে প্রেরণ করা হয়েছে।',
  },
  {
    book: 'Sahih al-Bukhari', chapter: 'Oaths', hadithNumber: 6677,
    textEn: 'None of you truly believes until he loves for his brother what he loves for himself.',
    textAr: 'لاَ يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ.',
    textBn: 'তোমাদের কেউ ততক্ষণ পর্যন্ত পূর্ণ মুমিন হবে না যতক্ষণ না সে তার ভাইয়ের জন্য তাই চায় যা সে নিজের জন্য চায়।',
  },

  // ── Sahih Muslim ──────────────────────────────────────────────────────────
  {
    book: 'Sahih Muslim', chapter: 'Faith', hadithNumber: 8,
    textEn: 'Faith has over seventy branches, and modesty is a branch of faith.',
    textAr: 'الإِيمَانُ بِضْعٌ وَسَبْعُونَ شُعْبَةً، وَالْحَيَاءُ شُعْبَةٌ مِنَ الإِيمَانِ.',
    textBn: 'ইমানের সত্তরেরও বেশি শাখা রয়েছে এবং লজ্জা ইমানের একটি শাখা।',
  },
  {
    book: 'Sahih Muslim', chapter: 'Purification', hadithNumber: 223,
    textEn: 'Cleanliness is half of faith.',
    textAr: 'الطَّهُورُ شَطْرُ الإِيمَانِ.',
    textBn: 'পবিত্রতা ইমানের অর্ধেক।',
  },
  {
    book: 'Sahih Muslim', chapter: 'Prayer', hadithNumber: 482,
    textEn: 'The key to Paradise is prayer, and the key to prayer is purification.',
    textAr: 'مِفْتَاحُ الْجَنَّةِ الصَّلاَةُ، وَمِفْتَاحُ الصَّلاَةِ الطُّهُورُ.',
    textBn: 'জান্নাতের চাবি হলো নামাজ এবং নামাজের চাবি হলো পবিত্রতা।',
  },
  {
    book: 'Sahih Muslim', chapter: 'Remembrance', hadithNumber: 2675,
    textEn: 'Whoever recites SubhanAllah wa bihamdihi one hundred times a day, his sins will be wiped away even if they are like the foam of the sea.',
    textAr: 'مَنْ قَالَ سُبْحَانَ اللَّهِ وَبِحَمْدِهِ فِي يَوْمٍ مِائَةَ مَرَّةٍ حُطَّتْ خَطَايَاهُ وَإِنْ كَانَتْ مِثْلَ زَبَدِ الْبَحْرِ.',
    textBn: 'যে ব্যক্তি প্রতিদিন একশতবার "সুবহানাল্লাহি ওয়া বিহামদিহি" বলবে, তার পাপগুলো মুছে যাবে যদিও তা সমুদ্রের ফেনার মতো হয়।',
  },
  {
    book: 'Sahih Muslim', chapter: 'Virtues', hadithNumber: 2564,
    textEn: 'Do not envy one another; do not inflate prices for one another; do not hate one another; do not turn away from one another; and do not undercut one another in trade. Be, O slaves of Allah, brothers.',
    textAr: 'لاَ تَحَاسَدُوا وَلاَ تَنَاجَشُوا وَلاَ تَبَاغَضُوا وَلاَ تَدَابَرُوا وَلاَ يَبِعْ بَعْضُكُمْ عَلَى بَيْعِ بَعْضٍ وَكُونُوا عِبَادَ اللَّهِ إِخْوَانًا.',
    textBn: 'তোমরা পরস্পর হিংসা করো না, মূল্য বাড়িয়ে দিও না, ঘৃণা করো না, পেছন ফিরে থেকো না এবং একে অপরের ব্যবসায় ক্ষতি করো না। আল্লাহর বান্দা হও, ভাই হও।',
  },
  {
    book: 'Sahih Muslim', chapter: 'Charity', hadithNumber: 1631,
    textEn: 'When a person dies, his deeds come to an end except for three: ongoing charity, knowledge that is benefited from, or a righteous child who prays for him.',
    textAr: 'إِذَا مَاتَ الإِنْسَانُ انْقَطَعَ عَنْهُ عَمَلُهُ إِلاَّ مِنْ ثَلاَثَةٍ: إِلاَّ مِنْ صَدَقَةٍ جَارِيَةٍ، أَوْ عِلْمٍ يُنْتَفَعُ بِهِ، أَوْ وَلَدٍ صَالِحٍ يَدْعُو لَهُ.',
    textBn: 'যখন মানুষ মারা যায়, তার আমল বন্ধ হয়ে যায় তিনটি ছাড়া: চলমান সদকা, উপকারী জ্ঞান, বা নেককার সন্তান যে তার জন্য দোয়া করে।',
  },
  {
    book: 'Sahih Muslim', chapter: 'Quran', hadithNumber: 798,
    textEn: 'The one who is proficient in the recitation of the Quran will be with the honorable and obedient scribes (angels) and he who recites the Quran and finds it difficult to recite, doing his best to recite it in the best way possible, will have a double reward.',
    textAr: 'الْمَاهِرُ بِالْقُرْآنِ مَعَ السَّفَرَةِ الْكِرَامِ الْبَرَرَةِ، وَالَّذِي يَقْرَأُ الْقُرْآنَ وَيَتَتَعْتَعُ فِيهِ، وَهُوَ عَلَيْهِ شَاقٌّ، لَهُ أَجْرَانِ.',
    textBn: 'যে ব্যক্তি কুরআন পড়তে দক্ষ সে সম্মানিত ও আনুগত্যশীল ফেরেশতাদের সাথে থাকবে। আর যে পড়তে গিয়ে আটকে যায় কিন্তু চেষ্টা করে, তার দ্বিগুণ পুরস্কার।',
  },
  {
    book: 'Sahih Muslim', chapter: 'Repentance', hadithNumber: 2747,
    textEn: 'Allah is more pleased with the repentance of His slave than a person who has his camel in a waterless desert carrying his provision of food and drink and it is lost. He, having lost all hope, lies down in the shade and is in despair when he finds the camel standing before him. He takes hold of its reins and then out of boundless joy blurts out: O Allah! You are my slave and I am Your Lord. He commits this mistake out of extreme joy.',
    textAr: 'لَلَّهُ أَشَدُّ فَرَحًا بِتَوْبَةِ عَبْدِهِ حِينَ يَتُوبُ إِلَيْهِ مِنْ أَحَدِكُمْ كَانَ عَلَى رَاحِلَتِهِ بِأَرْضِ فَلاَةٍ فَانْفَلَتَتْ مِنْهُ.',
    textBn: 'বান্দা যখন তওবা করে আল্লাহ তার তওবায় সেই ব্যক্তির চেয়েও বেশি খুশি হন যার উট মরুভূমিতে হারিয়ে গিয়েছিল এবং হঠাৎ পেয়ে গেছে।',
  },
  {
    book: 'Sahih Muslim', chapter: 'Goodness', hadithNumber: 2588,
    textEn: 'Righteousness is good character, and sin is that which wavers in your soul and you dislike people finding out about it.',
    textAr: 'الْبِرُّ حُسْنُ الْخُلُقِ وَالإِثْمُ مَا حَاكَ فِي صَدْرِكَ وَكَرِهْتَ أَنْ يَطَّلِعَ عَلَيْهِ النَّاسُ.',
    textBn: 'নেকি হলো উত্তম চরিত্র এবং পাপ হলো যা তোমার বুকে দোলা দেয় এবং তুমি অপছন্দ করো যে লোকেরা তা জানুক।',
  },
  {
    book: 'Sahih Muslim', chapter: 'Paradise', hadithNumber: 2822,
    textEn: 'Allah has prepared for His righteous servants what no eye has seen, no ear has heard, and no human heart has conceived.',
    textAr: 'أَعْدَدْتُ لِعِبَادِيَ الصَّالِحِينَ مَا لاَ عَيْنٌ رَأَتْ وَلاَ أُذُنٌ سَمِعَتْ وَلاَ خَطَرَ عَلَى قَلْبِ بَشَرٍ.',
    textBn: 'আল্লাহ বলেন: আমি আমার নেক বান্দাদের জন্য এমন কিছু প্রস্তুত করেছি যা কোনো চোখ দেখেনি, কোনো কান শোনেনি এবং কোনো মানুষের হৃদয়ে কল্পনা হয়নি।',
  },

  // ── Sunan Abu Dawud ──────────────────────────────────────────────────────
  {
    book: 'Sunan Abu Dawud', chapter: 'Prayer', hadithNumber: 495,
    textEn: 'Teach your children prayer when they are seven years old, and smack them if they do not pray when they are ten.',
    textAr: 'مُرُوا أَوْلاَدَكُمْ بِالصَّلاَةِ وَهُمْ أَبْنَاءُ سَبْعِ سِنِينَ، وَاضْرِبُوهُمْ عَلَيْهَا وَهُمْ أَبْنَاءُ عَشْرٍ.',
    textBn: 'তোমাদের সন্তানদের সাত বছর বয়সে নামাজের নির্দেশ দাও এবং দশ বছরে না পড়লে (হালকাভাবে) মারো।',
  },
  {
    book: 'Sunan Abu Dawud', chapter: 'Purification', hadithNumber: 61,
    textEn: 'Water is pure and purifying; nothing makes it impure except that which changes its color, taste, or smell.',
    textAr: 'الْمَاءُ طَهُورٌ لاَ يُنَجِّسُهُ شَيْءٌ إِلاَّ مَا غَيَّرَ لَوْنَهُ أَوْ طَعْمَهُ أَوْ رِيحَهُ.',
    textBn: 'পানি পবিত্র এবং পবিত্রকারী; কিছুই একে অপবিত্র করে না যদি না তা তার রং, স্বাদ বা গন্ধ পরিবর্তন করে।',
  },
  {
    book: 'Sunan Abu Dawud', chapter: 'Sunnah', hadithNumber: 4607,
    textEn: 'Hold fast to my Sunnah and the Sunnah of the rightly-guided caliphs after me. Adhere to it and cling to it firmly.',
    textAr: 'عَلَيْكُمْ بِسُنَّتِي وَسُنَّةِ الْخُلَفَاءِ الرَّاشِدِينَ الْمَهْدِيِّينَ مِنْ بَعْدِي، تَمَسَّكُوا بِهَا وَعَضُّوا عَلَيْهَا بِالنَّوَاجِذِ.',
    textBn: 'আমার সুন্নাহ এবং আমার পরে সৎপথপ্রাপ্ত খলিফাদের সুন্নাহ আঁকড়ে ধরো। তা মেনে চলো এবং দাঁত দিয়ে কামড়ে ধরো।',
  },
  {
    book: 'Sunan Abu Dawud', chapter: 'Manners', hadithNumber: 4800,
    textEn: 'A person follows the religion of his close friend, so each of you should consider whom he makes his close friend.',
    textAr: 'الرَّجُلُ عَلَى دِينِ خَلِيلِهِ، فَلْيَنْظُرْ أَحَدُكُمْ مَنْ يُخَالِلُ.',
    textBn: 'মানুষ তার বন্ধুর ধর্মের উপর থাকে, তাই তোমাদের প্রত্যেকে দেখুক সে কাকে বন্ধু বানাচ্ছে।',
  },
  {
    book: 'Sunan Abu Dawud', chapter: 'Night Prayer', hadithNumber: 1368,
    textEn: 'The best prayer after the obligatory prayers is the night prayer.',
    textAr: 'أَفْضَلُ الصَّلاَةِ بَعْدَ الْفَرِيضَةِ صَلاَةُ اللَّيْلِ.',
    textBn: 'ফরজ নামাজের পরে সর্বোত্তম নামাজ হলো রাতের নামাজ।',
  },
  {
    book: 'Sunan Abu Dawud', chapter: 'Medicine', hadithNumber: 3855,
    textEn: 'Make use of the two remedies: honey and the Quran.',
    textAr: 'عَلَيْكُمْ بِالشِّفَاءَيْنِ: الْعَسَلِ وَالْقُرْآنِ.',
    textBn: 'দুটি নিরাময় ব্যবহার করো: মধু এবং কুরআন।',
  },
  {
    book: 'Sunan Abu Dawud', chapter: 'Zakah', hadithNumber: 1672,
    textEn: 'The upper hand is better than the lower hand. The upper hand is the one that gives, and the lower hand is the one that takes.',
    textAr: 'الْيَدُ الْعُلْيَا خَيْرٌ مِنَ الْيَدِ السُّفْلَى، وَابْدَأْ بِمَنْ تَعُولُ.',
    textBn: 'ওপরের হাত নিচের হাতের চেয়ে উত্তম। ওপরের হাত দানকারীর এবং নিচের হাত গ্রহণকারীর।',
  },
  {
    book: 'Sunan Abu Dawud', chapter: 'Knowledge', hadithNumber: 3641,
    textEn: 'Whoever travels a path in search of knowledge, Allah will make easy for him a path to Paradise.',
    textAr: 'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ طَرِيقًا إِلَى الْجَنَّةِ.',
    textBn: 'যে ব্যক্তি জ্ঞান অন্বেষণে পথ চলে, আল্লাহ তার জন্য জান্নাতের পথ সহজ করে দেন।',
  },
  {
    book: 'Sunan Abu Dawud', chapter: 'Fasting', hadithNumber: 2363,
    textEn: 'There are two pleasures for the fasting person: one at the time of breaking his fast, and the other at the time when he will meet his Lord.',
    textAr: 'لِلصَّائِمِ فَرْحَتَانِ: فَرْحَةٌ حِينَ يُفْطِرُ، وَفَرْحَةٌ حِينَ يَلْقَى رَبَّهُ.',
    textBn: 'রোজাদারের জন্য দুটি আনন্দ আছে: একটি ইফতারের সময় এবং অপরটি যখন সে তার রবের সাথে সাক্ষাৎ করবে।',
  },
  {
    book: 'Sunan Abu Dawud', chapter: 'General Behavior', hadithNumber: 4682,
    textEn: 'Be modest before Allah as He truly deserves. Guard your head and what it contains, your stomach and what it holds.',
    textAr: 'اسْتَحْيُوا مِنَ اللَّهِ حَقَّ الْحَيَاءِ، احْفَظُوا الرَّأْسَ وَمَا حَوَى، وَالْبَطْنَ وَمَا وَعَى.',
    textBn: 'আল্লাহর ব্যাপারে যথাযথ লজ্জা রাখো। মাথা ও তার মধ্যে যা আছে তা রক্ষা করো, পেট ও তাতে যা আছে তা রক্ষা করো।',
  },

  // ── Jami at-Tirmidhi ──────────────────────────────────────────────────────
  {
    book: "Jami' at-Tirmidhi", chapter: 'Virtues', hadithNumber: 2516,
    textEn: 'Be mindful of Allah and He will protect you. Be mindful of Allah and you will find Him in front of you. If you ask, ask only Allah; if you seek help, seek help only from Allah.',
    textAr: 'احْفَظِ اللَّهَ يَحْفَظْكَ، احْفَظِ اللَّهَ تَجِدْهُ تُجَاهَكَ، إِذَا سَأَلْتَ فَاسْأَلِ اللَّهَ، وَإِذَا اسْتَعَنْتَ فَاسْتَعِنْ بِاللَّهِ.',
    textBn: 'আল্লাহকে স্মরণ রাখো, তিনি তোমাকে রক্ষা করবেন। আল্লাহকে স্মরণ রাখো, তুমি তাঁকে তোমার সামনে পাবে। যখন চাও, শুধু আল্লাহর কাছে চাও; যখন সাহায্য চাও, শুধু আল্লাহর কাছে সাহায্য চাও।',
  },
  {
    book: "Jami' at-Tirmidhi", chapter: 'Asceticism', hadithNumber: 2377,
    textEn: 'Be in this world as though you were a stranger or a traveler passing through.',
    textAr: 'كُنْ فِي الدُّنْيَا كَأَنَّكَ غَرِيبٌ أَوْ عَابِرُ سَبِيلٍ.',
    textBn: 'দুনিয়ায় এমনভাবে থাকো যেন তুমি একজন অপরিচিত বা পথচারী।',
  },
  {
    book: "Jami' at-Tirmidhi", chapter: 'Prayer', hadithNumber: 413,
    textEn: 'Prayer is the pillar of the religion.',
    textAr: 'الصَّلاَةُ عِمَادُ الدِّينِ.',
    textBn: 'নামাজ হলো দীনের স্তম্ভ।',
  },
  {
    book: "Jami' at-Tirmidhi", chapter: 'Supplication', hadithNumber: 3370,
    textEn: 'Supplication is the essence of worship.',
    textAr: 'الدُّعَاءُ مُخُّ الْعِبَادَةِ.',
    textBn: 'দোয়া হলো ইবাদতের মূল।',
  },
  {
    book: "Jami' at-Tirmidhi", chapter: 'Good Character', hadithNumber: 2003,
    textEn: 'The heaviest thing that will be placed on the believer\'s scale on the Day of Resurrection is good character.',
    textAr: 'مَا مِنْ شَيْءٍ أَثْقَلُ فِي مِيزَانِ الْمُؤْمِنِ يَوْمَ الْقِيَامَةِ مِنْ حُسْنِ الْخُلُقِ.',
    textBn: 'কিয়ামতের দিন মুমিনের পাল্লায় সবচেয়ে ভারী জিনিস হবে উত্তম চরিত্র।',
  },
  {
    book: "Jami' at-Tirmidhi", chapter: 'Quran', hadithNumber: 2906,
    textEn: 'The best of you are those who learn the Quran and teach it.',
    textAr: 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ.',
    textBn: 'তোমাদের মধ্যে সর্বোত্তম সে যে কুরআন শেখে এবং শেখায়।',
  },
  {
    book: "Jami' at-Tirmidhi", chapter: 'Zuhd', hadithNumber: 2340,
    textEn: 'Richness is not in having many possessions, but richness is the richness of the soul.',
    textAr: 'لَيْسَ الْغِنَى عَنْ كَثْرَةِ الْعَرَضِ وَلَكِنَّ الْغِنَى غِنَى النَّفْسِ.',
    textBn: 'সম্পদের প্রাচুর্য দিয়ে সম্পদশালী হওয়া যায় না; বরং প্রকৃত সম্পদ হলো আত্মার সম্পদ।',
  },
  {
    book: "Jami' at-Tirmidhi", chapter: 'Parents', hadithNumber: 1899,
    textEn: 'The pleasure of the Lord is in the pleasure of the parent, and the displeasure of the Lord is in the displeasure of the parent.',
    textAr: 'رِضَا الرَّبِّ فِي رِضَا الْوَالِدِ، وَسَخَطُ الرَّبِّ فِي سَخَطِ الْوَالِدِ.',
    textBn: 'রবের সন্তুষ্টি পিতামাতার সন্তুষ্টিতে এবং রবের অসন্তোষ পিতামাতার অসন্তোষে।',
  },
  {
    book: "Jami' at-Tirmidhi", chapter: 'Mercy', hadithNumber: 1924,
    textEn: 'Show mercy to those on earth, and the One in heaven will show mercy to you.',
    textAr: 'ارْحَمُوا مَنْ فِي الأَرْضِ يَرْحَمْكُمْ مَنْ فِي السَّمَاءِ.',
    textBn: 'পৃথিবীবাসীদের প্রতি দয়া করো, আকাশে যিনি আছেন তিনি তোমাদের প্রতি দয়া করবেন।',
  },
  {
    book: "Jami' at-Tirmidhi", chapter: 'Truthfulness', hadithNumber: 1971,
    textEn: 'Adhere to truthfulness, for truthfulness leads to righteousness and righteousness leads to Paradise.',
    textAr: 'عَلَيْكُمْ بِالصِّدْقِ، فَإِنَّ الصِّدْقَ يَهْدِي إِلَى الْبِرِّ، وَالْبِرَّ يَهْدِي إِلَى الْجَنَّةِ.',
    textBn: 'সত্যবাদিতা আঁকড়ে ধরো, কারণ সত্যবাদিতা নেকির দিকে নিয়ে যায় এবং নেকি জান্নাতের দিকে নিয়ে যায়।',
  },

  // ── Sunan an-Nasa'i ───────────────────────────────────────────────────────
  {
    book: "Sunan an-Nasa'i", chapter: 'Prayer', hadithNumber: 461,
    textEn: 'The first thing the servant will be held accountable for on the Day of Judgment is the prayer.',
    textAr: 'أَوَّلُ مَا يُحَاسَبُ الْعَبْدُ بِهِ يَوْمَ الْقِيَامَةِ الصَّلاَةُ.',
    textBn: 'কিয়ামতের দিন বান্দার সর্বপ্রথম নামাজের হিসাব নেওয়া হবে।',
  },
  {
    book: "Sunan an-Nasa'i", chapter: 'Fasting', hadithNumber: 2217,
    textEn: 'Whoever fasts Ramadan out of faith and in hope of reward, his past sins will be forgiven.',
    textAr: 'مَنْ صَامَ رَمَضَانَ إِيمَانًا وَاحْتِسَابًا غُفِرَ لَهُ مَا تَقَدَّمَ مِنْ ذَنْبِهِ.',
    textBn: 'যে ব্যক্তি ঈমান ও ছওয়াবের আশায় রমজানে রোজা রাখে, তার পূর্বের পাপ ক্ষমা করে দেওয়া হয়।',
  },
  {
    book: "Sunan an-Nasa'i", chapter: 'Jihad', hadithNumber: 3097,
    textEn: 'The greatest Jihad is to battle your own soul.',
    textAr: 'أَفْضَلُ الْجِهَادِ مَنْ جَاهَدَ نَفْسَهُ فِي ذَاتِ اللَّهِ عَزَّ وَجَلَّ.',
    textBn: 'শ্রেষ্ঠ জিহাদ হলো নিজের নফসের বিরুদ্ধে জিহাদ।',
  },
  {
    book: "Sunan an-Nasa'i", chapter: 'Hajj', hadithNumber: 2622,
    textEn: 'Whoever performs Hajj for the sake of Allah and does not utter any obscene speech or commit any evil deed, will return as sinless as the day his mother gave birth to him.',
    textAr: 'مَنْ حَجَّ لِلَّهِ فَلَمْ يَرْفُثْ وَلَمْ يَفْسُقْ رَجَعَ كَيَوْمِ وَلَدَتْهُ أُمُّهُ.',
    textBn: 'যে ব্যক্তি আল্লাহর জন্য হজ্জ করে এবং অশ্লীল কথা বলে না ও পাপ করে না, সে সেদিনের মতো ফিরে আসে যেদিন মা তাকে জন্ম দিয়েছিল।',
  },
  {
    book: "Sunan an-Nasa'i", chapter: 'Zakah', hadithNumber: 2523,
    textEn: 'Charity does not decrease wealth.',
    textAr: 'مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ.',
    textBn: 'সদকা সম্পদ কমায় না।',
  },
  {
    book: "Sunan an-Nasa'i", chapter: 'Sins', hadithNumber: 4938,
    textEn: 'Avoid the seven great destructive sins: associating partners with Allah; practicing sorcery; killing a soul which Allah has forbidden except by right; consuming riba; consuming the wealth of the orphan; fleeing from the battlefield; and accusing chaste, innocent, believing women.',
    textAr: 'اجْتَنِبُوا السَّبْعَ الْمُوبِقَاتِ: الشِّرْكُ بِاللَّهِ، وَالسِّحْرُ، وَقَتْلُ النَّفْسِ، وَأَكْلُ الرِّبَا، وَأَكْلُ مَالِ الْيَتِيمِ، وَالتَّوَلِّي يَوْمَ الزَّحْفِ، وَقَذْفُ الْمُحْصَنَاتِ.',
    textBn: 'সাতটি ধ্বংসাত্মক পাপ থেকে বিরত থাকো: শিরক, জাদু, অন্যায়ভাবে হত্যা, সুদ ভক্ষণ, এতিমের সম্পদ ভক্ষণ, যুদ্ধক্ষেত্র থেকে পলায়ন, এবং সতী নারীর বিরুদ্ধে অপবাদ।',
  },
  {
    book: "Sunan an-Nasa'i", chapter: 'Night Prayer', hadithNumber: 1602,
    textEn: 'Hold fast to night prayer, for it was the way of the righteous before you, a means of nearness to Allah, expiation for sins, and a shield against disease.',
    textAr: 'عَلَيْكُمْ بِقِيَامِ اللَّيْلِ فَإِنَّهُ دَأْبُ الصَّالِحِينَ قَبْلَكُمْ وَقُرْبَةٌ إِلَى اللَّهِ.',
    textBn: 'রাতের নামাজ আঁকড়ে ধরো, কারণ এটি তোমাদের আগের নেককারদের অভ্যাস, আল্লাহর নৈকট্যের মাধ্যম এবং পাপের কাফফারা।',
  },
  {
    book: "Sunan an-Nasa'i", chapter: 'Etiquette', hadithNumber: 5311,
    textEn: 'The Muslim is the one from whose tongue and hand other Muslims are safe.',
    textAr: 'الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ.',
    textBn: 'মুসলিম সে ব্যক্তি যার জিহ্বা ও হাত থেকে অন্য মুসলিমরা নিরাপদ।',
  },
  {
    book: "Sunan an-Nasa'i", chapter: 'Gifts', hadithNumber: 3790,
    textEn: 'Give gifts to one another and you will love one another.',
    textAr: 'تَهَادَوْا تَحَابُّوا.',
    textBn: 'উপহার দাও, একে অপরকে ভালোবাসবে।',
  },
  {
    book: "Sunan an-Nasa'i", chapter: 'Remembrance', hadithNumber: 1248,
    textEn: 'He who recites after every prayer: SubhanAllah 33 times, Alhamdulillah 33 times, Allahu Akbar 33 times, and completes the hundred with La ilaha illallah wahdahu la sharika lah — his sins will be forgiven even if they are like the foam of the sea.',
    textAr: 'مَنْ سَبَّحَ اللَّهَ فِي دُبُرِ كُلِّ صَلاَةٍ ثَلاَثًا وَثَلاَثِينَ وَحَمِدَ اللَّهَ ثَلاَثًا وَثَلاَثِينَ وَكَبَّرَ اللَّهَ ثَلاَثًا وَثَلاَثِينَ.',
    textBn: 'যে ব্যক্তি প্রতি নামাজের পরে ৩৩ বার সুবহানাল্লাহ, ৩৩ বার আলহামদুলিল্লাহ, ৩৩ বার আল্লাহু আকবার এবং একশত পূর্ণ করে লা ইলাহা ইল্লাল্লাহ বলে, তার পাপ ক্ষমা করা হবে যদিও সমুদ্রের ফেনার মতো হয়।',
  },

  // ── Sunan Ibn Majah ───────────────────────────────────────────────────────
  {
    book: 'Sunan Ibn Majah', chapter: 'Sunnah', hadithNumber: 1,
    textEn: 'Follow my Sunnah and the Sunnah of the rightly-guided caliphs after me.',
    textAr: 'فَعَلَيْكُمْ بِسُنَّتِي وَسُنَّةِ الْخُلَفَاءِ الرَّاشِدِينَ الْمَهْدِيِّينَ مِنْ بَعْدِي.',
    textBn: 'আমার সুন্নাহ এবং আমার পরে সৎপথপ্রাপ্ত খলিফাদের সুন্নাহ অনুসরণ করো।',
  },
  {
    book: 'Sunan Ibn Majah', chapter: 'Mosques', hadithNumber: 800,
    textEn: 'The mosques are the houses of Allah on earth, and it gives joy to Allah when His guests visit Him therein.',
    textAr: 'الْمَسَاجِدُ بُيُوتُ اللَّهِ فِي الأَرْضِ وَهِيَ تُضِيءُ لأَهْلِ السَّمَاءِ.',
    textBn: 'মসজিদ হলো পৃথিবীতে আল্লাহর ঘর এবং এগুলো আকাশবাসীদের জন্য আলো ছড়ায়।',
  },
  {
    book: 'Sunan Ibn Majah', chapter: 'Fasting', hadithNumber: 1742,
    textEn: 'Take suhoor, for there is blessing in suhoor.',
    textAr: 'تَسَحَّرُوا فَإِنَّ فِي السَّحُورِ بَرَكَةً.',
    textBn: 'সেহরি খাও, কারণ সেহরিতে বরকত আছে।',
  },
  {
    book: 'Sunan Ibn Majah', chapter: 'Business', hadithNumber: 2145,
    textEn: 'The honest and trustworthy merchant will be with the prophets, the truthful, and the martyrs.',
    textAr: 'التَّاجِرُ الصَّدُوقُ الأَمِينُ مَعَ النَّبِيِّينَ وَالصِّدِّيقِينَ وَالشُّهَدَاءِ.',
    textBn: 'সৎ ও আমানতদার ব্যবসায়ী নবী, সিদ্দিক ও শহিদদের সাথে থাকবে।',
  },
  {
    book: 'Sunan Ibn Majah', chapter: 'Medicine', hadithNumber: 3436,
    textEn: 'Allah has not created a disease without creating a cure for it.',
    textAr: 'مَا أَنْزَلَ اللَّهُ دَاءً إِلاَّ أَنْزَلَ لَهُ شِفَاءً.',
    textBn: 'আল্লাহ কোনো রোগ পাঠাননি যার জন্য প্রতিকার পাঠাননি।',
  },
  {
    book: 'Sunan Ibn Majah', chapter: 'Patience', hadithNumber: 4031,
    textEn: 'No calamity befalls a Muslim but that Allah expiates some of his sins because of it, even if it were the prick he receives from a thorn.',
    textAr: 'مَا يُصِيبُ الْمُسْلِمَ مِنْ نَصَبٍ وَلاَ وَصَبٍ وَلاَ هَمٍّ وَلاَ حَزَنٍ وَلاَ أَذًى وَلاَ غَمٍّ حَتَّى الشَّوْكَةِ يُشَاكُهَا إِلاَّ كَفَّرَ اللَّهُ بِهَا مِنْ خَطَايَاهُ.',
    textBn: 'কোনো মুসলিমের উপর যে বিপদ আসে — ক্লান্তি, রোগ, দুশ্চিন্তা, দুঃখ, কষ্ট বা কাঁটার খোঁচাও — তার পাপের কাফফারা হয়।',
  },
  {
    book: 'Sunan Ibn Majah', chapter: 'Zakat', hadithNumber: 1844,
    textEn: 'Protect yourself from the Fire even if with half a date.',
    textAr: 'اتَّقُوا النَّارَ وَلَوْ بِشِقِّ تَمْرَةٍ، فَمَنْ لَمْ يَجِدْ فَبِكَلِمَةٍ طَيِّبَةٍ.',
    textBn: 'আগুন থেকে বাঁচো যদিও অর্ধেক খেজুর দিয়ে হোক; যে তা পারো না, সে মিষ্টি কথা দিয়ে হোক।',
  },
  {
    book: 'Sunan Ibn Majah', chapter: 'Etiquette', hadithNumber: 3694,
    textEn: 'Kindness is not found in anything but that it adds to its beauty, and it is not withdrawn from anything but it makes it defective.',
    textAr: 'إِنَّ الرِّفْقَ لاَ يَكُونُ فِي شَيْءٍ إِلاَّ زَانَهُ، وَلاَ يُنْزَعُ مِنْ شَيْءٍ إِلاَّ شَانَهُ.',
    textBn: 'নম্রতা যেকোনো জিনিসে থাকলে তাকে সুশোভিত করে এবং যেকোনো জিনিস থেকে নেওয়া হলে তাকে কুৎসিত করে।',
  },
  {
    book: 'Sunan Ibn Majah', chapter: 'Supplication', hadithNumber: 3828,
    textEn: 'Whoever does not ask from Allah, Allah becomes angry with him.',
    textAr: 'مَنْ لَمْ يَسْأَلِ اللَّهَ يَغْضَبْ عَلَيْهِ.',
    textBn: 'যে আল্লাহর কাছে চায় না, আল্লাহ তার উপর রাগান্বিত হন।',
  },
  {
    book: 'Sunan Ibn Majah', chapter: 'Death', hadithNumber: 4258,
    textEn: 'Remember often the destroyer of pleasures — death.',
    textAr: 'أَكْثِرُوا ذِكْرَ هَاذِمِ اللَّذَّاتِ: الْمَوْتِ.',
    textBn: 'আনন্দের বিনাশকারী মৃত্যুকে বেশি বেশি স্মরণ করো।',
  },
];

// ── Seeder ────────────────────────────────────────────────────────────────────
async function seed() {
  const col = db.collection('hadith');
  const BATCH_SIZE = 400;

  // Add globalIndex to each hadith
  const hadithWithIndex = HADITH.map((h, i) => ({ ...h, globalIndex: i + 1 }));

  console.log(`Seeding ${hadithWithIndex.length} hadith into 'hadith' collection...`);

  for (let i = 0; i < hadithWithIndex.length; i += BATCH_SIZE) {
    const batch  = db.batch();
    const chunk  = hadithWithIndex.slice(i, i + BATCH_SIZE);
    chunk.forEach(h => {
      const ref = col.doc(`${h.book.replace(/[^a-zA-Z0-9]/g, '_')}_${h.hadithNumber}`);
      batch.set(ref, {
        ...h,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });
    await batch.commit();
    console.log(`  ✓ Committed batch ${Math.floor(i / BATCH_SIZE) + 1} (${chunk.length} docs)`);
  }

  console.log(`\nDone. ${hadithWithIndex.length} hadith seeded.`);
  console.log('Note: Extend the HADITH array to reach 1000 entries from all 6 books.');
  process.exit(0);
}

seed().catch(e => { console.error(e); process.exit(1); });
