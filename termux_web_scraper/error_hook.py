import os
from abc import ABC, abstractmethod
from typing import List

from selenium import webdriver

from .helpers import save_screenshot
from .notifier import Notifier


class ErrorHook(ABC):
    """Abstract base class for an error hook."""

    @abstractmethod
    def handle(self, exception: Exception, driver: webdriver.Firefox, notifiers: List[Notifier]):
        """
        Handles an error.

        Args:
            exception: The exception that occurred.
            driver: The Selenium WebDriver instance.
            notifiers: A list of notifier instances to use for sending notifications.
        """
        pass


class ScreenshotErrorHook(ErrorHook):
    """An error hook that saves a screenshot on failure."""

    def __init__(self, screenshots_dir: str):
        """
        Initializes the ScreenshotErrorHook.

        Args:
            screenshots_dir: The directory where screenshots will be saved.
        """
        self._screenshots_dir = screenshots_dir
        os.makedirs(self._screenshots_dir, exist_ok=True)

    def handle(self, exception: Exception, driver: webdriver.Firefox, notifiers: List[Notifier]):
        """
        Handles the error by saving a screenshot.
        """
        print(f"ScreenshotErrorHook: Saving screenshot due to error: {exception}")
        if driver:
            save_screenshot(driver, self._screenshots_dir)


class NotificationErrorHook(ErrorHook):
    """An error hook that sends a notification on failure."""

    def handle(self, exception: Exception, driver: webdriver.Firefox, notifiers: List[Notifier]):
        """
        Handles the error by sending a notification.
        """
        message = f"An unexpected error occurred: {exception}"
        print(f"NotificationErrorHook: Sending notification: {message}")
        for notifier in notifiers:
            notifier.notify(message)
