//
//  main.swift
//  kill-apps
//
//  Optimized for speed: pure POSIX signaling by default, no AppKit load.
//  Created by Jason K. on 12/22/25.
//

import Foundation

struct Offender: Codable {
  let name: String?
  let pid: Int32
  let bundle: String?
}

struct Config: Codable {
  var denylist: [String] = []
  var gracePeriodSec: Double = 8
  var termWaitSec: Double = 5
  var killWaitSec: Double = 3
}

enum ExitCode: Int32 {
  case ok = 0
  case skippedOrDryRun = 1
  case escalationUsed = 2
  case stubbornAfterKill = 3
  case badArgs = 64
}

@inline(__always)
func eprint(_ s: String) { fputs(s + "\n", stderr) }

@inline(__always)
func readStdinAll() -> Data { FileHandle.standardInput.readDataToEndOfFile() }

func loadConfig() -> Config {
  let home = FileManager.default.homeDirectoryForCurrentUser
  let url = home.appendingPathComponent(".config/unfreeze.json")
  guard let data = try? Data(contentsOf: url) else { return Config() }
  return (try? JSONDecoder().decode(Config.self, from: data)) ?? Config()
}

func compileRegexes(_ patterns: [String]) -> [NSRegularExpression] {
  patterns.compactMap { pat in
    try? NSRegularExpression(pattern: pat, options: [])
  }
}

@inline(__always)
func matchesAny(_ s: String, _ regs: [NSRegularExpression]) -> Bool {
  let ns = s as NSString
  let range = NSRange(location: 0, length: ns.length)
  for r in regs {
    if r.firstMatch(in: s, options: [], range: range) != nil { return true }
  }
  return false
}

// Fast path: rely on signals and PID. Graceful quit via bundle ID is optional and off by default.
@inline(__always)
func pidAlive(_ pid: Int32) -> Bool { kill(pid, 0) == 0 }

@inline(__always)
func sendSignal(_ sig: Int32, pid: Int32) { _ = kill(pid, sig) }

// Low-latency polling: short aggressive burst, then steady cadence until timeout.
func sleepPoll(_ seconds: Double, pid: Int32) -> Bool {
  if seconds <= 0 { return !pidAlive(pid) }

  // First 1s: aggressive 50ms checks for responsiveness
  var remaining = seconds
  var step: Double = 0.05
  var spent: Double = 0
  while spent < 1.0 && spent < seconds {
    if !pidAlive(pid) { return true }
    usleep(50_000)
    spent += step
  }
  remaining = max(0, seconds - spent)

  // Then 200ms cadence for the remainder
  step = 0.2
  let loops = Int(remaining / step)
  for _ in 0..<max(1, loops) {
    if !pidAlive(pid) { return true }
    usleep(200_000)
  }
  return !pidAlive(pid)
}

@inline(__always)
func usage() -> Never {
  eprint(
    """
    Usage:
      unfreeze-kill [--dry-run] [--exclude REGEX ...] [--only REGEX ...] [--fast] [--graceful]
    Expects JSON array on stdin: [{ "name": "...", "pid": 123, "bundle": "..." }, ...]

    Flags:
      --fast       Default behavior (no-op): go TERM -> KILL with tight waits.
      --graceful   Add a brief pre-TERM grace wait (no AppKit).
    """
  )
  exit(ExitCode.badArgs.rawValue)
}

@main
struct UnfreezeMain {
  static func main() {
    var dryRun = false
    var exclude: [String] = []
    var only: [String] = []
    var graceful = false   // opt-in
    var instant = false    // skip TERM, go straight to KILL
    var fast = false       // tighter waits

    var i = 1
    let argv = CommandLine.arguments
    while i < argv.count {
      let a = argv[i]
      switch a {
      case "--dry-run":
        dryRun = true; i += 1
      case "--exclude":
        guard i + 1 < argv.count else { usage() }
        exclude.append(argv[i + 1]); i += 2
      case "--only":
        guard i + 1 < argv.count else { usage() }
        only.append(argv[i + 1]); i += 2
      case "--fast":
        fast = true; i += 1
      case "--graceful":
        graceful = true; i += 1
      case "--instant":
        instant = true; i += 1
      case "--help", "-h":
        usage()
      default:
        usage()
      }
    }

    var cfg = loadConfig()
    if fast {
      // Aggressive defaults when asked to be fast
      cfg.termWaitSec = min(cfg.termWaitSec, 0.8)
      cfg.killWaitSec = min(cfg.killWaitSec, 0.5)
      cfg.gracePeriodSec = min(cfg.gracePeriodSec, 0.5)
    }
    let denyRegexes = compileRegexes(cfg.denylist + exclude)
    let onlyRegexes = compileRegexes(only)

    let input = readStdinAll()
    let offenders = (try? JSONDecoder().decode([Offender].self, from: input)) ?? []

    // Filter
    let filtered = offenders.filter { o in
      let key = "\(o.bundle ?? "") \(o.name ?? "")".trimmingCharacters(in: .whitespaces)
      if !onlyRegexes.isEmpty && !matchesAny(key, onlyRegexes) { return false }
      return true
    }

    if filtered.isEmpty {
      exit(ExitCode.ok.rawValue)
    }

    var usedEscalation = false
    var skipped = 0

    // Apply denylist and dry-run before signaling
    var targets: [Offender] = []
    for o in filtered {
      let key = "\(o.bundle ?? "") \(o.name ?? "")".trimmingCharacters(in: .whitespaces)
      if matchesAny(key, denyRegexes) { skipped += 1; continue }
      if dryRun { skipped += 1; continue }
      targets.append(o)
    }

    if targets.isEmpty {
      if dryRun || skipped > 0 { exit(ExitCode.skippedOrDryRun.rawValue) }
      exit(ExitCode.ok.rawValue)
    }

    if graceful {
      // Brief grace before signals
      let grace = min(1.0, max(0, cfg.gracePeriodSec))
      if grace > 0 {
        // Poll all; break early if none alive
        var elapsed: Double = 0
        while elapsed < grace {
          if targets.allSatisfy({ !pidAlive($0.pid) }) { break }
          usleep(100_000) // 100ms
          elapsed += 0.1
        }
      }
      // Remove any that died during grace
      targets.removeAll(where: { !pidAlive($0.pid) })
    }

    // Send signals in batch
    if instant {
      for t in targets { sendSignal(SIGKILL, pid: t.pid) }
      usedEscalation = true
    } else {
      // TERM all
      for t in targets { sendSignal(SIGTERM, pid: t.pid) }
      usedEscalation = true
      // Wait up to termWaitSec for all to exit
      let termWait = max(0, cfg.termWaitSec)
      var elapsed: Double = 0
      while elapsed < termWait {
        targets.removeAll(where: { !pidAlive($0.pid) })
        if targets.isEmpty { break }
        usleep(100_000) // 100ms
        elapsed += 0.1
      }

      // KILL remaining
      if !targets.isEmpty {
        for t in targets { sendSignal(SIGKILL, pid: t.pid) }
      }
    }

    // Final wait for any remaining after KILL
    let killWait = max(0, cfg.killWaitSec)
    var stubborn = 0
    if killWait > 0 && !targets.isEmpty {
      var elapsed: Double = 0
      while elapsed < killWait {
        targets.removeAll(where: { !pidAlive($0.pid) })
        if targets.isEmpty { break }
        usleep(100_000) // 100ms
        elapsed += 0.1
      }
      stubborn = targets.filter({ pidAlive($0.pid) }).count
    }

    if stubborn > 0 { exit(ExitCode.stubbornAfterKill.rawValue) }
    if dryRun || skipped > 0 { exit(ExitCode.skippedOrDryRun.rawValue) }
    if usedEscalation { exit(ExitCode.escalationUsed.rawValue) }
    exit(ExitCode.ok.rawValue)
  }
}

