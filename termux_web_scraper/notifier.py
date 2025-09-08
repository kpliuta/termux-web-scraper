from abc import ABC, abstractmethod

import requests


class Notifier(ABC):
    """Abstract base class for a notifier."""

    @abstractmethod
    def notify(self, message: str):
        """Sends a notification."""
        pass


class TelegramNotifier(Notifier):
    """A notifier for sending messages to Telegram."""

    def __init__(
            self,
            bot_token: str,
            chat_id: str,
            api_url: str = "https://api.telegram.org/bot<your_bot_token>/sendMessage"
    ):
        """
        Initializes the TelegramNotifier.

        Args:
            api_url: The base URL for the Telegram Bot API.
            bot_token: The token for the Telegram bot.
            chat_id: The ID of the chat to send messages to.
        """
        if not bot_token or not chat_id or not api_url:
            raise ValueError("Telegram API URL, bot token, and chat ID must be provided.")
        self.api_url = api_url.replace('<your_bot_token>', bot_token)
        self.chat_id = chat_id

    def notify(self, message: str):
        """
        Sends a message to Telegram.

        Args:
            message: The message to send.
        """
        try:
            response = requests.post(self.api_url, data={'chat_id': self.chat_id, 'text': message})
            response.raise_for_status()
            print(f"Telegram notification sent: {message}")
        except requests.exceptions.RequestException as e:
            print(f"Error sending Telegram notification: {e}")
