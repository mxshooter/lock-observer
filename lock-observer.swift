import Foundation

let name = (CommandLine.arguments[0] as NSString).lastPathComponent
let version = "1.1.1"
let build = "2025-03-01-001"
let author = "AJ ONeal <aj@therootcompany.com>"
let fork = "Max Malygin <maxmalygin@gmail.com>"

let versionMessage = "\(name) \(version) (\(build))"
let copyrightMessage = "Copyright 2024 \(author)\nForked by \(fork)"

let helpMessage = """
Runs a user-specified command whenever the screen is locked or unlocked by
listening for the "com.apple.screenIsLocked" and "com.apple.screenIsUnlocked"
events, using /usr/bin/command -v to find the program in the user's PATH
(or the explicit path given), and then runs it with /usr/bin/command, which
can run aliases and shell functions also.

USAGE
  \(name) [OPTIONS] <onlock_command> <onunlock_command>

EXAMPLE
  \(name) ./onlock ./onunlock

OPTIONS
  --version, -V, version
      Display the version information and exit.
  --help, help
      Display this help and exit.
"""

signal(SIGINT) { _ in
    printForHuman("received ctrl+c, exiting...")
    exit(0)
}

func printForHuman(_ message: String) {
    if let data = "\(message)\n".data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
}

func getCommandPath(_ command: String) -> String? {
    let commandv = Process()
    commandv.launchPath = "/usr/bin/command"
    commandv.arguments = ["-v", command]

    let pipe = Pipe()
    commandv.standardOutput = pipe
    commandv.standardError = FileHandle.standardError

    try! commandv.run()
    commandv.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let commandPath = String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
    else {
        return nil
    }

    if commandv.terminationStatus != 0, commandPath.isEmpty {
        return nil
    }

    return commandPath
}

class ScreenLockObserver {
    var lockCommandPath: String
    var lockCommandArgs: [String]
    var unlockCommandPath: String
    var unlockCommandArgs: [String]

    init(lockCommandArgs: ArraySlice<String>, unlockCommandArgs: ArraySlice<String>) {
        self.lockCommandPath = lockCommandArgs.first!
        self.lockCommandArgs = Array(lockCommandArgs)
        self.unlockCommandPath = unlockCommandArgs.first!
        self.unlockCommandArgs = Array(unlockCommandArgs)

        let dnc = DistributedNotificationCenter.default()

        _ = dnc.addObserver(forName: NSNotification.Name("com.apple.screenIsLocked"), object: nil, queue: .main) { _ in
            NSLog("notification: com.apple.screenIsLocked")
            self.runOnLock()
        }

        NSLog("Waiting for 'com.apple.screenIsLocked' to run \(self.lockCommandArgs) or 'com.apple.screenIsUnlocked' to run \(self.unlockCommandArgs)")
        _ = dnc.addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, queue: .main) { _ in
            NSLog("notification: com.apple.screenIsUnlocked")
            self.runOnUnlock()
        }
    }

    private func runOnLock() {
        let task = Process()
        task.launchPath = "/usr/bin/command"
        task.arguments = lockCommandArgs
        task.standardOutput = FileHandle.standardOutput
        task.standardError = FileHandle.standardError

        do {
            try task.run()
        } catch {
            printForHuman("Failed to run \(self.lockCommandPath): \(error.localizedDescription)")
            if let nsError = error as NSError? {
                printForHuman("Error details: \(nsError)")
            }
            exit(1)
        }

        task.waitUntilExit()
    }

    private func runOnUnlock() {
        let task = Process()
        task.launchPath = "/usr/bin/command"
        task.arguments = unlockCommandArgs
        task.standardOutput = FileHandle.standardOutput
        task.standardError = FileHandle.standardError

        do {
            try task.run()
        } catch {
            printForHuman("Failed to run \(self.unlockCommandPath): \(error.localizedDescription)")
            if let nsError = error as NSError? {
                printForHuman("Error details: \(nsError)")
            }
            exit(1)
        }

        task.waitUntilExit()
    }
}

@discardableResult
func removeItem(_ array: inout ArraySlice<String>, _ item: String) -> Bool {
    if let index = array.firstIndex(of: item) {
        array.remove(at: index)
        return true
    }
    return false
}

func processArgs(_ args: inout ArraySlice<String>) -> (ArraySlice<String>, ArraySlice<String>) {
    var childArgs: ArraySlice<String> = []
    if let delimiterIndex = args.firstIndex(of: "--") {
        let childArgsIndex = delimiterIndex + 1
        childArgs = args[childArgsIndex...]
        args.removeSubrange(delimiterIndex...)
    }
    if removeItem(&args, "--help") || removeItem(&args, "help") {
        printForHuman(versionMessage)
        printForHuman("")
        printForHuman(helpMessage)
        printForHuman("")
        printForHuman(copyrightMessage)
        exit(0)
    }
    if removeItem(&args, "--version") || removeItem(&args, "-V") || removeItem(&args, "version") {
        printForHuman(versionMessage)
        printForHuman(copyrightMessage)
        exit(0)
    }

    childArgs = args + childArgs
    guard childArgs.count >= 2 else {
        printForHuman(versionMessage)
        printForHuman("")
        printForHuman(helpMessage)
        printForHuman("")
        printForHuman(copyrightMessage)
        exit(1)
    }

    // Разделяем аргументы на две команды
    let lockCommandArgs = childArgs.prefix(1)
    let unlockCommandArgs = childArgs.suffix(from: childArgs.startIndex + 1)

    // Проверяем, что обе команды существуют
    guard let lockCommandPath = getCommandPath(lockCommandArgs.first!) else {
        printForHuman("ERROR:\n    \(lockCommandArgs.first!) not found in PATH")
        exit(1)
    }
    guard let unlockCommandPath = getCommandPath(unlockCommandArgs.first!) else {
        printForHuman("ERROR:\n    \(unlockCommandArgs.first!) not found in PATH")
        exit(1)
    }

    // Возвращаем аргументы с корректными путями
    var finalLockCommandArgs = Array(lockCommandArgs)
    finalLockCommandArgs[0] = lockCommandPath

    var finalUnlockCommandArgs = Array(unlockCommandArgs)
    finalUnlockCommandArgs[0] = unlockCommandPath

    return (ArraySlice(finalLockCommandArgs), ArraySlice(finalUnlockCommandArgs))
}

var args = CommandLine.arguments[1...]
let (lockCommandArgs, unlockCommandArgs) = processArgs(&args)
_ = ScreenLockObserver(lockCommandArgs: lockCommandArgs, unlockCommandArgs: unlockCommandArgs)

RunLoop.main.run()