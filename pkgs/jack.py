import requests
from bs4 import BeautifulSoup
import argparse
import curses
import textwrap
import json
import sys
import time  # For potential small delays between requests
import re # For filtering

# --- Constants and Configuration ---
BASE_URL = "https://1337x.to"
DEFAULT_PAGES_TO_SCRAPE = 3  # Scrape the first 3 pages by default
REQUEST_TIMEOUT = 15  # Seconds

# --- Curses Color Pairs ---
COLOR_PAIR_NORMAL = 1
COLOR_PAIR_SELECTED = 2
COLOR_PAIR_HEADER = 3
COLOR_PAIR_BORDER = 4
COLOR_PAIR_SEEDS = 5
COLOR_PAIR_LEECHES = 6
COLOR_PAIR_STATUS = 7
COLOR_PAIR_FILTER_PROMPT = 8 # New color pair for filter prompt

# --- Scraping Functions ---

def scrape_1337x_search(query, pages=DEFAULT_PAGES_TO_SCRAPE, interactive_mode=False, stdscr=None):
    """
    Scrapes search results from 1337x.to for a given query across multiple pages.

    Args:
        query (str): The search term.
        pages (int): The number of pages to scrape.
        interactive_mode (bool): True if running in curses UI mode.
        stdscr (curses window object): The curses window object if in interactive mode.

    Returns:
        list: A list of dictionaries, where each dictionary represents a torrent
              result, or None if the request fails or no results found on the
              first page.
    """
    all_results = []
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                      'AppleWebKit/537.36 (KHTML, like Gecko) '
                      'Chrome/91.0.4472.124 Safari/537.36'
    }

    if not interactive_mode:
        print(f"Searching for '{query}' across {pages} pages...")

    for page_num in range(1, pages + 1):
        search_url = f"{BASE_URL}/search/{requests.utils.quote(query)}/{page_num}/"

        if interactive_mode and stdscr:
            height, width = stdscr.getmaxyx()
            status_line = f"Fetching page {page_num}/{pages}..."
            # Clear previous status and print new one
            stdscr.move(height - 1, 1)
            stdscr.clrtoeol()
            stdscr.addstr(height - 1, 1, status_line[:width-2], curses.color_pair(COLOR_PAIR_STATUS))
            stdscr.refresh()
        elif not interactive_mode:
            print(f"Fetching page {page_num}: {search_url}")  # Status update

        try:
            response = requests.get(search_url, headers=headers,
                                    timeout=REQUEST_TIMEOUT)
            response.raise_for_status()

            soup = BeautifulSoup(response.content, 'html.parser')

            table = soup.find('table', class_='table-list')

            if table:
                rows = table.find('tbody').find_all('tr')

                if not rows and page_num == 1:
                    no_results_div = soup.find('div', class_='box-info-heading')
                    if no_results_div and "No results" in no_results_div.get_text():
                         if not interactive_mode:
                              print("No results found.")
                         return []
                    else:
                         if not interactive_mode:
                              print("Could not find results table or no results message.")
                         return None  # Indicate failure to parse

                if not rows and page_num > 1:
                    if not interactive_mode:
                         print(f"No more results found after page {page_num - 1}.")
                    break  # Stop scraping if a page has no results

                for row in rows:
                    cols = row.find_all('td')
                    if len(cols) > 5:
                        name_col = cols[0]
                        name_link = name_col.find_all('a')

                        if len(name_link) > 1:
                             name = name_link[1].get_text(strip=True)
                             link = BASE_URL + name_link[1]['href']
                        else:
                             name = name_link[0].get_text(strip=True)
                             link = BASE_URL + name_link[0]['href']  # Fallback

                        seeds = cols[1].get_text(strip=True)
                        leeches = cols[2].get_text(strip=True)
                        upload_time = cols[3].get_text(strip=True)
                        size = cols[4].get_text(strip=True)
                        uploader = cols[5].get_text(strip=True)

                        all_results.append({
                            'name': name,
                            'link': link,
                            'seeds': seeds,
                            'leeches': leeches,
                            'upload_time': upload_time,
                            'size': size,
                            'uploader': uploader
                        })
            elif page_num == 1:
                 no_results_div = soup.find('div', class_='box-info-heading')
                 if no_results_div and "No results" in no_results_div.get_text():
                      if not interactive_mode:
                           print("No results found.")
                      return []
                 else:
                      if not interactive_mode:
                           print("Could not find results table structure on the first page.")
                      return None  # Indicate failure to parse

            # Add a small delay between requests to be polite
            time.sleep(0.5)

        except requests.exceptions.RequestException as e:
            if not interactive_mode:
                 print(f"Error during request for page {page_num}: {e}")
            if page_num == 1:
                 return None  # Indicate failure if first page fails
            else:
                 if not interactive_mode:
                      print("Continuing with results from previous pages.")
                 break  # Stop scraping on error for subsequent pages
        except Exception as e:
            if not interactive_mode:
                 print(f"An error occurred during parsing page {page_num}: {e}")
            if page_num == 1:
                 return None  # Indicate failure if first page fails
            else:
                 if not interactive_mode:
                      print("Continuing with results from previous pages.")
                 break  # Stop scraping on error for subsequent pages

    if not interactive_mode:
        print(f"Finished scraping. Found {len(all_results)} results.")
    return all_results

def get_magnet_link(torrent_url):
    """
    Scrapes a torrent details page for the magnet link.

    Args:
        torrent_url (str): The URL of the torrent details page.

    Returns:
        str: The magnet link, or None if not found or request fails.
    """
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                      'AppleWebKit/537.36 (KHTML, like Gecko) '
                      'Chrome/91.0.4472.124 Safari/537.36'
    }

    try:
        response = requests.get(torrent_url, headers=headers,
                                timeout=REQUEST_TIMEOUT)
        response.raise_for_status()

        soup = BeautifulSoup(response.content, 'html.parser')

        # Magnet link is usually in an <a> tag with href starting with 'magnet:'
        magnet_link_tag = soup.find('a', href=lambda href: href and
                                    href.startswith('magnet:'))

        if magnet_link_tag:
            return magnet_link_tag['href']
        else:
            # Try finding the download button which often contains the magnet link
            download_button = soup.find('a', class_='btn-green')
            if download_button and download_button.get('href', '').startswith('magnet:'):
                 return download_button['href']
            # Look for specific div structures if buttons are not reliable
            magnet_div = soup.find('div', class_='box-info-copy')
            if magnet_div:
                 magnet_link_tag_in_div = magnet_div.find('a',
                                                         href=lambda href: href and
                                                         href.startswith('magnet:'))
                 if magnet_link_tag_in_div:
                      return magnet_link_tag_in_div['href']

            return None  # Magnet link not found on the page

    except requests.exceptions.RequestException as e:
        print(f"Error during request for magnet link: {e}")
        return None
    except Exception as e:
        print(f"An error occurred during parsing magnet link: {e}")
        return None

# --- Transmission RPC Function ---

def send_to_transmission(magnet_link, transmission_url):
    """
    Sends a magnet link to a Transmission RPC endpoint.

    Args:
        magnet_link (str): The magnet link to add.
        transmission_url (str): The base URL of the Transmission Web UI
                                (e.g., http://localhost:9091).

    Returns:
        bool: True if successful, False otherwise.
        str: A message indicating the result.
    """
    rpc_url = f"{transmission_url.rstrip('/')}/transmission/rpc"
    session_id = None
    headers = {'Content-Type': 'application/json'}  # Specify content type

    # Attempt 1: Send request without session ID
    try:
        payload = {"method": "torrent-add", "arguments": {"filename": magnet_link}}
        response = requests.post(rpc_url, data=json.dumps(payload),
                                 headers=headers, timeout=10)

        if response.status_code == 409:
            # Session ID required, get it from headers
            session_id = response.headers.get('X-Transmission-Session-Id')
            if not session_id:
                return False, "Transmission RPC: Session ID not found in response headers."

            # Attempt 2: Send request with session ID
            headers['X-Transmission-Session-Id'] = session_id
            response = requests.post(rpc_url, data=json.dumps(payload),
                                     headers=headers, timeout=10)

        response.raise_for_status()  # Raise for other HTTP errors

        rpc_response = response.json()
        if rpc_response.get('result') == 'success':
            # Check if torrent-added or duplicate-torrent
            if 'torrent-added' in rpc_response['arguments']:
                 name = rpc_response['arguments']['torrent-added'].get('name', 'Unknown')
                 return True, f"Successfully added '{name}' to Transmission."
            elif 'torrent-duplicate' in rpc_response['arguments']:
                 name = rpc_response['arguments']['torrent-duplicate'].get('name', 'Unknown')
                 return True, f"Torrent '{name}' is already in Transmission."
            else:
                 return True, "Successfully sent magnet link to Transmission (unknown status)."
        else:
            return False, f"Transmission RPC Error: {rpc_response.get('result', 'Unknown error')}"

    except requests.exceptions.RequestException as e:
        return False, f"Error communicating with Transmission RPC: {e}"
    except json.JSONDecodeError:
        return False, "Transmission RPC: Invalid JSON response."
    except Exception as e:
        return False, f"An unexpected error occurred sending to Transmission: {e}"


# --- Curses UI Functions ---

def init_colors():
    """Initializes curses color pairs."""
    if curses.has_colors():
        curses.start_color()
        # Define color pairs: pair_number, foreground, background
        curses.init_pair(COLOR_PAIR_NORMAL, curses.COLOR_WHITE, curses.COLOR_BLACK)
        # Black text on Cyan background
        curses.init_pair(COLOR_PAIR_SELECTED, curses.COLOR_BLACK, curses.COLOR_CYAN)
        curses.init_pair(COLOR_PAIR_HEADER, curses.COLOR_YELLOW, curses.COLOR_BLACK)
        curses.init_pair(COLOR_PAIR_BORDER, curses.COLOR_CYAN, curses.COLOR_BLACK)
        curses.init_pair(COLOR_PAIR_SEEDS, curses.COLOR_GREEN, curses.COLOR_BLACK)
        curses.init_pair(COLOR_PAIR_LEECHES, curses.COLOR_RED, curses.COLOR_BLACK)
        curses.init_pair(COLOR_PAIR_STATUS, curses.COLOR_MAGENTA, curses.COLOR_BLACK)
        curses.init_pair(COLOR_PAIR_FILTER_PROMPT, curses.COLOR_YELLOW, curses.COLOR_BLACK) # Yellow prompt for filter

def draw_table(stdscr, display_results, selected_row_display_index, start_row, selected_indices_full, full_results_map):
    """
    Draws the results table in the curses window with styling.

    Args:
        stdscr: The curses window object.
        display_results (list): The list of results currently being displayed (can be filtered).
        selected_row_display_index (int): The index of the currently selected row *within the display_results list*.
        start_row (int): The starting index of the display_results list to show on screen.
        selected_indices_full (set): A set of indices of selected items *within the full results list*.
        full_results_map (list): A list mapping index in display_results to index in the full results list.
    """
    stdscr.clear()
    height, width = stdscr.getmaxyx()

    # Ensure terminal is large enough
    min_height = 10
    min_width = 80
    if height < min_height or width < min_width:
        stdscr.addstr(0, 0, f"Terminal too small ({width}x{height}). "
                      f"Please resize to at least {min_width}x{min_height}.")
        stdscr.refresh()
        return False  # Indicate failure to draw

    # Leave space for header, border, status, and filter/input line at the bottom
    max_rows = height - 6
    max_cols = width - 2  # Leave space for border

    if max_rows <= 0 or max_cols <= 0:
         stdscr.addstr(0, 0, "Terminal too small for table layout.")
         stdscr.refresh()
         return False

    # Draw border
    stdscr.attron(curses.color_pair(COLOR_PAIR_BORDER))
    stdscr.box()
    stdscr.attroff(curses.color_pair(COLOR_PAIR_BORDER))

    # Header
    header_text = (" 1337x Search Results (UP/DOWN: Navigate, SPACE: Select/Deselect, "
                   "ENTER: Process, /: Filter, ESC: Exit) ")
    # Center the header text
    header_x = max(0, int((width - len(header_text)) / 2))
    stdscr.addstr(0, header_x, header_text,
                  curses.color_pair(COLOR_PAIR_HEADER) | curses.A_BOLD)

    # Column Headers
    headers = ["Sel", "Name", "Seeds", "Leeches", "Size", "Uploaded", "Uploader"]
    separator_width = len(headers) - 1
    available_width = max_cols - separator_width

    # Proportional widths for main content columns
    name_width = int(available_width * 0.35)
    seeds_width = int(available_width * 0.08)
    leeches_width = int(available_width * 0.08)
    size_width = int(available_width * 0.1)
    uploaded_width = int(available_width * 0.12)
    uploader_width = int(available_width * 0.12)
    sel_width = 4 # Fixed width for "[ ]" or "[X]"

    col_widths = [sel_width, name_width, seeds_width, leeches_width,
                  size_width, uploaded_width, uploader_width]

    # Adjust total width to fit exactly
    current_total_content_width = sum(col_widths)
    if current_total_content_width != available_width:
        # Adjust the widest column (Name)
        col_widths[1] += (available_width - current_total_content_width)

    x_offset = 1  # Start inside the border
    for i, header in enumerate(headers):
        stdscr.addstr(2, x_offset, header[:col_widths[i]],
                      curses.color_pair(COLOR_PAIR_HEADER) | curses.A_UNDERLINE)
        x_offset += col_widths[i] + 1  # +1 for separator

    stdscr.hline(3, 1, curses.ACS_HLINE, max_cols,
                 curses.color_pair(COLOR_PAIR_BORDER))  # Separator line

    # Draw rows
    # Only display rows from start_row up to start_row + max_rows
    rows_to_display = display_results[start_row : start_row + max_rows]

    for i, result in enumerate(rows_to_display):
        y = 4 + i
        x_offset = 1
        # This is the index within the *currently displayed* portion of the filtered list
        display_index = start_row + i
        # Get the original index in the full results list
        original_index = full_results_map[display_index]


        # Determine row attribute (normal or selected/highlighted)
        attr = curses.color_pair(COLOR_PAIR_NORMAL)
        if display_index == selected_row_display_index:
            attr = curses.color_pair(COLOR_PAIR_SELECTED) | curses.A_BOLD  # Highlight current row
        elif original_index in selected_indices_full:
             attr = curses.color_pair(COLOR_PAIR_SELECTED)  # Just selected, not current

        # Selection Marker
        marker = "[X]" if original_index in selected_indices_full else "[ ]"
        stdscr.addstr(y, x_offset, marker, attr)
        x_offset += col_widths[0] + 1

        # Other columns
        row_data = [
            result['name'],
            result['seeds'],
            result['leeches'],
            result['size'],
            result['upload_time'],
            result['uploader']
        ]

        for j, data in enumerate(row_data):
            col_index = j + 1  # Adjust index for col_widths list (skipping 'Sel')
            # Wrap text for the 'Name' column
            if j == 0:  # Name column
                 wrapped_lines = textwrap.wrap(str(data), width=col_widths[col_index])
                 display_text = wrapped_lines[0] if wrapped_lines else ""
            else:
                 display_text = str(data)[:col_widths[col_index]]  # Truncate other columns

            # Apply specific color for Seeds/Leeches if not selected/highlighted AND not the current row
            current_attr = attr
            if display_index != selected_row_display_index:
                if j == 1:  # Seeds column
                    current_attr = curses.color_pair(COLOR_PAIR_SEEDS)
                elif j == 2:  # Leeches column
                    current_attr = curses.color_pair(COLOR_PAIR_LEECHES)

            stdscr.addstr(y, x_offset, display_text, current_attr)
            x_offset += col_widths[col_index] + 1

    # Status/Instruction line (drawn below the table, above the filter line if active)
    status_text = f"Total results: {len(display_results)} ({len(full_results_map)} filtered from {len(full_results_map)} total). Selected: {len(selected_indices_full)}" if len(display_results) != len(full_results_map) else f"Total results: {len(display_results)}. Selected: {len(selected_indices_full)}"
    # Clear the status line area before drawing
    stdscr.move(height - 2, 1) # Status line is now 2 lines from bottom
    stdscr.clrtoeol()
    stdscr.addstr(height - 2, 1, status_text[:width-2], curses.color_pair(COLOR_PAIR_STATUS))

    stdscr.refresh()
    return True  # Indicate successful draw

def get_search_query_ui(stdscr):
    """Gets the search query from the user interactively using curses."""
    stdscr.clear()
    height, width = stdscr.getmaxyx()
    prompt = " Enter search query: "
    prompt_y = height // 2
    prompt_x = int((width - len(prompt)) / 2)

    # Calculate box position relative to the prompt
    box_height = 3
    box_width = min(width - 4, 60) # Limit box width
    box_y = prompt_y
    box_x = prompt_x + len(prompt)

    # Adjust box_x if it goes off screen
    if box_x + box_width + 2 > width:
        box_x = width - box_width - 3
        # Recalculate prompt_x to align with the box
        prompt_x = box_x - len(prompt)
        # Ensure prompt_x is not negative
        prompt_x = max(0, prompt_x)


    stdscr.addstr(prompt_y, prompt_x, prompt, curses.A_BOLD)

    stdscr.attron(curses.color_pair(COLOR_PAIR_BORDER))
    stdscr.addch(box_y - 1, box_x - 1, curses.ACS_ULCORNER)
    stdscr.hline(box_y - 1, box_x, curses.ACS_HLINE, box_width + 1) # +1 for the corner
    stdscr.addch(box_y - 1, box_x + box_width + 1, curses.ACS_URCORNER)
    stdscr.addch(box_y, box_x - 1, curses.ACS_VLINE)
    stdscr.addch(box_y, box_x + box_width + 1, curses.ACS_VLINE)
    stdscr.addch(box_y + 1, box_x - 1, curses.ACS_LLCORNER)
    stdscr.hline(box_y + 1, box_x, curses.ACS_HLINE, box_width + 1) # +1 for the corner
    stdscr.addch(box_y + 1, box_x + box_width + 1, curses.ACS_LRCORNER)
    stdscr.attroff(curses.color_pair(COLOR_PAIR_BORDER))

    stdscr.move(prompt_y, box_x) # Move cursor to input position inside the box
    stdscr.refresh()

    query = ""
    curses.echo()  # Turn on echoing of characters
    curses.curs_set(1)  # Show cursor

    # Get input until Enter is pressed
    while True:
        char = stdscr.getch()
        if char == curses.KEY_ENTER or char in [10, 13]:  # Handle Enter key
            break
        elif char == curses.KEY_BACKSPACE or char == 127:  # Handle Backspace
            if len(query) > 0:
                query = query[:-1]
                # Clear the character on screen
                stdscr.addstr(prompt_y, box_x + len(query), " ")
                stdscr.move(prompt_y, box_x + len(query))
                stdscr.refresh()
        elif 32 <= char <= 126 and box_x + len(query) < box_x + box_width:  # Printable characters within box bounds
            query += chr(char)
            stdscr.addch(prompt_y, box_x + len(query) - 1, char)  # Add character to screen
            stdscr.refresh()
        elif char == 27:  # ESC key
             query = None  # Indicate cancellation
             break

    curses.noecho()  # Turn off echoing
    curses.curs_set(0)  # Hide cursor

    return query

def get_filter_query_ui(stdscr, current_filter):
    """Gets the filter query from the user at the bottom of the screen."""
    height, width = stdscr.getmaxyx()
    prompt = "/"
    input_y = height - 1
    input_x = 1 # Start after border

    # Clear the filter line
    stdscr.move(input_y, input_x)
    stdscr.clrtoeol()

    stdscr.addstr(input_y, input_x, prompt, curses.color_pair(COLOR_PAIR_FILTER_PROMPT))
    stdscr.addstr(input_y, input_x + len(prompt), current_filter, curses.color_pair(COLOR_PAIR_NORMAL))

    stdscr.move(input_y, input_x + len(prompt) + len(current_filter)) # Move cursor to end of current filter
    stdscr.refresh()

    filter_query = current_filter
    curses.echo()  # Turn on echoing
    curses.curs_set(1)  # Show cursor

    while True:
        char = stdscr.getch()
        if char == curses.KEY_ENTER or char in [10, 13]: # Enter key
            break
        elif char == curses.KEY_BACKSPACE or char == 127: # Backspace
            if len(filter_query) > 0:
                filter_query = filter_query[:-1]
                # Clear the character on screen
                stdscr.addstr(input_y, input_x + len(prompt) + len(filter_query), " ")
                stdscr.move(input_y, input_x + len(prompt) + len(filter_query))
                stdscr.refresh()
        elif char == 27: # ESC key
            filter_query = None # Indicate cancellation
            break
        elif 32 <= char <= 126 and input_x + len(prompt) + len(filter_query) < width - 2: # Printable characters within bounds
            filter_query += chr(char)
            stdscr.addch(input_y, input_x + len(prompt) + len(filter_query) - 1, char)
            stdscr.refresh()

    curses.noecho() # Turn off echoing
    curses.curs_set(0) # Hide cursor

    # Clear the filter line after input is done
    stdscr.move(input_y, input_x)
    stdscr.clrtoeol()
    stdscr.refresh()

    return filter_query


def display_results_ui(stdscr, results):
    """Displays results in a table and allows user selection and filtering."""
    if not results:
        stdscr.clear()
        stdscr.addstr(0, 0, "No results found.")
        stdscr.addstr(2, 0, "Press any key to exit.")
        stdscr.refresh()
        stdscr.getch()
        return []  # Return empty list for no selection

    full_results = results # Keep the original list
    filtered_results = list(full_results) # Start with all results
    # Map index in filtered_results to index in full_results
    filtered_indices_map = list(range(len(full_results)))

    current_row_display_index = 0 # Index in the *currently displayed* list
    start_row = 0  # For scrolling the *currently displayed* list
    selected_indices_full = set()  # Use a set for efficient add/remove (indices from *full* list)
    current_filter = "" # Current filter string

    while True:
        # Update max_rows in case terminal was resized
        height, width = stdscr.getmaxyx()
        max_rows = height - 6 # Leave space for header, border, status, and filter line

        if max_rows <= 0: # Prevent infinite loop if terminal is too small
             stdscr.clear()
             stdscr.addstr(0, 0, "Terminal too small for table layout.")
             stdscr.refresh()
             key = stdscr.getch()
             if key == 27: # ESC
                  return []
             continue # Keep checking size

        # Ensure current_row_display_index is within bounds of filtered results
        if len(filtered_results) > 0:
            current_row_display_index = max(0, min(current_row_display_index, len(filtered_results) - 1))
        else:
            current_row_display_index = 0 # Reset if no results match filter

        # Ensure start_row is valid for scrolling
        if len(filtered_results) > max_rows:
             start_row = max(0, min(start_row, len(filtered_results) - max_rows))
        else:
             start_row = 0 # No need to scroll if all fit

        # Draw the table using the filtered results and the mapping
        if not draw_table(stdscr, filtered_results, current_row_display_index,
                          start_row, selected_indices_full, filtered_indices_map):
             # Terminal too small, draw_table printed message, wait for resize or exit
             key = stdscr.getch()
             if key == 27:  # ESC
                  return []  # Indicate cancellation
             continue  # Redraw on any other key press

        # Draw the filter prompt if a filter is active
        if current_filter:
            filter_prompt_text = f"/{current_filter}"
            stdscr.move(height - 1, 1)
            stdscr.clrtoeol()
            stdscr.addstr(height - 1, 1, filter_prompt_text[:width-2], curses.color_pair(COLOR_PAIR_FILTER_PROMPT))
            stdscr.refresh()


        key = stdscr.getch()

        if key == curses.KEY_UP:
            if current_row_display_index > 0:
                current_row_display_index -= 1
                if current_row_display_index < start_row:
                    start_row -= 1
        elif key == curses.KEY_DOWN:
            if current_row_display_index < len(filtered_results) - 1:
                current_row_display_index += 1
                # Adjust start_row to keep the selected row visible
                if current_row_display_index >= start_row + max_rows:
                    start_row += 1
        elif key == ord(' '):  # Space bar
            if len(filtered_results) > 0: # Only select if there are results to select
                original_index = filtered_indices_map[current_row_display_index]
                if original_index in selected_indices_full:
                    selected_indices_full.remove(original_index)
                else:
                    selected_indices_full.add(original_index)
        elif key == ord('/'): # Filter mode
            curses.curs_set(1) # Show cursor for input
            new_filter = get_filter_query_ui(stdscr, current_filter)
            curses.curs_set(0) # Hide cursor

            if new_filter is not None: # If not cancelled by ESC
                current_filter = new_filter
                # Apply filter
                if current_filter:
                    filtered_results = []
                    filtered_indices_map = []
                    filter_pattern = re.compile(re.escape(current_filter), re.IGNORECASE)
                    for i, item in enumerate(full_results):
                        if filter_pattern.search(item['name']):
                            filtered_results.append(item)
                            filtered_indices_map.append(i)
                else: # Filter cleared
                    filtered_results = list(full_results)
                    filtered_indices_map = list(range(len(full_results)))

                # Reset display position after filtering
                current_row_display_index = 0
                start_row = 0
            # Redraw the table immediately after filter input
            continue # Skip the rest of the loop and redraw
        elif key == curses.KEY_ENTER or key in [10, 13]:
            # Process selected items
            items_to_process_indices = set(selected_indices_full)
            if not items_to_process_indices and len(filtered_results) > 0:
                # If nothing explicitly selected, process the currently highlighted item
                original_index = filtered_indices_map[current_row_display_index]
                items_to_process_indices.add(original_index)

            # Get links for all selected indices from the FULL results list
            selected_links = [full_results[i]['link'] for i in sorted(list(items_to_process_indices))]
            return selected_links  # Return the list of selected links
        elif key == 27:  # ESC key
            return []  # Indicate user cancelled selection

def main(stdscr, args):
    """Main function to run the interactive script using curses."""
    init_colors()  # Initialize colors
    curses.curs_set(0)  # Hide cursor initially
    stdscr.keypad(True)  # Enable special keys (like arrow keys)

    search_query = args.search  # Get query from flag first

    if not search_query:
        # If no search flag, get query interactively
        search_query = get_search_query_ui(stdscr)

    if not search_query:
        stdscr.clear()
        stdscr.addstr(0, 0, "No search query entered. Exiting.",
                      curses.color_pair(COLOR_PAIR_STATUS))
        stdscr.addstr(2, 0, "Press any key to exit.")
        stdscr.refresh()
        stdscr.getch()
        return  # Exit if no query

    # Display loading message during scraping
    stdscr.clear()
    height, width = stdscr.getmaxyx()
    loading_message = f"Searching for '{search_query}' across {args.pages} pages..."
    stdscr.addstr(height // 2, int((width - len(loading_message)) / 2),
                  loading_message, curses.color_pair(COLOR_PAIR_STATUS) | curses.A_BOLD)
    stdscr.refresh()

    # Scrape results in interactive mode
    search_results = scrape_1337x_search(search_query, args.pages,
                                         interactive_mode=True, stdscr=stdscr)

    # Clear loading message area
    stdscr.clear()
    stdscr.refresh()

    if search_results is None:
        stdscr.clear()
        stdscr.addstr(0, 0, "An error occurred during the search.",
                      curses.color_pair(COLOR_PAIR_STATUS))
        stdscr.addstr(2, 0, "Press any key to exit.")
        stdscr.refresh()
        stdscr.getch()
        return  # Exit on search error

    selected_links = display_results_ui(stdscr, search_results)

    # Curses UI ends here. Print results to standard output.
    # curses.wrapper handles endwin() when main returns normally.

    if selected_links:
        # Find the full result objects for the selected links to get names etc.
        # Need to use the original search_results list here
        selected_items = [item for item in search_results if item['link'] in selected_links]

        print(f"\nProcessing {len(selected_items)} selected item(s):")
        for i, selected_item in enumerate(selected_items):
            print(f"\n--- Item {i+1}/{len(selected_items)} ---")
            print(f"Name: {selected_item['name']}")
            print(f"Link: {selected_item['link']}")

            print("Fetching magnet link...")
            magnet_link = get_magnet_link(selected_item['link'])

            if magnet_link:
                print("Magnet Link:")
                print(magnet_link)

                if args.url:
                    print("\nSending magnet link to Transmission at "
                          f"{args.url}...")
                    success, message = send_to_transmission(magnet_link, args.url)
                    print(message)
                else:
                    print("\nTransmission URL not provided (--url flag). "
                          "Skipping sending to Transmission.")

            else:
                print("\nCould not retrieve magnet link for this item.")
    elif not search_results:
        print("\nNo results found.")
    else:
        print("\nNo item selected.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Scrape 1337x.to search results and optionally send to '
                    'Transmission.')
    parser.add_argument('--search', type=str,
                        help='Perform a search directly (skips interactive UI).')
    parser.add_argument('--url', type=str,
                        help='Transmission Web UI URL (e.g.http://localhost:9091).')
    parser.add_argument('--pages', type=int, default=DEFAULT_PAGES_TO_SCRAPE,
                        help=f'Num of search results pages to scrape (default:'
                             f'{DEFAULT_PAGES_TO_SCRAPE}).')

    args = parser.parse_args()

    if args.search and not args.url:
        print("Warning: --search flag provided without --url. Will only print "
            "magnet link for the first result")

    if args.search:
        # Run directly without curses if --search is provided
        search_query = args.search
        # scrape_1337x_search prints status updates directly in this mode
        search_results = scrape_1337x_search(search_query, args.pages,
                                             interactive_mode=False)

        if search_results is None:
            print("An error occurred during the search.")
            sys.exit(1)  # Exit with error code
        elif not search_results:
           # "No results found" is printed by scrape_1337x_search
           sys.exit(0)  # Exit successfully but with no results

        # Select the first result in non-interactive mode
        selected_item = search_results[0]
        print(f"Non-interactive mode: Selected '{selected_item['name']}'")

        # Process the single selected link
        print(f"\nFetching magnet link for: {selected_item['name']}")
        magnet_link = get_magnet_link(selected_item['link'])

        if magnet_link:
            print("\nMagnet Link:")
            print(magnet_link)

            if args.url:
                print("\nSending magnet link to Transmission at "
                      f"{args.url}...")
                success, message = send_to_transmission(magnet_link, args.url)
                print(message)
            else:
                print("\nTransmission URL not provided (--url flag). "
                      "Skipping sending to Transmission.")
        else:
            print("\nCould not retrieve magnet link for the selected item.")

        sys.exit(0)  # Exit after non-interactive run

    else:
        # Run with curses UI if --search is not provided
        try:
            # curses.wrapper handles initscr(), endwin(), and exceptions within main
            curses.wrapper(main, args)
        except curses.error as e:
            print(f"Curses error: {e}")
            print("Your terminal might not support curses, or the window is "
                  "too small.")
        except Exception as e:
            print(f"An unexpected error occurred: {e}")
            # In case of an unexpected error *outside* curses.wrapper,
            # try to clean up curses if it was initialized.
            # This is a fallback and might still produce the ERR message
            # if endwin was already called or state is bad.
            try:
                curses.endwin()
            except curses.error:
                pass # Ignore if endwin fails

