import https from 'https';

export interface TelegramMessage {
  chat_id: string;
  text: string;
  parse_mode?: 'HTML' | 'Markdown';
}

export class TelegramBot {
  private botToken: string;
  private chatId: string;

  constructor(botToken: string, chatId: string) {
    this.botToken = botToken;
    this.chatId = chatId;
  }

  async sendMessage(text: string, parseMode: 'HTML' | 'Markdown' = 'HTML'): Promise<boolean> {
    const message: TelegramMessage = {
      chat_id: this.chatId,
      text: text,
      parse_mode: parseMode
    };

    return new Promise((resolve, reject) => {
      const data = JSON.stringify(message);
      
      const options = {
        hostname: 'api.telegram.org',
        port: 443,
        path: `/bot${this.botToken}/sendMessage`,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(data)
        }
      };

      const req = https.request(options, (res) => {
        let responseData = '';
        
        res.on('data', (chunk) => {
          responseData += chunk;
        });
        
        res.on('end', () => {
          try {
            const response = JSON.parse(responseData);
            if (response.ok) {
              resolve(true);
            } else {
              console.error('Telegram API error:', response.description);
              resolve(false);
            }
          } catch (error) {
            console.error('Error parsing Telegram response:', error);
            resolve(false);
          }
        });
      });

      req.on('error', (error) => {
        console.error('Telegram request error:', error);
        resolve(false);
      });

      req.setTimeout(10000, () => {
        req.destroy();
        console.error('Telegram request timeout');
        resolve(false);
      });

      req.write(data);
      req.end();
    });
  }

  static formatPropertyMessage(properties: any[], searchName: string): string {
    let message = `🏠 <b>${properties.length} New Property Alert${properties.length > 1 ? 's' : ''}</b>\n`;
    message += `📍 <i>${searchName}</i>\n\n`;
    
    properties.forEach((property, index) => {
      message += `<b>${index + 1}. ${property.address}</b>\n`;
      message += `💰 ${property.price}\n`;
      message += `🛏️ ${property.bedrooms} bed`;
      if (property.bathrooms) message += ` | 🚿 ${property.bathrooms} bath`;
      message += `\n`;
      message += `🔗 https://www.rightmove.co.uk${property.propertyUrl}\n\n`;
    });
    
    return message;
  }
}