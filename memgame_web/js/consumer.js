// Action Cable consumer для веб-сокет соединений
class ActionCableConsumer {
  constructor() {
    this.cable = null;
    this.subscriptions = new Map();
    this.connectionReady = false;
    this.pendingSubscriptions = [];
    this.reconnectTimer = null;
    this.shouldReconnect = true;
  }

  connect(url = '/cable', params = {}) {
    console.log('🔌 [ActionCableConsumer] Connecting to:', url, 'with params:', params);
    
    // Очищаем таймер переподключения
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    
    // Сбрасываем флаг готовности
    this.connectionReady = false;
    
    if (this.cable) {
      console.log('🔌 [ActionCableConsumer] Closing existing connection');
      this.cable.close();
    }

    // Создаем WebSocket соединение к Action Cable
    const wsUrl = this.buildWebSocketUrl(url, params);
    console.log('🔌 [ActionCableConsumer] WebSocket URL:', wsUrl);
    this.cable = new WebSocket(wsUrl);
    
    // Сохраняем параметры для переподключения
    this.lastUrl = url;
    this.lastParams = params;
    
    this.cable.onopen = () => {
      console.log('🔗 [ActionCableConsumer] Connected to Action Cable');
      // Устанавливаем флаг готовности
      this.connectionReady = true;
      // Обрабатываем отложенные подписки
      this.processPendingSubscriptions();
    };
    
    this.cable.onclose = (event) => {
      console.log('❌ [ActionCableConsumer] Disconnected from Action Cable, code:', event.code, 'reason:', event.reason);
      this.connectionReady = false;
      
      // Переподключение только если это разрешено и не было намеренным отключением
      if (this.shouldReconnect && event.code !== 1000) {
        console.log('🔄 [ActionCableConsumer] Scheduling reconnection in 3 seconds...');
        this.reconnectTimer = setTimeout(() => {
          if (this.shouldReconnect) {
            console.log('🔄 [ActionCableConsumer] Attempting reconnection...');
            this.connect(this.lastUrl, this.lastParams);
          }
        }, 3000);
      } else {
        console.log('🔌 [ActionCableConsumer] Reconnection disabled or clean close');
      }
    };
    
    this.cable.onmessage = (event) => {
      console.log('📨 [ActionCableConsumer] Raw message received:', event.data);
      const message = JSON.parse(event.data);
      console.log('📨 [ActionCableConsumer] Parsed message:', message);
      this.handleMessage(message);
    };
    
    this.cable.onerror = (error) => {
      console.error('❌ [ActionCableConsumer] WebSocket error:', error);
    };
  }

  processPendingSubscriptions() {
    console.log('🔄 [ActionCableConsumer] Processing pending subscriptions:', this.pendingSubscriptions.length);
    
    while (this.pendingSubscriptions.length > 0) {
      const pendingSubscription = this.pendingSubscriptions.shift();
      console.log('🔄 [ActionCableConsumer] Processing pending subscription:', pendingSubscription.identifier);
      
      this.send({
        command: 'subscribe',
        identifier: pendingSubscription.identifier
      });
    }
  }

  buildWebSocketUrl(path, params) {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = window.location.host;
    const paramString = new URLSearchParams(params).toString();
    return `${protocol}//${host}${path}${paramString ? '?' + paramString : ''}`;
  }

  subscribe(channel, params = {}) {
    const identifier = JSON.stringify({ channel, ...params });
    console.log('📻 [ActionCableConsumer] Subscribing to channel:', channel, 'with params:', params);
    console.log('📻 [ActionCableConsumer] Identifier:', identifier);
    
    const subscription = {
      identifier,
      connected: () => {
        console.log('✅ [ActionCableConsumer] Subscription connected:', identifier);
      },
      disconnected: () => {
        console.log('❌ [ActionCableConsumer] Subscription disconnected:', identifier);
      },
      received: (data) => {
        console.log('📨 [ActionCableConsumer] Data received for subscription:', identifier, data);
      },
      perform: (action, data = {}) => {
        console.log('🎬 [ActionCableConsumer] Performing action:', action, 'with data:', data);
        this.send({
          command: 'message',
          identifier,
          data: JSON.stringify({ action, ...data })
        });
      },
      unsubscribe: () => {
        console.log('🔌 [ActionCableConsumer] Unsubscribing from:', identifier);
        this.send({
          command: 'unsubscribe',
          identifier
        });
        this.subscriptions.delete(identifier);
      }
    };

    this.subscriptions.set(identifier, subscription);
    
    // Отправляем команду подписки или добавляем в очередь
    if (this.connectionReady) {
      console.log('📤 [ActionCableConsumer] Connection ready - sending subscribe command for:', identifier);
      this.send({
        command: 'subscribe',
        identifier
      });
    } else {
      console.log('⏳ [ActionCableConsumer] Connection not ready - queueing subscription for:', identifier);
      this.pendingSubscriptions.push({ identifier });
    }

    return subscription;
  }

  send(data) {
    console.log('📤 [ActionCableConsumer] Attempting to send:', data);
    
    if (this.cable && this.cable.readyState === WebSocket.OPEN) {
      const jsonData = JSON.stringify(data);
      console.log('📤 [ActionCableConsumer] Sending JSON:', jsonData);
      this.cable.send(jsonData);
      console.log('📤 [ActionCableConsumer] Send completed');
    } else {
      console.error('❌ [ActionCableConsumer] Cannot send - WebSocket not ready. ReadyState:', this.cable?.readyState);
      console.error('❌ [ActionCableConsumer] WebSocket states: CONNECTING=0, OPEN=1, CLOSING=2, CLOSED=3');
    }
  }

  handleMessage(message) {
    console.log('🔄 [ActionCableConsumer] Handling message:', message);
    const { identifier, message: data, type } = message;
    console.log('🔄 [ActionCableConsumer] Message details - identifier:', identifier, 'type:', type, 'data:', data);
    
    // Обрабатываем системные сообщения (welcome, ping) без identifier
    if (!identifier) {
      if (type === 'welcome') {
        console.log('🎉 [ActionCableConsumer] Welcome message received - connection ready');
        return;
      } else if (type === 'ping') {
        console.log('💓 [ActionCableConsumer] Ping received:', data);
        return;
      } else {
        console.log('ℹ️ [ActionCableConsumer] System message:', type, data);
        return;
      }
    }
    
    const subscription = this.subscriptions.get(identifier);
    console.log('🔄 [ActionCableConsumer] Found subscription:', !!subscription);
    
    if (!subscription) {
      console.warn('⚠️ [ActionCableConsumer] No subscription found for identifier:', identifier);
      return;
    }

    switch (type) {
      case 'confirm_subscription':
        console.log('✅ [ActionCableConsumer] Subscription confirmed for:', identifier);
        subscription.connected();
        break;
      case 'reject_subscription':
        console.log('❌ [ActionCableConsumer] Subscription rejected for:', identifier);
        subscription.disconnected();
        break;
      default:
        console.log('📨 [ActionCableConsumer] Regular message for:', identifier, 'data:', data);
        if (data) {
          subscription.received(data);
        }
        break;
    }
  }

  disconnect() {
    console.log('🔌 [ActionCableConsumer] Disconnecting...');
    
    // Отключаем автоматическое переподключение
    this.shouldReconnect = false;
    
    // Очищаем таймер переподключения
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    
    if (this.cable) {
      this.cable.close(1000, 'Manual disconnect'); // Чистое закрытие
      this.cable = null;
    }
    
    this.connectionReady = false;
    this.subscriptions.clear();
    this.pendingSubscriptions = [];
    
    console.log('🔌 [ActionCableConsumer] Disconnected and cleaned up');
  }
}

// Глобальный экземпляр consumer
window.actionCableConsumer = new ActionCableConsumer(); 