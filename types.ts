
export interface RetributionPlan {
  movieTitle: string;
  synopsis: string;
  theVillian: string;
  theSins: string;
  ironicRetribution: string;
  tagline: string;
  releaseYear: string;
}

export type Step = 'WELCOME' | 'VILLAIN' | 'SINS' | 'UPLOAD' | 'GENERATING' | 'REVEAL';
