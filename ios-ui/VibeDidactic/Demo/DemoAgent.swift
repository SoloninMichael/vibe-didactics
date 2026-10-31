import VibieKit
import Foundation

/// A scripted session presenting the three curated demo video reels in order (1 -> 2 -> 3).
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
        AgentStatus(state: state, detail: detail, project: "google-halloween", agent: .demo)
    }

    private static func script() -> [ReelItem] {
        [
            lesson(.demoVid1,
                   project: "google-halloween",
                   path: "google_halloween/spooky_route_controller.py",
                   intent: "I'll reserve candy in GhostLock for kids already walking to House #7 so Google Maps immediately switches the pin to grey and routes new kids to House #8. Abandoned walking reservations expire after 180 seconds.",
                   diff: """
                    def assign_next_house(kid_id, street_houses):
                        for house in street_houses:
                            physical_candy = feeder_sensor.read_count(house.id)
                   -        claimable_candy = physical_candy
                   +        walking_kids = ghost_lock.active_walkers(house.id)
                   +        claimable_candy = physical_candy - walking_kids
                            if claimable_candy > 0:
                   +            ghost_lock.reserve(house.id, kid_id, ttl_sec=180)
                                return google_maps.route(kid_id, to=house.id)
                        return google_maps.show_grey_pin_and_reroute(kid_id)
                   """),
            lesson(.demoVid2,
                   project: "google-halloween",
                   path: "google_halloween/spooky_route_controller.py",
                   intent: "Break-It! Mode counterfactual check: if we delete '- walking_kids' on line 46, claimable_candy stays 1 while Kid A walks to eat the last candy, leaving pin_state ORANGE (stale!) and sending Kid B to an empty bowl at House #7.",
                   diff: """
                    def assign_next_house(kid_id, street_houses):
                        for house in street_houses:
                            physical_candy = feeder_sensor.read_count(house.id)
                            walking_kids = ghost_lock.active_walkers(house.id)
                   -        claimable_candy = physical_candy - walking_kids
                   +        claimable_candy = physical_candy  # BREAK-IT: walking_kids ignored!
                            if claimable_candy > 0:
                                ghost_lock.reserve(house.id, kid_id, ttl_sec=180)
                                return google_maps.route(kid_id, to=house.id)
                        return google_maps.show_grey_pin_and_reroute(kid_id)
                   """),
            lesson(.demoVid3,
                   project: "multi-agent-workflow",
                   path: "workflows/multi_agent_pipeline.py",
                   intent: "I'll fan out each user prompt to three parallel Azure OpenAI agent branches (Sales, Marketing, and Product), validate their structured outputs before recalling department data, and bundle all three processed results.",
                   diff: """
                    async def run_workflow(user_prompt: str) -> WorkflowStatus:
                   -    sales = await sales_agent.run(user_prompt)
                   -    return bundle_processed_data([sales])
                   +    sales_branch, marketing_branch, product_branch = await asyncio.gather(
                   +        run_branch(sales_agent, recall_sales, process_sales, user_prompt),
                   +        run_branch(marketing_agent, recall_marketing, process_marketing, user_prompt),
                   +        run_branch(product_agent, recall_product, process_product, user_prompt),
                   +    )
                   +    bundled = bundle_processed_data([sales_branch, marketing_branch, product_branch])
                   +    return generate_success_status(bundled)
                   """),
        ]
    }

    // MARK: Builders

    private static func lesson(_ lesson: DemoLesson, project: String, path: String, intent: String, diff: String) -> ReelItem {
        let parsed = parse(diff)
        let card = ChangeCard(agent: .demo, project: project, kind: .edit, tool: "Edit", filePath: path,
                              agentIntent: intent, lines: parsed.lines, additions: parsed.additions,
                              deletions: parsed.deletions, language: "Python")
        return ReelItem(card: card, demoLesson: lesson)
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
