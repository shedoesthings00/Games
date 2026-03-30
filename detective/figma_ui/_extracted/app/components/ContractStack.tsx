import { FileText, X } from 'lucide-react';

interface ContractStackProps {
  onClick: () => void;
  isExpanded: boolean;
}

export function ContractStack({ onClick, isExpanded }: ContractStackProps) {
  if (isExpanded) {
    return (
      <div className="relative w-full max-w-4xl h-full max-h-[90vh] flex items-center justify-center">
        {/* Botón cerrar */}
        <button
          onClick={onClick}
          className="absolute top-4 right-4 z-10 bg-[#c4342d] text-white p-3 border-4 border-[#942420] hover:bg-[#d4443d] transition-colors"
        >
          <X className="w-6 h-6" />
        </button>

        {/* Papel grande */}
        <div className="relative w-full h-full bg-[#ece0c0] border-8 border-[#ccc09c] shadow-2xl p-12 overflow-y-auto font-mono" style={{ imageRendering: 'pixelated' }}>
          {/* Header del contrato */}
          <div className="border-b-4 border-[#2a1a0a] pb-6 mb-6">
            <div className="text-center space-y-2">
              <div className="text-3xl font-bold text-[#2a1a0a] tracking-wider">
                CONTRATO DE SERVICIOS
              </div>
              <div className="text-lg text-[#4a3a2a]">
                EL DESPACHO - DETECTIVES PRIVADOS
              </div>
              <div className="text-sm text-[#6a5a4a]">
                Nº CASO: 2026-0042
              </div>
            </div>
          </div>

          {/* Sello urgente */}
          <div className="absolute top-12 right-12 w-32 h-32 rounded-full border-8 border-[#c4342d] opacity-30 flex items-center justify-center rotate-12">
            <div className="text-2xl font-bold text-[#c4342d] -rotate-12">
              URGENTE
            </div>
          </div>

          {/* Contenido */}
          <div className="space-y-6 text-[#2a1a0a]">
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <div className="font-bold mb-1">CLIENTE:</div>
                <div className="bg-white border-2 border-[#ccc09c] p-2">Laura Gómez</div>
              </div>
              <div>
                <div className="font-bold mb-1">FECHA:</div>
                <div className="bg-white border-2 border-[#ccc09c] p-2">30 de Marzo, 2026</div>
              </div>
              <div>
                <div className="font-bold mb-1">TIPO DE CASO:</div>
                <div className="bg-white border-2 border-[#ccc09c] p-2">Corporativo</div>
              </div>
              <div>
                <div className="font-bold mb-1">PRESUPUESTO:</div>
                <div className="bg-white border-2 border-[#ccc09c] p-2">1.200€</div>
              </div>
            </div>

            <div>
              <div className="font-bold mb-2 text-lg">DESCRIPCIÓN DEL CASO:</div>
              <div className="bg-white border-4 border-[#ccc09c] p-4 leading-relaxed">
                La cliente sospecha de irregularidades financieras en su empresa. 
                Necesita investigación discreta sobre posibles malversaciones de fondos 
                por parte de un alto ejecutivo. Se requiere recopilación de pruebas 
                documentales y seguimiento de movimientos sospechosos.
                <br/><br/>
                PLAZO MÁXIMO: 15 días hábiles
                <br/>
                CONFIDENCIALIDAD: Nivel ALTO
              </div>
            </div>

            <div>
              <div className="font-bold mb-2">SERVICIOS INCLUIDOS:</div>
              <div className="bg-white border-4 border-[#ccc09c] p-4 space-y-2">
                <div className="flex items-start gap-2">
                  <div className="w-4 h-4 border-2 border-[#2a1a0a] bg-[#2a1a0a] mt-1"></div>
                  <div>Vigilancia y seguimiento (máx. 40 horas)</div>
                </div>
                <div className="flex items-start gap-2">
                  <div className="w-4 h-4 border-2 border-[#2a1a0a] bg-[#2a1a0a] mt-1"></div>
                  <div>Investigación documental</div>
                </div>
                <div className="flex items-start gap-2">
                  <div className="w-4 h-4 border-2 border-[#2a1a0a] bg-[#2a1a0a] mt-1"></div>
                  <div>Informe final detallado con pruebas</div>
                </div>
                <div className="flex items-start gap-2">
                  <div className="w-4 h-4 border-2 border-[#2a1a0a] mt-1"></div>
                  <div>Testificación en juicio (+300€)</div>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-8 pt-8">
              <div className="space-y-4">
                <div className="border-t-4 border-[#2a1a0a] pt-2">
                  <div className="text-center font-bold">FIRMA DEL CLIENTE</div>
                  <div className="text-center text-sm text-[#6a5a4a] mt-2">Laura Gómez</div>
                </div>
              </div>
              <div className="space-y-4">
                <div className="border-t-4 border-[#2a1a0a] pt-2">
                  <div className="text-center font-bold">FIRMA DEL DETECTIVE</div>
                  <div className="text-center text-sm text-[#6a5a4a] mt-2">________________</div>
                </div>
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="mt-12 pt-6 border-t-2 border-[#ccc09c] text-xs text-center text-[#6a5a4a]">
            El Despacho S.L. - C/ Misteriosa 42, 28001 Madrid - Tel: 91-555-0042 - Licencia: DET-2024-042
          </div>
        </div>
      </div>
    );
  }

  return (
    <button
      onClick={onClick}
      className="relative group cursor-pointer transition-transform hover:scale-105 active:scale-95"
      style={{ imageRendering: 'pixelated' }}
    >
      {/* Stack de papeles con efecto 3D */}
      <div className="relative">
        {/* Papel 3 (más atrás) */}
        <div className="absolute w-48 h-64 bg-[#e4d4b4] border-4 border-[#c4b494] shadow-lg -rotate-2 translate-y-2" />
        
        {/* Papel 2 (medio) */}
        <div className="absolute w-48 h-64 bg-[#e8d8b8] border-4 border-[#c8b898] shadow-lg rotate-1 translate-y-1" />
        
        {/* Papel 1 (delante) */}
        <div className="relative w-48 h-64 bg-[#ece0c0] border-4 border-[#ccc09c] shadow-xl flex flex-col items-center justify-center gap-4 transition-all group-hover:shadow-2xl">
          {/* Icono */}
          <FileText className="w-16 h-16 text-[#4a3a2a] opacity-60" strokeWidth={3} />
          
          {/* Texto */}
          <div className="text-center font-mono">
            <p className="font-bold text-[#2a1a0a] uppercase tracking-wider text-sm">
              CONTRATOS
            </p>
            <p className="text-[#4a3a2a] text-xs mt-1">
              FÍSICOS
            </p>
          </div>

          {/* Badge con número */}
          <div className="absolute -top-3 -right-3 w-10 h-10 bg-[#c4342d] border-4 border-[#942420] text-white flex items-center justify-center font-bold text-lg shadow-lg">
            3
          </div>

          {/* Líneas simulando texto */}
          <div className="absolute bottom-8 left-6 right-6 space-y-2">
            <div className="h-2 bg-[#3a2a1a] w-full" />
            <div className="h-2 bg-[#3a2a1a] w-3/4" />
            <div className="h-2 bg-[#3a2a1a] w-5/6" />
          </div>

          {/* Sello */}
          <div className="absolute bottom-4 right-4 w-12 h-12 rounded-full border-4 border-[#8a3a2a] opacity-20 flex items-center justify-center">
            <div className="text-[6px] font-bold text-[#8a3a2a] rotate-12">
              URGENTE
            </div>
          </div>
        </div>
      </div>

      {/* Hover indicator */}
      <div className="absolute -bottom-6 left-1/2 -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity">
        <div className="bg-[#2a1a0a] border-2 border-[#1a0a0a] text-[#d4a574] px-3 py-1 text-xs whitespace-nowrap font-mono">
          CLICK PARA REVISAR
        </div>
      </div>
    </button>
  );
}