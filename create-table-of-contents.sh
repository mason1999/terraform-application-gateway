#! /usr/bin/bash

set -eo pipefail

input_markdown_file=$1
output_markdown_file=$2

usage() {
    if [[ -z "${input_markdown_file}" ]] && [[ -z "${output_markdown_file}" ]]; then
        cat <<'EOF'
This script creates a new markdown file with a table of contents. Usage:
    - ./create-table-of-contents.sh "README.md" : Creates a new markdown file which defaults to "NEW_README.MD"
    - ./create-table-of-contents.sh "README.md" "TOC.md" : Creates a new markdown file "TOC.md"
EOF
    exit 0
    fi
}

check_output_file_provided() {
    if [[ -z "${output_markdown_file}" ]]; then
        echo 'Defaulting to output file: "NEW_README.md"...'
        output_markdown_file="NEW_README.md"
    fi
}

check_markdown_file_exists() {
    if [[ ! -e "${input_markdown_file}" ]]; then
        echo -e "\e[91mError: ${input_markdown_file} does not exists.\e[37m"
        exit 1
    fi
}

check_table_of_contents_exists() {
    if cat "${input_markdown_file}" | grep '^# Table of contents' > /dev/null; then
        echo "# Table of contents section already exists."
        exit 0
    fi

    if cat "${input_markdown_file}" | grep '^# Table of Contents' > /dev/null; then
        echo "# Table of Contents section already exists."
        exit 0
    fi
}

create_table_of_contents() {
    # Create section_headings_buffer.md to buffer the current section headings
    rm -f "section_headings_buffer.md"
    cat "${input_markdown_file}" | grep '^#' > "section_headings_buffer.md"

    # Create table_of_contents_buffer.md to buffer the table of contents
    rm -f "table_of_contents_buffer.md"
    touch "table_of_contents_buffer.md"
    echo '# Table of Contents' > "table_of_contents_buffer.md"
    echo '' >> "table_of_contents_buffer.md"

    # Create the output markdown file
    rm -f "${output_markdown_file}"
    touch "${output_markdown_file}"
    cp "${input_markdown_file}" "${output_markdown_file}"

    OLD_IFS="${IFS}"
    IFS=$'\n'

    for x in $(cat "section_headings_buffer.md"); do
        section_name=$(echo "${x}" | sed 's/# //g' | sed 's/#//g') # Remove #'s'
        identifier=$(echo "${section_name}" | tr ': ' '_') # Replace spaces with '_'
        list_label=$(echo $x | sed 's/# /* /g' | sed 's/#/  /g' | sed "s/${section_name}/\[${section_name}\]/g") # Replace header with correct indentation and enclose in '[]'
        list_label_linked_section="${list_label}(#${identifier})" # Append link with (#identifier)

        sed -i "s/\# ${section_name}/\# ${section_name}\n<a id=\"${identifier}\"><\/a>/g" "${output_markdown_file}" # Replace section name with section name <newline> <a id="identifer"></a>
        echo "${list_label_linked_section}" >> "table_of_contents_buffer.md"
    done
    echo "" >> "table_of_contents_buffer.md"

    IF="${OLD_IFS}"

    cat "${output_markdown_file}" >> "table_of_contents_buffer.md"
    cat "table_of_contents_buffer.md" > "${output_markdown_file}"

    # Remove the buffer files
    rm -f "section_headings_buffer.md"
    rm -f "table_of_contents_buffer.md"
}

########## BEGIN SCRIPT ##########
usage
check_output_file_provided
check_markdown_file_exists
check_table_of_contents_exists
create_table_of_contents
