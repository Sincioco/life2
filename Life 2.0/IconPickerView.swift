// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                         Life 2.0 - Icon Picker View
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.0
// Programmed Date:  November 22, 2025                                                      For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  Allow the user to pick an Icon symbol for their activity.
// ————————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation
import SwiftUI
import UIKit
import SwiftData

// MARK: - Models

struct SymbolItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

enum IconCategory: String, CaseIterable, Identifiable {
    case recent
    case all
    case gaming
    case fitness
    case nature
    
    case school
    case work
    case exercise
    case lifestyle
    case sports
    case tech
    case family
    case mindfulness
    case people
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .recent:      return "Recent"
        case .all:         return "All"
        case .gaming:      return "Gaming"
        case .fitness:     return "Fitness"
        case .nature:      return "Nature"
            
        case .school:      return "School"
        case .work:        return "Work"
        case .exercise:    return "Exercise"
        case .lifestyle:   return "Lifestyle"
        case .sports:      return "Sports"
        case .tech:        return "Tech"
        case .family:      return "Family"
        case .mindfulness: return "Mind"
        case .people:      return "People"
        }
    }
}

// MARK: - Icon Picker View

struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: String
    
    @State private var searchText: String = ""
    @State private var allSymbols: [SymbolItem] = []
    @State private var recentIcons: [String] = []
    
    @State private var selectedCategory: IconCategory = .all
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // Persist recent icon names (comma-separated)
    @AppStorage("recentIconNames") private var recentIconNamesStorage: String = ""

    @Query private var activities: [Activity]
    @Query private var categories: [Category]
    
    /// All icon names currently used by existing activities and categories
    private var usedIconNames: Set<String> {
        Set(activities.map { $0.icon } + categories.map { $0.icon })
    }
    
    /// Icons that should be excluded in the picker (used by *other* activities or categories)
    private var excludedIconNames: Set<String> {
        var set = usedIconNames
        set.remove(selectedIcon)   // allow the currently selected icon, so editing an activity still shows its icon
        return set
    }

    
    // MARK: Category symbol lists (~30 each)

    private let gamingSymbols = [
        "a.circle", "a.circle.fill", "arcade.stick", "arcade.stick.and.arrow.down", "arcade.stick.and.arrow.left", "arcade.stick.and.arrow.left.and.arrow.right.outward", "arcade.stick.and.arrow.right", "arcade.stick.and.arrow.up", "arcade.stick.and.arrow.up.and.arrow.down", "arcade.stick.console",
        "arcade.stick.console.fill", "arrowkeys", "arrowkeys.down.filled", "arrowkeys.fill", "arrowkeys.left.filled", "arrowkeys.right.filled", "arrowkeys.up.filled", "arrowtriangle.down.circle", "arrowtriangle.down.circle.fill", "arrowtriangle.left.circle",
        "arrowtriangle.left.circle.fill", "arrowtriangle.right.circle", "arrowtriangle.right.circle.fill", "arrowtriangle.up.circle", "arrowtriangle.up.circle.fill", "b.circle", "b.circle.fill", "button.angledbottom.horizontal.left", "button.angledbottom.horizontal.left.fill", "button.angledbottom.horizontal.right",
        "button.angledbottom.horizontal.right.fill", "button.angledtop.vertical.left", "button.angledtop.vertical.left.fill", "button.angledtop.vertical.right", "button.angledtop.vertical.right.fill", "button.horizontal", "button.horizontal.fill", "button.roundedbottom.horizontal", "button.roundedbottom.horizontal.fill", "button.roundedtop.horizontal",
        "button.roundedtop.horizontal.fill", "c.circle", "c.circle.fill", "circle.circle", "circle.circle.fill", "circle.grid.cross", "circle.grid.cross.down.filled", "circle.grid.cross.fill", "circle.grid.cross.left.filled", "circle.grid.cross.right.filled",
        "circle.grid.cross.up.filled", "circle.square", "circle.square.fill", "dpad", "dpad.down.filled", "dpad.fill", "dpad.left.filled", "dpad.right.filled", "dpad.up.filled", "flag.2.crossed",
        "flag.2.crossed.circle", "flag.2.crossed.circle.fill", "flag.2.crossed.fill", "flag.and.flag.filled.crossed", "flag.filled.and.flag.crossed", "flag.pattern.checkered", "flag.pattern.checkered.2.crossed", "flag.pattern.checkered.circle", "flag.pattern.checkered.circle.fill", "formfitting.gamecontroller",
        "formfitting.gamecontroller.fill", "gamecontroller", "gamecontroller.circle", "gamecontroller.circle.fill", "gamecontroller.fill", "gearshift.layout.sixspeed", "house", "house.circle", "house.circle.fill", "house.fill",
        "house.slash", "house.slash.fill", "l.button.roundedbottom.horizontal", "l.button.roundedbottom.horizontal.fill", "l.circle", "l.circle.fill", "l.joystick", "l.joystick.fill", "l.joystick.press.down", "l.joystick.press.down.fill",
        "l.joystick.tilt.down", "l.joystick.tilt.down.fill", "l.joystick.tilt.left", "l.joystick.tilt.left.fill", "l.joystick.tilt.right", "l.joystick.tilt.right.fill", "l.joystick.tilt.up", "l.joystick.tilt.up.fill", "l1.button.roundedbottom.horizontal", "l1.button.roundedbottom.horizontal.fill",
        "l1.circle", "l1.circle.fill", "l2.button.angledtop.vertical.left", "l2.button.angledtop.vertical.left.fill", "l2.button.roundedtop.horizontal", "l2.button.roundedtop.horizontal.fill", "l2.circle", "l2.circle.fill", "l3.button.angledbottom.horizontal.left", "l3.button.angledbottom.horizontal.left.fill",
        "l4.button.horizontal", "l4.button.horizontal.fill", "lb.button.roundedbottom.horizontal", "lb.button.roundedbottom.horizontal.fill", "lb.circle", "lb.circle.fill", "line.3.horizontal.button.angledtop.vertical.right", "line.3.horizontal.button.angledtop.vertical.right.fill", "line.3.horizontal.circle", "line.3.horizontal.circle.fill",
        "lm.button.horizontal", "lm.button.horizontal.fill", "lt.button.roundedtop.horizontal", "lt.button.roundedtop.horizontal.fill", "lt.circle", "lt.circle.fill", "m1.button.horizontal", "m1.button.horizontal.fill", "m2.button.horizontal", "m2.button.horizontal.fill",
        "m3.button.horizontal", "m3.button.horizontal.fill", "m4.button.horizontal", "m4.button.horizontal.fill", "minus", "minus.circle", "minus.circle.fill", "p1.button.horizontal", "p1.button.horizontal.fill", "p2.button.horizontal",
        "p2.button.horizontal.fill", "p3.button.horizontal", "p3.button.horizontal.fill", "p4.button.horizontal", "p4.button.horizontal.fill", "paddleshifter.left", "paddleshifter.left.fill", "paddleshifter.right", "paddleshifter.right.fill", "pedal.accelerator",
        "pedal.accelerator.fill", "pedal.brake", "pedal.brake.fill", "pedal.clutch", "pedal.clutch.fill", "playstation.logo", "plus", "plus.circle", "plus.circle.fill", "r.button.roundedbottom.horizontal",
        "r.button.roundedbottom.horizontal.fill", "r.circle", "r.circle.fill", "r.joystick", "r.joystick.fill", "r.joystick.press.down", "r.joystick.press.down.fill", "r.joystick.tilt.down", "r.joystick.tilt.down.fill", "r.joystick.tilt.left",
        "r.joystick.tilt.left.fill", "r.joystick.tilt.right", "r.joystick.tilt.right.fill", "r.joystick.tilt.up", "r.joystick.tilt.up.fill", "r1.button.roundedbottom.horizontal", "r1.button.roundedbottom.horizontal.fill", "r1.circle", "r1.circle.fill", "r2.button.angledtop.vertical.right",
        "r2.button.angledtop.vertical.right.fill", "r2.button.roundedtop.horizontal", "r2.button.roundedtop.horizontal.fill", "r2.circle", "r2.circle.fill", "r3.button.angledbottom.horizontal.right", "r3.button.angledbottom.horizontal.right.fill", "r4.button.horizontal", "r4.button.horizontal.fill", "rb.button.roundedbottom.horizontal",
        "rb.button.roundedbottom.horizontal.fill", "rb.circle", "rb.circle.fill", "rectangle.fill.on.rectangle.fill", "rectangle.on.rectangle", "rectangle.on.rectangle.button.angledtop.vertical.left", "rectangle.on.rectangle.button.angledtop.vertical.left.fill", "rectangle.on.rectangle.circle", "rectangle.on.rectangle.circle.fill", "rectangle.on.rectangle.square",
        "rectangle.on.rectangle.square.fill", "rm.button.horizontal", "rm.button.horizontal.fill", "rsb.button.angledbottom.horizontal.right", "rsb.button.angledbottom.horizontal.right.fill", "rt.button.roundedtop.horizontal", "rt.button.roundedtop.horizontal.fill", "rt.circle", "rt.circle.fill", "square.circle",
        "square.circle.fill", "triangle.circle", "triangle.circle.fill", "x.circle", "x.circle.fill", "xbox.logo", "xmark", "xmark.circle", "xmark.circle.fill", "y.circle",
        "y.circle.fill", "z.circle", "z.circle.fill", "zl.button.roundedtop.horizontal", "zl.button.roundedtop.horizontal.fill", "zr.button.roundedtop.horizontal", "zr.button.roundedtop.horizontal.fill"
    ]
    
    private let fitnessSymbols = [
        "1.lane",
        "10.lane",
        "11.lane",
        "12.lane",
        "2.lane",
        "3.lane",
        "4.lane",
        "5.lane",
        "6.lane",
        "7.lane",
        "8.lane",
        "9.lane",
        "american.football",
        "american.football.circle",
        "american.football.circle.fill",
        "american.football.fill",
        "american.football.professional",
        "american.football.professional.circle",
        "american.football.professional.circle.fill",
        "american.football.professional.fill",
        "australian.football",
        "australian.football.circle",
        "australian.football.circle.fill",
        "australian.football.fill",
        "baseball",
        "baseball.circle",
        "baseball.circle.fill",
        "baseball.diamond.bases",
        "baseball.diamond.bases.outs.indicator",
        "baseball.fill",
        "basketball",
        "basketball.circle",
        "basketball.circle.fill",
        "basketball.fill",
        "chevron.down.2",
        "chevron.down.forward.dotted.2",
        "chevron.down.right.dotted.2",
        "chevron.up.2",
        "chevron.up.forward.dotted.2",
        "chevron.up.right.dotted.2",
        "cricket.ball",
        "cricket.ball.circle",
        "cricket.ball.circle.fill",
        "cricket.ball.fill",
        "duffle.bag",
        "duffle.bag.fill",
        "dumbbell",
        "dumbbell.fill",
        "figure.american.football",
        "figure.american.football.circle",
        "figure.american.football.circle.fill",
        "figure.archery",
        "figure.archery.circle",
        "figure.archery.circle.fill",
        "figure.australian.football",
        "figure.australian.football.circle",
        "figure.australian.football.circle.fill",
        "figure.badminton",
        "figure.badminton.circle",
        "figure.badminton.circle.fill",
        "figure.barre",
        "figure.barre.circle",
        "figure.barre.circle.fill",
        "figure.baseball",
        "figure.baseball.circle",
        "figure.baseball.circle.fill",
        "figure.basketball",
        "figure.basketball.circle",
        "figure.basketball.circle.fill",
        "figure.bowling",
        "figure.bowling.circle",
        "figure.bowling.circle.fill",
        "figure.boxing",
        "figure.boxing.circle",
        "figure.boxing.circle.fill",
        "figure.climbing",
        "figure.climbing.circle",
        "figure.climbing.circle.fill",
        "figure.cooldown",
        "figure.cooldown.circle",
        "figure.cooldown.circle.fill",
        "figure.core.training",
        "figure.core.training.circle",
        "figure.core.training.circle.fill",
        "figure.cricket",
        "figure.cricket.circle",
        "figure.cricket.circle.fill",
        "figure.cross.training",
        "figure.cross.training.circle",
        "figure.cross.training.circle.fill",
        "figure.curling",
        "figure.curling.circle",
        "figure.curling.circle.fill",
        "figure.dance",
        "figure.dance.circle",
        "figure.dance.circle.fill",
        "figure.disc.sports",
        "figure.disc.sports.circle",
        "figure.disc.sports.circle.fill",
        "figure.elliptical",
        "figure.elliptical.circle",
        "figure.elliptical.circle.fill",
        "figure.equestrian.sports",
        "figure.equestrian.sports.circle",
        "figure.equestrian.sports.circle.fill",
        "figure.fencing",
        "figure.fencing.circle",
        "figure.fencing.circle.fill",
        "figure.field.hockey",
        "figure.field.hockey.circle",
        "figure.field.hockey.circle.fill",
        "figure.fishing",
        "figure.fishing.circle",
        "figure.fishing.circle.fill",
        "figure.flexibility",
        "figure.flexibility.circle",
        "figure.flexibility.circle.fill",
        "figure.golf",
        "figure.golf.circle",
        "figure.golf.circle.fill",
        "figure.gymnastics",
        "figure.gymnastics.circle",
        "figure.gymnastics.circle.fill",
        "figure.hand.cycling",
        "figure.hand.cycling.circle",
        "figure.hand.cycling.circle.fill",
        "figure.handball",
        "figure.handball.circle",
        "figure.handball.circle.fill",
        "figure.highintensity.intervaltraining",
        "figure.highintensity.intervaltraining.circle",
        "figure.highintensity.intervaltraining.circle.fill",
        "figure.hiking",
        "figure.hiking.circle",
        "figure.hiking.circle.fill",
        "figure.hockey",
        "figure.hockey.circle",
        "figure.hockey.circle.fill",
        "figure.hunting",
        "figure.hunting.circle",
        "figure.hunting.circle.fill",
        "figure.ice.hockey",
        "figure.ice.hockey.circle",
        "figure.ice.hockey.circle.fill",
        "figure.ice.skating",
        "figure.ice.skating.circle",
        "figure.ice.skating.circle.fill",
        "figure.indoor.cycle",
        "figure.indoor.cycle.circle",
        "figure.indoor.cycle.circle.fill",
        "figure.indoor.rowing",
        "figure.indoor.rowing.circle",
        "figure.indoor.rowing.circle.fill",
        "figure.indoor.soccer",
        "figure.indoor.soccer.circle",
        "figure.indoor.soccer.circle.fill",
        "figure.jumprope",
        "figure.jumprope.circle",
        "figure.jumprope.circle.fill",
        "figure.kickboxing",
        "figure.kickboxing.circle",
        "figure.kickboxing.circle.fill",
        "figure.lacrosse",
        "figure.lacrosse.circle",
        "figure.lacrosse.circle.fill",
        "figure.martial.arts",
        "figure.martial.arts.circle",
        "figure.martial.arts.circle.fill",
        "figure.mind.and.body",
        "figure.mind.and.body.circle",
        "figure.mind.and.body.circle.fill",
        "figure.mixed.cardio",
        "figure.mixed.cardio.circle",
        "figure.mixed.cardio.circle.fill",
        "figure.open.water.swim",
        "figure.open.water.swim.circle",
        "figure.open.water.swim.circle.fill",
        "figure.outdoor.cycle",
        "figure.outdoor.cycle.circle",
        "figure.outdoor.cycle.circle.fill",
        "figure.outdoor.rowing",
        "figure.outdoor.rowing.circle",
        "figure.outdoor.rowing.circle.fill",
        "figure.outdoor.soccer",
        "figure.outdoor.soccer.circle",
        "figure.outdoor.soccer.circle.fill",
        "figure.pickleball",
        "figure.pickleball.circle",
        "figure.pickleball.circle.fill",
        "figure.pilates",
        "figure.pilates.circle",
        "figure.pilates.circle.fill",
        "figure.play",
        "figure.play.circle",
        "figure.play.circle.fill",
        "figure.pool.swim",
        "figure.pool.swim.circle",
        "figure.pool.swim.circle.fill",
        "figure.racquetball",
        "figure.racquetball.circle",
        "figure.racquetball.circle.fill",
        "figure.roll",
        "figure.roll.circle",
        "figure.roll.circle.fill",
        "figure.roll.runningpace",
        "figure.roll.runningpace.circle",
        "figure.roll.runningpace.circle.fill",
        "figure.rolling",
        "figure.rolling.circle",
        "figure.rolling.circle.fill",
        "figure.rugby",
        "figure.rugby.circle",
        "figure.rugby.circle.fill",
        "figure.run",
        "figure.run.circle",
        "figure.run.circle.fill",
        "figure.run.square.stack",
        "figure.run.square.stack.fill",
        "figure.run.treadmill",
        "figure.run.treadmill.circle",
        "figure.run.treadmill.circle.fill",
        "figure.sailing",
        "figure.sailing.circle",
        "figure.sailing.circle.fill",
        "figure.skateboarding",
        "figure.skateboarding.circle",
        "figure.skateboarding.circle.fill",
        "figure.skiing.crosscountry",
        "figure.skiing.crosscountry.circle",
        "figure.skiing.crosscountry.circle.fill",
        "figure.skiing.downhill",
        "figure.skiing.downhill.circle",
        "figure.skiing.downhill.circle.fill",
        "figure.snowboarding",
        "figure.snowboarding.circle",
        "figure.snowboarding.circle.fill",
        "figure.socialdance",
        "figure.socialdance.circle",
        "figure.socialdance.circle.fill",
        "figure.softball",
        "figure.softball.circle",
        "figure.softball.circle.fill",
        "figure.squash",
        "figure.squash.circle",
        "figure.squash.circle.fill",
        "figure.stair.stepper",
        "figure.stair.stepper.circle",
        "figure.stair.stepper.circle.fill",
        "figure.stairs",
        "figure.stairs.circle",
        "figure.stairs.circle.fill",
        "figure.step.training",
        "figure.step.training.circle",
        "figure.step.training.circle.fill",
        "figure.strengthtraining.functional",
        "figure.strengthtraining.functional.circle",
        "figure.strengthtraining.functional.circle.fill",
        "figure.strengthtraining.traditional",
        "figure.strengthtraining.traditional.circle",
        "figure.strengthtraining.traditional.circle.fill",
        "figure.surfing",
        "figure.surfing.circle",
        "figure.surfing.circle.fill",
        "figure.table.tennis",
        "figure.table.tennis.circle",
        "figure.table.tennis.circle.fill",
        "figure.taichi",
        "figure.taichi.circle",
        "figure.taichi.circle.fill",
        "figure.tennis",
        "figure.tennis.circle",
        "figure.tennis.circle.fill",
        "figure.track.and.field",
        "figure.track.and.field.circle",
        "figure.track.and.field.circle.fill",
        "figure.volleyball",
        "figure.volleyball.circle",
        "figure.volleyball.circle.fill",
        "figure.walk",
        "figure.walk.circle",
        "figure.walk.circle.fill",
        "figure.walk.diamond",
        "figure.walk.diamond.fill",
        "figure.walk.motion",
        "figure.walk.motion.trianglebadge.exclamationmark",
        "figure.walk.treadmill",
        "figure.walk.treadmill.circle",
        "figure.walk.treadmill.circle.fill",
        "figure.water.fitness",
        "figure.water.fitness.circle",
        "figure.water.fitness.circle.fill",
        "figure.waterpolo",
        "figure.waterpolo.circle",
        "figure.waterpolo.circle.fill",
        "figure.wrestling",
        "figure.wrestling.circle",
        "figure.wrestling.circle.fill",
        "figure.yoga",
        "figure.yoga.circle",
        "figure.yoga.circle.fill",
        "flag.2.crossed",
        "flag.2.crossed.circle",
        "flag.2.crossed.circle.fill",
        "flag.2.crossed.fill",
        "flag.and.flag.filled.crossed",
        "flag.filled.and.flag.crossed",
        "flag.pattern.checkered",
        "flag.pattern.checkered.2.crossed",
        "flag.pattern.checkered.circle",
        "flag.pattern.checkered.circle.fill",
        "gamecontroller",
        "gamecontroller.circle",
        "gamecontroller.circle.fill",
        "gamecontroller.fill",
        "gauge.with.needle",
        "gauge.with.needle.fill",
        "hockey.puck",
        "hockey.puck.circle",
        "hockey.puck.circle.fill",
        "hockey.puck.fill",
        "lane",
        "medal",
        "medal.fill",
        "oar.2.crossed",
        "oar.2.crossed.circle",
        "oar.2.crossed.circle.fill",
        "rugbyball",
        "rugbyball.circle",
        "rugbyball.circle.fill",
        "rugbyball.fill",
        "skateboard",
        "skateboard.fill",
        "skis",
        "skis.fill",
        "snowboard",
        "snowboard.fill",
        "soccerball",
        "soccerball.circle",
        "soccerball.circle.fill",
        "soccerball.circle.fill.inverse",
        "soccerball.circle.inverse",
        "soccerball.inverse",
        "sportscourt",
        "sportscourt.circle",
        "sportscourt.circle.fill",
        "sportscourt.fill",
        "surfboard",
        "surfboard.fill",
        "tennis.racket",
        "tennis.racket.circle",
        "tennis.racket.circle.fill",
        "tennisball",
        "tennisball.circle",
        "tennisball.circle.fill",
        "tennisball.fill",
        "trophy",
        "trophy.circle",
        "trophy.circle.fill",
        "trophy.fill",
        "volleyball",
        "volleyball.circle",
        "volleyball.circle.fill",
        "volleyball.fill",
        "water.waves",
        "water.waves.and.arrow.trianglehead.down",
        "water.waves.and.arrow.trianglehead.down.trianglebadge.exclamationmark",
        "water.waves.and.arrow.trianglehead.up",
        "water.waves.slash"
    ]
    
    private let natureSymbols = [
        "allergens",
        "allergens.fill",
        "ant",
        "ant.circle",
        "ant.circle.fill",
        "ant.fill",
        "apple.meditate",
        "apple.meditate.circle",
        "apple.meditate.circle.fill",
        "apple.meditate.square.stack",
        "apple.meditate.square.stack.fill",
        "atom",
        "bird",
        "bird.circle",
        "bird.circle.fill",
        "bird.fill",
        "bolt",
        "bolt.badge.automatic",
        "bolt.badge.automatic.fill",
        "bolt.badge.checkmark",
        "bolt.badge.checkmark.fill",
        "bolt.badge.clock",
        "bolt.badge.clock.fill",
        "bolt.badge.xmark",
        "bolt.badge.xmark.fill",
        "bolt.circle",
        "bolt.circle.fill",
        "bolt.fill",
        "bolt.shield",
        "bolt.shield.fill",
        "bolt.slash",
        "bolt.slash.circle",
        "bolt.slash.circle.fill",
        "bolt.slash.fill",
        "bolt.square",
        "bolt.square.fill",
        "bolt.trianglebadge.exclamationmark",
        "bolt.trianglebadge.exclamationmark.fill",
        "camera.macro",
        "camera.macro.circle",
        "camera.macro.circle.fill",
        "camera.macro.slash",
        "camera.macro.slash.circle",
        "camera.macro.slash.circle.fill",
        "carrot",
        "carrot.fill",
        "cat",
        "cat.circle",
        "cat.circle.fill",
        "cat.fill",
        "cloud",
        "cloud.bolt",
        "cloud.bolt.circle",
        "cloud.bolt.circle.fill",
        "cloud.bolt.fill",
        "cloud.bolt.rain",
        "cloud.bolt.rain.circle",
        "cloud.bolt.rain.circle.fill",
        "cloud.bolt.rain.fill",
        "cloud.circle",
        "cloud.circle.fill",
        "cloud.drizzle",
        "cloud.drizzle.circle",
        "cloud.drizzle.circle.fill",
        "cloud.drizzle.fill",
        "cloud.fill",
        "cloud.fog",
        "cloud.fog.circle",
        "cloud.fog.circle.fill",
        "cloud.fog.fill",
        "cloud.hail",
        "cloud.hail.circle",
        "cloud.hail.circle.fill",
        "cloud.hail.fill",
        "cloud.heavyrain",
        "cloud.heavyrain.circle",
        "cloud.heavyrain.circle.fill",
        "cloud.heavyrain.fill",
        "cloud.moon",
        "cloud.moon.bolt",
        "cloud.moon.bolt.circle",
        "cloud.moon.bolt.circle.fill",
        "cloud.moon.bolt.fill",
        "cloud.moon.circle",
        "cloud.moon.circle.fill",
        "cloud.moon.fill",
        "cloud.moon.rain",
        "cloud.moon.rain.circle",
        "cloud.moon.rain.circle.fill",
        "cloud.moon.rain.fill",
        "cloud.rain",
        "cloud.rain.circle",
        "cloud.rain.circle.fill",
        "cloud.rain.fill",
        "cloud.rainbow.crop",
        "cloud.rainbow.crop.fill",
        "cloud.sleet",
        "cloud.sleet.circle",
        "cloud.sleet.circle.fill",
        "cloud.sleet.fill",
        "cloud.snow",
        "cloud.snow.circle",
        "cloud.snow.circle.fill",
        "cloud.snow.fill",
        "cloud.sun",
        "cloud.sun.bolt",
        "cloud.sun.bolt.circle",
        "cloud.sun.bolt.circle.fill",
        "cloud.sun.bolt.fill",
        "cloud.sun.circle",
        "cloud.sun.circle.fill",
        "cloud.sun.fill",
        "cloud.sun.rain",
        "cloud.sun.rain.circle",
        "cloud.sun.rain.circle.fill",
        "cloud.sun.rain.fill",
        "dog",
        "dog.circle",
        "dog.circle.fill",
        "dog.fill",
        "drop",
        "drop.circle",
        "drop.circle.fill",
        "drop.degreesign",
        "drop.degreesign.fill",
        "drop.degreesign.slash",
        "drop.degreesign.slash.fill",
        "drop.fill",
        "drop.triangle",
        "drop.triangle.fill",
        "environments",
        "environments.circle",
        "environments.circle.fill",
        "environments.fill",
        "environments.slash",
        "environments.slash.circle",
        "environments.slash.circle.fill",
        "environments.slash.fill",
        "fish",
        "fish.circle",
        "fish.circle.fill",
        "fish.fill",
        "flame",
        "flame.circle",
        "flame.circle.fill",
        "flame.fill",
        "fossil.shell",
        "fossil.shell.fill",
        "globe.americas",
        "globe.americas.fill",
        "globe.asia.australia",
        "globe.asia.australia.fill",
        "globe.central.south.asia",
        "globe.central.south.asia.fill",
        "globe.europe.africa",
        "globe.europe.africa.fill",
        "hare",
        "hare.circle",
        "hare.circle.fill",
        "hare.fill",
        "humidity",
        "humidity.fill",
        "hurricane",
        "hurricane.circle",
        "hurricane.circle.fill",
        "ladybug",
        "ladybug.circle",
        "ladybug.circle.fill",
        "ladybug.fill",
        "ladybug.slash",
        "ladybug.slash.circle",
        "ladybug.slash.circle.fill",
        "ladybug.slash.fill",
        "laurel.leading",
        "laurel.trailing",
        "leaf",
        "leaf.arrow.trianglehead.clockwise",
        "leaf.circle",
        "leaf.circle.fill",
        "leaf.fill",
        "lizard",
        "lizard.circle",
        "lizard.circle.fill",
        "lizard.fill",
        "microbe",
        "microbe.circle",
        "microbe.circle.fill",
        "microbe.fill",
        "moon",
        "moon.circle",
        "moon.circle.fill",
        "moon.dust",
        "moon.dust.circle",
        "moon.dust.circle.fill",
        "moon.dust.fill",
        "moon.fill",
        "moon.haze",
        "moon.haze.circle",
        "moon.haze.circle.fill",
        "moon.haze.fill",
        "moon.stars",
        "moon.stars.circle",
        "moon.stars.circle.fill",
        "moon.stars.fill",
        "moonphase.first.quarter",
        "moonphase.first.quarter.inverse",
        "moonphase.full.moon",
        "moonphase.full.moon.inverse",
        "moonphase.last.quarter",
        "moonphase.last.quarter.inverse",
        "moonphase.new.moon",
        "moonphase.new.moon.inverse",
        "moonphase.waning.crescent",
        "moonphase.waning.crescent.inverse",
        "moonphase.waning.gibbous",
        "moonphase.waning.gibbous.inverse",
        "moonphase.waxing.crescent",
        "moonphase.waxing.crescent.inverse",
        "moonphase.waxing.gibbous",
        "moonphase.waxing.gibbous.inverse",
        "mountain.2",
        "mountain.2.circle",
        "mountain.2.circle.fill",
        "mountain.2.fill",
        "pawprint",
        "pawprint.circle",
        "pawprint.circle.fill",
        "pawprint.fill",
        "rainbow",
        "service.dog",
        "service.dog.fill",
        "smoke",
        "smoke.circle",
        "smoke.circle.fill",
        "smoke.fill",
        "snowflake",
        "snowflake.circle",
        "snowflake.circle.fill",
        "snowflake.slash",
        "sparkles",
        "sun.dust",
        "sun.dust.circle",
        "sun.dust.circle.fill",
        "sun.dust.fill",
        "sun.haze",
        "sun.haze.circle",
        "sun.haze.circle.fill",
        "sun.haze.fill",
        "sun.horizon",
        "sun.horizon.circle",
        "sun.horizon.circle.fill",
        "sun.horizon.fill",
        "sun.max",
        "sun.max.circle",
        "sun.max.circle.fill",
        "sun.max.fill",
        "sun.max.trianglebadge.exclamationmark",
        "sun.max.trianglebadge.exclamationmark.fill",
        "sun.min",
        "sun.min.fill",
        "sun.rain",
        "sun.rain.circle",
        "sun.rain.circle.fill",
        "sun.rain.fill",
        "sun.snow",
        "sun.snow.circle",
        "sun.snow.circle.fill",
        "sun.snow.fill",
        "sunrise",
        "sunrise.circle",
        "sunrise.circle.fill",
        "sunrise.fill",
        "sunset",
        "sunset.circle",
        "sunset.circle.fill",
        "sunset.fill",
        "thermometer.snowflake",
        "thermometer.snowflake.circle",
        "thermometer.snowflake.circle.fill",
        "thermometer.sun",
        "thermometer.sun.circle",
        "thermometer.sun.circle.fill",
        "thermometer.sun.fill",
        "thermometer.variable",
        "thermometer.variable.and.figure",
        "thermometer.variable.and.figure.circle",
        "thermometer.variable.and.figure.circle.fill",
        "thermometer.variable.badge.clock",
        "thermometer.variable.badge.play",
        "tornado",
        "tornado.circle",
        "tornado.circle.fill",
        "tortoise",
        "tortoise.circle",
        "tortoise.circle.fill",
        "tortoise.fill",
        "tree",
        "tree.circle",
        "tree.circle.fill",
        "tree.fill",
        "tropicalstorm",
        "tropicalstorm.circle",
        "tropicalstorm.circle.fill",
        "water.waves",
        "water.waves.and.arrow.trianglehead.down",
        "water.waves.and.arrow.trianglehead.down.trianglebadge.exclamationmark",
        "water.waves.and.arrow.trianglehead.up",
        "water.waves.slash",
        "wind",
        "wind.circle",
        "wind.circle.fill",
        "wind.snow",
        "wind.snow.circle",
        "wind.snow.circle.fill",
    ]
    
    private let schoolSymbols = [
        "book", "book.fill", "book.closed", "book.closed.fill",
        "text.book.closed", "text.book.closed.fill",
        "graduationcap", "graduationcap.fill",
        "pencil", "pencil.circle", "pencil.circle.fill",
        "pencil.and.outline",
        "highlighter",
        "paperplane", "paperplane.fill",
        "lasso",
        "folder", "folder.fill",
        "doc", "doc.fill",
        "doc.text", "doc.text.fill",
        "doc.richtext", "doc.richtext.fill",
        "text.alignleft", "text.aligncenter",
        "text.alignright", "text.justify",
        "studentdesk",
        "brain.head.profile"
    ]
    
    private let workSymbols = [
        "briefcase", "briefcase.fill",
        "calendar", "calendar.badge.clock", "calendar.badge.exclamationmark",
        "clock", "alarm",
        "hourglass", "hourglass.bottomhalf.filled",
        "chart.bar", "chart.bar.fill",
        "chart.line.uptrend.xyaxis", "chart.xyaxis.line",
        "list.bullet", "list.bullet.rectangle.portrait", "checklist",
        "tray", "tray.fill", "tray.full", "tray.full.fill",
        "folder", "folder.fill",
        "doc.badge.gearshape", "doc.text.magnifyingglass",
        "envelope", "envelope.fill",
        "paperclip", "paperclip.circle", "paperclip.circle.fill",
        "person.text.rectangle"
    ]
    
    private let exerciseSymbols = [
        "figure.walk", "figure.walk.circle", "figure.walk.circle.fill",
        "figure.run", "figure.run.circle", "figure.run.circle.fill",
        "figure.strengthtraining.traditional",
        "figure.core.training",
        "figure.flexibility",
        "figure.cooldown",
        "figure.indoor.cycle",
        "bicycle",
        "flame", "flame.fill",
        "heart", "heart.fill", "bolt.heart",
        "sportscourt", "sportscourt.fill",
        "dumbbell", "dumbbell.fill",
        "figure.mind.and.body",
        "figure.yoga", "figure.pilates",
        "shoeprints.fill",
        "lungs.fill",
        "speedometer",
        "stopwatch",
        "figure.stairs",
        "medal.fill"
    ]
    
    private let lifestyleSymbols = [
        "sun.max", "sun.max.fill",
        "moon.stars", "moon.stars.fill",
        "house", "house.fill", "house.and.flag",
        "bed.double", "bed.double.fill",
        "sofa.fill",
        "lamp.table.fill",
        "cart", "cart.fill",
        "bag", "bag.fill",
        "wineglass", "wineglass.fill",
        "mug.fill",
        "fork.knife",
        "takeoutbag.and.cup.and.straw.fill",
        "leaf", "leaf.fill",
        "camera", "camera.fill",
        "photo", "photo.fill",
        "music.note", "music.note.list",
        "sparkles",
        "theatermasks.fill"
    ]
    
    private let sportsSymbols = [
        "sportscourt", "sportscourt.fill",
        "basketball", "basketball.fill",
        "soccerball", "soccerball.fill",
        "tennis.racket",
        "baseball", "baseball.fill",
        "football", "football.fill",
        "cricket.ball.fill",
        "hockey.puck", "hockey.puck.fill",
        "figure.golf",
        "figure.badminton",
        "figure.boxing",
        "figure.archery",
        "figure.skiing.downhill",
        "figure.snowboarding",
        "flag", "flag.fill",
        "target",
        "trophy", "trophy.fill",
        "medal", "medal.fill",
        "laurel.leading", "laurel.trailing"
    ]
    
    private let techSymbols = [
        "iphone", "iphone.gen3",
        "ipad",
        "laptopcomputer",
        "desktopcomputer",
        "macbook",
        "display",
        "tv",
        "applewatch",
        "airpods", "airpodspro",
        "keyboard", "keyboard.fill",
        "printer", "printer.fill",
        "wifi", "wifi.circle", "wifi.circle.fill",
        "antenna.radiowaves.left.and.right",
        "router",
        "cpu",
        "memorychip",
        "gearshape", "gearshape.fill",
        "bolt", "bolt.fill",
        "battery.100", "battery.25",
        "cloud",
        "server.rack"
    ]
    
    private let familySymbols = [
        "person", "person.fill",
        "person.2", "person.2.fill",
        "person.3", "person.3.fill",
        "figure.child",
        "figure.2.child.holdinghands",
        "figure.and.child.holdinghands",
        "figure.2.and.child.holdinghands",
        "house", "house.fill",
        "heart", "heart.fill",
        "calendar.badge.heart",
        "gift", "gift.fill",
        "car", "car.fill",
        "photo.on.rectangle",
        "photo.stack",
        "person.crop.circle.badge.checkmark",
        "person.crop.circle.badge.questionmark",
        "person.line.dotted.person",
        "hands.sparkles.fill",
        "hand.raised.fill",
        "figure.2",
        "person.2.badge.gearshape",
        "person.crop.circle"
    ]
    
    private let mindfulnessSymbols = [
        "brain.head.profile",
        "figure.mind.and.body",
        "figure.cooldown",
        "figure.yoga",
        "figure.seated.side",
        "figure.lotus",
        "spa", "spa.fill",
        "leaf", "leaf.fill",
        "wind",
        "drop", "drop.fill",
        "water.waves",
        "waveform",
        "waveform.path.ecg",
        "sparkles",
        "sun.max",
        "moon", "moon.stars",
        "heart.text.square", "heart.text.square.fill",
        "face.smiling", "smiley",
        "cloud",
        "cloud.sun", "cloud.moon",
        "clock",
        "pause.circle"
    ]
    
    private let peopleSymbols = [
        "person", "person.fill",
        "person.circle", "person.circle.fill",
        "person.crop.circle", "person.crop.circle.fill",
        "person.crop.square", "person.crop.square.fill",
        "person.crop.rectangle", "person.crop.rectangle.fill",
        "person.crop.circle.badge.plus",
        "person.crop.circle.badge.minus",
        "person.crop.circle.badge.checkmark",
        "person.crop.circle.badge.xmark",
        "person.fill.turn.right",
        "person.fill.turn.left",
        "person.badge.plus",
        "person.badge.minus",
        "person.2", "person.2.fill", "person.2.circle",
        "person.3", "person.3.fill",
        "person.2.wave.2",
        "person.2.gobackward",
        "person.2.crop.square.stack",
        "person.and.arrow.left.and.arrow.right",
        "person.line.dotted.person",
        "person.icloud", "person.icloud.fill"
    ]
    
    private var allBaseNames: [String] {
        Array(Set(
            gamingSymbols +
            fitnessSymbols +
            natureSymbols +
            
            schoolSymbols +
            workSymbols +
            exerciseSymbols +
            lifestyleSymbols +
            sportsSymbols +
            techSymbols +
            familySymbols +
            mindfulnessSymbols +
            peopleSymbols
        ))
    }
    
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 56), spacing: 16)
    ]
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Group {
                if verticalSizeClass == .compact {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(IconCategory.allCases) { category in
                            Text(category.title).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                } else {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(IconCategory.allCases) { category in
                            Text(category.title).tag(category)
                        }
                    }
                    .pickerStyle(.automatic)
                }
            }
            .padding([.horizontal, .top])
            
            
            ScrollView {
                if displayedSymbols.isEmpty {
                    VStack(spacing: 12) {
                        Text("No symbols")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if selectedCategory == .recent {
                            Text("Recently used icons will appear here.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(displayedSymbols) { symbol in
                            Button {
                                select(symbol.name)
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: symbol.name)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 28)
                                    
                                    Text(symbol.name)
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Choose Icon")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search symbols")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .onAppear {
            if allSymbols.isEmpty {
                loadAllSymbols()
            }
            loadRecentIcons()
        }
    }
    
    // MARK: - Filtering
    
    private var displayedSymbols: [SymbolItem] {
        let base = symbolsForSelectedCategory()
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private func symbolsForSelectedCategory() -> [SymbolItem] {
        switch selectedCategory {
        case .recent:
            let recentSet = Set(recentIcons)
            return allSymbols.filter { recentSet.contains($0.name) }
        case .all:
            return allSymbols
        case .gaming:
            return allSymbols.filter { gamingSymbols.contains($0.name)}
        case .fitness:
            return allSymbols.filter { fitnessSymbols.contains($0.name) }
        case .nature:
            return allSymbols.filter { natureSymbols.contains($0.name) }
            
            
        case .school:
            return allSymbols.filter { schoolSymbols.contains($0.name) }
        case .work:
            return allSymbols.filter { workSymbols.contains($0.name) }
        case .exercise:
            return allSymbols.filter { exerciseSymbols.contains($0.name) }
        case .lifestyle:
            return allSymbols.filter { lifestyleSymbols.contains($0.name) }
        case .sports:
            return allSymbols.filter { sportsSymbols.contains($0.name) }
        case .tech:
            return allSymbols.filter { techSymbols.contains($0.name) }
        case .family:
            return allSymbols.filter { familySymbols.contains($0.name) }
        case .mindfulness:
            return allSymbols.filter { mindfulnessSymbols.contains($0.name) }
        case .people:
            return allSymbols.filter { peopleSymbols.contains($0.name) }
        }
    }
    
    // MARK: - Data setup
    
    private func loadAllSymbols() {
        // Only keep symbols that are actually available on this OS
        // and are not already used by other Activity records or categories
        allSymbols = allBaseNames
            .filter { UIImage(systemName: $0) != nil }
            .filter { !excludedIconNames.contains($0) }
            .sorted()
            .map { SymbolItem(name: $0) }
    }
    
    private func loadRecentIcons() {
        guard !recentIconNamesStorage.isEmpty else {
            recentIcons = []
            return
        }
        recentIcons = recentIconNamesStorage
            .split(separator: ",")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }
    
    private func saveRecentIcons() {
        recentIconNamesStorage = recentIcons.joined(separator: ",")
    }
    
    // MARK: - Selection / recents
    
    private func select(_ symbolName: String) {
        selectedIcon = symbolName
        updateRecent(with: symbolName)
        dismiss()
    }
    
    private func updateRecent(with symbolName: String) {
        // Move to front, keep unique, limit to 20
        recentIcons.removeAll { $0 == symbolName }
        recentIcons.insert(symbolName, at: 0)
        
        if recentIcons.count > 20 {
            recentIcons = Array(recentIcons.prefix(20))
        }
        
        saveRecentIcons()
    }
}

