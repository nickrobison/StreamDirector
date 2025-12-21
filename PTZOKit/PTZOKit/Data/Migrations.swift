//
//  Migrations.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/26/25.
//

import Foundation
import GRDB

struct Migrator {
    let database: DatabaseQueue
    func migrate() throws {
        
        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        migrator.registerMigration("Create initial tables") { db in
            try db.create(table: "Cameras") { t in
                t.primaryKey("id", .text).notNull(onConflict: .replace).defaults(sql: "uuid()")
                t.column("name", .text).notNull()
                t.column("hostname", .text).notNull()
                t.column("port", .integer).notNull()
                t.column("configuration", .jsonText).notNull()
            }
            
            try db.create(table: "Presets") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text)
                t.column("cameraId", .text).references("cameras", column: "id", onDelete: .cascade)
            }
        }
        
        
        try migrator.migrate(database)
    }
}

#if DEBUG
extension Database {
    func seedPTZOSampleData() throws {
        try seed {
            CameraRecord(id: UUID(1), name: "Camera 1", hostname: "camera1.local", port: 1234, configuration: CameraConfiguration(username: "admin", password: "test"))
            CameraRecord(id: UUID(2), name: "Camera 2", hostname: "camera2.local", port: 1234, configuration: CameraConfiguration(username: "admin", password: "test"))
            
            
            for (index, name) in ["Alter", "Lectern", "Entry"].enumerated() {
                PresetRecord(id: index, name: name, cameraId: UUID(1), value: .presetID(String(index)))
            }
        }
    }
}
#endif
