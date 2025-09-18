import React, { createContext, useContext, useState, useEffect } from 'react';

interface DatabaseContextType {
  currentEnvironment: 'dev' | 'prod';
  setCurrentEnvironment: (env: 'dev' | 'prod') => void;
  apiUrl: string;
}

const DatabaseContext = createContext<DatabaseContextType | undefined>(undefined);

export const useDatabaseContext = () => {
  const context = useContext(DatabaseContext);
  if (!context) {
    throw new Error('useDatabaseContext must be used within a DatabaseProvider');
  }
  return context;
};

interface DatabaseProviderProps {
  children: React.ReactNode;
}

export const DatabaseProvider: React.FC<DatabaseProviderProps> = ({ children }) => {
  const [currentEnvironment, setCurrentEnvironment] = useState<'dev' | 'prod'>('dev');
  const apiUrl = 'http://localhost:5002';

  // Persist environment selection
  useEffect(() => {
    const saved = localStorage.getItem('gameforge-db-admin-env');
    if (saved === 'dev' || saved === 'prod') {
      setCurrentEnvironment(saved);
    }
  }, []);

  const handleEnvironmentChange = (env: 'dev' | 'prod') => {
    setCurrentEnvironment(env);
    localStorage.setItem('gameforge-db-admin-env', env);
  };

  return (
    <DatabaseContext.Provider
      value={{
        currentEnvironment,
        setCurrentEnvironment: handleEnvironmentChange,
        apiUrl,
      }}
    >
      {children}
    </DatabaseContext.Provider>
  );
};