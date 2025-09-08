from typing import Callable, List, Dict, Any, Tuple, Optional

from selenium import webdriver
from selenium.webdriver.firefox.options import Options

from .error_hook import Notifier, ErrorHook
from .scraper_runner import ScraperRunner


def get_default_driver_options() -> Options:
    """
    Returns a default set of options for the Firefox WebDriver.
    """
    options = Options()
    # Set a common browser window size for consistency.
    options.add_argument("--width=1920")
    options.add_argument("--height=1080")

    # Use a realistic browser user-agent.
    options.set_preference("general.useragent.override",
                           "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:115.0) Gecko/20100101 Firefox/115.0")
    # Disables loading of any browser extensions.
    options.set_preference("extensions.enabledScopes", 0)
    # The following options help to avoid detection as an automated browser.
    # Disables the "navigator.webdriver" flag.
    options.set_preference("dom.webdriver.enabled", False)
    # Disables GPU hardware acceleration if needed, especially in headless mode.
    options.set_preference("layers.acceleration.disabled", True)
    return options


class ScraperBuilder:
    """
    A builder for constructing the ScraperRunner instance.
    """

    def __init__(self):
        """
        Initializes the ScraperBuilder.
        """
        self._steps: List[Tuple[str, Callable[[webdriver.Firefox, Dict[str, Any], Callable[[str], None]], None]]] = []
        self._error_hooks: List[ErrorHook] = []
        self._notifiers: List[Notifier] = []
        self._state: Dict[str, Any] = {}
        self._driver_options: Optional[Options] = None

    def with_step(
            self,
            name: str,
            func: Callable[[webdriver.Firefox, Dict[str, Any], Callable[[str], None]], None]
    ) -> 'ScraperBuilder':
        """
        Adds a named step to the execution sequence.
        Args:
            name: The name of the step (for logging).
            func: A function that takes (driver, state, notify_callback).
        """
        self._steps.append((name, func))
        return self

    def with_error_hook(self, error_hook: ErrorHook) -> 'ScraperBuilder':
        """
        Adds an error hook to the application.
        """
        self._error_hooks.append(error_hook)
        return self

    def with_notifier(self, notifier: Notifier) -> 'ScraperBuilder':
        """
        Adds a notifier to the application.
        """
        self._notifiers.append(notifier)
        return self

    def with_state(self, state: Dict[str, Any]) -> 'ScraperBuilder':
        """
        Sets the initial state for the application.
        """
        self._state = state
        return self

    def with_driver_options(self, options: Options) -> 'ScraperBuilder':
        """
        Sets custom options for the WebDriver.
        """
        self._driver_options = options
        return self

    def build(self) -> ScraperRunner:
        """
        Initializes the WebDriver and builds the Application instance.
        """
        options = self._driver_options or get_default_driver_options()

        return ScraperRunner(
            driver=webdriver.Firefox(options),
            steps=self._steps,
            error_hooks=self._error_hooks,
            state=self._state,
            notifiers=self._notifiers
        )
