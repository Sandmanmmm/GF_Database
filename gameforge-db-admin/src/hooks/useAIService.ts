import { useMutation, useQuery } from '@tanstack/react-query';
import { useDatabaseContext } from '../contexts/DatabaseContext';

interface NaturalLanguageRequest {
  query: string;
}

interface NaturalLanguageResponse {
  success: boolean;
  result: {
    success: boolean;
    confidence: number;
    sql: string;
    explanation: string;
    category: string;
    security_check: {
      safe: boolean;
      warnings: string[];
    };
    optimization_suggestions: string[];
  };
  timestamp: string;
}

interface ExecuteQueryRequest {
  sql: string;
  safetyCheck?: boolean;
}

interface ExecuteQueryResponse {
  success: boolean;
  data: any[];
  rowCount: number;
  executionTime: number;
  fields: Array<{
    name: string;
    dataTypeID: number;
  }>;
  timestamp: string;
}

interface OptimizationRecommendation {
  id: string;
  type: 'INDEX' | 'QUERY' | 'SCHEMA' | 'PERFORMANCE';
  title: string;
  description: string;
  impact: 'HIGH' | 'MEDIUM' | 'LOW';
  effort: 'LOW' | 'MEDIUM' | 'HIGH';
  sqlSuggestion?: string;
}

interface OptimizationResponse {
  success: boolean;
  recommendations: OptimizationRecommendation[];
  databaseStats: any;
  timestamp: string;
}

interface SecurityAlert {
  id: string;
  severity: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
  title: string;
  description: string;
  affected: string[];
  recommendation: string;
}

interface SecurityAuditResponse {
  success: boolean;
  alerts: SecurityAlert[];
  details: any;
  timestamp: string;
}

const API_BASE_URL = 'http://localhost:5002';

export const useAIService = () => {
  const { currentEnvironment } = useDatabaseContext();

  // Natural Language to SQL Conversion
  const processNaturalLanguage = useMutation<NaturalLanguageResponse, Error, NaturalLanguageRequest>({
    mutationFn: async ({ query }) => {
      const response = await fetch(`${API_BASE_URL}/api/${currentEnvironment}/ai/natural-language`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ query }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to process natural language query');
      }

      return response.json();
    },
  });

  // Execute AI-generated query
  const executeQuery = useMutation<ExecuteQueryResponse, Error, ExecuteQueryRequest>({
    mutationFn: async ({ sql, safetyCheck = true }) => {
      const response = await fetch(`${API_BASE_URL}/api/${currentEnvironment}/ai/execute-query`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ sql, safetyCheck }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to execute query');
      }

      return response.json();
    },
  });

  // Get optimization recommendations
  const useOptimizationRecommendations = () => {
    return useQuery<OptimizationResponse, Error>({
      queryKey: ['ai-optimization', currentEnvironment],
      queryFn: async () => {
        const response = await fetch(`${API_BASE_URL}/api/${currentEnvironment}/ai/optimization-recommendations`);
        
        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.error || 'Failed to get optimization recommendations');
        }

        return response.json();
      },
      refetchInterval: 5 * 60 * 1000, // Refetch every 5 minutes
      staleTime: 2 * 60 * 1000, // Data is fresh for 2 minutes
    });
  };

  // Get security audit results
  const useSecurityAudit = () => {
    return useQuery<SecurityAuditResponse, Error>({
      queryKey: ['ai-security-audit', currentEnvironment],
      queryFn: async () => {
        const response = await fetch(`${API_BASE_URL}/api/${currentEnvironment}/ai/security-audit`);
        
        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.error || 'Failed to perform security audit');
        }

        return response.json();
      },
      refetchInterval: 10 * 60 * 1000, // Refetch every 10 minutes
      staleTime: 5 * 60 * 1000, // Data is fresh for 5 minutes
    });
  };

  return {
    processNaturalLanguage,
    executeQuery,
    useOptimizationRecommendations,
    useSecurityAudit,
  };
};

export type {
  NaturalLanguageRequest,
  NaturalLanguageResponse,
  ExecuteQueryRequest,
  ExecuteQueryResponse,
  OptimizationRecommendation,
  OptimizationResponse,
  SecurityAlert,
  SecurityAuditResponse,
};