'use client';

import { Bell, User } from 'lucide-react';
import { Button } from '@/components/ui/button';

export default function Header() {
  return (
    <header className="h-16 border-b border-zinc-200 bg-white/90 backdrop-blur-sm flex items-center justify-between px-6 sticky top-0 z-30">
      <div className="flex items-center">
        <div className="text-sm text-zinc-600">
          Welcome back, <span className="font-medium text-zinc-900">Admin</span>
        </div>
      </div>

      <div className="flex items-center space-x-4">
        <Button variant="ghost" size="icon" className="relative">
          <Bell className="h-5 w-5 text-zinc-500 hover:text-blue-500" />
          <span className="absolute top-2 right-2 h-2 w-2 bg-red-500 rounded-full" />
        </Button>
        
        <div className="flex items-center space-x-2">
          <div className="h-8 w-8 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center overflow-hidden">
             <User className="h-4 w-4 text-white" />
          </div>
          <div className="hidden md:block">
            <p className="text-sm font-medium">Admin User</p>
            <p className="text-xs text-zinc-500">Super Administrator</p>
          </div>
        </div>
      </div>
    </header>
  );
}
