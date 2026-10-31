import VibieKit
import Foundation

struct Options {
    var positional: [String] = []
    private var values: [String: String] = [:]
    private var flags: Set<String> = []

    init(_ arguments: [String]) {
        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            if argument.hasPrefix("--") {
                if let eq = argument.firstIndex(of: "=") {
                    values[String(argument[..<eq])] = String(argument[argument.index(after: eq)...])
                } else if ["--name", "--port", "--control-port", "--agent", "--timeout"].contains(argument) {
                    values[argument] = iterator.next()
                } else {
                    flags.insert(argument)
                }
            } else {
                positional.append(argument)
            }
        }
    }

    func value(_ key: String) -> String? { values[key] }
    func flag(_ key: String) -> Bool { flags.contains(key) }
    func port(_ key: String) -> UInt16? { values[key].flatMap { UInt16($0) } }
    var agent: AgentKind { values["--agent"].flatMap(AgentKind.init(rawValue:)) ?? .claudeCode }
    var controlPort: UInt16 { port("--control-port") ?? Vibie.controlPort }
}

let arguments = Array(CommandLine.arguments.dropFirst())
let command = arguments.first ?? "help"
let options = Options(Array(arguments.dropFirst()))

switch command {
case "serve":
    do {
        let server = try BridgeServer(
            home: BridgeHome(),
            name: options.value("--name") ?? BridgeHome.defaultName,
            port: options.port("--port") ?? Vibie.defaultPort,
            controlPort: options.controlPort)
        try server.start(forcePairing: options.flag("--pair"))
        signal(SIGINT) { _ in
            print("\nBridge stopped. Claude Code will fall back to asking in the terminal.")
            exit(0)
        }
        dispatchMain()
    } catch {
        Console.fail("Couldn't start the bridge: \(error)")
        exit(1)
    }

case "hook":
    HookCommand.run(agent: options.agent, timeout: options.value("--timeout").flatMap(Double.init) ?? 590, controlPort: options.controlPort)

case "install-hooks":
    do {
        try InstallHooks.run(
            projectDirectory: options.positional.first,
            global: options.flag("--global"),
            agent: options.agent,
            checkpoints: !options.flag("--no-checkpoints"))
    } catch {
        Console.fail("Couldn't install hooks: \(error)")
        exit(1)
    }

case "simulate":
    Simulate.run(kind: options.positional.first ?? "edit", controlPort: options.controlPort)

case "status":
    BridgeHome().printStatus()

case "unpair":
    do {
        try BridgeHome().saveTrusted([])
        Console.success("Forgot every paired phone. Run `vibie serve --pair` to pair again.")
    } catch {
        Console.fail("\(error)")
        exit(1)
    }

default:
    print("""
    \(Console.bold("vibie")) — review your coding agent's changes as reels on your iPhone.

    \(Console.bold("Usage"))
      vibie serve [--pair] [--name "My Mac"] [--port 7766]
          Run the bridge. Shows a pairing QR code the first time (or with --pair).

      vibie install-hooks [project-dir] [--global] [--no-checkpoints]
          Add Vibie hooks to <project>/.claude/settings.local.json
          (or ~/.claude/settings.json with --global).

      vibie simulate [edit|bash|stop]
          Send a pretend change to your phone to try the flow without an agent.

      vibie status     Show this Mac's fingerprint and paired phones.
      vibie unpair     Forget all paired phones.

      vibie hook       (Called by Claude Code. Reads hook JSON on stdin.)

    Everything stays between this Mac and your phone. No servers, no accounts.
    """)
}
