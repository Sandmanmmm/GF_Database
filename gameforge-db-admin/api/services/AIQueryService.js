// AI Query Service - Natural Language to SQL Conversion
class AIQueryService {
  constructor() {
    this.confidence_threshold = 0.7;
    this.query_patterns = this.initializePatterns();
  }

  initializePatterns() {
    return {
      // Basic SELECT patterns
      'show_users': {
        pattern: /(?:show|list|get|find|display)\s+(?:all\s+)?users?/i,
        template: 'SELECT * FROM users',
        confidence: 0.9
      },
      'count_users': {
        pattern: /(?:how many|count)\s+users?/i,
        template: 'SELECT COUNT(*) as user_count FROM users',
        confidence: 0.95
      },
      'recent_users': {
        pattern: /(?:recent|new|latest)\s+users?/i,
        template: 'SELECT * FROM users ORDER BY created_at DESC LIMIT 10',
        confidence: 0.85
      },
      'active_users': {
        pattern: /active\s+users?/i,
        template: 'SELECT * FROM users WHERE last_login_at > NOW() - INTERVAL \'30 days\'',
        confidence: 0.8
      },
      
      // Time-based queries
      'users_this_month': {
        pattern: /users?\s+(?:registered|created|joined)\s+(?:this\s+)?month/i,
        template: 'SELECT * FROM users WHERE created_at >= DATE_TRUNC(\'month\', CURRENT_DATE)',
        confidence: 0.9
      },
      'users_today': {
        pattern: /users?\s+(?:registered|created|joined)\s+today/i,
        template: 'SELECT * FROM users WHERE DATE(created_at) = CURRENT_DATE',
        confidence: 0.95
      },
      
      // Search patterns
      'search_by_email': {
        pattern: /(?:find|search|get)\s+user[s]?\s+(?:with|by)\s+email\s+(.+)/i,
        template: 'SELECT * FROM users WHERE email ILIKE \'%{param}%\'',
        confidence: 0.85
      },
      'search_by_username': {
        pattern: /(?:find|search|get)\s+user[s]?\s+(?:with|by)\s+(?:username|name)\s+(.+)/i,
        template: 'SELECT * FROM users WHERE username ILIKE \'%{param}%\'',
        confidence: 0.85
      },
      
      // Analytical queries
      'user_statistics': {
        pattern: /(?:user|users?)\s+(?:statistics|stats|analytics)/i,
        template: `SELECT 
          COUNT(*) as total_users,
          COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as new_users_30d,
          COUNT(CASE WHEN last_login_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as active_users_7d
        FROM users`,
        confidence: 0.8
      },
      
      // Table analysis
      'table_info': {
        pattern: /(?:describe|info|structure|columns)\s+(?:table\s+)?(\w+)/i,
        template: 'SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = \'{param}\'',
        confidence: 0.9
      },
      
      // Performance queries
      'slow_queries': {
        pattern: /(?:slow|slowest)\s+(?:queries|query)/i,
        template: 'SELECT query, mean_time, calls FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10',
        confidence: 0.85
      }
    };
  }

  async processNaturalLanguage(input) {
    const cleanInput = input.trim().toLowerCase();
    let bestMatch = null;
    let highestConfidence = 0;
    let extractedParam = null;

    // Try to match against known patterns
    for (const [key, pattern] of Object.entries(this.query_patterns)) {
      const match = cleanInput.match(pattern.pattern);
      if (match && pattern.confidence > highestConfidence) {
        bestMatch = pattern;
        highestConfidence = pattern.confidence;
        
        // Extract parameter if found
        if (match[1]) {
          extractedParam = match[1].trim().replace(/['"]/g, '');
        }
      }
    }

    if (bestMatch && highestConfidence >= this.confidence_threshold) {
      let sql = bestMatch.template;
      
      // Replace parameter placeholder if needed
      if (extractedParam && sql.includes('{param}')) {
        sql = sql.replace(/\{param\}/g, extractedParam);
      }

      return {
        success: true,
        confidence: highestConfidence,
        sql: sql,
        explanation: this.generateExplanation(input, sql),
        category: this.categorizeQuery(sql),
        security_check: this.performSecurityCheck(sql),
        optimization_suggestions: this.getOptimizationSuggestions(sql)
      };
    }

    // Fallback: Generate a basic query based on keywords
    return this.generateFallbackQuery(input);
  }

  generateFallbackQuery(input) {
    const keywords = input.toLowerCase().split(/\s+/);
    const tables = ['users', 'orders', 'products', 'customers']; // Known tables
    
    let detectedTable = null;
    for (const table of tables) {
      if (keywords.includes(table) || keywords.includes(table.slice(0, -1))) {
        detectedTable = table;
        break;
      }
    }

    if (!detectedTable) {
      detectedTable = 'users'; // Default fallback
    }

    const sql = `SELECT * FROM ${detectedTable} LIMIT 10`;
    
    return {
      success: true,
      confidence: 0.5,
      sql: sql,
      explanation: `Generated a basic query for table '${detectedTable}' based on your input. Consider being more specific for better results.`,
      category: 'SELECT',
      security_check: { safe: true, warnings: [] },
      optimization_suggestions: [`Consider adding WHERE clauses to filter results`, `Add ORDER BY for consistent results`]
    };
  }

  categorizeQuery(sql) {
    const upperSql = sql.toUpperCase().trim();
    
    if (upperSql.startsWith('SELECT')) return 'SELECT';
    if (upperSql.startsWith('INSERT')) return 'INSERT';
    if (upperSql.startsWith('UPDATE')) return 'UPDATE';
    if (upperSql.startsWith('DELETE')) return 'DELETE';
    if (upperSql.startsWith('CREATE')) return 'DDL';
    if (upperSql.startsWith('ALTER')) return 'DDL';
    if (upperSql.startsWith('DROP')) return 'DDL';
    
    return 'ANALYSIS';
  }

  performSecurityCheck(sql) {
    const warnings = [];
    const upperSql = sql.toUpperCase();
    
    // Check for potential dangerous operations
    if (upperSql.includes('DROP TABLE') || upperSql.includes('DELETE FROM') && !upperSql.includes('WHERE')) {
      warnings.push('Query contains potentially destructive operations without WHERE clause');
    }
    
    if (upperSql.includes('--') || upperSql.includes('/*')) {
      warnings.push('Query contains SQL comments which might indicate injection attempts');
    }
    
    if (sql.includes("'") && sql.includes("||")) {
      warnings.push('Potential SQL injection pattern detected');
    }

    return {
      safe: warnings.length === 0,
      warnings: warnings
    };
  }

  getOptimizationSuggestions(sql) {
    const suggestions = [];
    const upperSql = sql.toUpperCase();
    
    if (upperSql.includes('SELECT *')) {
      suggestions.push('Consider selecting specific columns instead of using SELECT *');
    }
    
    if (upperSql.includes('WHERE') && upperSql.includes('LIKE')) {
      suggestions.push('Consider using indexes on columns used in LIKE operations');
    }
    
    if (!upperSql.includes('LIMIT') && upperSql.startsWith('SELECT')) {
      suggestions.push('Consider adding LIMIT clause for large result sets');
    }
    
    if (upperSql.includes('ORDER BY') && !upperSql.includes('LIMIT')) {
      suggestions.push('ORDER BY without LIMIT can be expensive on large tables');
    }

    return suggestions;
  }

  generateExplanation(originalInput, generatedSql) {
    return `Generated SQL query based on your request: "${originalInput}". This query will ${this.describeQuery(generatedSql)}.`;
  }

  describeQuery(sql) {
    const upperSql = sql.toUpperCase().trim();
    
    if (upperSql.startsWith('SELECT COUNT(*)')) {
      return 'count the number of records';
    }
    
    if (upperSql.startsWith('SELECT') && upperSql.includes('ORDER BY') && upperSql.includes('DESC')) {
      return 'retrieve records sorted by the most recent first';
    }
    
    if (upperSql.startsWith('SELECT') && upperSql.includes('WHERE')) {
      return 'retrieve records that match specific conditions';
    }
    
    if (upperSql.startsWith('SELECT')) {
      return 'retrieve records from the database';
    }
    
    return 'perform the requested database operation';
  }

  async generateOptimizationRecommendations(databaseStats) {
    const recommendations = [];
    
    // Index recommendations based on query patterns
    if (databaseStats.slowQueries) {
      for (const query of databaseStats.slowQueries) {
        if (query.query.includes('WHERE') && query.mean_time > 100) {
          recommendations.push({
            type: 'INDEX',
            title: 'Add index for slow WHERE clause',
            description: `Query is taking ${query.mean_time}ms on average. Consider adding an index.`,
            impact: 'HIGH',
            effort: 'LOW',
            sqlSuggestion: this.suggestIndex(query.query)
          });
        }
      }
    }
    
    // Connection pool recommendations
    if (databaseStats.connectionPoolUsage > 80) {
      recommendations.push({
        type: 'PERFORMANCE',
        title: 'High connection pool usage',
        description: 'Connection pool is at high capacity. Consider optimizing connection usage.',
        impact: 'MEDIUM',
        effort: 'MEDIUM'
      });
    }
    
    return recommendations;
  }

  suggestIndex(query) {
    // Simple index suggestion based on WHERE clauses
    const whereMatch = query.match(/WHERE\s+(\w+)\s*[=<>]/i);
    if (whereMatch) {
      const column = whereMatch[1];
      const tableMatch = query.match(/FROM\s+(\w+)/i);
      if (tableMatch) {
        const table = tableMatch[1];
        return `CREATE INDEX CONCURRENTLY idx_${table}_${column} ON ${table}(${column});`;
      }
    }
    return '-- Unable to suggest specific index';
  }
}

module.exports = AIQueryService;