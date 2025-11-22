import Foundation
import SQLite

/// Database for storing architectural validation rules
class RuleDatabase {
    private let db: Connection
    private let dbPath: String
    
    init() throws {
        // Use user's home directory for database
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let dbDir = homeDir.appendingPathComponent(".smith-validation")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
        
        dbPath = dbDir.appendingPathComponent("rules.sqlite3").path
        
        // Initialize database
        db = try Connection(dbPath)
        
        // Create tables if they don't exist
        try createTables()
        
        print("🗄️ Database initialized at: \(dbPath)")
    }
    
    private func createTables() throws {
        // Rules table
        try db.execute("""
            CREATE TABLE IF NOT EXISTS rules (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                domain TEXT,
                pattern_prompt TEXT,
                template_type TEXT,
                js_code TEXT NOT NULL,
                version TEXT DEFAULT '1.0',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_used TIMESTAMP,
                usage_count INTEGER DEFAULT 0,
                auto_fixes_applied INTEGER DEFAULT 0,
                is_active BOOLEAN DEFAULT TRUE NOT NULL CHECK (is_active != 0)
            )
        """)
        
        // Indexes for performance
        try db.execute("CREATE INDEX IF NOT EXISTS idx_rules_active ON rules(is_active);")
        try db.execute("CREATE INDEX IF NOT EXISTS idx_rules_domain ON rules(domain);")
        
        // AI sessions table for tracking rule creation sessions
        try db.execute("""
            CREATE TABLE IF NOT EXISTS ai_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT UNIQUE NOT NULL,
                started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                completed_at TIMESTAMP,
                user_input TEXT,
                ai_analysis TEXT,
                generated_rule_id INTEGER REFERENCES rules(id),
                status TEXT DEFAULT 'active',
                notes TEXT
            )
        """)
        
        print("📋 Database tables created successfully")
    }
    
    // MARK: - Rule Management
    
    func insertRule(_ rule: DatabaseRule) -> Int64 {
        do {
            try db.run("""
                INSERT INTO rules (name, domain, pattern_prompt, template_type, js_code, version, created_at, is_active)
                VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, TRUE)
            """, rule.name, rule.domain, rule.patternPrompt ?? "", rule.templateType, rule.jsCode, rule.version)
            
            let rowId: Int64 = db.lastInsertRowid
            print("✅ Rule '\(rule.name)' inserted with ID: \(rowId)")
            return rowId
        } catch {
            print("❌ Failed to insert rule: \(error)")
            return -1
        }
    }
    
    func getRules(activeOnly: Bool = true) -> [DatabaseRule] {
        do {
            let activeFilter = activeOnly ? "WHERE is_active = TRUE" : ""
            let query = "SELECT * FROM rules \(activeFilter) ORDER BY created_at DESC"
            
            var rules: [DatabaseRule] = []
            for row in try db.prepare(query) {
                rules.append(DatabaseRule(row: row))
            }
            
            print("📄 Loaded \(rules.count) rules from database")
            return rules
        } catch {
            print("❌ Failed to load rules: \(error)")
            return []
        }
    }
    
    func updateRuleUsage(ruleId: Int64, fileCount: Int, fixCount: Int, confidence: Double, duration: TimeInterval) {
        do {
            try db.run("""
                UPDATE rules 
                SET usage_count = usage_count + ?,
                    auto_fixes_applied = auto_fixes_applied + ?,
                    last_used = CURRENT_TIMESTAMP
                WHERE id = ?
            """, fileCount, fixCount, ruleId)
        } catch {
            print("❌ Failed to update rule usage: \(error)")
        }
    }
    
    func deactivateRule(_ ruleId: Int64) {
        do {
            try db.run("UPDATE rules SET is_active = FALSE WHERE id = ?", ruleId)
            print("🔇 Rule \(ruleId) deactivated")
        } catch {
            print("❌ Failed to deactivate rule: \(error)")
        }
    }
    
    // MARK: - Session Management
    
    func startSession(sessionId: String, userInput: String) -> Int64 {
        do {
            try db.run("""
                INSERT INTO ai_sessions (session_id, started_at, user_input, status)
                VALUES (?, CURRENT_TIMESTAMP, ?, 'active')
            """, sessionId, userInput)
            
            let rowId: Int64 = db.lastInsertRowid
            print("🚀 AI session started: \(sessionId)")
            return rowId
        } catch {
            print("❌ Failed to start AI session: \(error)")
            return -1
        }
    }
    
    func completeSession(_ sessionId: Int64, analysis: String, ruleId: Int64?, notes: String) {
        do {
            if let rId = ruleId {
                try db.run("""
                    UPDATE ai_sessions 
                    SET completed_at = CURRENT_TIMESTAMP, 
                        ai_analysis = ?,
                        generated_rule_id = ?,
                        status = 'completed',
                        notes = ?
                    WHERE id = ?
                """, analysis, rId, notes, sessionId)
            } else {
                try db.run("""
                    UPDATE ai_sessions 
                    SET completed_at = CURRENT_TIMESTAMP, 
                        ai_analysis = ?,
                        status = 'completed',
                        notes = ?
                    WHERE id = ?
                """, analysis, notes, sessionId)
            }
            print("✅ AI session completed: \(sessionId)")
        } catch {
            print("❌ Failed to complete AI session: \(error)")
        }
    }
    
    // MARK: - Rule Templates
    
    func insertSampleRules() {
        // Create sample JavaScript rules directly
        let sampleRules = [
            ("NamingConvention", """
                // Rule: ViewController classes must end with "ViewController"
                const classes = ASTBridge.getClasses();
                classes.forEach(cls => {
                    if (cls.name.includes("Controller") && !cls.name.endsWith("ViewController")) {
                        RuleEngine.addViolation({
                            ruleName: "ViewController Naming Convention",
                            severity: "medium",
                            actualValue: "Class name: " + cls.name,
                            expectedValue: "Should end with ViewController",
                            automationConfidence: 0.95,
                            recommendedAction: "Rename " + cls.name + " to " + cls.name.replace("Controller", "ViewController"),
                            targetName: cls.name
                        });
                    }
                });
            """),
            
            ("StructSize", """
                // Rule: Structs should not have too many properties
                const classes = ASTBridge.getClasses().filter(cls =>
                    cls.kind.includes('struct')
                );
                classes.forEach(cls => {
                    const propertyCount = ASTBridge.countProperties(cls.name);
                    if (propertyCount > 15) {
                        RuleEngine.addViolation({
                            ruleName: "Struct Size Limit",
                            severity: "high",
                            actualValue: "Struct " + cls.name + " has " + propertyCount + " properties",
                            expectedValue: "Struct should have 15 or fewer properties",
                            automationConfidence: 0.8,
                            recommendedAction: "Extract related properties into separate structs",
                            targetName: cls.name
                        });
                    }
                });
            """),
            
            ("AsyncErrorHandling", """
                // Rule: Async functions should have error handling
                const sourceCode = ASTBridge.currentSourceCode;
                const hasAsync = sourceCode.includes('await') || sourceCode.includes('async');
                const hasErrorHandling = sourceCode.includes('catch') ||
                                      sourceCode.includes('throws') ||
                                      sourceCode.includes('Result<');
                if (hasAsync && !hasErrorHandling) {
                    RuleEngine.addViolation({
                        ruleName: "Async Error Handling",
                        severity: "critical",
                        actualValue: "Async function lacks error handling",
                        expectedValue: "Async functions should handle errors",
                        automationConfidence: 0.9,
                        recommendedAction: "Add proper error handling to async function"
                    });
                }
            """)
        ]
        
        for (templateName, jsCode) in sampleRules {
            let rule = DatabaseRule(
                id: Optional<Int64>.none,
                name: templateName,
                domain: "sample",
                patternPrompt: "Sample rule for \(templateName)",
                templateType: templateName,
                jsCode: jsCode,
                version: "1.0",
                createdAt: Date(),
                lastUsed: Optional<Date>.none,
                usageCount: 0,
                autoFixesApplied: 0,
                isActive: true
            )
            
            _ = insertRule(rule)
        }
        
        print("📝 Sample rules inserted into database")
    }
}

// MARK: - Database Models

struct DatabaseRule: Codable {
    let id: Int64?
    let name: String
    let domain: String
    let patternPrompt: String?
    let templateType: String
    let jsCode: String
    let version: String
    let createdAt: Date
    let lastUsed: Date?
    let usageCount: Int
    let autoFixesApplied: Int
    let isActive: Bool
    
    init(row: Statement.Element) {
        self.id = row[0] as? Int64
        self.name = row[1] as? String ?? ""
        self.domain = row[2] as? String ?? ""
        self.patternPrompt = row[3] as? String
        self.templateType = row[4] as? String ?? ""
        self.jsCode = row[5] as? String ?? ""
        self.version = row[6] as? String ?? "1.0"
        self.createdAt = Date(timeIntervalSince1970: row[7] as? TimeInterval ?? 0)
        self.lastUsed = row[8] != nil ? Date(timeIntervalSince1970: row[8] as! TimeInterval) : nil
        self.usageCount = row[9] as? Int ?? 0
        self.autoFixesApplied = row[10] as? Int ?? 0
        self.isActive = row[11] as? Bool ?? true
    }
    
    init(id: Int64?, name: String, domain: String, patternPrompt: String?, templateType: String, jsCode: String, version: String, createdAt: Date, lastUsed: Date?, usageCount: Int, autoFixesApplied: Int, isActive: Bool) {
        self.id = id
        self.name = name
        self.domain = domain
        self.patternPrompt = patternPrompt
        self.templateType = templateType
        self.jsCode = jsCode
        self.version = version
        self.createdAt = createdAt
        self.lastUsed = lastUsed
        self.usageCount = usageCount
        self.autoFixesApplied = autoFixesApplied
        self.isActive = isActive
    }
}
