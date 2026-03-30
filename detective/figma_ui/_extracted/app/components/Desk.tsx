import { useState } from 'react';
import { ContractStack } from './ContractStack';
import { Computer } from './Computer';
import { Phone } from './Phone';
import { Clock, Coffee, Lamp } from 'lucide-react';

export function Desk() {
  const [activeItem, setActiveItem] = useState<string | null>(null);

  return (
    <div className="relative w-full h-full flex flex-col" style={{ imageRendering: 'pixelated' }}>
      {/* Modales */}
      {activeItem === 'computer' && (
        <div className="absolute inset-0 z-50 bg-black/80 flex items-center justify-center p-8">
          <Computer 
            isActive={true}
            isExpanded={true}
            onClick={() => setActiveItem(null)} 
          />
        </div>
      )}

      {activeItem === 'contracts' && (
        <div className="absolute inset-0 z-50 bg-black/80 flex items-center justify-center p-8">
          <ContractStack 
            isExpanded={true}
            onClick={() => setActiveItem(null)} 
          />
        </div>
      )}

      {/* Fondo del despacho - parte superior */}
      <div className="h-1/3 bg-gradient-to-b from-[#2a1f1a] to-[#3d2f28] relative">
        {/* Ventana al fondo */}
        <div className="absolute top-8 left-1/2 -translate-x-1/2 w-64 h-32 bg-[#1a1410] border-4 border-[#4a3a2a]">
          <div className="w-full h-full bg-gradient-to-b from-[#5a7a9a] to-[#3a5a7a] opacity-40" />
          <div className="absolute inset-0 grid grid-cols-2 gap-1 p-1">
            <div className="border-2 border-[#2a1f1a]" />
            <div className="border-2 border-[#2a1f1a]" />
            <div className="border-2 border-[#2a1f1a]" />
            <div className="border-2 border-[#2a1f1a]" />
          </div>
        </div>

        {/* Estantería */}
        <div className="absolute top-24 left-12 w-48 h-16 bg-[#2a1f1a] border-2 border-[#1a1410]">
          <div className="flex gap-1 p-2">
            <div className="w-6 h-12 bg-[#8a4a2a] border border-[#6a3a1a]" />
            <div className="w-8 h-12 bg-[#6a3a1a] border border-[#5a2a0a]" />
            <div className="w-7 h-12 bg-[#7a4a2a] border border-[#6a3a1a]" />
            <div className="w-6 h-12 bg-[#8a5a3a] border border-[#7a4a2a]" />
            <div className="w-9 h-12 bg-[#6a3a2a] border border-[#5a2a1a]" />
          </div>
        </div>

        {/* Reloj de pared - redondo */}
        <div className="absolute top-12 right-16">
          <div className="relative w-24 h-24 bg-[#d4c4a4] rounded-full border-4 border-[#4a3a2a] shadow-xl">
            {/* Cara del reloj */}
            <div className="absolute inset-2 bg-[#ece0c0] rounded-full border-2 border-[#8a7a6a]">
              {/* Marcas de las horas */}
              <div className="absolute top-1 left-1/2 -translate-x-1/2 w-1 h-2 bg-[#2a1a0a]" />
              <div className="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-2 bg-[#2a1a0a]" />
              <div className="absolute left-1 top-1/2 -translate-y-1/2 w-2 h-1 bg-[#2a1a0a]" />
              <div className="absolute right-1 top-1/2 -translate-y-1/2 w-2 h-1 bg-[#2a1a0a]" />
              
              {/* Manecilla de horas (apuntando a 9) */}
              <div 
                className="absolute top-1/2 left-1/2 w-1 h-6 bg-[#2a1a0a] origin-bottom"
                style={{ 
                  transform: 'translate(-50%, -100%) rotate(-90deg)',
                  transformOrigin: 'bottom center'
                }}
              />
              
              {/* Manecilla de minutos (apuntando a 3 - 15 minutos) */}
              <div 
                className="absolute top-1/2 left-1/2 w-0.5 h-8 bg-[#4a3a2a] origin-bottom"
                style={{ 
                  transform: 'translate(-50%, -100%) rotate(90deg)',
                  transformOrigin: 'bottom center'
                }}
              />
              
              {/* Centro del reloj */}
              <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-2 h-2 bg-[#2a1a0a] rounded-full border border-[#1a0a0a]" />
            </div>
          </div>
        </div>
      </div>

      {/* Mesa - parte inferior */}
      <div className="flex-1 bg-[#5a4a3a] relative shadow-inner">
        {/* Textura de madera pixelada */}
        <div 
          className="absolute inset-0 opacity-20"
          style={{
            backgroundImage: `repeating-linear-gradient(90deg, 
              transparent, 
              transparent 4px, 
              rgba(0,0,0,0.2) 4px, 
              rgba(0,0,0,0.2) 5px)`
          }}
        />

        {/* Elementos del escritorio */}
        <div className="relative w-full h-full flex items-center justify-center gap-8 px-12">
          
          {/* Lámpara de escritorio - superior izquierda */}
          <div className="absolute top-8 left-12">
            <div className="w-12 h-16 relative">
              {/* Pantalla */}
              <div className="w-12 h-6 bg-[#d4a574] border-2 border-[#a47544]" />
              {/* Brazo */}
              <div className="w-2 h-8 bg-[#6a5a4a] border border-[#4a3a2a] mx-auto" />
              {/* Base */}
              <div className="w-8 h-2 bg-[#6a5a4a] border border-[#4a3a2a] mx-auto" />
              {/* Luz */}
              <div className="w-3 h-3 bg-yellow-300 absolute top-6 left-1/2 -translate-x-1/2 blur-md animate-pulse" />
            </div>
          </div>

          {/* Taza de café pixelada */}
          <div className="absolute bottom-24 left-24">
            <div className="w-10 h-12 bg-[#4a3a2a] border-2 border-[#2a1a0a] relative">
              <div className="w-3 h-6 bg-[#4a3a2a] border-2 border-[#2a1a0a] absolute -right-3 top-2" />
              <div className="absolute top-0 left-1/2 -translate-x-1/2 w-6 h-4 bg-[#6a4a2a] opacity-60" />
            </div>
          </div>

          {/* PILA DE CONTRATOS - IZQUIERDA */}
          <div className="flex-1 flex items-center justify-center">
            <ContractStack 
              isExpanded={false}
              onClick={() => setActiveItem('contracts')} 
            />
          </div>

          {/* ORDENADOR - CENTRO */}
          <div className="flex-1 flex items-center justify-center">
            <Computer 
              isActive={false}
              isExpanded={false}
              onClick={() => setActiveItem('computer')} 
            />
          </div>

          {/* TELÉFONO - DERECHA */}
          <div className="flex-1 flex items-center justify-center">
            <Phone onClick={() => setActiveItem('phone')} />
          </div>

          {/* Notas adhesivas pixeladas */}
          <div className="absolute bottom-12 right-32 w-20 h-20 bg-[#f4e4a4] border-2 border-[#d4c484] shadow-md rotate-6 p-2">
            <div className="space-y-2">
              <div className="w-full h-1 bg-[#3a2a1a]" />
              <div className="w-3/4 h-1 bg-[#3a2a1a]" />
              <div className="w-full h-1 bg-[#3a2a1a]" />
              <div className="w-2/3 h-1 bg-[#3a2a1a]" />
            </div>
          </div>

          {/* Bolígrafo pixelado */}
          <div className="absolute bottom-32 right-24">
            <div className="w-24 h-3 bg-[#2a4a6a] border border-[#1a3a5a] rotate-45" />
            <div className="w-6 h-3 bg-[#c4a574] border border-[#a48554] absolute left-0 top-0 rotate-45" />
          </div>
        </div>
      </div>
    </div>
  );
}