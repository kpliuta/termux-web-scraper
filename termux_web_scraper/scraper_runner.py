from typing import Callable, List, Dict, Any, Tuple

from selenium import webdriver

from .error_hook import ErrorHook, Notifier


class ScraperRunner:
    """
    The core scraper class that runs the web scraping steps.
    """

    def __init__(
            self,
            driver: webdriver.Firefox,
            steps: List[Tuple[str, Callable[[webdriver.Firefox, Dict[str, Any], Callable[[str], None]], None]]],
            error_hooks: List[ErrorHook],
            state: Dict[str, Any],
            notifiers: List[Notifier]
    ):
        """
        Initializes the ScraperRunner.

        Args:
            driver: The Selenium WebDriver instance.
            steps: A list of steps (name, function) to execute.
            error_hooks: A list of error hook instances.
            state: The application state.
            notifiers: A list of notifier instances.
        """
        self.driver = driver
        self.steps = steps
        self.error_hooks = error_hooks
        self.state = state
        self.notifiers = notifiers

    def run(self):
        """
        Runs the scraper by executing each step in sequence.
        """
        try:
            for name, func in self.steps:
                print(f"- Executing step: {name}")
                func(self.driver, self.state, self._notify_callback)
        except Exception as e:
            print(f"An unexpected error occurred during execution: {e}")
            for hook in self.error_hooks:
                hook.handle(e, self.driver, self.notifiers)
            raise
        finally:
            print("- Execution finished, quitting driver")
            self.driver.quit()

    def _notify_callback(self, message: str):
        print(f"Executing notify callback for message: {message}")
        for notifier in self.notifiers:
            notifier.notify(message)
