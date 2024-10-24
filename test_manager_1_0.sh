#!/bin/bash

# ANSI color codes
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

# Define the absolute path for the test directory
ABSOLUTE_TEST_PATH="/test"

# Predefined list of countries (easy to append in the future)
countries=("Norway" "United Kingdom" "Denmark" "Germany")

# Function to display a header with border and color
print_header() {
  echo -e "${CYAN}=============================================${RESET}"
  echo -e "${GREEN}         Test Manager 1.0                    ${RESET}"
  echo -e "${CYAN}=============================================${RESET}"
  echo ""
}

# Function to display the menu
show_menu() {
  echo -e "${YELLOW}What would you like to do?${RESET}"
  echo -e "${CYAN}1) Create Test Folder Structure${RESET}"
  echo -e "${CYAN}2) Create Podman Containers${RESET}"
  echo -e "${CYAN}3) List Active Containers${RESET}"
  echo -e "${CYAN}4) Stop a Container${RESET}"
  echo -e "${CYAN}5) Finish a Test (Stop all related containers)${RESET}"
  echo -e "${CYAN}6) Exit${RESET}"
  echo -n -e "${YELLOW}Enter your choice (1-6): ${RESET}"
  read choice
}

# Function to prompt the user to select a country from the predefined list
choose_country() {
  echo -e "${YELLOW}Please choose a nation:${RESET}"
  for i in "${!countries[@]}"; do
    echo -e "${CYAN}$((i+1))) ${countries[$i]}${RESET}"
  done
  echo -n -e "${YELLOW}Enter the number corresponding to your choice: ${RESET}"
  read country_choice

  # Ensure valid selection
  if [[ "$country_choice" -ge 1 && "$country_choice" -le "${#countries[@]}" ]]; then
    nation="${countries[$((country_choice-1))]}"
    echo -e "${GREEN}You selected: $nation${RESET}"
  else
    echo -e "${RED}Invalid choice. Please try again.${RESET}"
    choose_country
  fi
}

# Function to prompt the user and read input for test number and container count
get_user_input() {
  choose_country
  echo -e "${YELLOW}Enter Test Number: ${RESET}"
  read test_number
  echo -e "${YELLOW}Enter number of containers to create: ${RESET}"
  read container_count
}

# Function to create folder structure
create_folder_structure() {
  base_path="${ABSOLUTE_TEST_PATH}/${nation}/${test_number}"
  subfolders=("Testplan" "Raw" "Import" "Report")
  containers_path="${base_path}/containers"

  echo -e "${CYAN}Creating folder structure at ${base_path}...${RESET}"
  mkdir -p "${base_path}"

  # Create subfolders (Testplan, Raw, Import, Report)
  for folder in "${subfolders[@]}"; do
    mkdir -p "${base_path}/${folder}"
    echo -e "${GREEN}  Created folder: ${base_path}/${folder}${RESET}"
  done

  echo -e "${CYAN}Folder structure created successfully!${RESET}"
  echo ""
}

# Function to create CSV file header
initialize_csv() {
  csv_file="${ABSOLUTE_TEST_PATH}/containers_list.csv"
  
  # Check if CSV file already exists, if not, create it with headers
  if [ ! -f "${csv_file}" ]; then
    echo "Container Name,Test Number,Nation,Volume Mount Path" > "${csv_file}"
    echo -e "${GREEN}CSV file initialized: ${csv_file}${RESET}"
  fi
}

# Function to create Podman containers and log to CSV
create_podman_containers() {
  containers_path="${ABSOLUTE_TEST_PATH}/${nation}/${test_number}/containers"
  csv_file="${ABSOLUTE_TEST_PATH}/containers_list.csv"

  echo -e "${CYAN}Creating containers folder at ${containers_path}...${RESET}"
  mkdir -p "${containers_path}"

  # Loop to create specified number of containers
  for i in $(seq 1 $container_count); do
    container_name="test_container_${nation}_${test_number}_${i}"
    volume_mount_path="/data${i}"

    echo -e "${YELLOW}Creating container $container_name...${RESET}"
    
    # Podman command to create container (customize as needed)
    podman create --name "${container_name}" -v "${containers_path}:${volume_mount_path}" alpine

    echo -e "${GREEN}  Created Podman container: ${container_name} with volume mounted at ${volume_mount_path}${RESET}"

    # Append container details to the CSV file
    echo "${container_name},${test_number},${nation},${containers_path}:${volume_mount_path}" >> "${csv_file}"
  done

  echo -e "${CYAN}Podman containers created and logged to CSV successfully!${RESET}"
  echo ""
}

# Function to show active containers
show_active_containers() {
  echo -e "${CYAN}Listing active containers...${RESET}"
  podman ps --format "{{.ID}} {{.Names}}"
  echo ""
}

# Function to stop a container
stop_container() {
  echo -e "${YELLOW}Enter the container name or ID to stop, or type 'exit' to skip: ${RESET}"
  read container_id

  if [ "$container_id" != "exit" ]; then
    echo -e "${RED}Stopping container $container_id...${RESET}"
    podman stop "$container_id"
    echo -e "${GREEN}Container $container_id stopped.${RESET}"
  else
    echo -e "${CYAN}No containers stopped.${RESET}"
  fi
}

# Function to stop all containers related to a test
stop_test_containers() {
  echo -e "${CYAN}Stopping all containers for test: Nation=${nation}, Test Number=${test_number}...${RESET}"
  
  # List all containers matching the test
  podman ps --filter "name=test_container_${nation}_${test_number}" --format "{{.ID}} {{.Names}}" | while read -r id name; do
    echo -e "${RED}Stopping container ${name}...${RESET}"
    podman stop "${id}"
    echo -e "${GREEN}Container ${name} stopped.${RESET}"
  done

  echo -e "${CYAN}All containers for the test have been stopped.${RESET}"
}

# Main script execution
print_header
while true; do
  show_menu

  case $choice in
    1)
      get_user_input
      create_folder_structure
      ;;
    2)
      get_user_input
      initialize_csv
      create_podman_containers
      ;;
    3)
      show_active_containers
      ;;
    4)
      stop_container
      ;;
    5)
      get_user_input
      stop_test_containers
      ;;
    6)
      echo -e "${CYAN}Exiting Test Manager 1.0. Goodbye!${RESET}"
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid choice. Please enter a number between 1 and 6.${RESET}"
      ;;
  esac
done
