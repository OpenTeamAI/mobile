import CoreData
import Foundation

final class PortalCache {
    private let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PortalCache", managedObjectModel: Self.makeModel())
        if inMemory {
            let store = NSPersistentStoreDescription()
            store.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [store]
        }
        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Portal cache failed to load: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save<T: Encodable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder.portal.encode(value)
        let context = container.viewContext

        var caughtError: Error?
        context.performAndWait {
            do {
                let object = try fetchObject(forKey: key, in: context) ?? NSEntityDescription.insertNewObject(
                    forEntityName: "CachedPayload",
                    into: context
                )
                object.setValue(key, forKey: "key")
                object.setValue(data, forKey: "data")
                object.setValue(Date(), forKey: "updatedAt")
                try context.save()
            } catch {
                caughtError = error
            }
        }
        if let caughtError {
            throw caughtError
        }
    }

    func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        let context = container.viewContext
        var data: Data?

        var caughtError: Error?
        context.performAndWait {
            do {
                let object = try fetchObject(forKey: key, in: context)
                data = object?.value(forKey: "data") as? Data
            } catch {
                caughtError = error
            }
        }
        if let caughtError {
            throw caughtError
        }

        guard let data else {
            return nil
        }
        return try JSONDecoder.portal.decode(T.self, from: data)
    }

    private func fetchObject(forKey key: String, in context: NSManagedObjectContext) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CachedPayload")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "key == %@", key)
        return try context.fetch(request).first
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "CachedPayload"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let key = NSAttributeDescription()
        key.name = "key"
        key.attributeType = .stringAttributeType
        key.isOptional = false

        let data = NSAttributeDescription()
        data.name = "data"
        data.attributeType = .binaryDataAttributeType
        data.isOptional = false

        let updatedAt = NSAttributeDescription()
        updatedAt.name = "updatedAt"
        updatedAt.attributeType = .dateAttributeType
        updatedAt.isOptional = false

        entity.properties = [key, data, updatedAt]
        model.entities = [entity]
        return model
    }
}
