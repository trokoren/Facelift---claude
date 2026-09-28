import Foundation

/// Where the app talks to its server (Supabase).
///
/// Both values are safe to ship in the app: the anon key is a public key that only lets the app
/// call the functions we expose. Real secrets (the Perfect Corp key, later the Anthropic key)
/// live in Supabase's function secrets and never touch the app or this repo.
///
/// While these are empty, scans fall back to sample results so the app still works end to end.
enum Backend {
    /// e.g. "https://abcdefghijkl.supabase.co"
    static let supabaseURL = ""
    /// Supabase > Project Settings > API > "anon public" key.
    static let anonKey = ""

    static var isConfigured: Bool { !supabaseURL.isEmpty && !anonKey.isEmpty }

    static func functionURL(_ name: String) -> URL? {
        URL(string: "\(supabaseURL)/functions/v1/\(name)")
    }
}
