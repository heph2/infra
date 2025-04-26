import requests
from bs4 import BeautifulSoup
import argparse
import curses
import textwrap
import json
import sys
import time  # For potential small delays between requests

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

# --- Scraping Functions ---

def scrape_1337x_search(query, pages=DEFAULT_PAGES_TO_SCRAPE):
    """
    Scrapes search results from 1337x.to for a given query across multiple pages.

    Args:
        query (str): The search term.
        pages (int): The number of pages to scrape.

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

    print(f"Searching for '{query}' across {pages} pages...")

    for page_num in range(1, pages + 1):
        search_url = f"{BASE_URL}/search/{requests.utils.quote(query)}/{page_num}/"
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
                    # No results on the first page
                    no_results_div = soup.find('div', class_='box-info-heading')
                    if no_results_div and "No results" in no_results_div.get_text():
                         print("No results found.")
                         return []
                    else:
                         print("Could not find results table or no results message.")
                         return None  # Indicate failure to parse

                if not rows and page_num > 1:
                    # No more results on subsequent pages
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
                 # No table found on the first page
                 no_results_div = soup.find('div', class_='box-info-heading')
                 if no_results_div and "No results" in no_results_div.get_text():
                      print("No results found.")
                      return []
                 else:
                      print("Could not find results table structure on the first page.")
                      return None  # Indicate failure to parse

            # Add a small delay between requests to be polite
            time.sleep(0.5)

        except requests.exceptions.RequestException as e:
            print(f"Error during request for page {page_num}: {e}")
            if page_num == 1:
                 return None  # Indicate failure if first page fails
            else:
                 print("Continuing with results from previous pages.")
                 break  # Stop scraping on error for subsequent pages
        except Exception as e:
            print(f"An error occurred during parsing page {page_num}: {e}")
            if page_num == 1:
                 return None  # Indicate failure if first page fails
            else:
                 print("Continuing with results from previous pages.")
                 break  # Stop scraping on error for subsequent pages

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

def draw_table(stdscr, results, selected_row, start_row, selected_indices):
    """Draws the results table in the curses window with styling."""
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

    max_rows = height - 6  # Leave space for header, border, status, and input
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
                   "ENTER: Process, ESC: Exit) ")
    stdscr.addstr(0, int((width - len(header_text)) / 2), header_text,
                  curses.color_pair(COLOR_PAIR_HEADER) | curses.A_BOLD)

    # Column Headers
    # Added a column for selection marker
    headers = ["Sel", "Name", "Seeds", "Leeches", "Size", "Uploaded", "Uploader"]
    # Dynamic column width calculation (adjusting for the new 'Sel' column)
    col_widths = [4, int(max_cols * 0.35), int(max_cols * 0.08), int(max_cols * 0.08),
                  int(max_cols * 0.1), int(max_cols * 0.12), int(max_cols * 0.12)]

    # Adjust widths to fit exactly and account for separators
    current_total_width = sum(col_widths) + len(headers) - 1
    if current_total_width > max_cols:
        col_widths[1] -= (current_total_width - max_cols)  # Reduce name column
    elif current_total_width < max_cols:
         col_widths[1] += (max_cols - current_total_width)  # Increase name column

    x_offset = 1  # Start inside the border
    for i, header in enumerate(headers):
        stdscr.addstr(2, x_offset, header[:col_widths[i]],
                      curses.color_pair(COLOR_PAIR_HEADER) | curses.A_UNDERLINE)
        x_offset += col_widths[i] + 1  # +1 for separator

    stdscr.hline(3, 1, curses.ACS_HLINE, max_cols,
                 curses.color_pair(COLOR_PAIR_BORDER))  # Separator line

    # Draw rows
    display_results = results[start_row : start_row + max_rows]
    for i, result in enumerate(display_results):
        y = 4 + i
        x_offset = 1
        row_index = start_row + i  # Actual index in the full results list

        # Determine row attribute (normal or selected/highlighted)
        attr = curses.color_pair(COLOR_PAIR_NORMAL)
        if row_index == selected_row:
            attr = curses.color_pair(COLOR_PAIR_SELECTED) | curses.A_BOLD  # Highlight current row
        elif row_index in selected_indices:
             attr = curses.color_pair(COLOR_PAIR_SELECTED)  # Just selected, not current

        # Selection Marker
        marker = "[X]" if row_index in selected_indices else "[ ]"
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
                 wrapped_lines = textwrap.wrap(data, width=col_widths[col_index])
                 display_text = wrapped_lines[0] if wrapped_lines else ""
            else:
                 display_text = str(data)[:col_widths[col_index]]  # Truncate other columns

            # Apply specific color for Seeds/Leeches if not selected/highlighted
            current_attr = attr
            if row_index != selected_row and row_index not in selected_indices:
                if j == 1:  # Seeds column
                    current_attr = curses.color_pair(COLOR_PAIR_SEEDS)
                elif j == 2:  # Leeches column
                    current_attr = curses.color_pair(COLOR_PAIR_LEECHES)

            stdscr.addstr(y, x_offset, display_text, current_attr)
            x_offset += col_widths[col_index] + 1

    # Status/Instruction line
    status_text = f"Total results: {len(results)}. Selected: {len(selected_indices)}"
    stdscr.addstr(height - 1, 1, status_text, curses.color_pair(COLOR_PAIR_STATUS))


    stdscr.refresh()
    return True  # Indicate successful draw

def get_search_query_ui(stdscr):
    """Gets the search query from the user interactively using curses."""
    stdscr.clear()
    height, width = stdscr.getmaxyx()
    prompt = " Enter search query: "
    stdscr.addstr(height // 2, int((width - len(prompt)) / 2), prompt, curses.A_BOLD)
    stdscr.refresh()

    query = ""
    curses.echo()  # Turn on echoing of characters
    curses.curs_set(1)  # Show cursor

    input_y = height // 2
    input_x = int((width - len(prompt)) / 2) + len(prompt)

    # Get input until Enter is pressed
    while True:
        char = stdscr.getch()
        if char == curses.KEY_ENTER or char in [10, 13]:  # Handle Enter key
            break
        elif char == curses.KEY_BACKSPACE or char == 127:  # Handle Backspace
            if len(query) > 0:
                query = query[:-1]
                # Clear the character on screen
                stdscr.addstr(input_y, input_x + len(query), " ")
                stdscr.move(input_y, input_x + len(query))
                stdscr.refresh()
        elif 32 <= char <= 126 and input_x + len(query) < width - 2:  # Printable characters within bounds
            query += chr(char)
            stdscr.addch(input_y, input_x + len(query) - 1, char)  # Add character to screen
            stdscr.refresh()
        elif char == 27:  # ESC key
             query = None  # Indicate cancellation
             break

    curses.noecho()  # Turn off echoing
    curses.curs_set(0)  # Hide cursor

    return query

def display_results_ui(stdscr, results):
    """Displays results in a table and allows user selection."""
    if not results:
        stdscr.clear()
        stdscr.addstr(0, 0, "No results found.")
        stdscr.addstr(2, 0, "Press any key to exit.")
        stdscr.refresh()
        stdscr.getch()
        return []  # Return empty list for no selection

    current_row = 0
    start_row = 0  # For scrolling
    selected_indices = set()  # Use a set for efficient add/remove
    height, width = stdscr.getmaxyx()
    max_rows = height - 6  # Calculated in draw_table, but needed here for logic

    while True:
        if not draw_table(stdscr, results, current_row, start_row,
                          selected_indices):
             # Terminal too small, wait for resize or exit
             key = stdscr.getch()
             if key == 27:  # ESC
                  return []  # Indicate cancellation
             continue  # Redraw on any other key press

        key = stdscr.getch()

        if key == curses.KEY_UP:
            if current_row > 0:
                current_row -= 1
                if current_row < start_row:
                    start_row -= 1
        elif key == curses.KEY_DOWN:
            if current_row < len(results) - 1:
                current_row += 1
                if current_row >= start_row + max_rows:
                    start_row += 1
        elif key == ord(' '):  # Space bar
            if current_row in selected_indices:
                selected_indices.remove(current_row)
            else:
                selected_indices.add(current_row)
        elif key == curses.KEY_ENTER or key in [10, 13]:
            # Process selected items
            if not selected_indices:
                # If nothing selected, process the currently highlighted item
                selected_indices.add(current_row)

            # Get links for all selected indices
            selected_links = [results[i]['link'] for i in sorted(list(selected_indices))]
            return selected_links  # Return the list of selected links
        elif key == 27:  # ESC key
            return []  # Indicate user cancelled selection

def main(stdscr, args):
    """Main function to run the interactive or non-interactive script."""
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

    stdscr.clear()
    stdscr.addstr(0, 0, f"Searching for '{search_query}'...",
                  curses.color_pair(COLOR_PAIR_STATUS))
    stdscr.refresh()

    # Scrape results (using the specified number of pages)
    search_results = scrape_1337x_search(search_query, args.pages)

    if search_results is None:
        stdscr.clear()
        stdscr.addstr(0, 0, "An error occurred during the search.",
                      curses.color_pair(COLOR_PAIR_STATUS))
        stdscr.addstr(2, 0, "Press any key to exit.")
        stdscr.refresh()
        stdscr.getch()
        return  # Exit on search error

    selected_links = []
    if not args.search:  # Only display UI if not in non-interactive mode
        selected_links = display_results_ui(stdscr, search_results)
    elif search_results:
        # In non-interactive mode with results, select the first one
        selected_links = [search_results[0]['link']]
        # Print the name of the selected item in non-interactive mode
        curses.endwin()  # End curses before printing to stdout
        print(f"Non-interactive mode: Selected '{search_results[0]['name']}'")


    # Curses ends here if in interactive mode or if we need to print output
    if not args.search or not selected_links:
         curses.endwin()  # Ensure curses is ended if it was started

    if selected_links:
        print(f"\nProcessing {len(selected_links)} selected item(s):")
        for i, selected_link in enumerate(selected_links):
            print(f"\n--- Item {i+1}/{len(selected_links)} ---")
            # Find the name corresponding to the link for better output
            item_name = next((item['name'] for item in search_results
                              if item['link'] == selected_link), selected_link)
            print(f"Fetching magnet link for: {item_name}")

            magnet_link = get_magnet_link(selected_link)

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
    elif args.search and not search_results:
         # "No results found" is printed by scrape_1337x_search
        pass  # No need to print anything else here
    else:
        print("\nNo item selected or search cancelled.")


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
        # Need to simulate the main logic flow without the curses wrapper
        search_query = args.search
        # scrape_1337x_search prints status updates directly in this mode
        search_results = scrape_1337x_search(search_query, args.pages)

        if search_results is None:
            print("An error occurred during the search.")
            sys.exit(1)  # Exit with error code
        elif not search_results:
             # "No results found" is printed by scrape_1337x_search
           sys.exit(0)  # Exit successfully but with no results

        # Select the first result in non-interactive mode
        selected_links = [search_results[0]['link']]
        print(f"Non-interactive mode: Selected '{search_results[0]['name']}'")

        # Process the single selected link
        print(f"\nFetching magnet link for: {search_results[0]['name']}")
        magnet_link = get_magnet_link(selected_links[0])

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
            curses.wrapper(main, args)  # Pass args to main
        except curses.error as e:
            print(f"Curses error: {e}")
            print("Your terminal might not support curses, or the window is "
                  "too small.")
        except Exception as e:
            print(f"An unexpected error occurred: {e}")
            # Ensure curses is ended if it failed after initialization
            try:
                curses.endwin()
            except curses.error:
                pass  # Ignore if endwin fails
