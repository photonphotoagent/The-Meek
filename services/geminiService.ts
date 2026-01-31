
import { GoogleGenAI, Type } from "@google/genai";
import { RetributionPlan } from "../types";

const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });

export async function generateRetribution(villainName: string, sins: string): Promise<RetributionPlan> {
  const prompt = `
    Act as a cult-classic 1990s horror film screenwriter (think Scream, I Know What You Did Last Summer, and Candyman). 
    I want to create a fictional "Retribution Plan" for an ex-partner who has been "awful."
    
    Villain's Name: ${villainName}
    Their Sins/Crimes against the protagonist: ${sins}
    
    Create a detailed horror movie plot where this person gets an IRONIC, supernatural or cinematic comeuppance. 
    The tone should be gritty, dark, slightly campy, and distinctly 90s.
    Ensure no real-world harm is suggested; focus on cinematic, supernatural, and thematic horror tropes.
  `;

  const response = await ai.models.generateContent({
    model: 'gemini-3-flash-preview',
    contents: prompt,
    config: {
      responseMimeType: "application/json",
      responseSchema: {
        type: Type.OBJECT,
        properties: {
          movieTitle: { type: Type.STRING },
          synopsis: { type: Type.STRING },
          theVillian: { type: Type.STRING },
          theSins: { type: Type.STRING },
          ironicRetribution: { type: Type.STRING },
          tagline: { type: Type.STRING },
          releaseYear: { type: Type.STRING }
        },
        required: ["movieTitle", "synopsis", "theVillian", "theSins", "ironicRetribution", "tagline", "releaseYear"]
      }
    }
  });

  return JSON.parse(response.text);
}

export async function generatePosterImage(movieTitle: string, tagline: string, villainImageBase64?: string, mimeType?: string): Promise<string> {
  const textPrompt = `A 90s horror movie poster for a film titled "${movieTitle}". The tagline is "${tagline}". Gritty, dark, VHS aesthetic, dark reds and greens, shadows, high contrast. Stylized cinematic art. ${villainImageBase64 ? "Incorporate the likeness of the person in the provided image as the primary villain or a victim in the shadows." : ""}`;
  
  const contents: any = {
    parts: [{ text: textPrompt }]
  };

  if (villainImageBase64 && mimeType) {
    contents.parts.unshift({
      inlineData: {
        data: villainImageBase64.split(',')[1] || villainImageBase64,
        mimeType: mimeType
      }
    });
  }

  const response = await ai.models.generateContent({
    model: 'gemini-2.5-flash-image',
    contents: contents,
    config: {
      imageConfig: {
        aspectRatio: "3:4"
      }
    }
  });

  for (const part of response.candidates?.[0]?.content?.parts || []) {
    if (part.inlineData) {
      return `data:image/png;base64,${part.inlineData.data}`;
    }
  }
  
  return 'https://picsum.photos/600/800'; // Fallback
}
