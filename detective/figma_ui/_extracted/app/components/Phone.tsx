import { Phone as PhoneIcon, PhoneCall } from 'lucide-react';

interface PhoneProps {
  onClick: () => void;
}

export function Phone({ onClick }: PhoneProps) {
  return (
    <button
      onClick={onClick}
      className="relative group cursor-pointer transition-transform hover:scale-105 active:scale-95"
      style={{ imageRendering: 'pixelated' }}
    >
      {/* Teléfono retro pixelado */}
      <div className="relative">
        {/* Base del teléfono */}
        <div className="relative bg-[#2a1a1a] border-4 border-[#1a0a0a] p-4 w-48 h-56">
          {/* Pantalla pequeña */}
          <div className="bg-[#4a6a4a] border-4 border-[#2a4a2a] h-12 mb-4 flex items-center justify-center">
            <div className="text-[#8aaa8a] font-mono text-xs tracking-wider">
              SIN LLAMADAS
            </div>
          </div>

          {/* Teclado numérico pixelado */}
          <div className="grid grid-cols-3 gap-2">
            {[1, 2, 3, 4, 5, 6, 7, 8, 9, '*', 0, '#'].map((num) => (
              <div
                key={num}
                className="bg-[#4a3a2a] border-4 border-[#3a2a1a] h-8 flex items-center justify-center text-[#d4a574] font-bold text-sm shadow-inner hover:bg-[#5a4a3a] transition-colors font-mono"
              >
                {num}
              </div>
            ))}
          </div>

          {/* Botones de función */}
          <div className="flex gap-2 mt-3">
            <div className="flex-1 bg-[#4a8a4a] border-4 border-[#3a6a3a] h-8 flex items-center justify-center shadow-inner">
              <div className="w-4 h-4 bg-white border-2 border-[#2a6a2a]" />
            </div>
            <div className="flex-1 bg-[#8a4a4a] border-4 border-[#6a3a3a] h-8 flex items-center justify-center shadow-inner">
              <div className="w-4 h-2 bg-white border-2 border-[#6a3a3a]" />
            </div>
          </div>

          {/* LED indicator pixelado */}
          <div className="absolute top-2 right-2 w-3 h-3 bg-[#8a4a4a] border-2 border-[#6a3a3a]" />
        </div>

        {/* Cable del teléfono pixelado */}
        <div className="absolute -bottom-4 left-1/2 -translate-x-1/2 w-2 h-8 bg-[#3a2a1a] border border-[#2a1a0a]" />
        
        {/* Cable en espiral simplificado */}
        <div className="absolute -bottom-8 left-1/2 -translate-x-1/2">
          <div className="flex flex-col gap-0.5">
            <div className="w-6 h-1 bg-[#3a2a1a] border border-[#2a1a0a] rounded-full -ml-3" />
            <div className="w-6 h-1 bg-[#3a2a1a] border border-[#2a1a0a] rounded-full ml-1" />
            <div className="w-6 h-1 bg-[#3a2a1a] border border-[#2a1a0a] rounded-full -ml-2" />
          </div>
        </div>

        {/* Auricular pixelado */}
        <div className="absolute -top-8 right-4 w-20 h-8 bg-[#2a1a1a] border-4 border-[#1a0a0a] rotate-12">
          <div className="absolute inset-2 flex items-center justify-between px-2">
            <div className="w-4 h-4 bg-[#4a3a2a] border-2 border-[#3a2a1a]" />
            <div className="w-4 h-4 bg-[#4a3a2a] border-2 border-[#3a2a1a]" />
          </div>
        </div>
      </div>

      {/* Hover indicator */}
      <div className="absolute -bottom-12 left-1/2 -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity">
        <div className="bg-[#2a1a0a] border-2 border-[#1a0a0a] text-[#d4a574] px-3 py-1 text-xs whitespace-nowrap font-mono">
          CLICK PARA LLAMAR
        </div>
      </div>
    </button>
  );
}