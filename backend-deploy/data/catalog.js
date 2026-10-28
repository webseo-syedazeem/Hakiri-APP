const ACTIVITIES = [
  {
    slug: "think_fast",
    name: "Think Fast",
    isMvp: true,
    tagline: "Instant cognitive agility under time pressure",
    description:
      "A random question flashes on screen. After 5 seconds the app records for 60 seconds while you think on the spot.",
    cognitiveMechanism: "Rapid lexical retrieval and on-the-spot framing under stress",
    prepDurationSeconds: 5,
    defaultDurationSeconds: 60,
    benefits: [
      "High cognitive agility under stress",
      "Higher perceived authority",
      "Reduced meeting fatigue with bottom-line-up-front answers",
    ],
    successMeasures: ["Latency and stall tactics", "Structural coherence", "Composition and fillers"],
    rubrics: [
      {
        key: "latency",
        name: "Latency and stall tactics",
        beginner: "Stalling and panic",
        intermediary: "Intentional silence",
        professional: "Instant framing with a deliberate pause",
      },
      {
        key: "structural_coherence",
        name: "Structural coherence",
        beginner: "Chronological narrative",
        intermediary: "Basic framework",
        professional: "Thematic bucketing",
      },
      {
        key: "composition_fillers",
        name: "Composition and fillers",
        beginner: "High density of fillers",
        intermediary: "Controlled vocabulary",
        professional: "Zero fillers",
      },
    ],
  },
  {
    slug: "connect_the_dots",
    name: "Connect the Dots",
    isMvp: true,
    tagline: "Lateral thinking and the seamless pivot",
    description:
      "Two random topics appear, a 5 second countdown runs, then you have 60 seconds to connect them.",
    cognitiveMechanism: "Associative retrieval and metaphorical bridge building",
    prepDurationSeconds: 5,
    defaultDurationSeconds: 60,
    benefits: [
      "Faster lexical retrieval",
      "Mastery of the seamless pivot",
      "Creative problem solving under observation",
    ],
    successMeasures: ["Pivot placement", "Bridge logic", "Conceptual integration", "Speech mechanics"],
    rubrics: [
      {
        key: "pivot_placement",
        name: "Pivot placement",
        beginner: "Spends 45+ seconds on concept A and finishes concept B awkwardly",
        intermediary: "Transitions around the 25 to 35 second mark and splits both concepts",
        professional: "Plants the connection inside the opening",
      },
      {
        key: "bridge_logic",
        name: "Bridge logic",
        beginner: "Jarring or disjointed link",
        intermediary: "Explicit transition phrase",
        professional: "Seamless metaphorical reframe",
      },
      {
        key: "conceptual_integration",
        name: "Conceptual integration",
        beginner: "Treats the two ideas as separate",
        intermediary: "Applies a lesson from the first concept to the second",
        professional: "Synthesises both into one thesis",
      },
      {
        key: "speech_mechanics",
        name: "Speech mechanics",
        beginner: "High filler density or a stammer at the bridge",
        intermediary: "1 to 3 fillers per minute and a steady cadence",
        professional: "Zero fillers and a confident vocal pivot",
      },
    ],
  },
  {
    slug: "build_your_point",
    name: "Build Your Point",
    isMvp: false,
    tagline: "Coming after the MVP",
    description: "A later activity for structuring a single point before you say it.",
    cognitiveMechanism: "Point-first construction",
    prepDurationSeconds: 10,
    defaultDurationSeconds: 60,
    benefits: ["Clearer recommendations"],
    successMeasures: ["Point first", "Support", "Close"],
    rubrics: [],
  },
  {
    slug: "explain_it_simply",
    name: "Explain It Simply",
    isMvp: true,
    tagline: "Demystifying complexity for non-experts",
    description:
      "A topic and an audience appear. Explain it to that person. If the topic is unfamiliar, use the learn-more link first.",
    cognitiveMechanism: "Analogical reasoning and audience calibration",
    prepDurationSeconds: 5,
    defaultDurationSeconds: 60,
    benefits: ["Cross-functional leadership", "Deeper processing", "Less meeting friction"],
    successMeasures: ["Audience alignment", "Immediate engagement", "Time optimisation", "Linguistic fit"],
    rubrics: [
      {
        key: "persona_calibration",
        name: "Persona calibration",
        beginner: "Talks about yourself and misses the listener",
        intermediary: "Uses a relevant example, then slips into the wrong vocabulary",
        professional: "Vocabulary matches that person throughout",
      },
      {
        key: "time_to_value",
        name: "Time to value",
        beginner: "Spends 20+ seconds defining terms",
        intermediary: "Drops the first analogy around 15 to 20 seconds",
        professional: "Lands the core analogy within 7 seconds",
      },
      {
        key: "structural_output",
        name: "Structural output",
        beginner: "Uneven and cut off by the buzzer",
        intermediary: "Finishes on time but rushed",
        professional: "Hook, analogy, and conclusion",
      },
      {
        key: "linguistic_fit",
        name: "Linguistic fit",
        beginner: "Wordy, multi-clause sentences",
        intermediary: "Average sentence under 18 words",
        professional: "Average sentence under 12 words",
      },
    ],
  },
  {
    slug: "cut_it_in_half",
    name: "Cut It In Half",
    isMvp: true,
    tagline: "Clear, concise synthesis",
    description:
      "A long brief appears. You get time to read it, then you summarise it out loud.",
    cognitiveMechanism: "Information distillation and bottom-line-up-front delivery",
    prepDurationSeconds: 60,
    defaultDurationSeconds: 30,
    benefits: ["Forces synthesis", "Commands more authority", "Increases retention"],
    successMeasures: ["Rate compression", "Time to value", "Jargon mimicry"],
    rubrics: [
      {
        key: "rate_compression",
        name: "Rate compression",
        beginner: "Reduces the text by about 10 to 20 percent",
        intermediary: "Reduces the text by about 40 to 50 percent",
        professional: "Reduces the text by about 60 percent in punchy sentences",
      },
      {
        key: "time_to_value",
        name: "Time to value",
        beginner: "Main point lands in the last 10 seconds",
        intermediary: "Main point lands in the middle",
        professional: "Main point lands within the first 5 seconds",
      },
      {
        key: "jargon_mimicry",
        name: "Jargon mimicry",
        beginner: "High density of fillers and copied jargon",
        intermediary: "Controlled vocabulary",
        professional: "Paraphrased, with fillers gone",
      },
    ],
  },
  {
    slug: "vocabulary_upgrade",
    name: "Vocabulary Upgrade",
    isMvp: false,
    tagline: "Coming after the MVP",
    description: "A later activity for precise word choice. Complex vocabulary is not rewarded for its own sake.",
    cognitiveMechanism: "Precise word retrieval",
    prepDurationSeconds: 5,
    defaultDurationSeconds: 60,
    benefits: ["Clearer diction"],
    successMeasures: ["Precision", "Accessibility"],
    rubrics: [],
  },
  {
    slug: "storytelling_gym",
    name: "Storytelling Gym",
    isMvp: true,
    tagline: "Replace data dumps with a narrative",
    description: "A scenario appears. You have 60 seconds to tell it as a story with a point.",
    cognitiveMechanism: "Narrative arc, tension, and a landed lesson",
    prepDurationSeconds: 10,
    defaultDurationSeconds: 60,
    benefits: ["Higher message retention", "Drives action", "Relatable executive presence"],
    successMeasures: ["Structural architecture", "Tension and conflict", "Significance", "Speech and delivery"],
    rubrics: [
      {
        key: "structural_architecture",
        name: "Structural architecture",
        beginner: "Loose timeline with 40+ seconds of backstory",
        intermediary: "Three-part arc, about 20 seconds each",
        professional: "Balanced arc with 15 seconds left to land the point",
      },
      {
        key: "tension",
        name: "Tension and conflict",
        beginner: "Mentions the problem casually",
        intermediary: "Defines the roadblock",
        professional: "Raises the stakes to a systemic level",
      },
      {
        key: "significance",
        name: "Significance check",
        beginner: "Generic ending",
        intermediary: "A practical workplace lesson",
        professional: "A value, a metric, or a call to action",
      },
      {
        key: "speech_delivery",
        name: "Speech and delivery",
        beginner: "Many fillers and rushed sentences",
        intermediary: "Low fillers, controlled, slightly robotic",
        professional: "Zero fillers and intentional pauses",
      },
    ],
  },
  {
    slug: "one_minute_expert",
    name: "1 Minute Expert",
    isMvp: true,
    tagline: "Chunk a topic and sound ready",
    description: "You speak on a topic for 60 seconds: a hook, structured depth, and a conclusion.",
    cognitiveMechanism: "Categorical frameworks and an executive thesis",
    prepDurationSeconds: 5,
    defaultDurationSeconds: 60,
    benefits: ["Agility under a clock", "Perceived authority", "Less rambling"],
    successMeasures: ["The hook", "Information depth", "Time management"],
    rubrics: [
      {
        key: "hook",
        name: "The hook",
        beginner: "Defines the topic in a textbook way",
        intermediary: "Says why it matters today",
        professional: "Opens with a bold statement",
      },
      {
        key: "information_depth",
        name: "Information depth",
        beginner: "Lists disconnected facts",
        intermediary: "Groups facts into two clear points",
        professional: "Connects the topic to a wider impact or analogy",
      },
      {
        key: "time_management",
        name: "Time management",
        beginner: "Runs out around 40 seconds",
        intermediary: "Speaks for 60 seconds with a rushed ending",
        professional: "Concludes between 55 and 60 seconds",
      },
    ],
  },
  {
    slug: "debate_me",
    name: "Debate Me",
    isMvp: true,
    tagline: "Hold your ground when someone pushes back",
    description:
      "A stakeholder challenges you. You have 60 seconds to answer. The other side of the debate is played by the AI inside the Flutter app.",
    cognitiveMechanism: "Composure, power pauses, and counter-framing",
    prepDurationSeconds: 5,
    defaultDurationSeconds: 60,
    benefits: ["Mental agility", "Muscle memory under pressure"],
    successMeasures: ["Delivery", "Rhetorical integrity", "Perceived confidence"],
    rubrics: [
      {
        key: "delivery",
        name: "Delivery",
        beginner: "Rushing, thin breath, little awareness of pace",
        intermediary: "Less monotone, fewer fillers, answers the actual pushback",
        professional: "A 1 to 2 second power pause, steady pitch, no wasted words",
      },
      {
        key: "rhetorical_integrity",
        name: "Rhetorical integrity",
        beginner: "Filler-heavy and indirect",
        intermediary: "Answers the objection with limited fillers",
        professional: "Direct counter-frame and zero waste",
      },
      {
        key: "perceived_confidence",
        name: "Perceived confidence",
        beginner: "Sounds unsure or defensive",
        intermediary: "Sounds steady",
        professional: "Sounds authoritative without talking down",
      },
    ],
  },
  {
    slug: "listen_and_respond",
    name: "Listen and Respond",
    isMvp: false,
    tagline: "Coming after the MVP",
    description: "A later activity for active listening before you reply.",
    cognitiveMechanism: "Listening then responding",
    prepDurationSeconds: 0,
    defaultDurationSeconds: 60,
    benefits: ["Fewer misaligned replies"],
    successMeasures: ["Listening", "Response fit"],
    rubrics: [],
  },
  {
    slug: "conversation_flow",
    name: "Conversation Flow",
    isMvp: false,
    tagline: "Coming after the MVP",
    description: "A later activity for keeping a conversation moving.",
    cognitiveMechanism: "Turn-taking and transitions",
    prepDurationSeconds: 0,
    defaultDurationSeconds: 60,
    benefits: ["Smoother conversations"],
    successMeasures: ["Flow", "Turn balance"],
    rubrics: [],
  },
  {
    slug: "speak_up",
    name: "Speak Up",
    isMvp: false,
    tagline: "Coming after the MVP",
    description: "A later activity for saying the thing you have been holding back.",
    cognitiveMechanism: "Assertive initiation",
    prepDurationSeconds: 5,
    defaultDurationSeconds: 60,
    benefits: ["More voice in the room"],
    successMeasures: ["Initiation", "Clarity of ask"],
    rubrics: [],
  },
];

function p(entry) {
  return {
    title: null,
    secondaryText: null,
    tags: [],
    industries: ["general"],
    durationSeconds: 60,
    prepSeconds: 5,
    learnMoreUrl: null,
    learnMoreLabel: null,
    ...entry,
  };
}

const PROMPTS = [
  p({
    code: "tf_b_friday_calls",
    activitySlug: "think_fast",
    difficulty: "beginner",
    title: "Friday video calls",
    promptText: "Should companies completely ban video calls on Fridays? Why or why not?",
    objective: "Fill the silence and survive the clock with one clear view.",
    exemplarResponse:
      "Ban standing video calls on Fridays. People need one quiet day to finish work. Keep a single optional call for anything that truly cannot wait until Monday.",
    tags: ["workplace"],
    prepSeconds: 5,
  }),
  p({
    code: "tf_b_one_skill",
    activitySlug: "think_fast",
    difficulty: "beginner",
    title: "One skill tomorrow",
    promptText: "If you could instantly become an expert in any one skill tomorrow, what would it be and why?",
    objective: "Start speaking within a few seconds and give one reason.",
    exemplarResponse:
      "I would choose clear speaking. It is the skill that makes every other skill usable in a meeting, a pitch, and a hard conversation.",
    prepSeconds: 5,
  }),
  p({
    code: "tf_b_startup_or_giant",
    activitySlug: "think_fast",
    difficulty: "beginner",
    title: "Startup or multinational",
    promptText: "Is it better to work for a massive multinational or a 10-person startup at the beginning of your career?",
    objective: "Pick a side and give two short reasons.",
    exemplarResponse:
      "Start at the small company. You see the whole business, you get responsibility early, and you learn faster than you would in a narrow first role.",
    prepSeconds: 5,
  }),
  p({
    code: "tf_b_habit",
    activitySlug: "think_fast",
    difficulty: "beginner",
    title: "One productivity habit",
    promptText: "What is one everyday habit or tool that you believe drastically improves your productivity?",
    objective: "Name one habit and say why it works.",
    exemplarResponse:
      "Write the single outcome for the day before you open messages. It stops the inbox from choosing your work.",
    prepSeconds: 5,
  }),
  p({
    code: "tf_i_missed_deadline",
    activitySlug: "think_fast",
    difficulty: "intermediary",
    title: "Missed deadline",
    promptText:
      "Your team has missed a major project deadline due to a miscommunication. How do you explain this to your client without blaming your team?",
    objective: "Own the miss, state the new date, and keep trust.",
    exemplarResponse:
      "We missed Friday's delivery. The handoff inside our team was unclear, and that is on me. The revised delivery is Thursday at 2pm, and I will send a daily status until then.",
    tags: ["client"],
    industries: [
      "corporate_finance",
      "tech_product",
      "sales_marketing",
      "healthcare_edu",
    ],
    prepSeconds: 5,
  }),
  p({
    code: "tf_i_unexpected_question",
    activitySlug: "think_fast",
    difficulty: "intermediary",
    title: "Unexpected question in a meeting",
    promptText:
      "In a leadership meeting someone asks you a question you were not prepared for. How do you answer in the next 60 seconds without freezing or bluffing?",
    objective: "Buy a clean second, frame what you know, and commit to a follow-up.",
    exemplarResponse:
      "Good question. I do not have the exact number here. What I can say is the trend is up this month. I will confirm the figure and send it to the group within the hour.",
    prepSeconds: 5,
  }),
  p({
    code: "tf_i_bad_news",
    activitySlug: "think_fast",
    difficulty: "intermediary",
    title: "Share bad news upward",
    promptText:
      "You need to tell your manager that a key initiative will miss this month's target. How do you say it clearly without sounding defeated?",
    objective: "Lead with the bottom line, then the cause and the recovery plan.",
    exemplarResponse:
      "We will miss this month's target by about 12%. The main driver was a delayed vendor handoff. Here is the recovery: we resequence two items and I will update you Friday with a revised forecast.",
    prepSeconds: 5,
  }),
  p({
    code: "tf_i_interview_strength",
    activitySlug: "think_fast",
    difficulty: "intermediary",
    title: "Interview strength",
    promptText:
      "In a job interview they ask: 'What is your greatest professional strength?' Answer with one clear strength and a short proof story.",
    objective: "One strength, one proof, no laundry list.",
    exemplarResponse:
      "My strength is turning messy updates into decisions. Last quarter I cut our weekly status from 40 minutes to a five-minute brief with three asks, and approvals moved the same day.",
    prepSeconds: 5,
  }),
  p({
    code: "tf_i_colleague_disagrees",
    activitySlug: "think_fast",
    difficulty: "intermediary",
    title: "Colleague disagrees",
    promptText: "A colleague strongly disagrees with your project proposal in a meeting. How do you respond to them on the spot?",
    objective: "Acknowledge the point, then restate your recommendation.",
    exemplarResponse:
      "You are right that the timeline is tight. I still recommend we ship the smaller version on Friday, because waiting for the full scope misses the client's window.",
    prepSeconds: 5,
  }),
  p({
    code: "tf_i_no_budget",
    activitySlug: "think_fast",
    difficulty: "intermediary",
    title: "No development budget",
    promptText:
      "If a manager tells you, 'We don't have the budget for your professional development request this year,' how do you negotiate?",
    objective: "Ask for a smaller yes instead of arguing with the no.",
    exemplarResponse:
      "I understand the budget is closed. Could we approve one course this quarter and review a second one after the half-year numbers?",
    prepSeconds: 5,
  }),
  p({
    code: "tf_i_roi",
    activitySlug: "think_fast",
    difficulty: "intermediary",
    title: "Explain ROI",
    promptText: "How would you explain return on investment to a non-technical stakeholder?",
    objective: "Use a plain comparison, not a formula lecture.",
    exemplarResponse:
      "ROI asks a simple question: for every pound we put in, how many pounds come back? If we spend 10 and get 15, the return is worth doing.",
    learnMoreUrl: "https://www.investopedia.com/terms/r/returnoninvestment.asp",
    learnMoreLabel: "Read a plain definition of ROI",
    prepSeconds: 5,
  }),
  p({
    code: "tf_p_platform_down",
    activitySlug: "think_fast",
    difficulty: "professional",
    title: "Platform offline",
    promptText:
      "Our company's core software platform just went offline globally, and clients are panicking on social media. Give an immediate 60-second update to the board.",
    objective: "Lead with status, impact, and the next checkpoint.",
    exemplarResponse:
      "The platform is down worldwide as of 14:10 UTC. Customers cannot sign in. Engineering is rolling DNS back now. Next update is in 15 minutes. Social replies are pointing people to the status page.",
    industries: ["tech_product", "corporate_finance"],
    tags: ["crisis"],
    prepSeconds: 5,
  }),
  p({
    code: "tf_p_ai_advantage",
    activitySlug: "think_fast",
    difficulty: "professional",
    title: "New competitive advantage",
    promptText: "Artificial intelligence is rapidly commoditising our core service. What is our company's new competitive advantage?",
    objective: "Name one advantage that is hard to copy.",
    exemplarResponse:
      "The model is no longer the advantage. Our advantage is the client data we already hold and the people who know how to apply it in their industry. We sell that judgement, not the raw tool.",
    industries: ["tech_product", "corporate_finance", "sales_marketing"],
    prepSeconds: 5,
  }),
  p({
    code: "tf_p_speed_vs_data",
    activitySlug: "think_fast",
    difficulty: "professional",
    title: "Speed or perfect data",
    promptText: "In business, is it more dangerous to move too slowly with perfect data, or too quickly with flawed data?",
    objective: "Take a position and name the risk you accept.",
    exemplarResponse:
      "Moving too slowly is more dangerous when the market is shifting. I would move with flawed data on a small bet, and I would not bet the company until the numbers settle.",
    prepSeconds: 5,
  }),
  p({
    code: "tf_p_cheaper_competitor",
    activitySlug: "think_fast",
    difficulty: "professional",
    title: "Cheaper competitor",
    promptText:
      "Reframe this statement for the sales team: 'Our competitor's product is significantly cheaper than ours, so we are losing market share.'",
    objective: "Give the team a new line they can say tomorrow.",
    exemplarResponse:
      "We are not losing because we cost more. We are losing the deals where we talk about price first. Open with the outcome we deliver, then show why the cheaper option costs more later.",
    industries: ["sales_marketing"],
    tags: ["sales"],
    prepSeconds: 5,
  }),
  p({
    code: "tf_i_healthcare_handoff",
    activitySlug: "think_fast",
    difficulty: "intermediary",
    title: "Missed clinical handoff",
    promptText:
      "A colleague missed a patient handoff detail. How do you raise it on the spot without blaming them in front of the team?",
    objective: "Protect the patient and the relationship in one breath.",
    exemplarResponse:
      "Before we move on, I want to confirm the allergy note from the last shift. I will add it to the chart now so the next person has it.",
    industries: ["healthcare_edu"],
    tags: ["healthcare"],
    prepSeconds: 5,
  }),
  p({
    code: "tf_b_healthcare_patient",
    activitySlug: "think_fast",
    difficulty: "beginner",
    title: "Anxious patient",
    promptText: "A patient asks why their medication changed. Explain the next step in 60 seconds without alarming them.",
    objective: "Be clear, calm, and specific.",
    exemplarResponse:
      "Your doctor changed the dose because the last result was higher than we want. You start the new tablet tomorrow morning. If you feel dizzy, call the ward number on this card.",
    industries: ["healthcare_edu"],
    prepSeconds: 5,
  }),
  p({
    code: "tf_p_sales_hallway",
    activitySlug: "think_fast",
    difficulty: "professional",
    title: "Sixty seconds with a VP",
    promptText: "You have 60 seconds with a VP walking to their next meeting. Open the conversation so they agree to a proper call.",
    objective: "One outcome, one proof, one ask.",
    exemplarResponse:
      "Teams like yours lose about a week each quarter rewriting proposals. We cut that rewrite in half for a similar sales team. Can I have 15 minutes Thursday to show you the before and after?",
    industries: ["sales_marketing"],
    prepSeconds: 5,
  }),

  // Cut It In Half: promptText = PASSAGE to compress; exemplarResponse = short "must keep" brief.
  p({
    code: "cih_b_slack",
    activitySlug: "cut_it_in_half",
    difficulty: "beginner",
    title: "Slack after-hours policy",
    promptText:
      "Hey team, I just wanted to jump on here and let everyone know that we've been looking at how we manage our internal communications lately. It turns out that a lot of people are feeling pretty overwhelmed by the sheer volume of Slack messages flying around every day, especially after hours. Because of that, leadership has decided that starting next Monday, we are going to implement a new policy where no one is expected to reply to any Slack messages after 6:00 PM. We really want everyone to get some proper downtime so we can keep our productivity high during normal working hours.",
    objective: "Cut this message roughly in half. Lead with the policy.",
    exemplarResponse:
      "From Monday, nobody is expected to reply to Slack after 6pm. The aim is real downtime so daytime work stays focused.",
    tags: ["internal"],
    prepSeconds: 60,
    durationSeconds: 30,
  }),
  p({
    code: "cih_b_fire_alarm",
    activitySlug: "cut_it_in_half",
    difficulty: "beginner",
    title: "Office closed Friday",
    promptText:
      "Hi all, just a quick reminder that the office will be closed on Friday afternoon for the fire alarm upgrade. The contractors will be on site from 1pm, so everyone needs to leave the building by then. Please make sure you take your laptop home with you on Friday morning, because you won't be able to get back in until Monday. Thanks for your patience.",
    objective: "Cut this to the facts. Lead with what people must do.",
    exemplarResponse:
      "Office closed Friday from 1pm; take your laptop home; no access until Monday.",
    prepSeconds: 60,
    durationSeconds: 30,
  }),
  p({
    code: "cih_b_expenses_app",
    activitySlug: "cut_it_in_half",
    difficulty: "beginner",
    title: "New expenses system",
    promptText:
      "Hello team, from next month we are switching to a new expenses system. Instead of filling in the spreadsheet and emailing it to finance, you'll take a photo of your receipt in the app and submit it there. Training sessions are next Tuesday at 10am and 3pm — please join one of them. Old spreadsheet claims will not be accepted after the end of this month.",
    objective: "Cut this to the facts people need.",
    exemplarResponse:
      "Expenses move to the app next month; photo receipts only; join Tuesday training; spreadsheet claims stop end of month.",
    prepSeconds: 60,
    durationSeconds: 30,
  }),
  p({
    code: "cih_i_cac",
    activitySlug: "cut_it_in_half",
    difficulty: "intermediary",
    title: "Rising acquisition cost",
    promptText:
      "As we review our financial performance metrics for the third quarter of this fiscal year, the data indicates a highly concerning downward trend. Specifically, our customer acquisition costs have escalated by a significant 22% compared to the previous quarter, which is largely driven by increased ad bidding competition on our primary paid social media channels. Concurrently, our overall conversion rates have flattened out entirely. To address this widening margin gap, the marketing department needs to immediately pause all active top-of-funnel ad campaigns by Friday afternoon so we can reallocate our remaining budget into our high-performing email retention strategies.",
    objective: "Cut this by about half. Lead with the decision.",
    exemplarResponse:
      "Acquisition cost is up 22% and conversion is flat. Pause top-of-funnel ads by Friday and move the remaining budget into email retention.",
    industries: ["corporate_finance", "sales_marketing"],
    prepSeconds: 60,
    durationSeconds: 30,
  }),
  p({
    code: "cih_i_pipeline",
    activitySlug: "cut_it_in_half",
    difficulty: "intermediary",
    title: "Pipeline risk update",
    promptText:
      "I wanted to give everyone a bit of context on where we are with the Q4 pipeline before the forecast call. We've had a few deals slip, mainly because procurement on the buyer side has slowed, and two of our larger opportunities are now tracking into January rather than December. That said, the mid-market motion is healthy and we still have a path to land within five percent of target if we protect the three deals in verbal commit and stop discounting below the floor without approval. Can everyone please update Salesforce by Thursday noon so finance can lock the number?",
    objective: "Cut this to the risk and the ask.",
    exemplarResponse:
      "Two large deals slipped to January; mid-market is fine. Protect the three verbal commits, no discounts below floor without approval, and update Salesforce by Thursday noon.",
    industries: ["sales_marketing"],
    prepSeconds: 60,
    durationSeconds: 30,
  }),
  p({
    code: "cih_i_incident",
    activitySlug: "cut_it_in_half",
    difficulty: "intermediary",
    title: "Incident status note",
    promptText:
      "Just circling back on this morning's outage so everyone has the same story. Around 09:40 we saw elevated error rates on the checkout API after a config change went out. We rolled the change back at 10:05 and error rates returned to normal by 10:18. No customer payment data was exposed. We're writing a full postmortem and will share draft actions by tomorrow EOD. In the meantime please route any customer questions to the status page link rather than inventing timelines.",
    objective: "Cut this to status, impact, and next step.",
    exemplarResponse:
      "Checkout errors from a 09:40 config change; rolled back by 10:05; recovered 10:18; no payment data exposed. Postmortem draft tomorrow; point customers to the status page.",
    industries: ["tech_product"],
    prepSeconds: 60,
    durationSeconds: 30,
  }),
  p({
    code: "cih_i_ward_report",
    activitySlug: "cut_it_in_half",
    difficulty: "intermediary",
    title: "Ward handoff note",
    promptText:
      "So basically overnight the patient was a bit unsettled and we tried a few things and the observations were mostly okay but then towards morning the oxygen crept up a little and we called the doctor who said to continue and review later. Family were anxious at the bedside and we explained that stable does not mean going home today. Pain was managed with the usual dose and she took some breakfast. Please make sure the allergy note from last shift is still on the chart before the ward round.",
    objective: "Cut this handoff to status, change, and action.",
    exemplarResponse:
      "Overnight: restless, obs mostly stable; oxygen need rose toward morning — doctor said continue and review later. Allergy note must stay on the chart before ward round.",
    industries: ["healthcare_edu"],
    prepSeconds: 60,
    durationSeconds: 30,
  }),
  p({
    code: "cih_i_parent_note",
    activitySlug: "cut_it_in_half",
    difficulty: "intermediary",
    title: "School / clinic parent note",
    promptText:
      "Dear parents, I am writing to let you know that next Wednesday the clinic will run a short immunisation session in the hall between 9 and 11. Children who are due their booster will be seen first. Please bring the red book if you have it. If your child is unwell with a fever that morning, please do not bring them and call us to rebook. We will send a text confirmation the day before. Thank you for your help in keeping the queue moving.",
    objective: "Cut this to the facts parents need.",
    exemplarResponse:
      "Wednesday 9–11 immunisation session; bring the red book; stay home and rebook if fever; text confirmation the day before.",
    industries: ["healthcare_edu"],
    prepSeconds: 60,
    durationSeconds: 30,
  }),
  p({
    code: "cih_p_pricing",
    activitySlug: "cut_it_in_half",
    difficulty: "professional",
    title: "Pricing model shift",
    promptText:
      "In light of shifting macroeconomic tailwinds and aggressive market penetration by low-cost, decentralized competitors, our current enterprise SaaS monetization framework is experiencing unprecedented margin erosion. While our legacy client footprint remains relatively insulated due to multi-year contractual lock-ins, our net new logo acquisition velocity has decelerated by a critical margin. Consequently, cross-functional stakeholders must urgently initiate a comprehensive pricing restructuring paradigm. We need to transition from our traditional seat-based licensing model to a consumption-based utility model before the upcoming annual shareholder summit to safeguard our projected valuation targets.",
    objective: "Compress hard. Decision in the first five seconds.",
    exemplarResponse:
      "Switch new customers from seats to usage pricing before the shareholder meeting. Existing contracts stay. New-logo growth has slowed — usage pricing protects the valuation story.",
    industries: ["corporate_finance", "tech_product"],
    prepSeconds: 60,
    durationSeconds: 30,
  }),
  p({
    code: "cih_p_board_risk",
    activitySlug: "cut_it_in_half",
    difficulty: "professional",
    title: "Board risk paragraph",
    promptText:
      "Following an extensive review of our third-party vendor landscape and in light of recent regulatory guidance regarding operational resilience, the risk committee recommends that we accelerate the dual-sourcing programme for our two most critical payment processors. Although dual-sourcing introduces short-term cost and integration complexity, the concentration risk on a single provider is no longer acceptable given our transaction volume and the potential supervisory consequences of a prolonged outage. Management is asked to present a 90-day dual-sourcing plan at the next board meeting, including budget, owners, and exit criteria for the primary vendor dependency.",
    objective: "Board-ready brevity. Ask and deadline first.",
    exemplarResponse:
      "We need a 90-day dual-sourcing plan for our two critical payment processors at the next board. Single-provider concentration risk is no longer acceptable; short-term cost is worth the resilience.",
    industries: ["corporate_finance"],
    prepSeconds: 60,
    durationSeconds: 30,
  }),

  p({
    code: "ome_b_creator",
    activitySlug: "one_minute_expert",
    difficulty: "beginner",
    title: "The creator economy",
    promptText: "Explain why someone can make a full-time living on TikTok or YouTube.",
    objective: "Speak for the full minute without running out of things to say.",
    exemplarResponse:
      "Someone can make a full-time living on TikTok or YouTube because attention has value. First, a creator builds an audience by posting regularly. Brands and platforms pay for that attention through ads and sponsorships. Second, many creators sell their own products — courses, merch, memberships — once people already trust them. The job is not one viral video. It is showing up often enough that the audience stays, and turning that attention into income.",
    learnMoreUrl: "https://en.wikipedia.org/wiki/Creator_economy",
    learnMoreLabel: "Creator economy, in brief",
    industries: ["sales_marketing", "tech_product"],
    prepSeconds: 5,
  }),
  p({
    code: "ome_b_remote",
    activitySlug: "one_minute_expert",
    difficulty: "beginner",
    title: "Remote work",
    promptText: "Explain the number one benefit of working from home versus a physical office.",
    objective: "Stay talking until the minute is nearly done.",
    exemplarResponse:
      "The number one benefit of working from home is uninterrupted focus. In an office, people stop by your desk, meetings stack up, and the commute eats the start and end of the day. At home, that noise drops. You get longer stretches of deep work, and the hours you used to spend travelling go back into the actual job. For many roles, that focus is the real productivity gain — not the pyjamas.",
    industries: ["tech_product", "sales_marketing", "corporate_finance"],
    prepSeconds: 5,
  }),
  p({
    code: "ome_b_coffee",
    activitySlug: "one_minute_expert",
    difficulty: "beginner",
    title: "Coffee culture",
    promptText: "Explain why people are willing to pay £5 for a premium coffee instead of making it at home.",
    objective: "Keep going for 60 seconds with a simple structure.",
    exemplarResponse:
      "People pay five pounds for premium coffee because they are not only buying a drink. First, they are buying a pause — a small break before work or between meetings. Second, they are buying a place and a ritual: leaving the house, standing in a queue, starting the day in public. Home coffee is cheaper, but it does not give that reset. So the price is really for the experience around the cup, not just the caffeine.",
    industries: ["sales_marketing"],
    prepSeconds: 5,
  }),
  p({
    code: "ome_b_fitness",
    activitySlug: "one_minute_expert",
    difficulty: "beginner",
    title: "Consistency over intensity",
    promptText: "Explain why consistency matters more than intensity when starting a new workout routine.",
    objective: "Fill the minute with one idea, repeated clearly.",
    exemplarResponse:
      "Consistency matters more than intensity because the body changes from what you repeat, not from what you try once. A brutal workout you quit after a week leaves almost nothing behind. A moderate session you do three times a week becomes a habit, and the habit is what builds strength and fitness. When you start, the goal is not to impress yourself on day one. It is to still be training next month. Show up often, keep it doable, and intensity can grow later.",
    industries: ["sales_marketing"],
    prepSeconds: 5,
  }),
  p({
    code: "ome_i_automation",
    activitySlug: "one_minute_expert",
    difficulty: "intermediary",
    title: "Automation and augmentation",
    promptText: "Explain the difference between automation, which replaces tasks, and augmentation, which helps humans.",
    objective: "Use two clear buckets.",
    exemplarResponse:
      "Here is the difference that matters at work today. Automation takes a task off a person's plate — like software that sorts invoices so nobody types them by hand. Augmentation stays beside the person — like a tool that drafts options a doctor still chooses from. One removes work. The other improves the human decision. If you confuse them, you either fire the wrong people or you expect software to own judgment it should not own. So ask: are we replacing the task, or are we making the human better at it?",
    industries: ["tech_product"],
    learnMoreUrl: "https://en.wikipedia.org/wiki/Intelligence_amplification",
    learnMoreLabel: "Augmentation versus replacement",
    prepSeconds: 5,
  }),
  p({
    code: "ome_i_psych_safety",
    activitySlug: "one_minute_expert",
    difficulty: "intermediary",
    title: "Psychological safety",
    promptText: "Explain what psychological safety means in a team and why it prevents project failures.",
    objective: "Define it, then give two reasons it matters.",
    exemplarResponse:
      "Psychological safety means people can say 'this will fail' without being punished. Projects fail in silence. When bad news arrives early, the team can still change course — so safety is about catching problems in time, not about being soft.",
    learnMoreUrl: "https://en.wikipedia.org/wiki/Psychological_safety",
    learnMoreLabel: "What psychological safety means",
    // People / product leadership — not Corporate & Finance catalog.
    industries: ["tech_product", "sales_marketing"],
    prepSeconds: 5,
  }),
  p({
    code: "ome_i_pmf",
    activitySlug: "one_minute_expert",
    difficulty: "intermediary",
    title: "Product-market fit",
    promptText: "Explain product-market fit to a non-technical stakeholder.",
    objective: "Two points and a takeaway, no jargon pile-up.",
    exemplarResponse:
      "Product-market fit means the people you built for keep coming back without being pushed. Why that matters today: until you have it, ads and sales mostly buy noise, not loyalty. Two simple checks. First, do customers return on their own and tell others, or do you chase them every week with discounts and reminders? Second, if you raise the price a little, do they stay — or vanish? If you still have to beg them to care, you do not have fit yet. You have a product looking for a market. The takeaway for any stakeholder: prove pull before you scale push. Talk to the few who already need this, tighten the offer until they pull, then spend to grow. Fit first. Scale second.",
    learnMoreUrl: "https://en.wikipedia.org/wiki/Product-market_fit",
    learnMoreLabel: "Product-market fit",
    industries: ["tech_product", "sales_marketing"],
    prepSeconds: 5,
  }),
  p({
    code: "ome_i_wrong_metric",
    activitySlug: "one_minute_expert",
    difficulty: "intermediary",
    title: "The wrong metric",
    promptText: "Explain why tracking the wrong KPI can ruin a finance or ops strategy.",
    objective: "One example, two points.",
    exemplarResponse:
      "Tracking the wrong KPI can ruin a strategy because the metric you reward is the behaviour you get. Take a simple example: a team only tracks cost cuts and ignores cash conversion. The P&L looks tidy while working capital blows up — stock rises, customers pay late, and cash quietly disappears. Two points. First, a good-looking number can hide a broken process. Second, people will game whatever you put on the dashboard. So pick the outcome you actually want — cash, quality, retention — then pick the number that forces that behaviour. Wrong scoreboard, wrong game.",
    industries: ["corporate_finance"],
    prepSeconds: 5,
  }),
  p({
    code: "ome_b_ebitda",
    activitySlug: "one_minute_expert",
    difficulty: "beginner",
    title: "EBITDA in plain English",
    promptText: "Explain what EBITDA means to a smart colleague who is not in finance.",
    objective: "One clear definition, then why leaders still look at it.",
    exemplarResponse:
      "EBITDA is a rough view of operating profit before interest, tax, and the accounting for assets wearing out. In plain English: how is the core business performing before financing and tax choices cloud the picture? Leaders still look at it for two reasons. First, it helps compare companies or years without those extras in the way. Second, it is a common language with investors and boards. It is not cash in the bank, and it is not the whole story — but it is a fast way to ask: is the underlying business healthy?",
    industries: ["corporate_finance"],
    prepSeconds: 5,
  }),
  p({
    code: "ome_b_runway",
    activitySlug: "one_minute_expert",
    difficulty: "beginner",
    title: "Cash runway",
    promptText: "Explain what cash runway means and why a CFO watches it weekly.",
    objective: "Define it, then give one risk if you ignore it.",
    exemplarResponse:
      "Cash runway is how many months you can keep operating with the cash you have at today's burn rate. If you have six months of cash and you spend the same each month, your runway is six months. CFOs watch it weekly because a surprise spike in hiring, ads, or suppliers can cut months off the plan before the next board meeting notices. Ignore runway and you can look busy and growing while quietly running out of time to raise money or cut costs. So runway is not a finance curiosity — it is the survival clock.",
    industries: ["corporate_finance"],
    prepSeconds: 5,
  }),
  p({
    code: "ome_i_working_capital",
    activitySlug: "one_minute_expert",
    difficulty: "intermediary",
    title: "Working capital",
    promptText: "Explain working capital to a non-finance stakeholder and why it can kill a profitable company.",
    objective: "Define it, then one concrete risk.",
    exemplarResponse:
      "Working capital is the cash tied up in day-to-day operations — stock on shelves, invoices customers have not paid yet, and bills you still owe suppliers. Why it matters: a company can show profit on paper and still run out of cash. Imagine sales look strong, but customers pay in sixty days while suppliers demand payment in fourteen. Profit is booked; cash is gone. That gap is how profitable companies die. So when someone says 'we are making money,' also ask: when does the cash actually arrive, and can we fund the wait?",
    industries: ["corporate_finance"],
    prepSeconds: 5,
  }),
  p({
    code: "ome_i_capex_opex",
    activitySlug: "one_minute_expert",
    difficulty: "intermediary",
    title: "CapEx versus OpEx",
    promptText: "Explain the difference between CapEx and OpEx as if you are briefing a budget owner.",
    objective: "Two buckets, one decision implication.",
    exemplarResponse:
      "Think of two budget buckets. CapEx is money spent to buy or build an asset that lasts years — systems, equipment, office fit-out. OpEx is the ongoing cost of running the business this year — salaries, software subscriptions, marketing. Why the split matters for a budget owner: CapEx usually hits the balance sheet and is spread over time; OpEx hits this year's P&L and can make the year look worse even when the investment is right. Before you approve spend, ask which bucket it sits in, and what story that creates for finance and the board. Same pound, different reporting — and different decision pressure.",
    industries: ["corporate_finance"],
    prepSeconds: 5,
  }),
  p({
    code: "ome_p_attention",
    activitySlug: "one_minute_expert",
    difficulty: "professional",
    title: "The attention economy",
    promptText: "Explain how human focus has become a valuable economic commodity. Open with a bold claim.",
    objective: "Executive thesis, then a punchy close before 60 seconds.",
    exemplarResponse:
      "Attention is the product. The apps are just the mines. Whoever holds someone's focus can sell that focus — to advertisers, to platforms, to their own upsell. That is why human attention became an economic commodity: minutes are scarce, and every company is competing for the same scarce minutes. Think of a city with one busy street corner; every shop wants the town crier pointing at them. The systemic point is simple: product quality still matters, but distribution now means winning focus first. Close with this: if you cannot hold attention, you cannot sell anything else.",
    prepSeconds: 5,
  }),
  p({
    code: "ome_p_deglobal",
    activitySlug: "one_minute_expert",
    difficulty: "professional",
    title: "De-globalisation",
    promptText: "Explain why supply chains are shifting away from global efficiency toward local resilience.",
    objective: "A thesis, a systemic point, and a close.",
    exemplarResponse:
      "Cheap and far used to win. One blocked port proved that cheap and far can also stop the business overnight. That is why supply chains are shifting from pure global efficiency toward local resilience. The systemic point: a late product often costs more than a higher unit price — lost sales, idle factories, angry customers, and emergency air freight. So companies are paying more to source closer, hold buffer stock, and dual-source critical parts. Efficiency optimised for peacetime. Resilience is the insurance premium for a brittle world. Close: the winning chain is not the cheapest — it is the one that still delivers when the map breaks.",
    industries: ["corporate_finance", "tech_product"],
    prepSeconds: 5,
  }),
  p({
    code: "ome_p_paradox",
    activitySlug: "one_minute_expert",
    difficulty: "professional",
    title: "The paradox of choice",
    promptText: "Explain why giving a customer more options can decrease sales conversion.",
    objective: "Bold open, one mechanism, a close.",
    exemplarResponse:
      "More options feel helpful and often freeze the buyer. That is the paradox of choice: adding choices can decrease conversion. The mechanism is simple. When every option looks reasonable, choosing feels risky — people fear picking wrong, so they delay or leave. Cognitive load rises; the next step stops being obvious. A shorter menu, a recommended default, or a guided path reduces that fear and makes action easy. Analogy: a restaurant with three clear dishes sells faster than one with forty near-identical plates. Close: if you want more sales, do not only add options — remove the ones that create hesitation.",
    industries: ["sales_marketing"],
    learnMoreUrl: "https://en.wikipedia.org/wiki/The_Paradox_of_Choice",
    learnMoreLabel: "Paradox of choice",
    prepSeconds: 5,
  }),
  p({
    code: "ome_p_disruption",
    activitySlug: "one_minute_expert",
    difficulty: "professional",
    title: "Legacy versus agility",
    promptText: "Explain why massive, well-funded companies often get disrupted by tiny, cash-poor startups.",
    objective: "Reframe the topic as an executive thesis.",
    exemplarResponse:
      "Massive, well-funded companies get disrupted because they are protecting a machine that already prints money. Every change threatens today's revenue, today's margins, today's org chart. The tiny startup has nothing to protect, so it can change the offer every week and learn in public. Funding does not beat a shorter decision cycle. The systemic point: incumbents optimise for continuity; disruptors optimise for learning speed. Cash buys time, but it also buys bureaucracy. Close with this: the giant dies slowly when 'we cannot risk the core' becomes the loudest voice in the room — and the startup wins by shipping while that meeting is still booking.",
    industries: ["corporate_finance", "tech_product"],
    prepSeconds: 5,
  }),

  p({
    code: "eis_b_inflation",
    activitySlug: "explain_it_simply",
    difficulty: "beginner",
    title: "Inflation to a student",
    promptText: "Explain inflation to a high-school student wondering why their favourite snack just got more expensive.",
    objective: "Conversational tone. No lecture.",
    exemplarResponse:
      "The same coins buy less snack than last year. Shops pay more for ingredients and energy, so the price on the shelf goes up. That rise in everyday prices is inflation.",
    learnMoreUrl: "https://en.wikipedia.org/wiki/Inflation",
    learnMoreLabel: "Inflation in plain terms",
    prepSeconds: 5,
  }),
  p({
    code: "eis_b_job_child",
    activitySlug: "explain_it_simply",
    difficulty: "beginner",
    title: "Your job to a child",
    promptText: 'Explain your job to a 5-year-old who asks, "What do you actually do all day at your desk?"',
    objective: "Sound like a person, not a job description.",
    exemplarResponse:
      "I help a team decide what to do next. I listen, I write the plan so nobody gets confused, and I check that we finished what we promised.",
    prepSeconds: 5,
  }),
  p({
    code: "eis_b_ecommerce",
    activitySlug: "explain_it_simply",
    difficulty: "beginner",
    title: "Ecommerce to a blacksmith",
    promptText: "Explain ecommerce to a medieval blacksmith who has magically travelled to the present day.",
    objective: "Use his world as the picture.",
    exemplarResponse:
      "Imagine the market square is open all night, and the stall is a page people visit from their homes. They point at the horseshoe, pay, and a rider brings it to their door.",
    prepSeconds: 5,
  }),
  p({
    code: "eis_i_seo_chef",
    activitySlug: "explain_it_simply",
    difficulty: "intermediary",
    title: "SEO to a chef",
    promptText: "Explain search engine optimisation to a traditional chef who wants more local customers in their bakery.",
    objective: "Anchor it with an analogy from their street.",
    exemplarResponse:
      "When someone nearby searches 'fresh bread', Google is the person on the corner giving directions. SEO is making your shop the clearest answer: the right name, the right street, and proof that people like what you bake.",
    learnMoreUrl: "https://developers.google.com/search/docs/fundamentals/seo-starter-guide",
    learnMoreLabel: "Search essentials",
    industries: ["sales_marketing"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_i_privacy",
    activitySlug: "explain_it_simply",
    difficulty: "intermediary",
    title: "Data privacy to a shop assistant",
    promptText: 'Explain data privacy to a retail shop assistant who wants to know why websites keep asking them to "Accept all".',
    objective: "Analogy first, then why it matters to them.",
    exemplarResponse:
      "Accept all is like letting a stranger copy your till receipts, your usual bus route, and what you almost bought. The site wants that trail so it can follow you with adverts. You can say no to the extra copying.",
    learnMoreUrl: "https://www.ncsc.gov.uk/collection/device-security-guidance/glossary",
    learnMoreLabel: "Why sites ask for consent",
    prepSeconds: 5,
  }),
  p({
    code: "eis_i_cloud_parent",
    activitySlug: "explain_it_simply",
    difficulty: "intermediary",
    title: "The cloud to a parent",
    promptText:
      "Explain 'the cloud' to a parent who thinks it means their photos are floating in the sky.",
    objective: "Friendly analogy. No jargon pile-up.",
    exemplarResponse:
      "The cloud is just someone else's computer, kept safe in a big building. When you save a photo there, it lives on that computer so you can open it from your phone or laptop. It is storage with a login, not weather.",
    industries: ["tech_product"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_i_api_waiter",
    activitySlug: "explain_it_simply",
    difficulty: "intermediary",
    title: "APIs to a restaurant manager",
    promptText:
      "Explain what an API is to a restaurant manager who has never written code.",
    objective: "Use the restaurant as the picture.",
    exemplarResponse:
      "An API is the waiter between the kitchen and the dining room. Guests do not walk into the kitchen; they ask through the waiter, get a clear answer, and the kitchen stays organised. Software apps talk to each other the same way.",
    industries: ["tech_product"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_i_brand_neighbour",
    activitySlug: "explain_it_simply",
    difficulty: "intermediary",
    title: "Brand to a neighbour",
    promptText:
      "Explain what a brand is to a neighbour who thinks it only means a logo on a bag.",
    objective: "Simple, human, one clear takeaway.",
    exemplarResponse:
      "A brand is the promise people remember when they hear your name. The logo is just the badge. If every visit feels reliable and a bit special, that feeling is the brand — and it is why they come back.",
    industries: ["sales_marketing"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_i_cashflow_friend",
    activitySlug: "explain_it_simply",
    difficulty: "intermediary",
    title: "Cash flow to a friend",
    promptText:
      "Explain cash flow to a friend who runs a small shop and mixes up profit with money in the till.",
    objective: "One analogy, then why it can sink a busy shop.",
    exemplarResponse:
      "Profit is the score on paper. Cash flow is whether the till has money today. You can look profitable and still run dry if customers pay late while you pay suppliers now. Watch the till, not only the score.",
    industries: ["corporate_finance"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_i_vaccine_uncle",
    activitySlug: "explain_it_simply",
    difficulty: "intermediary",
    title: "Vaccines to an uncle",
    promptText:
      "Explain how a vaccine works to an uncle who is curious but nervous about 'putting something in his body'.",
    objective: "Calm, clear, no scare tactics.",
    exemplarResponse:
      "A vaccine is a practice round for your immune system. It shows a safe copy of the threat so your body learns the shape. Later, if the real thing shows up, your body already knows how to fight it faster.",
    industries: ["healthcare_edu"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_i_triage_patient",
    activitySlug: "explain_it_simply",
    difficulty: "intermediary",
    title: "Triage to a worried patient",
    promptText:
      "Explain triage to a patient in A&E who thinks waiting means the staff are ignoring them.",
    objective: "Calm, respectful, clear priority logic.",
    exemplarResponse:
      "Triage is sorting by urgency, not by who arrived first. Someone struggling to breathe goes ahead of a sprained ankle even if they walked in later. Waiting does not mean you do not matter — it means others need help right now to stay safe.",
    industries: ["healthcare_edu"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_i_antibiotics_parent",
    activitySlug: "explain_it_simply",
    difficulty: "intermediary",
    title: "Antibiotics to a parent",
    promptText:
      "Explain why antibiotics will not help a viral cold to a parent who wants a prescription 'just in case'.",
    objective: "Firm but kind. One clear reason.",
    exemplarResponse:
      "Antibiotics kill bacteria, not viruses. A typical cold is viral, so the medicine will not shorten it — and using it when it is not needed makes future infections harder to treat. Rest, fluids, and time are the real treatment here.",
    industries: ["healthcare_edu"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_i_consent_teen",
    activitySlug: "explain_it_simply",
    difficulty: "intermediary",
    title: "Informed consent to a teen",
    promptText:
      "Explain informed consent to a teenager about to have a minor procedure who just wants it 'over with'.",
    objective: "Respect autonomy without sounding like a lecture.",
    exemplarResponse:
      "Informed consent means you understand what will happen, what could go wrong, and what the choices are — then you say yes. It is not a formality. It is you staying in charge of your body while we do the work safely.",
    industries: ["healthcare_edu"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_i_funnel_coach",
    activitySlug: "explain_it_simply",
    difficulty: "intermediary",
    title: "Sales funnel to a sports coach",
    promptText:
      "Explain a sales funnel to a youth sports coach who only knows try-outs and match day.",
    objective: "Map it to their season language.",
    exemplarResponse:
      "A sales funnel is like your season path: many kids hear about the club, fewer come to try-outs, fewer still make the squad, and a small group play match day. Each step narrows. Marketing fills the top; closing is match day.",
    industries: ["sales_marketing"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_i_margin_baker",
    activitySlug: "explain_it_simply",
    difficulty: "intermediary",
    title: "Gross margin to a baker",
    promptText:
      "Explain gross margin to a baker who knows flour costs but not finance words.",
    objective: "Kitchen maths, not spreadsheet talk.",
    exemplarResponse:
      "Gross margin is what is left from the loaf price after you pay for flour, butter, and packaging — before rent and wages. If that slice is too thin, no amount of busy weekends will save the shop.",
    industries: ["corporate_finance", "sales_marketing"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_p_quantum",
    activitySlug: "explain_it_simply",
    difficulty: "professional",
    title: "Quantum computing to a sales director",
    promptText: "Explain quantum computing to a busy sales director who only cares about speed, revenue, and things that work right now.",
    objective: "Say why it matters to that person within a few seconds.",
    exemplarResponse:
      "It will not change your quarter. It is a new kind of machine that can try a huge number of routes at once. The revenue story later is faster discovery in drugs, materials, and logistics. For this year, treat it as a watch item, not a pitch.",
    learnMoreUrl: "https://en.wikipedia.org/wiki/Quantum_computing",
    learnMoreLabel: "Quantum computing overview",
    industries: ["tech_product", "sales_marketing"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_p_ml_historian",
    activitySlug: "explain_it_simply",
    difficulty: "professional",
    title: "Machine learning to a historian",
    promptText: "Explain machine learning to a historian of ancient civilisations who is sceptical of technology.",
    objective: "Use their world, and say why the idea still matters to them.",
    exemplarResponse:
      "It is pattern-spotting at a scale no scribe could manage. You still decide what the pattern means. The machine only notices that these shards, these words, or these records keep showing up together.",
    learnMoreUrl: "https://en.wikipedia.org/wiki/Machine_learning",
    learnMoreLabel: "Machine learning, the idea",
    industries: ["tech_product", "healthcare_edu"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_p_irr_board",
    activitySlug: "explain_it_simply",
    difficulty: "professional",
    title: "IRR to a non-finance board member",
    promptText:
      "Explain internal rate of return (IRR) to a board member who is strong on the business but not on finance jargon.",
    objective: "Plain language, one decision they can take from it.",
    exemplarResponse:
      "IRR is the growth rate that makes an investment's cash in and cash out balance. If two projects need the same money, the higher IRR is usually the better use of cash — unless the risk or timing is worse.",
    industries: ["corporate_finance"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_p_latency_ops",
    activitySlug: "explain_it_simply",
    difficulty: "professional",
    title: "Latency to an ops lead",
    promptText:
      "Explain latency to an operations lead who keeps asking why the app 'feels slow' even when servers are up.",
    objective: "Business impact in the first sentence.",
    exemplarResponse:
      "Latency is the wait between tap and result. Uptime means the system is alive; latency means it is useful. A shop that is open but makes every customer queue for thirty seconds still loses sales.",
    industries: ["tech_product", "corporate_finance"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_p_nps_ward",
    activitySlug: "explain_it_simply",
    difficulty: "professional",
    title: "NPS to a ward manager",
    promptText:
      "Explain Net Promoter Score to a hospital ward manager who is tired of survey jargon.",
    objective: "Make it operational, not corporate.",
    exemplarResponse:
      "NPS asks one thing: would you recommend us? Promoters pull others in; detractors warn them away. For a ward, it is a simple pulse on whether patients leave telling a good story or a warning.",
    industries: ["healthcare_edu"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_b_wifi_grandma",
    activitySlug: "explain_it_simply",
    difficulty: "beginner",
    title: "Wi‑Fi to a grandparent",
    promptText:
      "Explain Wi‑Fi to a grandparent who keeps asking why the internet works in the garden but not in the bathroom.",
    objective: "Warm and simple. One picture.",
    exemplarResponse:
      "Wi‑Fi is an invisible radio signal from a small box in your house. Walls and distance weaken it, so the garden might catch it while the bathroom does not. It is not magic — it is a signal with a limited reach.",
    prepSeconds: 5,
  }),
  p({
    code: "eis_b_password_teen",
    activitySlug: "explain_it_simply",
    difficulty: "beginner",
    title: "Strong passwords to a teen",
    promptText:
      "Explain why a strong password matters to a teenager who uses the same word for every app.",
    objective: "One clear risk, no lecture tone.",
    exemplarResponse:
      "If one site gets hacked and you reused the same password, thieves can walk into your email and games too. A unique password is a different key for every door — so one broken lock does not open the whole house.",
    prepSeconds: 5,
  }),

  p({
    code: "stg_b_morning",
    activitySlug: "storytelling_gym",
    difficulty: "beginner",
    title: "Morning disaster",
    promptText:
      "Tell a 60-second story about a time an unexpected morning disaster completely derailed your schedule, and how you recovered.",
    objective: "Use a simple three-part story.",
    exemplarResponse:
      "I had a 9am client pitch. At 8:15 my coffee went down my shirt and the train was cancelled. I bought a shirt, joined from the taxi, and we still closed. The lesson was that the recovery is the part people remember.",
    prepSeconds: 10,
  }),
  p({
    code: "stg_i_skeptic",
    activitySlug: "storytelling_gym",
    difficulty: "intermediary",
    title: "Sceptical stakeholder",
    promptText:
      "Describe a situation where a difficult client was highly sceptical of your proposal, and how you shifted their perspective.",
    objective: "Setup, tension, and a workplace lesson, evenly paced.",
    exemplarResponse:
      "The client had been burned by a late launch the year before. They folded their arms at the timeline. I showed the two risks that had caused the last delay and the owner of each one this time. They approved a smaller first release. Scepticism dropped when the risk had a name.",
    industries: ["sales_marketing", "corporate_finance", "tech_product"],
    prepSeconds: 10,
  }),
  p({
    code: "stg_p_agile",
    activitySlug: "storytelling_gym",
    difficulty: "professional",
    title: "From hierarchy to autonomy",
    promptText:
      "You are shifting the company from a traditional hierarchy to a more autonomous model. Tell a story that helps long-serving employees accept the friction of that change.",
    objective: "Land a strategic point, not a generic ending.",
    exemplarResponse:
      "For years, every decision waited in one office. That felt safe, and it also made us late. Last quarter a team shipped a fix in two days because they did not wait for a committee. The friction is real. The point is that speed now belongs to the people closest to the customer.",
    industries: ["corporate_finance", "tech_product"],
    prepSeconds: 10,
  }),
  p({
    code: "stg_i_healthcare",
    activitySlug: "storytelling_gym",
    difficulty: "intermediary",
    title: "A ward story with a point",
    promptText:
      "Tell a 60-second story about a moment when clearer communication changed a patient's outcome or a family's trust.",
    objective: "Three parts, and a practical lesson for the ward.",
    exemplarResponse:
      "A family thought 'stable' meant 'going home today'. They were angry by the afternoon. I sat down, said stable means not getting worse, and named the one result we still needed. The anger dropped. The lesson was to translate the word before we leave the room.",
    industries: ["healthcare_edu"],
    prepSeconds: 10,
  }),

  p({
    code: "ctd_i_garden_vc",
    activitySlug: "connect_the_dots",
    difficulty: "intermediary",
    title: "Winter gardening and venture capital",
    promptText: "Connect gardening in winter with venture capital investing.",
    secondaryText: "Concept A: Gardening in winter. Concept B: Venture capital investing.",
    objective: "Build a logical link by about the 30 second mark.",
    exemplarResponse:
      "Winter gardening looks dead, but the roots are doing the work. Venture investing in a quiet market is the same. You are funding the roots, not the blossom you can already see.",
    tags: ["metaphor"],
    prepSeconds: 5,
  }),
  p({
    code: "ctd_i_blueprints",
    activitySlug: "connect_the_dots",
    difficulty: "intermediary",
    title: "Blueprints and culture",
    promptText: "Connect architectural blueprints with a corporate culture change.",
    secondaryText: "Concept A: Architectural blueprints. Concept B: Corporate culture transformation.",
    objective: "Use a transition phrase and give both ideas real time.",
    exemplarResponse:
      "A blueprint shows the walls before anyone picks up a hammer. A culture change needs the same drawing: who decides, who speaks, and what good looks like, before you ask people to behave differently.",
    prepSeconds: 5,
  }),
  p({
    code: "ctd_p_chess_ai",
    activitySlug: "connect_the_dots",
    difficulty: "professional",
    title: "Chess and AI ethics",
    promptText: "Connect a game of chess with artificial intelligence ethics.",
    secondaryText: "Concept A: Playing chess. Concept B: Artificial intelligence ethics.",
    objective: "Make the link feel natural.",
    exemplarResponse:
      "In chess, the danger is not the next move. It is the move that move allows. AI ethics is the same board: a harmless feature can set up a later harm, so you judge the position, not only the piece you just played.",
    industries: ["tech_product"],
    prepSeconds: 5,
  }),
  p({
    code: "ctd_p_interest_rates",
    activitySlug: "connect_the_dots",
    difficulty: "professional",
    title: "Interest rates and hiring freezes",
    promptText: "Connect rising interest rates with a company-wide hiring freeze.",
    secondaryText: "Concept A: Rising interest rates. Concept B: A hiring freeze.",
    objective: "Make the cash / cost link explicit by mid-answer.",
    exemplarResponse:
      "When money gets more expensive, debt and growth plans both cost more. A hiring freeze is the same pressure inside the firm: you protect cash now so the balance sheet can live with a higher cost of capital.",
    industries: ["corporate_finance"],
    prepSeconds: 5,
  }),
  p({
    code: "ctd_i_storm",
    activitySlug: "connect_the_dots",
    difficulty: "intermediary",
    title: "Thunderstorm and markets",
    promptText: "Connect a severe thunderstorm with a microeconomic market disruption.",
    secondaryText: "Concept A: A severe thunderstorm. Concept B: Microeconomic market disruption.",
    objective: "Transition without a jarring jump.",
    exemplarResponse:
      "A storm does not argue with your plans. It just removes the road. A sudden price shock does the same to a market: supply, demand, and timing all move at once, and the old route is gone.",
    industries: ["corporate_finance"],
    prepSeconds: 5,
  }),
  p({
    code: "ctd_b_coffee_sales",
    activitySlug: "connect_the_dots",
    difficulty: "beginner",
    title: "Broken coffee machine and Q4",
    promptText: "Connect a broken coffee machine with your Q4 sales strategy. Speak for the full minute.",
    secondaryText: "Concept A: A broken coffee machine. Concept B: Our Q4 sales strategy.",
    objective: "Do not freeze. Keep fillers low and keep talking.",
    exemplarResponse:
      "A broken coffee machine ruins the morning because everyone assumed it would work. A Q4 plan fails the same way if the pipeline was never real. Check the machine before you promise the cups.",
    industries: ["sales_marketing"],
    prepSeconds: 5,
  }),
  p({
    code: "ctd_b_flight",
    activitySlug: "connect_the_dots",
    difficulty: "beginner",
    title: "Delayed flight and clients",
    promptText: "Connect a delayed flight with managing client expectations.",
    secondaryText: "Concept A: A delayed flight. Concept B: Managing client expectations.",
    objective: "Speak for 60 seconds and make any link you can defend.",
    exemplarResponse:
      "The worst part of a delay is silence from the gate. Clients feel the same when a date slips and nobody says so. Early news is the difference between annoyance and distrust.",
    prepSeconds: 5,
  }),
  p({
    code: "ctd_i_furniture",
    activitySlug: "connect_the_dots",
    difficulty: "intermediary",
    title: "Flat-pack and onboarding",
    promptText: "Connect assembling flat-pack furniture with onboarding a new employee.",
    secondaryText: "Concept A: Assembling flat-pack furniture. Concept B: Onboarding a new employee.",
    objective: "Transition with a clear phrase around the middle.",
    exemplarResponse:
      "Flat-pack fails when the instructions skip a step and you notice at the end. Onboarding fails the same way. This directly mirrors that: name the parts, the order, and who to ask before the new person is already stuck.",
    prepSeconds: 5,
  }),
  p({
    code: "ctd_b_shoelace",
    activitySlug: "connect_the_dots",
    difficulty: "beginner",
    title: "Shoelace and a bug",
    promptText: "Connect an untied shoelace with a software bug.",
    secondaryText: "Concept A: An untied shoelace. Concept B: A software bug.",
    objective: "Keep talking for the full minute.",
    exemplarResponse:
      "An untied lace is small until you trip in front of everyone. A small bug is the same. Ignore it on a quiet path and it becomes the thing that stops the release.",
    industries: ["tech_product"],
    prepSeconds: 5,
  }),
  p({
    code: "ctd_i_healthcare",
    activitySlug: "connect_the_dots",
    difficulty: "intermediary",
    title: "A triage queue and a product backlog",
    promptText: "Connect a hospital triage queue with a product backlog.",
    secondaryText: "Concept A: A hospital triage queue. Concept B: A product backlog.",
    objective: "Apply the lesson of the first idea to the second.",
    exemplarResponse:
      "Triage is not a waiting list of equal items. The chest pain jumps the queue. A backlog should work the same way: severity and time-sensitivity decide the order, not who shouted last.",
    industries: ["healthcare_edu", "tech_product"],
    prepSeconds: 5,
  }),

  p({
    code: "deb_b_office",
    activitySlug: "debate_me",
    difficulty: "beginner",
    title: "Five days in the office",
    promptText:
      "Act as a friendly colleague. Debate why working from the office five days a week is better than working from home. Push back gently when I give my reasons.",
    objective: "Do not rush. Breathe, then give your view.",
    exemplarResponse:
      "I like seeing people, and I still think five mandatory days confuses presence with output. Let us pick two days that are actually for collaboration and protect the rest for focused work.",
    prepSeconds: 5,
  }),
  p({
    code: "deb_b_staycation",
    activitySlug: "debate_me",
    difficulty: "beginner",
    title: "Staycation",
    promptText: "Act as a family member. Debate why a staycation is better than an expensive holiday abroad this year.",
    objective: "Stay calm and answer the pushback.",
    exemplarResponse:
      "I hear that everyone else is going away. This year I would rather have a rested week and money left in the account than a trip we spend the autumn paying for.",
    prepSeconds: 5,
  }),
  p({
    code: "deb_i_deadline",
    activitySlug: "debate_me",
    difficulty: "intermediary",
    title: "Deadline extension",
    promptText:
      "Act as a strict project manager. Debate my request to extend a project deadline by two weeks. Question my time management and demand justification.",
    objective: "Answer the challenge without going flat or defensive.",
    exemplarResponse:
      "The extra two weeks are not for the original scope. A dependency slipped by six working days. I can deliver the agreed scope on the original date if we cut the two items we added last Tuesday.",
    industries: ["tech_product", "corporate_finance", "healthcare_edu"],
    prepSeconds: 5,
  }),
  p({
    code: "deb_i_refund",
    activitySlug: "debate_me",
    difficulty: "intermediary",
    title: "Refund demand",
    promptText:
      "Act as an assertive customer. Debate why your subscription should be fully refunded, claiming the product did not live up to expectations. Do not accept simple answers.",
    objective: "Listen, then answer the actual claim.",
    exemplarResponse:
      "I am sorry it felt short of what you expected. A full refund applies when the service was unavailable. What you described is the plan working, but not the outcome you wanted. I can offer the unused month back, or a working session to get you to that outcome.",
    industries: ["sales_marketing"],
    prepSeconds: 5,
  }),
  p({
    code: "deb_i_hiring_freeze",
    activitySlug: "debate_me",
    difficulty: "intermediary",
    title: "Hiring freeze",
    promptText:
      "Act as a cost-focused CFO. Debate my request to hire one more person for the team. Push back on headcount, ask for proof of impact, and suggest we wait a quarter.",
    objective: "Defend the hire with outcomes, not emotion.",
    exemplarResponse:
      "I hear the freeze. This role removes a bottleneck that delayed two releases last quarter. If we wait, we still pay overtime and slip dates. I can start with a six-month contractor and review permanent headcount after the next launch.",
    prepSeconds: 5,
  }),
  p({
    code: "deb_i_meeting_culture",
    activitySlug: "debate_me",
    difficulty: "intermediary",
    title: "Too many meetings",
    promptText:
      "Act as a busy teammate who loves meetings. Debate my proposal to cut recurring meetings by half. Argue that alignment will suffer if we reduce them.",
    objective: "Protect focus time without dismissing collaboration.",
    exemplarResponse:
      "Alignment matters, and most of our status calls repeat the same update. Keep one decision meeting, move status to a written note, and protect two deep-work blocks. We still meet when a choice needs people in the room.",
    prepSeconds: 5,
  }),
  p({
    code: "deb_i_promotion",
    activitySlug: "debate_me",
    difficulty: "intermediary",
    title: "Promotion timing",
    promptText:
      "Act as a sceptical manager. Debate why I should wait another year for a promotion even though I believe I already deliver at the next level.",
    objective: "Stay composed and evidence-led.",
    exemplarResponse:
      "I understand you want more runway. Here is what I already own at the next level: X shipped, Y mentored, Z owned without escalation. If the title needs one more proof point, name it and I will deliver it this quarter.",
    prepSeconds: 5,
  }),
  p({
    code: "deb_i_scope_creep",
    activitySlug: "debate_me",
    difficulty: "intermediary",
    title: "Scope creep",
    promptText:
      "Act as an excited stakeholder. Debate why we should add three new features before launch. Push back when I say we should protect the release date.",
    objective: "Hold the line on scope without sounding rigid.",
    exemplarResponse:
      "Those ideas are good, and they belong in the next release. Shipping the core promise on time builds trust. If we add all three now, we risk a late, buggy launch. Let’s lock v1 and schedule the extras for the sprint after.",
    prepSeconds: 5,
  }),
  p({
    code: "deb_i_remote_policy",
    activitySlug: "debate_me",
    difficulty: "intermediary",
    title: "Return to office",
    promptText:
      "Act as a leader who wants everyone back in the office three days a week. Debate my view that flexible remote work still delivers strong results.",
    objective: "Argue with results, not lifestyle preferences alone.",
    exemplarResponse:
      "Presence helps for workshops. Our delivery metrics were stronger with two office days and clear collaboration blocks. Force three days and we lose focus time without gaining better decisions. Let’s keep two and review after one quarter.",
    prepSeconds: 5,
  }),
  p({
    code: "deb_i_price_increase",
    activitySlug: "debate_me",
    difficulty: "intermediary",
    title: "Price increase",
    promptText:
      "Act as a long-term client angry about a 12% price increase. Debate why you should keep the old price, and challenge any value claims I make.",
    objective: "Acknowledge frustration, then reframe value calmly.",
    exemplarResponse:
      "I understand a 12% jump stings. The increase funds the support and uptime you asked for last year. I can hold your current rate for one more quarter if we renew for twelve months, or move you to a lighter plan without the extras you do not use.",
    prepSeconds: 5,
  }),
  p({
    code: "deb_p_vc",
    activitySlug: "debate_me",
    difficulty: "professional",
    title: "Sceptical investor",
    promptText:
      "Act as a sceptical venture investor. Interrupt the pitch, challenge the business model and the market size, and force a calm retake of the room.",
    objective: "Use a short silence, then answer without a rising pitch.",
    exemplarResponse:
      "The market number is not the point. We sell to the 4,000 operators who already pay for this workaround. Our model is a yearly seat plus usage. If the usage assumption is wrong by half, we are still above the cost to serve.",
    industries: ["tech_product", "sales_marketing", "corporate_finance"],
    prepSeconds: 5,
  }),
  p({
    code: "deb_p_journalist",
    activitySlug: "debate_me",
    difficulty: "professional",
    title: "Hostile journalist",
    promptText:
      "Act as a hostile journalist investigating a corporate data breach. Ask who is to blame, and push back if the answer sounds defensive.",
    objective: "No cracked pitch. Facts, responsibility, and the next step.",
    exemplarResponse:
      "I will not speculate on a person before the review finishes. What I can say is that customer data was exposed, we have closed the access path, and affected customers are being contacted today. I am accountable for that update.",
    industries: ["corporate_finance", "tech_product"],
    prepSeconds: 5,
  }),
  p({
    code: "deb_i_healthcare",
    activitySlug: "debate_me",
    difficulty: "intermediary",
    title: "Family wants a different plan",
    promptText:
      "Act as a worried family member. Debate the care plan. You believe the team is not doing enough. Answer without sounding dismissive.",
    objective: "Stay steady and specific.",
    exemplarResponse:
      "I can see why this feels too slow. The next step is the scan at 4pm. Until that result is back, starting the stronger treatment would be a guess. I will come back with the result as soon as I have it.",
    industries: ["healthcare_edu"],
    prepSeconds: 5,
  }),

  // --- Extra healthcare clinical prompts (health first, not school-lesson topics) ---
  p({
    code: "eis_b_bp_patient",
    activitySlug: "explain_it_simply",
    difficulty: "beginner",
    title: "Blood pressure to a patient",
    promptText:
      "Explain what blood pressure numbers mean to a patient who only knows 'high' or 'low'.",
    objective: "Calm and practical. One clear takeaway.",
    exemplarResponse:
      "The top number is the push when your heart beats. The bottom is the pressure between beats. High means your heart and vessels are working harder than they should — so we watch it and treat it before it causes bigger problems.",
    industries: ["healthcare_edu"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_b_diabetes_friend",
    activitySlug: "explain_it_simply",
    difficulty: "beginner",
    title: "Diabetes to a friend",
    promptText:
      "Explain Type 2 diabetes to a friend who thinks it only means 'too much sugar in tea'.",
    objective: "Simple, no blame, one picture.",
    exemplarResponse:
      "Your body uses sugar for energy. In Type 2, the key that opens the cell door does not work well, so sugar stays in the blood. It is not just about sweet drinks — it is about how the body handles energy every day.",
    industries: ["healthcare_edu"],
    prepSeconds: 5,
  }),
  p({
    code: "eis_i_discharge_family",
    activitySlug: "explain_it_simply",
    difficulty: "intermediary",
    title: "Discharge plan to a family",
    promptText:
      "Explain a hospital discharge plan to a family who is worried about going home 'too soon'.",
    objective: "Reassure with a clear next-step list.",
    exemplarResponse:
      "Going home does not mean everything is finished. It means the hospital part is stable enough, and the rest continues with these meds, this follow-up date, and this number to call if X happens. Here is what to watch for in the first 48 hours.",
    industries: ["healthcare_edu"],
    prepSeconds: 5,
  }),
  p({
    code: "tf_b_missed_meds",
    activitySlug: "think_fast",
    difficulty: "beginner",
    title: "Missed medication dose",
    promptText:
      "A patient calls and says they forgot last night's tablet. What do you tell them in the next 60 seconds?",
    objective: "Clear instruction. No panic. One next step.",
    exemplarResponse:
      "Do not double up this morning. Take today's dose at the usual time, and tell us if you miss two doses in a row. If you feel chest pain or severe dizziness, call emergency services now.",
    industries: ["healthcare_edu"],
    prepSeconds: 5,
  }),
  p({
    code: "tf_i_ward_update",
    activitySlug: "think_fast",
    difficulty: "intermediary",
    title: "Ward round update",
    promptText:
      "The consultant asks for a 60-second update on your patient. Give the status, the problem, and the ask.",
    objective: "BLUF: status, issue, request.",
    exemplarResponse:
      "Mrs Khan is stable overnight. Oxygen is down to 2 litres. The open issue is the pending culture result. I need your decision on whether we stop the IV antibiotics this afternoon.",
    industries: ["healthcare_edu"],
    prepSeconds: 5,
  }),
  p({
    code: "ome_i_hand_hygiene",
    activitySlug: "one_minute_expert",
    difficulty: "intermediary",
    title: "Hand hygiene that sticks",
    promptText:
      "Explain why hand hygiene still fails on busy wards, and what actually changes behaviour.",
    objective: "One clear argument for 60 seconds.",
    exemplarResponse:
      "Posters do not fail people — friction does. When gel is out of reach or gloves feel like a shortcut, compliance drops. Put gel at the bed, make the first touch a clean touch, and audit the moment of care, not the policy document. Behaviour follows the easiest safe path.",
    industries: ["healthcare_edu"],
    prepSeconds: 5,
  }),
  p({
    code: "ome_b_pain_scale",
    activitySlug: "one_minute_expert",
    difficulty: "beginner",
    title: "Pain scale to a patient",
    promptText:
      "Explain the 0 to 10 pain scale to a patient who keeps saying 'it just hurts'.",
    objective: "Fill the minute with a simple structure.",
    exemplarResponse:
      "Zero is no pain. Ten is the worst pain you can imagine. We ask for a number so we can see if treatment is helping — not to test you. Compare today with yesterday. If it was an eight and now it is a five, that is progress even if it still hurts.",
    industries: ["healthcare_edu"],
    prepSeconds: 5,
  }),
  p({
    code: "deb_b_vaccine_myth",
    activitySlug: "debate_me",
    difficulty: "beginner",
    title: "Vaccine worry",
    promptText:
      "Act as a polite relative. Debate that 'natural immunity is always better than vaccines'. Push back gently on medical advice.",
    objective: "Stay calm, clear, and factual.",
    exemplarResponse:
      "Natural infection can leave immunity, and it can also leave harm. Vaccines train the same system with far less risk. The goal is protection without the illness.",
    industries: ["healthcare_edu"],
    prepSeconds: 5,
  }),
];

const CHALLENGES = [
  {
    slug: "bluf_sprint",
    title: "The 7-Day BLUF Sprint",
    tag: "ACTIVE CHALLENGE",
    description:
      "Deliver the bottom line first. Open your answer within 5 seconds, without a long warm-up.",
    targetCount: 7,
    activitySlugs: ["think_fast", "cut_it_in_half"],
    oncePerDay: true,
  },
  {
    slug: "silent_power_pause",
    title: "The Silent Power Pause",
    tag: "EXECUTIVE PRESENCE",
    description: "Hold a deliberate pause of about 1 to 2 seconds before your main recommendation.",
    targetCount: 3,
    activitySlugs: ["debate_me", "think_fast", "storytelling_gym"],
    oncePerDay: false,
  },
  {
    slug: "jargon_elimination",
    title: "Jargon Elimination",
    tag: "EXPLAIN IT SIMPLY",
    description: "Complete 3 explanations without hiding behind buzzwords.",
    targetCount: 3,
    activitySlugs: ["explain_it_simply"],
    oncePerDay: false,
  },
];

const SCORING_PRINCIPLES = [
  "Do not penalise accents. Score whether words are distinct and well paced.",
  "Do not reward one universal speaking pace.",
  "Do not treat every filler as a failure. Context matters.",
  "Do not reward complex vocabulary for its own sake.",
  "If audio quality or the transcript is poor, withhold the judgement.",
  "Keep a coached retry separate from a fresh prompt.",
  "Keep streaks and XP separate from skill scores.",
];

const ASSESSMENT_QUESTIONS = [
  {
    id: "full_name",
    type: "text",
    title: "What's your name?",
    subtitle: "Let's personalize your speaking experience.",
    options: [],
  },
  {
    id: "voice_profile",
    type: "choice",
    title: "Which voice profile fits you best?",
    subtitle: "This helps us personalize your voice training.",
    options: [
      { id: "male", label: "Male", description: "Build stronger resonance and steady projection" },
      { id: "female", label: "Female", description: "Develop pitch clarity and vocal control" },
      { id: "non_binary", label: "Non-binary / Vocal alignment", description: "Personalize your pitch and vocal range" },
    ],
  },
  {
    id: "career_stage",
    type: "choice",
    title: "Where are you in your career?",
    subtitle: "We'll tailor your practice to situations you're likely to face.",
    options: [
      { id: "early", label: "Student / Early career", description: "Interviews, presentations and starting work" },
      { id: "mid_level", label: "Mid-level professional", description: "Meetings, projects and performance conversations" },
      { id: "exec", label: "Senior executive / Founder", description: "Pitches, keynotes and high-stakes conversations" },
      { id: "self_learner", label: "General self-learner", description: "Everyday communication and personal development" },
    ],
  },
  {
    id: "career_type",
    type: "choice",
    title: "What's your main work environment?",
    subtitle: "Choose the option that best matches your day-to-day.",
    options: [
      { id: "corporate_finance", label: "Corporate & Finance", description: "Meetings, data reviews and formal presentations" },
      { id: "tech_product", label: "Tech, Engineering & Product", description: "Explaining complex ideas simply" },
      { id: "sales_marketing", label: "Sales, Marketing & Content", description: "Persuasion, negotiation and audience engagement" },
      { id: "healthcare_edu", label: "Healthcare & Education", description: "Patients, families, clinical clarity" },
      { id: "other", label: "Other", description: "Something else" },
    ],
  },
  {
    id: "speaking_confidence",
    type: "choice",
    title: "How confident do you feel speaking under pressure?",
    subtitle: "Choose the option that sounds most like you.",
    options: [
      { id: "not_very", label: "Not very confident", description: "I get nervous, rush or struggle to find my words" },
      { id: "fairly", label: "Fairly confident", description: "I communicate well but sometimes rely on filler words" },
      { id: "very", label: "Very confident", description: "I'm comfortable speaking, but want to sharpen my delivery" },
    ],
  },
  {
    id: "primary_roadblock",
    type: "choice",
    title: "What gets in your way most when you speak?",
    subtitle: "Pick your biggest challenge. You can work on the others later.",
    options: [
      { id: "blank_pressure", label: "I go blank under pressure", description: "I struggle to organize my thoughts quickly" },
      { id: "too_long", label: "I take too long to get to the point", description: "I over-explain before getting to my message" },
      { id: "filler_rush", label: "I rush or use too many filler words", description: "I use words like 'um' or 'so' while thinking" },
      { id: "explain_simple", label: "I struggle to explain things simply", description: "I know what I mean, but make it sound complicated" },
      { id: "keep_engaged", label: "I struggle to keep people engaged", description: "My message doesn't always land or stick" },
      { id: "lose_confidence", label: "I lose confidence when challenged", description: "I struggle to respond clearly when someone disagrees" },
    ],
  },
  {
    id: "primary_goal",
    type: "choice",
    title: "What's your main goal?",
    subtitle: "What would you most like Hakkiri to help you improve?",
    options: [
      { id: "authority", label: "Speak with more authority and executive presence", description: "" },
      { id: "calmer_confident", label: "Feel calmer and more confident speaking under pressure", description: "" },
      { id: "persuasive_arguments", label: "Build clear, persuasive arguments on the spot", description: "" },
      { id: "clear_daily", label: "Speak more clearly and confidently every day", description: "" },
      { id: "keep_engaged", label: "Keep people engaged and make an impact", description: "" },
      { id: "other", label: "Other", description: "Personal communication goals" },
    ],
  },
];

module.exports = { ACTIVITIES, PROMPTS, CHALLENGES, SCORING_PRINCIPLES, ASSESSMENT_QUESTIONS };
