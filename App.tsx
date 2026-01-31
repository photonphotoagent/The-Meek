
import React, { useState, useRef } from 'react';
import { Ghost, Skull, Zap, Flame, Terminal, Play, RotateCcw, Share2, AlertCircle, Upload, Camera, Trash2 } from 'lucide-react';
import { generateRetribution, generatePosterImage } from './services/geminiService';
import { Step, RetributionPlan } from './types';

const App: React.FC = () => {
  const [step, setStep] = useState<Step>('WELCOME');
  const [villainName, setVillainName] = useState('');
  const [sins, setSins] = useState('');
  const [villainImage, setVillainImage] = useState<{ base64: string; type: string } | null>(null);
  const [plan, setPlan] = useState<RetributionPlan | null>(null);
  const [posterUrl, setPosterUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const startRitual = () => setStep('VILLAIN');

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 4 * 1024 * 1024) {
        setError("The image is too heavy for the ritual. Max 4MB.");
        return;
      }
      const reader = new FileReader();
      reader.onloadend = () => {
        setVillainImage({
          base64: reader.result as string,
          type: file.type
        });
        setError(null);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleGenerate = async () => {
    setError(null);
    setStep('GENERATING');
    setLoading(true);
    try {
      const generatedPlan = await generateRetribution(villainName, sins);
      setPlan(generatedPlan);
      const poster = await generatePosterImage(
        generatedPlan.movieTitle, 
        generatedPlan.tagline, 
        villainImage?.base64, 
        villainImage?.type
      );
      setPosterUrl(poster);
      setStep('REVEAL');
    } catch (err) {
      console.error(err);
      setError("The spirits are restless. Connection to the void lost.");
      setStep('WELCOME');
    } finally {
      setLoading(false);
    }
  };

  const reset = () => {
    setStep('WELCOME');
    setVillainName('');
    setSins('');
    setVillainImage(null);
    setPlan(null);
    setPosterUrl(null);
    setError(null);
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-4 relative overflow-hidden">
      {/* Background Ambience */}
      <div className="fixed inset-0 pointer-events-none opacity-20 flex items-center justify-center">
        <Ghost className="w-[80vw] h-[80vw] text-red-900 animate-pulse" />
      </div>

      <main className="w-full max-w-2xl z-10 bg-black/80 border-2 border-green-900 p-8 shadow-[0_0_50px_rgba(0,255,65,0.2)] rounded-lg backdrop-blur-sm">
        
        {error && (
          <div className="mb-6 bg-red-950/50 border border-red-500 p-4 text-red-400 flex items-center gap-2 animate-bounce">
            <AlertCircle size={20} />
            <span>{error}</span>
          </div>
        )}

        {step === 'WELCOME' && (
          <div className="text-center space-y-8 py-10">
            <h1 className="horror-title text-6xl md:text-8xl mb-4 tracking-wider uppercase">Retribution</h1>
            <p className="text-2xl text-green-500/80 font-mono italic">"The meek shall inherit the earth... once the wicked are dealt with."</p>
            <div className="space-y-4">
              <p className="text-lg opacity-70 max-w-md mx-auto">Welcome to the void. Here, we transmute your betrayal into cinematic justice. Enter the ritual to craft your perfect 90s horror retribution.</p>
              <button 
                onClick={startRitual}
                className="group relative inline-flex items-center gap-3 px-8 py-4 bg-green-900 hover:bg-green-700 text-black font-bold text-2xl transition-all hover:scale-105 active:scale-95"
              >
                <Play fill="currentColor" />
                INSERT TAPE
                <div className="absolute -inset-1 border-2 border-green-400 opacity-0 group-hover:opacity-100 transition-opacity animate-pulse"></div>
              </button>
            </div>
          </div>
        )}

        {step === 'VILLAIN' && (
          <div className="space-y-6 animate-[fadeIn_0.5s]">
            <div className="flex items-center gap-3 border-b border-green-900 pb-2 mb-8">
              <Skull className="text-green-500" />
              <h2 className="text-3xl uppercase tracking-widest">IDENTIFY THE ANTAGONIST</h2>
            </div>
            <p className="text-xl text-green-400/70">What is the name of the one who wronged you?</p>
            <input 
              value={villainName}
              onChange={(e) => setVillainName(e.target.value)}
              placeholder="NAME OF THE WICKED..."
              className="w-full bg-transparent border-2 border-green-900 p-4 text-3xl focus:border-green-400 outline-none placeholder:text-green-950"
            />
            <div className="flex justify-end pt-8">
              <button 
                onClick={() => setStep('SINS')}
                className="px-8 py-3 bg-green-900 hover:bg-green-700 text-black font-bold flex items-center gap-2"
                disabled={!villainName}
              >
                NEXT <Zap size={20} />
              </button>
            </div>
          </div>
        )}

        {step === 'SINS' && (
          <div className="space-y-6 animate-[fadeIn_0.5s]">
            <div className="flex items-center gap-3 border-b border-green-900 pb-2 mb-8">
              <Flame className="text-red-600" />
              <h2 className="text-3xl uppercase tracking-widest text-red-500">THEIR SINS</h2>
            </div>
            <p className="text-xl text-red-400/70">What did they do to deserve this fate? Be specific. Let the ink bleed.</p>
            <textarea 
              value={sins}
              onChange={(e) => setSins(e.target.value)}
              placeholder="CHEATING, BETRAYAL, LIES, COWARDICE..."
              rows={5}
              className="w-full bg-transparent border-2 border-red-900 p-4 text-2xl focus:border-red-500 outline-none placeholder:text-red-950 text-red-400"
            />
            <div className="flex justify-between pt-8">
              <button onClick={() => setStep('VILLAIN')} className="text-green-900 hover:text-green-400">BACK</button>
              <button 
                onClick={() => setStep('UPLOAD')}
                className="px-8 py-3 bg-red-900 hover:bg-red-700 text-black font-bold flex items-center gap-2"
                disabled={!sins}
              >
                NEXT <Zap size={20} />
              </button>
            </div>
          </div>
        )}

        {step === 'UPLOAD' && (
          <div className="space-y-6 animate-[fadeIn_0.5s]">
            <div className="flex items-center gap-3 border-b border-green-900 pb-2 mb-8">
              <Camera className="text-blue-500" />
              <h2 className="text-3xl uppercase tracking-widest text-blue-400">EVIDENCE LOCKER</h2>
            </div>
            <p className="text-xl text-blue-400/70">Upload a portrait of the antagonist. The AI will weave their likeness into the tapestry of retribution.</p>
            
            <div className="flex flex-col items-center justify-center border-4 border-dashed border-blue-900 p-10 rounded-xl bg-blue-950/10 hover:bg-blue-900/20 transition-all cursor-pointer group relative overflow-hidden"
                 onClick={() => !villainImage && fileInputRef.current?.click()}>
              {villainImage ? (
                <div className="relative w-full flex flex-col items-center">
                  <img src={villainImage.base64} alt="Evidence" className="max-h-64 rounded-lg shadow-2xl grayscale brightness-75 border-2 border-blue-500" />
                  <button 
                    onClick={(e) => { e.stopPropagation(); setVillainImage(null); }}
                    className="absolute -top-4 -right-4 bg-red-600 p-2 rounded-full hover:bg-red-500 transition-colors shadow-lg"
                  >
                    <Trash2 size={20} className="text-white" />
                  </button>
                  <p className="mt-4 text-blue-400 font-mono text-sm uppercase">Subject Identified. Likeness Acquired.</p>
                </div>
              ) : (
                <>
                  <Upload size={64} className="text-blue-900 group-hover:text-blue-500 group-hover:scale-110 transition-all mb-4" />
                  <p className="text-blue-900 font-mono group-hover:text-blue-400">CLICK TO UPLOAD EVIDENCE</p>
                  <p className="text-xs text-blue-950 mt-2 uppercase">Supported: JPG, PNG (Max 4MB)</p>
                </>
              )}
              <input 
                type="file" 
                ref={fileInputRef} 
                onChange={handleFileChange} 
                className="hidden" 
                accept="image/*" 
              />
            </div>

            <div className="flex justify-between pt-8">
              <button onClick={() => setStep('SINS')} className="text-green-900 hover:text-green-400">BACK</button>
              <div className="flex gap-4">
                 <button 
                  onClick={handleGenerate}
                  className="text-zinc-600 hover:text-zinc-400 text-sm uppercase font-mono"
                >
                  SKIP PHOTO
                </button>
                <button 
                  onClick={handleGenerate}
                  className="px-12 py-4 bg-blue-900 hover:bg-blue-600 text-black font-bold text-2xl flex items-center gap-2 animate-pulse shadow-[0_0_20px_rgba(59,130,246,0.5)]"
                >
                  CRAFT RETRIBUTION <Skull size={24} />
                </button>
              </div>
            </div>
          </div>
        )}

        {step === 'GENERATING' && (
          <div className="py-20 flex flex-col items-center gap-8 animate-[pulse_2s_infinite]">
            <div className="relative">
              <div className="w-32 h-32 border-8 border-green-900 border-t-green-400 rounded-full animate-spin"></div>
              <Terminal className="absolute inset-0 m-auto text-green-400 animate-pulse" size={40} />
            </div>
            <div className="text-center space-y-2">
              <p className="text-3xl flicker">CONSULTING THE VOID...</p>
              <p className="text-green-900 font-mono">REWINDING TAPE. RENDERING CARNAGE. BALANCING THE SCALES.</p>
            </div>
          </div>
        )}

        {step === 'REVEAL' && plan && (
          <div className="space-y-10 animate-[fadeIn_1s_ease-out]">
            <div className="text-center">
              <p className="text-red-600 text-xl tracking-[0.3em] font-bold mb-2 italic">A MEEK PRODUCTION PRESENTS</p>
              <h1 className="horror-title text-6xl md:text-7xl uppercase mb-2 leading-none">{plan.movieTitle}</h1>
              <p className="blood-text text-2xl italic">"{plan.tagline}"</p>
            </div>

            <div className="grid md:grid-cols-2 gap-8">
              <div className="border-4 border-green-900 p-2 shadow-2xl relative group bg-black overflow-hidden">
                {posterUrl ? (
                  <img src={posterUrl} alt="Movie Poster" className="w-full h-auto grayscale hover:grayscale-0 transition-all duration-1000 scale-105 group-hover:scale-100" />
                ) : (
                  <div className="w-full aspect-[3/4] bg-zinc-900 flex items-center justify-center">
                    <Ghost size={64} className="text-zinc-800" />
                  </div>
                )}
                <div className="absolute bottom-4 left-4 right-4 bg-black/80 p-2 text-[10px] md:text-xs font-mono border border-green-900 backdrop-blur-sm">
                  <p>DIRECTED BY THE FATE</p>
                  <p>WRITTEN BY RETRIBUTION</p>
                  <p>STARRING {plan.theVillian.toUpperCase()}</p>
                  <p>RELEASED {plan.releaseYear}</p>
                </div>
              </div>

              <div className="space-y-6 font-mono text-sm md:text-base">
                <div>
                  <h3 className="text-green-500 uppercase tracking-widest text-xs border-b border-green-900 mb-2">The Cast</h3>
                  <p className="text-lg"><span className="text-zinc-500">The Villain:</span> {plan.theVillian}</p>
                </div>
                <div>
                  <h3 className="text-green-500 uppercase tracking-widest text-xs border-b border-green-900 mb-2">The Motivation</h3>
                  <p className="text-zinc-400 italic">"{plan.theSins}"</p>
                </div>
                <div>
                  <h3 className="text-red-600 uppercase tracking-widest text-xs border-b border-red-900 mb-2">Plot Synopsis</h3>
                  <p className="text-md leading-relaxed text-zinc-300">{plan.synopsis}</p>
                </div>
                <div className="bg-red-950/20 border border-red-900 p-4 rounded relative overflow-hidden">
                   <div className="absolute top-0 right-0 p-1 bg-red-900/50 text-[10px] text-red-200">RESTRICTED</div>
                  <h3 className="text-red-500 uppercase tracking-widest text-xs mb-2 font-bold flex items-center gap-2">
                    <Skull size={14} /> THE FINAL JUSTICE
                  </h3>
                  <p className="text-red-200 italic">"{plan.ironicRetribution}"</p>
                </div>
              </div>
            </div>

            <div className="flex flex-wrap justify-center gap-4 pt-8 border-t border-green-900">
              <button 
                onClick={reset}
                className="flex items-center gap-2 px-6 py-2 border border-green-500 text-green-500 hover:bg-green-500 hover:text-black transition-colors uppercase font-bold tracking-widest"
              >
                <RotateCcw size={18} /> WATCH ANOTHER TAPE
              </button>
              <button 
                onClick={() => window.print()}
                className="flex items-center gap-2 px-6 py-2 border border-red-500 text-red-500 hover:bg-red-500 hover:text-black transition-colors uppercase font-bold tracking-widest"
              >
                <Share2 size={18} /> IMMORTALIZE SCENARIO
              </button>
            </div>
          </div>
        )}
      </main>

      {/* VHS UI Elements */}
      <div className="fixed top-4 left-4 font-mono text-green-500/50 pointer-events-none select-none">
        <p>PLAY ►</p>
        <p>SP 0:00:00</p>
      </div>
      <div className="fixed bottom-4 right-4 font-mono text-green-500/50 pointer-events-none select-none text-right">
        <p>MARCH 19, 1997</p>
        <p>LP 12:44:01 AM</p>
      </div>

      <footer className="mt-12 text-zinc-700 font-mono text-[10px] md:text-sm z-10 text-center uppercase tracking-widest opacity-50">
        <p>© 1997 MEEK INHERITANCE PRODUCTIONS. ALL RIGHTS OBSERVED.</p>
        <p>FOR ENTERTAINMENT AND CATHARTIC PURPOSES ONLY. NO ACTUAL HARM INTENDED.</p>
      </footer>

      <style dangerouslySetInnerHTML={{ __html: `
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(10px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}} />
    </div>
  );
};

export default App;
