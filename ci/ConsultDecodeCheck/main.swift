// Run in CI: decodes sample consult responses the way the app does and fails the build
// if a realistic (or partly malformed) response can't be read.
import Foundation

func check(_ name: String, _ json: String, expectConcerns: Int) {
    do {
        let consult = try JSONDecoder().decode(Consult.self, from: Data(json.utf8))
        guard consult.concerns.count == expectConcerns else {
            print("FAIL \(name): expected \(expectConcerns) concerns, got \(consult.concerns.count)")
            exit(1)
        }
        print("ok   \(name): \(consult.skinType.label), \(consult.strengths.count) strengths, \(consult.concerns.count) concerns, plan \(consult.plan.morning.count)+\(consult.plan.evening.count)")
    } catch {
        print("FAIL \(name): \(error)")
        exit(1)
    }
}

let full = """
{"intro":"Your skin has a lovely even tone.","skinType":{"label":"oily","explanation":"Your T-zone makes more oil."},
"strengths":[{"title":"Even tone","detail":"Very little redness."},{"title":"Rested eyes","detail":"Minimal dark circles."}],
"concerns":[{"key":"pore","title":"Visible pores","severity":"moderate","summary":"Pores show on your nose.","seen":"a","why":"b","todo":"c","expect":"d"},
{"key":"texture","title":"Texture","severity":"mild","summary":"Slight roughness.","seen":"a","why":"b","todo":"c","expect":"d"}],
"watch":{"title":"Shine","detail":"Summer can add shine."},
"plan":{"focus":"Clear pores","morning":["Cleanser","Niacinamide","SPF"],"evening":["Cleanser","BHA","Moisturizer"]}}
"""
check("full response", full, expectConcerns: 2)

// Missing fields, an empty concern, no watch, plan as a string: still readable.
let messy = """
{"intro":"Hi","skinType":{"label":"combination"},
"strengths":[{"title":"Glow"}],
"concerns":[{"key":"pore","title":"Pores","severity":"notable","summary":"x"},{"key":"texture"}],
"watch":"Keep pores clear in summer.",
"plan":"use spf"}
"""
check("messy response", messy, expectConcerns: 1)
if (try? JSONDecoder().decode(Consult.self, from: Data(messy.utf8)))?.watch?.detail != "Keep pores clear in summer." {
    print("FAIL watch as plain text was dropped"); exit(1)
}
print("ok   watch as plain text kept")
