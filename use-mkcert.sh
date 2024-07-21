#! /usr/bin/bash

install=false
uninstall=false
root_authority=false
create=false
create_domain=""
delete=false
delete_domain=""
pfx=false
pfx_certificate=""
output=false
output_certificate=""
key=false
key_certificate=""
ca=false
ca_certificate=""
while getopts 'iurc:d:P:O:K:C:' option; do 
    case $option in
        (i) install=true
        ;;
        (u) uninstall=true
        ;;
        (r) root_authority=true
        ;;
        (c) create=true
            create_domain="${OPTARG}"
        ;;
        (d) delete=true
            delete_domain="${OPTARG}"
        ;;
        (P) pfx=true
            pfx_certificate="${OPTARG}"
        ;;
        (O) output=true
            output_certificate="${OPTARG}"
        ;;
        (K) key=true
            key_certificate="${OPTARG}"
        ;;
        (C) ca=true
            ca_certificate="${OPTARG}"
        ;;
    esac

done

ensure_dependencies() {
    if ! command -v mkcert >/dev/null 2>&2; then
        curl -sS -Lo mkcert "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
        chmod a+x mkcert
        sudo cp mkcert /usr/local/bin
        rm mkcert
    fi
}

usage() {
    cat<<'EOF'
usage:
    ./use-mkcert : Shows the help menu. Installs mkcert if not already installed.
    ./use-mkcert -r : Copy root CA to current directory
    ./use-mkcert -ir : Install mkcert root authority
    ./use-mkcert -ur : Uninstall mkcert root authority
    ./use-mkcert -c "example.com" : Create public and private certificate for example.com in pem files with default naming.
    ./use-mkcert -c "example.com" -O "example.com.pem" -K "example.com-key.pem" : Create a public and private certificate with names for the files.
    ./use-mkcert -c "example.com" -O "example.com.pem" -K "example.com-key.pem" -P : Create a pfx version of the certificate with default naming.
    ./use-mkcert -c "example.com" -O "example.com.pem" -K "example.com-key.pem" -P "example.com.pfx" : Create a pfx version of the certificate with name for the pfx file.
    ./use-mkcert -C "root_ca.cer" : Creates a .cer version of the root mkcert CA.
    ./use-mkcert -d "" : Deletes all the pem, crt and pfx files in the directory.
    ./use-mkcert -d "example.com" : Deletes all the pem, crt and pfx files in the directory with name "example.com"

Show public and private .crt files: mkcert -CAROOT

General Background Information:
/etc/ssl/certs/ : directory containing all the system-wide trusted root CA's
/etc/ssl/certs/ca-certificates.crt : crt file containing a concatentation of all the root CA .pem files
/etc/ca-certificates.conf : tells which files are to be included in the above
To add a Root CA (system): Copy CA certificate to /usr/local/share/ca-certificates/ with .crt extension and then run sudo update-ca-certificates
To remove a Root CA (system): Remove the certificate from /usr/local/share/ca-certificates/ and run sudo update-ca-certificates --fresh

To create a .pfx file: openssl pkcs12 -export -out <your pfx file name>.pfx -inkey <your key certificate>.key -in <your other certificate>.crt
EOF
}

#################### BEGIN SCRIPT ####################
ensure_dependencies

if [[ "${OPTIND}" == "1" ]]; then
    usage
    exit 0
fi

if $create && $delete; then
    echo -e "\e[91mError cannt use -c and -d together\e[37m"
    exit 1
fi

if $install && $root_authority; then
    mkcert -install
    exit 0
fi

if $uninstall && $root_authority; then
    sudo rm -f /usr/local/share/ca-certificates/mkcert*
    sudo update-ca-certificates --fresh
    rm -rf $(mkcert -CAROOT)
    exit 0
fi

if ! $uninstall && ! $install && $root_authority; then 
    if [[ ! -e "$(mkcert -CAROOT)/rootCA.pem" ]]; then
        echo -e "\e[91mError: $(mkcert -CAROOT)/rootCA.pem does not exist."
        exit 1
    fi 
    rm -f "./rootCA.pem"
    cp "$(mkcert -CAROOT)/rootCA.pem" . &&  echo -e "\e[92mCopied root certificate to current directory\e[37m"
    exit 0
fi

if $create; then
    mkcert -cert-file "${output_certificate}" -key-file "${key_certificate}" "${create_domain}"

    if $pfx; then
        openssl pkcs12 -export -out "${pfx_certificate}" -inkey "${key_certificate}" -in "${output_certificate}"
    fi
    exit 0
fi

if $ca; then
    if [[ ! -e "$(mkcert -CAROOT)/rootCA.pem" ]]; then
        echo -e "\e[91mError: $(mkcert -CAROOT)/rootCA.pem does not exist."
        exit 1
    fi 

    if [[ ! -e "$(mkcert -CAROOT)/rootCA-key.pem" ]]; then
        echo -e "\e[91mError: $(mkcert -CAROOT)/rootCA.pem does not exist."
        exit 1
    fi 
    openssl pkcs12 -export -out "${ca_certificate}" -inkey "$(mkcert -CAROOT)/rootCA-key.pem" -in "$(mkcert -CAROOT)/rootCA.pem"
    exit 0
fi

if $delete; then
    rm -f *"${delete_domain}"{.pem,.crt,.pfx,.cer}
    exit 0
fi
