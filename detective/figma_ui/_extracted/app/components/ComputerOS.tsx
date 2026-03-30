import { useState } from 'react';
import { FileText, History, Mail, Calendar, X, Folder, Minimize2 } from 'lucide-react';

type App = 'contracts' | 'history' | 'mail' | 'calendar' | null;

export function ComputerOS() {
  const [openApp, setOpenApp] = useState<App>(null);

  const apps = [
    { id: 'contracts' as App, name: 'Contratos', icon: FileText, color: 'text-[#4a8a4a]' },
    { id: 'history' as App, name: 'Historial', icon: History, color: 'text-[#8a8a4a]' },
    { id: 'mail' as App, name: 'Correos', icon: Mail, color: 'text-[#4a6a8a]' },
    { id: 'calendar' as App, name: 'Calendario', icon: Calendar, color: 'text-[#8a4a6a]' },
  ];

  return (
    <div className="relative w-full h-full bg-[#1a2a1a] p-2 font-mono" style={{ imageRendering: 'pixelated' }}>
      {/* Header del OS */}
      <div className="bg-[#2a4a2a] border-2 border-[#3a5a3a] px-2 py-1 flex items-center justify-between mb-2">
        <div className="text-[#6aaa6a] text-[10px] flex items-center gap-2">
          <Folder className="w-3 h-3" strokeWidth={3} />
          <span>DESPACHO.EXE</span>
        </div>
        <div className="text-[#6aaa6a] text-[8px]">
          09:15:42
        </div>
      </div>

      {openApp ? (
        // Ventana de aplicación abierta
        <div className="bg-[#0a1a0a] border-4 border-[#3a5a3a] h-[calc(100%-32px)]">
          {/* Barra de título */}
          <div className="bg-[#2a4a2a] border-b-2 border-[#3a5a3a] px-2 py-1 flex items-center justify-between">
            <span className="text-[#6aaa6a] text-[10px] uppercase tracking-wider">
              {apps.find(a => a.id === openApp)?.name}
            </span>
            <button 
              onClick={() => setOpenApp(null)}
              className="text-[#aa6a6a] hover:text-[#ca8a8a] transition-colors border-2 border-[#aa6a6a] p-0.5"
            >
              <X className="w-3 h-3" strokeWidth={3} />
            </button>
          </div>

          {/* Contenido de la app */}
          <div className="p-2 text-[#6aaa6a] text-[9px] space-y-1 overflow-y-auto max-h-[calc(100%-28px)]">
            {openApp === 'contracts' && (
              <div className="space-y-2">
                <div className="border-2 border-[#3a5a3a] p-2 hover:bg-[#1a2a1a] cursor-pointer bg-[#0a1a0a]">
                  <div className="font-bold tracking-wider">CASO-2026-0042</div>
                  <div className="opacity-70 mt-1">Laura Gómez - Corporativo</div>
                  <div className="opacity-50 mt-1">Presupuesto: 1200€</div>
                  <div className="border-t border-[#3a5a3a] mt-2 pt-1 text-[8px]">
                    Estado: PENDIENTE
                  </div>
                </div>
                <div className="border-2 border-[#3a5a3a] p-2 hover:bg-[#1a2a1a] cursor-pointer bg-[#0a1a0a]">
                  <div className="font-bold tracking-wider">CASO-2026-0043</div>
                  <div className="opacity-70 mt-1">Anónimo - Amenazas</div>
                  <div className="opacity-50 mt-1">Presupuesto: 400€</div>
                  <div className="border-t border-[#3a5a3a] mt-2 pt-1 text-[8px]">
                    Estado: ACTIVO
                  </div>
                </div>
                <div className="border-2 border-[#3a5a3a] p-2 hover:bg-[#1a2a1a] cursor-pointer bg-[#0a1a0a]">
                  <div className="font-bold tracking-wider">CASO-2026-0044</div>
                  <div className="opacity-70 mt-1">Marta del Río - Desaparición</div>
                  <div className="opacity-50 mt-1">Presupuesto: 900€</div>
                  <div className="border-t border-[#3a5a3a] mt-2 pt-1 text-[8px]">
                    Estado: URGENTE
                  </div>
                </div>
              </div>
            )}

            {openApp === 'history' && (
              <div className="space-y-2">
                <div className="border-b-2 border-[#3a5a3a] pb-1 mb-2 bg-[#2a4a2a] p-2">
                  <div className="font-bold tracking-wider">CASOS ARCHIVADOS</div>
                </div>
                <div className="space-y-2">
                  <div className="border-2 border-[#3a5a3a] p-2 bg-[#0a1a0a]">
                    <div className="flex justify-between">
                      <span>&gt; Caso corporativo</span>
                      <span className="opacity-50">15/03/2026</span>
                    </div>
                    <div className="opacity-50 mt-1 text-[8px]">RESUELTO - ÉXITO</div>
                  </div>
                  <div className="border-2 border-[#3a5a3a] p-2 bg-[#0a1a0a]">
                    <div className="flex justify-between">
                      <span>&gt; Caso desaparición</span>
                      <span className="opacity-50">12/03/2026</span>
                    </div>
                    <div className="opacity-50 mt-1 text-[8px]">EN CURSO</div>
                  </div>
                  <div className="border-2 border-[#3a5a3a] p-2 bg-[#0a1a0a]">
                    <div className="flex justify-between">
                      <span>&gt; Caso amenazas</span>
                      <span className="opacity-50">10/03/2026</span>
                    </div>
                    <div className="opacity-50 mt-1 text-[8px]">ARCHIVADO</div>
                  </div>
                  <div className="border-2 border-[#3a5a3a] p-2 bg-[#0a1a0a]">
                    <div className="flex justify-between">
                      <span>&gt; Caso infidelidad</span>
                      <span className="opacity-50">08/03/2026</span>
                    </div>
                    <div className="opacity-50 mt-1 text-[8px]">RECHAZADO</div>
                  </div>
                </div>
              </div>
            )}

            {openApp === 'mail' && (
              <div className="space-y-2">
                <div className="border-2 border-[#3a5a3a] p-2 bg-[#2a4a2a]">
                  <div className="flex justify-between mb-1">
                    <span className="font-bold">[NUEVO]</span>
                    <span className="opacity-50">09:15</span>
                  </div>
                  <div className="border-t border-[#3a5a3a] pt-1 mt-1">
                    <div className="opacity-70">De: laura.gil@email.com</div>
                    <div className="mt-1 font-bold">Urgente - Necesito ayuda</div>
                    <div className="mt-2 text-[8px] opacity-50">
                      Por favor, contacte conmigo...
                    </div>
                  </div>
                </div>
                <div className="border-2 border-[#3a5a3a] p-2 bg-[#0a1a0a]">
                  <div className="flex justify-between mb-1">
                    <span className="opacity-70">[LEÍDO]</span>
                    <span className="opacity-50">08:42</span>
                  </div>
                  <div className="border-t border-[#3a5a3a] pt-1 mt-1">
                    <div className="opacity-70">De: detective@despacho.com</div>
                    <div className="mt-1">Política actualizada</div>
                    <div className="mt-2 text-[8px] opacity-50">
                      Se han actualizado las normas...
                    </div>
                  </div>
                </div>
                <div className="border-2 border-[#3a5a3a] p-2 bg-[#0a1a0a]">
                  <div className="flex justify-between mb-1">
                    <span className="opacity-70">[LEÍDO]</span>
                    <span className="opacity-50">07:21</span>
                  </div>
                  <div className="border-t border-[#3a5a3a] pt-1 mt-1">
                    <div className="opacity-70">De: cliente@empresa.com</div>
                    <div className="mt-1">Pago procesado</div>
                  </div>
                </div>
              </div>
            )}

            {openApp === 'calendar' && (
              <div className="space-y-2">
                <div className="border-b-2 border-[#3a5a3a] pb-1 mb-2 bg-[#2a4a2a] p-2">
                  <div className="font-bold tracking-wider">MARZO 2026</div>
                </div>
                <div className="grid grid-cols-7 gap-1 text-center text-[8px] mb-2">
                  {['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((day) => (
                    <div key={day} className="opacity-50 font-bold bg-[#2a4a2a] p-1 border border-[#3a5a3a]">{day}</div>
                  ))}
                  {Array.from({ length: 31 }, (_, i) => (
                    <div 
                      key={i}
                      className={`p-1 border-2 border-[#3a5a3a] ${
                        i === 29 ? 'bg-[#4a8a4a] font-bold' : 'bg-[#0a1a0a]'
                      }`}
                    >
                      {i + 1}
                    </div>
                  ))}
                </div>
                <div className="border-2 border-[#3a5a3a] p-2 bg-[#2a4a2a]">
                  <div className="font-bold mb-2">HOY - 30/03/2026</div>
                  <div className="space-y-1 text-[8px]">
                    <div className="border-b border-[#3a5a3a] pb-1">&gt; 10:00 - Laura Gómez (Reunión)</div>
                    <div className="border-b border-[#3a5a3a] pb-1">&gt; 13:00 - Slot libre</div>
                    <div className="border-b border-[#3a5a3a] pb-1">&gt; 16:00 - Llamada programada</div>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      ) : (
        // Escritorio con iconos de apps
        <div className="grid grid-cols-2 gap-3 p-3">
          {apps.map((app) => {
            const Icon = app.icon;
            return (
              <button
                key={app.id}
                onClick={() => setOpenApp(app.id)}
                className="bg-[#2a4a2a] border-4 border-[#3a5a3a] hover:border-[#4a6a4a] hover:bg-[#3a5a3a] transition-all p-3 flex flex-col items-center gap-2 group"
              >
                <Icon className={`w-8 h-8 ${app.color} group-hover:scale-110 transition-transform`} strokeWidth={3} />
                <span className="text-[#6aaa6a] text-[9px] uppercase tracking-wider">
                  {app.name}
                </span>
              </button>
            );
          })}
        </div>
      )}

      {/* Barra inferior del OS */}
      <div className="absolute bottom-0 left-0 right-0 bg-[#2a4a2a] border-t-2 border-[#3a5a3a] px-2 py-1">
        <div className="flex items-center justify-between text-[8px] text-[#6aaa6a]">
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 bg-[#4a8a4a] border border-[#2a6a2a]" />
            <span>SISTEMA: OK</span>
          </div>
          <div className="flex gap-2">
            <div className="w-2 h-2 bg-[#4a8a4a] border border-[#2a6a2a] animate-pulse" />
            <span>CONECTADO</span>
          </div>
        </div>
      </div>
    </div>
  );
}