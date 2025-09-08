import random
import time
from datetime import datetime
from typing import Any, Tuple, Union

from selenium.webdriver.remote.webdriver import WebDriver
from selenium.webdriver.support import expected_conditions as ec
from selenium.webdriver.support.ui import WebDriverWait


def get_element(driver: WebDriver, locator: Tuple[str, str], timeout: int = 10) -> Any:
    """
    Waits for and returns a single web element identified by the given locator.

    Args:
        driver: The Selenium WebDriver instance.
        locator: A tuple containing the By strategy and the locator string (e.g., (By.ID, "element_id")).
        timeout: The maximum time in seconds to wait for the element to be visible.

    Returns:
        The located web element.
    """
    print(f"Get an element  {locator[0]}='{locator[1]}'")
    wait = WebDriverWait(driver, timeout)
    return wait.until(ec.visibility_of_element_located(locator))


def click_element(driver: WebDriver, locator: Tuple[str, str], timeout: int = 10) -> None:
    """
    Finds a web element using the given locator and clicks on it.

    This function first waits for the element to become visible and then
    performs a click action.

    Args:
        driver: The Selenium WebDriver instance.
        locator: A tuple containing the By strategy and the locator string.
        timeout: The maximum time in seconds to wait for the element to be visible.
    """
    print(f"Click an element  {locator[0]}='{locator[1]}'")
    element = get_element(driver, locator, timeout)
    element.click()


def send_keys(driver: WebDriver, locator: Tuple[str, str], text: str, timeout: int = 10) -> None:
    """
    Sends the given text to a web element identified by the locator.

    Args:
        driver: The Selenium WebDriver instance.
        locator: A tuple containing the By strategy and the locator string.
        text: The text to be sent to the element.
        timeout: The maximum time in seconds to wait for the element to be visible.
    """
    print(f"Send keys to an element  {locator[0]}='{locator[1]}'")
    txt = get_element(driver, locator, timeout)
    txt.send_keys(text)


def random_sleep(x: Union[int, float], y: Union[int, float]) -> None:
    """
    Pauses the execution for a random duration between x and y milliseconds.

    Args:
        x: The minimum sleep time in milliseconds.
        y: The maximum sleep time in milliseconds.
    """
    random_duration = random.uniform(x, y) / 1000  # Convert to seconds
    print(f"Sleep for  {random_duration} seconds")
    time.sleep(random_duration)


def save_screenshot(driver: WebDriver, screenshots_dir: str) -> None:
    """
    Saves a screenshot of the current page to the specified directory.

    The screenshot filename will include a timestamp to ensure uniqueness.

    Args:
        driver: The Selenium WebDriver instance.
        screenshots_dir: The directory where the screenshot will be saved.
    """
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    screenshot_name = f"{screenshots_dir}/{timestamp}.png"
    print(f"Save a screenshot to {screenshot_name}")
    driver.save_screenshot(screenshot_name)
