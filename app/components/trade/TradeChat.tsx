'use client';

import { useState, useRef, useEffect } from 'react';
import SendIcon from './SendIcon.js';

interface Message {
  id: number;
  text: string;
  isOwn: boolean;
}

export default function TradeChat() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = () => {
    if (newMessage.trim()) {
      setMessages((prevMessages) => [
        ...prevMessages,
        { id: prevMessages.length + 1, text: newMessage, isOwn: true },
      ]);
      setNewMessage('');
    }
  };
  
  // Different layout for mobile vs desktop
  const isMobile = typeof window !== 'undefined' && window.innerWidth < 768;
  
  return (
    <div className={`
      flex flex-col
      ${isMobile ? 'h-[calc(100vh-200px)]' : 'h-[500px]'}
      border rounded-lg
    `}>
      {/* Messages Container */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`flex ${message.isOwn ? 'justify-end' : 'justify-start'}`}
          >
            <div className={`
              max-w-[85%] sm:max-w-[70%] md:max-w-[60%]
              p-3 rounded-lg
              ${message.isOwn 
                ? 'bg-green-100 text-gray-800 rounded-br-none' 
                : 'bg-gray-100 text-gray-800 rounded-bl-none'}
            `}>
              {message.text}
            </div>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>
      
      {/* Input Area */}
      <div className="border-t p-3">
        <div className="flex items-center space-x-2">
          <input
            type="text"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            placeholder="Type your message..."
            className="flex-1 p-3 border rounded-lg focus:outline-none focus:border-primary"
            onKeyPress={(e) => e.key === 'Enter' && handleSend()}
          />
          <button
            onClick={handleSend}
            className="bg-primary text-white p-3 rounded-lg hover:bg-green-700"
          >
            <SendIcon />
          </button>
        </div>
        
        {/* Quick Replies on Mobile */}
        {isMobile && (
          <div className="mt-2 flex overflow-x-auto space-x-2 pb-1">
            {['Kubali', 'Pinga', 'Ngoja kidogo', 'Nimefika'].map((text) => (
              <button
                key={text}
                onClick={() => setNewMessage(text)}
                className="px-3 py-1.5 bg-gray-100 rounded-full text-sm whitespace-nowrap"
              >
                {text}
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
