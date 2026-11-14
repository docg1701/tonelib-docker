#!/bin/bash
# Helpers de sudo para os scripts deste repositório.
#
# Regra: nunca falhar dizendo "instale X" e parar. Perguntar ao usuário se ele
# autoriza o sudo, mostrar o comando exato que vai rodar, e só então executar.
# Em execução não-interativa (CI, pipe, cron) NÃO pergunta: imprime o comando e
# falha, para não travar esperando input.
#
# Mensagens informativas vão para stderr, para que os helpers possam ser usados
# dentro de $(...) sem corromper a substituição.

# Detecta o gerenciador de pacotes da distro
detect_pm() {
    local pm
    for pm in apt-get dnf pacman zypper apk; do
        if command -v "$pm" > /dev/null 2>&1; then
            echo "$pm"
            return 0
        fi
    done
    return 1
}

# Nome do pacote por gerenciador. Só os casos que mudam de nome entram aqui.
pkg_for() {
    local name="$1" pm="$2"

    case "$name" in
        xz)
            case "$pm" in
                apt-get) echo "xz-utils" ;;
                *) echo "xz" ;;
            esac
            ;;
        *)
            echo "$name" ;;
    esac
}

# Pergunta antes de rodar algo com sudo.
# Uso: ask_sudo "descrição" comando [args...]
ask_sudo() {
    local desc="$1"
    shift

    if [ "$(id -u)" -eq 0 ]; then
        "$@"
        return
    fi

    if [ ! -t 0 ]; then
        echo -e "${RED:-}[ERRO]${NC:-} Precisa de root para: $desc" >&2
        echo "  Modo não-interativo: rode manualmente -> sudo $*" >&2
        return 1
    fi

    if ! command -v sudo > /dev/null 2>&1; then
        echo -e "${RED:-}[ERRO]${NC:-} sudo não encontrado para: $desc" >&2
        echo "  Rode como root: $*" >&2
        return 1
    fi

    echo "" >&2
    echo -e "${YELLOW:-}[SUDO]${NC:-} Este script precisa de root para: $desc" >&2
    echo -e "       comando: ${GREEN:-}sudo $*${NC:-}" >&2

    local resp=""
    read -r -p "       Autorizar agora? [s/N] " resp || resp=""
    case "$resp" in
        [sSyY]*)
            sudo "$@"
            ;;
        *)
            echo -e "${YELLOW:-}[SUDO]${NC:-} Não autorizado. Para seguir manualmente:" >&2
            echo "  sudo $*" >&2
            return 1
            ;;
    esac
}

# Instala um pacote com o gerenciador da distro (perguntando via ask_sudo).
pm_install() {
    local pkg="$1" pm

    if ! pm=$(detect_pm); then
        echo -e "${RED:-}[ERRO]${NC:-} Nenhum gerenciador de pacotes conhecido." >&2
        echo "  Instale o pacote '$pkg' manualmente e rode novamente." >&2
        return 1
    fi

    pkg=$(pkg_for "$pkg" "$pm")
    echo -e "${YELLOW:-}[INFO]${NC:-} Pacote '$pkg' será instalado (gerenciador: $pm)." >&2

    case "$pm" in
        apt-get) ask_sudo "instalar o pacote $pkg" apt-get install -y "$pkg" ;;
        dnf) ask_sudo "instalar o pacote $pkg" dnf install -y "$pkg" ;;
        pacman) ask_sudo "instalar o pacote $pkg" pacman -S --noconfirm "$pkg" ;;
        zypper) ask_sudo "instalar o pacote $pkg" zypper install -y "$pkg" ;;
        apk) ask_sudo "instalar o pacote $pkg" apk add "$pkg" ;;
    esac
}

# Garante que um binário existe; se não, oferece instalar o pacote via sudo.
# Uso: require_tool <binário> <pacote>
require_tool() {
    local bin="$1" pkg="$2"

    command -v "$bin" > /dev/null 2>&1 && return 0

    echo -e "${YELLOW:-}[INFO]${NC:-} '$bin' não encontrado (pacote '$pkg')." >&2

    pm_install "$pkg" || {
        echo -e "${RED:-}[ERRO]${NC:-} '$bin' continua indisponível." >&2
        return 1
    }

    command -v "$bin" > /dev/null 2>&1 || {
        echo -e "${RED:-}[ERRO]${NC:-} '$bin' não apareceu no PATH depois da instalação." >&2
        return 1
    }
    echo -e "${GREEN:-}[OK]${NC:-} '$bin' instalado." >&2
}
