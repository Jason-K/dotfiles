//
//  launch-or-activate.swift
//  launch-or-activate
//
//  Created by Jason K on 12/22/25.
//

import AppKit
import Foundation
import ApplicationServices // LaunchServices for faster bundle lookups

enum Mode {
  case bundleID(String)
  case appName(String)
  case appPath(String)
}

func die(_ msg: String, code: Int32 = 2) -> Never {
  fputs("launch-or-activate: \(msg)\n", stderr)
  exit(code)
}

func parseArgs() -> Mode {
  let args = CommandLine.arguments.dropFirst()
  guard let first = args.first else {
    die("Usage: launch-or-activate -b <bundle_id> | -a <app name> | <path-to-app>")
  }

  if first == "-b" {
    guard args.count == 2 else { die("Usage: launch-or-activate -b <bundle_id>") }
    return .bundleID(String(args[args.index(args.startIndex, offsetBy: 1)]))
  } else if first == "-a" {
    guard args.count == 2 else { die("Usage: launch-or-activate -a <app name>") }
    return .appName(String(args[args.index(args.startIndex, offsetBy: 1)]))
  } else {
    return .appPath(String(first))
  }
}

func activateIfRunning(bundleID: String) -> Bool {
  if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
    _ = app.activate(options: [])
    return true
  }
  return false
}

// Fast path: LaunchServices lookup without hitting disk repeatedly
func urlForBundleIDFast(_ bundleID: String) -> URL? {
  guard let arr = LSCopyApplicationURLsForBundleIdentifier(bundleID as CFString, nil)?.takeRetainedValue() as? [URL] else {
    return nil
  }
  return arr.first
}

func openAppSynchronously(at url: URL) -> Bool {
  let config = NSWorkspace.OpenConfiguration()
  config.activates = true
  let semaphore = DispatchSemaphore(value: 0)
  var ok = false
  NSWorkspace.shared.openApplication(at: url, configuration: config) { app, error in
    ok = (error == nil && app != nil)
    semaphore.signal()
  }
  _ = semaphore.wait(timeout: .now() + 10) // small timeout to avoid hangs
  return ok
}

func openApp(at url: URL) {
  if openAppSynchronously(at: url) { exit(0) }
  die("Failed to open application at \(url.path)")
}

func resolveAppURL(named name: String) -> URL? {
  // Accept names with or without the ".app" suffix
  let candidateNames: [String]
  if name.hasSuffix(".app") {
    candidateNames = [name]
  } else {
    candidateNames = [name + ".app", name]
  }

  let fm = FileManager.default
  // Common application directories to search
  let searchDirs: [URL] = [
    URL(fileURLWithPath: "/Applications", isDirectory: true),
    URL(fileURLWithPath: "/System/Applications", isDirectory: true),
    fm.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
  ]

  for dir in searchDirs {
    for candidate in candidateNames {
      let url = dir.appendingPathComponent(candidate, isDirectory: true)
      if fm.fileExists(atPath: url.path) {
        return url
      }
    }
  }

  // As a fallback, try resolving by bundle identifier if the provided name looks like one
  if name.contains(".") {
    if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: name) {
      return appURL
    }
  }

  return nil
}

func resolveURLForBundleID(_ bundleID: String) -> URL? {
  return urlForBundleIDFast(bundleID) ?? NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
}

@main
struct LaunchOrActivate {
  static func main() {
    let mode = parseArgs()
    switch mode {
    case .bundleID(let bid):
      if activateIfRunning(bundleID: bid) { exit(0) }
      if let appURL = resolveURLForBundleID(bid) {
        if openAppSynchronously(at: appURL) { exit(0) }
        die("Failed to open application for bundle identifier \(bid)")
      } else {
        die("Could not find application for bundle identifier \(bid)")
      }

    case .appName(let name):
      if let appURL = resolveAppURL(named: name) {
        if let bundle = Bundle(url: appURL), let bid = bundle.bundleIdentifier {
          if activateIfRunning(bundleID: bid) { exit(0) }
        }
        if openAppSynchronously(at: appURL) { exit(0) }
        die("Failed to open application named \(name)")
      } else {
        die("Could not resolve app named \(name)")
      }

    case .appPath(let path):
      let url: URL
      if path.hasSuffix(".app") == false && path.contains("/") == false {
        if let resolved = resolveAppURL(named: path) {
          url = resolved
        } else {
          die("Could not resolve app named \(path)")
        }
      } else {
        url = URL(fileURLWithPath: path)
      }
      if let bundle = Bundle(url: url), let bid = bundle.bundleIdentifier {
        if activateIfRunning(bundleID: bid) { exit(0) }
      }
      if openAppSynchronously(at: url) { exit(0) }
      die("Failed to open application at \(url.path)")
    }
  }
}

