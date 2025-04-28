import requests
import re
import json
from urllib.parse import urlparse
import sys
import traceback

# Known organization IDs mapped to environments
ORG_MAPPING = {
    "d9ee1fd7-868c-4ea0-af89-5b9813db863d": "test",  # Wawanesa-Test
}

# URL patterns for different environments
DR_PATTERNS = ['.dr.', '-dr.', '-dr-', '/dr/', 'wawanesa-dr']
TEST_PATTERNS = ['.test.', '-test-', 'wawanesa-test', 'cac1.pure.cloud']  # Added cac1 as a test indicator

# Words that might cause false positives
EXCLUDE_WORDS = {
    'dr': ['directory', 'drive', 'drop', 'draw'],
    'test': ['latest', 'contest', 'attestation']
}

# Debug mode
DEBUG = True

def debug_print(*args):
    """Print only if debug mode is enabled"""
    if DEBUG:
        print(*args)

def detect_environment(url, content=None, debug=False):
    """
    Detect environment from URL and optionally page content
    Returns tuple of (environment_type, confidence, detection_method)
    """
    debug_print(f"\nAnalyzing URL: {url}")
    
    # First check for organization ID in content
    if content:
        debug_print("Checking content for organization IDs...")
        for org_id, env in ORG_MAPPING.items():
            if org_id in content:
                debug_print(f"Found organization ID in content: {org_id} -> {env}")
                return (env, 0.95, "org_id")
        debug_print("No organization IDs found in content")

    # Parse URL
    parsed = urlparse(url.lower())
    hostname = parsed.netloc
    path = parsed.path
    fragment = parsed.fragment
    
    debug_print(f"URL components: hostname={hostname}, path={path}, fragment={fragment}")
    
    # Special case for known hostnames
    if 'cac1.pure.cloud' in hostname:
        debug_print("Detected cac1.pure.cloud hostname - this is a TEST environment")
        return ("test", 0.8, "hostname")
    
    # Check for exclude words in DR detection
    should_skip_dr = False
    for word in EXCLUDE_WORDS['dr']:
        if word in hostname or word in path or word in fragment:
            debug_print(f"Found exclude word '{word}' - skipping DR detection")
            should_skip_dr = True
            break
    
    if not should_skip_dr:
        # Check for DR patterns
        for pattern in DR_PATTERNS:
            full_url = f"{hostname}{path}{fragment}"
            if pattern in full_url:
                debug_print(f"Found DR pattern: {pattern}")
                return ("dr", 0.7, "url_pattern")
    
    # Check for test patterns
    for pattern in TEST_PATTERNS:
        full_url = f"{hostname}{path}{fragment}"
        if pattern in full_url:
            debug_print(f"Found TEST pattern: {pattern}")
            return ("test", 0.7, "url_pattern")
    
    # Make API request to check for org ID
    try:
        debug_print("Attempting API requests to detect organization ID...")
        # Try common API endpoints
        api_endpoints = [
            f"{parsed.scheme}://{parsed.netloc}/api/v2/organizations/me",
            f"{parsed.scheme}://{parsed.netloc}/api/v1/org?fl=*"
        ]
        
        for endpoint in api_endpoints:
            debug_print(f"Trying endpoint: {endpoint}")
            try:
                headers = {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                }
                response = requests.get(endpoint, headers=headers, timeout=5)
                debug_print(f"Response status: {response.status_code}")
                
                if response.status_code == 200:
                    data = response.json()
                    debug_print(f"API response: {json.dumps(data, indent=2)[:500]}...")
                    
                    # Extract org ID from various possible locations in the response
                    org_id = None
                    if 'id' in data:
                        org_id = data['id']
                    elif 'guid' in data:
                        org_id = data['guid']
                    elif 'res' in data and 'guid' in data['res']:
                        org_id = data['res']['guid']
                    
                    debug_print(f"Extracted org ID: {org_id}")
                    
                    if org_id and org_id in ORG_MAPPING:
                        debug_print(f"Matched org ID {org_id} to environment: {ORG_MAPPING[org_id]}")
                        return (ORG_MAPPING[org_id], 0.95, "api_request")
            except Exception as e:
                debug_print(f"Error making request to {endpoint}: {str(e)}")
                continue
    except Exception as e:
        debug_print(f"Exception in API detection: {str(e)}")
        if debug:
            traceback.print_exc()
    
    debug_print("No environment detected, defaulting to unknown")
    return ("unknown", 0.5, "default")

# Test with sample URLs
test_urls = [
    "https://apps.cac1.pure.cloud/directory/#/person/7214c54e-64d5-4108-bc6f-9fd8f5ebfae0",
    "https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr",
    "https://apps.mypurecloud.com/directory/#/person/123456"
]

# Add option to specify URL as command line argument
if len(sys.argv) > 1:
    test_urls = [sys.argv[1]]
    print(f"Testing single URL from command line: {test_urls[0]}")

for url in test_urls:
    env, confidence, method = detect_environment(url, debug=True)
    print(f"URL: {url}")
    print(f"Environment: {env} (confidence: {confidence}, method: {method})")
    print("-" * 50)

# Add a manual test option
if __name__ == "__main__" and len(sys.argv) <= 1:
    print("\nWould you like to test another URL? (y/n)")
    choice = input().strip().lower()
    if choice == 'y':
        print("Enter URL to test:")
        test_url = input().strip()
        env, confidence, method = detect_environment(test_url, debug=True)
        print(f"URL: {test_url}")
        print(f"Environment: {env} (confidence: {confidence}, method: {method})")
    
    print("\nUpdating organization mapping...")
    print("Current organization mapping:")
    for org_id, env in ORG_MAPPING.items():
        print(f"  {org_id} -> {env}")
    
    print("\nWould you like to add a new organization ID mapping? (y/n)")
    choice = input().strip().lower()
    if choice == 'y':
        print("Enter organization ID:")
        org_id = input().strip()
        print("Enter environment type (dr/test/dev):")
        env_type = input().strip().lower()
        
        print(f"Adding mapping: {org_id} -> {env_type}")
        print("Add this to your script:")
        print(f'ORG_MAPPING["{org_id}"] = "{env_type}"  # Added manually')