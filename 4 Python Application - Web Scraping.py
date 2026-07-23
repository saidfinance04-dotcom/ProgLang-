# Companion script for Session 2 application: Python web scraping.
#
# Goal:
# This file is a slide companion with both the runnable code and the teaching
# text from active (non-commented) slides. It should be usable as a substitute
# for the deck, except for images.
#
# Outline:
# 1) APIs
# 2) Technology basics
# 3) Static scraping
# 4) Dynamic scraping

# Where Python fits (vs R and Julia):
# - R: traditional statistics, econometrics workflows, strong statistical plots.
# - Julia: high-performance modern scientific/numerical computing.
# - Python: strongest "glue" language across data collection, ML, and deployment.
#
# Python is especially strong for:
# - APIs, web scraping, and automation workflows
# - machine learning, NLP, and LLM tooling ecosystems
# - connecting analysis to production apps/services/pipelines

from io import StringIO

import pandas as pd
import requests
from bs4 import BeautifulSoup


# -----------------------------------------------------------------------------
# 1) APIs
# -----------------------------------------------------------------------------

# API (Application Programming Interface):
# More reliable, faster, and no parsing compared with scraping HTML.
#
# World Bank API example:
url = "https://api.worldbank.org/v2/country/DE/indicator/NY.GDP.MKTP.CD"
params = {"format": "json", "date": "2020:2023"}  # No API key needed

response = requests.get(url, params=params)
data = response.json()

gdp_data = pd.DataFrame(data[1])
print(gdp_data[["date", "value"]])

# JSON (JavaScript Object Notation) is a common API format.
# In Python, it behaves like nested dictionaries/lists.

# Exercise: Eurostat API
# Repeat the same idea with Eurostat:
# https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data
#
# Suggested setup:
# - dataset: nama_10_gdp
# - na_item=B1GQ
# - unit=CP_MEUR
# - freq=A
# - geo=DE (then try more countries)
#
# Goal: print a small table with year and value.
# You can of course use an LLM to help draft query/parsing code.
#
# Starter:
# url = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/nama_10_gdp"
# params = {"na_item": "B1GQ", "unit": "CP_MEUR", "freq": "A", "geo": "DE"}
# response = requests.get(url, params=params)
# data = response.json()


# -----------------------------------------------------------------------------
# 2) Technology basics
# -----------------------------------------------------------------------------

# HTML
# Hypertext Markup Language. Anything you see in your browser is based on HTML.
#
# Example structure:
# <html>
#     <head><title>Example</title></head>
#     <body>
#         <h1>Hello World</h1>
#         <p>This is a paragraph.</p>
#         <a href="https://example.com">Link</a>
#     </body>
# </html>
#
# Most common HTML tags:
# - <html>, <head>, <body>: document structure
# - <h1> to <h6>: headings
# - <p>: paragraph
# - <a>: hyperlink
# - <ul>, <ol>, <li>: lists
# - <div>, <span>: generic layout/styling containers
# - <img>: image
# - <table>, <tr>, <td>, <th>: tables
# - <form>, <input>, <button>: forms and user input

# HTTP
# - HTTP transfers HTML between computers.
# - About 90% of internet traffic is HTTP/HTTPS (with a large video share).
# - Minimal GET request can be done with curl in the terminal.
#
# These commands are for the terminal, not for Python:
# curl.exe https://gsefm.eu/ > gsefm.html
# curl.exe https://gsefm.eu/ -L > gsefm.html
#
# The redirection operator ">" writes command output into a file.

# Common HTTP response codes:
# - 200 OK
# - 301 Moved Permanently
# - 302 Found
# - 400 Bad Request
# - 401 Unauthorized
# - 403 Forbidden (possibly blocked)
# - 404 Not Found
# - 429 Too Many Requests
# - 500 Internal Server Error
# - 503 Service Unavailable


# -----------------------------------------------------------------------------
# 3) Static scraping
# -----------------------------------------------------------------------------

# Static web pages:
# - content is directly available in HTML source
# - simple HTTP request + HTML parsing is enough
# - common tools: requests + BeautifulSoup

url = "https://example.com"
response = requests.get(url, timeout=30)
soup = BeautifulSoup(response.text, "html.parser")

page_title = soup.title.get_text(strip=True)
print(page_title)


# CSS selectors for scraping:
# - CSS (Cascading Style Sheets) controls presentation.
# - Selectors can identify elements by tag/class/id hierarchy.
# - Example: div.profile > h3
# - Robust selectors help scraping survive site changes.
# - In browser DevTools, right click -> Inspect helps find selectors.

url = "https://en.wikipedia.org/wiki/List_of_countries_by_GDP_(nominal)"
response = requests.get(url, timeout=30)
print(response.text)
print(response.status_code)

# Retry with a browser-like User-Agent.
# User-Agent = string that identifies browser/application to the server.
# Some websites block missing/suspicious user agents.
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/120.0.0.0 Safari/537.36"
}
response = requests.get(url, headers=headers, timeout=30)
print(response.status_code)
soup = BeautifulSoup(response.text, "html.parser")

# Find the first table with class 'wikitable'
table = soup.select_one("table.wikitable")
# Equivalent without CSS selector:
table = soup.find("table", {"class": "wikitable"})

# Read the table into a DataFrame
df = pd.read_html(StringIO(str(table)))[0]
print(df.head())


# Exercise: Scrape quotes.toscrape.com (static, non-js-delayed)
# Use: https://quotes.toscrape.com/
# - Extract quote text and author for all quotes on the first page.
# - This is very similar to the previous block:
#   request page -> parse HTML with BeautifulSoup -> select elements.
# - Students can of course use an LLM to help with selector/code drafting.
#
# Starter idea:
# url = "https://quotes.toscrape.com/"
# response = requests.get(url, timeout=30)
# soup = BeautifulSoup(response.text, "html.parser")
# quote_cards = soup.select(".quote")
# for quote in quote_cards:
#     text = quote.select_one(".text").get_text(strip=True)
#     author = quote.select_one(".author").get_text(strip=True)
#     print(f"{text} - {author}")
#


# -----------------------------------------------------------------------------
# 4) Dynamic scraping
# -----------------------------------------------------------------------------

# Dynamic websites:
# - static sites are like printed pages (content immediately in HTML)
# - dynamic sites load/generate content via JavaScript after initial load
# - example: quotes.toscrape.com/js-delayed/ has no quotes in initial HTML

url = "https://quotes.toscrape.com/js-delayed/"
response = requests.get(url, timeout=30)
soup = BeautifulSoup(response.text, "html.parser")
quotes = soup.select(".quote")
print(len(quotes))

# Selenium used to be common, but Playwright is now widely preferred for
# browser automation in many workflows.

# pip install playwright
# playwright install
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=False)
    page = browser.new_page()
    page.goto("https://quotes.toscrape.com/js-delayed/")
    page.wait_for_function(
        "document.querySelectorAll('.quote').length > 0", timeout=15000
    )

    quotes = page.locator(".quote")
    for i in range(quotes.count()):
        quote = quotes.nth(i)
        text = quote.locator(".text").inner_text().strip()
        author = quote.locator(".author").inner_text().strip()
        print(f"{text} - {author}")

    # Keep the browser open briefly so the rendered quotes are visible in class.
    page.wait_for_timeout(3000)
    browser.close()
