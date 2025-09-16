#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

INSTALL_DIR="$HOME/.kavak/bin"
REPO_URL="https://github.com/faboscarpa/fscarpa"
VERSION="latest"

echo -e "${GREEN}Kavak Tools - Instalador de Binarios${NC}"
echo "Instalando kavak-tools desde binarios precompilados..."

detect_os_arch() {
    local os=""
    local arch=""
    
    case "$OSTYPE" in
        darwin*)  os="darwin" ;;
        linux*)   os="linux" ;;
        msys*|cygwin*) os="windows" ;;
        *) 
            echo -e "${RED}Sistema operativo no soportado: $OSTYPE${NC}"
            exit 1
            ;;
    esac
    
    case "$(uname -m)" in
        x86_64) arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
        *)
            echo -e "${RED}Arquitectura no soportada: $(uname -m)${NC}"
            exit 1
            ;;
    esac
    
    echo "${os}_${arch}"
}

get_latest_release() {
    local api_url="https://api.github.com/repos/faboscarpa/fscarpa/releases/latest"
    
    if command -v curl >/dev/null 2>&1; then
        curl -s "$api_url" 2>/dev/null | grep -o '"tag_name":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "v1.0.0"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$api_url" 2>/dev/null | grep -o '"tag_name":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "v1.0.0"
    else
        echo "v1.0.0"
    fi
}

download_binary() {
    local platform="$1"
    local version="$2"
    local binary_name="kavak-tools"
    
    if [[ "$platform" == "windows"* ]]; then
        binary_name="${binary_name}.exe"
    fi
    
    local filename="kavak-tools_${platform}"
    if [[ "$platform" == "windows"* ]]; then
        filename="${filename}.exe"
    fi
    
    # Descargar desde GitHub usando la estructura de raw files
    local download_url="https://raw.githubusercontent.com/faboscarpa/fscarpa/${version}/releases/${version}/${filename}"
    local temp_file="/tmp/${filename}"
    
    echo -e "${GREEN}Descargando ${filename}...${NC}" >&2
    
    if command -v curl >/dev/null 2>&1; then
        if ! curl -fL "$download_url" -o "$temp_file"; then
            echo -e "${RED}Error al descargar el binario${NC}" >&2
            echo "URL: $download_url" >&2
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q "$download_url" -O "$temp_file"; then
            echo -e "${RED}Error al descargar el binario${NC}" >&2
            echo "URL: $download_url" >&2
            return 1
        fi
    else
        echo -e "${RED}Error: Se requiere curl o wget para descargar el binario${NC}" >&2
        return 1
    fi
    
    # Verificar que el archivo se descargó correctamente
    if [ ! -f "$temp_file" ] || [ ! -s "$temp_file" ]; then
        echo -e "${RED}Error: El archivo descargado está vacío o no existe${NC}" >&2
        return 1
    fi
    
    echo "$temp_file"
}

install_binary() {
    local temp_file="$1"
    local target_file="$INSTALL_DIR/kavak-tools"
    
    mkdir -p "$INSTALL_DIR"
    
    if ! cp "$temp_file" "$target_file"; then
        echo -e "${RED}Error al copiar el binario a $target_file${NC}"
        return 1
    fi
    
    chmod +x "$target_file"
    rm -f "$temp_file"
    
    echo -e "${GREEN}Binario instalado en $target_file${NC}"
}

add_to_path() {
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo -e "${YELLOW}Añadiendo $INSTALL_DIR al PATH...${NC}"
        
        local shell_name
        shell_name=$(basename "$SHELL")
        local profile_file=""
        
        case "$shell_name" in
            bash)
                if [ -f "$HOME/.bash_profile" ]; then
                    profile_file="$HOME/.bash_profile"
                else
                    profile_file="$HOME/.bashrc"
                fi
                ;;
            zsh)
                profile_file="$HOME/.zshrc"
                ;;
            *)
                profile_file="$HOME/.profile"
                ;;
        esac
        
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$profile_file"
        echo -e "${YELLOW}Añadido al $profile_file${NC}"
        echo -e "${YELLOW}Reinicia tu terminal o ejecuta: source $profile_file${NC}"
    else
        echo -e "${GREEN}$INSTALL_DIR ya está en el PATH${NC}"
    fi
}

verify_installation() {
    if [ -x "$INSTALL_DIR/kavak-tools" ]; then
        echo -e "${GREEN}Verificando instalación...${NC}"
        "$INSTALL_DIR/kavak-tools" --version
        echo -e "${GREEN}¡Instalación exitosa!${NC}"
        echo "Ejecuta 'kavak-tools --help' para ver las opciones disponibles."
    else
        echo -e "${RED}Error: El binario no se instaló correctamente${NC}"
        return 1
    fi
}

main() {
    local platform
    platform=$(detect_os_arch)
    echo "Plataforma detectada: $platform"
    
    local version
    if [ "$VERSION" = "latest" ]; then
        version=$(get_latest_release)
        echo "Versión más reciente: $version"
    else
        version="$VERSION"
    fi
    
    local temp_file
    temp_file=$(download_binary "$platform" "$version")
    local download_result=$?
    
# Debug eliminado para versión final
    
    if [ $download_result -eq 0 ] && [ -f "$temp_file" ]; then
        install_binary "$temp_file"
        add_to_path
        verify_installation
    else
        echo -e "${RED}Error durante la instalación${NC}"
# Debug eliminado para versión final
        exit 1
    fi
}

main "$@"
