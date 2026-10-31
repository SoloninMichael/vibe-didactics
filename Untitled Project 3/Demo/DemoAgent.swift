import VibieKit
import Foundation

/// A scripted Claude Code session on a small vibe-coded app, so Vibie is fun before pairing a Mac.
final class DemoAgent {
    private var queue: [ReelItem] = []

    func reset() {
        queue = Self.script()
    }

    func opening() -> [ReelItem] {
        let first = Array(queue.prefix(3))
        queue.removeFirst(min(3, queue.count))
        return first
    }

    func next() -> ReelItem? {
        queue.isEmpty ? nil : queue.removeFirst()
    }

    func status(_ state: AgentStatus.State, _ detail: String) -> AgentStatus {
        AgentStatus(state: state, detail: detail, project: "candy-feeder", agent: .claudeCode)
    }

    private static func script() -> [ReelItem] {
        let lessons = [
            lesson(.lastCandy, path: "maps/candy_availability.py",
                   intent: "I'll reserve candy for kids already walking to House #7 so Google Maps doesn't send more kids to an empty porch. Count walking reservations as candy already promised, and release abandoned reservations after three minutes.",
                   diff: """
                    def house_has_candy(house_id, physical_candy):
                   -    return physical_candy > 0
                   +    walking_kids = reservations.active_count(house_id)
                   +    return physical_candy - walking_kids > 0

                    def start_walk(house_id, kid_id):
                   +    reservations.add(house_id, kid_id, ttl_sec=180)
                   """),
            lesson(.costumeAuth, path: "feeder/costume_auth.py",
                   intent: "I'll combine costume and rounded height so two Spider-Man friends can each claim a candy. Round height to 10cm buckets so small changes, like standing on tiptoes, are less likely to create a new claim key.",
                   diff: """
                    def claim_candy(costume, height_cm):
                   -    kid_id = costume
                   +    height_bucket = round(height_cm / 10) * 10
                   +    kid_id = f"{costume}_{height_bucket}cm"
                        if claims.contains(kid_id):
                            return "ALREADY CLAIMED"
                        claims.add(kid_id)
                        feeder.dispense_one()
                   """),
        ]
        let otherChanges: [ChangeCard] = [
            edit("src/components/PlantCard.tsx", language: "TSX",
                 intent: "I'll add a \"Thirsty\" badge to each plant card so you can see at a glance which plants need water. It compares the days since the last watering with each plant's schedule.",
                 diff: """
                  import type { Plant } from "../types";
                 +import { daysSince } from "../lib/daysSince";

                 ~8
                  export function PlantCard({ plant }: { plant: Plant }) {
                 +  const days = daysSince(plant.lastWatered);
                 +  const thirsty = days >= plant.waterEveryDays;
                 +
                    return (
                      <div className="plant-card">
                        <img src={plant.photo} alt="" />
                        <h3>{plant.name}</h3>
                 +      <span className={thirsty ? "badge thirsty" : "badge"}>
                 +        {thirsty ? `Thirsty · ${days}d` : `Watered ${days}d ago`}
                 +      </span>
                      </div>
                    );
                  }
                 """),
            command("npm install date-fns@4.1.0",
                    intent: "Install date-fns for reliable date math\n\nCounting days is surprisingly tricky across time zones and daylight saving, so I'll use the well-known date-fns library instead of hand-rolling it."),
            create("src/lib/daysSince.ts", language: "TypeScript",
                   intent: "I'll create a tiny helper that counts whole days since a date. Keeping it in one place means every screen decides \"thirsty\" the same way.",
                   diff: """
                   +import { differenceInCalendarDays } from "date-fns";
                   +
                   +/** Whole days between a past date and today (never negative). */
                   +export function daysSince(date: string | Date): number {
                   +  const then = typeof date === "string" ? new Date(date) : date;
                   +  return Math.max(0, differenceInCalendarDays(new Date(), then));
                   +}
                   """),
            edit("src/api/auth.ts", language: "TypeScript",
                 intent: "I'll hash passwords with bcrypt so a database leak doesn't expose them. Right now login compares the typed password with the stored one as plain text.",
                 diff: """
                 -import { db } from "./db";
                 +import bcrypt from "bcryptjs";
                 +import { db } from "./db";

                  export async function login(email: string, password: string) {
                    const user = await db.users.findByEmail(email);
                 -  if (!user || user.password !== password) {
                 +  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
                      throw new AuthError("Invalid email or password");
                    }
                    return createSession(user.id);
                  }
                 """),
            command("rm -rf .next node_modules && npm ci",
                    intent: "Clean reinstall to fix the stale build cache\n\nThe dev server keeps serving an old build. I'll wipe the build cache and node_modules, then reinstall everything from the lockfile."),
            sensitive(".env.local",
                      intent: "I'll add the SESSION_SECRET that the new login code needs to sign cookies."),
            checkpoint(intent: "Done! Plants now show a \"Thirsty\" badge when they're overdue, day counting uses date-fns, and login checks hashed passwords with bcrypt. Existing users still have plain-text passwords, so next I'd suggest a one-time migration to hash them."),
        ]
        return lessons + otherChanges.map { ReelItem(card: $0) }
    }

    // MARK: Builders

    private static func lesson(_ lesson: DemoLesson, path: String, intent: String, diff: String) -> ReelItem {
        let parsed = parse(diff)
        let card = ChangeCard(agent: .claudeCode, project: "candy-feeder", kind: .edit, tool: "Edit", filePath: path,
                              agentIntent: intent, lines: parsed.lines, additions: parsed.additions,
                              deletions: parsed.deletions, language: "Python")
        return ReelItem(card: card, demoLesson: lesson)
    }

    private static func edit(_ path: String, language: String, intent: String, diff: String) -> ChangeCard {
        let parsed = parse(diff)
        return ChangeCard(agent: .claudeCode, project: "plant-pal", kind: .edit, tool: "Edit", filePath: path,
                          agentIntent: intent, lines: parsed.lines, additions: parsed.additions, deletions: parsed.deletions, language: language)
    }

    private static func create(_ path: String, language: String, intent: String, diff: String) -> ChangeCard {
        let parsed = parse(diff)
        return ChangeCard(agent: .claudeCode, project: "plant-pal", kind: .create, tool: "Write", filePath: path,
                          agentIntent: intent, lines: parsed.lines, additions: parsed.additions, language: language)
    }

    private static func command(_ command: String, intent: String) -> ChangeCard {
        ChangeCard(agent: .claudeCode, project: "plant-pal", kind: .command, tool: "Bash", command: command, agentIntent: intent, language: "Shell")
    }

    private static func sensitive(_ path: String, intent: String) -> ChangeCard {
        ChangeCard(agent: .claudeCode, project: "plant-pal", kind: .edit, tool: "Edit", filePath: path, agentIntent: intent,
                   lines: [DiffLine(kind: .gap, text: "Contents hidden — this file can hold secrets, so it never leaves your Mac")],
                   additions: 1, redactions: 1, language: "Env")
    }

    private static func checkpoint(intent: String) -> ChangeCard {
        ChangeCard(agent: .claudeCode, project: "plant-pal", kind: .checkpoint, tool: "Stop", agentIntent: intent)
    }

    /// Each line starts with "+", "-" or " ", or is "~N" for N unchanged lines.
    private static func parse(_ text: String) -> (lines: [DiffLine], additions: Int, deletions: Int) {
        var old = 1, new = 1, additions = 0, deletions = 0
        var lines: [DiffLine] = []
        for raw in text.components(separatedBy: "\n") {
            guard let marker = raw.first else {
                lines.append(DiffLine(kind: .context, text: "", oldNumber: old, newNumber: new)); old += 1; new += 1
                continue
            }
            let body = String(raw.dropFirst())
            switch marker {
            case "+": lines.append(DiffLine(kind: .added, text: body, newNumber: new)); new += 1; additions += 1
            case "-": lines.append(DiffLine(kind: .removed, text: body, oldNumber: old)); old += 1; deletions += 1
            case "~":
                let count = Int(body) ?? 1
                lines.append(DiffLine(kind: .gap, text: "\(count) unchanged lines")); old += count; new += count
            default: lines.append(DiffLine(kind: .context, text: body, oldNumber: old, newNumber: new)); old += 1; new += 1
            }
        }
        return (lines, additions, deletions)
    }
}
