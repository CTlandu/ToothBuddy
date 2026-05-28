import CoreData
import ToothBuddyCore

// MARK: - Managed object subclasses

@objc(CDProfile)
final class CDProfile: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var colorTag: String?
    @NSManaged var symbol: String?
    @NSManaged var birthYear: NSNumber?
    @NSManaged var creatorLabel: String?
    @NSManaged var createdAt: Date?
    @NSManaged var modifiedAt: Date?
    @NSManaged var mode: String?            // Spec 05 §7 — additive, default "kid"
    @NSManaged var records: NSSet?
    @NSManaged var care: CDProfileCare?
    @NSManaged var achievements: NSSet?
    @NSManaged var group: CDGroup?
}

@objc(CDGroup)
final class CDGroup: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var createdAt: Date?
    @NSManaged var modifiedAt: Date?
    @NSManaged var members: NSSet?
}

@objc(CDBrushingRecord)
final class CDBrushingRecord: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var startDate: Date?
    @NSManaged var endDate: Date?
    @NSManaged var modifiedAt: Date?
    @NSManaged var profile: CDProfile?
}

@objc(CDProfileCare)
final class CDProfileCare: NSManagedObject {
    @NSManaged var lastBrushHeadReplaced: Date?
    @NSManaged var brushHeadIntervalDays: Int64
    @NSManaged var lastDentistVisit: Date?
    @NSManaged var dentistIntervalDays: Int64
    @NSManaged var modifiedAt: Date?
    @NSManaged var profile: CDProfile?
}

@objc(CDAchievementUnlock)
final class CDAchievementUnlock: NSManagedObject {
    @NSManaged var achievementID: String?
    @NSManaged var unlockedAt: Date?
    @NSManaged var profile: CDProfile?
}

// MARK: - Programmatic model (no .xcdatamodeld; CloudKit-compatible:
// every attribute optional or defaulted, all relationships have inverses,
// no unique constraints — so P2.5 can enable the CloudKit container with no migration).

enum ToothBuddyModel {
    // Built once at launch, then read-only; Core Data types predate Sendable.
    // AUDIT 2026-05-28 (Plan U1): `nonisolated(unsafe)` is endorsed by SE-0412 for
    // "developer-managed isolation" — here the developer-managed part is "built
    // exactly once at first access, then never mutated again". `NSManagedObjectModel`
    // is documented thread-safe after configuration. The cleaner alternatives
    // (`@MainActor`, wrapping in an actor) would force every Core Data context
    // initializer to become async, which would cascade through all 11 stores.
    nonisolated(unsafe) static let shared: NSManagedObjectModel = build()

    private static func attr(_ name: String, _ type: NSAttributeType,
                             optional: Bool = true, def: Any? = nil) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = type
        a.isOptional = optional
        if let def { a.defaultValue = def }
        return a
    }

    private static func build() -> NSManagedObjectModel {
        let profile = NSEntityDescription()
        profile.name = "CDProfile"
        profile.managedObjectClassName = "CDProfile"

        let record = NSEntityDescription()
        record.name = "CDBrushingRecord"
        record.managedObjectClassName = "CDBrushingRecord"

        let care = NSEntityDescription()
        care.name = "CDProfileCare"
        care.managedObjectClassName = "CDProfileCare"

        let ach = NSEntityDescription()
        ach.name = "CDAchievementUnlock"
        ach.managedObjectClassName = "CDAchievementUnlock"

        let group = NSEntityDescription()
        group.name = "CDGroup"
        group.managedObjectClassName = "CDGroup"

        profile.properties = [
            attr("id", .UUIDAttributeType),
            attr("name", .stringAttributeType),
            attr("colorTag", .stringAttributeType),
            attr("symbol", .stringAttributeType),
            attr("birthYear", .integer64AttributeType),
            attr("creatorLabel", .stringAttributeType),
            attr("createdAt", .dateAttributeType),
            attr("modifiedAt", .dateAttributeType),
            // Spec 05 §7 — additive, optional + default ⇒ existing rows read as "kid"
            // (same zero-loss CloudKit-compatible rule as the P2.1 schema).
            attr("mode", .stringAttributeType, optional: true, def: "kid")
        ]
        record.properties = [
            attr("id", .UUIDAttributeType),
            attr("startDate", .dateAttributeType),
            attr("endDate", .dateAttributeType),
            attr("modifiedAt", .dateAttributeType)
        ]
        care.properties = [
            attr("lastBrushHeadReplaced", .dateAttributeType),
            attr("brushHeadIntervalDays", .integer64AttributeType, optional: false, def: 90),
            attr("lastDentistVisit", .dateAttributeType),
            attr("dentistIntervalDays", .integer64AttributeType, optional: false, def: 180),
            attr("modifiedAt", .dateAttributeType)
        ]
        ach.properties = [
            attr("achievementID", .stringAttributeType),
            attr("unlockedAt", .dateAttributeType)
        ]
        group.properties = [
            attr("id", .UUIDAttributeType),
            attr("name", .stringAttributeType),
            attr("createdAt", .dateAttributeType),
            attr("modifiedAt", .dateAttributeType)
        ]

        // Relationships (all with inverses — required for CloudKit).
        let pToR = NSRelationshipDescription()
        pToR.name = "records"; pToR.destinationEntity = record
        pToR.minCount = 0; pToR.maxCount = 0; pToR.deleteRule = .cascadeDeleteRule
        let rToP = NSRelationshipDescription()
        rToP.name = "profile"; rToP.destinationEntity = profile
        rToP.minCount = 0; rToP.maxCount = 1; rToP.deleteRule = .nullifyDeleteRule
        pToR.inverseRelationship = rToP; rToP.inverseRelationship = pToR

        let pToCare = NSRelationshipDescription()
        pToCare.name = "care"; pToCare.destinationEntity = care
        pToCare.minCount = 0; pToCare.maxCount = 1; pToCare.deleteRule = .cascadeDeleteRule
        let careToP = NSRelationshipDescription()
        careToP.name = "profile"; careToP.destinationEntity = profile
        careToP.minCount = 0; careToP.maxCount = 1; careToP.deleteRule = .nullifyDeleteRule
        pToCare.inverseRelationship = careToP; careToP.inverseRelationship = pToCare

        let pToA = NSRelationshipDescription()
        pToA.name = "achievements"; pToA.destinationEntity = ach
        pToA.minCount = 0; pToA.maxCount = 0; pToA.deleteRule = .cascadeDeleteRule
        let aToP = NSRelationshipDescription()
        aToP.name = "profile"; aToP.destinationEntity = profile
        aToP.minCount = 0; aToP.maxCount = 1; aToP.deleteRule = .nullifyDeleteRule
        pToA.inverseRelationship = aToP; aToP.inverseRelationship = pToA

        // Group ↔ members (Spec 02 §6.4 / §7.1). Optional; nil = pure-solo.
        let gToM = NSRelationshipDescription()
        gToM.name = "members"; gToM.destinationEntity = profile
        gToM.minCount = 0; gToM.maxCount = 0; gToM.deleteRule = .nullifyDeleteRule
        let pToG = NSRelationshipDescription()
        pToG.name = "group"; pToG.destinationEntity = group
        pToG.minCount = 0; pToG.maxCount = 1; pToG.deleteRule = .nullifyDeleteRule
        gToM.inverseRelationship = pToG; pToG.inverseRelationship = gToM

        profile.properties += [pToR, pToCare, pToA, pToG]
        record.properties += [rToP]
        care.properties += [careToP]
        ach.properties += [aToP]
        group.properties += [gToM]

        let model = NSManagedObjectModel()
        model.entities = [profile, record, care, ach, group]
        return model
    }
}

// MARK: - Persistence controller

/// Local Core Data stack. Uses `NSPersistentCloudKitContainer` so P2.5 only needs to add
/// `cloudKitContainerOptions` + entitlements (no model migration — schema is already
/// CloudKit-compatible). For now it is local-only.
final class PersistenceController {
    // Single shared stack, accessed from @MainActor stores; viewContext is main-queue.
    // AUDIT 2026-05-28 (Plan U1): `nonisolated(unsafe)` is the right choice here per
    // SE-0412 — the safety invariant is that `viewContext` is touched only from the
    // main queue (every store is `@MainActor`-isolated). Static-let creates the
    // controller lazily and exactly once; `container` is configured before any
    // `viewContext` access. Wrapping in `@MainActor` would force the static to be
    // async-accessed, which breaks the singleton pattern used by all `*.shared` stores.
    nonisolated(unsafe) static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ToothBuddy",
                                                  managedObjectModel: ToothBuddyModel.shared)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        // P2.5 TODO: set description.cloudKitContainerOptions + iCloud entitlements.
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber,
            forKey: NSPersistentHistoryTrackingKey)
        container.loadPersistentStores { _, error in
            if let error { assertionFailure("Core Data load failed: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy =
            NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
    }

    var viewContext: NSManagedObjectContext { container.viewContext }

    func save() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        do { try ctx.save() } catch { assertionFailure("Core Data save failed: \(error)") }
    }
}

// MARK: - Managed ↔ DTO mapping (ToothBuddyCore value types are the testable truth)

extension CDProfile {
    func toDTO() -> Profile? {
        guard let id, let name,
              let color = ProfileColor(rawValue: colorTag ?? ""),
              let sym = ProfileSymbol(rawValue: symbol ?? "") else { return nil }
        return Profile(id: id, name: name, colorTag: color, symbol: sym,
                       birthYear: birthYear?.intValue,
                       creatorLabel: creatorLabel ?? "",
                       createdAt: createdAt ?? Date(),
                       modifiedAt: modifiedAt ?? Date(),
                       mode: ProfileMode(rawValue: mode ?? "kid") ?? .kid)
    }

    func apply(_ p: Profile) {
        id = p.id; name = p.name
        colorTag = p.colorTag.rawValue; symbol = p.symbol.rawValue
        birthYear = p.birthYear.map(NSNumber.init(value:))
        creatorLabel = p.creatorLabel
        createdAt = p.createdAt; modifiedAt = p.modifiedAt
        mode = p.mode.rawValue
    }
}

extension CDBrushingRecord {
    func toDTO() -> BrushingRecord? {
        guard let id, let pid = profile?.id, let startDate, let endDate else { return nil }
        return BrushingRecord(id: id, profileID: pid, startDate: startDate, endDate: endDate)
    }
}
