#!/bin/bash

# b2s-customers.sh
# ----------------
# BigCommerce to Shopify customer converter

# Default values
INPUT="bigcommerce.csv" # Default template, not bulk-edit
OUTPUT="shopify.csv"
TEST_MODE=false
TEST_LIMIT=100
VERBOSE=false

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Convert BigCommerce customer data to Shopify format"
    echo ""
    echo "OPTIONS:"
    echo "  --test           Run in test mode (process first $TEST_LIMIT records)"
    echo "  --input FILE     Input CSV file (default: bigcommerce.csv)"
    echo "  --output FILE    Output CSV file (default: shopify.csv)"
    echo "  --limit N        Number of records for test mode (default: $TEST_LIMIT)"
    echo "  --verbose        Show detailed progress information"
    echo "  --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                 # Convert all records"
    echo "  $0 --test                         # Convert first 100 records for testing"
    echo "  $0 --input data.csv --output out.csv  # Use custom file names"
    echo "  $0 --test --limit 50 --verbose    # Test mode with 50 records and verbose output"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --test)
            TEST_MODE=true
            shift
            ;;
        --input)
            INPUT="$2"
            shift 2
            ;;
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        --limit)
            TEST_LIMIT="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Set output file for test mode
if [[ "$TEST_MODE" == true ]]; then
    if [[ "$OUTPUT" == "shopify.csv" ]]; then
        OUTPUT="shopify_test.csv"
    fi
fi

# Input validation
echo -e "${BLUE}🔍 Validating input files...${NC}"

if [[ ! -f "$INPUT" ]]; then
    echo -e "${RED}❌ Error: Input file '$INPUT' not found${NC}"
    exit 1
fi

if [[ ! -r "$INPUT" ]]; then
    echo -e "${RED}❌ Error: Cannot read input file '$INPUT'${NC}"
    exit 1
fi

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Error: Python 3 is required but not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Input validation passed${NC}"

# Display configuration
echo -e "${BLUE}📋 Configuration:${NC}"
echo "   Input file:  $INPUT"
echo "   Output file: $OUTPUT"
if [[ "$TEST_MODE" == true ]]; then
    echo -e "   Mode:        ${YELLOW}TEST (first $TEST_LIMIT records)${NC}"
else
    echo "   Mode:        FULL CONVERSION"
fi
echo "   Verbose:     $VERBOSE"
echo ""

# Create backup of existing output file
if [[ -f "$OUTPUT" ]] && [[ "$TEST_MODE" == false ]]; then
    return;
    backup_file="${OUTPUT}.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}⚠️  Output file exists, creating backup: $backup_file${NC}"
    cp "$OUTPUT" "$backup_file"
fi

# Write Shopify header
echo -e "${BLUE}📝 Writing Shopify CSV header...${NC}"
cat <<EOF > "$OUTPUT"
First Name,Last Name,Email,Accepts Email Marketing,Default Address Company,Default Address Address1,Default Address Address2,Default Address City,Default Address Province Code,Default Address Country Code,Default Address Zip,Default Address Phone,Phone,Accepts SMS Marketing,Tags,Note,Tax Exempt
EOF

echo -e "${BLUE}📊 Analyzing input file structure...${NC}"

# Count total lines for progress bar
if [ "$TEST_MODE" = true ]; then
    total_lines=$TEST_LIMIT
    echo -e "Will process ${YELLOW}$total_lines${NC} records (test mode)"
else
    echo "Counting total records..."
    total_lines=$(tail -n +2 "$INPUT" | wc -l | xargs)
    echo -e "Will process ${GREEN}$total_lines${NC} records (full conversion)"
fi

# Validate that we have records to process
if [[ $total_lines -eq 0 ]]; then
    echo -e "${RED}❌ Error: No data records found in input file${NC}"
    exit 1
fi

# Create enhanced Python converter script
echo -e "${BLUE}🔧 Generating conversion engine...${NC}"

# Why Python is necessary:
# 1. Complex CSV parsing with proper handling of quoted fields and escaping
# 2. Advanced regex pattern matching for address parsing
# 3. Robust string manipulation and cleaning functions
# 4. Better error handling and data validation
# 5. Progress tracking with time estimates
# 6. Unicode and encoding support
# While this could theoretically be done in pure bash, Python provides much more reliable 
# CSV parsing and string manipulation, especially for complex data like the address fields.

cat > convert_csv.py << 'PYTHON_EOF'
import csv
import re
import sys
import time

def clean_phone(phone):
    """Clean phone number - remove unwanted characters but keep basic formatting"""
    if not phone:
        return ""
    # Keep only digits
    return re.sub(r'\D', '', phone)

def parse_address(addr_str):
    """Parse the first address from the addresses field"""
    if not addr_str:
        return ["", "", "", "", "", "", "", ""]
    
    # Get first address (split by |)
    first_addr = addr_str.split('|')[0] if '|' in addr_str else addr_str
    
    # Extract fields using regex
    company = ""
    address1 = ""
    address2 = ""
    city = ""
    province = ""
    country = ""
    zip_code = ""
    phone = ""
    
    # Extract each field
    if "Address Company:" in first_addr:
        match = re.search(r'Address Company:\s*([^,]*)', first_addr)
        if match:
            company = match.group(1).strip()
    
    if "Address Line 1:" in first_addr:
        match = re.search(r'Address Line 1:\s*([^,]*)', first_addr)
        if match:
            address1 = match.group(1).strip()
    
    if "Address Line 2:" in first_addr:
        match = re.search(r'Address Line 2:\s*([^,]*)', first_addr)
        if match:
            address2 = match.group(1).strip()
    
    if "City/Suburb:" in first_addr:
        match = re.search(r'City/Suburb:\s*([^,]*)', first_addr)
        if match:
            city = match.group(1).strip()
    
    if "State Abbreviation:" in first_addr:
        match = re.search(r'State Abbreviation:\s*([^,]*)', first_addr)
        if match:
            province = match.group(1).strip()
    
    if "Country:" in first_addr:
        match = re.search(r'Country:\s*([^,]*)', first_addr)
        if match:
            # Convert country name to 2-letter ISO code
            country_name = match.group(1).strip()
            country_map = {
                "Other": "",
                "Afghanistan": "AF",
                "Aland Islands": "AX",
                "Albania": "AL",
                "Algeria": "DZ",
                "American Samoa": "AS",
                "Andorra": "AD",
                "Angola": "AO",
                "Anguilla": "AI",
                "Antarctica": "AQ",
                "Antigua and Barbuda": "AG",
                "Armenia": "AM",
                "Aruba": "AW",
                "Australia": "AU",
                "Austria": "AT",
                "Azerbaijan": "AZ",
                "Bahamas": "BS",
                "Bahrain": "BH",
                "Bangladesh": "BD",
                "Barbados": "BB",
                "Belarus": "BY",
                "Belgium": "BE",
                "Belize": "BZ",
                "Benin": "BJ",
                "Bermuda": "BM",
                "Bhutan": "BT",
                "Bolivia": "BO",
                "Bonaire, Sint Eustatius and Saba": "BQ",
                "Bosnia and Herzegovina": "BA",
                "Botswana": "BW",
                "Bouvet Island": "BV",
                "Brazil": "BR",
                "British Indian Ocean Territory": "IO",
                "Brunei Darussalam": "BN",
                "Bulgaria": "BG",
                "Burkina Faso": "BF",
                "Burundi": "BI",
                "Cabo Verde": "CV",
                "Cambodia": "KH",
                "Cameroon": "CM",
                "Canada": "CA",
                "Cayman Islands": "KY",
                "Central African Republic": "CF",
                "Chad": "TD",
                "Chile": "CL",
                "China": "CN",
                "Christmas Island": "CX",
                "Cocos (Keeling) Islands": "CC",
                "Colombia": "CO",
                "Comoros": "KM",
                "Congo": "CG",
                "Congo, Democratic Republic of the": "CD",
                "Cook Islands": "CK",
                "Costa Rica": "CR",
                "Cote d'Ivoire": "CI",
                "Croatia": "HR",
                "Cuba": "CU",
                "Curacao": "CW",
                "Cyprus": "CY",
                "Czech Republic": "CZ",
                "Denmark": "DK",
                "Djibouti": "DJ",
                "Dominica": "DM",
                "Dominican Republic": "DO",
                "Ecuador": "EC",
                "Egypt": "EG",
                "El Salvador": "SV",
                "Equatorial Guinea": "GQ",
                "Eritrea": "ER",
                "Estonia": "EE",
                "Eswatini": "SZ",
                "Ethiopia": "ET",
                "Falkland Islands (Malvinas)": "FK",
                "Faroe Islands": "FO",
                "Fiji": "FJ",
                "Finland": "FI",
                "France": "FR",
                "French Guiana": "GF",
                "French Polynesia": "PF",
                "French Southern Territories": "TF",
                "Gabon": "GA",
                "Gambia": "GM",
                "Georgia": "GE",
                "Germany": "DE",
                "Ghana": "GH",
                "Gibraltar": "GI",
                "Greece": "GR",
                "Greenland": "GL",
                "Grenada": "GD",
                "Guadeloupe": "GP",
                "Guam": "GU",
                "Guatemala": "GT",
                "Guernsey": "GG",
                "Guinea": "GN",
                "Guinea-Bissau": "GW",
                "Guyana": "GY",
                "Haiti": "HT",
                "Heard Island and McDonald Islands": "HM",
                "Holy See": "VA",
                "Honduras": "HN",
                "Hong Kong": "HK",
                "Hungary": "HU",
                "Iceland": "IS",
                "India": "IN",
                "Indonesia": "ID",
                "Iran": "IR",
                "Iraq": "IQ",
                "Ireland": "IE",
                "Isle of Man": "IM",
                "Israel": "IL",
                "Italy": "IT",
                "Jamaica": "JM",
                "Japan": "JP",
                "Jersey": "JE",
                "Jordan": "JO",
                "Kazakhstan": "KZ",
                "Kenya": "KE",
                "Kiribati": "KI",
                "Korea, Democratic People's Republic of": "KP",
                "Korea, Republic of": "KR",
                "Kuwait": "KW",
                "Kyrgyzstan": "KG",
                "Lao People's Democratic Republic": "LA",
                "Latvia": "LV",
                "Lebanon": "LB",
                "Lesotho": "LS",
                "Liberia": "LR",
                "Libya": "LY",
                "Liechtenstein": "LI",
                "Lithuania": "LT",
                "Luxembourg": "LU",
                "Macao": "MO",
                "Madagascar": "MG",
                "Malawi": "MW",
                "Malaysia": "MY",
                "Maldives": "MV",
                "Mali": "ML",
                "Malta": "MT",
                "Marshall Islands": "MH",
                "Martinique": "MQ",
                "Mauritania": "MR",
                "Mauritius": "MU",
                "Mayotte": "YT",
                "Mexico": "MX",
                "Micronesia, Federated States of": "FM",
                "Moldova, Republic of": "MD",
                "Monaco": "MC",
                "Mongolia": "MN",
                "Montenegro": "ME",
                "Montserrat": "MS",
                "Morocco": "MA",
                "Mozambique": "MZ",
                "Myanmar": "MM",
                "Namibia": "NA",
                "Nauru": "NR",
                "Nepal": "NP",
                "Netherlands": "NL",
                "New Caledonia": "NC",
                "New Zealand": "NZ",
                "Nicaragua": "NI",
                "Niger": "NE",
                "Nigeria": "NG",
                "Niue": "NU",
                "Norfolk Island": "NF",
                "North Macedonia": "MK",
                "Northern Mariana Islands": "MP",
                "Norway": "NO",
                "Oman": "OM",
                "Pakistan": "PK",
                "Palau": "PW",
                "Palestine, State of": "PS",
                "Panama": "PA",
                "Papua New Guinea": "PG",
                "Paraguay": "PY",
                "Peru": "PE",
                "Philippines": "PH",
                "Pitcairn": "PN",
                "Poland": "PL",
                "Portugal": "PT",
                "Puerto Rico": "PR",
                "Qatar": "QA",
                "Reunion": "RE",
                "Romania": "RO",
                "Russian Federation": "RU",
                "Rwanda": "RW",
                "Saint Barthelemy": "BL",
                "Saint Helena, Ascension and Tristan da Cunha": "SH",
                "Saint Kitts and Nevis": "KN",
                "Saint Lucia": "LC",
                "Saint Martin (French part)": "MF",
                "Saint Pierre and Miquelon": "PM",
                "Saint Vincent and the Grenadines": "VC",
                "Samoa": "WS",
                "San Marino": "SM",
                "Sao Tome and Principe": "ST",
                "Saudi Arabia": "SA",
                "Senegal": "SN",
                "Serbia": "RS",
                "Seychelles": "SC",
                "Sierra Leone": "SL",
                "Singapore": "SG",
                "Sint Maarten (Dutch part)": "SX",
                "Slovakia": "SK",
                "Slovenia": "SI",
                "Solomon Islands": "SB",
                "Somalia": "SO",
                "South Africa": "ZA",
                "South Georgia and the South Sandwich Islands": "GS",
                "South Sudan": "SS",
                "Spain": "ES",
                "Sri Lanka": "LK",
                "Sudan": "SD",
                "Suriname": "SR",
                "Svalbard and Jan Mayen": "SJ",
                "Sweden": "SE",
                "Switzerland": "CH",
                "Syrian Arab Republic": "SY",
                "Taiwan": "TW",
                "Tajikistan": "TJ",
                "Tanzania, United Republic of": "TZ",
                "Thailand": "TH",
                "Timor-Leste": "TL",
                "Togo": "TG",
                "Tokelau": "TK",
                "Tonga": "TO",
                "Trinidad and Tobago": "TT",
                "Tunisia": "TN",
                "Turkey": "TR",
                "Turkmenistan": "TM",
                "Turks and Caicos Islands": "TC",
                "Tuvalu": "TV",
                "Uganda": "UG",
                "Ukraine": "UA",
                "United Arab Emirates": "AE",
                "United Kingdom": "GB",
                "United States": "US",
                "United States Minor Outlying Islands": "UM",
                "Uruguay": "UY",
                "Uzbekistan": "UZ",
                "Vanuatu": "VU",
                "Venezuela": "VE",
                "Viet Nam": "VN",
                "Virgin Islands, British": "VG",
                "Virgin Islands, U.S.": "VI",
                "Wallis and Futuna": "WF",
                "Western Sahara": "EH",
                "Yemen": "YE",
                "Zambia": "ZM",
                "Zimbabwe": "ZW"
            }
            country = country_map.get(country_name, country_name[:2].upper())
    
    if "Zip/Postcode:" in first_addr:
        match = re.search(r'Zip/Postcode:\s*([^,]*)', first_addr)
        if match:
            zip_code = match.group(1).strip()
    
    if "Address Phone:" in first_addr:
        match = re.search(r'Address Phone:\s*([^|,]*)', first_addr)
        if match:
            phone = clean_phone(match.group(1))
    
    return [company, address1, address2, city, province, country, zip_code, phone]

def show_progress(processed, total, start_time, verbose=False):
    """Display enhanced progress bar with ETA"""
    if total == 0:
        return
        
    percentage = min(100, (processed * 100) // total)
    bar_length = 40
    filled_length = min(bar_length, (processed * bar_length) // total)
    bar = "█" * filled_length + "░" * (bar_length - filled_length)
    
    # Calculate ETA
    elapsed = time.time() - start_time
    if processed > 0 and elapsed > 0:
        rate = processed / elapsed
        remaining = (total - processed) / rate if rate > 0 and processed < total else 0
        eta_str = f" ETA: {int(remaining)}s" if remaining > 0 else " Done!"
    else:
        eta_str = ""
    
    # Format rate
    rate_str = f" ({processed/elapsed:.1f} rec/s)" if elapsed > 0 and processed > 0 else ""
    
    if verbose:
        print(f"\r🔄 Progress: [{bar}] {percentage:3d}% ({processed:,}/{total:,}){rate_str}{eta_str}", end="", flush=True)
    else:
        print(f"\rProgress: [{bar}] {percentage:3d}% ({processed:,}/{total:,}){eta_str}", end="", flush=True)

def main():
    if len(sys.argv) != 7:
        print("Usage: python3 convert_csv.py <input_file> <output_file> <test_mode> <test_limit> <total_records> <verbose>", file=sys.stderr)
        sys.exit(1)
        
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    test_mode = sys.argv[3] == 'true'
    test_limit = int(sys.argv[4])
    total_records = int(sys.argv[5])
    verbose = sys.argv[6] == 'true'
    
    start_time = time.time()
    
    try:
        # Find column indexes
        with open(input_file, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            header = next(reader)
            
            # Find column indexes
            first_name_idx = last_name_idx = company_idx = email_idx = phone_idx = -1
            notes_idx = group_idx = tax_exempt_idx = addresses_idx = -1
            
            for i, col in enumerate(header):
                col = col.strip().strip('"')
                if col == "First Name":
                    first_name_idx = i
                elif col == "Last Name":
                    last_name_idx = i
                elif col == "Company":
                    company_idx = i
                elif col == "Email":
                    email_idx = i
                elif col == "Phone":
                    phone_idx = i
                elif col == "Notes":
                    notes_idx = i
                elif col == "Customer Group":
                    group_idx = i
                elif col == "Tax Exempt Category":
                    tax_exempt_idx = i
                elif col == "Addresses":
                    addresses_idx = i
        
        processed = 0
        errors = 0
        max_records = test_limit if test_mode else total_records
        
        # Read and process CSV
        with open(input_file, 'r', encoding='utf-8') as infile:
            reader = csv.reader(infile)
            header = next(reader)  # Skip header
            
            with open(output_file, 'a', encoding='utf-8') as outfile:
                writer = csv.writer(outfile)
                
                for row_num, row in enumerate(reader, 1):
                    if test_mode and row_num > test_limit:
                        break
                    
                    try:
                        # Ensure row has enough columns
                        max_idx = max(first_name_idx, last_name_idx, company_idx, email_idx, 
                                      phone_idx, notes_idx, group_idx, tax_exempt_idx, addresses_idx)
                        while len(row) <= max_idx:
                            row.append("")
                        
                        # Extract basic fields safely
                        first_name = row[first_name_idx] if first_name_idx >= 0 else ""
                        last_name = row[last_name_idx] if last_name_idx >= 0 else ""
                        email = row[email_idx] if email_idx >= 0 else ""
                        company = row[company_idx] if company_idx >= 0 else ""
                        phone = ""
                        notes = row[notes_idx] if notes_idx >= 0 else ""
                        group = row[group_idx] if group_idx >= 0 else ""
                        tax_exempt = row[tax_exempt_idx] if tax_exempt_idx >= 0 else ""
                        addresses = row[addresses_idx] if addresses_idx >= 0 else ""
                        
                        # Parse address
                        addr_company, addr1, addr2, city, province, country, zip_code, addr_phone = parse_address(addresses)
                        
                        # Clean address phone
                        #addr_phone = clean_phone(addr_phone)
                        addr_phone = clean_phone(row[phone_idx] if phone_idx >= 0 else "")
                        
                        # Tax exempt handling
                        tax_exempt_val = "yes" if tax_exempt.strip() or group == "Tax exempt Trade 1" else "no"
                        
                        # Tags
                        # Map group values to tags as per requirements
                        group_map = {
                            "Trade 1": "Trade 10",
                            "Trade 2": "Trade 12",
                            "Trade 3": "Trade 20",
                            "Trade 4": "Trade 5",
                            "Tax exempt Trade 1": "Trade 10",
                            "Trade 5": "",
                            "Trade 6": ""
                        }
                        tags = group_map.get(group, group)
                        
                        # Write Shopify row
                        shopify_row = [
                            first_name,           # First Name
                            last_name,            # Last Name  
                            email,                # Email
                            "",                   # Accepts Email Marketing
                            addr_company,         # Default Address Company
                            addr1,                # Default Address Address1
                            addr2,                # Default Address Address2
                            city,                 # Default Address City
                            province,             # Default Address Province Code
                            country,              # Default Address Country Code
                            zip_code,             # Default Address Zip
                            addr_phone,           # Default Address Phone
                            phone,                # Phone
                            "",                   # Accepts SMS Marketing
                            tags,                 # Tags
                            notes,                # Note
                            tax_exempt_val        # Tax Exempt
                        ]
                        
                        writer.writerow(shopify_row)
                        processed += 1
                        
                        # Show progress bar every 50 records or at completion
                        if processed % 50 == 0 or processed >= max_records:
                            show_progress(processed, max_records, start_time, verbose)
                    
                    except Exception as e:
                        errors += 1
                        if verbose:
                            print(f"\nWarning: Error processing row {row_num}: {str(e)}", file=sys.stderr)
        
        # Final progress update
        show_progress(processed, max_records, start_time, verbose)
        
        elapsed_time = time.time() - start_time
        print(f"\n\n✅ Conversion complete!")
        print(f"   📊 Records processed: {processed:,}")
        if errors > 0:
            print(f"   ⚠️  Errors encountered: {errors}")
        print(f"   ⏱️  Time elapsed: {elapsed_time:.1f}s")
        if processed > 0:
            print(f"   🚀 Average rate: {processed/elapsed_time:.1f} records/second")
    
    except Exception as e:
        print(f"\n❌ Fatal error: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
PYTHON_EOF

# Run the Python converter
echo -e "${BLUE}🚀 Starting conversion process...${NC}"
echo ""

# Check if conversion engine was created successfully
if [[ ! -f "convert_csv.py" ]]; then
    echo -e "${RED}❌ Error: Failed to create conversion engine${NC}"
    exit 1
fi

python3 convert_csv.py "$INPUT" "$OUTPUT" "$TEST_MODE" "$TEST_LIMIT" "$total_lines" "$VERBOSE"
conversion_exit_code=$?

# Clean up
rm -f convert_csv.py

echo ""

# Check conversion results
if [[ $conversion_exit_code -eq 0 ]]; then
    if [[ -f "$OUTPUT" ]]; then
        output_lines=$(wc -l < "$OUTPUT")
        data_lines=$((output_lines - 1))  # Subtract header line
        
        echo -e "${GREEN}🎉 SUCCESS!${NC}"
        echo "   📁 Output file: $OUTPUT"
        echo -e "   📊 Records written: ${GREEN}$data_lines${NC}"
        
        # Show file size
        if command -v du &> /dev/null; then
            file_size=$(du -h "$OUTPUT" | cut -f1)
            echo "   💾 File size: $file_size"
        fi
        
        # Show sample of output if verbose (removed the automatic sample logging)
        if [[ "$VERBOSE" == true ]] && [[ $data_lines -gt 0 ]]; then
            echo ""
            echo -e "${BLUE}📋 Sample output (first 3 records):${NC}"
            head -n 4 "$OUTPUT" | tail -n 3 | while IFS=, read -r fname lname email rest; do
                echo "   • $fname $lname ($email)"
            done
        fi
        
        echo ""
        echo -e "${GREEN}✨ Conversion completed successfully!${NC}"
        
        if [[ "$TEST_MODE" == true ]]; then
            echo -e "${YELLOW}ℹ️  This was a test run. Use without --test flag for full conversion.${NC}"
        fi
    else
        echo -e "${RED}❌ Error: Output file was not created${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Conversion failed with exit code $conversion_exit_code${NC}"
    exit 1
fi
