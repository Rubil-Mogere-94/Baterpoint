import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import io, { Socket } from 'socket.io-client';

interface Message {
  sender: string;
  message: string;
  timestamp: string;
  trade_id?: number; // Optional as status messages might not have it
}

export default function Trade() {
  const { id: tradeIdParam } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const tradeId = parseInt(tradeIdParam || '0');

  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [socket, setSocket] = useState<Socket | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [username, setUsername] = useState<string | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);


  useEffect(() => {
    if (!tradeId) {
      // Redirect or show error if tradeId is invalid
      navigate('/browse'); // Example: redirect to browse page
      return;
    }

    const token = localStorage.getItem('access_token');
    if (!token) {
      navigate('/login'); // Redirect to login if no token
      return;
    }

    // Connect to Socket.IO server
    const newSocket = io('http://localhost:8000', {
      transports: ['websocket'],
      auth: {
        token: token, // This is a custom auth parameter, handle on server
      },
    });

    setSocket(newSocket);

    newSocket.on('connect', () => {
      console.log('Connected to Socket.IO server');
      setIsConnected(true);
      // Explicitly emit authenticate event with the token
      newSocket.emit('authenticate', { token });
    });

    newSocket.on('authenticated', (data) => {
      console.log('Authenticated:', data.username);
      setIsAuthenticated(true);
      setUsername(data.username);
      // Once authenticated, join the trade chat room
      newSocket.emit('join_trade_chat', { trade_id: tradeId });
    });

    newSocket.on('auth_error', (error) => {
      console.error('Authentication error:', error);
      setIsAuthenticated(false);
      navigate('/login'); // Redirect on auth error
    });

    newSocket.on('joined_trade_chat', (data) => {
      console.log('Joined trade chat:', data.room);
    });

    newSocket.on('message', (msg: Message) => {
      setMessages((prevMessages) => [...prevMessages, msg]);
    });

    newSocket.on('status_message', (msg: { message: string }) => {
      setMessages((prevMessages) => [...prevMessages, { sender: "System", message: msg.message, timestamp: new Date().toISOString() }]);
    });

    newSocket.on('chat_error', (error) => {
      console.error('Chat error:', error);
      // Display chat-specific error to user
    });

    newSocket.on('disconnect', () => {
      console.log('Disconnected from Socket.IO server');
      setIsConnected(false);
      setIsAuthenticated(false);
    });

    return () => {
      newSocket.disconnect();
    };
  }, [tradeId, navigate]);

  const sendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (newMessage.trim() && socket && isAuthenticated && isConnected) {
      socket.emit('send_message', { message: newMessage });
      setNewMessage('');
    }
  };

  if (!tradeId) {
    return <div className="text-center p-8">Invalid Trade ID.</div>;
  }

  if (!isConnected) {
    return <div className="text-center p-8">Connecting to chat...</div>;
  }

  if (!isAuthenticated) {
    return <div className="text-center p-8">Authenticating chat...</div>;
  }

  return (
    <div className="flex flex-col h-[calc(100vh-64px)] bg-gray-100"> {/* Adjust height based on your layout */}
      <h2 className="text-2xl font-bold text-center py-4 bg-white shadow-sm">Trade Chat for Listing #{tradeId}</h2>
      
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((msg, index) => (
          <div key={index} className={`flex ${msg.sender === username ? 'justify-end' : 'justify-start'}`}>
            <div className={`p-3 rounded-lg max-w-xs ${msg.sender === username ? 'bg-blue-500 text-white' : 'bg-gray-300 text-gray-800'}`}>
              <div className="font-semibold">{msg.sender === username ? 'You' : msg.sender}</div>
              <div>{msg.message}</div>
              <div className="text-xs text-right opacity-75 mt-1">{new Date(msg.timestamp).toLocaleTimeString()}</div>
            </div>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      <form onSubmit={sendMessage} className="p-4 bg-white border-t flex items-center">
        <input
          type="text"
          value={newMessage}
          onChange={(e) => setNewMessage(e.target.value)}
          placeholder="Type a message..."
          className="flex-1 p-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          disabled={!isAuthenticated || !isConnected}
        />
        <button
          type="submit"
          className="ml-4 px-6 py-3 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 disabled:opacity-50"
          disabled={!newMessage.trim() || !isAuthenticated || !isConnected}
        >
          Send
        </button>
      </form>
    </div>
  );
}