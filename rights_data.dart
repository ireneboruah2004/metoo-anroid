// Plain-language content. English only for now.
// IMPORTANT: have a lawyer or your university's legal aid cell verify this
// file before the app is shared with other students, then add Assamese and
// Hindi versions reviewed by a native speaker.

class Helpline {
  final String name;
  final String number;
  final String note;
  const Helpline(this.name, this.number, this.note);
}

class RightsTopic {
  final String title;
  final String summary;
  final List<String> points;
  const RightsTopic(this.title, this.summary, this.points);
}

const helplines = <Helpline>[
  Helpline('Emergency', '112', 'Police, ambulance, fire. Use if you are in danger now.'),
  Helpline('Women Helpline', '181', 'Counselling, and connects you to police, legal and shelter help.'),
  Helpline('Police: women in distress', '1091', 'Police helpline for women.'),
  Helpline('Free legal aid (NALSA)', '15100', 'Free legal advice and a free lawyer.'),
  Helpline('Cyber crime', '1930', 'Online harassment, blackmail, fraud. Also report at cybercrime.gov.in.'),
  Helpline('Childline', '1098', 'If the person who needs help is under 18.'),
];

const rightsTopics = <RightsTopic>[
  RightsTopic(
    'You do not have to decide today',
    'Reporting is your choice. These steps keep your options open whatever you decide.',
    [
      'Get to a safe place first. Call 112 if you are in danger.',
      'Keep evidence: screenshots, messages, call logs, photos, names of witnesses. Do not delete anything.',
      'After a physical or sexual assault, a medical examination soon after helps your case. Hospitals must give free treatment to survivors of sexual assault and acid attacks. If you have already washed or changed, still go.',
      'Write down what happened with dates while you remember it. The Complaint tab keeps it private on this phone.',
      'You can speak to a counsellor or lawyer first, at no cost: call 181 or 15100.',
      'Some complaints have time limits, so do not wait a long time without checking.',
    ],
  ),
  RightsTopic(
    'Filing a police complaint (FIR)',
    'You can ask any police station to register your complaint.',
    [
      'Zero FIR: if the crime happened in another area, the station must still register it and transfer it.',
      'In many states you can also file an e-FIR online, then sign it at the station within three days.',
      'For serious (cognizable) offences the police must register an FIR. Ask for a free copy.',
      'For sexual offences, you can ask for your statement to be recorded by a woman police officer, and at a place that is comfortable for you.',
      'If the police refuse, send your complaint in writing to the Superintendent of Police, or approach a Magistrate.',
      'You can bring someone you trust with you.',
    ],
  ),
  RightsTopic(
    'Free legal help',
    'Women are entitled to free legal services under the Legal Services Authorities Act.',
    [
      'Call 15100 (NALSA) or visit the District Legal Services Authority (DLSA) at the district court.',
      'Ask for a panel lawyer. The lawyer is free for your case.',
      'Your university or college may also have a legal aid cell or a committee for women.',
    ],
  ),
  RightsTopic(
    'One Stop Centres (Sakhi)',
    'Government centres that give help in one place.',
    [
      'Medical help, police support, legal aid, counselling and temporary shelter.',
      'Call 181 and ask to be connected to the One Stop Centre in your district.',
    ],
  ),
  RightsTopic(
    'Harassment at work or on campus',
    'The Sexual Harassment of Women at Workplace Act (POSH), 2013 protects you at work, and UGC rules cover colleges and universities.',
    [
      'Every workplace with 10 or more staff, and every college or university, must have an Internal Committee.',
      'File a written complaint with the Committee. This is generally due within 3 months of the incident, and can be extended by up to 3 more months with a reason.',
      'Settlement (conciliation) can happen only if you ask for it.',
      'Your identity must be kept confidential, and you cannot be punished for complaining.',
      'You can also go to the police at the same time.',
    ],
  ),
  RightsTopic(
    'Stalking, online abuse, leaked images',
    'Stalking, secretly recording or sharing private images, and sexual harassment are crimes.',
    [
      'Take screenshots showing the date, name and link. Do not delete the messages.',
      'Report at cybercrime.gov.in or call 1930. You can also report to the app or website.',
      'StopNCII.org can help stop intimate images from spreading online.',
      'Block the person only after you have saved the evidence.',
    ],
  ),
  RightsTopic(
    'Violence at home',
    'The Protection of Women from Domestic Violence Act, 2005 protects women at home, including in live-in relationships.',
    [
      'You can ask a court for a protection order, the right to stay in the shared home, money for expenses, and custody orders.',
      'Contact the district Protection Officer, call 181, or go to the police.',
      'Domestic violence can also be reported to the police as cruelty.',
    ],
  ),
  RightsTopic(
    'Your privacy',
    'The law protects survivors of sexual offences.',
    [
      'Publishing the name or identity of a survivor of a sexual offence is prohibited.',
      'Trials for rape cases are held in private (in camera).',
      'Ask the police, hospital and committee to keep your details confidential.',
    ],
  ),
];
