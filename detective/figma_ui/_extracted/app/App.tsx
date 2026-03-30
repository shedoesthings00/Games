import { useState } from 'react';
import { Desk } from './components/Desk';

export default function App() {
  return (
    <div className="w-full h-screen overflow-hidden bg-[#3d2f28]">
      <Desk />
    </div>
  );
}
