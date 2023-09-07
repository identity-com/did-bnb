import type {Config} from 'jest';

export default async (): Promise<Config> => {
  return {
    verbose: true,
    preset: "ts-jest",
    transform: {
        "node_modules/variables/.+\\.(j|t)sx?$": "ts-jest"
    },
    transformIgnorePatterns: [
      "node_modules/(?!variables/.*)"
    ]
  };
};