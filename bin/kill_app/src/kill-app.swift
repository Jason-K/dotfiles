//
//  main.swift
//  kill-apps
//
//  Optimized for speed: pure POSIX signaling by default, no AppKit load.
//  Created by Jason K. on 12/22/25.
//

import AppKit
import Foundation
import CoreGraphics

// MARK: - Types

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

// MARK: - Main

@main
struct UnfreezeMain {

  // MARK: - Helpers

  static func eprint(_ s: String) { fputs(s + "\n", stderr) }

  static func loadConfig() -> Config {
    // Load from script directory
    if let exePath = CommandLine.arguments.first {
      let exeDir = URL(fileURLWithPath: exePath).deletingLastPathComponent().path
      let localConfig = URL(fileURLWithPath: exeDir).appendingPathComponent("do-not-kill.json")
      if let data = try? Data(contentsOf: localConfig) {
        return (try? JSONDecoder().decode(Config.self, from: data)) ?? Config()
      }
    }
    return Config()
  }

  static func compileRegexes(_ patterns: [String]) -> [NSRegularExpression] {
    patterns.compactMap { pat in
      try? NSRegularExpression(pattern: pat, options: [])
    }
  }

  static func matchesAny(_ s: String, _ regs: [NSRegularExpression]) -> Bool {
    let ns = s as NSString
    let range = NSRange(location: 0, length: ns.length)
    for r in regs {
      if r.firstMatch(in: s, options: [], range: range) != nil { return true }
    }
    return false
  }

  // MARK: - Process Management

  static func pidAlive(_ pid: Int32) -> Bool { kill(pid, 0) == 0 }

  static func sendSignal(_ sig: Int32, pid: Int32) { _ = kill(pid, sig) }

  // MARK: - Detection Logic

  static func getFrontmostApp() -> [Offender] {
    // 1. Try CoreGraphics (Fast, no permissions needed)
    if let cg = getFrontmostCoreGraphics() { return cg }

    // 2. Try NSWorkspace
    if let ws = getFrontmostNSWorkspace() { return ws }

    // 3. Last resort: AppleScript
    return getFrontmostAppleScript()
  }

  static func getFrontmostCoreGraphics() -> [Offender]? {
    let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
    guard let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return nil }

    for window in info {
      if let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
         let pid = window[kCGWindowOwnerPID as String] as? Int32, pid > 0,
         let name = window[kCGWindowOwnerName as String] as? String {
         return [Offender(name: name, pid: pid, bundle: nil)]
      }
    }
    return nil
  }

  static func getFrontmostNSWorkspace() -> [Offender]? {
    if let app = NSWorkspace.shared.frontmostApplication {
      return [Offender(name: app.localizedName, pid: app.processIdentifier, bundle: app.bundleIdentifier)]
    }
    return nil
  }

  static func getFrontmostAppleScript() -> [Offender] {
    let scriptSource = "tell application \"System Events\" to get {name, unix id, bundle identifier} of first process whose frontmost is true"
    guard let script = NSAppleScript(source: scriptSource) else { return [] }

    var error: NSDictionary?
    let descriptor = script.executeAndReturnError(&error)

    // NSAppleEventDescriptor is returned directly, check for error via 'error' dict or if descriptor is null (it's implicitly unwrapped usually but let's be safe if API varies, though current swift SDK says distinct return)
    // Actually executeAndReturnError returns NSAppleEventDescriptor! (implicit unwrap) or just NSAppleEventDescriptor depending on SDK version.
    // The previous error said "initializer for conditional binding must have Optional type", so it is NOT optional.

    if descriptor.numberOfItems >= 2 {
      let name = descriptor.atIndex(1)?.stringValue
      let pid = descriptor.atIndex(2)?.int32Value ?? 0
      let bundle = descriptor.atIndex(3)?.stringValue
      if pid > 0 {
        return [Offender(name: name, pid: pid, bundle: bundle)]
      }
    }
    return []
  }

  static func getUnresponsiveApps() -> [Offender] {
    // Query System Events for processes where backgroundOnly is false and responding is false
    let scriptSource = """
      tell application "System Events"
        set openProcs to every process whose background only is false and responding is false
        set res to {}
        repeat with proc in openProcs
          try
            set end of res to {name of proc, unix id of proc, bundle identifier of proc}
          end try
        end repeat
        return res
      end tell
      """

    guard let script = NSAppleScript(source: scriptSource) else { return [] }
    var error: NSDictionary?
    let descriptor = script.executeAndReturnError(&error)

    // Descriptor is non-optional
    var results: [Offender] = []
    let list = descriptor
    let count = list.numberOfItems
    if count > 0 {
       for i in 1...count {
         if let item = list.atIndex(i), item.numberOfItems >= 2 {
           let name = item.atIndex(1)?.stringValue
           let pid = item.atIndex(2)?.int32Value ?? 0
           let bundle = item.atIndex(3)?.stringValue
           if pid > 0 {
             results.append(Offender(name: name, pid: pid, bundle: bundle))
           }
         }
       }
    }
    return results
  }

  static func usage() -> Never {
    eprint(
      """
      Usage:
        kill-app [--dry-run] [--exclude REGEX ...] [--only REGEX ...] [--foreground] [--fast] [--graceful]

      Flags:
        --foreground Detect and kill the frontmost application.
        --fast       Default behavior (no-op): go TERM -> KILL with tight waits.
        --graceful   Add a brief pre-TERM grace wait.
        --instant    Skip TERM, go straight to KILL.
      """
    )
    exit(ExitCode.badArgs.rawValue)
  }

  static func main() {
    var dryRun = false
    var exclude: [String] = []
    var only: [String] = []
    var graceful = false   // opt-in
    var instant = false    // skip TERM, go straight to KILL
    var fast = false       // tighter waits
    var foreground = false // target frontmost

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
      case "--foreground":
        foreground = true; i += 1
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

    // Detect Offenders
    let offenders = foreground ? getFrontmostApp() : getUnresponsiveApps()

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
      if matchesAny(key, denyRegexes) {
         if dryRun { print("[DRY RUN] Skipping (denylist): \(o.name ?? "?") (\(o.pid))") }
         skipped += 1; continue
      }
      if dryRun {
        print("[DRY RUN] Would kill: \(o.name ?? "?") (\(o.pid))")
        skipped += 1; continue
      }
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
