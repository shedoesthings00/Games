import { useState } from 'react';
import { Monitor, Power, FileText, History, Mail, Calendar, X } from 'lucide-react';
import { ComputerOS } from './ComputerOS';

interface ComputerProps {
  isActive: boolean;
  isExpanded: boolean;
  onClick: () => void;
}

export function Computer({ isActive, onClick, isExpanded }: ComputerProps) {
  if (isExpanded) {
    return (
      <div className="relative w-full max-w-6xl h-full max-h-[90vh] flex items-center justify-center">
        {/* Botón cerrar */}
        <button
          onClick={onClick}
          className="absolute top-4 right-4 z-10 bg-[#c4342d] text-white p-3 border-4 border-[#942420] hover:bg-[#d4443d] transition-colors"
        >
          <X className="w-6 h-6" />
        </button>

        {/* Pantalla grande */}
        <div className="relative bg-[#2a1a1a] border-8 border-[#1a0a0a] p-8 w-full h-full" style={{ imageRendering: 'pixelated' }}>
          <div className="relative w-full h-full bg-[#1a2a1a] border-4 border-[#2a4a2a] overflow-hidden">
            <ComputerOS />
          </div>

          {/* Indicador de encendido */}
          <div className="absolute bottom-4 right-4 flex items-center gap-2">
            <div className="w-3 h-3 bg-[#4a8a4a] border-2 border-[#2a6a2a] animate-pulse" />
            <span className="text-[#6aaa6a] text-xs font-mono">ONLINE</span>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="relative group" style={{ imageRendering: 'pixelated' }}>
      {/* Monitor */}
      <button
        onClick={onClick}
        className="relative cursor-pointer transition-transform hover:scale-105 active:scale-95"
      >
        {/* Carcasa del monitor */}
        <div className="relative bg-[#d4c4a4] border-4 border-[#a49484] p-3 w-80">
          {/* Pantalla */}
          <div className={`relative w-full h-56 border-4 overflow-hidden transition-all ${
            isActive 
              ? 'bg-[#1a2a1a] border-[#2a4a2a]' 
              : 'bg-[#0a0a0a] border-[#1a1a1a]'
          }`}>
            {isActive ? (
              <ComputerOS />
            ) : (
              <div className="w-full h-full flex items-center justify-center">
                <div className="text-[#2a3a2a] text-xs animate-pulse font-mono">
                  ▮
                </div>
              </div>
            )}
          </div>

          {/* Marco inferior con info */}
          <div className="mt-2 flex items-center justify-between px-2">
            <div className="text-[6px] text-[#6a5a4a] font-mono uppercase tracking-wider">
              DETECTIVE OS v2.1
            </div>
            <div className={`w-3 h-3 border-2 ${
              isActive 
                ? 'bg-[#4a8a4a] border-[#2a6a2a]' 
                : 'bg-[#4a3a2a] border-[#2a1a0a]'
            }`} />
          </div>
        </div>

        {/* Base del monitor */}
        <div className="w-24 h-6 bg-[#a49484] border-4 border-[#8a7a6a] mx-auto" />
        <div className="w-32 h-3 bg-[#5a4a3a] border-2 border-[#4a3a2a] mx-auto" />

        {/* Teclado pixelado */}
        <div className="mt-4 w-80 h-16 bg-[#c4b4a4] border-4 border-[#a49484] mx-auto">
          <div className="grid grid-cols-12 gap-1 p-2">
            {Array.from({ length: 36 }).map((_, i) => (
              <div key={i} className="w-full aspect-square bg-[#8a7a6a] border-2 border-[#6a5a4a]" />
            ))}
          </div>
        </div>
      </button>

      {/* Hover indicator */}
      {!isActive && (
        <div className="absolute -bottom-8 left-1/2 -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity">
          <div className="bg-[#2a1a0a] border-2 border-[#1a0a0a] text-[#d4a574] px-3 py-1 text-xs whitespace-nowrap font-mono">
            CLICK PARA ENCENDER
          </div>
        </div>
      )}
    </div>
  );
}